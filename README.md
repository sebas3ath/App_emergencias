# Urgencias en tiempo real (demo Flutter)

## Cómo ejecutarlo
1. Descomprime la carpeta y entra a ella en la terminal.
2. `flutter create . --project-name urgencias_demo`  (genera android/ios/web; conserva lib/ y pubspec.yaml)
3. `flutter pub get`
4. `flutter run`

## Accesos
| Rol | Acceso |
|---|---|
| Paciente | Se registra una vez; luego entra solo con su cédula |
| Médico | `medico1@gmail.com` / `123456` |
| Enfermería | `enfermeria1@gmail.com` / `123456` |

## Permisos
| Acción | Paciente | Enfermería | Médico |
|---|---|---|---|
| Ver historia, exámenes, medicamentos, hospitalización | Sí (solo lectura) | Sí | Sí |
| Registrar triaje y atención | No | No | Sí |
| Indicar exámenes / medicamentos / hospitalizar | No | No | Sí |
| Marcar examen realizado / toma administrada | No | Sí | Sí |
| Registrar visita hospitalaria | No | Sí | Sí |
| Iniciar atención | No | No | Sí |

Los permisos se validan también en `store.dart`, no solo en la interfaz.

## Prueba sugerida
1. Paciente: regístrate (activa "Modo demo rápido" en el inicio).
2. Médico: abre el expediente → registra triaje, atención, un examen, un medicamento y hospitaliza.
3. Enfermería: marca el examen como realizado y una toma como administrada; registra una visita.
4. Paciente: "Ver detalle" → ve todo, sin botones de edición.

## Límites del demo
Los datos se guardan en el mismo dispositivo (shared_preferences). Para producción:
backend (Firebase/API), autenticación real y notificaciones push.
