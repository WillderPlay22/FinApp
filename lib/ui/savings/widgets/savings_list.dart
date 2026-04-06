import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:finapp/data/models/saving.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import '../../../config/theme/app_colors.dart';
import '../../shared/icon_mapper.dart';
import '../../shared/currency_amount_display.dart';
import '../modals/saving_detail_modal.dart';
import '../../home/widgets/glass_card.dart';

class SavingsList extends ConsumerWidget {
  const SavingsList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(savingsDaoProvider);

    return StreamBuilder<List<Saving>>(
      stream: dao.watchAllSavings(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('Error al cargar ahorros'));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          final appColors = AppColors.of(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.seedling,
                    size: 48, color: appColors.textSecondary),
                const Gap(12),
                Text(
                  'No tienes planes de ahorro activos.',
                  style: TextStyle(color: appColors.textSecondary),
                ),
                const Gap(4),
                Text(
                  'Toca + para crear uno.',
                  style: TextStyle(
                      color: appColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          );
        }

        final savings = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
          itemCount: savings.length,
          itemBuilder: (context, index) =>
              _SavingCard(saving: savings[index]),
        );
      },
    );
  }
}

class _SavingCard extends StatelessWidget {
  final Saving saving;

  const _SavingCard({required this.saving});

  @override
  Widget build(BuildContext context) {
    final appColors = AppColors.of(context);
    final color = Color(saving.colorValue);
    final isGoal = saving.type == SavingType.goal;
    final progress =
        (isGoal && saving.targetAmount != null && saving.targetAmount! > 0)
            ? (saving.currentAmount / saving.targetAmount!).clamp(0.0, 1.0)
            : null;
    final isCompleted = isGoal &&
        saving.targetAmount != null &&
        saving.currentAmount >= saving.targetAmount!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            builder: (_) => SavingDetailModal(saving: saving),
          );
        },
        child: GlassCard(
          accentColor: color,
          borderRadius: 16,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // — Icono —
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: FaIcon(
                    getIconFromCode(saving.iconCode),
                    size: 20,
                    color: color,
                  ),
                ),
              ),
              const Gap(14),

              // — Nombre + progreso —
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            saving.name,
                            style: TextStyle(
                              color: appColors.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isCompleted)
                          Container(
                            margin: const EdgeInsets.only(left: 6),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '¡Meta!',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                    const Gap(6),
                    if (progress != null) ...[
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: value,
                            minHeight: 4,
                            backgroundColor: color.withAlpha(20),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const Gap(4),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}% de \$${saving.targetAmount!.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 11, color: appColors.textSecondary),
                      ),
                    ] else
                      Text(
                        'Fondo Indefinido',
                        style: TextStyle(
                            fontSize: 12, color: appColors.textSecondary),
                      ),
                  ],
                ),
              ),
              const Gap(12),

              // — Monto —
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  CurrencyAmountDisplay(
                    amount: saving.currentAmount,
                    currencyCode: saving.currencyCode,
                    textAlign: TextAlign.end,
                    primaryStyle: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
                    secondaryStyle: TextStyle(
                        fontSize: 11, color: appColors.textSecondary),
                  ),
                  const Gap(4),
                  Icon(Icons.chevron_right_rounded,
                      size: 18, color: appColors.textSecondary),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
