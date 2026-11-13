import 'package:flutter/material.dart';
import '../models.dart';
import '../store.dart';
import '../utils.dart';
import '../widgets/campos_dialog.dart';

/// Historia clínica, exámenes, medicamentos y hospitalización de una visita.
/// rol == null => paciente: SOLO LECTURA (no se muestra ningún botón de edición).
/// rol == medico => puede indicar y registrar todo.
/// rol == enfermeria => solo marca exámenes/dosis y registra visitas.
class ExpedienteScreen extends StatelessWidget {
  final String visitaId;
  final Rol? rol;
  const ExpedienteScreen({super.key, required this.visitaId, required this.rol});

  bool get _medico => rol == Rol.medico;
  bool get _personal => rol != null;
  Store get s => Store.instance;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: s,
        builder: (context, _) {
          final v = s.visita(visitaId);
          if (v == null) return const Scaffold();
          final p = s.paciente(v.cedula);
          return DefaultTabController(
            length: 4,
            child: Scaffold(
              appBar: AppBar(
                title: Text(p?.nombreCompleto ?? 'Paciente'),
                bottom: const TabBar(isScrollable: true, tabs: [
                  Tab(text: 'Historia'),
                  Tab(text: 'Exámenes'),
                  Tab(text: 'Medicamentos'),
                  Tab(text: 'Hospitalización'),
                ]),
              ),
              body: TabBarView(children: [
                _historia(context, v, p),
                _examenes(context, v),
                _meds(context, v),
                _hosp(context, v),
              ]),
            ),
          );
        },
      );

  // ---------- Utilidades de diseño ----------
  Widget _tarjeta(String titulo, List<Widget> hijos) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(titulo,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...hijos,
          ]),
        ),
      );

  Widget _soloLectura() => rol == null
      ? const Padding(
          padding: EdgeInsets.only(bottom: 8),
          child: Text(
              'Esta información la registra el personal de salud. Tú solo puedes consultarla.',
              style: TextStyle(fontSize: 12)),
        )
      : const SizedBox();

  Widget _boton(String texto, VoidCallback onPressed) => Align(
        alignment: Alignment.centerLeft,
        child: FilledButton(onPressed: onPressed, child: Text(texto)),
      );

  // ---------- Historia clínica ----------
  Widget _historia(BuildContext c, Visita v, Paciente? p) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _soloLectura(),
          _tarjeta('Datos del paciente', [
            Text(p?.nombreCompleto ?? v.cedula),
            Text('CC ${v.cedula} · Sangre ${p?.sangre ?? '-'}'),
            Text('Llegada: ${hora(v.llegada)}'),
          ]),
          _nota(c, 'Triaje', v.triaje,
              'Notas de triaje (motivo, síntomas, signos vitales)',
              (t) => s.guardarTriaje(v.id, t)),
          _nota(c, 'Atención médica', v.notaAtencion,
              'Notas de la consulta (valoración, indicaciones)',
              (t) => s.guardarNotaAtencion(v.id, t)),
        ],
      );

  Widget _nota(BuildContext c, String titulo, NotaClinica? n, String label,
      void Function(String) guardar) {
    return _tarjeta(titulo, [
      Text(n?.texto ?? 'Aún no registrado.'),
      if (n != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text('Registrado por ${n.por} · ${horaCorta(n.fecha)}',
              style: const TextStyle(fontSize: 12)),
        ),
      if (_medico)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: OutlinedButton(
            onPressed: () async {
              final r = await pedirCampos(c, titulo,
                  [Campo('texto', label, lineas: 5, inicial: n?.texto ?? '')]);
              if (r != null) guardar(r['texto']!);
            },
            child: Text(n == null ? 'Registrar' : 'Editar'),
          ),
        ),
    ]);
  }

  // ---------- Exámenes ----------
  Widget _examenes(BuildContext c, Visita v) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _soloLectura(),
          if (_medico) _boton('Indicar examen', () => _indicarExamen(c, v)),
          if (v.examenes.isEmpty)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No hay exámenes indicados.')),
          for (final e in v.examenes) _examenTile(v, e),
        ],
      );

  Widget _examenTile(Visita v, Examen e) {
    final hecho = e.realizado != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
                child: Text(e.nombre,
                    style: const TextStyle(fontWeight: FontWeight.bold))),
            Etiqueta(hecho ? 'Realizado' : 'Pendiente',
                hecho ? Colors.green.shade700 : Colors.orange.shade800),
          ]),
          Text(e.tipo == 'hospitalario'
              ? 'Monitoreo hospitalario'
              : 'Examen de urgencias'),
          Text('Indicado a las ${hora(e.indicado)}'),
          Text(hecho
              ? 'Realizado a las ${hora(e.realizado)} (${e.realizadoPor ?? ''}) · espera ${fmt(s.segundos(e.indicado, e.realizado))}'
              : 'Tiempo de espera: ${fmt(s.segundos(e.indicado))}'),
          if (_personal && !hecho)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                  onPressed: () => s.marcarExamen(v.id, e.id),
                  child: const Text('Marcar realizado')),
            ),
        ]),
      ),
    );
  }

  Future<void> _indicarExamen(BuildContext c, Visita v,
      {bool monitoreo = false}) async {
    final conTipo = !monitoreo && v.hosp != null;
    final r = await pedirCampos(
        c, monitoreo ? 'Examen de monitoreo' : 'Indicar examen', [
      const Campo('nombre', 'Nombre del examen (ej. Hemograma)'),
      if (conTipo)
        const Campo('tipo', 'Tipo',
            opciones: ['Urgencias', 'Monitoreo hospitalario']),
    ]);
    if (r == null) return;
    final hosp = monitoreo || r['tipo'] == 'Monitoreo hospitalario';
    s.indicarExamen(v.id, r['nombre']!, hosp ? 'hospitalario' : 'urgencias');
  }

  // ---------- Medicamentos ----------
  Widget _meds(BuildContext c, Visita v) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _soloLectura(),
          if (_medico) _boton('Indicar medicamento', () => _indicarMed(c, v)),
          if (v.medicamentos.isEmpty)
            const Padding(
                padding: EdgeInsets.all(12),
                child: Text('No hay medicamentos indicados.')),
          for (final m in v.medicamentos) _medCard(v, m),
        ],
      );

  Widget _medCard(Visita v, Medicamento m) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(m.nombre,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            Text('${m.cantidad} · cada ${m.cadaHoras} h'),
            const Divider(),
            for (var i = 0; i < m.tomas.length; i++) _tomaFila(v, m, i),
          ]),
        ),
      );

  Widget _tomaFila(Visita v, Medicamento m, int i) {
    final t = m.tomas[i];
    final hecha = t.administrada != null;
    final atrasada = !hecha && t.hora.isBefore(DateTime.now());
    final color = hecha
        ? Colors.green.shade700
        : atrasada
            ? Colors.red.shade700
            : Colors.blueGrey;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(children: [
        SizedBox(
            width: 90,
            child: Text(horaCorta(t.hora),
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(
          child: Text(
              hecha
                  ? 'Administrada ${horaCorta(t.administrada!)} · ${t.por ?? ''}'
                  : atrasada
                      ? 'Atrasada'
                      : 'Pendiente',
              style: TextStyle(color: color)),
        ),
        if (_personal && !hecha)
          TextButton(
              onPressed: () => s.marcarToma(v.id, m.id, i),
              child: const Text('Marcar administrada')),
      ]),
    );
  }

  Future<void> _indicarMed(BuildContext c, Visita v) async {
    final r = await pedirCampos(c, 'Indicar medicamento', const [
      Campo('nombre', 'Medicamento (ej. Acetaminofén)'),
      Campo('cantidad', 'Dosis (ej. 500 mg)'),
      Campo('cada', 'Cada cuántas horas', opciones: ['4', '6', '8', '12']),
      Campo('n', 'Número de tomas',
          opciones: ['1', '2', '3', '4', '5', '6'], inicial: '3'),
    ]);
    if (r == null) return;
    s.indicarMedicamento(v.id, r['nombre']!, r['cantidad']!,
        int.parse(r['cada']!), int.parse(r['n']!));
  }

  // ---------- Hospitalización ----------
  Widget _hosp(BuildContext c, Visita v) {
    final h = v.hosp;
    if (h == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Este paciente no tiene orden de hospitalización.'),
        if (_medico)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _boton('Hospitalizar paciente', () => _hospitalizar(c, v)),
          ),
      ]);
    }
    final monitoreo = v.examenes.where((e) => e.tipo == 'hospitalario').toList();
    return ListView(padding: const EdgeInsets.all(16), children: [
      _soloLectura(),
      _tarjeta('Ubicación y horarios', [
        Text('Habitación ${h.habitacion} · Piso ${h.piso} · Ala ${h.ala}'),
        Text('Horario de visitas: ${h.horarioVisitas}'),
        Text('Horario de comidas: ${h.horarioComidas}'),
        Text('Hospitalizado desde ${horaCorta(h.desde)}'),
      ]),
      _tarjeta('Visitas de médicos y enfermeros', [
        if (h.visitas.isEmpty) const Text('Sin visitas registradas.'),
        for (final x in h.visitas.reversed)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text('${horaCorta(x.fecha)} · ${x.quien}: ${x.nota}'),
          ),
        if (_personal)
          OutlinedButton(
            onPressed: () async {
              final r = await pedirCampos(c, 'Registrar visita',
                  const [Campo('nota', 'Observación', lineas: 3)]);
              if (r != null) s.registrarVisitaClinica(v.id, r['nota']!);
            },
            child: const Text('Registrar visita'),
          ),
      ]),
      _tarjeta('Exámenes de monitoreo', [
        if (monitoreo.isEmpty) const Text('Sin exámenes de monitoreo.'),
        for (final e in monitoreo) _examenTile(v, e),
        if (_medico)
          OutlinedButton(
              onPressed: () => _indicarExamen(c, v, monitoreo: true),
              child: const Text('Indicar examen de monitoreo')),
      ]),
    ]);
  }

  Future<void> _hospitalizar(BuildContext c, Visita v) async {
    final r = await pedirCampos(c, 'Hospitalizar paciente', const [
      Campo('hab', 'Habitación'),
      Campo('piso', 'Piso'),
      Campo('ala', 'Ala'),
      Campo('hv', 'Horario de visitas', inicial: '10:00-12:00 y 16:00-18:00'),
      Campo('hc', 'Horario de comidas', inicial: '7:00, 12:00 y 18:00'),
    ]);
    if (r == null) return;
    s.hospitalizar(v.id, r['hab']!, r['piso']!, r['ala']!, r['hv']!, r['hc']!);
  }
}
