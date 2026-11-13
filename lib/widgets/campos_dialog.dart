import 'package:flutter/material.dart';

/// Campo de un formulario sencillo: texto libre o lista de opciones.
class Campo {
  final String key, label, inicial;
  final List<String>? opciones;
  final int lineas;
  const Campo(this.key, this.label,
      {this.opciones, this.lineas = 1, this.inicial = ''});
}

/// Muestra un formulario y devuelve los valores por clave, o null si se cancela.
Future<Map<String, String>?> pedirCampos(
        BuildContext context, String titulo, List<Campo> campos) =>
    showDialog<Map<String, String>>(
        context: context, builder: (_) => _CamposDialog(titulo, campos));

class _CamposDialog extends StatefulWidget {
  final String titulo;
  final List<Campo> campos;
  const _CamposDialog(this.titulo, this.campos);
  @override
  State<_CamposDialog> createState() => _CamposDialogState();
}

class _CamposDialogState extends State<_CamposDialog> {
  final Map<String, TextEditingController> _ctl = {};
  final Map<String, String> _sel = {};
  String? _err;

  @override
  void initState() {
    super.initState();
    for (final c in widget.campos) {
      final o = c.opciones;
      if (o == null) {
        _ctl[c.key] = TextEditingController(text: c.inicial);
      } else {
        _sel[c.key] = o.contains(c.inicial) ? c.inicial : o.first;
      }
    }
  }

  @override
  void dispose() {
    for (final t in _ctl.values) {
      t.dispose();
    }
    super.dispose();
  }

  void _enviar() {
    final r = <String, String>{};
    for (final c in widget.campos) {
      final v = c.opciones == null ? _ctl[c.key]!.text.trim() : _sel[c.key]!;
      if (v.isEmpty) {
        setState(() => _err = 'Completa todos los campos.');
        return;
      }
      r[c.key] = v;
    }
    Navigator.pop(context, r);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(widget.titulo),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final c in widget.campos)
              Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: c.opciones == null
                    ? TextField(
                        controller: _ctl[c.key],
                        minLines: c.lineas,
                        maxLines: c.lineas,
                        decoration: InputDecoration(
                            labelText: c.label,
                            border: const OutlineInputBorder()),
                      )
                    : DropdownButtonFormField<String>(
                        value: _sel[c.key],
                        isExpanded: true,
                        decoration: InputDecoration(
                            labelText: c.label,
                            border: const OutlineInputBorder()),
                        items: c.opciones!
                            .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _sel[c.key] = v ?? _sel[c.key]!),
                      ),
              ),
            if (_err != null)
              Text(_err!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ]),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          FilledButton(onPressed: _enviar, child: const Text('Guardar')),
        ],
      );
}
