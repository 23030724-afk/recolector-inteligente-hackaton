# Recolector Inteligente API

Backend completo para el prototipo del hackathon. Incluye autenticación JWT, roles, rutas, domicilios, reportes, alertas operativas, operador y administrador.

## Roles incluidos

- **Ciudadano**: registra domicilios, consulta ETA, ve alertas de su ruta, manda reportes y califica.
- **Operador**: ve sus rutas asignadas, inicia jornada, avanza positionId, reporta retrasos, averías e incidencias.
- **Administrador**: ve dashboard logístico, reportes, alertas, rutas, operadores y asigna operadores a rutas.

## Instalación

Desde la carpeta `recolector_backend`:

```bash
python -m venv .venv
```

Windows PowerShell:

```bash
.venv\Scripts\Activate.ps1
```

Mac/Linux:

```bash
source .venv/bin/activate
```

Instalar dependencias:

```bash
pip install -r requirements.txt
```

Copiar variables de entorno:

```bash
copy .env.example .env
```

En Mac/Linux:

```bash
cp .env.example .env
```

Correr servidor:

```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Abrir documentación interactiva:

```text
http://127.0.0.1:8000/docs
```

## Cuentas demo

```text
Ciudadano:
demo@correo.com
123456

Operador:
operador@demo.com
123456

Operador 2:
operador2@demo.com
123456

Administrador:
admin@demo.com
123456
```

## Flujo rápido de prueba en /docs

1. `POST /auth/login` con `admin@demo.com` o el rol que quieras.
2. Copia el `access_token`.
3. Presiona **Authorize** arriba a la derecha.
4. Escribe: `Bearer TU_TOKEN`.
5. Prueba endpoints según rol.

## Endpoints principales

### Auth

```text
POST /auth/login
POST /auth/register
GET  /auth/me
```

### Público

```text
GET /public/health
GET /public/colonias
GET /public/routes
GET /public/guide
```

### Ciudadano

```text
GET  /citizen/domicilios
POST /citizen/domicilios
GET  /citizen/domicilios/{domicilio_id}/eta
GET  /citizen/alerts
POST /citizen/reports
POST /citizen/ratings
```

Ejemplo para crear domicilio:

```json
{
  "tipo": "Casa principal",
  "direccion": "Calle Luna 123",
  "colonia": "Zona Centro",
  "lat": 20.521,
  "lng": -100.821
}
```

### Operador

```text
GET  /operator/routes
GET  /operator/routes/{route_id}
GET  /operator/alerts
POST /operator/routes/{route_id}/start
POST /operator/routes/{route_id}/advance/{position_id}
POST /operator/routes/{route_id}/delay
POST /operator/routes/{route_id}/breakdown
POST /operator/routes/{route_id}/incident
POST /operator/routes/{route_id}/complete
```

### Administrador

```text
GET   /admin/dashboard
GET   /admin/users
GET   /admin/operators
GET   /admin/routes
POST  /admin/routes/{route_id}/assign-operator
GET   /admin/alerts
PATCH /admin/alerts/{alert_id}/close
GET   /admin/reports
PATCH /admin/reports/{report_id}/status
```

## Simulador de ruta

En otra terminal, con el servidor corriendo:

```bash
python -m app.simulator RUTA-01
```

Esto actualiza `positionId` y genera alertas automáticamente.

## Cómo conectar Flutter

Agrega `http`:

```bash
flutter pub add http
```

Ejemplo base:

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

const apiBase = 'http://10.0.2.2:8000'; // Android emulator
// const apiBase = 'http://127.0.0.1:8000'; // Chrome en la misma PC

Future<String> login(String email, String password) async {
  final res = await http.post(
    Uri.parse('$apiBase/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email, 'password': password}),
  );

  if (res.statusCode >= 400) {
    throw Exception(res.body);
  }

  return jsonDecode(res.body)['access_token'];
}
```

## Nota de arquitectura

Este backend usa SQLite para que corra rápido en hackathon. Para producción pueden cambiar `DATABASE_URL` a PostgreSQL/MySQL y conservar la misma API.
