import { verifyJWT } from '../../middleware/verifyJWT.js';
import { requirePermission } from '../../middleware/requirePermission.js';
import { genId, ok, paginate, parsePagination, tenantScope } from '../../utils/helpers.js';

export default async function tenantRoutes(fastify) {
  const db = fastify.knex;

  // GET /tenant/profile
  fastify.get('/profile', { preHandler: [verifyJWT] }, async (req) => {
    const tenant = await db('tenants').where({ id: req.tenantId }).first();
    if (!tenant) return { success: false, error: { code: 'NOT_FOUND' } };
    const config = await db('tenant_config').where({ tenant_id: req.tenantId });
    const configMap = {};
    for (const c of config) configMap[c.key] = c.value_json;
    return ok({ ...tenant, config: configMap });
  });

  // PUT /tenant/profile
  fastify.put('/profile', { preHandler: [verifyJWT, requirePermission('tenant.manage')] }, async (req) => {
    const { name, slug, logo_url, phone, address, timezone, currency_code, country_code } = req.body;
    await db('tenants').where({ id: req.tenantId }).update({
      ...(name && { name }),
      ...(slug && { slug }),
      ...(logo_url !== undefined && { logo_url }),
      ...(phone !== undefined && { phone }),
      ...(address !== undefined && { address }),
      ...(timezone && { timezone }),
      ...(currency_code && { currency_code }),
      ...(country_code && { country_code }),
      updated_at: new Date(),
    });
    const updated = await db('tenants').where({ id: req.tenantId }).first();
    return ok(updated);
  });

  // PUT /tenant/config/:key
  fastify.put('/config/:key', { preHandler: [verifyJWT, requirePermission('tenant.manage')] }, async (req) => {
    const { key } = req.params;
    const { value } = req.body;
    const existing = await db('tenant_config').where({ tenant_id: req.tenantId, key }).first();
    if (existing) {
      await db('tenant_config').where({ id: existing.id }).update({
        value_json: JSON.stringify(value),
        updated_at: new Date(),
      });
    } else {
      await db('tenant_config').insert({
        id: genId(),
        tenant_id: req.tenantId,
        key,
        value_json: JSON.stringify(value),
      });
    }
    return ok({ key, value });
  });

  // GET /tenant/branches
  fastify.get('/branches', { preHandler: [verifyJWT] }, async (req) => {
    const branches = await tenantScope(db('branches'), req.tenantId).orderBy('name_fr');
    return ok(branches);
  });

  // POST /tenant/branches
  fastify.post('/branches', { preHandler: [verifyJWT, requirePermission('branches.manage')] }, async (req) => {
    const { name_fr, name_ar, address, phone, timezone } = req.body;
    const tenantBranchCount = await db('branches').where({ tenant_id: req.tenantId }).whereNull('deleted_at').count('id as count').first();
    const tenant = await db('tenants').where({ id: req.tenantId }).first();
    if (tenantBranchCount.count >= tenant.max_branches) {
      throw { status: 403, code: 'BRANCH_LIMIT', message_fr: `Limite de ${tenant.max_branches} branches atteinte`, message_ar: `تم الوصول إلى حد ${tenant.max_branches} فروع` };
    }
    const id = genId();
    await db('branches').insert({ id, tenant_id: req.tenantId, name_fr, name_ar, address, phone, timezone });
    const branch = await db('branches').where({ id }).first();
    return ok(branch);
  });

  // PUT /tenant/branches/:id
  fastify.put('/branches/:id', { preHandler: [verifyJWT, requirePermission('branches.manage')] }, async (req) => {
    const { id } = req.params;
    const { name_fr, name_ar, address, phone, timezone, is_active } = req.body;
    await tenantScope(db('branches'), req.tenantId).where({ id }).update({
      ...(name_fr && { name_fr }),
      ...(name_ar !== undefined && { name_ar }),
      ...(address !== undefined && { address }),
      ...(phone !== undefined && { phone }),
      ...(timezone && { timezone }),
      ...(is_active !== undefined && { is_active }),
      updated_at: new Date(),
    });
    const branch = await db('branches').where({ id }).first();
    return ok(branch);
  });

  // GET /tenant/roles
  fastify.get('/roles', { preHandler: [verifyJWT] }, async (req) => {
    const roles = await db('roles').where({ tenant_id: req.tenantId }).orderBy('name');
    return ok(roles);
  });

  // POST /tenant/roles
  fastify.post('/roles', { preHandler: [verifyJWT, requirePermission('roles.manage')] }, async (req) => {
    const { name, permissions } = req.body;
    const id = genId();
    await db('roles').insert({
      id, tenant_id: req.tenantId, name,
      permissions_json: JSON.stringify(permissions || []),
    });
    return ok(await db('roles').where({ id }).first());
  });

  // PUT /tenant/roles/:id
  fastify.put('/roles/:id', { preHandler: [verifyJWT, requirePermission('roles.manage')] }, async (req) => {
    const { id } = req.params;
    const { name, permissions } = req.body;
    await db('roles').where({ id, tenant_id: req.tenantId }).update({
      ...(name && { name }),
      ...(permissions && { permissions_json: JSON.stringify(permissions) }),
      updated_at: new Date(),
    });
    return ok(await db('roles').where({ id }).first());
  });
}
