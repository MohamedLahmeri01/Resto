import fp from 'fastify-plugin';
import knexLib from 'knex';
import knexConfig from '../../knexfile.js';

async function db(fastify) {
  const knex = knexLib.default(knexConfig);

  // Test connection
  await knex.raw('SELECT 1');
  fastify.log.info('Database connected');

  fastify.decorate('knex', knex);

  fastify.addHook('onClose', async () => {
    await knex.destroy();
  });
}

export const dbPlugin = fp(db, { name: 'db' });
