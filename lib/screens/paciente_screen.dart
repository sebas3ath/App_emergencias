import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets/rating_dialog.dart';
import 'expediente_screen.dart';

class PacienteScreen extends StatefulWidget {
  const PacienteScreen({super.key});
  @override
  State<PacienteScreen> createState() => _PacienteScreenState();
}

class _PacienteScreenState extends State<PacienteScreen> {
  final s = Store.instance;
  StreamSubscription<AlertaEvento>? _sub;

  @override
  void initState() {
    super.initState();
    // Notificación a los 5 minutos sin atención.
    _sub = s.alertas.listen((e) {
      if (!mounted || e.visita.cedula != s.cedulaSesion) return;
      if (e.minutos == 5) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.orange,
          content: Text('Han pasado 5 minutos sin atenderte.'),
        ));
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _cerrar() {
    s.cerrarSesion();
    Navigator.popUntil(context, (r) => r.isFirst);
  }

  Future<void> _salir(Visita v) async {
    s.registrarSalida(v.id);
    final r = await showDialog<Calificacion>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const RatingDialog());
    if (r != null) s.calificar(v.id, r);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final ced = s.cedulaSesion;
          final p = ced == null ? null : s.paciente(ced);
          final v = ced == null ? null : (s.visitaActiva(ced) ?? s.ultimaVisita(ced));
          if (p == null || v == null) return const Scaffold();
          return Scaffold(
            appBar: AppBar(
              title: Text('Hola, ${p.nombres}'),
              actions: [
                IconButton(
                    tooltip: 'Cerrar sesión',
                    icon: const Icon(Icons.logout),
                    onPressed: _cerrar)
              ],
            ),
            body: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      v.salida != null ? _resumen(v) : _activa(v, p),
                      const SizedBox(height: 12),
                      _clinica(v),
                    ]),
              ),
            ),
          );
        },
      );

  Widget _activa(Visita v, Paciente p) {
    final e = s.segundos(v.llegada);
    final est = s.estado(v);
    final enEspera = v.atencion == null;
    final seg = enEspera ? e : s.espera(v);
    final color = est == Estado.alerta
        ? Colors.red
        : est == Estado.aviso
            ? Colors.orange
            : Colors.green;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(p.nombreCompleto,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            EstadoChip(est),
          ]),
          const SizedBox(height: 4),
          Text('Llegada: ${hora(v.llegada)}  ·  ${v.medico}'),
          const SizedBox(height: 16),
          Text(enEspera ? 'Tiempo esperando' : 'Esperaste hasta ser atendido'),
          Text(fmt(seg),
              style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
              value: enEspera ? (e / Config.maxSeg).clamp(0.0, 1.0) : 1,
              minHeight: 10,
              color: enEspera ? color : Colors.green),
          const SizedBox(height: 6),
          const Text('Máximo esperado: 7 min. Aviso a los 5 min.'),
          if (enEspera && e >= Config.avisoSeg)
            Aviso(
                'Han pasado 5 minutos sin atenderte.'
                '${e >= Config.maxSeg ? ' Tu médico ya recibió una alerta.' : ''}',
                e >= Config.maxSeg ? Colors.red : Colors.orange),
          if (!enEspera)
            Aviso('Te están atendiendo desde las ${hora(v.atencion)}.',
                Colors.green),
          const SizedBox(height: 12),
          FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
              onPressed: () => _salir(v),
              child: const Text('Registrar mi salida')),
        ]),
      ),
    );
  }

  Widget _resumen(Visita v) => Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Gracias por tu visita',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Salida registrada a las ${hora(v.salida)}.'),
            Text('Tiempo total en urgencias: ${fmt(s.segundos(v.llegada, v.salida))}'),
            if (v.cal != null) ...[
              const SizedBox(height: 8),
              Text('Tu calificación: ${'★' * v.cal!.estrellas}'),
            ] else ...[
              const SizedBox(height: 8),
              OutlinedButton(
                  onPressed: () async {
                    final r = await showDialog<Calificacion>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const RatingDialog());
                    if (r != null) s.calificar(v.id, r);
                  },
                  child: const Text('Calificar mi experiencia')),
            ],
            const SizedBox(height: 16),
            FilledButton(
                onPressed: () => s.ingresar(v.cedula),
                child: const Text('Nuevo ingreso a urgencias')),
            TextButton(onPressed: _cerrar, child: const Text('Cerrar sesión')),
          ]),
        ),
      );

  /// Resumen de solo lectura de la información clínica registrada por el personal.
  Widget _clinica(Visita v) {
    final exPend = v.examenes.where((e) => e.realizado == null).length;
    final tomasPend = v.medicamentos
        .fold<int>(0, (a, m) => a + m.tomas.where((t) => t.administrada == null).length);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mi información clínica',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Historia clínica: '
              '${v.triaje == null ? 'triaje pendiente' : 'triaje registrado'}'
              '${v.notaAtencion == null ? '' : ' · atención registrada'}'),
          Text('Exámenes pendientes: $exPend'),
          Text('Tomas de medicamentos pendientes: $tomasPend'),
          if (v.hosp != null) Text('Hospitalización: habitación ${v.hosp!.habitacion}'),
          const SizedBox(height: 4),
          const Text('Solo el personal de salud puede modificar esta información.',
              style: TextStyle(fontSize: 12)),
          const SizedBox(height: 8),
          OutlinedButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ExpedienteScreen(visitaId: v.id, rol: null))),
              child: const Text('Ver detalle')),
        ]),
      ),
    );
  }
}
