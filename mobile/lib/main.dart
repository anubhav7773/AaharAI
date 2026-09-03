import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/config/app_env.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;
  try {
    final env = AppEnv.fromEnvironment().validate();
    await Supabase.initialize(
      url: env.supabaseUrl,
      publishableKey: env.supabaseAnonKey,
    );
  } on Object catch (error) {
    startupError = error;
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(
    ProviderScope(
      child: AaharAiApp(startupError: startupError),
    ),
  );
}

class AaharAiApp extends ConsumerWidget {
  const AaharAiApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (startupError != null) {
      return MaterialApp(
        title: 'AaharAi',
        debugShowCheckedModeBanner: false,
        home: StartupErrorScreen(error: startupError!),
      );
    }
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'AaharAi',
      debugShowCheckedModeBanner: false,
      theme: AaharTheme.lightTheme,
      routerConfig: router,
    );
  }
}

class StartupErrorScreen extends StatelessWidget {
  const StartupErrorScreen({super.key, required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'App configuration is incomplete.\n\n$error\n\n'
            'Build with SUPABASE_URL and SUPABASE_ANON_KEY using --dart-define.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
