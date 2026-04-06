import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:gap/gap.dart';
import '../../../config/theme/app_colors.dart';
import '../../../logic/providers/time_provider.dart';

class HomeGreetingHeader extends ConsumerWidget {
  const HomeGreetingHeader({super.key});

  String _greeting(int hour) {
    if (hour < 12) return 'Buenos dias';
    if (hour < 18) return 'Buenas tardes';
    return 'Buenas noches';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(nowProvider);
    final appColors = AppColors.of(context);
    final dateStr =
        DateFormat("EEEE, d 'de' MMMM", 'es').format(now);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _greeting(now.hour),
            style: TextStyle(
              color: appColors.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Gap(2),
          Text(
            dateStr[0].toUpperCase() + dateStr.substring(1),
            style: TextStyle(
              color: appColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
