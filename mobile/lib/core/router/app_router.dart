import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/welcome_screen.dart';
import '../../features/scanner/presentation/universal_scanner_screen.dart';
import '../../features/analysis/presentation/food_analysis_screen.dart';
import '../../features/analysis/models/food_analysis_model.dart';
import '../../features/street_food/presentation/street_food_screen.dart';
import '../../features/diary/presentation/daily_diary_screen.dart';
import '../../features/subscription/presentation/paywall_modal.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/welcome',
    routes: [
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithBottomNav(child: child);
        },
        routes: [
          GoRoute(
            path: '/scanner',
            builder: (context, state) => const UniversalScannerScreen(),
          ),
          GoRoute(
            path: '/street-food',
            builder: (context, state) => const StreetFoodIndexScreen(),
          ),
          GoRoute(
            path: '/diary',
            builder: (context, state) => const DailyDiaryScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/analysis',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is FoodAnalysisResponse) {
            return FoodAnalysisScreen(analysis: extra);
          } else if (extra is Map<String, dynamic>) {
            return FoodAnalysisScreen(rawPayload: extra);
          }
          return const FoodAnalysisScreen();
        },
      ),
      GoRoute(
        path: '/subscription',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          return const Scaffold(
            body: SafeArea(child: PaywallModal()),
          );
        },
      ),
    ],
  );
});

class ScaffoldWithBottomNav extends StatelessWidget {
  final Widget child;
  const ScaffoldWithBottomNav({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/street-food')) currentIndex = 1;
    if (location.startsWith('/diary')) currentIndex = 2;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (idx) {
          switch (idx) {
            case 0:
              context.go('/scanner');
              break;
            case 1:
              context.go('/street-food');
              break;
            case 2:
              context.go('/diary');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.fastfood_outlined),
            label: 'Street Food',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_rounded),
            label: 'Diary',
          ),
        ],
      ),
    );
  }
}
