/**
 * Branch & Floor Layout: branches, floor_sections, tables
 */
export async function up(knex) {
  await knex.schema.createTable('branches', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.string('address', 500);
    t.string('phone', 50);
    t.string('timezone', 100).defaultTo('Africa/Algiers');
    t.boolean('is_active').notNullable().defaultTo(true);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'id']);
    t.index(['tenant_id', 'is_active']);
  });

  await knex.schema.createTable('floor_sections', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').notNullable().references('id').inTable('branches').onDelete('CASCADE');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.integer('display_order').defaultTo(0);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'branch_id']);
  });

  await knex.schema.createTable('tables', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').notNullable().references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('section_id').references('id').inTable('floor_sections').onDelete('SET NULL');
    t.string('table_number', 20).notNullable();
    t.integer('seats').notNullable().defaultTo(4);
    t.float('pos_x').defaultTo(0);
    t.float('pos_y').defaultTo(0);
    t.float('width').defaultTo(80);
    t.float('height').defaultTo(80);
    t.string('shape', 20).defaultTo('rectangle'); // rectangle, circle, square
    t.string('status', 20).notNullable().defaultTo('available');
    // status: available, occupied, reserved, cleaning
    t.uuid('current_order_id');
    t.timestamp('occupied_since');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'branch_id']);
    t.index(['tenant_id', 'status']);
    t.unique(['tenant_id', 'branch_id', 'table_number']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('tables');
  await knex.schema.dropTableIfExists('floor_sections');
  await knex.schema.dropTableIfExists('branches');
}
