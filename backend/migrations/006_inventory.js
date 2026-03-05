/**
 * Inventory: ingredients, stock_movements, suppliers,
 *            purchase_orders, purchase_order_lines, waste_logs
 */
export async function up(knex) {
  await knex.schema.createTable('suppliers', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('name', 255).notNullable();
    t.string('contact_name', 255);
    t.string('email', 255);
    t.string('phone', 50);
    t.string('address', 500);
    t.string('payment_terms', 100);
    t.integer('lead_days').defaultTo(0);
    t.float('rating');
    t.boolean('is_active').notNullable().defaultTo(true);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id']);
  });

  await knex.schema.createTable('ingredients', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').references('id').inTable('branches').onDelete('CASCADE');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.string('unit', 30).notNullable(); // kg, g, L, mL, piece, bunch
    t.string('category', 100); // produce, meat, dairy, dry_goods, beverage, etc.
    t.float('current_stock').notNullable().defaultTo(0);
    t.float('par_level').notNullable().defaultTo(0);
    t.float('reorder_quantity').defaultTo(0);
    t.integer('cost_per_unit_cents').defaultTo(0);
    t.uuid('supplier_id').references('id').inTable('suppliers').onDelete('SET NULL');
    t.string('barcode', 100);
    t.string('storage_location', 100);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'branch_id']);
    t.index(['tenant_id', 'category']);
    t.index(['barcode']);
  });

  // Add FK from recipe_ingredients to ingredients
  await knex.schema.alterTable('recipe_ingredients', (t) => {
    t.foreign('ingredient_id').references('id').inTable('ingredients').onDelete('CASCADE');
  });

  await knex.schema.createTable('stock_movements', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('ingredient_id').notNullable().references('id').inTable('ingredients').onDelete('CASCADE');
    t.string('movement_type', 30).notNullable();
    // movement_type: purchase, sale_deduction, waste, adjustment, stock_count
    t.float('quantity_delta').notNullable();
    t.float('stock_after').notNullable();
    t.uuid('reference_id'); // order_id, po_id, waste_log_id, etc.
    t.string('reference_type', 50); // order, purchase_order, waste_log, stock_count
    t.text('notes');
    t.uuid('performed_by_user_id').references('id').inTable('users').onDelete('SET NULL');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'ingredient_id']);
    t.index(['tenant_id', 'created_at']);
    t.index(['tenant_id', 'movement_type']);
  });

  await knex.schema.createTable('purchase_orders', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').notNullable().references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('supplier_id').notNullable().references('id').inTable('suppliers').onDelete('CASCADE');
    t.string('status', 30).notNullable().defaultTo('draft');
    // status: draft, pending_approval, approved, sent, partial_received, received, cancelled
    t.integer('subtotal_cents').defaultTo(0);
    t.integer('tax_cents').defaultTo(0);
    t.integer('total_cents').defaultTo(0);
    t.uuid('approved_by_user_id').references('id').inTable('users').onDelete('SET NULL');
    t.timestamp('sent_at');
    t.date('expected_delivery_date');
    t.text('notes');
    t.uuid('created_by_user_id').references('id').inTable('users').onDelete('SET NULL');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'status']);
    t.index(['tenant_id', 'supplier_id']);
  });

  await knex.schema.createTable('purchase_order_lines', (t) => {
    t.uuid('id').primary();
    t.uuid('po_id').notNullable().references('id').inTable('purchase_orders').onDelete('CASCADE');
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('ingredient_id').notNullable().references('id').inTable('ingredients').onDelete('CASCADE');
    t.float('quantity_ordered').notNullable();
    t.float('quantity_received').defaultTo(0);
    t.integer('unit_price_cents').notNullable().defaultTo(0);
    t.integer('total_cents').notNullable().defaultTo(0);
    t.timestamp('received_at');
    t.text('discrepancy_notes');
    t.index(['po_id']);
    t.index(['tenant_id']);
  });

  await knex.schema.createTable('waste_logs', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').notNullable().references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('ingredient_id').notNullable().references('id').inTable('ingredients').onDelete('CASCADE');
    t.float('quantity').notNullable();
    t.string('unit', 30).notNullable();
    t.string('waste_type', 30).notNullable();
    // waste_type: spoilage, over_prep, plate_return, other
    t.integer('cost_cents').defaultTo(0);
    t.text('notes');
    t.uuid('logged_by_user_id').references('id').inTable('users').onDelete('SET NULL');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'branch_id']);
    t.index(['tenant_id', 'created_at']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('waste_logs');
  await knex.schema.dropTableIfExists('purchase_order_lines');
  await knex.schema.dropTableIfExists('purchase_orders');
  await knex.schema.dropTableIfExists('stock_movements');
  await knex.schema.alterTable('recipe_ingredients', (t) => {
    t.dropForeign('ingredient_id');
  });
  await knex.schema.dropTableIfExists('ingredients');
  await knex.schema.dropTableIfExists('suppliers');
}
