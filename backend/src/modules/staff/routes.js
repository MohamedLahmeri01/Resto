import bcrypt from 'bcrypt';
import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';
import crypto from 'crypto';

const BCRYPT_ROUNDS = 12;

export default async function staffRoutes(fastify) {
  const db = fastify.knex;

  // POST /staff — Create staff account (admin only)
  fastify.post('/', { preHandler: [verifyJWT, requirePermission('staff.manage')] }, async (req) => {
    const { email, phone, first_name_fr, first_name_ar, last_name_fr, last_name_ar, role, role_id, branch_id, preferred_locale, pin } = req.body;

    // Check email uniqueness within tenant
    const existing = await db('users').where({ tenant_id: req.tenantId, email: email.toLowerCase() }).whereNull('deleted_at').first();
    if (existing) throw { status: 409, code: 'EMAIL_EXISTS', message_fr: 'Cet email est déjà utilisé', message_ar: 'هذا البريد الإلكتروني مستخدم بالفعل' };

    const id = genId();
    const onboardingToken = crypto.randomBytes(32).toString('hex');
    const pinHash = pin ? await bcrypt.hash(pin, BCRYPT_ROUNDS) : null;

    await db('users').insert({
      id, tenant_id: req.tenantId, email: email.toLowerCase(), phone,
      first_name_fr, first_name_ar, last_name_fr, last_name_ar,
      role: role || 'staff', role_id, preferred_locale: preferred_locale || 'fr',
      pin_hash: pinHash, is_active: true,
      onboarding_token: onboardingToken,
      onboarding_token_expires_at: new Date(Date.now() + 48 * 60 * 60 * 1000),
      created_by_user_id: req.user.sub,
    });

    // Audit log
    await db('audit_log').insert({
      id: genId(), tenant_id: req.tenantId, user_id: req.user.sub,
      action: 'staff.create', entity_type: 'user', entity_id: id,
      new_value_json: JSON.stringify({ email, role }),
      ip_address: req.ip,
    });

    const user = await db('users').where({ id }).first();
    return ok({
      ...user,
      password_hash: undefined,
      pin_hash: undefined,
      onboarding_link: `/auth/setup-password?token=${onboardingToken}`,
    });
  });

  // GET /staff — List all staff
  fastify.get('/', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { role, is_active, search, branch_id } = req.query;
    let query = tenantScope(db('users'), req.tenantId);
    if (role) query = query.where('role', role);
    if (is_active !== undefined) query = query.where('is_active', is_active === 'true');
    if (search) query = query.where(function () { this.where('first_name_fr', 'like', `%${search}%`).orWhere('last_name_fr', 'like', `%${search}%`).orWhere('email', 'like', `%${search}%`); });

    const total = await query.clone().count('id as count').first();
    const staff = await query.select('id', 'tenant_id', 'email', 'phone', 'first_name_fr', 'first_name_ar',
      'last_name_fr', 'last_name_ar', 'role', 'role_id', 'preferred_locale', 'is_active',
      'last_login_at', 'created_at')
      .orderBy('first_name_fr').limit(limit).offset(offset);

    // Get current shift status
    for (const s of staff) {
      const currentAttendance = await db('attendance')
        .where({ user_id: s.id, tenant_id: req.tenantId })
        .whereNull('clocked_out_at')
        .first();
      s.is_clocked_in = !!currentAttendance;
    }

    return paginate(staff, { page, limit, total: total?.count || 0 });
  });

  // PATCH /staff/:id
  fastify.patch('/:id', { preHandler: [verifyJWT, requirePermission('staff.manage')] }, async (req) => {
    const { id } = req.params;
    const user = await tenantScope(db('users'), req.tenantId).where({ id }).first();
    if (!user) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Employé introuvable', message_ar: 'الموظف غير موجود' };

    const allowed = ['first_name_fr', 'first_name_ar', 'last_name_fr', 'last_name_ar', 'phone', 'role', 'role_id', 'preferred_locale', 'is_active'];
    const updates = {};
    for (const k of allowed) if (req.body[k] !== undefined) updates[k] = req.body[k];

    if (req.body.pin) updates.pin_hash = await bcrypt.hash(req.body.pin, BCRYPT_ROUNDS);
    updates.updated_at = new Date();
    await db('users').where({ id }).update(updates);

    await db('audit_log').insert({
      id: genId(), tenant_id: req.tenantId, user_id: req.user.sub,
      action: 'staff.update', entity_type: 'user', entity_id: id,
      old_value_json: JSON.stringify({ role: user.role }),
      new_value_json: JSON.stringify(updates),
      ip_address: req.ip,
    });

    return ok(await db('users').where({ id }).select('id', 'email', 'first_name_fr', 'last_name_fr', 'role', 'is_active').first());
  });

  // POST /staff/:id/deactivate
  fastify.post('/:id/deactivate', { preHandler: [verifyJWT, requirePermission('staff.manage')] }, async (req) => {
    const { id } = req.params;
    await db('users').where({ id, tenant_id: req.tenantId }).update({ is_active: false, updated_at: new Date() });
    // Revoke all tokens
    await db('refresh_tokens').where({ user_id: id }).whereNull('revoked_at').update({ revoked_at: new Date() });
    return ok({ deactivated: true });
  });

  // GET /staff/schedule — Weekly rota
  fastify.get('/schedule', { preHandler: [verifyJWT] }, async (req) => {
    const { branch_id, week_start } = req.query;
    const branchId = branch_id || req.user.branch_id;
    const start = week_start ? new Date(week_start) : new Date();
    start.setDate(start.getDate() - start.getDay());
    start.setHours(0, 0, 0, 0);
    const end = new Date(start);
    end.setDate(end.getDate() + 7);

    let query = db('shifts').where({ tenant_id: req.tenantId }).where('start_time', '>=', start).where('start_time', '<', end);
    if (branchId) query = query.where('branch_id', branchId);
    const shifts = await query.orderBy('start_time');

    // Enrich with user names
    const userIds = [...new Set(shifts.map((s) => s.user_id))];
    const users = userIds.length ? await db('users').whereIn('id', userIds).select('id', 'first_name_fr', 'last_name_fr', 'role') : [];
    const userMap = {};
    for (const u of users) userMap[u.id] = u;

    return ok(shifts.map((s) => ({ ...s, user: userMap[s.user_id] || null })));
  });

  // POST /staff/schedule/shifts
  fastify.post('/schedule/shifts', { preHandler: [verifyJWT, requirePermission('staff.schedule')] }, async (req) => {
    const { user_id, branch_id, start_time, end_time, break_minutes } = req.body;
    const id = genId();
    await db('shifts').insert({
      id, tenant_id: req.tenantId,
      branch_id: branch_id || req.user.branch_id,
      user_id, start_time, end_time, break_minutes: break_minutes || 0,
    });
    return ok(await db('shifts').where({ id }).first());
  });

  // POST /attendance/clock-in
  fastify.post('/attendance/clock-in', { preHandler: [verifyJWT] }, async (req) => {
    const existing = await db('attendance')
      .where({ user_id: req.user.sub, tenant_id: req.tenantId })
      .whereNull('clocked_out_at').first();
    if (existing) throw { status: 409, code: 'ALREADY_CLOCKED', message_fr: 'Déjà pointé', message_ar: 'تم تسجيل الحضور مسبقاً' };

    const id = genId();
    const { method, device_id, shift_id } = req.body;
    await db('attendance').insert({
      id, tenant_id: req.tenantId, user_id: req.user.sub,
      shift_id, clocked_in_at: new Date(),
      clock_in_method: method || 'pin', ip_address: req.ip, device_id,
    });

    fastify.managerNs.to(`tenant:${req.tenantId}`).emit('staff:clocked_in', {
      user_id: req.user.sub, shift_id, clocked_in_at: new Date(),
    });

    return ok({ id, clocked_in_at: new Date() });
  });

  // POST /attendance/clock-out
  fastify.post('/attendance/clock-out', { preHandler: [verifyJWT] }, async (req) => {
    const record = await db('attendance')
      .where({ user_id: req.user.sub, tenant_id: req.tenantId })
      .whereNull('clocked_out_at').first();
    if (!record) throw { status: 404, code: 'NOT_CLOCKED', message_fr: 'Pas de pointage en cours', message_ar: 'لا يوجد تسجيل حضور حالي' };

    const clockedOut = new Date();
    const hoursWorked = (clockedOut - new Date(record.clocked_in_at)) / 3600000;
    await db('attendance').where({ id: record.id }).update({ clocked_out_at: clockedOut, hours_worked: Math.round(hoursWorked * 100) / 100 });

    return ok({ clocked_out_at: clockedOut, hours_worked: Math.round(hoursWorked * 100) / 100 });
  });

  // GET /staff/attendance
  fastify.get('/attendance', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { user_id, date_from, date_to } = req.query;
    let query = db('attendance').where({ tenant_id: req.tenantId });
    if (user_id) query = query.where('user_id', user_id);
    if (date_from) query = query.where('clocked_in_at', '>=', date_from);
    if (date_to) query = query.where('clocked_in_at', '<=', date_to);
    const total = await query.clone().count('id as count').first();
    return paginate(await query.orderBy('clocked_in_at', 'desc').limit(limit).offset(offset), { page, limit, total: total?.count || 0 });
  });

  // === Leave Requests ===
  fastify.post('/leave-requests', { preHandler: [verifyJWT] }, async (req) => {
    const id = genId();
    await db('leave_requests').insert({
      id, tenant_id: req.tenantId, user_id: req.user.sub, ...req.body,
    });
    return ok(await db('leave_requests').where({ id }).first());
  });

  fastify.get('/leave-requests', { preHandler: [verifyJWT] }, async (req) => {
    const { user_id, status } = req.query;
    let query = db('leave_requests').where({ tenant_id: req.tenantId });
    if (user_id) query = query.where('user_id', user_id);
    else if (req.user.role !== 'owner' && req.user.role !== 'manager') query = query.where('user_id', req.user.sub);
    if (status) query = query.where('status', status);
    return ok(await query.orderBy('created_at', 'desc'));
  });

  fastify.patch('/leave-requests/:id', { preHandler: [verifyJWT, requirePermission('staff.manage')] }, async (req) => {
    const { status, review_notes } = req.body;
    await db('leave_requests').where({ id: req.params.id, tenant_id: req.tenantId }).update({
      status, review_notes, reviewed_by_user_id: req.user.sub, updated_at: new Date(),
    });
    return ok(await db('leave_requests').where({ id: req.params.id }).first());
  });
}
