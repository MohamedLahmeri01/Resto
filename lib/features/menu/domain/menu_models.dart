class MenuCategory {
  final String id;
  final String nameFr;
  final String? nameAr;
  final int displayOrder;
  final bool isActive;
  final String? parentId;
  final List<MenuItem> items;

  MenuCategory({
    required this.id,
    required this.nameFr,
    this.nameAr,
    this.displayOrder = 0,
    this.isActive = true,
    this.parentId,
    this.items = const [],
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) => MenuCategory(
    id: json['id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    nameAr: json['name_ar'],
    displayOrder: json['display_order'] ?? 0,
    isActive: json['is_active'] == true || json['is_active'] == 1,
    parentId: json['parent_id'],
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => MenuItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class MenuItem {
  final String id;
  final String categoryId;
  final String nameFr;
  final String? nameAr;
  final String? descriptionFr;
  final String? descriptionAr;
  final int basePriceCents;
  final String? imageUrl;
  final String? prepStation;
  final bool is86d;
  final int displayOrder;
  final List<ModifierGroup> modifierGroups;

  MenuItem({
    required this.id,
    required this.categoryId,
    required this.nameFr,
    this.nameAr,
    this.descriptionFr,
    this.descriptionAr,
    required this.basePriceCents,
    this.imageUrl,
    this.prepStation,
    this.is86d = false,
    this.displayOrder = 0,
    this.modifierGroups = const [],
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) => MenuItem(
    id: json['id'] ?? '',
    categoryId: json['category_id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    nameAr: json['name_ar'],
    descriptionFr: json['description_fr'],
    descriptionAr: json['description_ar'],
    basePriceCents: json['base_price_cents'] ?? 0,
    imageUrl: json['image_url'],
    prepStation: json['prep_station'],
    is86d: json['is_86d'] == true || json['is_86d'] == 1,
    displayOrder: json['display_order'] ?? 0,
    modifierGroups: (json['modifier_groups'] as List<dynamic>?)
        ?.map((e) => ModifierGroup.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class ModifierGroup {
  final String id;
  final String nameFr;
  final String? nameAr;
  final String selectionType;
  final int minSelections;
  final int maxSelections;
  final List<Modifier> modifiers;

  ModifierGroup({
    required this.id,
    required this.nameFr,
    this.nameAr,
    this.selectionType = 'single_optional',
    this.minSelections = 0,
    this.maxSelections = 1,
    this.modifiers = const [],
  });

  factory ModifierGroup.fromJson(Map<String, dynamic> json) => ModifierGroup(
    id: json['id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    nameAr: json['name_ar'],
    selectionType: json['selection_type'] ?? 'single_optional',
    minSelections: json['min_selections'] ?? 0,
    maxSelections: json['max_selections'] ?? 1,
    modifiers: (json['modifiers'] as List<dynamic>?)
        ?.map((e) => Modifier.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
  );
}

class Modifier {
  final String id;
  final String nameFr;
  final String? nameAr;
  final int priceDeltaCents;

  Modifier({
    required this.id,
    required this.nameFr,
    this.nameAr,
    this.priceDeltaCents = 0,
  });

  factory Modifier.fromJson(Map<String, dynamic> json) => Modifier(
    id: json['id'] ?? '',
    nameFr: json['name_fr'] ?? '',
    nameAr: json['name_ar'],
    priceDeltaCents: json['price_delta_cents'] ?? 0,
  );
}
