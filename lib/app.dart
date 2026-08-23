import 'package:dairyfarmabuka/screens/auth/auth_gate.dart';
import 'package:flutter/material.dart';

class DairyFarmApp extends StatelessWidget {
  const DairyFarmApp({super.key});
  //go router 2.0 and animations bakaya after firebase and shared preferences again implement.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Dairy Farm Manager',
      home: const AuthGate(),
    );
  }
}
