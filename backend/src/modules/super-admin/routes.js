import bcrypt from 'bcrypt';
import { verifyJWT } from '../../middleware/verifyJWT.js';
import { genId, ok, paginate, parsePagination } from '../../utils/helpers.js';
import crypto from 'crypto';

const BCRYPT_ROUNDS = 12;

// Super-admin guard
async function requireSuperAdmin(request, reply) {
  if (!request.user || request.user.role !== 'super_admin') {
    return reply.code(403).send({
      success: false,
      error: { code: 'SUPER_ADMIN_REQUIRED', message_fr: 'Accès super admin requis', message_ar: 'مطلوب صلاحيات المشرف العام' },
    });
  }
}

export default async function superAdminRoutes(fastify) {
  const db = fastify.knex;

  // All routes require super admin
  fastify.addHook('preHandler', verifyJWT);
  fastify.addHook('preHandler', requireSuperAdmin);

  // GET /super-admin/tenants — List all tenants
  fastify.get('/tenants', async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { status, search } = req.query;
    let query = db('tenants').whereNull('deleted_at');
    if (status) query = query.where('status', status);
    if (search) query = query.where(function () { this.where('name', 'like', `%${search}%`).orWhere('slug', 'like', `%${search}%`); });
    const total = await query.clone().count('id as count').first();
    const tenants = await query.orderBy('created_at', 'desc').limit(limit).offset(offset);

    // Add user count
    for (const t of tenants) {
      const uc = await db('users').where({ tenant_id: t.id }).whereNull('deleted_at').count('id as count').first();
      t.user_count = uc?.count || 0;
    }
    return paginate(tenants, { page, limit, total: total?.count || 0 });
  });

  // POST /super-admin/tenants — Create new tenant
  fastify.post('/tenants', async (req) => {
    const { name, slug, admin_email, plan_tier, country_code, currency_code, timezone } = req.body;

    // Check slug uniqueness
    const existing = await db('tenants').where({ slug }).first();
    if (existing) throw { status: 409, code: 'SLUG_EXISTS', message_fr: 'Ce slug est déjà utilisé', message_ar: 'هذا المعرف مستخدم بالفعل' };

    // Get plan
    const plan = plan_tier ? await db('subscription_plans').where({ name: plan_tier }).first() : null;

    // Create tenant
    const tenantId = genId();
    await db('tenants').insert({
      id: tenantId, name, slug,
      plan_id: plan?.id || null,
      plan_tier: plan_tier || 'starter',
      status: 'onboarding',
      billing_email: admin_email,
      country_code: country_code || 'DZ',
      currency_code: currency_code || 'DZD',
      timezone: timezone || 'Africa/Algiers',
      max_branches: plan?.max_branches || 1,
      subscription_start: new Date(),
      subscription_end: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000), // 30-day trial
    });

    // Create default roles
    const roles = [
      { name: 'owner', permissions: ['*'], is_system: true },
      { name: 'manager', permissions: ['orders.*', 'menu.*', 'tables.*', 'staff.*', 'inventory.*', 'reports.*', 'crm.*', 'finance.*', 'kds.*'], is_system: true },
      { name: 'cashier', permissions: ['orders.create', 'orders.update', 'payments.create', 'tables.update', 'menu.read', 'kds.bump'], is_system: true },
      { name: 'waiter', permissions: ['orders.create', 'orders.update', 'tables.update', 'menu.read'], is_system: true },
      { name: 'chef', permissions: ['kds.bump', 'menu.read', 'inventory.read'], is_system: true },
    ];

    const ownerRoleId = genId();
    for (const r of roles) {
      const rid = r.name === 'owner' ? ownerRoleId : genId();
      await db('roles').insert({
        id: rid, tenant_id: tenantId, name: r.name,
        permissions_json: JSON.stringify(r.permissions),
        is_system_role: r.is_system,
      });
    }

    // Create admin user
    const adminId = genId();
    const onboardingToken = crypto.randomBytes(32).toString('hex');
    await db('users').insert({
      id: adminId, tenant_id: tenantId,
      email: admin_email.toLowerCase(), role: 'owner', role_id: ownerRoleId,
      is_active: true, preferred_locale: 'fr',
      onboarding_token: onboardingToken,
      onboarding_token_expires_at: new Date(Date.now() + 48 * 60 * 60 * 1000),
    });

    // Default config
    const defaults = [
      { key: 'default_locale', value: 'fr' },
      { key: 'tax_rate', value: 19 },
      { key: 'table_turn_alert_minutes', value: 90 },
      { key: 'low_stock_default_par', value: 10 },
      { key: 'opening_float_cents', value: 500000 },
      { key: 'receipt_footer_fr', value: 'Merci de votre visite !' },
      { key: 'receipt_footer_ar', value: 'شكراً لزيارتكم!' },
    ];
    for (const d of defaults) {
      await db('tenant_config').insert({
        id: genId(), tenant_id: tenantId, key: d.key,
        value_json: JSON.stringify(d.value),
      });
    }

    return ok({
      tenant_id: tenantId,
      admin_user_id: adminId,
      onboarding_link: `/auth/setup-password?token=${onboardingToken}`,
      status: 'onboarding',
    });
  });

  // PATCH /super-admin/tenants/:id — Update tenant (suspend, reactivate, etc.)
  fastify.patch('/tenants/:id', async (req) => {
    const { status, plan_tier, max_branches } = req.body;
    const updates = { updated_at: new Date() };
    if (status) updates.status = status;
    if (plan_tier) updates.plan_tier = plan_tier;
    if (max_branches) updates.max_branches = max_branches;
    await db('tenants').where({ id: req.params.id }).update(updates);
    return ok(await db('tenants').where({ id: req.params.id }).first());
  });

  // GET /super-admin/metrics — Platform metrics
  fastify.get('/metrics', async () => {
    const totalTenants = await db('tenants').whereNull('deleted_at').count('id as count').first();
    const activeTenants = await db('tenants').where({ status: 'active' }).count('id as count').first();
    const totalUsers = await db('users').whereNull('deleted_at').count('id as count').first();

    const todayOrders = await db('orders')
      .where('created_at', '>=', new Date(new Date().setHours(0, 0, 0, 0)))
      .count('id as count').first();

    const planBreakdown = await db('tenants')
      .whereNull('deleted_at')
      .groupBy('plan_tier')
      .select('plan_tier')
      .count('id as count');

    return ok({
      total_tenants: totalTenants?.count || 0,
      active_tenants: activeTenants?.count || 0,
      total_users: totalUsers?.count || 0,
      today_orders: todayOrders?.count || 0,
      plan_breakdown: planBreakdown,
    });
  });

  // GET /super-admin/subscription-plans
  fastify.get('/subscription-plans', async () => {
    return ok(await db('subscription_plans').orderBy('monthly_price_cents'));
  });

  // POST /super-admin/subscription-plans
  fastify.post('/subscription-plans', async (req) => {
    const id = genId();
    await db('subscription_plans').insert({ id, ...req.body });
    return ok(await db('subscription_plans').where({ id }).first());
  });
}
