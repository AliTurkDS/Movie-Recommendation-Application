import 'package:flutter/material.dart';

import '../../../core/constants.dart';

/// One selectable row in a filter picker.
class FilterPickerItem {
  const FilterPickerItem({required this.label, required this.onSelect});
  final String label;
  final VoidCallback onSelect;
}

/// Opens a modal bottom sheet to pick one value for a filter dimension.
///
/// When [searchable] is true a search field is shown at the top (used for the
/// long Year and Country lists). An "Any …" row clears the dimension when
/// [onClear] is provided. [selectedLabel] highlights the current choice.
Future<void> showFilterPicker({
  required BuildContext context,
  required String title,
  required List<FilterPickerItem> items,
  String? selectedLabel,
  bool searchable = false,
  VoidCallback? onClear,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _FilterPickerSheet(
      title: title,
      items: items,
      selectedLabel: selectedLabel,
      searchable: searchable,
      onClear: onClear,
    ),
  );
}

class _FilterPickerSheet extends StatefulWidget {
  const _FilterPickerSheet({
    required this.title,
    required this.items,
    required this.selectedLabel,
    required this.searchable,
    required this.onClear,
  });

  final String title;
  final List<FilterPickerItem> items;
  final String? selectedLabel;
  final bool searchable;
  final VoidCallback? onClear;

  @override
  State<_FilterPickerSheet> createState() => _FilterPickerSheetState();
}

class _FilterPickerSheetState extends State<_FilterPickerSheet> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final query = _search.trim().toLowerCase();
    final filtered = query.isEmpty
        ? widget.items
        : widget.items
            .where((i) => i.label.toLowerCase().contains(query))
            .toList();

    final height = MediaQuery.of(context).size.height * 0.7;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: height,
        padding: const EdgeInsets.only(top: 12),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          children: [
            // Drag handle.
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(widget.title, style: AppText.sectionTitle),
              ),
            ),
            const SizedBox(height: 12),
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.title.toLowerCase()}…',
                    hintStyle:
                        const TextStyle(color: AppColors.textSecondary),
                    prefixIcon: const Icon(Icons.search,
                        color: AppColors.textSecondary),
                    filled: true,
                    fillColor: AppColors.cardBg,
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  if (widget.onClear != null && query.isEmpty)
                    _row(
                      context,
                      label: 'Any ${widget.title.toLowerCase()}',
                      selected: widget.selectedLabel == null,
                      onTap: () {
                        Navigator.pop(context);
                        widget.onClear!();
                      },
                    ),
                  for (final item in filtered)
                    _row(
                      context,
                      label: item.label,
                      selected: item.label == widget.selectedLabel,
                      onTap: () {
                        Navigator.pop(context);
                        item.onSelect();
                      },
                    ),
                  if (filtered.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text('No matches',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context, {
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      title: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.accent : AppColors.textPrimary,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check, color: AppColors.accent, size: 20)
          : null,
    );
  }
}
