import { AuthService } from './service.js';
import { verifyJWT } from '../../middleware/verifyJWT.js';
import { ok } from '../../utils/helpers.js';

export default async function authRoutes(fastify) {
  const authService = new AuthService(fastify.knex, fastify.redis, fastify.jwt);

  // POST /auth/login
  fastify.post('/login', {
    schema: {
      body: {
        type: 'object',
        required: ['email', 'password'],
        properties: {
          email: { type: 'string', format: 'email' },
          password: { type: 'string', minLength: 1 },
        },
      },
    },
  }, async (request, reply) => {
    const { email, password } = request.body;
    const result = await authService.login(
      email.toLowerCase().trim(),
      password,
      request.headers['user-agent'],
      request.ip,
    );

    // Set refresh token as httpOnly cookie
    reply.setCookie('refresh_token', result.refresh_token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'Strict',
      path: '/v1/auth/refresh',
      maxAge: 7 * 24 * 60 * 60, // 7 days
    });

    return ok({ access_token: result.access_token, refresh_token: result.refresh_token, user: result.user });
  });

  // POST /auth/login/pin
  fastify.post('/login/pin', {
    schema: {
      body: {
        type: 'object',
        required: ['pin'],
        properties: {
          pin: { type: 'string', minLength: 4, maxLength: 6 },
          branch_id: { type: 'string' },
        },
      },
    },
  }, async (request, reply) => {
    const { pin, branch_id } = request.body;
    const result = await authService.loginPin(pin, branch_id, request.headers['user-agent'], request.ip);
    return ok(result);
  });

  // POST /auth/refresh
  fastify.post('/refresh', async (request, reply) => {
    const refreshToken = request.cookies?.refresh_token || request.body?.refresh_token;
    if (!refreshToken) {
      return reply.code(401).send({ success: false, error: { code: 'NO_REFRESH_TOKEN', message_fr: 'Token de rafraîchissement manquant', message_ar: 'رمز التحديث مفقود' } });
    }

    const result = await authService.refresh(refreshToken, request.ip, request.headers['user-agent']);

    reply.setCookie('refresh_token', result.refresh_token, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'Strict',
      path: '/v1/auth/refresh',
      maxAge: 7 * 24 * 60 * 60,
    });

    return ok({ access_token: result.access_token, refresh_token: result.refresh_token });
  });

  // POST /auth/logout
  fastify.post('/logout', { preHandler: [verifyJWT] }, async (request, reply) => {
    await authService.logout(request.user.sub);
    reply.clearCookie('refresh_token', { path: '/v1/auth/refresh' });
    return ok({ message: 'Logged out' });
  });

  // GET /auth/me
  fastify.get('/me', { preHandler: [verifyJWT] }, async (request) => {
    const user = await authService.me(request.user.sub);
    return ok(user);
  });

  // POST /auth/change-password
  fastify.post('/change-password', {
    preHandler: [verifyJWT],
    schema: {
      body: {
        type: 'object',
        required: ['old_password', 'new_password'],
        properties: {
          old_password: { type: 'string' },
          new_password: { type: 'string', minLength: 8 },
        },
      },
    },
  }, async (request) => {
    await authService.changePassword(request.user.sub, request.body.old_password, request.body.new_password);
    return ok({ message: 'Password changed' });
  });

  // POST /auth/setup-password
  fastify.post('/setup-password', {
    schema: {
      body: {
        type: 'object',
        required: ['token', 'password'],
        properties: {
          token: { type: 'string' },
          password: { type: 'string', minLength: 8 },
        },
      },
    },
  }, async (request) => {
    await authService.setupPassword(request.body.token, request.body.password);
    return ok({ message: 'Password set successfully' });
  });
}
