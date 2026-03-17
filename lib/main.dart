import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'app/router.dart';

/// Cold-start deep link — consumed by SplashScreen._navigate()
Uri? _pendingDeepLink;

Uri? consumePendingDeepLink() {
  final link = _pendingDeepLink;
  _pendingDeepLink = null;
  return link;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  try {
    _pendingDeepLink = await AppLinks().getInitialLink();
  } catch (_) {}
  runApp(const ProviderScope(child: GyaanGuruApp()));
}

class GyaanGuruApp extends ConsumerStatefulWidget {
  const GyaanGuruApp({super.key});

  @override
  ConsumerState<GyaanGuruApp> createState() => _GyaanGuruAppState();
}

class _GyaanGuruAppState extends ConsumerState<GyaanGuruApp> {
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();
    // Warm-start: app already running when link is tapped
    _linkSub = AppLinks().uriLinkStream.listen(_handleLink);
  }

  void _handleLink(Uri uri) {
    if (uri.scheme != 'gyaanguru') return;
    final segs = uri.pathSegments;
    // gyaanguru:///challenge/accept/{token}
    if (segs.length >= 3 && segs[0] == 'challenge' && segs[1] == 'accept') {
      final token = segs[2];
      if (token.isNotEmpty) router.go('/challenge/accept/$token');
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Gyaan Guru',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.dark,
      // Clamp system text scaling so layout never breaks on accessibility sizes
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(
              minScaleFactor: 0.85,
              maxScaleFactor: 1.15,
            ),
          ),
          child: child!,
        );
      },
      routerConfig: router,
    );
  }
}
