import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../config/theme/app_colors.dart';
import '../../income/modals/add_income_modal.dart';
import '../../expenses/modals/add_expense_modal.dart';
import '../../expenses/modals/add_debt_modal.dart';
import '../../savings/modals/add_saving_modal.dart';
import 'glass_card.dart';
import 'glass_icon_button.dart';

class QuickActionsRow extends ConsumerWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appColors = AppColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        borderRadius: 20,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acciones Rapidas',
              style: TextStyle(
                color: appColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GlassIconButton(
                  icon: FontAwesomeIcons.plus,
                  color: appColors.incomeColor,
                  label: 'Ingreso',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddIncomeModal(),
                  ),
                ),
                GlassIconButton(
                  icon: FontAwesomeIcons.minus,
                  color: appColors.expenseColor,
                  label: 'Gasto',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddExpenseModal(),
                  ),
                ),
                GlassIconButton(
                  icon: FontAwesomeIcons.fileInvoiceDollar,
                  color: appColors.debtColor,
                  label: 'Deuda',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddDebtModal(),
                  ),
                ),
                GlassIconButton(
                  icon: FontAwesomeIcons.piggyBank,
                  color: appColors.savingsColor,
                  label: 'Ahorro',
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const AddSavingModal(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
