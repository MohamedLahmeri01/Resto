import fp from 'fastify-plugin';
import Redis from 'ioredis';

async function redis(fastify) {
  const url = process.env.REDIS_URL || 'redis://127.0.0.1:6379';
  let client;

  try {
    client = new Redis(url, {
      lazyConnect: true,
      maxRetriesPerRequest: 3,
      retryStrategy: (times) => (times > 2 ? null : Math.min(times * 200, 2000)),
    });
    client.on('error', () => {}); // suppress unhandled error events
    await client.connect();
    fastify.log.info('Redis connected');
  } catch (err) {
    fastify.log.warn('Redis not available — running without cache');
    // Provide a no-op redis stub for dev without Redis
    client = {
      get: async () => null,
      set: async () => 'OK',
      del: async () => 0,
      setex: async () => 'OK',
      ping: async () => 'PONG',
      exists: async () => 0,
      expire: async () => 0,
      keys: async () => [],
      quit: async () => {},
    };
  }

  fastify.decorate('redis', client);

  fastify.addHook('onClose', async () => {
    if (client.quit) await client.quit();
  });
}

export const redisPlugin = fp(redis, { name: 'redis' });
