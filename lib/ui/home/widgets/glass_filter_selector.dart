import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../home_providers.dart';
import 'glass_filter_pill.dart';

class GlassFilterSelector extends ConsumerWidget {
  const GlassFilterSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(summaryFilterProvider);

    Widget buildPill(String label, SummaryFilter value) {
      return GlassFilterPill(
        label: label,
        isSelected: selected == value,
        onTap: () => ref.read(summaryFilterProvider.notifier).state = value,
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            buildPill('Pago Actual', SummaryFilter.currentPeriod),
            const Gap(8),
            buildPill('Siguiente Pago', SummaryFilter.nextPeriod),
            const Gap(8),
            buildPill('Mes', SummaryFilter.currentMonth),
            const Gap(8),
            buildPill('Proximo Mes', SummaryFilter.nextMonth),
          ],
        ),
      ),
    );
  }
}
