import bcrypt from 'bcrypt';
import { genId, ok } from '../../utils/helpers.js';

const BCRYPT_ROUNDS = 12;

export class AuthService {
  constructor(knex, redis, jwt) {
    this.knex = knex;
    this.redis = redis;
    this.jwt = jwt;
  }

  async login(email, password, deviceInfo, ipAddress) {
    const user = await this.knex('users')
      .where({ email })
      .whereNull('deleted_at')
      .first();

    if (!user) throw { status: 401, code: 'INVALID_CREDENTIALS', message_fr: 'Email ou mot de passe incorrect', message_ar: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' };
    if (!user.is_active) throw { status: 403, code: 'ACCOUNT_DISABLED', message_fr: 'Compte désactivé', message_ar: 'الحساب معطل' };

    const valid = await bcrypt.compare(password, user.password_hash);
    if (!valid) {
      // Track failed attempts
      const key = `login_fail:${ipAddress}`;
      const fails = await this.redis.get(key);
      const count = (parseInt(fails) || 0) + 1;
      await this.redis.setex(key, 900, count.toString());
      if (count >= 10) {
        await this.knex('users').where({ id: user.id }).update({ is_active: false });
      }
      throw { status: 401, code: 'INVALID_CREDENTIALS', message_fr: 'Email ou mot de passe incorrect', message_ar: 'البريد الإلكتروني أو كلمة المرور غير صحيحة' };
    }

    // Load role permissions
    let permissions = [];
    if (user.role_id) {
      const role = await this.knex('roles').where({ id: user.role_id }).first();
      if (role) {
        permissions = typeof role.permissions_json === 'string'
          ? JSON.parse(role.permissions_json)
          : (role.permissions_json || []);
      }
    }

    // Get branch
    const branch = await this.knex('branches')
      .where({ tenant_id: user.tenant_id })
      .whereNull('deleted_at')
      .where({ is_active: true })
      .first();

    const tokenPayload = {
      sub: user.id,
      tenant_id: user.tenant_id,
      role: user.role,
      permissions,
      branch_id: branch?.id || null,
      locale: user.preferred_locale,
    };

    const jti = genId();
    const accessToken = this.jwt.sign({ ...tokenPayload, jti });
    const refreshToken = this.jwt.signRefresh({ sub: user.id, tenant_id: user.tenant_id, jti: genId() });

    // Store refresh token
    const refreshHash = await bcrypt.hash(refreshToken, 6);
    await this.knex('refresh_tokens').insert({
      id: genId(),
      user_id: user.id,
      tenant_id: user.tenant_id,
      token_hash: refreshHash,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      device_info: deviceInfo,
      ip_address: ipAddress,
      user_agent: deviceInfo,
    });

    // Update last login
    await this.knex('users').where({ id: user.id }).update({ last_login_at: new Date() });

    // Clear failed attempts
    await this.redis.del(`login_fail:${ipAddress}`);

    return {
      access_token: accessToken,
      refresh_token: refreshToken,
      user: this._sanitizeUser(user, permissions, branch),
    };
  }

  async loginPin(pin, branchId, deviceInfo, ipAddress) {
    // PIN login searches all active users in the branch tenant
    const users = await this.knex('users')
      .whereNull('deleted_at')
      .where({ is_active: true })
      .whereNotNull('pin_hash')
      .select('*');

    let matchedUser = null;
    for (const user of users) {
      const valid = await bcrypt.compare(pin, user.pin_hash);
      if (valid) {
        matchedUser = user;
        break;
      }
    }

    if (!matchedUser) {
      throw { status: 401, code: 'INVALID_PIN', message_fr: 'Code PIN incorrect', message_ar: 'رمز PIN غير صحيح' };
    }

    let permissions = [];
    if (matchedUser.role_id) {
      const role = await this.knex('roles').where({ id: matchedUser.role_id }).first();
      if (role) permissions = typeof role.permissions_json === 'string' ? JSON.parse(role.permissions_json) : (role.permissions_json || []);
    }

    const branch = branchId
      ? await this.knex('branches').where({ id: branchId }).first()
      : await this.knex('branches').where({ tenant_id: matchedUser.tenant_id, is_active: true }).whereNull('deleted_at').first();

    const tokenPayload = {
      sub: matchedUser.id,
      tenant_id: matchedUser.tenant_id,
      role: matchedUser.role,
      permissions,
      branch_id: branch?.id || null,
      locale: matchedUser.preferred_locale,
    };

    // Short-lived token for POS
    const accessToken = this.jwt.sign({ ...tokenPayload, jti: genId() }, { expiresIn: '8h' });

    await this.knex('users').where({ id: matchedUser.id }).update({ last_login_at: new Date() });

    return {
      access_token: accessToken,
      user: this._sanitizeUser(matchedUser, permissions, branch),
    };
  }

  async refresh(refreshToken, ipAddress, userAgent) {
    // Decode the refresh token first
    let payload;
    try {
      payload = this.jwt.verify(refreshToken);
    } catch {
      throw { status: 401, code: 'INVALID_REFRESH', message_fr: 'Session expirée', message_ar: 'انتهت الجلسة' };
    }

    // Find and validate stored token
    const stored = await this.knex('refresh_tokens')
      .where({ user_id: payload.sub })
      .whereNull('revoked_at')
      .where('expires_at', '>', new Date())
      .orderBy('created_at', 'desc')
      .first();

    if (!stored) {
      throw { status: 401, code: 'INVALID_REFRESH', message_fr: 'Session expirée', message_ar: 'انتهت الجلسة' };
    }

    // Revoke old token
    await this.knex('refresh_tokens').where({ id: stored.id }).update({ revoked_at: new Date() });

    // Load user
    const user = await this.knex('users').where({ id: payload.sub }).whereNull('deleted_at').first();
    if (!user || !user.is_active) {
      throw { status: 401, code: 'ACCOUNT_DISABLED', message_fr: 'Compte désactivé', message_ar: 'الحساب معطل' };
    }

    let permissions = [];
    if (user.role_id) {
      const role = await this.knex('roles').where({ id: user.role_id }).first();
      if (role) permissions = typeof role.permissions_json === 'string' ? JSON.parse(role.permissions_json) : (role.permissions_json || []);
    }

    const branch = await this.knex('branches').where({ tenant_id: user.tenant_id, is_active: true }).whereNull('deleted_at').first();

    const tokenPayload = {
      sub: user.id,
      tenant_id: user.tenant_id,
      role: user.role,
      permissions,
      branch_id: branch?.id || null,
      locale: user.preferred_locale,
    };

    const newAccess = this.jwt.sign({ ...tokenPayload, jti: genId() });
    const newRefresh = this.jwt.signRefresh({ sub: user.id, tenant_id: user.tenant_id, jti: genId() });

    // Store new refresh token
    const refreshHash = await bcrypt.hash(newRefresh, 6);
    await this.knex('refresh_tokens').insert({
      id: genId(),
      user_id: user.id,
      tenant_id: user.tenant_id,
      token_hash: refreshHash,
      expires_at: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      ip_address: ipAddress,
      user_agent: userAgent,
    });

    return { access_token: newAccess, refresh_token: newRefresh };
  }

  async logout(userId) {
    await this.knex('refresh_tokens')
      .where({ user_id: userId })
      .whereNull('revoked_at')
      .update({ revoked_at: new Date() });
  }

  async me(userId) {
    const user = await this.knex('users').where({ id: userId }).whereNull('deleted_at').first();
    if (!user) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Utilisateur non trouvé', message_ar: 'المستخدم غير موجود' };

    let permissions = [];
    if (user.role_id) {
      const role = await this.knex('roles').where({ id: user.role_id }).first();
      if (role) permissions = typeof role.permissions_json === 'string' ? JSON.parse(role.permissions_json) : (role.permissions_json || []);
    }

    const branch = await this.knex('branches').where({ tenant_id: user.tenant_id, is_active: true }).whereNull('deleted_at').first();

    return this._sanitizeUser(user, permissions, branch);
  }

  async changePassword(userId, oldPassword, newPassword) {
    const user = await this.knex('users').where({ id: userId }).first();
    if (!user) throw { status: 404, code: 'NOT_FOUND', message_fr: 'Utilisateur non trouvé', message_ar: 'المستخدم غير موجود' };

    const valid = await bcrypt.compare(oldPassword, user.password_hash);
    if (!valid) throw { status: 401, code: 'WRONG_PASSWORD', message_fr: 'Ancien mot de passe incorrect', message_ar: 'كلمة المرور القديمة غير صحيحة' };

    if (newPassword.length < 8) throw { status: 422, code: 'WEAK_PASSWORD', message_fr: 'Le mot de passe doit contenir au moins 8 caractères', message_ar: 'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل' };

    const hash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await this.knex('users').where({ id: userId }).update({
      password_hash: hash,
      force_password_change: false,
      updated_at: new Date(),
    });
  }

  async setupPassword(token, newPassword) {
    const user = await this.knex('users')
      .where({ onboarding_token: token })
      .where('onboarding_token_expires_at', '>', new Date())
      .first();

    if (!user) throw { status: 400, code: 'INVALID_TOKEN', message_fr: 'Lien expiré ou invalide', message_ar: 'الرابط منتهي الصلاحية أو غير صالح' };
    if (newPassword.length < 8) throw { status: 422, code: 'WEAK_PASSWORD', message_fr: 'Le mot de passe doit contenir au moins 8 caractères', message_ar: 'يجب أن تحتوي كلمة المرور على 8 أحرف على الأقل' };

    const hash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    await this.knex('users').where({ id: user.id }).update({
      password_hash: hash,
      onboarding_token: null,
      onboarding_token_expires_at: null,
      force_password_change: false,
      updated_at: new Date(),
    });
  }

  _sanitizeUser(user, permissions = [], branch = null) {
    return {
      id: user.id,
      tenant_id: user.tenant_id,
      email: user.email,
      phone: user.phone,
      first_name_fr: user.first_name_fr,
      first_name_ar: user.first_name_ar,
      last_name_fr: user.last_name_fr,
      last_name_ar: user.last_name_ar,
      role: user.role,
      permissions,
      preferred_locale: user.preferred_locale,
      is_active: user.is_active,
      branch: branch ? { id: branch.id, name_fr: branch.name_fr, name_ar: branch.name_ar } : null,
      force_password_change: user.force_password_change,
    };
  }
}
