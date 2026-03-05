/**
 * Platform Layer: tenants, tenant_config, subscription_plans
 */
export async function up(knex) {
  // subscription_plans
  await knex.schema.createTable('subscription_plans', (t) => {
    t.uuid('id').primary();
    t.string('name', 100).notNullable();
    t.integer('max_branches').notNullable().defaultTo(1);
    t.integer('max_staff').notNullable().defaultTo(10);
    t.json('features_json');
    t.integer('max_users').notNullable().defaultTo(10);
    t.string('display_name_fr', 100);
    t.string('display_name_ar', 100);
    t.integer('monthly_price_cents').notNullable().defaultTo(0);
    t.integer('annual_price_cents').notNullable().defaultTo(0);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
  });

  // tenants
  await knex.schema.createTable('tenants', (t) => {
    t.uuid('id').primary();
    t.string('name', 255).notNullable();
    t.string('slug', 100).notNullable().unique();
    t.uuid('plan_id').references('id').inTable('subscription_plans').onDelete('SET NULL');
    t.string('plan_tier', 50).notNullable().defaultTo('starter');
    t.string('status', 50).notNullable().defaultTo('onboarding');
    // status: onboarding, active, suspended, cancelled
    t.string('billing_email', 255);
    t.string('country_code', 10).defaultTo('DZ');
    t.string('currency_code', 10).defaultTo('DZD');
    t.string('timezone', 100).defaultTo('Africa/Algiers');
    t.timestamp('subscription_start');
    t.timestamp('subscription_end');
    t.integer('max_branches').notNullable().defaultTo(1);
    t.string('logo_url', 500);
    t.string('phone', 50);
    t.string('address', 500);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
  });

  // tenant_config
  await knex.schema.createTable('tenant_config', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('key', 191).notNullable();
    t.json('value_json');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.unique(['tenant_id', 'key']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('tenant_config');
  await knex.schema.dropTableIfExists('tenants');
  await knex.schema.dropTableIfExists('subscription_plans');
}
