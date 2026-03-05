/**
 * Fastify preHandler hook — verifies JWT from Authorization header.
 * Attaches decoded payload to request.user and request.tenantId.
 */
export async function verifyJWT(request, reply) {
  try {
    const header = request.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return reply.code(401).send({
        success: false,
        error: {
          code: 'AUTH_REQUIRED',
          message_fr: 'Authentification requise',
          message_ar: 'المصادقة مطلوبة',
        },
      });
    }

    const token = header.slice(7);
    const payload = request.server.jwt.verify(token);

    // Optional: check revocation in Redis
    const revoked = await request.server.redis.get(`revoked:${payload.jti || token}`);
    if (revoked) {
      return reply.code(401).send({
        success: false,
        error: {
          code: 'TOKEN_REVOKED',
          message_fr: 'Session expirée',
          message_ar: 'انتهت الجلسة',
        },
      });
    }

    request.user = payload;
    request.tenantId = payload.tenant_id;
  } catch (err) {
    return reply.code(401).send({
      success: false,
      error: {
        code: 'INVALID_TOKEN',
        message_fr: 'Token invalide ou expiré',
        message_ar: 'رمز غير صالح أو منتهي الصلاحية',
      },
    });
  }
}
