enum Rol { medico, enfermeria }

enum Estado { esperando, aviso, alerta, enAtencion, salio }

class Paciente {
  final String cedula, nombres, apellidos, correo, telefono, sangre;
  const Paciente({
    required this.cedula,
    required this.nombres,
    required this.apellidos,
    required this.correo,
    required this.telefono,
    required this.sangre,
  });

  String get nombreCompleto => '$nombres $apellidos';

  Map<String, dynamic> toJson() => {
        'cedula': cedula,
        'nombres': nombres,
        'apellidos': apellidos,
        'correo': correo,
        'telefono': telefono,
        'sangre': sangre,
      };

  factory Paciente.fromJson(Map<String, dynamic> j) => Paciente(
        cedula: j['cedula'],
        nombres: j['nombres'],
        apellidos: j['apellidos'],
        correo: j['correo'],
        telefono: j['telefono'],
        sangre: j['sangre'],
      );
}

class Calificacion {
  final int estrellas;
  final String aspecto;
  final String comentario;
  const Calificacion(this.estrellas, this.aspecto, this.comentario);

  Map<String, dynamic> toJson() =>
      {'e': estrellas, 'a': aspecto, 'c': comentario};
  factory Calificacion.fromJson(Map<String, dynamic> j) =>
      Calificacion(j['e'], j['a'], j['c']);
}

/// Nota de historia clínica (triaje o atención médica).
class NotaClinica {
  final String texto, por;
  final DateTime fecha;
  const NotaClinica(this.texto, this.por, this.fecha);

  Map<String, dynamic> toJson() =>
      {'t': texto, 'p': por, 'f': fecha.toIso8601String()};
  factory NotaClinica.fromJson(Map<String, dynamic> j) =>
      NotaClinica(j['t'], j['p'], DateTime.parse(j['f']));
}

/// Examen indicado por el médico. tipo: 'urgencias' | 'hospitalario'.
class Examen {
  final String id, nombre, tipo;
  final DateTime indicado;
  DateTime? realizado;
  String? realizadoPor;

  Examen({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.indicado,
    this.realizado,
    this.realizadoPor,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'tipo': tipo,
        'indicado': indicado.toIso8601String(),
        'realizado': realizado?.toIso8601String(),
        'por': realizadoPor,
      };

  factory Examen.fromJson(Map<String, dynamic> j) => Examen(
        id: j['id'],
        nombre: j['nombre'],
        tipo: j['tipo'],
        indicado: DateTime.parse(j['indicado']),
        realizado: j['realizado'] == null ? null : DateTime.parse(j['realizado']),
        realizadoPor: j['por'],
      );
}

/// Una toma programada de un medicamento.
class Toma {
  final DateTime hora;
  DateTime? administrada;
  String? por;

  Toma(this.hora, {this.administrada, this.por});

  Map<String, dynamic> toJson() => {
        'h': hora.toIso8601String(),
        'a': administrada?.toIso8601String(),
        'p': por,
      };

  factory Toma.fromJson(Map<String, dynamic> j) => Toma(
        DateTime.parse(j['h']),
        administrada: j['a'] == null ? null : DateTime.parse(j['a']),
        por: j['p'],
      );
}

class Medicamento {
  final String id, nombre, cantidad;
  final int cadaHoras;
  final List<Toma> tomas;

  Medicamento({
    required this.id,
    required this.nombre,
    required this.cantidad,
    required this.cadaHoras,
    required this.tomas,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'cantidad': cantidad,
        'cada': cadaHoras,
        'tomas': tomas.map((t) => t.toJson()).toList(),
      };

  factory Medicamento.fromJson(Map<String, dynamic> j) => Medicamento(
        id: j['id'],
        nombre: j['nombre'],
        cantidad: j['cantidad'],
        cadaHoras: j['cada'],
        tomas: (j['tomas'] as List)
            .map((e) => Toma.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Visita de un médico o enfermero durante la hospitalización.
class Seguimiento {
  final DateTime fecha;
  final String quien, nota;
  const Seguimiento(this.fecha, this.quien, this.nota);

  Map<String, dynamic> toJson() =>
      {'f': fecha.toIso8601String(), 'q': quien, 'n': nota};
  factory Seguimiento.fromJson(Map<String, dynamic> j) =>
      Seguimiento(DateTime.parse(j['f']), j['q'], j['n']);
}

class Hospitalizacion {
  final String habitacion, piso, ala, horarioVisitas, horarioComidas;
  final DateTime desde;
  final List<Seguimiento> visitas;

  Hospitalizacion({
    required this.habitacion,
    required this.piso,
    required this.ala,
    required this.horarioVisitas,
    required this.horarioComidas,
    required this.desde,
    List<Seguimiento>? visitas,
  }) : visitas = visitas ?? [];

  Map<String, dynamic> toJson() => {
        'hab': habitacion,
        'piso': piso,
        'ala': ala,
        'hv': horarioVisitas,
        'hc': horarioComidas,
        'desde': desde.toIso8601String(),
        'visitas': visitas.map((v) => v.toJson()).toList(),
      };

  factory Hospitalizacion.fromJson(Map<String, dynamic> j) => Hospitalizacion(
        habitacion: j['hab'],
        piso: j['piso'],
        ala: j['ala'],
        horarioVisitas: j['hv'],
        horarioComidas: j['hc'],
        desde: DateTime.parse(j['desde']),
        visitas: ((j['visitas'] as List?) ?? [])
            .map((e) => Seguimiento.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// Una visita = un ingreso a urgencias (llegada -> salida).
class Visita {
  final String id, cedula, medico;
  final DateTime llegada;
  DateTime? atencion, salida;
  bool a5, a7;
  Calificacion? cal;
  NotaClinica? triaje, notaAtencion;
  final List<Examen> examenes;
  final List<Medicamento> medicamentos;
  Hospitalizacion? hosp;

  Visita({
    required this.id,
    required this.cedula,
    required this.medico,
    required this.llegada,
    this.atencion,
    this.salida,
    this.a5 = false,
    this.a7 = false,
    this.cal,
    this.triaje,
    this.notaAtencion,
    List<Examen>? examenes,
    List<Medicamento>? medicamentos,
    this.hosp,
  })  : examenes = examenes ?? [],
        medicamentos = medicamentos ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'cedula': cedula,
        'medico': medico,
        'llegada': llegada.toIso8601String(),
        'atencion': atencion?.toIso8601String(),
        'salida': salida?.toIso8601String(),
        'a5': a5,
        'a7': a7,
        'cal': cal?.toJson(),
        'triaje': triaje?.toJson(),
        'notaAtencion': notaAtencion?.toJson(),
        'examenes': examenes.map((e) => e.toJson()).toList(),
        'meds': medicamentos.map((m) => m.toJson()).toList(),
        'hosp': hosp?.toJson(),
      };

  factory Visita.fromJson(Map<String, dynamic> j) => Visita(
        id: j['id'],
        cedula: j['cedula'],
        medico: j['medico'],
        llegada: DateTime.parse(j['llegada']),
        atencion: j['atencion'] == null ? null : DateTime.parse(j['atencion']),
        salida: j['salida'] == null ? null : DateTime.parse(j['salida']),
        a5: j['a5'] == true,
        a7: j['a7'] == true,
        cal: j['cal'] == null
            ? null
            : Calificacion.fromJson(j['cal'] as Map<String, dynamic>),
        triaje: j['triaje'] == null
            ? null
            : NotaClinica.fromJson(j['triaje'] as Map<String, dynamic>),
        notaAtencion: j['notaAtencion'] == null
            ? null
            : NotaClinica.fromJson(j['notaAtencion'] as Map<String, dynamic>),
        examenes: ((j['examenes'] as List?) ?? [])
            .map((e) => Examen.fromJson(e as Map<String, dynamic>))
            .toList(),
        medicamentos: ((j['meds'] as List?) ?? [])
            .map((e) => Medicamento.fromJson(e as Map<String, dynamic>))
            .toList(),
        hosp: j['hosp'] == null
            ? null
            : Hospitalizacion.fromJson(j['hosp'] as Map<String, dynamic>),
      );
}
