import 'package:go_router/go_router.dart';
import '../screens/splash_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/matchmaking_screen.dart';
import '../screens/battle_screen.dart';
import '../screens/result_screen.dart';
import '../screens/challenge_create_screen.dart';
import '../screens/challenge_accept_screen.dart';
import '../screens/daily_challenge_screen.dart';
import '../screens/leaderboard_screen.dart';
import '../screens/profile_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (ctx, state) => const SplashScreen()),
    GoRoute(path: '/register', builder: (ctx, state) => const RegisterScreen()),
    GoRoute(path: '/home', builder: (ctx, state) => const HomeScreen()),
    GoRoute(
      path: '/matchmaking',
      builder: (ctx, state) {
        final category = state.uri.queryParameters['category'] ?? 'cricket';
        return MatchmakingScreen(category: category);
      },
    ),
    GoRoute(
      path: '/battle/:matchId',
      builder: (ctx, state) {
        final matchId = state.pathParameters['matchId']!;
        final category = state.uri.queryParameters['category'] ?? '';
        return BattleScreen(matchId: matchId, category: category);
      },
    ),
    GoRoute(
      path: '/result',
      builder: (ctx, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return ResultScreen(data: extra ?? {});
      },
    ),
    GoRoute(path: '/challenge/create', builder: (ctx, state) => const ChallengeCreateScreen()),
    GoRoute(
      path: '/challenge/accept/:token',
      builder: (ctx, state) {
        final token = state.pathParameters['token']!;
        return ChallengeAcceptScreen(token: token);
      },
    ),
    GoRoute(path: '/daily', builder: (ctx, state) => const DailyChallengeScreen()),
    GoRoute(path: '/leaderboard', builder: (ctx, state) => const LeaderboardScreen()),
    GoRoute(path: '/profile', builder: (ctx, state) => const ProfileScreen()),
  ],
);
