import 'package:flutter/material.dart';
import 'models.dart';

String fmt(double seg) {
  final s = seg < 0 ? 0 : seg.floor();
  return '${(s ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';
}

String hora(DateTime? d) => d == null
    ? '-'
    : '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:${d.second.toString().padLeft(2, '0')}';

Color colorEstado(Estado e) {
  switch (e) {
    case Estado.esperando:
      return Colors.blueGrey;
    case Estado.aviso:
      return Colors.orange.shade800;
    case Estado.alerta:
      return Colors.red.shade700;
    case Estado.enAtencion:
      return Colors.green.shade700;
    case Estado.salio:
      return Colors.grey;
  }
}

String textoEstado(Estado e) {
  switch (e) {
    case Estado.esperando:
      return 'Esperando';
    case Estado.aviso:
      return 'Aviso: más de 5 min';
    case Estado.alerta:
      return 'Alerta: más de 7 min';
    case Estado.enAtencion:
      return 'En atención';
    case Estado.salio:
      return 'Salió';
  }
}

class EstadoChip extends StatelessWidget {
  final Estado estado;
  const EstadoChip(this.estado, {super.key});
  @override
  Widget build(BuildContext context) {
    final c = colorEstado(estado);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
          color: c.withAlpha(35), borderRadius: BorderRadius.circular(99)),
      child: Text(textoEstado(estado),
          style: TextStyle(color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class Aviso extends StatelessWidget {
  final String texto;
  final Color color;
  const Aviso(this.texto, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withAlpha(30),
          border: Border(left: BorderSide(color: color, width: 5)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(texto,
            style: TextStyle(color: color, fontWeight: FontWeight.bold)),
      );
}

String horaCorta(DateTime d) {
  final n = DateTime.now();
  final hm =
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  if (d.year == n.year && d.month == n.month && d.day == n.day) return hm;
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} $hm';
}

class Etiqueta extends StatelessWidget {
  final String texto;
  final Color color;
  const Etiqueta(this.texto, this.color, {super.key});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
            color: color.withAlpha(35), borderRadius: BorderRadius.circular(99)),
        child: Text(texto,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      );
}
