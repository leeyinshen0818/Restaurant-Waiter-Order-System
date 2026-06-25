import 'package:flutter/material.dart';

class TableSelectionGrid extends StatelessWidget {
  const TableSelectionGrid({
    required this.tables,
    required this.occupiedTables,
    required this.selectedTable,
    required this.onTableSelected,
    super.key,
  });

  final List<int> tables;
  final Set<int> occupiedTables;
  final int? selectedTable;
  final ValueChanged<int> onTableSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 76).floor().clamp(3, 5);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: tables.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.45,
          ),
          itemBuilder: (context, index) {
            final tableNo = tables[index];
            final isSelected = selectedTable == tableNo;
            final isOccupied = occupiedTables.contains(tableNo);
            return _TableButton(
              tableNo: tableNo,
              isSelected: isSelected,
              isOccupied: isOccupied,
              onPressed: isOccupied ? null : () => onTableSelected(tableNo),
            );
          },
        );
      },
    );
  }
}

class _TableButton extends StatelessWidget {
  const _TableButton({
    required this.tableNo,
    required this.isSelected,
    required this.isOccupied,
    required this.onPressed,
  });

  final int tableNo;
  final bool isSelected;
  final bool isOccupied;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final label = tableNo.toString().padLeft(2, '0');
    final backgroundColor = isSelected
        ? colorScheme.primary
        : isOccupied
        ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.6)
        : colorScheme.surface;
    final foregroundColor = isSelected
        ? colorScheme.onPrimary
        : isOccupied
        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.65)
        : colorScheme.onSurface;

    return Semantics(
      label: isOccupied ? 'Table $label occupied' : 'Table $label',
      button: true,
      enabled: !isOccupied,
      selected: isSelected,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outline,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            if (isOccupied) ...[
              const SizedBox(height: 2),
              const Text('Busy', style: TextStyle(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }
}
