import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/enums.dart';
import '../data/table_repository.dart';
import '../domain/table_model.dart';

class TableState {
  final List<FloorSection> sections;
  final List<RestaurantTable> allTables;
  final String? selectedSectionId;
  final bool isLoading;
  final String? error;

  const TableState({
    this.sections = const [],
    this.allTables = const [],
    this.selectedSectionId,
    this.isLoading = false,
    this.error,
  });

  TableState copyWith({
    List<FloorSection>? sections,
    List<RestaurantTable>? allTables,
    String? selectedSectionId,
    bool? isLoading,
    String? error,
  }) => TableState(
    sections: sections ?? this.sections,
    allTables: allTables ?? this.allTables,
    selectedSectionId: selectedSectionId ?? this.selectedSectionId,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  List<RestaurantTable> get filteredTables {
    if (selectedSectionId == null) return allTables;
    return allTables.where((t) => t.sectionId == selectedSectionId).toList();
  }

  int get availableCount => allTables.where((t) => t.status == TableStatus.available).length;
  int get occupiedCount => allTables.where((t) => t.status == TableStatus.occupied).length;
  int get reservedCount => allTables.where((t) => t.status == TableStatus.reserved).length;
}

class TableNotifier extends StateNotifier<TableState> {
  final TableRepository _repo;
  TableNotifier(this._repo) : super(const TableState());

  Future<void> loadTables() async {
    state = state.copyWith(isLoading: true, error: null);
    final result = await _repo.getTablesWithSections();
    if (result.isSuccess && result.data != null) {
      final data = result.data!;
      final sectionsList = (data['sections'] as List<dynamic>?)
          ?.map((e) => FloorSection.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      final tablesList = (data['tables'] as List<dynamic>?)
          ?.map((e) => RestaurantTable.fromJson(e as Map<String, dynamic>))
          .toList() ?? [];
      state = state.copyWith(
        sections: sectionsList,
        allTables: tablesList,
        isLoading: false,
      );
    } else {
      state = state.copyWith(isLoading: false, error: result.error?.message);
    }
  }

  void selectSection(String? sectionId) {
    state = state.copyWith(selectedSectionId: sectionId);
  }

  Future<void> updateTableStatus(String tableId, String status) async {
    await _repo.updateStatus(tableId, status);
    await loadTables();
  }
}

final tableProvider = StateNotifierProvider<TableNotifier, TableState>((ref) {
  final repo = ref.watch(tableRepositoryProvider);
  return TableNotifier(repo);
});
