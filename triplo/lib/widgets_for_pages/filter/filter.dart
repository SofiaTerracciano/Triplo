import 'package:flutter/material.dart';
import 'package:triplo/enum/SearchMode.dart';

class Filter extends StatelessWidget {
  final SearchMode mode;
  final SearchMode selectedMode;
  final String label;
  final ValueChanged<SearchMode> onSelected;

  const Filter({
    super.key,
    required this.mode,
    required this.selectedMode,
    required this.label,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: mode == selectedMode,
      onSelected: (_) => onSelected(mode),
    );
  }
}