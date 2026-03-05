import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';

export default async function inventoryRoutes(fastify) {
  const db = fastify.knex;

  // GET /inventory/ingredients
  fastify.get('/ingredients', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { branch_id, category, search, low_stock } = req.query;
    let query = tenantScope(db('ingredients'), req.tenantId);
    if (branch_id) query = query.where('branch_id', branch_id);
    if (category) query = query.where('category', category);
    if (search) query = query.where(function () { this.where('name_fr', 'like', `%${search}%`).orWhere('name_ar', 'like', `%${search}%`); });
    if (low_stock === 'true') query = query.whereRaw('current_stock <= par_level');

    const total = await query.clone().count('id as count').first();
    const items = await query.orderBy('name_fr').limit(limit).offset(offset);

    const enriched = items.map((i) => ({
      ...i,
      is_low_stock: i.current_stock <= i.par_level,
      stock_status: i.current_stock <= 0 ? 'out' : i.current_stock <= i.par_level ? 'low' : 'ok',
    }));

    return paginate(enriched, { page, limit, total: total?.count || 0 });
  });

  // POST /inventory/ingredients
  fastify.post('/ingredients', { preHandler: [verifyJWT, requirePermission('inventory.write')] }, async (req) => {
    const id = genId();
    await db('ingredients').insert({ id, tenant_id: req.tenantId, ...req.body });
    return ok(await db('ingredients').where({ id }).first());
  });

  // PUT /inventory/ingredients/:id
  fastify.put('/ingredients/:id', { preHandler: [verifyJWT, requirePermission('inventory.write')] }, async (req) => {
    await tenantScope(db('ingredients'), req.tenantId).where({ id: req.params.id }).update({ ...req.body, updated_at: new Date() });
    return ok(await db('ingredients').where({ id: req.params.id }).first());
  });

  // POST /inventory/stock-movements — Manual adjustment
  fastify.post('/stock-movements', { preHandler: [verifyJWT, requirePermission('inventory.write')] }, async (req) => {
    const { ingredient_id, movement_type, quantity_delta, notes, reference_id, reference_type } = req.body;
    const ingredient = await tenantScope(db('ingredients'), req.tenantId).where({ id: ingredient_id }).first();
    if (!ingredient) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Ingrédient introuvable', message_ar: 'المكون غير موجود' };

    const stockAfter = ingredient.current_stock + quantity_delta;
    const id = genId();
    await db('stock_movements').insert({
      id, tenant_id: req.tenantId, ingredient_id, movement_type,
      quantity_delta, stock_after: stockAfter,
      reference_id, reference_type, notes,
      performed_by_user_id: req.user.sub,
    });

    await db('ingredients').where({ id: ingredient_id }).update({
      current_stock: stockAfter, updated_at: new Date(),
    });

    // Low stock alert
    if (stockAfter <= ingredient.par_level) {
      fastify.managerNs.to(`tenant:${req.tenantId}`).emit('inventory:low_stock', {
        ingredient_id, name_fr: ingredient.name_fr, name_ar: ingredient.name_ar,
        current_stock: stockAfter, par_level: ingredient.par_level,
      });
    }

    return ok({ id, stock_after: stockAfter });
  });

  // GET /inventory/stock-movements
  fastify.get('/stock-movements', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { ingredient_id, movement_type, date_from, date_to } = req.query;
    let query = db('stock_movements').where({ tenant_id: req.tenantId });
    if (ingredient_id) query = query.where('ingredient_id', ingredient_id);
    if (movement_type) query = query.where('movement_type', movement_type);
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);

    const total = await query.clone().count('id as count').first();
    const movements = await query.orderBy('created_at', 'desc').limit(limit).offset(offset);
    return paginate(movements, { page, limit, total: total?.count || 0 });
  });

  // POST /inventory/stock-count — Physical count
  fastify.post('/stock-count', { preHandler: [verifyJWT, requirePermission('inventory.write')] }, async (req) => {
    const { counts } = req.body; // [{ ingredient_id, actual_quantity }]
    const results = [];
    for (const count of counts) {
      const ingredient = await tenantScope(db('ingredients'), req.tenantId).where({ id: count.ingredient_id }).first();
      if (!ingredient) continue;
      const variance = count.actual_quantity - ingredient.current_stock;
      if (variance !== 0) {
        await db('stock_movements').insert({
          id: genId(), tenant_id: req.tenantId, ingredient_id: count.ingredient_id,
          movement_type: 'stock_count', quantity_delta: variance,
          stock_after: count.actual_quantity, notes: `Physical count. Variance: ${variance}`,
          performed_by_user_id: req.user.sub,
        });
        await db('ingredients').where({ id: count.ingredient_id }).update({ current_stock: count.actual_quantity, updated_at: new Date() });
      }
      results.push({ ingredient_id: count.ingredient_id, expected: ingredient.current_stock, actual: count.actual_quantity, variance });
    }
    return ok(results);
  });

  // === Suppliers ===
  fastify.get('/suppliers', { preHandler: [verifyJWT] }, async (req) => {
    return ok(await tenantScope(db('suppliers'), req.tenantId).orderBy('name'));
  });

  fastify.post('/suppliers', { preHandler: [verifyJWT, requirePermission('inventory.write')] }, async (req) => {
    const id = genId();
    await db('suppliers').insert({ id, tenant_id: req.tenantId, ...req.body });
    return ok(await db('suppliers').where({ id }).first());
  });

  // === Purchase Orders ===
  fastify.get('/purchase-orders', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { status, supplier_id } = req.query;
    let query = db('purchase_orders').where({ tenant_id: req.tenantId });
    if (status) query = query.where('status', status);
    if (supplier_id) query = query.where('supplier_id', supplier_id);
    const total = await query.clone().count('id as count').first();
    const pos = await query.orderBy('created_at', 'desc').limit(limit).offset(offset);
    return paginate(pos, { page, limit, total: total?.count || 0 });
  });

  fastify.post('/purchase-orders', { preHandler: [verifyJWT, requirePermission('inventory.po.create')] }, async (req) => {
    const { supplier_id, branch_id, lines, notes, expected_delivery_date } = req.body;
    const poId = genId();
    let subtotal = 0;
    for (const line of (lines || [])) subtotal += (line.quantity_ordered || 0) * (line.unit_price_cents || 0);
    const taxConfig = await db('tenant_config').where({ tenant_id: req.tenantId, key: 'tax_rate' }).first();
    const taxRate = taxConfig ? parseFloat(JSON.parse(taxConfig.value_json)) : 0;
    const taxCents = Math.round(subtotal * taxRate / 100);

    await db('purchase_orders').insert({
      id: poId, tenant_id: req.tenantId, branch_id: branch_id || req.user.branch_id,
      supplier_id, status: 'draft', subtotal_cents: subtotal, tax_cents: taxCents,
      total_cents: subtotal + taxCents, notes, expected_delivery_date,
      created_by_user_id: req.user.sub,
    });
    for (const line of (lines || [])) {
      await db('purchase_order_lines').insert({
        id: genId(), po_id: poId, tenant_id: req.tenantId,
        ingredient_id: line.ingredient_id,
        quantity_ordered: line.quantity_ordered, unit_price_cents: line.unit_price_cents,
        total_cents: line.quantity_ordered * line.unit_price_cents,
      });
    }
    return ok(await db('purchase_orders').where({ id: poId }).first());
  });

  // PATCH /inventory/purchase-orders/:id/receive
  fastify.patch('/purchase-orders/:id/receive', { preHandler: [verifyJWT, requirePermission('inventory.po.receive')] }, async (req) => {
    const po = await db('purchase_orders').where({ id: req.params.id, tenant_id: req.tenantId }).first();
    if (!po) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Bon de commande introuvable', message_ar: 'أمر الشراء غير موجود' };

    const { lines } = req.body; // [{ po_line_id, quantity_received, discrepancy_notes }]
    for (const line of lines) {
      const poLine = await db('purchase_order_lines').where({ id: line.po_line_id }).first();
      if (!poLine) continue;
      await db('purchase_order_lines').where({ id: line.po_line_id }).update({
        quantity_received: line.quantity_received, received_at: new Date(),
        discrepancy_notes: line.discrepancy_notes,
      });
      // Update stock
      const ingredient = await db('ingredients').where({ id: poLine.ingredient_id }).first();
      if (ingredient) {
        const newStock = ingredient.current_stock + line.quantity_received;
        await db('ingredients').where({ id: ingredient.id }).update({ current_stock: newStock, updated_at: new Date() });
        await db('stock_movements').insert({
          id: genId(), tenant_id: req.tenantId, ingredient_id: ingredient.id,
          movement_type: 'purchase', quantity_delta: line.quantity_received,
          stock_after: newStock, reference_id: po.id, reference_type: 'purchase_order',
          performed_by_user_id: req.user.sub,
        });
      }
    }

    await db('purchase_orders').where({ id: po.id }).update({ status: 'received', updated_at: new Date() });
    return ok({ received: true });
  });

  // === Waste Logs ===
  fastify.post('/waste-logs', { preHandler: [verifyJWT, requirePermission('inventory.write')] }, async (req) => {
    const { ingredient_id, branch_id, quantity, unit, waste_type, cost_cents, notes } = req.body;
    const ingredient = await tenantScope(db('ingredients'), req.tenantId).where({ id: ingredient_id }).first();
    if (!ingredient) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Ingrédient introuvable', message_ar: 'المكون غير موجود' };

    const id = genId();
    await db('waste_logs').insert({
      id, tenant_id: req.tenantId, branch_id: branch_id || req.user.branch_id,
      ingredient_id, quantity, unit, waste_type, cost_cents: cost_cents || 0, notes,
      logged_by_user_id: req.user.sub,
    });

    // Deduct stock
    const newStock = ingredient.current_stock - quantity;
    await db('ingredients').where({ id: ingredient_id }).update({ current_stock: newStock, updated_at: new Date() });
    await db('stock_movements').insert({
      id: genId(), tenant_id: req.tenantId, ingredient_id,
      movement_type: 'waste', quantity_delta: -quantity, stock_after: newStock,
      reference_id: id, reference_type: 'waste_log',
      performed_by_user_id: req.user.sub,
    });

    return ok({ id, stock_after: newStock });
  });

  fastify.get('/waste-logs', { preHandler: [verifyJWT] }, async (req) => {
    const { page, limit, offset } = parsePagination(req.query);
    const { branch_id, waste_type, date_from, date_to } = req.query;
    let query = db('waste_logs').where({ tenant_id: req.tenantId });
    if (branch_id) query = query.where('branch_id', branch_id);
    if (waste_type) query = query.where('waste_type', waste_type);
    if (date_from) query = query.where('created_at', '>=', date_from);
    if (date_to) query = query.where('created_at', '<=', date_to);
    const total = await query.clone().count('id as count').first();
    return paginate(await query.orderBy('created_at', 'desc').limit(limit).offset(offset), { page, limit, total: total?.count || 0 });
  });
}
