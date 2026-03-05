/**
 * Staff & HR: shifts, attendance, leave_requests
 */
export async function up(knex) {
  await knex.schema.createTable('shifts', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('branch_id').notNullable().references('id').inTable('branches').onDelete('CASCADE');
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.timestamp('start_time').notNullable();
    t.timestamp('end_time').notNullable();
    t.integer('break_minutes').defaultTo(0);
    t.string('status', 20).notNullable().defaultTo('scheduled');
    // status: scheduled, active, completed, no_show
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'branch_id']);
    t.index(['tenant_id', 'user_id']);
    t.index(['tenant_id', 'start_time']);
  });

  await knex.schema.createTable('attendance', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.uuid('shift_id').references('id').inTable('shifts').onDelete('SET NULL');
    t.timestamp('clocked_in_at').notNullable();
    t.timestamp('clocked_out_at');
    t.string('clock_in_method', 20).defaultTo('pin');
    // clock_in_method: pin, nfc, biometric
    t.string('ip_address', 45);
    t.string('device_id', 255);
    t.float('hours_worked');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'user_id', 'created_at']);
    t.index(['tenant_id', 'clocked_in_at']);
  });

  await knex.schema.createTable('leave_requests', (t) => {
    t.uuid('id').primary();
    t.uuid('tenant_id').notNullable().references('id').inTable('tenants').onDelete('CASCADE');
    t.uuid('user_id').notNullable().references('id').inTable('users').onDelete('CASCADE');
    t.string('leave_type', 50).notNullable(); // annual, sick, personal, maternity, etc.
    t.date('start_date').notNullable();
    t.date('end_date').notNullable();
    t.float('days_count').notNullable();
    t.text('reason');
    t.string('status', 20).notNullable().defaultTo('pending');
    // status: pending, approved, rejected, cancelled
    t.uuid('reviewed_by_user_id').references('id').inTable('users').onDelete('SET NULL');
    t.text('review_notes');
    t.timestamp('created_at').notNullable().defaultTo(knex.fn.now());
    t.timestamp('updated_at').notNullable().defaultTo(knex.fn.now());
    t.index(['tenant_id', 'user_id']);
    t.index(['tenant_id', 'status']);
  });
}

export async function down(knex) {
  await knex.schema.dropTableIfExists('leave_requests');
  await knex.schema.dropTableIfExists('attendance');
  await knex.schema.dropTableIfExists('shifts');
}
