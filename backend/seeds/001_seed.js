import bcrypt from 'bcrypt';
import { v4 as uuidv4 } from 'uuid';
import crypto from 'crypto';

const genId = () => uuidv4();
const BCRYPT_ROUNDS = 12;

export async function seed(knex) {
  // Clean in reverse FK order
  const tables = [
    'notifications_log', 'loyalty_transactions', 'reservations', 'customers', 'loyalty_tiers',
    'leave_requests', 'attendance', 'shifts',
    'waste_logs', 'purchase_order_lines', 'purchase_orders', 'stock_movements', 'suppliers',
    'recipe_ingredients', 'recipes',
    'discounts_applied', 'payments', 'order_item_modifiers', 'order_items', 'orders',
    'discount_codes', 'discount_rules',
    'schedule_categories', 'menu_schedules', 'item_modifier_groups', 'modifiers', 'modifier_groups',
    'menu_items', 'menu_categories',
    'tables', 'floor_sections', 'branches',
    'audit_log', 'refresh_tokens', 'users', 'roles',
    'tenant_config', 'tenants', 'subscription_plans',
    'ingredients',
  ];
  for (const t of tables) {
    try { await knex(t).del(); } catch { /* table may not exist */ }
  }

  // â”€â”€ Subscription Plans â”€â”€
  const planStarter = genId();
  const planPro = genId();
  const planEnterprise = genId();
  await knex('subscription_plans').insert([
    { id: planStarter, name: 'starter', display_name_fr: 'Starter', display_name_ar: 'Ø£Ø³Ø§Ø³ÙŠ', monthly_price_cents: 500000, max_branches: 1, max_users: 5, features_json: JSON.stringify(['pos', 'orders', 'menu', 'tables']) },
    { id: planPro, name: 'pro', display_name_fr: 'Professionnel', display_name_ar: 'Ø§Ø­ØªØ±Ø§ÙÙŠ', monthly_price_cents: 1500000, max_branches: 3, max_users: 20, features_json: JSON.stringify(['pos', 'orders', 'menu', 'tables', 'inventory', 'staff', 'reports', 'crm', 'kds']) },
    { id: planEnterprise, name: 'enterprise', display_name_fr: 'Enterprise', display_name_ar: 'Ù…Ø¤Ø³Ø³Ø§Øª', monthly_price_cents: 3500000, max_branches: 50, max_users: 500, features_json: JSON.stringify(['*']) },
  ]);

  // â”€â”€ Tenant (Demo Restaurant) â”€â”€
  const tenantId = genId();
  await knex('tenants').insert({
    id: tenantId, name: 'Restaurant El Djazair', slug: 'el-djazair',
    plan_id: planPro, plan_tier: 'pro', status: 'active',
    billing_email: 'admin@eldjazair.dz',
    country_code: 'DZ', currency_code: 'DZD', timezone: 'Africa/Algiers',
    max_branches: 3, subscription_start: new Date(),
    subscription_end: new Date(Date.now() + 365 * 24 * 60 * 60 * 1000),
  });

  // â”€â”€ Tenant Config â”€â”€
  const configs = [
    { key: 'default_locale', value: 'fr' },
    { key: 'tax_rate', value: 19 },
    { key: 'table_turn_alert_minutes', value: 90 },
    { key: 'low_stock_default_par', value: 10 },
    { key: 'opening_float_cents', value: 500000 },
    { key: 'receipt_header_fr', value: 'Restaurant El Djazair' },
    { key: 'receipt_header_ar', value: 'Ù…Ø·Ø¹Ù… Ø§Ù„Ø¬Ø²Ø§Ø¦Ø±' },
    { key: 'receipt_footer_fr', value: 'Merci de votre visite !' },
    { key: 'receipt_footer_ar', value: 'Ø´ÙƒØ±Ø§Ù‹ Ù„Ø²ÙŠØ§Ø±ØªÙƒÙ…!' },
    { key: 'loyalty_points_per_100_cents', value: 1 },
    { key: 'wifi_password', value: 'bienvenue2024' },
  ];
  for (const c of configs) {
    await knex('tenant_config').insert({ id: genId(), tenant_id: tenantId, key: c.key, value_json: JSON.stringify(c.value) });
  }

  // â”€â”€ Roles â”€â”€
  const ownerRoleId = genId();
  const managerRoleId = genId();
  const cashierRoleId = genId();
  const waiterRoleId = genId();
  const chefRoleId = genId();
  await knex('roles').insert([
    { id: ownerRoleId, tenant_id: tenantId, name: 'owner', permissions_json: JSON.stringify(['*']), is_system_role: true },
    { id: managerRoleId, tenant_id: tenantId, name: 'manager', permissions_json: JSON.stringify(['orders.*', 'menu.*', 'tables.*', 'staff.*', 'inventory.*', 'reports.*', 'crm.*', 'finance.*', 'kds.*', 'notifications.*']), is_system_role: true },
    { id: cashierRoleId, tenant_id: tenantId, name: 'cashier', permissions_json: JSON.stringify(['orders.create', 'orders.update', 'payments.create', 'tables.update', 'menu.read', 'kds.bump', 'crm.read']), is_system_role: true },
    { id: waiterRoleId, tenant_id: tenantId, name: 'waiter', permissions_json: JSON.stringify(['orders.create', 'orders.update', 'tables.update', 'menu.read']), is_system_role: true },
    { id: chefRoleId, tenant_id: tenantId, name: 'chef', permissions_json: JSON.stringify(['kds.bump', 'menu.read', 'inventory.read']), is_system_role: true },
  ]);

  // â”€â”€ Branch â”€â”€
  const branchId = genId();
  await knex('branches').insert({
    id: branchId, tenant_id: tenantId,
    name_fr: 'Centre-ville', name_ar: 'ÙˆØ³Ø· Ø§Ù„Ù…Ø¯ÙŠÙ†Ø©',
    address: '12 Rue Didouche Mourad, Alger, DZ',
    phone: '+213555123456', is_active: true,
  });

  // â”€â”€ Users â”€â”€
  const adminPass = await bcrypt.hash('Admin@2024', BCRYPT_ROUNDS);
  const managerPass = await bcrypt.hash('Manager@2024', BCRYPT_ROUNDS);
  const cashierPin = await bcrypt.hash('1234', 6);
  const waiterPin = await bcrypt.hash('5678', 6);
  const chefPin = await bcrypt.hash('9999', 6);

  const adminId = genId();
  const managerId = genId();
  const cashierId = genId();
  const waiterId = genId();
  const chefId = genId();
  const superAdminId = genId();

  await knex('users').insert([
    { id: superAdminId, tenant_id: tenantId, first_name_fr: 'Super', last_name_fr: 'Admin', first_name_ar: 'Ø§Ù„Ù…Ø´Ø±Ù', last_name_ar: 'Ø§Ù„Ø¹Ø§Ù…', email: 'super@rms.local', password_hash: adminPass, role: 'super_admin', role_id: ownerRoleId, branch_id: branchId, is_active: true, preferred_locale: 'fr' },
    { id: adminId, tenant_id: tenantId, first_name_fr: 'Ahmed', last_name_fr: 'Bensalah', first_name_ar: 'Ø£Ø­Ù…Ø¯', last_name_ar: 'Ø¨Ù† ØµØ§Ù„Ø­', email: 'ahmed@eldjazair.dz', password_hash: adminPass, role: 'owner', role_id: ownerRoleId, branch_id: branchId, is_active: true, preferred_locale: 'fr' },
    { id: managerId, tenant_id: tenantId, first_name_fr: 'Karim', last_name_fr: 'Mebarki', first_name_ar: 'ÙƒØ±ÙŠÙ…', last_name_ar: 'Ù…Ø¨Ø§Ø±ÙƒÙŠ', email: 'karim@eldjazair.dz', password_hash: managerPass, role: 'manager', role_id: managerRoleId, branch_id: branchId, is_active: true, preferred_locale: 'fr' },
    { id: cashierId, tenant_id: tenantId, first_name_fr: 'Samira', last_name_fr: 'Boudiaf', first_name_ar: 'Ø³Ù…ÙŠØ±Ø©', last_name_ar: 'Ø¨ÙˆØ¶ÙŠØ§Ù', email: 'samira@eldjazair.dz', password_hash: managerPass, pin_hash: cashierPin, role: 'cashier', role_id: cashierRoleId, branch_id: branchId, is_active: true, preferred_locale: 'fr' },
    { id: waiterId, tenant_id: tenantId, first_name_fr: 'Yassine', last_name_fr: 'Hadjadj', first_name_ar: 'ÙŠØ§Ø³ÙŠÙ†', last_name_ar: 'Ø­Ø¬Ø§Ø¬', email: 'yassine@eldjazair.dz', password_hash: managerPass, pin_hash: waiterPin, role: 'waiter', role_id: waiterRoleId, branch_id: branchId, is_active: true, preferred_locale: 'ar' },
    { id: chefId, tenant_id: tenantId, first_name_fr: 'Omar', last_name_fr: 'Khelif', first_name_ar: 'Ø¹Ù…Ø±', last_name_ar: 'Ø®Ù„ÙŠÙ', email: 'omar@eldjazair.dz', password_hash: managerPass, pin_hash: chefPin, role: 'chef', role_id: chefRoleId, branch_id: branchId, is_active: true, preferred_locale: 'ar' },
  ]);

  // â”€â”€ Floor Sections & Tables â”€â”€
  const sallePrincipale = genId();
  const terrasse = genId();
  await knex('floor_sections').insert([
    { id: sallePrincipale, tenant_id: tenantId, branch_id: branchId, name_fr: 'Salle Principale', name_ar: 'Ø§Ù„Ù‚Ø§Ø¹Ø© Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©', display_order: 1 },
    { id: terrasse, tenant_id: tenantId, branch_id: branchId, name_fr: 'Terrasse', name_ar: 'Ø§Ù„Ø´Ø±ÙØ©', display_order: 2 },
  ]);

  const tableData = [];
  for (let i = 1; i <= 8; i++) {
    tableData.push({
      id: genId(), tenant_id: tenantId, branch_id: branchId, section_id: sallePrincipale,
      table_number: `T${i}`, seats: i <= 4 ? 4 : 6, status: 'available',
      pos_x: ((i - 1) % 4) * 180 + 50, pos_y: Math.floor((i - 1) / 4) * 180 + 50,
      width: 120, height: 120, shape: i <= 4 ? 'square' : 'round',
    });
  }
  for (let i = 1; i <= 4; i++) {
    tableData.push({
      id: genId(), tenant_id: tenantId, branch_id: branchId, section_id: terrasse,
      table_number: `TR${i}`, seats: 4, status: 'available',
      pos_x: (i - 1) * 200 + 50, pos_y: 50, width: 120, height: 120, shape: 'round',
    });
  }
  await knex('tables').insert(tableData);

  // â”€â”€ Menu Categories â”€â”€
  const catEntrees = genId();
  const catPlats = genId();
  const catGrillades = genId();
  const catDesserts = genId();
  const catBoissons = genId();
  const catBoissonsChaudes = genId();
  await knex('menu_categories').insert([
    { id: catEntrees, tenant_id: tenantId, name_fr: 'EntrÃ©es', name_ar: 'Ø§Ù„Ù…Ù‚Ø¨Ù„Ø§Øª', display_order: 1, is_active: true },
    { id: catPlats, tenant_id: tenantId, name_fr: 'Plats Principaux', name_ar: 'Ø§Ù„Ø£Ø·Ø¨Ø§Ù‚ Ø§Ù„Ø±Ø¦ÙŠØ³ÙŠØ©', display_order: 2, is_active: true },
    { id: catGrillades, tenant_id: tenantId, name_fr: 'Grillades', name_ar: 'Ø§Ù„Ù…Ø´ÙˆÙŠØ§Øª', display_order: 3, is_active: true },
    { id: catDesserts, tenant_id: tenantId, name_fr: 'Desserts', name_ar: 'Ø§Ù„Ø­Ù„ÙˆÙŠØ§Øª', display_order: 4, is_active: true },
    { id: catBoissons, tenant_id: tenantId, name_fr: 'Boissons', name_ar: 'Ø§Ù„Ù…Ø´Ø±ÙˆØ¨Ø§Øª', display_order: 5, is_active: true },
    { id: catBoissonsChaudes, tenant_id: tenantId, name_fr: 'Boissons Chaudes', name_ar: 'Ø§Ù„Ù…Ø´Ø±ÙˆØ¨Ø§Øª Ø§Ù„Ø³Ø§Ø®Ù†Ø©', display_order: 6, is_active: true },
  ]);

  // â”€â”€ Menu Items â”€â”€
  const items = [
    // EntrÃ©es
    { id: genId(), tenant_id: tenantId, category_id: catEntrees, name_fr: 'Chorba Frik', name_ar: 'Ø´ÙˆØ±Ø¨Ø© ÙØ±ÙŠÙƒ', description_fr: 'Soupe traditionnelle algÃ©rienne au blÃ© vert', description_ar: 'Ø´ÙˆØ±Ø¨Ø© Ø¬Ø²Ø§Ø¦Ø±ÙŠØ© ØªÙ‚Ù„ÙŠØ¯ÙŠØ© Ø¨Ø§Ù„ÙØ±ÙŠÙƒ', base_price_cents: 45000, prep_station: 'hot', display_order: 1 },
    { id: genId(), tenant_id: tenantId, category_id: catEntrees, name_fr: 'Bourek au Fromage', name_ar: 'Ø¨ÙˆØ±Ùƒ Ø¨Ø§Ù„Ø¬Ø¨Ù†', description_fr: 'Rouleaux croustillants au fromage et herbes', description_ar: 'Ù„ÙØ§Ø¦Ù Ù…Ù‚Ø±Ù…Ø´Ø© Ø¨Ø§Ù„Ø¬Ø¨Ù† ÙˆØ§Ù„Ø£Ø¹Ø´Ø§Ø¨', base_price_cents: 35000, prep_station: 'hot', display_order: 2 },
    { id: genId(), tenant_id: tenantId, category_id: catEntrees, name_fr: 'Salade VariÃ©e', name_ar: 'Ø³Ù„Ø·Ø© Ù…ØªÙ†ÙˆØ¹Ø©', description_fr: 'Salade fraÃ®che de saison', description_ar: 'Ø³Ù„Ø·Ø© Ù…ÙˆØ³Ù…ÙŠØ© Ø·Ø§Ø²Ø¬Ø©', base_price_cents: 30000, prep_station: 'cold', display_order: 3 },
    { id: genId(), tenant_id: tenantId, category_id: catEntrees, name_fr: 'Hmiss', name_ar: 'Ø­Ù…ÙŠØ³', description_fr: 'Poivrons grillÃ©s et tomates', description_ar: 'ÙÙ„ÙÙ„ Ù…Ø´ÙˆÙŠ ÙˆØ·Ù…Ø§Ø·Ù…', base_price_cents: 25000, prep_station: 'cold', display_order: 4 },
    // Plats Principaux
    { id: genId(), tenant_id: tenantId, category_id: catPlats, name_fr: 'Couscous Royal', name_ar: 'ÙƒØ³ÙƒØ³ Ù…Ù„ÙƒÙŠ', description_fr: 'Couscous avec agneau, poulet et merguez', description_ar: 'ÙƒØ³ÙƒØ³ Ù…Ø¹ Ù„Ø­Ù… Ø§Ù„ØºÙ†Ù… ÙˆØ§Ù„Ø¯Ø¬Ø§Ø¬ ÙˆØ§Ù„Ù…Ø±Ù‚Ø§Ø²', base_price_cents: 120000, prep_station: 'hot', display_order: 1 },
    { id: genId(), tenant_id: tenantId, category_id: catPlats, name_fr: 'Tajine Zitoune', name_ar: 'Ø·Ø§Ø¬ÙŠÙ† Ø²ÙŠØªÙˆÙ†', description_fr: 'Poulet aux olives et citron confit', description_ar: 'Ø¯Ø¬Ø§Ø¬ Ø¨Ø§Ù„Ø²ÙŠØªÙˆÙ† ÙˆØ§Ù„Ù„ÙŠÙ…ÙˆÙ† Ø§Ù„Ù…Ø­ÙÙˆØ¸', base_price_cents: 95000, prep_station: 'hot', display_order: 2 },
    { id: genId(), tenant_id: tenantId, category_id: catPlats, name_fr: 'Rechta', name_ar: 'Ø±Ø´ØªØ©', description_fr: 'PÃ¢tes traditionnelles sauce blanche au poulet', description_ar: 'Ù…Ø¹ÙƒØ±ÙˆÙ†Ø© ØªÙ‚Ù„ÙŠØ¯ÙŠØ© Ø¨ØµÙ„ØµØ© Ø¨ÙŠØ¶Ø§Ø¡ ÙˆØ¯Ø¬Ø§Ø¬', base_price_cents: 85000, prep_station: 'hot', display_order: 3 },
    { id: genId(), tenant_id: tenantId, category_id: catPlats, name_fr: 'Chakhchoukha', name_ar: 'Ø´Ø®Ø´ÙˆØ®Ø©', description_fr: 'Plat traditionnel des hauts plateaux', description_ar: 'Ø·Ø¨Ù‚ ØªÙ‚Ù„ÙŠØ¯ÙŠ Ù…Ù† Ø§Ù„Ù‡Ø¶Ø§Ø¨ Ø§Ù„Ø¹Ù„ÙŠØ§', base_price_cents: 90000, prep_station: 'hot', display_order: 4 },
    // Grillades
    { id: genId(), tenant_id: tenantId, category_id: catGrillades, name_fr: 'Brochettes d\'Agneau', name_ar: 'ÙƒØ¨Ø§Ø¨ Ù„Ø­Ù… Ø§Ù„ØºÙ†Ù…', description_fr: 'Brochettes d\'agneau marinÃ©es aux Ã©pices', description_ar: 'ÙƒØ¨Ø§Ø¨ Ù„Ø­Ù… Ø§Ù„ØºÙ†Ù… Ù…ØªØ¨Ù„ Ø¨Ø§Ù„ØªÙˆØ§Ø¨Ù„', base_price_cents: 110000, prep_station: 'grill', display_order: 1 },
    { id: genId(), tenant_id: tenantId, category_id: catGrillades, name_fr: 'CÃ´telettes GrillÃ©es', name_ar: 'ÙƒÙˆØªÙ„ÙŠØª Ù…Ø´ÙˆÙŠ', description_fr: 'CÃ´telettes d\'agneau grillÃ©es', description_ar: 'ÙƒÙˆØªÙ„ÙŠØª Ù„Ø­Ù… ØºÙ†Ù… Ù…Ø´ÙˆÙŠ', base_price_cents: 130000, prep_station: 'grill', display_order: 2 },
    { id: genId(), tenant_id: tenantId, category_id: catGrillades, name_fr: 'Poulet GrillÃ©', name_ar: 'Ø¯Ø¬Ø§Ø¬ Ù…Ø´ÙˆÙŠ', description_fr: 'Demi poulet marinÃ© et grillÃ©', description_ar: 'Ù†ØµÙ Ø¯Ø¬Ø§Ø¬Ø© Ù…ØªØ¨Ù„Ø© ÙˆÙ…Ø´ÙˆÙŠØ©', base_price_cents: 85000, prep_station: 'grill', display_order: 3 },
    { id: genId(), tenant_id: tenantId, category_id: catGrillades, name_fr: 'Merguez', name_ar: 'Ù…Ø±Ù‚Ø§Ø²', description_fr: 'Saucisses merguez grillÃ©es', description_ar: 'Ù…Ø±Ù‚Ø§Ø² Ù…Ø´ÙˆÙŠ', base_price_cents: 65000, prep_station: 'grill', display_order: 4 },
    // Desserts
    { id: genId(), tenant_id: tenantId, category_id: catDesserts, name_fr: 'Baklawa', name_ar: 'Ø¨Ù‚Ù„Ø§ÙˆØ©', description_fr: 'PÃ¢tisserie traditionnelle aux amandes et miel', description_ar: 'Ø­Ù„ÙˆÙŠØ§Øª ØªÙ‚Ù„ÙŠØ¯ÙŠØ© Ø¨Ø§Ù„Ù„ÙˆØ² ÙˆØ§Ù„Ø¹Ø³Ù„', base_price_cents: 35000, prep_station: 'cold', display_order: 1 },
    { id: genId(), tenant_id: tenantId, category_id: catDesserts, name_fr: 'Makroud', name_ar: 'Ù…Ù‚Ø±ÙˆØ·', description_fr: 'GÃ¢teau de semoule aux dattes', description_ar: 'Ø­Ù„ÙˆÙ‰ Ø§Ù„Ø³Ù…ÙŠØ¯ Ø¨Ø§Ù„ØªÙ…Ø±', base_price_cents: 30000, prep_station: 'cold', display_order: 2 },
    { id: genId(), tenant_id: tenantId, category_id: catDesserts, name_fr: 'CrÃ¨me Caramel', name_ar: 'ÙƒØ±ÙŠÙ… ÙƒØ±Ø§Ù…ÙŠÙ„', description_fr: 'CrÃ¨me caramel maison', description_ar: 'ÙƒØ±ÙŠÙ… ÙƒØ±Ø§Ù…ÙŠÙ„ Ù…Ù†Ø²Ù„ÙŠ', base_price_cents: 25000, prep_station: 'cold', display_order: 3 },
    // Boissons
    { id: genId(), tenant_id: tenantId, category_id: catBoissons, name_fr: 'Eau MinÃ©rale', name_ar: 'Ù…ÙŠØ§Ù‡ Ù…Ø¹Ø¯Ù†ÙŠØ©', base_price_cents: 10000, prep_station: 'bar', display_order: 1 },
    { id: genId(), tenant_id: tenantId, category_id: catBoissons, name_fr: 'Jus d\'Orange Frais', name_ar: 'Ø¹ØµÙŠØ± Ø¨Ø±ØªÙ‚Ø§Ù„ Ø·Ø§Ø²Ø¬', base_price_cents: 25000, prep_station: 'bar', display_order: 2 },
    { id: genId(), tenant_id: tenantId, category_id: catBoissons, name_fr: 'Limonade', name_ar: 'Ù„ÙŠÙ…ÙˆÙ†Ø§Ø¶Ø©', base_price_cents: 20000, prep_station: 'bar', display_order: 3 },
    { id: genId(), tenant_id: tenantId, category_id: catBoissons, name_fr: 'Citronnade', name_ar: 'Ø¹ØµÙŠØ± Ø§Ù„Ù„ÙŠÙ…ÙˆÙ†', base_price_cents: 20000, prep_station: 'bar', display_order: 4 },
    // Boissons Chaudes
    { id: genId(), tenant_id: tenantId, category_id: catBoissonsChaudes, name_fr: 'CafÃ© Express', name_ar: 'Ù‚Ù‡ÙˆØ© Ø§Ø³Ø¨Ø±ÙŠØ³Ùˆ', base_price_cents: 15000, prep_station: 'bar', display_order: 1 },
    { id: genId(), tenant_id: tenantId, category_id: catBoissonsChaudes, name_fr: 'ThÃ© Ã  la Menthe', name_ar: 'Ø´Ø§ÙŠ Ø¨Ø§Ù„Ù†Ø¹Ù†Ø§Ø¹', base_price_cents: 15000, prep_station: 'bar', display_order: 2 },
    { id: genId(), tenant_id: tenantId, category_id: catBoissonsChaudes, name_fr: 'CafÃ© au Lait', name_ar: 'Ù‚Ù‡ÙˆØ© Ø¨Ø§Ù„Ø­Ù„ÙŠØ¨', base_price_cents: 20000, prep_station: 'bar', display_order: 3 },
  ];
  await knex('menu_items').insert(items);

  // â”€â”€ Modifier Groups â”€â”€
  const modCuisson = genId();
  const modBoisson = genId();
  const modAccomp = genId();
  await knex('modifier_groups').insert([
    { id: modCuisson, tenant_id: tenantId, name_fr: 'Cuisson', name_ar: 'Ø¯Ø±Ø¬Ø© Ø§Ù„Ø·Ù‡ÙŠ', selection_type: 'single_optional', min_selections: 0, max_selections: 1 },
    { id: modBoisson, tenant_id: tenantId, name_fr: 'Taille', name_ar: 'Ø§Ù„Ø­Ø¬Ù…', selection_type: 'single_required', min_selections: 1, max_selections: 1 },
    { id: modAccomp, tenant_id: tenantId, name_fr: 'Accompagnements', name_ar: 'Ù…Ø±Ø§ÙÙ‚Ø§Øª', selection_type: 'multi', min_selections: 0, max_selections: 3 },
  ]);
  await knex('modifiers').insert([
    { id: genId(), tenant_id: tenantId, group_id: modCuisson, name_fr: 'Saignant', name_ar: 'Ù†ÙŠØ¡', price_delta_cents: 0, display_order: 1 },
    { id: genId(), tenant_id: tenantId, group_id: modCuisson, name_fr: 'Ã€ Point', name_ar: 'Ù…ØªÙˆØ³Ø·', price_delta_cents: 0, display_order: 2 },
    { id: genId(), tenant_id: tenantId, group_id: modCuisson, name_fr: 'Bien Cuit', name_ar: 'Ù†Ø§Ø¶Ø¬', price_delta_cents: 0, display_order: 3 },
    { id: genId(), tenant_id: tenantId, group_id: modBoisson, name_fr: 'Normal', name_ar: 'Ø¹Ø§Ø¯ÙŠ', price_delta_cents: 0, display_order: 1 },
    { id: genId(), tenant_id: tenantId, group_id: modBoisson, name_fr: 'Grand', name_ar: 'ÙƒØ¨ÙŠØ±', price_delta_cents: 10000, display_order: 2 },
    { id: genId(), tenant_id: tenantId, group_id: modAccomp, name_fr: 'Frites', name_ar: 'Ø¨Ø·Ø§Ø·Ø§ Ù…Ù‚Ù„ÙŠØ©', price_delta_cents: 15000, display_order: 1 },
    { id: genId(), tenant_id: tenantId, group_id: modAccomp, name_fr: 'Riz', name_ar: 'Ø£Ø±Ø²', price_delta_cents: 10000, display_order: 2 },
    { id: genId(), tenant_id: tenantId, group_id: modAccomp, name_fr: 'Salade', name_ar: 'Ø³Ù„Ø·Ø©', price_delta_cents: 10000, display_order: 3 },
  ]);

  // â”€â”€ Ingredients (Inventory) â”€â”€
  const ingredients = [
    { name_fr: 'Poulet entier', name_ar: 'Ø¯Ø¬Ø§Ø¬ ÙƒØ§Ù…Ù„', unit: 'kg', current_stock: 50, par_level: 20, reorder_quantity: 30, cost_per_unit_cents: 35000 },
    { name_fr: 'Agneau', name_ar: 'Ù„Ø­Ù… ØºÙ†Ù…', unit: 'kg', current_stock: 30, par_level: 15, reorder_quantity: 20, cost_per_unit_cents: 180000 },
    { name_fr: 'Semoule', name_ar: 'Ø³Ù…ÙŠØ¯', unit: 'kg', current_stock: 100, par_level: 30, reorder_quantity: 50, cost_per_unit_cents: 12000 },
    { name_fr: 'Tomates', name_ar: 'Ø·Ù…Ø§Ø·Ù…', unit: 'kg', current_stock: 40, par_level: 15, reorder_quantity: 25, cost_per_unit_cents: 8000 },
    { name_fr: 'Oignons', name_ar: 'Ø¨ØµÙ„', unit: 'kg', current_stock: 60, par_level: 20, reorder_quantity: 30, cost_per_unit_cents: 5000 },
    { name_fr: 'Poivrons', name_ar: 'ÙÙ„ÙÙ„', unit: 'kg', current_stock: 20, par_level: 10, reorder_quantity: 15, cost_per_unit_cents: 12000 },
    { name_fr: 'Olives', name_ar: 'Ø²ÙŠØªÙˆÙ†', unit: 'kg', current_stock: 15, par_level: 5, reorder_quantity: 10, cost_per_unit_cents: 25000 },
    { name_fr: 'Citrons confits', name_ar: 'Ù„ÙŠÙ…ÙˆÙ† Ù…Ø­ÙÙˆØ¸', unit: 'kg', current_stock: 10, par_level: 3, reorder_quantity: 5, cost_per_unit_cents: 30000 },
    { name_fr: 'Huile d\'olive', name_ar: 'Ø²ÙŠØª Ø²ÙŠØªÙˆÙ†', unit: 'litre', current_stock: 25, par_level: 10, reorder_quantity: 15, cost_per_unit_cents: 80000 },
    { name_fr: 'CafÃ© en grains', name_ar: 'Ø­Ø¨ÙˆØ¨ Ø§Ù„Ù‚Ù‡ÙˆØ©', unit: 'kg', current_stock: 8, par_level: 3, reorder_quantity: 5, cost_per_unit_cents: 250000 },
    { name_fr: 'Menthe fraÃ®che', name_ar: 'Ù†Ø¹Ù†Ø§Ø¹ Ø·Ø§Ø²Ø¬', unit: 'botte', current_stock: 20, par_level: 10, reorder_quantity: 15, cost_per_unit_cents: 5000 },
    { name_fr: 'Miel', name_ar: 'Ø¹Ø³Ù„', unit: 'kg', current_stock: 5, par_level: 2, reorder_quantity: 3, cost_per_unit_cents: 150000 },
    { name_fr: 'Amandes', name_ar: 'Ù„ÙˆØ²', unit: 'kg', current_stock: 8, par_level: 3, reorder_quantity: 5, cost_per_unit_cents: 250000 },
    { name_fr: 'Dattes', name_ar: 'ØªÙ…Ø±', unit: 'kg', current_stock: 10, par_level: 5, reorder_quantity: 8, cost_per_unit_cents: 100000 },
    { name_fr: 'Merguez', name_ar: 'Ù…Ø±Ù‚Ø§Ø²', unit: 'kg', current_stock: 15, par_level: 8, reorder_quantity: 10, cost_per_unit_cents: 90000 },
  ];
  for (const ing of ingredients) {
    await knex('ingredients').insert({ id: genId(), tenant_id: tenantId, ...ing });
  }

  // â”€â”€ Suppliers â”€â”€
  await knex('suppliers').insert([
    { id: genId(), tenant_id: tenantId, name: 'Viandes du Sahel', contact_name: 'Moussa Kaci', phone: '+213555111222', email: 'moussa@viandessahel.dz' },
    { id: genId(), tenant_id: tenantId, name: 'Fruits & LÃ©gumes Mitidja', contact_name: 'Fatima Hamdi', phone: '+213555333444', email: 'fatima@mitidja.dz' },
    { id: genId(), tenant_id: tenantId, name: 'Ã‰picerie en Gros Blida', contact_name: 'Ali Benali', phone: '+213555555666', email: 'ali@epicerieblida.dz' },
  ]);

  // â”€â”€ Loyalty Tiers â”€â”€
  await knex('loyalty_tiers').insert([
    { id: genId(), tenant_id: tenantId, name_fr: 'Bronze', name_ar: 'Ø¨Ø±ÙˆÙ†Ø²ÙŠ', min_points: 0, discount_pct: 0 },
    { id: genId(), tenant_id: tenantId, name_fr: 'Argent', name_ar: 'ÙØ¶ÙŠ', min_points: 500, discount_pct: 5 },
    { id: genId(), tenant_id: tenantId, name_fr: 'Or', name_ar: 'Ø°Ù‡Ø¨ÙŠ', min_points: 2000, discount_pct: 10 },
    { id: genId(), tenant_id: tenantId, name_fr: 'Platine', name_ar: 'Ø¨Ù„Ø§ØªÙŠÙ†ÙŠ', min_points: 5000, discount_pct: 15 },
  ]);

  // â”€â”€ Discount Rules â”€â”€
  await knex('discount_rules').insert([
    { id: genId(), tenant_id: tenantId, name_fr: 'Remise 10%', name_ar: 'Ø®ØµÙ… 10%', discount_type: 'percentage', value: 10, conditions_json: JSON.stringify({ min_order_cents: 200000 }), is_active: true },
    { id: genId(), tenant_id: tenantId, name_fr: 'Remise Manager', name_ar: 'Ø®ØµÙ… Ø§Ù„Ù…Ø¯ÙŠØ±', discount_type: 'percentage', value: 20, requires_manager_approval: true, is_active: true },
    { id: genId(), tenant_id: tenantId, name_fr: 'Happy Hour -15%', name_ar: 'Ø³Ø§Ø¹Ø© Ø³Ø¹ÙŠØ¯Ø© -15%', discount_type: 'percentage', value: 15, conditions_json: JSON.stringify({ hours: [14, 15, 16] }), is_active: true },
  ]);

  console.log('âœ… Seed completed successfully!');
  console.log('');
  console.log('Demo Accounts:');
  console.log('â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€');
  console.log('Super Admin: super@rms.local / Admin@2024');
  console.log('Owner:       ahmed@eldjazair.dz / Admin@2024');
  console.log('Manager:     karim@eldjazair.dz / Manager@2024');
  console.log('Cashier:     samira@eldjazair.dz / Manager@2024 | PIN: 1234');
  console.log('Waiter:      yassine@eldjazair.dz / Manager@2024 | PIN: 5678');
  console.log('Chef:        omar@eldjazair.dz / Manager@2024 | PIN: 9999');
  console.log('â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€');
}
