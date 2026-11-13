import 'dart:async';
import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../utils.dart';
import 'expediente_screen.dart';

/// Panel del personal de salud. El médico ve indicadores y puede iniciar
/// atención; la enfermería ve la lista de pacientes y sus expedientes.
class PersonalScreen extends StatefulWidget {
  const PersonalScreen({super.key});
  @override
  State<PersonalScreen> createState() => _PersonalScreenState();
}

class _PersonalScreenState extends State<PersonalScreen> {
  final s = Store.instance;
  StreamSubscription<AlertaEvento>? _sub;

  @override
  void initState() {
    super.initState();
    // Alerta al personal a los 7 minutos sin atención.
    _sub = s.alertas.listen((e) {
      if (!mounted || e.minutos != 7) return;
      final p = s.paciente(e.visita.cedula);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade700,
        content: Text(
            'ALERTA: ${p?.nombreCompleto ?? 'Paciente'} supera los 7 min sin atención.'),
      ));
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Widget _stat(String t, String v, {Color? color}) => SizedBox(
        width: 150,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t, style: const TextStyle(fontSize: 12)),
              Text(v,
                  style: TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          if (!s.esPersonal) return const Scaffold();
          final vs = s.visitas.reversed.toList();
          final top = s.aspectoTop;
          final sug = <String>[
            if (s.excedidos > 0)
              'Reforzar triage en horas pico: hubo pacientes que superaron los 7 minutos.',
            if (top != null && top.key != 'Nada, todo bien')
              'Plan de mejora prioritario: "${top.key}" (${top.value} mención/es).',
            if (s.calPromedio > 0 && s.calPromedio < 3.5)
              'Calificación promedio baja: revisar protocolo de trato y comunicación.',
          ];
          if (sug.isEmpty) sug.add('Sin hallazgos críticos por ahora.');

          return Scaffold(
            appBar: AppBar(
              title: Text(s.esMedico ? 'Panel médico' : 'Panel de enfermería'),
              actions: [
                IconButton(
                  tooltip: 'Cerrar sesión',
                  icon: const Icon(Icons.logout),
                  onPressed: () {
                    s.cerrarSesion();
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                )
              ],
            ),
            body: ListView(padding: const EdgeInsets.all(16), children: [
              for (final v in s.criticas)
                Aviso(
                    'ALERTA: ${s.paciente(v.cedula)?.nombreCompleto} lleva ${fmt(s.segundos(v.llegada))} sin atención.',
                    Colors.red.shade700),
              if (s.esMedico)
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _stat('Espera promedio', fmt(s.esperaPromedio)),
                  _stat('Casos sobre 7 min', '${s.excedidos}',
                      color: s.excedidos > 0 ? Colors.red : Colors.green),
                  _stat('Calificación',
                      s.calPromedio == 0 ? '-' : '${s.calPromedio.toStringAsFixed(1)} ★'),
                  _stat('Visitas', '${vs.length}'),
                ]),
              const SizedBox(height: 12),
              const Text('Pacientes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              if (vs.isEmpty)
                const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text('Aún no hay pacientes registrados.')),
              for (final v in vs) _tarjeta(v),
              if (s.esMedico) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Calidad y plan de contingencia',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      for (final x in sug) Text('• $x'),
                      if (s.calificadas.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        const Text('Opiniones',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        for (final v in s.calificadas)
                          Text('${'★' * v.cal!.estrellas} ${v.cal!.aspecto}'
                              '${v.cal!.comentario.isEmpty ? '' : ' - ${v.cal!.comentario}'}'),
                      ],
                    ]),
                  ),
                ),
                OutlinedButton(
                  onPressed: () async {
                    final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                              title: const Text('Reiniciar demo'),
                              content: const Text('Se borrarán todos los datos.'),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(c, false),
                                    child: const Text('Cancelar')),
                                FilledButton(
                                    onPressed: () => Navigator.pop(c, true),
                                    child: const Text('Borrar')),
                              ],
                            ));
                    if (ok == true) s.reiniciarDemo();
                  },
                  child: const Text('Reiniciar demo'),
                ),
              ],
            ]),
          );
        },
      );

  Widget _tarjeta(Visita v) {
    final p = s.paciente(v.cedula);
    final est = s.estado(v);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
                child: Text(p?.nombreCompleto ?? v.cedula,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            EstadoChip(est),
          ]),
          Text('CC ${v.cedula} · Sangre ${p?.sangre ?? '-'} · Tel ${p?.telefono ?? '-'}'),
          Text('Llegada ${hora(v.llegada)} · Salida ${hora(v.salida)} · '
              'Espera ${fmt(s.espera(v))}'
              '${v.cal != null ? ' · ${v.cal!.estrellas}★' : ''}'),
          const SizedBox(height: 6),
          Wrap(spacing: 8, alignment: WrapAlignment.end, children: [
            OutlinedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            ExpedienteScreen(visitaId: v.id, rol: s.rol))),
                child: const Text('Ver expediente')),
            if (s.esMedico && v.atencion == null && v.salida == null)
              FilledButton(
                  onPressed: () => s.iniciarAtencion(v.id),
                  child: const Text('Iniciar atención')),
          ]),
        ]),
      ),
    );
  }
}
