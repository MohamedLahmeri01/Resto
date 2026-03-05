import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';

export default async function paymentRoutes(fastify) {
  const db = fastify.knex;

  // POST /orders/:id/payments — Process payment
  fastify.post('/:orderId/pay', { preHandler: [verifyJWT, requirePermission('payments.create')] }, async (req) => {
    const { orderId } = req.params;
    const order = await tenantScope(db('orders'), req.tenantId).where({ id: orderId }).first();
    if (!order) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Commande introuvable', message_ar: 'الطلب غير موجود' };
    if (['closed', 'voided', 'refunded'].includes(order.status)) {
      throw { status: 409, code: 'ORDER_CLOSED', message_fr: 'Commande déjà finalisée', message_ar: 'الطلب مغلق بالفعل' };
    }

    const { method, amount_cents, reference } = req.body;
    const paymentId = genId();

    // Calculate already paid
    const paid = await db('payments')
      .where({ order_id: orderId, status: 'captured' })
      .sum('amount_cents as total').first();
    const alreadyPaid = paid?.total || 0;
    const remaining = order.total_cents - alreadyPaid;

    if (amount_cents > remaining + 100) { // +100 centimes tolerance for rounding
      throw { status: 422, code: 'OVERPAYMENT', message_fr: 'Montant supérieur au solde restant', message_ar: 'المبلغ يتجاوز الرصيد المتبقي' };
    }

    const changeCents = method === 'cash' && amount_cents > remaining ? amount_cents - remaining : 0;
    const capturedAmount = Math.min(amount_cents, remaining);

    await db('payments').insert({
      id: paymentId,
      order_id: orderId,
      tenant_id: req.tenantId,
      method,
      amount_cents: capturedAmount,
      reference,
      status: 'captured',
      cashier_id: req.user.sub,
      change_cents: changeCents,
      processed_at: new Date(),
    });

    // Check if fully paid
    const totalPaid = alreadyPaid + capturedAmount;
    if (totalPaid >= order.total_cents) {
      await db('orders').where({ id: orderId }).update({
        status: 'closed', closed_at: new Date(), updated_at: new Date(),
      });

      // Free up table
      if (order.table_id) {
        await db('tables').where({ id: order.table_id }).update({
          status: 'cleaning', current_order_id: null, occupied_since: null, updated_at: new Date(),
        });
        fastify.posNs.to(`tenant:${req.tenantId}`).emit('table:status_changed', {
          table_id: order.table_id, old_status: 'occupied', new_status: 'cleaning',
        });
      }

      // Update customer stats if linked
      if (order.customer_id) {
        await db('customers').where({ id: order.customer_id }).increment({
          total_visits: 1,
          lifetime_spend_cents: order.total_cents,
        }).update({ last_visit_at: new Date(), updated_at: new Date() });

        // Award loyalty points
        const loyaltyConfig = await db('tenant_config').where({ tenant_id: req.tenantId, key: 'points_per_currency_unit' }).first();
        if (loyaltyConfig) {
          const ppcu = parseFloat(JSON.parse(loyaltyConfig.value_json)) || 0;
          if (ppcu > 0) {
            const pointsEarned = Math.floor(order.total_cents / 100 / ppcu);
            if (pointsEarned > 0) {
              const customer = await db('customers').where({ id: order.customer_id }).first();
              const newBalance = (customer?.loyalty_points || 0) + pointsEarned;
              await db('customers').where({ id: order.customer_id }).update({ loyalty_points: newBalance });
              await db('loyalty_transactions').insert({
                id: genId(), tenant_id: req.tenantId, customer_id: order.customer_id,
                order_id: orderId, points_delta: pointsEarned, balance_after: newBalance,
                transaction_type: 'earn', description: `Commande ${order.order_number}`,
              });
            }
          }
        }
      }
    }

    // Emit payment event
    fastify.posNs.to(`tenant:${req.tenantId}`).emit('payment:captured', {
      order_id: orderId, amount_cents: capturedAmount, method, change_cents: changeCents,
    });

    // Audit
    await db('audit_log').insert({
      id: genId(), tenant_id: req.tenantId, user_id: req.user.sub,
      action: 'payment.capture', entity_type: 'payment', entity_id: paymentId,
      new_value_json: JSON.stringify({ order_id: orderId, method, amount_cents: capturedAmount }),
      ip_address: req.ip,
    });

    return ok({
      payment_id: paymentId,
      amount_cents: capturedAmount,
      change_cents: changeCents,
      remaining_cents: Math.max(0, order.total_cents - totalPaid),
      order_status: totalPaid >= order.total_cents ? 'closed' : order.status,
    });
  });

  // GET /payments/order/:orderId
  fastify.get('/order/:orderId', { preHandler: [verifyJWT] }, async (req) => {
    const payments = await db('payments').where({ order_id: req.params.orderId, tenant_id: req.tenantId });
    const order = await db('orders').where({ id: req.params.orderId }).first();
    const totalPaid = payments.filter((p) => p.status === 'captured').reduce((s, p) => s + p.amount_cents, 0);
    return ok({
      payments,
      total_due_cents: order?.total_cents || 0,
      total_paid_cents: totalPaid,
      remaining_cents: Math.max(0, (order?.total_cents || 0) - totalPaid),
    });
  });
}
