import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../supabase/supabase_service.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../features/wallet/presentation/screens/add_transaction_screen.dart';
import '../../features/wallet/presentation/screens/manage_categories_screen.dart';
import '../../features/wallet/presentation/screens/wallet_dashboard_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/media_cleaner/presentation/screens/media_cleaner_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/wallet',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull?.session != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/login';
      if (isLoggedIn && isAuthRoute) return '/wallet';
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/auth/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/wallet',
                builder: (context, state) => const WalletScreen(),
                routes: [
                  GoRoute(
                    path: 'add',
                    builder: (context, state) => const AddTransactionScreen(),
                  ),
                  GoRoute(
                    path: 'categories',
                    builder: (context, state) =>
                        const ManageCategoriesScreen(),
                  ),
                  GoRoute(
                    path: 'dashboard',
                    builder: (context, state) =>
                        const WalletDashboardScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                builder: (context, state) => const NotificationsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/media',
                builder: (context, state) => const MediaCleanerScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
