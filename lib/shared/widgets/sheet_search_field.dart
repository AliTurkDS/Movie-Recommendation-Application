import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// Shown in a list sheet when the search query matches nothing.
class SheetNoMatches extends StatelessWidget {
  const SheetNoMatches({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Text(
        'No matches found.',
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSecondary, height: 1.5),
      ),
    );
  }
}

/// A compact search field used to filter the saved-list sheets (Watched /
/// Watchlist / Unwatched) by title.
class SheetSearchField extends StatefulWidget {
  const SheetSearchField({
    super.key,
    required this.hint,
    required this.onChanged,
  });

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  State<SheetSearchField> createState() => _SheetSearchFieldState();
}

class _SheetSearchFieldState extends State<SheetSearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleChange(String value) {
    widget.onChanged(value);
    setState(() {}); // refresh the clear button
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: TextField(
        controller: _controller,
        onChanged: _handleChange,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon:
              const Icon(Icons.search, color: AppColors.textSecondary),
          suffixIcon: _controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close,
                      color: AppColors.textSecondary, size: 20),
                  onPressed: () {
                    _controller.clear();
                    _handleChange('');
                  },
                ),
          filled: true,
          fillColor: AppColors.cardBg,
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
