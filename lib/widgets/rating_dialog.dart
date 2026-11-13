import 'package:flutter/material.dart';
import '../models.dart';

class RatingDialog extends StatefulWidget {
  const RatingDialog({super.key});
  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _est = 0;
  String? _aspecto;
  final _com = TextEditingController();
  static const _aspectos = [
    'Tiempo de espera',
    'Trato del personal',
    'Información recibida',
    'Limpieza y comodidad',
    'Rapidez del examen o tratamiento',
    'Nada, todo bien',
  ];

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: const Text('¿Cómo fue tu experiencia?'),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                  5,
                  (i) => IconButton(
                        tooltip: '${i + 1} estrellas',
                        iconSize: 36,
                        icon: Icon(i < _est ? Icons.star : Icons.star_border,
                            color: Colors.amber.shade700),
                        onPressed: () => setState(() => _est = i + 1),
                      )),
            ),
            DropdownButtonFormField<String>(
              value: _aspecto,
              isExpanded: true,
              decoration: const InputDecoration(
                  labelText: '¿Qué debemos mejorar?',
                  border: OutlineInputBorder()),
              items: _aspectos
                  .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                  .toList(),
              onChanged: (v) => setState(() => _aspecto = v),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _com,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Comentarios (opcional)',
                  border: OutlineInputBorder()),
            ),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Omitir')),
          FilledButton(
            onPressed: _est == 0
                ? null
                : () => Navigator.pop(context,
                    Calificacion(_est, _aspecto ?? '', _com.text.trim())),
            child: const Text('Enviar calificación'),
          ),
        ],
      );
}
