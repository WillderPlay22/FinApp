import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';

class MonthYearPicker extends StatefulWidget {
  final DateTime initialDate;
  final DateTime firstDate;
  final DateTime lastDate;

  const MonthYearPicker({
    super.key,
    required this.initialDate,
    required this.firstDate,
    required this.lastDate,
  });

  @override
  State<MonthYearPicker> createState() => _MonthYearPickerState();
}

class _MonthYearPickerState extends State<MonthYearPicker> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Seleccionar Mes",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface)),
                // Year Selector
                DropdownButton<int>(
                  value: _selectedYear,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.arrow_drop_down),
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colors.primary),
                  items: List.generate(
                    widget.lastDate.year - widget.firstDate.year + 1,
                    (index) => widget.firstDate.year + index,
                  )
                      .map((year) => DropdownMenuItem(
                          value: year, child: Text(year.toString())))
                      .toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedYear = val);
                  },
                ),
              ],
            ),
            const Gap(20),
            // Months Grid
            SizedBox(
              height: 250,
              width: 300,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                ),
                itemCount: 12,
                itemBuilder: (context, index) {
                  final monthIndex = index + 1;
                  final isCurrentSelection = _selectedMonth == monthIndex;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedMonth = monthIndex),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrentSelection
                            ? colors.primary
                            : colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrentSelection
                              ? colors.primary
                              : colors.outlineVariant.withAlpha(50),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        DateFormat('MMM', 'es')
                            .format(DateTime(2024, monthIndex)),
                        style: TextStyle(
                          color: isCurrentSelection
                              ? colors.onPrimary
                              : colors.onSurface,
                          fontWeight: isCurrentSelection
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(20),
            // Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancelar"),
                ),
                const Gap(8),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(
                        context, DateTime(_selectedYear, _selectedMonth, 1));
                  },
                  child: const Text("Aceptar"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
