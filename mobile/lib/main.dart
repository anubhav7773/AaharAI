import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/app_env.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppEnv.fromEnvironment().validate();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    const ProviderScope(
      child: AaharAiApp(),
    ),
  );
}

class AaharAiApp extends ConsumerWidget {
  const AaharAiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AaharAi',
      debugShowCheckedModeBanner: false,
      theme: AaharTheme.lightTheme,
      routerConfig: router,
    );
  }
}
