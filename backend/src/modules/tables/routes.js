import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, tenantScope } from '../../utils/helpers.js';

export default async function tableRoutes(fastify) {
  const db = fastify.knex;

  // GET /tables — All tables with statuses
  fastify.get('/', { preHandler: [verifyJWT] }, async (req) => {
    const branchId = req.query.branch_id || req.user.branch_id;
    let query = tenantScope(db('tables'), req.tenantId);
    if (branchId) query = query.where('branch_id', branchId);
    const tables = await query.orderBy('section_id').orderBy('table_number');

    // Enrich with section info
    const sectionIds = [...new Set(tables.map((t) => t.section_id).filter(Boolean))];
    const sections = sectionIds.length
      ? await db('floor_sections').whereIn('id', sectionIds)
      : [];
    const sectionMap = {};
    for (const s of sections) sectionMap[s.id] = s;

    const enriched = tables.map((t) => ({
      ...t,
      section: t.section_id ? sectionMap[t.section_id] : null,
      time_occupied_minutes: t.occupied_since
        ? Math.round((Date.now() - new Date(t.occupied_since).getTime()) / 60000)
        : null,
    }));

    return ok(enriched);
  });

  // POST /tables
  fastify.post('/', { preHandler: [verifyJWT, requirePermission('tables.manage')] }, async (req) => {
    const { branch_id, section_id, table_number, seats, pos_x, pos_y, width, height, shape } = req.body;
    const id = genId();
    await db('tables').insert({
      id, tenant_id: req.tenantId, branch_id, section_id,
      table_number, seats: seats || 4,
      pos_x: pos_x || 0, pos_y: pos_y || 0,
      width: width || 80, height: height || 80,
      shape: shape || 'rectangle',
    });
    return ok(await db('tables').where({ id }).first());
  });

  // PUT /tables/:id
  fastify.put('/:id', { preHandler: [verifyJWT, requirePermission('tables.manage')] }, async (req) => {
    const { id } = req.params;
    const allowed = ['section_id', 'table_number', 'seats', 'pos_x', 'pos_y', 'width', 'height', 'shape'];
    const updates = {};
    for (const k of allowed) if (req.body[k] !== undefined) updates[k] = req.body[k];
    updates.updated_at = new Date();
    await tenantScope(db('tables'), req.tenantId).where({ id }).update(updates);
    return ok(await db('tables').where({ id }).first());
  });

  // PATCH /tables/:id/status
  fastify.patch('/:id/status', { preHandler: [verifyJWT, requirePermission('tables.update')] }, async (req) => {
    const { id } = req.params;
    const { status } = req.body;
    const table = await tenantScope(db('tables'), req.tenantId).where({ id }).first();
    if (!table) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Table introuvable', message_ar: 'الطاولة غير موجودة' };

    const oldStatus = table.status;
    const updates = { status, updated_at: new Date() };
    if (status === 'available') {
      updates.current_order_id = null;
      updates.occupied_since = null;
    }
    if (status === 'occupied' && oldStatus !== 'occupied') {
      updates.occupied_since = new Date();
    }

    await db('tables').where({ id }).update(updates);

    fastify.posNs.to(`tenant:${req.tenantId}`).emit('table:status_changed', {
      table_id: id, old_status: oldStatus, new_status: status,
    });

    return ok(await db('tables').where({ id }).first());
  });

  // POST /tables/merge
  fastify.post('/merge', { preHandler: [verifyJWT, requirePermission('tables.manage')] }, async (req) => {
    const { primary_table_id, merge_table_ids } = req.body;
    const primaryTable = await tenantScope(db('tables'), req.tenantId).where({ id: primary_table_id }).first();
    if (!primaryTable) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Table principale introuvable', message_ar: 'الطاولة الرئيسية غير موجودة' };

    // Move orders from merged tables to primary
    for (const tid of merge_table_ids) {
      const t = await db('tables').where({ id: tid, tenant_id: req.tenantId }).first();
      if (t?.current_order_id) {
        // Move items to primary order or create merged reference
        await db('orders').where({ id: t.current_order_id }).update({ table_id: primary_table_id });
      }
      await db('tables').where({ id: tid }).update({ status: 'occupied', current_order_id: primaryTable.current_order_id, updated_at: new Date() });
    }

    return ok({ merged: true, primary_table_id, merged_count: merge_table_ids.length });
  });

  // POST /tables/split
  fastify.post('/split', { preHandler: [verifyJWT, requirePermission('orders.create')] }, async (req) => {
    const { order_id, splits } = req.body;
    // splits: [{ seat_numbers: [1,2], table_id: "new-table-id" }, ...]
    const order = await tenantScope(db('orders'), req.tenantId).where({ id: order_id }).first();
    if (!order) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Commande introuvable', message_ar: 'الطلب غير موجود' };

    const newOrders = [];
    for (const split of splits) {
      const items = await db('order_items')
        .where({ order_id })
        .whereIn('seat_number', split.seat_numbers);

      if (!items.length) continue;

      const newOrderId = genId();
      const subtotal = items.reduce((s, i) => s + i.total_price_cents, 0);
      const taxRate = order.tax_cents / (order.subtotal_cents || 1);
      const taxCents = Math.round(subtotal * taxRate);

      await db('orders').insert({
        id: newOrderId, tenant_id: req.tenantId, branch_id: order.branch_id,
        table_id: split.table_id || order.table_id, order_type: order.order_type,
        status: 'sent', waiter_id: order.waiter_id, covers_count: split.seat_numbers.length,
        subtotal_cents: subtotal, tax_cents: taxCents, total_cents: subtotal + taxCents,
      });

      for (const item of items) {
        await db('order_items').where({ id: item.id }).update({ order_id: newOrderId });
      }
      newOrders.push(newOrderId);
    }

    // Recalculate original order
    const remainingItems = await db('order_items').where({ order_id });
    const newSubtotal = remainingItems.reduce((s, i) => s + i.total_price_cents, 0);
    const taxRate = order.tax_cents / (order.subtotal_cents || 1);
    await db('orders').where({ id: order_id }).update({
      subtotal_cents: newSubtotal,
      tax_cents: Math.round(newSubtotal * taxRate),
      total_cents: newSubtotal + Math.round(newSubtotal * taxRate),
      updated_at: new Date(),
    });

    return ok({ original_order_id: order_id, new_order_ids: newOrders });
  });

  // GET /tables/sections
  fastify.get('/sections', { preHandler: [verifyJWT] }, async (req) => {
    const branchId = req.query.branch_id || req.user.branch_id;
    let query = tenantScope(db('floor_sections'), req.tenantId);
    if (branchId) query = query.where('branch_id', branchId);
    return ok(await query.orderBy('display_order'));
  });

  // POST /tables/sections
  fastify.post('/sections', { preHandler: [verifyJWT, requirePermission('tables.manage')] }, async (req) => {
    const { branch_id, name_fr, name_ar, display_order } = req.body;
    const id = genId();
    await db('floor_sections').insert({ id, tenant_id: req.tenantId, branch_id, name_fr, name_ar, display_order: display_order || 0 });
    return ok(await db('floor_sections').where({ id }).first());
  });

  // DELETE /tables/:id
  fastify.delete('/:id', { preHandler: [verifyJWT, requirePermission('tables.manage')] }, async (req) => {
    await tenantScope(db('tables'), req.tenantId).where({ id: req.params.id }).update({ deleted_at: new Date() });
    return ok({ deleted: true });
  });
}
