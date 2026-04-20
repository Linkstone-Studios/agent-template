import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'core/constants/api_constants.dart';
import 'core/utils/logger.dart';
import 'core/theme/theme_provider.dart';
import 'core/services/remote_config_service.dart';
import 'routing/app_router.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.init(level: Level.INFO);
  final log = AppLogger.getLogger('Main');

  log.info('Starting AgentTemplate app...');

  // Load environment variables from .env file
  try {
    await dotenv.load(fileName: '.env');
    log.info('Environment variables loaded from .env');
  } catch (e) {
    log.warning('Could not load .env file: $e');
  }

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    log.info('Firebase initialized successfully');

    await FirebaseAppCheck.instance.activate();
    log.info('Firebase App Check activated');

    try {
      final remoteConfig = RemoteConfigService();
      await remoteConfig.initialize();
      log.info('Firebase Remote Config initialized successfully');
    } catch (e) {
      log.warning('Remote Config initialization failed: $e');
    }
  } catch (e) {
    log.warning('Firebase initialization failed: $e');
  }

  // Initialize Supabase
  final supabaseUrl = ApiConstants.supabaseUrl;
  final supabaseAnonKey = ApiConstants.supabaseAnonKey;
  log.info('Initializing Supabase with URL: $supabaseUrl');

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  log.info('Supabase initialized successfully');

  runApp(const ProviderScope(child: AgentTemplateApp()));
}

class AgentTemplateApp extends ConsumerWidget {
  const AgentTemplateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final log = AppLogger.getLogger('AgentTemplateApp');
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    final effectiveTheme = switch (themeMode) {
      ThemeMode.light => buildShadcnLightTheme(),
      ThemeMode.dark => buildShadcnDarkTheme(),
      ThemeMode.system => buildShadcnLightTheme(),
    };

    log.info(
      'Building AgentTemplateApp with themeMode: $themeMode',
    );

    return ShadcnApp.router(
      routerConfig: router,
      title: 'AgentTemplate',
      theme: effectiveTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}