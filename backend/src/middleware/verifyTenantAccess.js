/**
 * Verifies the requested resource belongs to the authenticated user's tenant.
 * Usage: { preHandler: [verifyJWT, verifyTenantAccess] }
 */
export async function verifyTenantAccess(request, reply) {
  const tenantId = request.tenantId;
  if (!tenantId) {
    return reply.code(403).send({
      success: false,
      error: {
        code: 'TENANT_MISSING',
        message_fr: 'Accès refusé — tenant non identifié',
        message_ar: 'تم رفض الوصول — لم يتم تحديد المستأجر',
      },
    });
  }

  // If the route has a :tenantId param, verify it matches
  if (request.params.tenantId && request.params.tenantId !== tenantId) {
    return reply.code(403).send({
      success: false,
      error: {
        code: 'TENANT_MISMATCH',
        message_fr: 'Accès refusé — mauvais tenant',
        message_ar: 'تم رفض الوصول — مستأجر خاطئ',
      },
    });
  }
}
