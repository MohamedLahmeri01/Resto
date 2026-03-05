import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok } from '../../utils/helpers.js';

export default async function kitchenRoutes(fastify) {
  const db = fastify.knex;

  // GET /kds/tickets — Active tickets for a station
  fastify.get('/tickets', { preHandler: [verifyJWT] }, async (req) => {
    const { station, branch_id } = req.query;
    const branchId = branch_id || req.user.branch_id;

    let query = db('order_items as oi')
      .join('orders as o', 'o.id', 'oi.order_id')
      .where('o.tenant_id', req.tenantId)
      .whereIn('oi.status', ['pending', 'fired', 'in_progress'])
      .whereNotIn('o.status', ['voided', 'closed', 'refunded']);

    if (branchId) query = query.where('o.branch_id', branchId);
    if (station) query = query.where('oi.prep_station', station);

    query = query.select(
      'o.id as order_id', 'o.order_number', 'o.table_id', 'o.covers_count',
      'o.created_at as order_created_at', 'o.order_type', 'o.notes as order_notes',
      'oi.id as item_id', 'oi.name_fr', 'oi.name_ar', 'oi.quantity',
      'oi.notes as item_notes', 'oi.status as item_status', 'oi.course_number',
      'oi.seat_number', 'oi.prep_station', 'oi.fired_at', 'oi.allergen_alert',
    ).orderBy('o.created_at', 'asc');

    const rows = await query;

    // Group by order
    const ticketMap = {};
    for (const row of rows) {
      if (!ticketMap[row.order_id]) {
        // Get table info
        let tableNumber = null;
        if (row.table_id) {
          const table = await db('tables').where({ id: row.table_id }).first();
          tableNumber = table?.table_number;
        }
        ticketMap[row.order_id] = {
          order_id: row.order_id,
          order_number: row.order_number,
          table_id: row.table_id,
          table_number: tableNumber,
          covers_count: row.covers_count,
          order_type: row.order_type,
          order_notes: row.order_notes,
          created_at: row.order_created_at,
          items: [],
        };
      }

      // Get modifiers for this item
      const modifiers = await db('order_item_modifiers').where({ order_item_id: row.item_id });

      ticketMap[row.order_id].items.push({
        id: row.item_id,
        name_fr: row.name_fr,
        name_ar: row.name_ar,
        quantity: row.quantity,
        notes: row.item_notes,
        status: row.item_status,
        course_number: row.course_number,
        seat_number: row.seat_number,
        prep_station: row.prep_station,
        fired_at: row.fired_at,
        allergen_alert: row.allergen_alert,
        modifiers,
      });
    }

    return ok(Object.values(ticketMap));
  });

  // PATCH /kds/tickets/:orderId/items/:itemId/bump — Mark item as ready
  fastify.patch('/tickets/:orderId/items/:itemId/bump', {
    preHandler: [verifyJWT, requirePermission('kds.bump')],
  }, async (req) => {
    const { orderId, itemId } = req.params;
    const item = await db('order_items').where({ id: itemId, order_id: orderId }).first();
    if (!item) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Article introuvable', message_ar: 'العنصر غير موجود' };

    await db('order_items').where({ id: itemId }).update({
      status: 'ready', ready_at: new Date(), updated_at: new Date(),
    });

    // Calculate cook time
    const firedAt = item.fired_at ? new Date(item.fired_at) : new Date(item.created_at);
    const cookTimeSeconds = Math.round((Date.now() - firedAt.getTime()) / 1000);

    // Emit bump event
    fastify.posNs.to(`tenant:${req.tenantId}`).emit('kds:item_bumped', {
      order_id: orderId, item_id: itemId, station: item.prep_station, cook_time_seconds: cookTimeSeconds,
    });
    fastify.managerNs.to(`tenant:${req.tenantId}`).emit('kds:item_bumped', {
      order_id: orderId, item_id: itemId, station: item.prep_station, cook_time_seconds: cookTimeSeconds,
    });

    // Check if all items for this order on this station are ready
    const remaining = await db('order_items')
      .where({ order_id: orderId, prep_station: item.prep_station })
      .whereIn('status', ['pending', 'fired', 'in_progress'])
      .count('id as c').first();

    if (remaining?.c === 0) {
      // Station complete — check if whole order is ready
      const allRemaining = await db('order_items')
        .where({ order_id: orderId })
        .whereIn('status', ['pending', 'fired', 'in_progress'])
        .count('id as c').first();

      if (allRemaining?.c === 0) {
        // All items ready — update order status
        await db('orders').where({ id: orderId }).update({ status: 'ready', updated_at: new Date() });
        fastify.posNs.to(`tenant:${req.tenantId}`).emit('kds:ticket_complete', { order_id: orderId });
        fastify.posNs.to(`tenant:${req.tenantId}`).emit('order:ready', {
          order_id: orderId,
          table_id: (await db('orders').where({ id: orderId }).first())?.table_id,
        });
      }
    }

    return ok({ bumped: true, cook_time_seconds: cookTimeSeconds });
  });

  // PATCH /kds/tickets/:orderId/bump-all — Bump all items on a ticket
  fastify.patch('/tickets/:orderId/bump-all', {
    preHandler: [verifyJWT, requirePermission('kds.bump')],
  }, async (req) => {
    const { orderId } = req.params;
    const station = req.query.station;

    let query = db('order_items')
      .where({ order_id: orderId })
      .whereIn('status', ['pending', 'fired', 'in_progress']);
    if (station) query = query.where('prep_station', station);

    await query.update({ status: 'ready', ready_at: new Date(), updated_at: new Date() });

    // Check if whole order now complete
    const remaining = await db('order_items')
      .where({ order_id: orderId })
      .whereIn('status', ['pending', 'fired', 'in_progress'])
      .count('id as c').first();

    if (remaining?.c === 0) {
      await db('orders').where({ id: orderId }).update({ status: 'ready', updated_at: new Date() });
    }

    fastify.posNs.to(`tenant:${req.tenantId}`).emit('kds:ticket_complete', { order_id: orderId });
    fastify.kitchenNs.to(`tenant:${req.tenantId}`).emit('kds:ticket_complete', { order_id: orderId });

    return ok({ bumped_all: true });
  });
}
