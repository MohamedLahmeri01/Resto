/**
 * Menu: categories, items, modifier_groups, modifiers, item_modifier_groups,
 *       menu_schedules, schedule_categories, recipes, recipe_ingredients
 */
export async function up(knex) {
  await knex.schema.createTable('menu_categories', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('parent_id').references('id').inTable('menu_categories').onDelete('SET NULL');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.string('photo_url', 500);
    t.integer('display_order').defaultTo(0);
    t.boolean('is_active').notNullable().defaultTo(true);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'branch_id']);
    t.index(['tenant_id', 'is_active']);
  });

  await knex.schema.createTable('menu_items', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('category_id').references('id').inTable('menu_categories').onDelete('SET NULL');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.text('description_fr');
    t.text('description_ar');
    t.string('photo_url', 500);
    t.integer('base_price_cents').notNullable().defaultTo(0);
    t.integer('calories');
    t.json('allergens_json'); // array of allergen strings
    t.boolean('is_available').notNullable().defaultTo(true);
    t.boolean('is_86d').notNullable().defaultTo(false);
    t.string('prep_station', 50).defaultTo('grill');
    // prep_station: grill, cold, prep, pastry, bar
    t.integer('display_order').defaultTo(0);
    t.string('barcode', 100);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'branch_id']);
    t.index(['tenant_id', 'category_id']);
    t.index(['tenant_id', 'is_available']);
    t.index(['tenant_id', 'prep_station']);
  });

  await knex.schema.createTable('modifier_groups', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.string('selection_type', 30).notNullable().defaultTo('single_optional');
    // selection_type: single_required, single_optional, multi
    t.integer('min_selections').defaultTo(0);
    t.integer('max_selections').defaultTo(1);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id']);
  });

  await knex.schema.createTable('modifiers', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('group_id').notNullable().references('id').inTable('modifier_groups').onDelete('CASCADE');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.integer('price_delta_cents').notNullable().defaultTo(0);
    t.boolean('is_active').notNullable().defaultTo(true);
    t.integer('display_order').defaultTo(0);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('deleted_at');
    t.index(['tenant_id', 'group_id']);
  });

  // Junction table: menu_items <-> modifier_groups
  await knex.schema.createTable('item_modifier_groups', (t) => {
    t.uuid('item_id').notNullable().references('id').inTable('menu_items').onDelete('CASCADE');
    t.uuid('group_id').notNullable().references('id').inTable('modifier_groups').onDelete('CASCADE');
    t.integer('display_order').defaultTo(0);
    t.primary(['item_id', 'group_id']);
  });

  await knex.schema.createTable('menu_schedules', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').references('id').inTable('branches').onDelete('CASCADE');
    t.string('name_fr', 255).notNullable();
    t.string('name_ar', 255);
    t.string('days_of_week', 50); // e.g. "mon,tue,wed,thu,fri"
    t.time('start_time');
    t.time('end_time');
    t.boolean('is_active').notNullable().defaultTo(true);
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'branch_id']);
  });

  // Junction: schedules <-> categories
  await knex.schema.createTable('schedule_categories', (t) => {
    t.uuid('schedule_id').notNullable().references('id').inTable('menu_schedules').onDelete('CASCADE');
    t.uuid('category_id').notNullable().references('id').inTable('menu_categories').onDelete('CASCADE');
    t.primary(['schedule_id', 'category_id']);
  });

  await knex.schema.createTable('recipes', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('item_id').notNullable().references('id').inTable('menu_items').onDelete('CASCADE');
    t.text('instructions_fr');
    t.text('instructions_ar');
    t.string('plating_photo_url', 500);
    t.float('portion_weight_grams');
    t.integer('version').defaultTo(1);
    t.uuid('created_by_user_id').references('id').inTable('users').onDelete('SET NULL');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'item_id']);
  });

  await knex.schema.createTable('recipe_ingredients', (t) => {
    t.uuid('id').primary();
    t.uuid('recipe_id').notNullable().references('id').inTable('recipes').onDelete('CASCADE');
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('ingredient_id'); // FK added after ingredients table
    t.float('quantity').notNullable();
    t.string('unit', 30).notNullable();
    t.index(['recipe_id']);
    t.index(['tenant_id']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('recipe_ingredients');
  await knex.schema.dropTableIfExists('recipes');
  await knex.schema.dropTableIfExists('schedule_categories');
  await knex.schema.dropTableIfExists('menu_schedules');
  await knex.schema.dropTableIfExists('item_modifier_groups');
  await knex.schema.dropTableIfExists('modifiers');
  await knex.schema.dropTableIfExists('modifier_groups');
  await knex.schema.dropTableIfExists('menu_items');
  await knex.schema.dropTableIfExists('menu_categories');
}
