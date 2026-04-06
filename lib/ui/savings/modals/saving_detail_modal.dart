import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:finapp/data/models/saving.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import 'package:finapp/logic/providers/decimal_separator_provider.dart';
import '../../shared/icon_mapper.dart';
import '../../shared/amount_input_formatter.dart';
import '../../../data/models/transaction.dart';
import '../../../config/theme/app_colors.dart';
import '../../home/widgets/glass_card.dart';

class SavingDetailModal extends ConsumerStatefulWidget {
  final Saving saving;

  const SavingDetailModal({super.key, required this.saving});

  @override
  ConsumerState<SavingDetailModal> createState() => _SavingDetailModalState();
}

class _SavingDetailModalState extends ConsumerState<SavingDetailModal> {
  bool _showConfetti = false;

  @override
  Widget build(BuildContext context) {
    final dao = ref.watch(savingsDaoProvider);
    final colors = Theme.of(context).colorScheme;
    final appColors = AppColors.of(context);

    return StreamBuilder<Saving?>(
      stream: dao.watchSaving(widget.saving.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 300,
              child: Center(child: CircularProgressIndicator()));
        }

        if (snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const SizedBox();
        }

        final saving = snapshot.data!;
        final color = Color(saving.colorValue);
        final isGoal = saving.type == SavingType.goal;
        final target = saving.targetAmount ?? 0.0;
        final progress =
            (isGoal && target > 0) ? (saving.currentAmount / target).clamp(0.0, 1.0) : 0.0;
        final isCompleted = isGoal && target > 0 && saving.currentAmount >= target;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            child: Scaffold(
              backgroundColor: colors.surface,
              body: Stack(
                children: [
                  ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                    children: [
                      // — Drag handle —
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: appColors.textSecondary.withAlpha(60),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const Gap(16),

                      // — Header —
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: color.withAlpha(25),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: FaIcon(getIconFromCode(saving.iconCode),
                                  size: 24, color: color),
                            ),
                          ),
                          const Gap(14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  saving.name,
                                  style: TextStyle(
                                    color: appColors.textPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Gap(4),
                                Text(
                                  isGoal
                                      ? 'Meta: \$${target.toStringAsFixed(2)}'
                                      : 'Fondo de Ahorro',
                                  style: TextStyle(
                                      color: appColors.textSecondary,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: () => _showEditDialog(context, saving),
                            icon: Icon(Icons.edit_outlined,
                                color: appColors.textSecondary, size: 20),
                            tooltip: 'Editar',
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const Gap(20),

                      // — Monto actual —
                      GlassCard(
                        accentColor: color,
                        borderRadius: 16,
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              '\$${saving.currentAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 38,
                                fontWeight: FontWeight.w900,
                                color: color,
                              ),
                            ),
                            Text(
                              'Ahorrado Actualmente',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: appColors.textSecondary),
                            ),
                            if (isGoal) ...[
                              const Gap(16),
                              TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0, end: progress),
                                duration: const Duration(milliseconds: 900),
                                curve: Curves.easeOutCubic,
                                builder: (_, value, __) => Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: value,
                                        minHeight: 10,
                                        backgroundColor:
                                            appColors.textSecondary.withAlpha(30),
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                          isCompleted
                                              ? const Color(0xFFFFD600)
                                              : color,
                                        ),
                                      ),
                                    ),
                                    const Gap(8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          '${(progress * 100).toStringAsFixed(1)}% completado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                            color: appColors.textPrimary,
                                          ),
                                        ),
                                        if (isCompleted)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFFD600)
                                                  .withAlpha(30),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: const Text(
                                              '¡Meta alcanzada! 🎉',
                                              style: TextStyle(
                                                color: Color(0xFFFFD600),
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Gap(16),

                      // — Acciones —
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showDepositDialog(context, saving),
                          icon: const Icon(FontAwesomeIcons.circleDollarToSlot,
                              size: 16),
                          label: const Text('REGISTRAR AHORRO'),
                          style: FilledButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      if (saving.currentAmount > 0) ...[
                        const Gap(10),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _showWithdrawDialog(context, saving),
                            icon: const Icon(
                                FontAwesomeIcons.moneyBillTransfer,
                                size: 14),
                            label: const Text('USAR AHORRO'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: color,
                              side: BorderSide(color: color.withAlpha(80)),
                              padding:
                                  const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14)),
                            ),
                          ),
                        ),
                      ],
                      const Gap(24),

                      // — Historial —
                      Text(
                        'Historial',
                        style: TextStyle(
                          color: appColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(10),
                      _buildHistoryList(dao, saving.id, appColors),
                    ],
                  ),

                  if (_showConfetti)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: _SimpleConfetti(
                          onFinished: () =>
                              setState(() => _showConfetti = false),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(dynamic dao, int savingId, AppColors appColors) {
    return StreamBuilder<List<FinancialTransaction>>(
      stream: dao.watchSavingTransactions(savingId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24.0),
            child: Center(
              child: Text(
                'Aún no hay movimientos.',
                style: TextStyle(color: appColors.textSecondary),
              ),
            ),
          );
        }

        final txs = snapshot.data!;
        return Column(
          children: txs.map((tx) {
            final isWithdrawal = tx.amount < 0;
            final color = isWithdrawal
                ? const Color(0xFFFF6B6B)
                : const Color(0xFF05D5AA);
            final sign = isWithdrawal ? '-' : '+';
            final absAmount = tx.amount.abs();

            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isWithdrawal
                          ? FontAwesomeIcons.arrowUp
                          : FontAwesomeIcons.arrowDown,
                      size: 14,
                      color: color,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isWithdrawal ? 'Retiro' : 'Depósito',
                          style: TextStyle(
                            color: appColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        Text(
                          DateFormat('dd MMM yyyy', 'es').format(tx.date),
                          style: TextStyle(
                              color: appColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$sign\$${absAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _showDepositDialog(BuildContext context, Saving saving) async {
    final dao = ref.read(savingsDaoProvider);
    final decimalSep = ref.read(decimalSeparatorProvider);
    double suggestedAmount = 0.0;

    if (saving.method == SavingMethod.fixed) {
      suggestedAmount = saving.fixedAmount ?? 0.0;
    } else {
      final netProjection = await dao.calculateMonthlyNetProjection();
      final base = netProjection > 0 ? netProjection : 0.0;
      suggestedAmount = base * ((saving.percentage ?? 0) / 100);
    }

    final controller = TextEditingController(
        text: suggestedAmount > 0 ? suggestedAmount.toStringAsFixed(2) : '');

    if (!mounted || !context.mounted) return;

    final color = Color(saving.colorValue);
    final appColors = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Registrar Ahorro',
          style: TextStyle(
              color: appColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              saving.name,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const Gap(16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                AmountInputFormatter(decimalSeparator: decimalSep)
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color),
              decoration: InputDecoration(
                prefixText: '\$ ',
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (saving.method == SavingMethod.percentage)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Calculado según proyección del mes actual.',
                  style: TextStyle(
                      fontSize: 11, color: appColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: appColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              final amount = parseAmount(controller.text, decimalSep);
              if (amount > 0) {
                final newAmount = saving.currentAmount + amount;
                final goalReached = saving.type == SavingType.goal &&
                    saving.targetAmount != null &&
                    newAmount >= saving.targetAmount!;

                await dao.depositToSaving(saving, amount);

                if (!ctx.mounted) return;
                Navigator.pop(ctx);

                if (goalReached && mounted) {
                  setState(() => _showConfetti = true);
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: color),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog(BuildContext context, Saving saving) {
    final dao = ref.read(savingsDaoProvider);
    final decimalSep = ref.read(decimalSeparatorProvider);
    final controller = TextEditingController();
    final color = Color(saving.colorValue);
    final appColors = AppColors.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Usar Ahorro',
          style: TextStyle(
              color: appColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Disponible: \$${saving.currentAmount.toStringAsFixed(2)}',
              style: TextStyle(color: appColors.textSecondary, fontSize: 13),
            ),
            const Gap(16),
            TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                AmountInputFormatter(decimalSeparator: decimalSep)
              ],
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: color),
              decoration: InputDecoration(
                hintText: 'Max ${saving.currentAmount.toStringAsFixed(2)}',
                prefixText: '\$ ',
                filled: true,
                fillColor: Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const Gap(8),
            Text(
              'Se registrará como retiro en tu historial.',
              style: TextStyle(
                  fontSize: 11, color: appColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: appColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              final amount = parseAmount(controller.text, decimalSep);
              if (amount > 0 && amount <= saving.currentAmount) {
                await dao.withdrawFromSaving(saving, amount);
                if (ctx.mounted) Navigator.pop(ctx);
              } else if (amount > saving.currentAmount) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'El monto supera el saldo disponible.')),
                );
              }
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Retirar'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Saving saving) {
    final nameCtrl = TextEditingController(text: saving.name);
    final targetCtrl = TextEditingController(
        text: saving.targetAmount?.toStringAsFixed(2) ?? '');
    int selectedIcon = saving.iconCode;
    int selectedColor = saving.colorValue;
    final appColors = AppColors.of(context);

    final List<IconData> availableIcons = [
      FontAwesomeIcons.piggyBank,
      FontAwesomeIcons.laptop,
      FontAwesomeIcons.mobile,
      FontAwesomeIcons.car,
      FontAwesomeIcons.house,
      FontAwesomeIcons.plane,
      FontAwesomeIcons.umbrellaBeach,
      FontAwesomeIcons.graduationCap,
      FontAwesomeIcons.gamepad,
      FontAwesomeIcons.coins,
      FontAwesomeIcons.sackDollar,
      FontAwesomeIcons.building,
    ];

    final List<Color> availableColors = [
      const Color(0xFFE91E63),
      Colors.teal,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.green,
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Padding(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: appColors.textSecondary.withAlpha(60),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Gap(16),
                  Text(
                    'Editar Ahorro',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: appColors.textPrimary),
                    textAlign: TextAlign.center,
                  ),
                  const Gap(20),
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon: const Icon(Icons.label_outline),
                      filled: true,
                      fillColor: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (saving.type == SavingType.goal) ...[
                    const Gap(12),
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Meta Objetivo',
                        prefixText: '\$ ',
                        prefixIcon: const Icon(Icons.flag_outlined),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ],
                  const Gap(20),
                  Text('Icono',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary)),
                  const Gap(10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableIcons.map((icon) {
                      final isSelected = selectedIcon == icon.codePoint;
                      final selColor = Color(selectedColor);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => selectedIcon = icon.codePoint),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? selColor.withAlpha(30)
                                : Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(color: selColor, width: 2)
                                : null,
                          ),
                          child: Center(
                            child: FaIcon(icon,
                                size: 18,
                                color: isSelected
                                    ? selColor
                                    : appColors.textSecondary),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(20),
                  Text('Color',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: appColors.textPrimary)),
                  const Gap(10),
                  Wrap(
                    spacing: 10,
                    children: availableColors.map((color) {
                      final isSelected =
                          selectedColor == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(
                            () => selectedColor = color.toARGB32()),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(
                                    color: Colors.white, width: 2.5)
                                : null,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check,
                                  color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(24),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteSaving(context, saving.id);
                        },
                        icon: const Icon(Icons.delete_outline,
                            color: Color(0xFFFF6B6B)),
                        label: const Text('Eliminar',
                            style:
                                TextStyle(color: Color(0xFFFF6B6B))),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: Text('Cancelar',
                            style: TextStyle(
                                color: appColors.textSecondary)),
                      ),
                      const Gap(8),
                      FilledButton(
                        onPressed: () async {
                          final newTarget =
                              double.tryParse(targetCtrl.text);
                          if (saving.type == SavingType.goal &&
                              newTarget != null) {
                            if (newTarget < saving.currentAmount) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(const SnackBar(
                                      content: Text(
                                          'La meta no puede ser menor a lo ya ahorrado.')));
                              return;
                            }
                            saving.targetAmount = newTarget;
                          }
                          saving.name = nameCtrl.text;
                          saving.iconCode = selectedIcon;
                          saving.colorValue = selectedColor;
                          await ref
                              .read(savingsDaoProvider)
                              .updateSaving(saving);
                          if (ctx.mounted) Navigator.pop(ctx);
                        },
                        child: const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deleteSaving(BuildContext context, int id) {
    final appColors = AppColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('¿Eliminar Ahorro?',
            style: TextStyle(
                color: appColors.textPrimary,
                fontWeight: FontWeight.bold)),
        content: Text(
          'Se eliminará el plan. El historial de movimientos permanecerá.',
          style: TextStyle(color: appColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar',
                style: TextStyle(color: appColors.textSecondary)),
          ),
          FilledButton(
            onPressed: () async {
              await ref.read(savingsDaoProvider).deleteSaving(id);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFFF6B6B)),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

// ── Confetti ──────────────────────────────────────────────────────────────────
class _SimpleConfetti extends StatefulWidget {
  final VoidCallback onFinished;
  const _SimpleConfetti({required this.onFinished});

  @override
  State<_SimpleConfetti> createState() => _SimpleConfettiState();
}

class _SimpleConfettiState extends State<_SimpleConfetti>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(seconds: 3));
    for (int i = 0; i < 50; i++) {
      _particles.add(_Particle(_rnd));
    }
    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => CustomPaint(
        painter: _ConfettiPainter(_particles, _controller.value),
        size: Size.infinite,
      ),
    );
  }
}

class _Particle {
  late double x, y, speed, theta, radius;
  late Color color;

  _Particle(Random rnd) {
    x = rnd.nextDouble();
    y = -rnd.nextDouble() * 0.5;
    speed = 0.01 + rnd.nextDouble() * 0.02;
    theta = rnd.nextDouble() * 2 * pi;
    radius = 3 + rnd.nextDouble() * 5;
    color = [
      Colors.red, Colors.blue, Colors.green,
      Colors.yellow, Colors.purple, Colors.orange,
    ][rnd.nextInt(6)];
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  _ConfettiPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    for (var p in particles) {
      p.y += p.speed;
      p.x += sin(p.theta + progress * 10) * 0.002;
      final dx = p.x * size.width;
      final dy = p.y * size.height;
      if (dy > -20 && dy < size.height + 20) {
        paint.color =
            p.color.withValues(alpha: (1.0 - progress).clamp(0.0, 1.0));
        canvas.drawCircle(Offset(dx, dy), p.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => true;
}
