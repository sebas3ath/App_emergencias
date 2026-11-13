import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

class Config {
  static const medicoCorreo = 'medico1@gmail.com';
  static const medicoClave = '123456';
  static const medicoNombre = 'Dr. Médico 1';
  static const enfermeriaCorreo = 'enfermeria1@gmail.com';
  static const enfermeriaClave = '123456';
  static const enfermeriaNombre = 'Enfermera 1';
  static const avisoSeg = 300; // 5 min
  static const maxSeg = 420; // 7 min
}

class AlertaEvento {
  final int minutos; // 5 o 7
  final Visita visita;
  AlertaEvento(this.minutos, this.visita);
}

/// Estado global de la demo. Guarda todo en el dispositivo (shared_preferences).
/// En la app real esto se reemplaza por un backend (p. ej. Firebase).
class Store extends ChangeNotifier {
  Store._();
  static final Store instance = Store._();
  static const _k = 'urg_demo_v3';

  final List<Paciente> pacientes = [];
  final List<Visita> visitas = [];
  bool rapido = false; // 1 min = 6 s
  String? cedulaSesion;
  Rol? rol; // null = paciente (solo lectura)
  bool get esMedico => rol == Rol.medico;
  bool get esPersonal => rol != null;

  SharedPreferences? _prefs;
  final _ctrl = StreamController<AlertaEvento>.broadcast();
  Stream<AlertaEvento> get alertas => _ctrl.stream;

  double get escala => rapido ? 10 : 1;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_k);
    if (raw != null) {
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        pacientes
          ..clear()
          ..addAll((m['pacientes'] as List)
              .map((e) => Paciente.fromJson(e as Map<String, dynamic>)));
        visitas
          ..clear()
          ..addAll((m['visitas'] as List)
              .map((e) => Visita.fromJson(e as Map<String, dynamic>)));
        rapido = m['rapido'] == true;
      } catch (_) {}
    }
    Timer.periodic(const Duration(seconds: 1), (_) {
      _revisarAlertas();
      notifyListeners();
    });
  }

  void _guardar() {
    _prefs?.setString(
        _k,
        jsonEncode({
          'pacientes': pacientes.map((e) => e.toJson()).toList(),
          'visitas': visitas.map((e) => e.toJson()).toList(),
          'rapido': rapido,
        }));
  }

  // ---------- Tiempo ----------
  double segundos(DateTime a, [DateTime? b]) =>
      (b ?? DateTime.now()).difference(a).inMilliseconds / 1000 * escala;

  double espera(Visita v) =>
      segundos(v.llegada, v.atencion ?? v.salida);

  Estado estado(Visita v) {
    if (v.salida != null) return Estado.salio;
    if (v.atencion != null) return Estado.enAtencion;
    final e = segundos(v.llegada);
    if (e >= Config.maxSeg) return Estado.alerta;
    if (e >= Config.avisoSeg) return Estado.aviso;
    return Estado.esperando;
  }

  void _revisarAlertas() {
    var cambio = false;
    for (final v in visitas) {
      if (v.atencion != null || v.salida != null) continue;
      final e = segundos(v.llegada);
      if (e >= Config.avisoSeg && !v.a5) {
        v.a5 = true;
        cambio = true;
        _ctrl.add(AlertaEvento(5, v));
      }
      if (e >= Config.maxSeg && !v.a7) {
        v.a7 = true;
        cambio = true;
        _ctrl.add(AlertaEvento(7, v));
      }
    }
    if (cambio) _guardar();
  }

  void setRapido(bool v) {
    rapido = v;
    _guardar();
    notifyListeners();
  }

  // ---------- Pacientes ----------
  Paciente? paciente(String cedula) {
    for (final p in pacientes) {
      if (p.cedula == cedula) return p;
    }
    return null;
  }

  Visita? visitaActiva(String cedula) {
    for (final v in visitas.reversed) {
      if (v.cedula == cedula && v.salida == null) return v;
    }
    return null;
  }

  Visita? ultimaVisita(String cedula) {
    for (final v in visitas.reversed) {
      if (v.cedula == cedula) return v;
    }
    return null;
  }

  void _nuevaVisita(String cedula) {
    visitas.add(Visita(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      cedula: cedula,
      medico: Config.medicoNombre,
      llegada: DateTime.now(), // hora de llegada
    ));
  }

  /// Devuelve un mensaje de error o null si todo salió bien.
  String? registrar(Paciente p) {
    rol = null;
    if (paciente(p.cedula) != null) {
      return 'Esa cédula ya está registrada. Usa "Ingresar con cédula".';
    }
    pacientes.add(p);
    _nuevaVisita(p.cedula);
    cedulaSesion = p.cedula;
    _guardar();
    notifyListeners();
    return null;
  }

  /// Ingreso solo con cédula. Si no tiene una visita abierta, se crea una nueva
  /// y se registra la hora de llegada.
  String? ingresar(String cedula) {
    rol = null;
    if (paciente(cedula) == null) {
      return 'No encontramos esa cédula. Primero regístrate.';
    }
    if (visitaActiva(cedula) == null) _nuevaVisita(cedula);
    cedulaSesion = cedula;
    _guardar();
    notifyListeners();
    return null;
  }

  void registrarSalida(String id) {
    final v = visitas.firstWhere((x) => x.id == id);
    v.salida = DateTime.now();
    _guardar();
    notifyListeners();
  }

  void calificar(String id, Calificacion c) {
    visitas.firstWhere((x) => x.id == id).cal = c;
    _guardar();
    notifyListeners();
  }

  void cerrarSesion() {
    cedulaSesion = null;
    rol = null;
    notifyListeners();
  }

  // ---------- Personal de salud ----------
  /// Devuelve el rol si las credenciales son correctas, o null.
  Rol? loginPersonal(String correo, String clave) {
    final c = correo.trim().toLowerCase();
    Rol? r;
    if (c == Config.medicoCorreo && clave == Config.medicoClave) {
      r = Rol.medico;
    } else if (c == Config.enfermeriaCorreo && clave == Config.enfermeriaClave) {
      r = Rol.enfermeria;
    }
    rol = r;
    cedulaSesion = null;
    notifyListeners();
    return r;
  }

  void iniciarAtencion(String id) {
    if (!esMedico) return;
    visitas.firstWhere((x) => x.id == id).atencion = DateTime.now();
    _guardar();
    notifyListeners();
  }

  void reiniciarDemo() {
    pacientes.clear();
    visitas.clear();
    cedulaSesion = null;
    _guardar();
    notifyListeners();
  }


  // ---------- Expediente clínico ----------
  // Solo el personal de salud escribe; el paciente (rol == null) nunca puede
  // modificar nada: cada método valida el rol antes de guardar.
  int _n = 0;
  String _id() => '${DateTime.now().microsecondsSinceEpoch}${_n++}';
  String get _quien =>
      rol == Rol.medico ? Config.medicoNombre : Config.enfermeriaNombre;

  Visita? visita(String id) {
    for (final v in visitas) {
      if (v.id == id) return v;
    }
    return null;
  }

  void _cambio() {
    _guardar();
    notifyListeners();
  }

  void guardarTriaje(String id, String texto) {
    final v = visita(id);
    if (!esMedico || v == null) return;
    v.triaje = NotaClinica(texto, _quien, DateTime.now());
    _cambio();
  }

  void guardarNotaAtencion(String id, String texto) {
    final v = visita(id);
    if (!esMedico || v == null) return;
    v.notaAtencion = NotaClinica(texto, _quien, DateTime.now());
    _cambio();
  }

  void indicarExamen(String id, String nombre, String tipo) {
    final v = visita(id);
    if (!esMedico || v == null) return;
    v.examenes.add(Examen(
        id: _id(), nombre: nombre, tipo: tipo, indicado: DateTime.now()));
    _cambio();
  }

  void marcarExamen(String vId, String eId) {
    final v = visita(vId);
    if (!esPersonal || v == null) return;
    for (final e in v.examenes) {
      if (e.id == eId && e.realizado == null) {
        e.realizado = DateTime.now();
        e.realizadoPor = _quien;
      }
    }
    _cambio();
  }

  void indicarMedicamento(
      String id, String nombre, String cantidad, int cadaHoras, int nTomas) {
    final v = visita(id);
    if (!esMedico || v == null) return;
    final ahora = DateTime.now();
    v.medicamentos.add(Medicamento(
      id: _id(),
      nombre: nombre,
      cantidad: cantidad,
      cadaHoras: cadaHoras,
      tomas: List.generate(
          nTomas, (i) => Toma(ahora.add(Duration(hours: cadaHoras * i)))),
    ));
    _cambio();
  }

  void marcarToma(String vId, String mId, int indice) {
    final v = visita(vId);
    if (!esPersonal || v == null) return;
    for (final m in v.medicamentos) {
      if (m.id == mId && indice >= 0 && indice < m.tomas.length) {
        final t = m.tomas[indice];
        if (t.administrada == null) {
          t.administrada = DateTime.now();
          t.por = _quien;
        }
      }
    }
    _cambio();
  }

  void hospitalizar(String id, String habitacion, String piso, String ala,
      String horarioVisitas, String horarioComidas) {
    final v = visita(id);
    if (!esMedico || v == null || v.hosp != null) return;
    v.hosp = Hospitalizacion(
      habitacion: habitacion,
      piso: piso,
      ala: ala,
      horarioVisitas: horarioVisitas,
      horarioComidas: horarioComidas,
      desde: DateTime.now(),
    );
    _cambio();
  }

  void registrarVisitaClinica(String id, String nota) {
    final h = visita(id)?.hosp;
    if (!esPersonal || h == null) return;
    h.visitas.add(Seguimiento(
        DateTime.now(), rol == Rol.medico ? 'Médico' : 'Enfermería', nota));
    _cambio();
  }

  // ---------- Indicadores ----------
  double get esperaPromedio {
    final l = visitas.where((v) => v.atencion != null).toList();
    if (l.isEmpty) return 0;
    return l.map(espera).reduce((a, b) => a + b) / l.length;
  }

  int get excedidos => visitas.where((v) => v.a7).length;

  List<Visita> get criticas => visitas
      .where((v) =>
          v.atencion == null &&
          v.salida == null &&
          segundos(v.llegada) >= Config.maxSeg)
      .toList();

  List<Visita> get calificadas => visitas.where((v) => v.cal != null).toList();

  double get calPromedio {
    final l = calificadas;
    if (l.isEmpty) return 0;
    return l.map((v) => v.cal!.estrellas).reduce((a, b) => a + b) / l.length;
  }

  MapEntry<String, int>? get aspectoTop {
    final m = <String, int>{};
    for (final v in calificadas) {
      final a = v.cal!.aspecto;
      if (a.isNotEmpty) m[a] = (m[a] ?? 0) + 1;
    }
    if (m.isEmpty) return null;
    final l = m.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return l.first;
  }
}
