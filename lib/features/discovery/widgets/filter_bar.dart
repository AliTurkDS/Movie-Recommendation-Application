import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../../../core/filter_options.dart';
import '../providers/filter_provider.dart';
import 'filter_picker_sheet.dart';

/// Horizontally scrollable filter row: an "All" reset chip followed by the
/// Category / Year / Country / Continent dropdown chips.
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(movieFilterProvider);
    final notifier = ref.read(movieFilterProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _Chip(
            label: 'All',
            active: filter.isEmpty,
            onTap: filter.isEmpty
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    notifier.clearAll();
                  },
          ),
          const SizedBox(width: 10),
          _Chip(
            label: 'Top Rated',
            active: filter.topRated,
            onTap: () {
              HapticFeedback.selectionClick();
              notifier.setTopRated(!filter.topRated);
            },
          ),
          const SizedBox(width: 10),
          _DropdownChip(
            label: filter.genreLabel ?? 'Category',
            active: filter.genreId != null,
            onTap: () => _pickCategory(context, ref, filter),
          ),
          const SizedBox(width: 10),
          _DropdownChip(
            label: filter.year?.toString() ?? 'Year',
            active: filter.year != null,
            onTap: () => _pickYear(context, ref, filter),
          ),
          const SizedBox(width: 10),
          _DropdownChip(
            label: filter.countryName ?? 'Country',
            active: filter.countryCode != null,
            onTap: () => _pickCountry(context, ref, filter),
          ),
          const SizedBox(width: 10),
          _DropdownChip(
            label: filter.continent ?? 'Continent',
            active: filter.continent != null,
            onTap: () => _pickContinent(context, ref, filter),
          ),
        ],
      ),
    );
  }

  void _pickCategory(BuildContext context, WidgetRef ref, MovieFilter filter) {
    final notifier = ref.read(movieFilterProvider.notifier);
    showFilterPicker(
      context: context,
      title: 'Category',
      selectedLabel: filter.genreLabel,
      items: [
        for (final g in kFilterGenres)
          FilterPickerItem(label: g.label, onSelect: () => notifier.setGenre(g)),
      ],
      onClear: () => notifier.setGenre(null),
    );
  }

  void _pickYear(BuildContext context, WidgetRef ref, MovieFilter filter) {
    final notifier = ref.read(movieFilterProvider.notifier);
    showFilterPicker(
      context: context,
      title: 'Year',
      searchable: true,
      selectedLabel: filter.year?.toString(),
      items: [
        for (final y in filterYears())
          FilterPickerItem(label: '$y', onSelect: () => notifier.setYear(y)),
      ],
      onClear: () => notifier.setYear(null),
    );
  }

  void _pickCountry(BuildContext context, WidgetRef ref, MovieFilter filter) {
    final notifier = ref.read(movieFilterProvider.notifier);
    // Scope to the chosen continent (if any), then sort by name.
    final pool = filter.continent == null
        ? kCountries
        : kCountries.where((c) => c.continent == filter.continent).toList();
    final sorted = [...pool]..sort((a, b) => a.name.compareTo(b.name));
    showFilterPicker(
      context: context,
      title:
          filter.continent == null ? 'Country' : 'Country in ${filter.continent}',
      searchable: true,
      selectedLabel: filter.countryName,
      items: [
        for (final c in sorted)
          FilterPickerItem(label: c.name, onSelect: () => notifier.setCountry(c)),
      ],
      onClear: () => notifier.setCountry(null),
    );
  }

  void _pickContinent(BuildContext context, WidgetRef ref, MovieFilter filter) {
    final notifier = ref.read(movieFilterProvider.notifier);
    showFilterPicker(
      context: context,
      title: 'Continent',
      selectedLabel: filter.continent,
      items: [
        for (final c in kContinents)
          FilterPickerItem(label: c, onSelect: () => notifier.setContinent(c)),
      ],
      onClear: () => notifier.setContinent(null),
    );
  }
}

/// A simple filter pill (used for the "All" reset chip).
class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.genreTagBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : AppColors.textSecondary,
            fontSize: 15,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// A filter pill with a trailing dropdown caret.
class _DropdownChip extends StatelessWidget {
  const _DropdownChip({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        alignment: Alignment.center,
        padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.genreTagBorder,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.textSecondary,
                fontSize: 15,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 20,
              color: active ? Colors.white : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
