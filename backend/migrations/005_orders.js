/**
 * Orders & Payments: orders, order_items, order_item_modifiers,
 *                    payments, discounts_applied, discount_rules, discount_codes
 */
export async function up(knex) {
  // discount_rules (referenced by discounts_applied)
  await knex.schema.createTable('discount_rules', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.string('discount_type', 30).notNullable();
    // discount_type: percentage, fixed, bogo, category_pct, happy_hour
    t.float('value').notNullable(); // percentage or fixed amount in cents
    t.json('conditions_json'); // time range, minimum order, applicable categories
    t.boolean('requires_manager_approval').defaultTo(false);
    t.integer('max_uses');
    t.integer('used_count').defaultTo(0);
    t.timestamp('start_at');
    t.timestamp('end_at');
    t.boolean('is_active').notNullable().defaultTo(true);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'is_active']);
  });

  await knex.schema.createTable('discount_codes', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('discount_rule_id').notNullable().references('id').inTable('discount_rules').onDelete('CASCADE');
    t.string('code', 50).notNullable();
    t.boolean('is_single_use').defaultTo(true);
    t.boolean('is_redeemed').defaultTo(false);
    t.uuid('redeemed_by_order_id');
    t.timestamp('redeemed_at');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.unique(['tenant_id', 'code']);
  });

  await knex.schema.createTable('orders', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').notNullable().references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('table_id').references('id').inTable('tables').onDelete('SET NULL');
    t.string('order_type', 20).notNullable().defaultTo('dine_in');
    // order_type: dine_in, takeaway, delivery
    t.string('status', 20).notNullable().defaultTo('draft');
    // status: draft, sent, in_progress, ready, served, closed, voided, refunded
    t.uuid('customer_id');
    t.uuid('waiter_id').references('id').inTable('users').onDelete('SET NULL');
    t.integer('covers_count').defaultTo(1);
    t.integer('subtotal_cents').defaultTo(0);
    t.integer('discount_cents').defaultTo(0);
    t.integer('tax_cents').defaultTo(0);
    t.integer('total_cents').defaultTo(0);
    t.json('tax_breakdown_json');
    t.text('notes');
    t.string('source', 50).defaultTo('pos'); // pos, qr, aggregator
    t.string('external_order_id', 255); // for aggregator orders
    t.boolean('is_offline').defaultTo(false);
    t.string('order_number', 20); // human-readable daily number
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('closed_at');
    t.timestamp('voided_at');
    t.index(['tenant_id', 'status']);
    t.index(['tenant_id', 'branch_id', 'created_at']);
    t.index(['tenant_id', 'table_id']);
    t.index(['tenant_id', 'waiter_id']);
    t.index(['tenant_id', 'customer_id']);
  });

  await knex.schema.createTable('order_items', (t) => {
    t.uuid('id').primary();
    t.uuid('order_id').notNullable().references('id').inTable('orders').onDelete('CASCADE');
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('item_id').references('id').inTable('menu_items').onDelete('SET NULL');
    t.string('name_fr', 255); // snapshot at order time
    t.string('name_ar', 255);
    t.integer('seat_number');
    t.integer('quantity').notNullable().defaultTo(1);
    t.integer('unit_price_cents').notNullable().defaultTo(0);
    t.integer('total_price_cents').notNullable().defaultTo(0);
    t.text('notes');
    t.boolean('allergen_alert').defaultTo(false);
    t.integer('course_number').defaultTo(1);
    t.string('status', 20).notNullable().defaultTo('pending');
    // status: pending, fired, in_progress, ready, served, voided
    t.string('prep_station', 50);
    t.timestamp('fired_at');
    t.timestamp('ready_at');
    t.timestamp('served_at');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['order_id']);
    t.index(['tenant_id', 'status']);
    t.index(['tenant_id', 'prep_station', 'status']);
  });

  await knex.schema.createTable('order_item_modifiers', (t) => {
    t.uuid('id').primary();
    t.uuid('order_item_id').notNullable().references('id').inTable('order_items').onDelete('CASCADE');
    t.uuid('modifier_id').references('id').inTable('modifiers').onDelete('SET NULL');
    t.string('name_fr', 255);
    t.string('name_ar', 255);
    t.integer('price_delta_cents').defaultTo(0);
    t.index(['order_item_id']);
  });

  await knex.schema.createTable('payments', (t) => {
    t.uuid('id').primary();
    t.uuid('order_id').notNullable().references('id').inTable('orders').onDelete('CASCADE');
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('method', 30).notNullable();
    // method: cash, card_nfc, card_chip, card_swipe, qr_pay, voucher, gift_card
    t.integer('amount_cents').notNullable();
    t.string('reference', 255);
    t.string('gateway_transaction_id', 255);
    t.string('status', 20).notNullable().defaultTo('pending');
    // status: pending, captured, failed, refunded, voided
    t.uuid('cashier_id').references('id').inTable('users').onDelete('SET NULL');
    t.string('terminal_id', 100);
    t.integer('change_cents').defaultTo(0);
    t.timestamp('processed_at');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['order_id']);
    t.index(['tenant_id', 'method']);
    t.index(['tenant_id', 'created_at']);
  });

  await knex.schema.createTable('discounts_applied', (t) => {
    t.uuid('id').primary();
    t.uuid('order_id').notNullable().references('id').inTable('orders').onDelete('CASCADE');
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('discount_rule_id').references('id').inTable('discount_rules').onDelete('SET NULL');
    t.string('code_used', 50);
    t.uuid('applied_by_user_id').references('id').inTable('users').onDelete('SET NULL');
    t.string('discount_type', 30);
    t.float('discount_value');
    t.integer('amount_cents').notNullable();
    t.uuid('authorized_by_manager_id').references('id').inTable('users').onDelete('SET NULL');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['order_id']);
    t.index(['tenant_id']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('discounts_applied');
  await knex.schema.dropTableIfExists('payments');
  await knex.schema.dropTableIfExists('order_item_modifiers');
  await knex.schema.dropTableIfExists('order_items');
  await knex.schema.dropTableIfExists('orders');
  await knex.schema.dropTableIfExists('discount_codes');
  await knex.schema.dropTableIfExists('discount_rules');
}
