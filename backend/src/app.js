import Fastify from 'fastify';
import cors from '@fastify/cors';
import rateLimit from '@fastify/rate-limit';
import cookie from '@fastify/cookie';
import 'dotenv/config';

import { dbPlugin } from './plugins/db.js';
import { redisPlugin } from './plugins/redis.js';
import { socketPlugin } from './plugins/socket.js';
import { authPlugin } from './plugins/auth.js';

// Module routes
import authRoutes from './modules/auth/routes.js';
import tenantRoutes from './modules/tenant/routes.js';
import menuRoutes from './modules/menu/routes.js';
import orderRoutes from './modules/order/routes.js';
import kitchenRoutes from './modules/kitchen/routes.js';
import tableRoutes from './modules/tables/routes.js';
import notificationRoutes from './modules/notification/routes.js';
import staffRoutes from './modules/staff/routes.js';
import paymentRoutes from './modules/payment/routes.js';
import inventoryRoutes from './modules/inventory/routes.js';
import analyticsRoutes from './modules/analytics/routes.js';
import reservationRoutes from './modules/reservation/routes.js';
import crmRoutes from './modules/crm/routes.js';
import financeRoutes from './modules/finance/routes.js';
import superAdminRoutes from './modules/super-admin/routes.js';

const app = Fastify({
  logger: {
    level: process.env.LOG_LEVEL || 'info',
    transport: process.env.NODE_ENV === 'development'
      ? { target: 'pino-pretty', options: { colorize: true } }
      : undefined,
  },
  genReqId: () => crypto.randomUUID(),
  requestTimeout: 30000,
});

// ─── Global Plugins ────────────────────────────────────────────
await app.register(cors, {
  origin: '*',
  methods: ['GET', 'HEAD', 'PUT', 'PATCH', 'POST', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Tenant-Id'],
});

await app.register(cookie);

await app.register(rateLimit, {
  max: 100,
  timeWindow: '1 minute',
  keyGenerator: (req) => req.headers['x-tenant-id'] || req.ip,
});

// ─── Infrastructure Plugins ────────────────────────────────────
await app.register(dbPlugin);
await app.register(redisPlugin);
await app.register(socketPlugin);
await app.register(authPlugin);

// ─── Health Check ──────────────────────────────────────────────
app.get('/health', async (req, reply) => {
  const dbOk = await app.knex.raw('SELECT 1').then(() => true).catch(() => false);
  const redisOk = await app.redis.ping().then(() => true).catch(() => false);
  return {
    status: dbOk && redisOk ? 'ok' : 'degraded',
    db: dbOk ? 'ok' : 'error',
    redis: redisOk ? 'ok' : 'error',
    version: '1.0.0',
    uptime_seconds: Math.floor(process.uptime()),
  };
});

// ─── API Routes ────────────────────────────────────────────────
await app.register(authRoutes, { prefix: '/v1/auth' });
await app.register(tenantRoutes, { prefix: '/v1/tenants' });
await app.register(menuRoutes, { prefix: '/v1/menu' });
await app.register(orderRoutes, { prefix: '/v1/orders' });
await app.register(kitchenRoutes, { prefix: '/v1/kds' });
await app.register(tableRoutes, { prefix: '/v1/tables' });
await app.register(staffRoutes, { prefix: '/v1/staff' });
await app.register(paymentRoutes, { prefix: '/v1/payments' });
await app.register(inventoryRoutes, { prefix: '/v1/inventory' });
await app.register(analyticsRoutes, { prefix: '/v1/analytics' });
await app.register(reservationRoutes, { prefix: '/v1/reservations' });
await app.register(crmRoutes, { prefix: '/v1/crm' });
await app.register(notificationRoutes, { prefix: '/v1/notifications' });
await app.register(financeRoutes, { prefix: '/v1/finance' });
await app.register(superAdminRoutes, { prefix: '/v1/super-admin' });

// ─── Global Error Handler ──────────────────────────────────────
app.setErrorHandler((error, req, reply) => {
  req.log.error(error);
  const statusCode = error.statusCode || 500;
  reply.status(statusCode).send({
    success: false,
    data: null,
    error: {
      code: error.code || 'INTERNAL_ERROR',
      message_fr: error.messageFr || 'Erreur interne du serveur',
      message_ar: error.messageAr || 'خطأ داخلي في الخادم',
    },
    meta: null,
  });
});

// ─── Start Server ──────────────────────────────────────────────
const PORT = parseInt(process.env.PORT || '3000');
const HOST = process.env.HOST || '0.0.0.0';

try {
  await app.listen({ port: PORT, host: HOST });
  app.log.info(`Server running on http://${HOST}:${PORT}`);
} catch (err) {
  app.log.fatal(err);
  process.exit(1);
}

export default app;
