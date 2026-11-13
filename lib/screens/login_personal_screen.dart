import 'package:flutter/material.dart';
import '../store.dart';
import 'personal_screen.dart';

class LoginPersonalScreen extends StatefulWidget {
  const LoginPersonalScreen({super.key});
  @override
  State<LoginPersonalScreen> createState() => _LoginPersonalScreenState();
}

class _LoginPersonalScreenState extends State<LoginPersonalScreen> {
  final _correo = TextEditingController();
  final _clave = TextEditingController();
  String? _err;
  bool _ver = false;

  void _entrar() {
    if (Store.instance.loginPersonal(_correo.text, _clave.text) != null) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const PersonalScreen()));
    } else {
      setState(() => _err = 'Correo o contraseña incorrectos.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Acceso personal de salud')),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(padding: const EdgeInsets.all(20), children: [
              TextField(
                controller: _correo,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Correo'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _clave,
                obscureText: !_ver,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  errorText: _err,
                  suffixIcon: IconButton(
                    icon: Icon(_ver ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _ver = !_ver),
                  ),
                ),
                onSubmitted: (_) => _entrar(),
              ),
              const SizedBox(height: 16),
              FilledButton(onPressed: _entrar, child: const Text('Ingresar')),
            ]),
          ),
        ),
      );
}
