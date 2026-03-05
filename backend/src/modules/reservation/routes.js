import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';
import crypto from 'crypto';

export default async function reservationRoutes(fastify) {
  const db = fastify.knex;

  // GET /reservations (auth)
  fastify.get('/', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { branch_id, status, date, date_from, date_to } = req.query;
    const branchId = branch_id || req.user.branch_id;

    let query = db('reservations').where({ tenant_id: req.tenantId });
    if (branchId) query = query.where('branch_id', branchId);
    if (status) query = query.where('status', status);
    if (date) query = query.where('date', date);
    if (date_from) query = query.where('date', '>=', date_from);
    if (date_to) query = query.where('date', '<=', date_to);

    const total = await query.clone().count('id as count').first();
    const reservations = await query.orderBy('date').orderBy('time_slot').limit(limit).offset(offset);
    return paginate(reservations, { page, limit, total: total?.count || 0 });
  });

  // GET /reservations/public/:tenant — Public reservation (no auth)
  fastify.get('/public/:tenantSlug', async (req) => {
    const tenant = await db('tenants').where({ slug: req.params.tenantSlug }).first();
    if (!tenant) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Restaurant non trouvé', message_ar: 'المطعم غير موجود' };

    const branches = await db('branches').where({ tenant_id: tenant.id, is_active: true }).whereNull('deleted_at');
    return ok({ restaurant_name: tenant.name, branches: branches.map((b) => ({ id: b.id, name_fr: b.name_fr, name_ar: b.name_ar })) });
  });

  // POST /reservations
  fastify.post('/', { preHandler: [verifyJWT] }, async (req) => {
    const { branch_id, table_id, party_size, date, time_slot, duration_minutes, special_requests, customer_id, customer_name, customer_phone, customer_email, deposit_amount_cents } = req.body;

    const confirmationCode = crypto.randomBytes(4).toString('hex').toUpperCase();
    const id = genId();
    await db('reservations').insert({
      id, tenant_id: req.tenantId, branch_id: branch_id || req.user.branch_id,
      customer_id, table_id, party_size, date, time_slot,
      duration_minutes: duration_minutes || 90, special_requests,
      customer_name, customer_phone, customer_email,
      deposit_amount_cents: deposit_amount_cents || 0, confirmation_code: confirmationCode,
    });

    // If customer not linked, auto-create
    if (!customer_id && (customer_phone || customer_email)) {
      let existingCustomer = null;
      if (customer_phone) existingCustomer = await db('customers').where({ tenant_id: req.tenantId, phone: customer_phone }).first();
      if (!existingCustomer && customer_email) existingCustomer = await db('customers').where({ tenant_id: req.tenantId, email: customer_email }).first();
      if (!existingCustomer) {
        const custId = genId();
        await db('customers').insert({
          id: custId, tenant_id: req.tenantId,
          first_name: customer_name, phone: customer_phone, email: customer_email,
        });
        await db('reservations').where({ id }).update({ customer_id: custId });
      } else {
        await db('reservations').where({ id }).update({ customer_id: existingCustomer.id });
      }
    }

    return ok(await db('reservations').where({ id }).first());
  });

  // PATCH /reservations/:id
  fastify.patch('/:id', { preHandler: [verifyJWT] }, async (req) => {
    const { status, table_id } = req.body;
    const reservation = await db('reservations').where({ id: req.params.id, tenant_id: req.tenantId }).first();
    if (!reservation) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Réservation introuvable', message_ar: 'الحجز غير موجود' };

    const updates = { updated_at: new Date() };
    if (status) updates.status = status;
    if (table_id) updates.table_id = table_id;

    await db('reservations').where({ id: req.params.id }).update(updates);

    // If seated, update table and emit
    if (status === 'seated' && (table_id || reservation.table_id)) {
      const tid = table_id || reservation.table_id;
      await db('tables').where({ id: tid }).update({ status: 'reserved', updated_at: new Date() });
      fastify.posNs.to(`tenant:${req.tenantId}`).emit('reservation:arrived', {
        reservation_id: req.params.id, customer_name: reservation.customer_name,
        party_size: reservation.party_size, table_id: tid,
      });
    }

    return ok(await db('reservations').where({ id: req.params.id }).first());
  });

  // DELETE /reservations/:id (cancel)
  fastify.delete('/:id', { preHandler: [verifyJWT] }, async (req) => {
    await db('reservations').where({ id: req.params.id, tenant_id: req.tenantId }).update({ status: 'cancelled', updated_at: new Date() });
    return ok({ cancelled: true });
  });
}
