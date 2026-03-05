/**
 * Factory that returns a preHandler requiring one or more permissions.
 * Usage: { preHandler: [verifyJWT, requirePermission('menu:write', 'order:write')] }
 *
 * The JWT payload.permissions is expected to be an array of strings.
 * Super-admin role bypasses all checks.
 */
export function requirePermission(...required) {
  return async function handler(request, reply) {
    const user = request.user;

    if (!user) {
      return reply.code(401).send({
        success: false,
        error: {
          code: 'AUTH_REQUIRED',
          message_fr: 'Authentification requise',
          message_ar: 'المصادقة مطلوبة',
        },
      });
    }

    // Super-admin bypasses all permission checks
    if (user.role === 'super_admin') return;

    const userPerms = user.permissions || [];
    const hasAll = required.every((p) => userPerms.includes(p));

    if (!hasAll) {
      return reply.code(403).send({
        success: false,
        error: {
          code: 'FORBIDDEN',
          message_fr: 'Permissions insuffisantes',
          message_ar: 'صلاحيات غير كافية',
        },
      });
    }
  };
}
