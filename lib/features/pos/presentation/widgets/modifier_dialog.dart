import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../menu/domain/menu_models.dart';

class ModifierDialog extends StatefulWidget {
  final MenuItem item;
  final void Function(List<Modifier> modifiers, String? notes) onConfirm;

  const ModifierDialog({super.key, required this.item, required this.onConfirm});

  @override
  State<ModifierDialog> createState() => _ModifierDialogState();
}

class _ModifierDialogState extends State<ModifierDialog> {
  final Map<String, List<Modifier>> _selections = {};
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    for (final group in widget.item.modifierGroups) {
      _selections[group.id] = [];
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    for (final group in widget.item.modifierGroups) {
      final selected = _selections[group.id] ?? [];
      if (selected.length < group.minSelections) return false;
    }
    return true;
  }

  void _toggleModifier(ModifierGroup group, Modifier mod) {
    setState(() {
      final list = _selections[group.id]!;
      if (list.contains(mod)) {
        list.remove(mod);
      } else {
        if (group.selectionType.startsWith('single')) {
          list.clear();
        }
        if (list.length < group.maxSelections) {
          list.add(mod);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item.nameFr),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...widget.item.modifierGroups.map(_buildGroup),
              const SizedBox(height: 16),
              TextField(
                controller: _notesCtrl,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Instructions spéciales...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
        FilledButton(
          onPressed: _isValid
              ? () {
                  final allMods = _selections.values.expand((l) => l).toList();
                  final notes = _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim();
                  widget.onConfirm(allMods, notes);
                  Navigator.pop(context);
                }
              : null,
          child: const Text('Ajouter'),
        ),
      ],
    );
  }

  Widget _buildGroup(ModifierGroup group) {
    final selected = _selections[group.id] ?? [];
    final requiredLabel = group.minSelections > 0 ? ' (obligatoire)' : ' (optionnel)';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${group.nameFr}$requiredLabel',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.modifiers.map((mod) {
              final isSelected = selected.contains(mod);
              return FilterChip(
                label: Text(
                  mod.priceDeltaCents > 0
                      ? '${mod.nameFr} (+${FormatUtils.money(mod.priceDeltaCents)})'
                      : mod.nameFr,
                ),
                selected: isSelected,
                onSelected: (_) => _toggleModifier(group, mod),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
