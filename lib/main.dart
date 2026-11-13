import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Store.instance.init();
  runApp(const UrgenciasApp());
}

class UrgenciasApp extends StatelessWidget {
  const UrgenciasApp({super.key});

  ThemeData _tema(Brightness b) => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF0F5C6B), brightness: b),
        inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(), isDense: true),
      );

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Urgencias en tiempo real',
        debugShowCheckedModeBanner: false,
        theme: _tema(Brightness.light),
        darkTheme: _tema(Brightness.dark),
        home: const HomeScreen(),
      );
}
