import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination } from '../../utils/helpers.js';

export default async function financeRoutes(fastify) {
  const db = fastify.knex;

  // GET /finance/cash-reconciliation
  fastify.get('/cash-reconciliation', { preHandler: [verifyJWT, requirePermission('finance.view')] }, async (req) => {
    const { date, branch_id } = req.query;
    const targetDate = date || new Date().toISOString().slice(0, 10);
    const branchId = branch_id || req.user.branch_id;
    const dayStart = new Date(`${targetDate}T00:00:00`);
    const dayEnd = new Date(`${targetDate}T23:59:59`);

    // Cash payments today
    let cashQuery = db('payments')
      .where({ tenant_id: req.tenantId, method: 'cash', status: 'captured' })
      .where('created_at', '>=', dayStart)
      .where('created_at', '<=', dayEnd);

    const cashIn = await cashQuery.clone().where('amount_cents', '>', 0).sum('amount_cents as total').first();
    const cashOut = await cashQuery.clone().where('amount_cents', '<', 0).sum('amount_cents as total').first();
    const cashRefunds = Math.abs(cashOut?.total || 0);

    // Opening float from config
    const floatConfig = await db('tenant_config').where({ tenant_id: req.tenantId, key: 'opening_float_cents' }).first();
    const openingFloat = floatConfig ? parseInt(JSON.parse(floatConfig.value_json)) : 0;

    const expectedCash = openingFloat + (cashIn?.total || 0) - cashRefunds;

    return ok({
      date: targetDate,
      opening_float_cents: openingFloat,
      cash_sales_cents: cashIn?.total || 0,
      cash_refunds_cents: cashRefunds,
      expected_cash_cents: expectedCash,
    });
  });

  // POST /finance/cash-reconciliation — Submit count
  fastify.post('/cash-reconciliation', { preHandler: [verifyJWT, requirePermission('finance.reconcile')] }, async (req) => {
    const { date, physical_cash_cents, notes } = req.body;

    // Get expected
    const recon = await fastify.inject({ method: 'GET', url: `/v1/finance/cash-reconciliation?date=${date}`, headers: req.headers });
    const expected = JSON.parse(recon.body).data;

    const variance = physical_cash_cents - expected.expected_cash_cents;

    await db('audit_log').insert({
      id: genId(), tenant_id: req.tenantId, user_id: req.user.sub,
      action: 'finance.cash_reconciliation', entity_type: 'reconciliation',
      new_value_json: JSON.stringify({
        date, physical_cash_cents, expected_cash_cents: expected.expected_cash_cents,
        variance_cents: variance, notes,
      }),
      ip_address: req.ip,
    });

    return ok({
      date,
      physical_cash_cents,
      expected_cash_cents: expected.expected_cash_cents,
      variance_cents: variance,
      status: variance === 0 ? 'balanced' : variance > 0 ? 'over' : 'short',
    });
  });

  // GET /finance/z-report — End of day report
  fastify.get('/z-report', { preHandler: [verifyJWT, requirePermission('finance.view')] }, async (req) => {
    const { date, branch_id } = req.query;
    const targetDate = date || new Date().toISOString().slice(0, 10);
    const branchId = branch_id || req.user.branch_id;
    const dayStart = new Date(`${targetDate}T00:00:00`);
    const dayEnd = new Date(`${targetDate}T23:59:59`);

    // Orders summary
    let ordersQuery = db('orders')
      .where({ tenant_id: req.tenantId })
      .where('created_at', '>=', dayStart).where('created_at', '<=', dayEnd);
    if (branchId) ordersQuery = ordersQuery.where('branch_id', branchId);

    const allOrders = await ordersQuery;
    const closed = allOrders.filter((o) => o.status === 'closed');
    const voided = allOrders.filter((o) => o.status === 'voided');
    const refunded = allOrders.filter((o) => o.status === 'refunded');

    const totalRevenue = closed.reduce((s, o) => s + o.total_cents, 0);
    const totalTax = closed.reduce((s, o) => s + o.tax_cents, 0);
    const totalDiscount = closed.reduce((s, o) => s + o.discount_cents, 0);
    const totalVoided = voided.reduce((s, o) => s + o.total_cents, 0);

    // Payment breakdown
    const payments = await db('payments')
      .where({ tenant_id: req.tenantId, status: 'captured' })
      .where('created_at', '>=', dayStart).where('created_at', '<=', dayEnd)
      .groupBy('method')
      .select('method')
      .sum('amount_cents as total_cents')
      .count('id as count');

    return ok({
      date: targetDate,
      total_orders: allOrders.length,
      closed_orders: closed.length,
      voided_orders: voided.length,
      refunded_orders: refunded.length,
      gross_revenue_cents: totalRevenue,
      total_tax_cents: totalTax,
      total_discount_cents: totalDiscount,
      total_voided_cents: totalVoided,
      net_revenue_cents: totalRevenue - totalDiscount,
      payment_breakdown: payments,
      covers: closed.reduce((s, o) => s + (o.covers_count || 0), 0),
      avg_check_cents: closed.length ? Math.round(totalRevenue / closed.length) : 0,
    });
  });

  // GET /finance/tax-summary
  fastify.get('/tax-summary', { preHandler: [verifyJWT, requirePermission('finance.view')] }, async (req) => {
    const { date_from, date_to } = req.query;
    let query = db('orders').where({ tenant_id: req.tenantId, status: 'closed' });
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);

    const summary = await query
      .select(
        db.raw('SUM(subtotal_cents) as taxable_sales_cents'),
        db.raw('SUM(tax_cents) as tax_collected_cents'),
        db.raw('COUNT(id) as order_count'),
      ).first();

    return ok(summary);
  });

  // GET /finance/daily-journal — Accounting export
  fastify.get('/daily-journal', { preHandler: [verifyJWT, requirePermission('finance.export')] }, async (req) => {
    const { date } = req.query;
    const targetDate = date || new Date().toISOString().slice(0, 10);
    const dayStart = new Date(`${targetDate}T00:00:00`);
    const dayEnd = new Date(`${targetDate}T23:59:59`);

    const revenue = await db('orders')
      .where({ tenant_id: req.tenantId, status: 'closed' })
      .where('created_at', '>=', dayStart).where('created_at', '<=', dayEnd)
      .select(
        db.raw('SUM(subtotal_cents) as revenue_cents'),
        db.raw('SUM(tax_cents) as tax_cents'),
        db.raw('SUM(discount_cents) as discount_cents'),
      ).first();

    const refunds = await db('payments')
      .where({ tenant_id: req.tenantId, status: 'refunded' })
      .where('created_at', '>=', dayStart).where('created_at', '<=', dayEnd)
      .sum('amount_cents as total').first();

    return ok({
      date: targetDate,
      revenue_cents: revenue?.revenue_cents || 0,
      tax_collected_cents: revenue?.tax_cents || 0,
      discount_given_cents: revenue?.discount_cents || 0,
      refund_cents: Math.abs(refunds?.total || 0),
      format: 'compatible with QuickBooks, Xero, Sage',
    });
  });
}
