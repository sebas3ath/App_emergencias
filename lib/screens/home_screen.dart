import 'package:flutter/material.dart';
import '../store.dart';
import 'login_personal_screen.dart';
import 'paciente_auth_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = Store.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Urgencias en tiempo real')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const Text('¿Quién eres?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              FilledButton.icon(
                style: FilledButton.styleFrom(padding: const EdgeInsets.all(24)),
                icon: const Icon(Icons.personal_injury),
                label: const Text('Soy paciente'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PacienteAuthScreen())),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(24)),
                icon: const Icon(Icons.medical_services),
                label: const Text('Soy personal de salud'),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const LoginPersonalScreen())),
              ),
              const SizedBox(height: 24),
              ListenableBuilder(
                listenable: s,
                builder: (_, __) => SwitchListTile(
                  title: const Text('Modo demo rápido'),
                  subtitle: const Text('1 minuto = 6 segundos'),
                  value: s.rapido,
                  onChanged: s.setRapido,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
