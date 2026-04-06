import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import 'widgets/home_greeting_header.dart';
import 'widgets/glass_filter_selector.dart';
import 'widgets/hero_balance_card.dart';
import 'widgets/glass_summary_metrics.dart';
import 'widgets/upcoming_payments_section.dart';
import 'widgets/savings_progress_section.dart';
import 'widgets/recent_activity_feed.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late AnimationController _entranceController;
  late final List<Animation<double>> _fadeAnims;
  late final List<Animation<Offset>> _slideAnims;

  static const int _maxStaggerIndex = 12;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _fadeAnims = List.generate(_maxStaggerIndex, (i) {
      final begin = (i * 0.06).clamp(0.0, 0.7);
      final end = (begin + 0.4).clamp(0.0, 1.0);
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _slideAnims = List.generate(_maxStaggerIndex, (i) {
      final begin = (i * 0.06).clamp(0.0, 0.7);
      final end = (begin + 0.4).clamp(0.0, 1.0);
      return Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entranceController,
          curve: Interval(begin, end, curve: Curves.easeOutCubic),
        ),
      );
    });

    _entranceController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Widget _staggered(int index, Widget child) {
    final i = index.clamp(0, _maxStaggerIndex - 1);
    return FadeTransition(
      opacity: _fadeAnims[i],
      child: SlideTransition(position: _slideAnims[i], child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sections = <Widget>[
      _staggered(0, const HomeGreetingHeader()),
      _staggered(1, const GlassFilterSelector()),
      _staggered(2, const Gap(16)),
      _staggered(2, const HeroBalanceCard()),
      _staggered(3, const Gap(16)),
      _staggered(3, const GlassSummaryMetrics()),
      _staggered(4, const Gap(16)),
      _staggered(4, const UpcomingPaymentsSection()),
      _staggered(5, const Gap(16)),
      _staggered(5, const SavingsProgressSection()),
      _staggered(6, const Gap(16)),
      _staggered(6, const RecentActivityFeed()),
      const Gap(110),
    ];

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverSafeArea(
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => sections[index],
                childCount: sections.length,
                addRepaintBoundaries: true,
                addAutomaticKeepAlives: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
