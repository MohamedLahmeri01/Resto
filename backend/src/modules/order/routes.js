import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';

export default async function orderRoutes(fastify) {
  const db = fastify.knex;

  // Helper: generate daily order number
  async function nextOrderNumber(tenantId, branchId) {
    const today = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const count = await db('orders')
      .where({ tenant_id: tenantId, branch_id: branchId })
      .where('created_at', '>=', new Date(new Date().setHours(0, 0, 0, 0)))
      .count('id as c')
      .first();
    return `${today}-${String((count?.c || 0) + 1).padStart(4, '0')}`;
  }

  // POST /orders — Create new order
  fastify.post('/', { preHandler: [verifyJWT, requirePermission('orders.create')] }, async (req) => {
    const { table_id, order_type, customer_id, covers_count, notes, items } = req.body;
    const branchId = req.user.branch_id;

    // Validate table availability for dine-in
    if (order_type === 'dine_in' && table_id) {
      const table = await tenantScope(db('tables'), req.tenantId).where({ id: table_id }).first();
      if (!table) throw { status: 404, code: 'TABLE_NOT_FOUND', message_fr: 'Table introuvable', message_ar: 'الطاولة غير موجودة' };
      if (table.status === 'occupied' && table.current_order_id) {
        throw { status: 409, code: 'TABLE_OCCUPIED', message_fr: 'Table déjà occupée', message_ar: 'الطاولة مشغولة بالفعل' };
      }
    }

    const orderId = genId();
    const orderNumber = await nextOrderNumber(req.tenantId, branchId);

    // Calculate totals from items
    let subtotal = 0;
    const orderItems = [];
    if (items?.length) {
      for (const item of items) {
        const menuItem = await db('menu_items').where({ id: item.item_id, tenant_id: req.tenantId }).first();
        if (!menuItem) continue;
        const unitPrice = menuItem.base_price_cents;
        let itemTotal = unitPrice * (item.quantity || 1);

        // Calculate modifier costs
        let modDelta = 0;
        if (item.modifier_ids?.length) {
          const mods = await db('modifiers').whereIn('id', item.modifier_ids);
          modDelta = mods.reduce((sum, m) => sum + (m.price_delta_cents || 0), 0);
        }
        itemTotal += modDelta * (item.quantity || 1);
        subtotal += itemTotal;

        orderItems.push({
          id: genId(),
          order_id: orderId,
          tenant_id: req.tenantId,
          item_id: item.item_id,
          name_fr: menuItem.name_fr,
          name_ar: menuItem.name_ar,
          seat_number: item.seat_number || null,
          quantity: item.quantity || 1,
          unit_price_cents: unitPrice + modDelta,
          total_price_cents: itemTotal,
          notes: item.notes || null,
          course_number: item.course_number || 1,
          prep_station: menuItem.prep_station,
          status: 'pending',
          modifiers: item.modifier_ids || [],
        });
      }
    }

    // Get tenant tax rate
    const taxConfig = await db('tenant_config').where({ tenant_id: req.tenantId, key: 'tax_rate' }).first();
    const taxRate = taxConfig ? parseFloat(JSON.parse(taxConfig.value_json)) : 0;
    const taxCents = Math.round(subtotal * taxRate / 100);
    const totalCents = subtotal + taxCents;

    // Insert order
    await db('orders').insert({
      id: orderId,
      tenant_id: req.tenantId,
      branch_id: branchId,
      table_id,
      order_type: order_type || 'dine_in',
      status: 'draft',
      customer_id,
      waiter_id: req.user.sub,
      covers_count: covers_count || 1,
      subtotal_cents: subtotal,
      tax_cents: taxCents,
      total_cents: totalCents,
      notes,
      order_number: orderNumber,
    });

    // Insert order items
    for (const oi of orderItems) {
      const modifiers = oi.modifiers;
      delete oi.modifiers;
      await db('order_items').insert(oi);
      // Insert order item modifiers
      if (modifiers.length) {
        const mods = await db('modifiers').whereIn('id', modifiers);
        for (const mod of mods) {
          await db('order_item_modifiers').insert({
            id: genId(),
            order_item_id: oi.id,
            modifier_id: mod.id,
            name_fr: mod.name_fr,
            name_ar: mod.name_ar,
            price_delta_cents: mod.price_delta_cents,
          });
        }
      }
    }

    // Update table status for dine-in
    if (order_type === 'dine_in' && table_id) {
      await db('tables').where({ id: table_id }).update({
        status: 'occupied',
        current_order_id: orderId,
        occupied_since: new Date(),
        updated_at: new Date(),
      });
      fastify.posNs.to(`tenant:${req.tenantId}`).emit('table:status_changed', {
        table_id, old_status: 'available', new_status: 'occupied',
      });
    }

    // Emit WebSocket event
    const order = await db('orders').where({ id: orderId }).first();
    const fullItems = await db('order_items').where({ order_id: orderId });
    fastify.posNs.to(`tenant:${req.tenantId}`).emit('order:created', {
      order_id: orderId, table_id, items: fullItems, order_type,
    });
    fastify.kitchenNs.to(`tenant:${req.tenantId}`).emit('order:created', {
      order_id: orderId, table_id, items: fullItems, order_type,
    });

    // Audit log
    await db('audit_log').insert({
      id: genId(), tenant_id: req.tenantId, user_id: req.user.sub,
      action: 'order.create', entity_type: 'order', entity_id: orderId,
      new_value_json: JSON.stringify({ order_type, table_id, items_count: orderItems.length }),
      ip_address: req.ip,
    });

    return ok({ ...order, items: fullItems });
  });

  // GET /orders — List orders
  fastify.get('/', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { status, branch_id, waiter_id, order_type, date_from, date_to, table_id } = req.query;

    let query = tenantScope(db('orders'), req.tenantId);
    if (status) query = query.where('status', status);
    if (branch_id) query = query.where('branch_id', branch_id);
    else if (req.user.branch_id) query = query.where('branch_id', req.user.branch_id);
    if (waiter_id) query = query.where('waiter_id', waiter_id);
    if (order_type) query = query.where('order_type', order_type);
    if (table_id) query = query.where('table_id', table_id);
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);

    const total = await query.clone().count('id as count').first();
    const orders = await query.orderBy('created_at', 'desc').limit(limit).offset(offset);

    return paginate(orders, { page, limit, total: total?.count || 0 });
  });

  // GET /orders/:id — Full detail
  fastify.get('/:id', { preHandler: [verifyJWT] }, async (req) => {
    const order = await tenantScope(db('orders'), req.tenantId).where({ id: req.params.id }).first();
    if (!order) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Commande introuvable', message_ar: 'الطلب غير موجود' };

    const items = await db('order_items').where({ order_id: order.id });
    for (const item of items) {
      item.modifiers = await db('order_item_modifiers').where({ order_item_id: item.id });
    }
    const payments = await db('payments').where({ order_id: order.id });
    const discounts = await db('discounts_applied').where({ order_id: order.id });

    return ok({ ...order, items, payments, discounts });
  });

  // PATCH /orders/:id — Update order status
  fastify.patch('/:id', { preHandler: [verifyJWT, requirePermission('orders.update')] }, async (req) => {
    const order = await tenantScope(db('orders'), req.tenantId).where({ id: req.params.id }).first();
    if (!order) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Commande introuvable', message_ar: 'الطلب غير موجود' };

    const { status: newStatus, notes } = req.body;
    const oldStatus = order.status;

    const updates = { updated_at: new Date() };
    if (newStatus) updates.status = newStatus;
    if (notes !== undefined) updates.notes = notes;
    if (newStatus === 'closed') updates.closed_at = new Date();
    if (newStatus === 'voided') updates.voided_at = new Date();

    await db('orders').where({ id: order.id }).update(updates);

    // Emit status change
    if (newStatus && newStatus !== oldStatus) {
      const payload = { order_id: order.id, old_status: oldStatus, new_status: newStatus };
      fastify.posNs.to(`tenant:${req.tenantId}`).emit('order:status_changed', payload);
      fastify.managerNs.to(`tenant:${req.tenantId}`).emit('order:status_changed', payload);
    }

    // Audit
    await db('audit_log').insert({
      id: genId(), tenant_id: req.tenantId, user_id: req.user.sub,
      action: 'order.update', entity_type: 'order', entity_id: order.id,
      old_value_json: JSON.stringify({ status: oldStatus }),
      new_value_json: JSON.stringify({ status: newStatus }),
      ip_address: req.ip,
    });

    return ok(await db('orders').where({ id: order.id }).first());
  });

  // POST /orders/:id/items — Add items to order
  fastify.post('/:id/items', { preHandler: [verifyJWT, requirePermission('orders.create')] }, async (req) => {
    const order = await tenantScope(db('orders'), req.tenantId).where({ id: req.params.id }).first();
    if (!order) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Commande introuvable', message_ar: 'الطلب غير موجود' };
    if (['closed', 'voided', 'refunded'].includes(order.status)) {
      throw { status: 409, code: 'ORDER_CLOSED', message_fr: 'Commande déjà fermée', message_ar: 'الطلب مغلق بالفعل' };
    }

    const { items } = req.body;
    let addedSubtotal = 0;
    const newItems = [];

    for (const item of items) {
      const menuItem = await db('menu_items').where({ id: item.item_id, tenant_id: req.tenantId }).first();
      if (!menuItem) continue;

      let modDelta = 0;
      if (item.modifier_ids?.length) {
        const mods = await db('modifiers').whereIn('id', item.modifier_ids);
        modDelta = mods.reduce((s, m) => s + (m.price_delta_cents || 0), 0);
      }

      const unitPrice = menuItem.base_price_cents + modDelta;
      const totalPrice = unitPrice * (item.quantity || 1);
      addedSubtotal += totalPrice;

      const oiId = genId();
      await db('order_items').insert({
        id: oiId, order_id: order.id, tenant_id: req.tenantId, item_id: item.item_id,
        name_fr: menuItem.name_fr, name_ar: menuItem.name_ar,
        seat_number: item.seat_number || null, quantity: item.quantity || 1,
        unit_price_cents: unitPrice, total_price_cents: totalPrice,
        notes: item.notes, course_number: item.course_number || 1,
        prep_station: menuItem.prep_station, status: 'pending',
      });

      if (item.modifier_ids?.length) {
        const mods = await db('modifiers').whereIn('id', item.modifier_ids);
        for (const mod of mods) {
          await db('order_item_modifiers').insert({
            id: genId(), order_item_id: oiId, modifier_id: mod.id,
            name_fr: mod.name_fr, name_ar: mod.name_ar, price_delta_cents: mod.price_delta_cents,
          });
        }
      }

      newItems.push({ id: oiId, name_fr: menuItem.name_fr, station: menuItem.prep_station });
    }

    // Recalculate totals
    const taxConfig = await db('tenant_config').where({ tenant_id: req.tenantId, key: 'tax_rate' }).first();
    const taxRate = taxConfig ? parseFloat(JSON.parse(taxConfig.value_json)) : 0;
    const newSubtotal = order.subtotal_cents + addedSubtotal;
    const newTax = Math.round(newSubtotal * taxRate / 100);
    await db('orders').where({ id: order.id }).update({
      subtotal_cents: newSubtotal,
      tax_cents: newTax,
      total_cents: newSubtotal + newTax - order.discount_cents,
      updated_at: new Date(),
    });

    // Emit to kitchen
    for (const ni of newItems) {
      fastify.kitchenNs.to(`station:${ni.station}`).emit('order:item_added', {
        order_id: order.id, item: ni, station: ni.station,
      });
    }

    const updatedItems = await db('order_items').where({ order_id: order.id });
    return ok(updatedItems);
  });

  // PATCH /orders/:id/items/:itemId — Update item status (fire, void, serve)
  fastify.patch('/:id/items/:itemId', { preHandler: [verifyJWT, requirePermission('orders.update')] }, async (req) => {
    const oi = await db('order_items').where({ id: req.params.itemId, order_id: req.params.id }).first();
    if (!oi) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Article introuvable', message_ar: 'العنصر غير موجود' };

    const { status: newStatus } = req.body;
    const updates = { status: newStatus, updated_at: new Date() };
    if (newStatus === 'fired') updates.fired_at = new Date();
    if (newStatus === 'ready') updates.ready_at = new Date();
    if (newStatus === 'served') updates.served_at = new Date();
    await db('order_items').where({ id: oi.id }).update(updates);

    return ok(await db('order_items').where({ id: oi.id }).first());
  });

  // POST /orders/:id/fire-course
  fastify.post('/:id/fire-course', { preHandler: [verifyJWT, requirePermission('orders.update')] }, async (req) => {
    const { course_number } = req.body;
    const items = await db('order_items')
      .where({ order_id: req.params.id, course_number, status: 'pending' });
    for (const item of items) {
      await db('order_items').where({ id: item.id }).update({ status: 'fired', fired_at: new Date() });
    }
    fastify.kitchenNs.to(`tenant:${req.tenantId}`).emit('order:course_fired', {
      order_id: req.params.id, course_number, items,
    });
    return ok({ fired: items.length });
  });

  // POST /orders/:id/void
  fastify.post('/:id/void', { preHandler: [verifyJWT, requirePermission('orders.void')] }, async (req) => {
    const order = await tenantScope(db('orders'), req.tenantId).where({ id: req.params.id }).first();
    if (!order) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Commande introuvable', message_ar: 'الطلب غير موجود' };

    const paidAmount = await db('payments').where({ order_id: order.id, status: 'captured' }).sum('amount_cents as total').first();
    if (paidAmount?.total > 0) throw { status: 409, code: 'ALREADY_PAID', message_fr: 'Commande déjà payée — utiliser remboursement', message_ar: 'الطلب مدفوع مسبقاً — استخدم الاسترداد' };

    await db('orders').where({ id: order.id }).update({ status: 'voided', voided_at: new Date(), updated_at: new Date() });
    await db('order_items').where({ order_id: order.id }).update({ status: 'voided' });

    // Restore table
    if (order.table_id) {
      await db('tables').where({ id: order.table_id }).update({ status: 'available', current_order_id: null, occupied_since: null, updated_at: new Date() });
      fastify.posNs.to(`tenant:${req.tenantId}`).emit('table:status_changed', { table_id: order.table_id, old_status: 'occupied', new_status: 'available' });
    }

    await db('audit_log').insert({ id: genId(), tenant_id: req.tenantId, user_id: req.user.sub, action: 'order.void', entity_type: 'order', entity_id: order.id, ip_address: req.ip });
    return ok({ voided: true });
  });

  // POST /orders/:id/refund
  fastify.post('/:id/refund', { preHandler: [verifyJWT, requirePermission('orders.refund')] }, async (req) => {
    const order = await tenantScope(db('orders'), req.tenantId).where({ id: req.params.id }).first();
    if (!order) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Commande introuvable', message_ar: 'الطلب غير موجود' };

    const { amount_cents, reason } = req.body;
    const refundAmount = amount_cents || order.total_cents;

    await db('payments').insert({
      id: genId(), order_id: order.id, tenant_id: req.tenantId,
      method: 'cash', amount_cents: -refundAmount,
      status: 'refunded', cashier_id: req.user.sub, processed_at: new Date(),
    });

    await db('orders').where({ id: order.id }).update({ status: 'refunded', updated_at: new Date() });

    await db('audit_log').insert({
      id: genId(), tenant_id: req.tenantId, user_id: req.user.sub,
      action: 'order.refund', entity_type: 'order', entity_id: order.id,
      new_value_json: JSON.stringify({ amount_cents: refundAmount, reason }),
      ip_address: req.ip,
    });

    return ok({ refunded: true, amount_cents: refundAmount });
  });
}
