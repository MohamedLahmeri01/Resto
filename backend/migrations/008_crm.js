/**
 * CRM & Reservations: customers, loyalty_tiers, loyalty_transactions,
 *                     reservations, notifications_log
 */
export async function up(knex) {
  await knex.schema.createTable('loyalty_tiers', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('name_fr', 100).notNullable();
    t.string('name_ar', 100);
    t.integer('min_points').notNullable().defaultTo(0);
    t.float('discount_pct').defaultTo(0);
    t.json('perks_json');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id']);
  });

  await knex.schema.createTable('customers', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('first_name', 100);
    t.string('last_name', 100);
    t.string('email', 191);
    t.string('phone', 50);
    t.date('birthday');
    t.string('preferred_locale', 10).defaultTo('fr');
    t.text('dietary_notes');
    t.uuid('loyalty_tier_id').references('id').inTable('loyalty_tiers').onDelete('SET NULL');
    t.integer('loyalty_points').defaultTo(0);
    t.integer('lifetime_spend_cents').defaultTo(0);
    t.integer('total_visits').defaultTo(0);
    t.timestamp('last_visit_at');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id']);
    t.index(['tenant_id', 'phone']);
    t.index(['tenant_id', 'email']);
  });

  // Now add FK from orders.customer_id to customers
  await knex.schema.alterTable('orders', (t) => {
    t.foreign('customer_id').references('id').inTable('customers').onDelete('SET NULL');
  });

  await knex.schema.createTable('loyalty_transactions', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('customer_id').notNullable().references('id').inTable('customers').onDelete('CASCADE');
    t.uuid('order_id').references('id').inTable('orders').onDelete('SET NULL');
    t.integer('points_delta').notNullable();
    t.integer('balance_after').notNullable();
    t.string('transaction_type', 30).notNullable();
    // transaction_type: earn, redeem, bonus, adjustment, tier_upgrade
    t.text('description');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'customer_id']);
  });

  await knex.schema.createTable('reservations', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').notNullable().references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('customer_id').references('id').inTable('customers').onDelete('SET NULL');
    t.uuid('table_id').references('id').inTable('tables').onDelete('SET NULL');
    t.integer('party_size').notNullable().defaultTo(2);
    t.date('date').notNullable();
    t.time('time_slot').notNullable();
    t.integer('duration_minutes').defaultTo(90);
    t.string('status', 20).notNullable().defaultTo('pending');
    // status: pending, confirmed, seated, completed, no_show, cancelled
    t.integer('deposit_amount_cents').defaultTo(0);
    t.boolean('deposit_paid').defaultTo(false);
    t.text('special_requests');
    t.string('confirmation_code', 20);
    t.string('customer_name', 200);
    t.string('customer_phone', 50);
    t.string('customer_email', 255);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'branch_id', 'date']);
    t.index(['tenant_id', 'status']);
    t.index(['confirmation_code']);
  });

  await knex.schema.createTable('notifications_log', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('recipient', 255).notNullable(); // email, phone, or device_token
    t.string('channel', 20).notNullable(); // email, sms, push
    t.string('template', 100);
    t.string('subject', 500);
    t.text('body');
    t.string('status', 20).notNullable().defaultTo('queued');
    // status: queued, sent, delivered, failed, bounced
    t.string('provider_message_id', 255);
    t.text('error_message');
    t.timestamp('sent_at');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'channel']);
    t.index(['tenant_id', 'created_at']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('notifications_log');
  await knex.schema.dropTableIfExists('reservations');
  await knex.schema.dropTableIfExists('loyalty_transactions');
  await knex.schema.alterTable('orders', (t) => {
    t.dropForeign('customer_id');
  });
  await knex.schema.dropTableIfExists('customers');
  await knex.schema.dropTableIfExists('loyalty_tiers');
}
