import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:isar/isar.dart'; // Necesario para QueryBuilder y filtros
import 'package:finapp/data/models/saving.dart';
import 'package:finapp/data/models/enums.dart';
import 'package:finapp/logic/providers/database_providers.dart';
import 'package:finapp/data/local_db/isar_db.dart'; // Para acceso directo a DB
import '../../shared/icon_mapper.dart';
import '../../../data/models/transaction.dart';
import '../../expenses/modals/add_expense_modal.dart'; // Importamos el modal de gastos

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

    return StreamBuilder<Saving?>(
      stream: dao.watchSaving(widget.saving.id),
      builder: (context, snapshot) {
        // 1. Si está conectando, mostramos un indicador de carga en lugar de cerrar
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()));
        }

        // 2. Si ya conectó y el dato es nulo (significa que se borró), entonces cerramos
        if (snapshot.data == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) Navigator.of(context).pop();
          });
          return const SizedBox();
        }
        final saving = snapshot.data!;
        final isGoal = saving.type == SavingType.goal;
        final targetAmount = saving.targetAmount ?? 0.0;
        final progress = (isGoal && targetAmount > 0) 
            ? (saving.currentAmount / targetAmount).clamp(0.0, 1.0) 
            : 0.0;

        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) => Container(
            clipBehavior: Clip.hardEdge, // Para que el confeti no se salga si usamos overflow
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: Stack(
              children: [
                ListView( // Cambiado a ListView para permitir scroll con el historial
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    // HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(width: 48), // Espaciador para centrar
                        Icon(getIconFromCode(saving.iconCode), size: 50, color: Color(saving.colorValue)),
                        IconButton(
                          onPressed: () => _showEditDialog(context, saving),
                          icon: const Icon(Icons.edit, color: Colors.grey),
                          tooltip: "Editar Ahorro",
                        ),
                      ],
                    ),
                    const Gap(10),
                    Text(saving.name, textAlign: TextAlign.center, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    Text(isGoal ? "Meta: \$${saving.targetAmount}" : "Fondo de Ahorro", textAlign: TextAlign.center, style: TextStyle(color: colors.outline)),
                    
                    const Gap(20),
                    
                    // PROGRESO
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            Text("\$${saving.currentAmount.toStringAsFixed(2)}", 
                                style: TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: Color(saving.colorValue))),
                            const Text("Ahorrado Actualmente", style: TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        if (saving.currentAmount > 0) ...[
                          const Gap(15),
                          ElevatedButton(
                            onPressed: () => _showUseSavingModal(context, saving),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colors.surfaceContainerHighest,
                              foregroundColor: colors.onSurface,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Text("Usar\nAhorro", textAlign: TextAlign.center, style: TextStyle(fontSize: 10)),
                          ),
                        ]
                      ],
                    ),
                    
                    if (isGoal) ...[
                      const Gap(20),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(5),
                        color: Color(saving.colorValue),
                        backgroundColor: colors.surfaceContainerHighest,
                      ),
                      const Gap(5),
                      Text("${(progress * 100).toStringAsFixed(1)}% completado", style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],

                    const Gap(30),
                    const Divider(),

                    // BOTÓN DEPOSITAR
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showDepositDialog(context, saving),
                        icon: const Icon(FontAwesomeIcons.circleDollarToSlot),
                        label: const Text("REGISTRAR AHORRO"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(saving.colorValue),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    
                    const Gap(10),

                    // HISTORIAL
                    const Gap(20),
                    const Text("Historial de Ahorros", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const Gap(10),
                    _buildHistoryList(dao, saving.id),
                  ],
                ),
                
                // ANIMACIÓN DE CONFETI
                if (_showConfetti)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: _SimpleConfetti(
                        onFinished: () => setState(() => _showConfetti = false),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHistoryList(dynamic dao, int savingId) {
    return StreamBuilder<List<FinancialTransaction>>(
      stream: dao.watchSavingTransactions(savingId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(20.0),
            child: Center(child: Text("Aún no hay depósitos.", style: TextStyle(color: Colors.grey))),
          );
        }
        final txs = snapshot.data!;
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: txs.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final tx = txs[index];
            return ListTile(
              leading: const Icon(FontAwesomeIcons.circleCheck, color: Colors.green, size: 20),
              title: Text(DateFormat('dd MMM yyyy', 'es').format(tx.date)),
              trailing: Text("+\$${tx.amount.toStringAsFixed(2)}", 
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            );
          },
        );
      },
    );
  }

  void _showEditDialog(BuildContext context, Saving saving) {
    final nameCtrl = TextEditingController(text: saving.name);
    final targetCtrl = TextEditingController(text: saving.targetAmount?.toString() ?? "");
    int selectedIcon = saving.iconCode;
    int selectedColor = saving.colorValue;
    
    // Iconos disponibles para seleccionar
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

    // Colores disponibles
    final List<Color> availableColors = [
      const Color(0xFFE91E63), // Pink (Default)
      Colors.teal,
      Colors.blue,
      Colors.orange,
      Colors.purple,
      Colors.green,
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Editar Ahorro"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Nombre", prefixIcon: Icon(Icons.label)),
                  ),
                  const Gap(15),
                  if (saving.type == SavingType.goal) ...[
                    TextField(
                      controller: targetCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: "Meta Objetivo", prefixIcon: Icon(Icons.flag)),
                    ),
                    const Gap(15),
                  ],
                  const Text("Icono", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Gap(10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: availableIcons.map((icon) {
                      final isSelected = selectedIcon == icon.codePoint;
                      return GestureDetector(
                        onTap: () => setState(() => selectedIcon = icon.codePoint),
                        child: CircleAvatar(
                          backgroundColor: isSelected ? Color(saving.colorValue) : Colors.grey.shade200,
                          foregroundColor: isSelected ? Colors.white : Colors.grey,
                          child: Icon(icon, size: 18),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(15),
                  const Text("Color", style: TextStyle(fontWeight: FontWeight.bold)),
                  const Gap(10),
                  Wrap(
                    spacing: 10,
                    children: availableColors.map((color) {
                      final isSelected = selectedColor == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => selectedColor = color.toARGB32()),
                        child: CircleAvatar(
                          backgroundColor: color,
                          radius: 16,
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 16) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(25),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(ctx); // Cerrar diálogo editar
                      _deleteSaving(context, saving.id); // Llamar confirmación borrar
                    },
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text("Eliminar Ahorro", style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
              ElevatedButton(
                onPressed: () async {
                  final newTarget = double.tryParse(targetCtrl.text);
                  
                  if (saving.type == SavingType.goal && newTarget != null) {
                    if (newTarget < saving.currentAmount) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("La meta no puede ser menor a lo ya ahorrado.")));
                      return;
                    }
                    saving.targetAmount = newTarget;
                  }
                  saving.name = nameCtrl.text;
                  saving.iconCode = selectedIcon;
                  saving.colorValue = selectedColor;

                  await ref.read(savingsDaoProvider).updateSaving(saving);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
                child: const Text("Guardar"),
              )
            ],
          );
        }
      ),
    );
  }

  void _showDepositDialog(BuildContext context, Saving saving) async {
    final dao = ref.read(savingsDaoProvider);
    double suggestedAmount = 0.0;

    // Calcular monto sugerido
    if (saving.method == SavingMethod.fixed) {
      suggestedAmount = saving.fixedAmount ?? 0.0;
    } else {
      // Calcular porcentaje del remanente
      final netProjection = await dao.calculateMonthlyNetProjection();
      // Si el remanente es negativo, sugerimos 0
      final base = netProjection > 0 ? netProjection : 0.0;
      suggestedAmount = base * ((saving.percentage ?? 0) / 100);
    }

    final controller = TextEditingController(text: suggestedAmount.toStringAsFixed(2));

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Registrar Ahorro"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Monto a depositar:"),
            const Gap(10),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(prefixText: "\$ "),
            ),
            if (saving.method == SavingMethod.percentage)
              const Padding(
                padding: EdgeInsets.only(top: 8.0),
                child: Text("Calculado según proyección actual", style: TextStyle(fontSize: 10, color: Colors.grey)),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount > 0) {
                await dao.depositToSaving(saving, amount);
                if (!ctx.mounted) return;
                
                // Verificar si se completó la meta para lanzar confeti
                if (saving.type == SavingType.goal && 
                    saving.targetAmount != null && 
                    saving.currentAmount >= saving.targetAmount!) {
                  setState(() {
                    _showConfetti = true;
                  });
                }

                Navigator.pop(ctx);
              }
            },
            child: const Text("Confirmar"),
          )
        ],
      ),
    );
  }

  void _showUseSavingModal(BuildContext context, Saving saving) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => AddExpenseModal(
        maxAmount: saving.currentAmount,
        isFromSaving: true,
        onExpenseSaved: (amount) async {
          // Lógica para equilibrar: Crear Ingreso y Reducir Ahorro
          final isar = await IsarService().db;
          await isar.writeTxn(() async {
            // 1. Crear Ingreso para equilibrar el gasto
            final income = FinancialTransaction()
              ..type = TransactionType.income
              ..amount = amount
              ..date = DateTime.now()
              ..note = "Ingreso por Uso de Ahorro: ${saving.name}"
              ..categoryName = "Ahorros"
              ..categoryIconCode = saving.iconCode
              ..colorValue = saving.colorValue;
            await isar.financialTransactions.put(income);

            // 2. Registrar retiro en el historial del ahorro (monto negativo)
            final withdrawal = FinancialTransaction()
              ..type = TransactionType.expense // Se marca como egreso interno del ahorro
              ..amount = -amount // Negativo para restar
              ..date = DateTime.now()
              ..note = "Uso de fondos"
              ..categoryName = "Ahorros" // ✅ Inicializamos campos obligatorios
              ..categoryIconCode = saving.iconCode
              ..colorValue = saving.colorValue
              ..relatedSaving.value = saving;
            
            await isar.financialTransactions.put(withdrawal);
            await withdrawal.relatedSaving.save();

            // 3. Actualizar saldo del ahorro
            saving.currentAmount -= amount;
            await isar.savings.put(saving);
          });
        },
      ),
    );
  }

  void _deleteSaving(BuildContext context, int id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("¿Eliminar Ahorro?"),
        content: const Text("Se eliminará el plan, pero las transacciones pasadas quedarán en el historial general."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
          TextButton(
            onPressed: () async {
              // Borrado profundo manual para asegurar que se va el historial
              final isar = await IsarService().db;
              await isar.writeTxn(() async {
                // 1. Buscar transacciones asociadas y DESVINCULARLAS (no borrarlas)
                final txs = await isar.financialTransactions.filter().relatedSaving((q) => q.idEqualTo(id)).findAll();
                for (var tx in txs) {
                  tx.relatedSaving.reset(); // Romper el vínculo con el ahorro
                  await isar.financialTransactions.put(tx); // Guardar la transacción actualizada
                }

                // 2. Borrar el ahorro
                await isar.savings.delete(id);
              });

              if (ctx.mounted) {
                Navigator.pop(ctx); // Cerrar diálogo
                // El modal se cerrará automáticamente gracias al StreamBuilder
              }
            },
            child: const Text("Eliminar", style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }
}

// --- WIDGET DE CONFETI SIMPLE (Sin dependencias externas) ---
class _SimpleConfetti extends StatefulWidget {
  final VoidCallback onFinished;
  const _SimpleConfetti({required this.onFinished});

  @override
  State<_SimpleConfetti> createState() => _SimpleConfettiState();
}

class _SimpleConfettiState extends State<_SimpleConfetti> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _rnd = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 3));
    
    // Generar partículas
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
      builder: (context, child) {
        return CustomPaint(
          painter: _ConfettiPainter(_particles, _controller.value),
          size: Size.infinite,
        );
      },
    );
  }
}

class _Particle {
  late double x;
  late double y;
  late double speed;
  late double theta;
  late double radius;
  late Color color;

  _Particle(Random rnd) {
    x = rnd.nextDouble(); // 0.0 a 1.0 (ancho relativo)
    y = -rnd.nextDouble() * 0.5; // Empieza arriba fuera de pantalla
    speed = 0.01 + rnd.nextDouble() * 0.02;
    theta = rnd.nextDouble() * 2 * pi;
    radius = 3 + rnd.nextDouble() * 5;
    color = [Colors.red, Colors.blue, Colors.green, Colors.yellow, Colors.purple, Colors.orange][rnd.nextInt(6)];
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
      // Actualizar posición (simulación simple en el draw loop)
      p.y += p.speed;
      p.x += sin(p.theta + progress * 10) * 0.002; // Oscilación lateral

      final dx = p.x * size.width;
      final dy = p.y * size.height;

      // Solo dibujar si está en pantalla
      if (dy > -20 && dy < size.height + 20) {
        paint.color = p.color.withOpacity((1.0 - progress).clamp(0.0, 1.0)); // Desvanecer al final
        canvas.drawCircle(Offset(dx, dy), p.radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}