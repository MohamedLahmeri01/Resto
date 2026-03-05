import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';

export default async function menuRoutes(fastify) {
  const db = fastify.knex;
  const redis = fastify.redis;

  const cacheKey = (tenantId, branchId) => `menu:${tenantId}:${branchId || 'all'}`;

  async function invalidateMenuCache(tenantId) {
    const keys = await redis.keys(`menu:${tenantId}:*`);
    if (keys.length) await redis.del(...keys);
  }

  // GET /menu — full menu tree (cached)
  fastify.get('/', { preHandler: [verifyJWT] }, async (req) => {
    const branchId = req.query.branch_id || req.user.branch_id;
    const key = cacheKey(req.tenantId, branchId);
    const cached = await redis.get(key);
    if (cached) return ok(JSON.parse(cached));

    const categoriesQ = tenantScope(db('menu_categories'), req.tenantId);
    if (branchId) categoriesQ.where(function () { this.where('branch_id', branchId).orWhereNull('branch_id'); });
    const categories = await categoriesQ.orderBy('display_order');

    const itemsQ = tenantScope(db('menu_items'), req.tenantId);
    if (branchId) itemsQ.where(function () { this.where('branch_id', branchId).orWhereNull('branch_id'); });
    const items = await itemsQ.orderBy('display_order');

    const modifierGroups = await tenantScope(db('modifier_groups'), req.tenantId);
    const modifiers = await tenantScope(db('modifiers'), req.tenantId).orderBy('display_order');
    const itemModGroups = await db('item_modifier_groups')
      .whereIn('item_id', items.map((i) => i.id));

    // Build tree
    const tree = categories.map((cat) => ({
      ...cat,
      items: items
        .filter((it) => it.category_id === cat.id)
        .map((it) => ({
          ...it,
          allergens: typeof it.allergens_json === 'string' ? JSON.parse(it.allergens_json) : (it.allergens_json || []),
          modifier_groups: itemModGroups
            .filter((img) => img.item_id === it.id)
            .map((img) => {
              const group = modifierGroups.find((g) => g.id === img.group_id);
              return group ? {
                ...group,
                modifiers: modifiers.filter((m) => m.group_id === group.id),
              } : null;
            })
            .filter(Boolean),
        })),
      subcategories: categories.filter((sub) => sub.parent_id === cat.id),
    })).filter((cat) => !cat.parent_id); // only top-level

    await redis.setex(key, 86400, JSON.stringify(tree)); // 24h cache
    return ok(tree);
  });

  // POST /menu/categories
  fastify.post('/categories', { preHandler: [verifyJWT, requirePermission('menu.write')] }, async (req) => {
    const { name_fr, name_ar, branch_id, parent_id, photo_url, display_order } = req.body;
    if (parent_id) {
      const parent = await tenantScope(db('menu_categories'), req.tenantId).where({ id: parent_id }).first();
      if (!parent) throw { status: 400, code: 'INVALID_PARENT', message_fr: 'Catégorie parente invalide', message_ar: 'الفئة الأم غير صالحة' };
    }
    const id = genId();
    await db('menu_categories').insert({ id, tenant_id: req.tenantId, branch_id, parent_id, name_fr, name_ar, photo_url, display_order: display_order || 0 });
    await invalidateMenuCache(req.tenantId);
    return ok(await db('menu_categories').where({ id }).first());
  });

  // PUT /menu/categories/:id
  fastify.put('/categories/:id', { preHandler: [verifyJWT, requirePermission('menu.write')] }, async (req) => {
    const { id } = req.params;
    await tenantScope(db('menu_categories'), req.tenantId).where({ id }).update({ ...req.body, updated_at: new Date() });
    await invalidateMenuCache(req.tenantId);
    return ok(await db('menu_categories').where({ id }).first());
  });

  // DELETE /menu/categories/:id (soft delete)
  fastify.delete('/categories/:id', { preHandler: [verifyJWT, requirePermission('menu.write')] }, async (req) => {
    await tenantScope(db('menu_categories'), req.tenantId).where({ id: req.params.id }).update({ deleted_at: new Date() });
    await invalidateMenuCache(req.tenantId);
    return ok({ deleted: true });
  });

  // POST /menu/items
  fastify.post('/items', { preHandler: [verifyJWT, requirePermission('menu.write')] }, async (req) => {
    const { name_fr, name_ar, description_fr, description_ar, branch_id, category_id, photo_url, base_price_cents, calories, allergens, prep_station, display_order, modifier_group_ids } = req.body;
    const id = genId();
    await db('menu_items').insert({
      id, tenant_id: req.tenantId, branch_id, category_id, name_fr, name_ar,
      description_fr, description_ar, photo_url,
      base_price_cents: base_price_cents || 0,
      calories, allergens_json: JSON.stringify(allergens || []),
      prep_station: prep_station || 'grill', display_order: display_order || 0,
    });
    // Attach modifier groups
    if (modifier_group_ids?.length) {
      for (let i = 0; i < modifier_group_ids.length; i++) {
        await db('item_modifier_groups').insert({ item_id: id, group_id: modifier_group_ids[i], display_order: i });
      }
    }
    await invalidateMenuCache(req.tenantId);
    return ok(await db('menu_items').where({ id }).first());
  });

  // PUT /menu/items/:id
  fastify.put('/items/:id', { preHandler: [verifyJWT, requirePermission('menu.write')] }, async (req) => {
    const { id } = req.params;
    const item = await tenantScope(db('menu_items'), req.tenantId).where({ id }).first();
    if (!item) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Article introuvable', message_ar: 'العنصر غير موجود' };

    const updates = { ...req.body, updated_at: new Date() };
    if (updates.allergens) { updates.allergens_json = JSON.stringify(updates.allergens); delete updates.allergens; }
    delete updates.modifier_group_ids;
    await tenantScope(db('menu_items'), req.tenantId).where({ id }).update(updates);

    // Handle is_86d broadcast
    if (req.body.is_86d !== undefined && req.body.is_86d !== item.is_86d) {
      const event = req.body.is_86d ? 'menu:item_86d' : 'menu:item_restored';
      fastify.posNs.to(`tenant:${req.tenantId}`).emit(event, { item_id: id, name_fr: item.name_fr, name_ar: item.name_ar });
    }

    await invalidateMenuCache(req.tenantId);
    return ok(await db('menu_items').where({ id }).first());
  });

  // DELETE /menu/items/:id (soft delete)
  fastify.delete('/items/:id', { preHandler: [verifyJWT, requirePermission('menu.write')] }, async (req) => {
    await tenantScope(db('menu_items'), req.tenantId).where({ id: req.params.id }).update({ deleted_at: new Date() });
    await invalidateMenuCache(req.tenantId);
    return ok({ deleted: true });
  });

  // GET /menu/items/:id/recipe
  fastify.get('/items/:id/recipe', { preHandler: [verifyJWT] }, async (req) => {
    const recipe = await db('recipes').where({ item_id: req.params.id, tenant_id: req.tenantId }).orderBy('version', 'desc').first();
    if (!recipe) return ok(null);
    const ingredients = await db('recipe_ingredients').where({ recipe_id: recipe.id });
    return ok({ ...recipe, ingredients });
  });

  // === Modifier Groups ===
  fastify.get('/modifier-groups', { preHandler: [verifyJWT] }, async (req) => {
    const groups = await tenantScope(db('modifier_groups'), req.tenantId);
    const mods = await tenantScope(db('modifiers'), req.tenantId).orderBy('display_order');
    return ok(groups.map((g) => ({ ...g, modifiers: mods.filter((m) => m.group_id === g.id) })));
  });

  fastify.post('/modifier-groups', { preHandler: [verifyJWT, requirePermission('menu.write')] }, async (req) => {
    const { name_fr, name_ar, selection_type, min_selections, max_selections, modifiers } = req.body;
    const groupId = genId();
    await db('modifier_groups').insert({ id: groupId, tenant_id: req.tenantId, name_fr, name_ar, selection_type: selection_type || 'single_optional', min_selections: min_selections || 0, max_selections: max_selections || 1 });
    if (modifiers?.length) {
      for (let i = 0; i < modifiers.length; i++) {
        await db('modifiers').insert({ id: genId(), tenant_id: req.tenantId, group_id: groupId, name_fr: modifiers[i].name_fr, name_ar: modifiers[i].name_ar, price_delta_cents: modifiers[i].price_delta_cents || 0, display_order: i });
      }
    }
    await invalidateMenuCache(req.tenantId);
    const group = await db('modifier_groups').where({ id: groupId }).first();
    const mods = await db('modifiers').where({ group_id: groupId }).orderBy('display_order');
    return ok({ ...group, modifiers: mods });
  });
}
