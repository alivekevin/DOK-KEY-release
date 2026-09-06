import 'screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/dokkey_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = DokkeyProvider();
  await provider.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: provider),
      ],
      child: const DokkeyApp(),
    ),
  );
}

class DokkeyApp extends StatelessWidget {
  const DokkeyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();

    return MaterialApp(
      title: 'DOK-KEY — Daily Wisdom with Kkaebi',
      debugShowCheckedModeBanner: false,
      theme: DokkeyTheme.currentTheme,
      locale: Locale(provider.lang),
      supportedLocales: const [
        Locale('ko', 'KR'),
        Locale('en', 'US'),
        Locale('ja', 'JP'),
        Locale('zh', 'CN'),
        Locale('hi', 'IN'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
    );
  }
}