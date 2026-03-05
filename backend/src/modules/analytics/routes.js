import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { ok } from '../../utils/helpers.js';

export default async function analyticsRoutes(fastify) {
  const db = fastify.knex;
  const redis = fastify.redis;

  // GET /analytics/dashboard — KPIs (cached)
  fastify.get('/dashboard', { preHandler: [verifyJWT, requirePermission('reports.view')] }, async (req) => {
    const branchId = req.query.branch_id || req.user.branch_id;
    const date = req.query.date || new Date().toISOString().slice(0, 10);
    const cacheKey = `kpi:${req.tenantId}:${branchId || 'all'}:${date}`;

    const cached = await redis.get(cacheKey);
    if (cached) return ok(JSON.parse(cached));

    const dayStart = new Date(`${date}T00:00:00`);
    const dayEnd = new Date(`${date}T23:59:59`);

    let ordersQuery = db('orders')
      .where({ tenant_id: req.tenantId })
      .where('created_at', '>=', dayStart)
      .where('created_at', '<=', dayEnd)
      .whereNotIn('status', ['voided', 'draft']);
    if (branchId) ordersQuery = ordersQuery.where('branch_id', branchId);

    const orders = await ordersQuery;
    const closedOrders = orders.filter((o) => o.status === 'closed');

    const revenue = closedOrders.reduce((s, o) => s + o.total_cents, 0);
    const covers = closedOrders.reduce((s, o) => s + (o.covers_count || 1), 0);
    const avgCheck = closedOrders.length ? Math.round(revenue / closedOrders.length) : 0;

    // Top items today
    const topItems = await db('order_items as oi')
      .join('orders as o', 'o.id', 'oi.order_id')
      .where('o.tenant_id', req.tenantId)
      .where('o.created_at', '>=', dayStart)
      .where('o.created_at', '<=', dayEnd)
      .whereNotIn('o.status', ['voided'])
      .groupBy('oi.item_id', 'oi.name_fr', 'oi.name_ar')
      .select('oi.item_id', 'oi.name_fr', 'oi.name_ar')
      .count('oi.id as qty')
      .sum('oi.total_price_cents as revenue_cents')
      .orderBy('qty', 'desc')
      .limit(10);

    // Low stock alerts
    const lowStock = await db('ingredients')
      .where({ tenant_id: req.tenantId })
      .whereRaw('current_stock <= par_level')
      .whereNull('deleted_at')
      .select('id', 'name_fr', 'name_ar', 'current_stock', 'par_level', 'unit')
      .limit(10);

    // Pending reservations today
    const pendingReservations = await db('reservations')
      .where({ tenant_id: req.tenantId, date })
      .whereIn('status', ['pending', 'confirmed'])
      .count('id as count').first();

    // Order type breakdown
    const byType = {};
    for (const o of closedOrders) {
      byType[o.order_type] = (byType[o.order_type] || 0) + 1;
    }

    // Payment method breakdown
    const paymentBreakdown = await db('payments as p')
      .join('orders as o', 'o.id', 'p.order_id')
      .where('p.tenant_id', req.tenantId)
      .where('p.created_at', '>=', dayStart)
      .where('p.created_at', '<=', dayEnd)
      .where('p.status', 'captured')
      .groupBy('p.method')
      .select('p.method')
      .sum('p.amount_cents as total_cents')
      .count('p.id as count');

    const kpis = {
      date,
      total_orders: orders.length,
      closed_orders: closedOrders.length,
      revenue_cents: revenue,
      covers,
      avg_check_cents: avgCheck,
      top_items: topItems,
      low_stock_alerts: lowStock,
      pending_reservations: pendingReservations?.count || 0,
      order_type_breakdown: byType,
      payment_breakdown: paymentBreakdown,
    };

    await redis.setex(cacheKey, 60, JSON.stringify(kpis));
    return ok(kpis);
  });

  // GET /analytics/sales-summary
  fastify.get('/sales-summary', { preHandler: [verifyJWT, requirePermission('reports.view')] }, async (req) => {
    const { date_from, date_to, branch_id, waiter_id, order_type } = req.query;
    let query = db('orders').where({ tenant_id: req.tenantId }).where('status', 'closed');
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);
    if (branch_id) query = query.where('branch_id', branch_id);
    if (waiter_id) query = query.where('waiter_id', waiter_id);
    if (order_type) query = query.where('order_type', order_type);

    const summary = await query.select(
      db.raw('COUNT(id) as total_orders'),
      db.raw('SUM(subtotal_cents) as subtotal_cents'),
      db.raw('SUM(discount_cents) as discount_cents'),
      db.raw('SUM(tax_cents) as tax_cents'),
      db.raw('SUM(total_cents) as revenue_cents'),
      db.raw('SUM(covers_count) as total_covers'),
    ).first();

    // Per-category breakdown
    const byCategory = await db('order_items as oi')
      .join('orders as o', 'o.id', 'oi.order_id')
      .join('menu_items as mi', 'mi.id', 'oi.item_id')
      .join('menu_categories as mc', 'mc.id', 'mi.category_id')
      .where('o.tenant_id', req.tenantId).where('o.status', 'closed')
      .modify((qb) => {
        if (date_from) qb.where('o.created_at', '>=', date_from);
        if (date_to) qb.where('o.created_at', '<=', date_to);
      })
      .groupBy('mc.id', 'mc.name_fr', 'mc.name_ar')
      .select('mc.id', 'mc.name_fr', 'mc.name_ar')
      .count('oi.id as items_sold')
      .sum('oi.total_price_cents as revenue_cents');

    return ok({ ...summary, by_category: byCategory });
  });

  // GET /analytics/hourly-heatmap
  fastify.get('/hourly-heatmap', { preHandler: [verifyJWT, requirePermission('reports.view')] }, async (req) => {
    const { date_from, date_to, branch_id } = req.query;
    let query = db('orders')
      .where({ tenant_id: req.tenantId, status: 'closed' });
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);
    if (branch_id) query = query.where('branch_id', branch_id);

    const orders = await query.select('created_at', 'total_cents', 'covers_count');
    const heatmap = {};
    for (const o of orders) {
      const dt = new Date(o.created_at);
      const day = dt.getDay();
      const hour = dt.getHours();
      const key = `${day}-${hour}`;
      if (!heatmap[key]) heatmap[key] = { day, hour, orders: 0, revenue_cents: 0, covers: 0 };
      heatmap[key].orders++;
      heatmap[key].revenue_cents += o.total_cents;
      heatmap[key].covers += o.covers_count || 1;
    }
    return ok(Object.values(heatmap));
  });

  // GET /analytics/voids-refunds
  fastify.get('/voids-refunds', { preHandler: [verifyJWT, requirePermission('reports.view')] }, async (req) => {
    const { date_from, date_to } = req.query;
    let query = db('orders').where({ tenant_id: req.tenantId }).whereIn('status', ['voided', 'refunded']);
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);
    const orders = await query.orderBy('created_at', 'desc');

    // Get associated audit logs for who authorized
    for (const o of orders) {
      const audit = await db('audit_log')
        .where({ entity_type: 'order', entity_id: o.id })
        .whereIn('action', ['order.void', 'order.refund'])
        .first();
      o.authorized_by = audit?.user_id;
    }
    return ok(orders);
  });

  // GET /analytics/staff-hours
  fastify.get('/staff-hours', { preHandler: [verifyJWT, requirePermission('reports.view')] }, async (req) => {
    const { date_from, date_to } = req.query;
    let query = db('attendance')
      .where({ tenant_id: req.tenantId })
      .whereNotNull('clocked_out_at');
    if (date_from) query = query.where('clocked_in_at', '>=', date_from);
    if (date_to) query = query.where('clocked_in_at', '<=', date_to);

    const records = await query
      .join('users as u', 'u.id', 'attendance.user_id')
      .groupBy('attendance.user_id', 'u.first_name_fr', 'u.last_name_fr', 'u.role')
      .select('attendance.user_id', 'u.first_name_fr', 'u.last_name_fr', 'u.role')
      .sum('attendance.hours_worked as total_hours')
      .count('attendance.id as days_worked');

    return ok(records);
  });

  // GET /analytics/discount-usage
  fastify.get('/discount-usage', { preHandler: [verifyJWT, requirePermission('reports.view')] }, async (req) => {
    const { date_from, date_to } = req.query;
    let query = db('discounts_applied').where({ tenant_id: req.tenantId });
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);

    const usage = await query
      .groupBy('discount_rule_id', 'discount_type')
      .select('discount_rule_id', 'discount_type')
      .count('id as redemptions')
      .sum('amount_cents as total_discount_cents');

    return ok(usage);
  });
}
