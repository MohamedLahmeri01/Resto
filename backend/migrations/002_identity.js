/**
 * Identity & Access: roles, users, refresh_tokens, audit_log
 */
export async function up(knex) {
  // roles
  await knex.schema.createTable('roles', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('name', 100).notNullable();
    t.json('permissions_json'); // array of permission strings
    t.boolean('is_system_role').notNullable().defaultTo(false);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'name']);
  });

  // users
  await knex.schema.createTable('users', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('email', 191).notNullable();
    t.string('phone', 50);
    t.string('password_hash', 255);
    t.string('first_name_fr', 100);
    t.string('first_name_ar', 100);
    t.string('last_name_fr', 100);
    t.string('last_name_ar', 100);
    t.string('role', 50).notNullable().defaultTo('staff');
    // role: super_admin, owner, manager, cashier, waiter, chef, host, staff
    t.uuid('role_id').references('id').inTable('roles').onDelete('SET NULL');
    t.uuid('branch_id');
    t.string('pin_hash', 255);
    t.string('preferred_locale', 10).defaultTo('fr');
    t.boolean('is_active').notNullable().defaultTo(true);
    t.timestamp('last_login_at');
    t.uuid('created_by_user_id');
    t.string('onboarding_token', 255);
    t.timestamp('onboarding_token_expires_at');
    t.boolean('force_password_change').defaultTo(false);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.unique(['tenant_id', 'email']);
    t.index(['tenant_id', 'id']);
    t.index(['tenant_id', 'role']);
    t.index(['tenant_id', 'is_active']);
  });

  // refresh_tokens
  await knex.schema.createTable('refresh_tokens', (t) => {
    t.uuid('id').primary();
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('token_hash', 255).notNullable();
    t.timestamp('expires_at').notNullable();
    t.timestamp('revoked_at');
    t.string('device_info', 500);
    t.string('ip_address', 45);
    t.string('user_agent', 500);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['user_id']);
    t.index(['token_hash']);
  });

  // audit_log (append-only)
  await knex.schema.createTable('audit_log', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('user_id').references('id').inTable('users').onDelete('SET NULL');
    t.string('action', 100).notNullable();
    t.string('entity_type', 100);
    t.uuid('entity_id');
    t.json('old_value_json');
    t.json('new_value_json');
    t.string('ip_address', 45);
    t.string('user_agent', 500);
    t.boolean('is_offline').defaultTo(false);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'created_at']);
    t.index(['tenant_id', 'entity_type', 'entity_id']);
    t.index(['tenant_id', 'user_id']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('audit_log');
  await knex.schema.dropTableIfExists('refresh_tokens');
  await knex.schema.dropTableIfExists('users');
  await knex.schema.dropTableIfExists('roles');
}
