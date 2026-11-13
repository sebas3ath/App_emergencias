import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import 'paciente_screen.dart';

void _irAPaciente(BuildContext c) => Navigator.pushReplacement(
    c, MaterialPageRoute(builder: (_) => const PacienteScreen()));

class PacienteAuthScreen extends StatelessWidget {
  const PacienteAuthScreen({super.key});

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Pacientes'),
            bottom: const TabBar(tabs: [
              Tab(text: 'Ingresar con cédula'),
              Tab(text: 'Registrarme'),
            ]),
          ),
          body: const TabBarView(children: [_Ingreso(), _Registro()]),
        ),
      );
}

class _Ingreso extends StatefulWidget {
  const _Ingreso();
  @override
  State<_Ingreso> createState() => _IngresoState();
}

class _IngresoState extends State<_Ingreso> {
  final _ced = TextEditingController();
  String? _err;

  void _entrar() {
    final c = _ced.text.trim();
    if (c.isEmpty) {
      setState(() => _err = 'Escribe tu cédula.');
      return;
    }
    final err = Store.instance.ingresar(c);
    if (err != null) {
      setState(() => _err = err);
    } else {
      _irAPaciente(context);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(padding: const EdgeInsets.all(20), children: [
            const Text('Si ya te registraste, entra solo con tu cédula. '
                'Se registrará tu hora de llegada.'),
            const SizedBox(height: 16),
            TextField(
              controller: _ced,
              keyboardType: TextInputType.number,
              decoration:
                  InputDecoration(labelText: 'Cédula', errorText: _err),
              onSubmitted: (_) => _entrar(),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _entrar, child: const Text('Ingresar')),
          ]),
        ),
      );
}

class _Registro extends StatefulWidget {
  const _Registro();
  @override
  State<_Registro> createState() => _RegistroState();
}

class _RegistroState extends State<_Registro> {
  final _form = GlobalKey<FormState>();
  final _n = TextEditingController(),
      _a = TextEditingController(),
      _c = TextEditingController(),
      _e = TextEditingController(),
      _t = TextEditingController();
  String _sangre = 'O+';
  String? _err;

  String? _req(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Campo obligatorio' : null;

  void _enviar() {
    if (!_form.currentState!.validate()) return;
    final err = Store.instance.registrar(Paciente(
      cedula: _c.text.trim(),
      nombres: _n.text.trim(),
      apellidos: _a.text.trim(),
      correo: _e.text.trim(),
      telefono: _t.text.trim(),
      sangre: _sangre,
    ));
    if (err != null) {
      setState(() => _err = err);
    } else {
      _irAPaciente(context);
    }
  }

  @override
  Widget build(BuildContext context) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                    controller: _n,
                    decoration: const InputDecoration(labelText: 'Nombres'),
                    validator: _req),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _a,
                    decoration: const InputDecoration(labelText: 'Apellidos'),
                    validator: _req),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _c,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Cédula'),
                    validator: _req),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _e,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                      const InputDecoration(labelText: 'Correo electrónico'),
                  validator: (v) => (v == null ||
                          !RegExp(r'^\S+@\S+\.\S+$').hasMatch(v.trim()))
                      ? 'Escribe un correo válido'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                    controller: _t,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Teléfono'),
                    validator: _req),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _sangre,
                  decoration:
                      const InputDecoration(labelText: 'Tipo de sangre'),
                  items: const ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']
                      .map((x) => DropdownMenuItem(value: x, child: Text(x)))
                      .toList(),
                  onChanged: (v) => setState(() => _sangre = v ?? 'O+'),
                ),
                if (_err != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(_err!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 16),
                FilledButton(
                    onPressed: _enviar,
                    child: const Text('Registrar ingreso a urgencias')),
              ],
            ),
          ),
        ),
      );
}
