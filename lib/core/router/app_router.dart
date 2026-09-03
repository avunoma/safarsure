import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/features/auth/providers/auth_provider.dart';
import 'package:safarsure/features/auth/screens/login_screen.dart';
import 'package:safarsure/features/auth/screens/otp_screen.dart';
import 'package:safarsure/features/auth/screens/splash_screen.dart';
import 'package:safarsure/features/home/screens/home_screen.dart';
import 'package:safarsure/features/profile/screens/profile_screen.dart';
import 'package:safarsure/features/requests/screens/request_status_screen.dart';
import 'package:safarsure/features/requests/screens/request_seat_screen.dart';
import 'package:safarsure/features/search/screens/search_results_screen.dart';
import 'package:safarsure/features/search/screens/search_screen.dart';
import 'package:safarsure/features/trips/screens/my_rides_screen.dart';
import 'package:safarsure/features/trips/screens/post_ride_screen.dart';
import 'package:safarsure/features/trips/screens/trip_detail_screen.dart';
import 'package:safarsure/features/trips/screens/trip_requests_screen.dart';
import 'package:safarsure/features/chat/screens/chat_screen.dart';
import 'package:safarsure/features/ratings/screens/rate_trip_screen.dart';
import 'package:safarsure/core/widgets/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _AuthRefreshListenable(ref),
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final user = authState.value;
      final location = state.matchedLocation;

      if (isLoading) {
        return location == '/splash' ? null : '/splash';
      }

      final isAuthRoute =
          location == '/login' || location == '/otp' || location == '/splash';

      if (user == null && !isAuthRoute) {
        return '/login';
      }

      if (user != null && isAuthRoute) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>? ?? {};
          return OtpScreen(
            phone: extra['phone'] as String? ?? '',
            name: extra['name'] as String? ?? '',
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (context, state) => const SearchScreen(),
                  ),
                  GoRoute(
                    path: 'results',
                    builder: (context, state) {
                      final params = state.extra as Map<String, dynamic>? ?? {};
                      return SearchResultsScreen(
                        fromCity: params['fromCity'] as String? ?? '',
                        toCity: params['toCity'] as String? ?? '',
                        date: params['date'] as DateTime? ?? DateTime.now(),
                        seats: params['seats'] as int? ?? 1,
                        leavingSoonOnly:
                            params['leavingSoonOnly'] as bool? ?? false,
                      );
                    },
                  ),
                  GoRoute(
                    path: 'trip/:tripId',
                    builder: (context, state) {
                      final tripId = state.pathParameters['tripId']!;
                      return TripDetailScreen(tripId: tripId);
                    },
                    routes: [
                      GoRoute(
                        path: 'request',
                        builder: (context, state) {
                          final tripId = state.pathParameters['tripId']!;
                          return RequestSeatScreen(tripId: tripId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/my-rides',
                builder: (context, state) => const MyRidesScreen(),
                routes: [
                  GoRoute(
                    path: 'post',
                    builder: (context, state) => const PostRideScreen(),
                  ),
                  GoRoute(
                    path: 'trip/:tripId',
                    builder: (context, state) {
                      final tripId = state.pathParameters['tripId']!;
                      return TripDetailScreen(tripId: tripId, isOwner: true);
                    },
                    routes: [
                      GoRoute(
                        path: 'requests',
                        builder: (context, state) {
                          final tripId = state.pathParameters['tripId']!;
                          return TripRequestsScreen(tripId: tripId);
                        },
                      ),
                    ],
                  ),
                  GoRoute(
                    path: 'request/:requestId',
                    builder: (context, state) {
                      final requestId = state.pathParameters['requestId']!;
                      return RequestStatusScreen(requestId: requestId);
                    },
                    routes: [
                      GoRoute(
                        path: 'chat',
                        builder: (context, state) {
                          final requestId =
                              state.pathParameters['requestId']!;
                          return ChatScreen(requestId: requestId);
                        },
                      ),
                      GoRoute(
                        path: 'rate',
                        builder: (context, state) {
                          final requestId =
                              state.pathParameters['requestId']!;
                          final extra =
                              state.extra as Map<String, dynamic>? ?? {};
                          return RateTripScreen(
                            requestId: requestId,
                            tripId: extra['tripId'] as String? ?? '',
                            rateeId: extra['rateeId'] as String? ?? '',
                            rateeLabel:
                                extra['rateeLabel'] as String? ?? 'Traveller',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
}
