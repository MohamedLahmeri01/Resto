import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';

export default async function crmRoutes(fastify) {
  const db = fastify.knex;

  // GET /crm/customers
  fastify.get('/customers', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { search, loyalty_tier_id, min_visits, max_visits } = req.query;
    let query = db('customers').where({ tenant_id: req.tenantId });
    if (search) query = query.where(function () {
      this.where('first_name', 'like', `%${search}%`)
        .orWhere('last_name', 'like', `%${search}%`)
        .orWhere('phone', 'like', `%${search}%`)
        .orWhere('email', 'like', `%${search}%`);
    });
    if (loyalty_tier_id) query = query.where('loyalty_tier_id', loyalty_tier_id);
    if (min_visits) query = query.where('total_visits', '>=', parseInt(min_visits));
    if (max_visits) query = query.where('total_visits', '<=', parseInt(max_visits));

    const total = await query.clone().count('id as count').first();
    const customers = await query.orderBy('first_name').limit(limit).offset(offset);
    return paginate(customers, { page, limit, total: total?.count || 0 });
  });

  // GET /crm/customers/:id
  fastify.get('/customers/:id', { preHandler: [verifyJWT] }, async (req) => {
    const customer = await db('customers').where({ id: req.params.id, tenant_id: req.tenantId }).first();
    if (!customer) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Client introuvable', message_ar: 'العميل غير موجود' };
    const transactions = await db('loyalty_transactions').where({ customer_id: customer.id }).orderBy('created_at', 'desc').limit(20);
    const reservations = await db('reservations').where({ customer_id: customer.id }).orderBy('date', 'desc').limit(10);
    const orders = await db('orders').where({ customer_id: customer.id, tenant_id: req.tenantId }).orderBy('created_at', 'desc').limit(10);
    return ok({ ...customer, loyalty_transactions: transactions, recent_reservations: reservations, recent_orders: orders });
  });

  // POST /crm/customers
  fastify.post('/customers', { preHandler: [verifyJWT, requirePermission('crm.write')] }, async (req) => {
    const id = genId();
    await db('customers').insert({ id, tenant_id: req.tenantId, ...req.body });
    return ok(await db('customers').where({ id }).first());
  });

  // PUT /crm/customers/:id
  fastify.put('/customers/:id', { preHandler: [verifyJWT, requirePermission('crm.write')] }, async (req) => {
    await db('customers').where({ id: req.params.id, tenant_id: req.tenantId }).update({ ...req.body, updated_at: new Date() });
    return ok(await db('customers').where({ id: req.params.id }).first());
  });

  // DELETE /crm/customers/:id — GDPR anonymize
  fastify.delete('/customers/:id', { preHandler: [verifyJWT, requirePermission('crm.delete')] }, async (req) => {
    const { id } = req.params;
    await db('customers').where({ id, tenant_id: req.tenantId }).update({
      first_name: `anonymized_customer_${id.slice(0, 8)}`,
      last_name: null, email: null, phone: null, birthday: null,
      dietary_notes: null, updated_at: new Date(),
    });
    return ok({ anonymized: true });
  });

  // === Loyalty Tiers ===
  fastify.get('/loyalty-tiers', { preHandler: [verifyJWT] }, async (req) => {
    return ok(await db('loyalty_tiers').where({ tenant_id: req.tenantId }).orderBy('min_points'));
  });

  fastify.post('/loyalty-tiers', { preHandler: [verifyJWT, requirePermission('crm.write')] }, async (req) => {
    const id = genId();
    await db('loyalty_tiers').insert({ id, tenant_id: req.tenantId, ...req.body });
    return ok(await db('loyalty_tiers').where({ id }).first());
  });

  fastify.put('/loyalty-tiers/:id', { preHandler: [verifyJWT, requirePermission('crm.write')] }, async (req) => {
    await db('loyalty_tiers').where({ id: req.params.id, tenant_id: req.tenantId }).update({ ...req.body, updated_at: new Date() });
    return ok(await db('loyalty_tiers').where({ id: req.params.id }).first());
  });

  // === Loyalty Transactions ===
  fastify.get('/loyalty/:customerId/transactions', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const query = db('loyalty_transactions').where({ customer_id: req.params.customerId, tenant_id: req.tenantId });
    const total = await query.clone().count('id as count').first();
    return paginate(await query.orderBy('created_at', 'desc').limit(limit).offset(offset), { page, limit, total: total?.count || 0 });
  });

  // POST /crm/loyalty/:customerId/redeem — Redeem points
  fastify.post('/loyalty/:customerId/redeem', { preHandler: [verifyJWT, requirePermission('crm.loyalty')] }, async (req) => {
    const { points, order_id, description } = req.body;
    const customer = await db('customers').where({ id: req.params.customerId, tenant_id: req.tenantId }).first();
    if (!customer) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Client introuvable', message_ar: 'العميل غير موجود' };
    if (customer.loyalty_points < points) throw { status: 422, code: 'INSUFFICIENT_POINTS', message_fr: 'Points insuffisants', message_ar: 'نقاط غير كافية' };

    const newBalance = customer.loyalty_points - points;
    await db('customers').where({ id: customer.id }).update({ loyalty_points: newBalance, updated_at: new Date() });
    const id = genId();
    await db('loyalty_transactions').insert({
      id, tenant_id: req.tenantId, customer_id: customer.id, order_id,
      points_delta: -points, balance_after: newBalance,
      transaction_type: 'redeem', description,
    });
    return ok({ transaction_id: id, points_redeemed: points, new_balance: newBalance });
  });

  // GET /crm/customers/lookup?phone=xxx
  fastify.get('/customers/lookup', { preHandler: [verifyJWT] }, async (req) => {
    const { phone, email } = req.query;
    let customer = null;
    if (phone) customer = await db('customers').where({ tenant_id: req.tenantId, phone }).first();
    if (!customer && email) customer = await db('customers').where({ tenant_id: req.tenantId, email }).first();
    return ok(customer);
  });
}
