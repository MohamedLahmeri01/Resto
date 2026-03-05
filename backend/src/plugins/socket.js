import fp from 'fastify-plugin';
import { Server } from 'socket.io';

async function socket(fastify) {
  const io = new Server(fastify.server, {
    cors: {
      origin: process.env.CORS_ORIGIN === '*' ? true : (process.env.CORS_ORIGIN || 'http://localhost:8080').split(',').map(s => s.trim()),
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  });

  // Namespaces
  const posNs = io.of('/pos');
  const kitchenNs = io.of('/kitchen');
  const managerNs = io.of('/manager');

  // Auth middleware for all namespaces
  const authMiddleware = async (socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      if (!token) return next(new Error('Authentication required'));

      const payload = fastify.jwt.verify(token);
      socket.user = payload;
      socket.join(`tenant:${payload.tenant_id}`);
      if (payload.branch_id) socket.join(`branch:${payload.branch_id}`);
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  };

  posNs.use(authMiddleware);
  kitchenNs.use(authMiddleware);
  managerNs.use(authMiddleware);

  // Kitchen namespace joins station rooms
  kitchenNs.on('connection', (socket) => {
    const station = socket.handshake.query?.station;
    if (station) socket.join(`station:${station}`);
    fastify.log.info(`KDS connected: station=${station}, user=${socket.user?.sub}`);
  });

  posNs.on('connection', (socket) => {
    fastify.log.info(`POS connected: user=${socket.user?.sub}`);
  });

  managerNs.on('connection', (socket) => {
    fastify.log.info(`Manager connected: user=${socket.user?.sub}`);
  });

  fastify.decorate('io', io);
  fastify.decorate('posNs', posNs);
  fastify.decorate('kitchenNs', kitchenNs);
  fastify.decorate('managerNs', managerNs);

  fastify.addHook('onClose', async () => {
    io.close();
  });
}

export const socketPlugin = fp(socket, { name: 'socket', dependencies: ['db'] });
