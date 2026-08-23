import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'firebase_options.dart';
import 'router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: DairyFarmApp()));
}

class DairyFarmApp extends StatelessWidget {
  const DairyFarmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Dairy Farm Manager',
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,

      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: Colors.green,

        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),

        cardTheme: const CardThemeData(elevation: 1, margin: EdgeInsets.zero),

        appBarTheme: const AppBarTheme(centerTitle: false),
      ),
    );
  }
}
