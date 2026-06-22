import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants.dart';
import '../providers/search_provider.dart';

/// A rounded search field. Debounces input and pushes the query into
/// [searchQueryProvider], which the deck listens to.
class MovieSearchBar extends ConsumerStatefulWidget {
  const MovieSearchBar({super.key});

  @override
  ConsumerState<MovieSearchBar> createState() => _MovieSearchBarState();
}

class _MovieSearchBarState extends ConsumerState<MovieSearchBar> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 450), () {
      ref.read(searchQueryProvider.notifier).state = value.trim();
      setState(() {}); // refresh the clear button
    });
  }

  void _clear() {
    _debounce?.cancel();
    _controller.clear();
    ref.read(searchQueryProvider.notifier).state = '';
    _focus.unfocus();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final hasText = _controller.text.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Container(
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.genreTagBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focus,
                onChanged: _onChanged,
                textInputAction: TextInputAction.search,
                onSubmitted: (v) {
                  _debounce?.cancel();
                  ref.read(searchQueryProvider.notifier).state = v.trim();
                },
                cursorColor: AppColors.accent,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 15),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: 'Search movies…',
                  hintStyle: TextStyle(
                      color: AppColors.textSecondary, fontSize: 15),
                ),
              ),
            ),
            if (hasText)
              GestureDetector(
                onTap: _clear,
                child: const Icon(Icons.close,
                    color: AppColors.textSecondary, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
