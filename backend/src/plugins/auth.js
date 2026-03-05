import fp from 'fastify-plugin';
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';
const ACCESS_EXPIRY = process.env.JWT_ACCESS_EXPIRY || '15m';
const REFRESH_EXPIRY = process.env.JWT_REFRESH_EXPIRY || '7d';

async function auth(fastify) {
  const jwtSign = (payload, options = {}) => {
    return jwt.sign(payload, JWT_SECRET, {
      expiresIn: options.expiresIn || ACCESS_EXPIRY,
      ...options,
    });
  };

  const jwtVerify = (token) => {
    return jwt.verify(token, JWT_SECRET);
  };

  const signRefreshToken = (payload) => {
    return jwt.sign(payload, JWT_SECRET, { expiresIn: REFRESH_EXPIRY });
  };

  fastify.decorate('jwt', { sign: jwtSign, verify: jwtVerify, signRefresh: signRefreshToken });

  // Decorators for request
  fastify.decorateRequest('user', null);
  fastify.decorateRequest('tenantId', null);
}

export const authPlugin = fp(auth, { name: 'auth' });
