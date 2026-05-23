import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecolectorApp());
}

// =======================================================
// JSON OFICIALES INTEGRADOS LOCALMENTE
// =======================================================

const String notificacionesJson = '''
[
  {
    "triggerEvent": "ROUTE_START",
    "condition": "Cuando positionId cambia de 1 a 2",
    "pushPayload": {
      "title": "¡Ruta Iniciada!",
      "body": "El camión recolector ha salido del Relleno Sanitario rumbo a tu sector. Asegúrate de tener listos tus residuos."
    }
  },
  {
    "triggerEvent": "TRUCK_PROXIMITY",
    "condition": "Cuando positionId llega a 4 (punto previo al destino)",
    "pushPayload": {
      "title": "Camión Cercano",
      "body": "El camión está a menos de 15 minutos de tu domicilio. Es momento de sacar tus bolsas a la acera."
    }
  },
  {
    "triggerEvent": "ROUTE_COMPLETED",
    "condition": "Cuando positionId llega a 8 (retorno al basurero)",
    "pushPayload": {
      "title": "Servicio Finalizado",
      "body": "El camión de tu sector ha concluido su jornada de recolección diaria."
    }
  }
]
''';

const String coloniasJson = '''
[
  { "colonia": "Zona Centro", "routeId": "RUTA-01", "horarioEstimado": "Matutino (06:30 - 07:15)" },
  { "colonia": "Las Arboledas", "routeId": "RUTA-01", "horarioEstimado": "Matutino (07:00 - 07:30)" },
  { "colonia": "Trojes", "routeId": "RUTA-13", "horarioEstimado": "Matutino (06:40 - 07:10)" },
  { "colonia": "San Juanico", "routeId": "RUTA-03", "horarioEstimado": "Matutino (06:45 - 07:15)" },
  { "colonia": "Los Olivos", "routeId": "RUTA-04", "horarioEstimado": "Matutino (07:00 - 07:40)" },
  { "colonia": "Rancho Seco", "routeId": "RUTA-05", "horarioEstimado": "Vespertino (14:15 - 15:00)" },
  { "colonia": "Las Insurgentes", "routeId": "RUTA-12", "horarioEstimado": "Matutino (06:35 - 07:10)" }
]
''';

const String rutasJson = '''
[
  {
    "routeId": "RUTA-01",
    "name": "Zona Centro - Las Arboledas",
    "truckId": 101,
    "status": "EN_RUTA",
    "positions": [
      { "positionId": 1, "lat": 20.5111, "lng": -100.9037, "speed": 0, "timestamp": "2026-05-22T06:00:00Z" },
      { "positionId": 2, "lat": 20.5185, "lng": -100.8450, "speed": 45, "timestamp": "2026-05-22T06:12:00Z" },
      { "positionId": 3, "lat": 20.5215, "lng": -100.8142, "speed": 22, "timestamp": "2026-05-22T06:25:00Z" },
      { "positionId": 4, "lat": 20.5212, "lng": -100.8175, "speed": 15, "timestamp": "2026-05-22T06:38:00Z" },
      { "positionId": 5, "lat": 20.5210, "lng": -100.8210, "speed": 0, "timestamp": "2026-05-22T06:50:00Z" },
      { "positionId": 6, "lat": 20.5235, "lng": -100.8212, "speed": 18, "timestamp": "2026-05-22T07:05:00Z" },
      { "positionId": 7, "lat": 20.5260, "lng": -100.8215, "speed": 20, "timestamp": "2026-05-22T07:18:00Z" },
      { "positionId": 8, "lat": 20.5111, "lng": -100.9037, "speed": 40, "timestamp": "2026-05-22T07:40:00Z" }
    ]
  },
  {
    "routeId": "RUTA-03",
    "name": "Sector Poniente - San Juanico",
    "truckId": 103,
    "status": "EN_RUTA",
    "positions": [
      { "positionId": 1, "lat": 20.5111, "lng": -100.9037, "speed": 0, "timestamp": "2026-05-22T06:10:00Z" },
      { "positionId": 2, "lat": 20.5250, "lng": -100.8510, "speed": 42, "timestamp": "2026-05-22T06:20:00Z" },
      { "positionId": 3, "lat": 20.5290, "lng": -100.8320, "speed": 20, "timestamp": "2026-05-22T06:35:00Z" },
      { "positionId": 4, "lat": 20.5315, "lng": -100.8355, "speed": 15, "timestamp": "2026-05-22T06:48:00Z" },
      { "positionId": 5, "lat": 20.5340, "lng": -100.8390, "speed": 0, "timestamp": "2026-05-22T07:00:00Z" },
      { "positionId": 6, "lat": 20.5362, "lng": -100.8425, "speed": 10, "timestamp": "2026-05-22T07:15:00Z" },
      { "positionId": 7, "lat": 20.5330, "lng": -100.8430, "speed": 18, "timestamp": "2026-05-22T07:28:00Z" },
      { "positionId": 8, "lat": 20.5111, "lng": -100.9037, "speed": 35, "timestamp": "2026-05-22T07:45:00Z" }
    ]
  },
  {
    "routeId": "RUTA-04",
    "name": "Oriente - Los Olivos",
    "truckId": 104,
    "status": "EN_RUTA",
    "positions": [
      { "positionId": 1, "lat": 20.5111, "lng": -100.9037, "speed": 0, "timestamp": "2026-05-22T06:15:00Z" },
      { "positionId": 2, "lat": 20.5260, "lng": -100.8010, "speed": 45, "timestamp": "2026-05-22T06:30:00Z" },
      { "positionId": 3, "lat": 20.5295, "lng": -100.7890, "speed": 24, "timestamp": "2026-05-22T06:45:00Z" },
      { "positionId": 4, "lat": 20.5320, "lng": -100.7850, "speed": 12, "timestamp": "2026-05-22T06:58:00Z" },
      { "positionId": 5, "lat": 20.5350, "lng": -100.7790, "speed": 0, "timestamp": "2026-05-22T07:12:00Z" },
      { "positionId": 6, "lat": 20.5310, "lng": -100.7760, "speed": 15, "timestamp": "2026-05-22T07:25:00Z" },
      { "positionId": 7, "lat": 20.5270, "lng": -100.7820, "speed": 26, "timestamp": "2026-05-22T07:38:00Z" },
      { "positionId": 8, "lat": 20.5111, "lng": -100.9037, "speed": 48, "timestamp": "2026-05-22T07:58:00Z" }
    ]
  },
  {
    "routeId": "RUTA-05",
    "name": "Sector Sur - Rancho Seco",
    "truckId": 105,
    "status": "EN_RUTA",
    "positions": [
      { "positionId": 1, "lat": 20.5111, "lng": -100.9037, "speed": 0, "timestamp": "2026-05-22T06:20:00Z" },
      { "positionId": 2, "lat": 20.5050, "lng": -100.8620, "speed": 35, "timestamp": "2026-05-22T06:32:00Z" },
      { "positionId": 3, "lat": 20.5020, "lng": -100.8350, "speed": 22, "timestamp": "2026-05-22T06:45:00Z" },
      { "positionId": 4, "lat": 20.4995, "lng": -100.8210, "speed": 14, "timestamp": "2026-05-22T06:58:00Z" },
      { "positionId": 5, "lat": 20.4970, "lng": -100.8150, "speed": 0, "timestamp": "2026-05-22T07:10:00Z" },
      { "positionId": 6, "lat": 20.5010, "lng": -100.8120, "speed": 16, "timestamp": "2026-05-22T07:22:00Z" },
      { "positionId": 7, "lat": 20.5060, "lng": -100.8160, "speed": 25, "timestamp": "2026-05-22T07:35:00Z" },
      { "positionId": 8, "lat": 20.5111, "lng": -100.9037, "speed": 40, "timestamp": "2026-05-22T07:55:00Z" }
    ]
  },
  {
    "routeId": "RUTA-12",
    "name": "Nororiente - Las Insurgentes",
    "truckId": 112,
    "status": "EN_RUTA",
    "positions": [
      { "positionId": 1, "lat": 20.5111, "lng": -100.9037, "speed": 0, "timestamp": "2026-05-22T06:08:00Z" },
      { "positionId": 2, "lat": 20.5280, "lng": -100.8080, "speed": 40, "timestamp": "2026-05-22T06:22:00Z" },
      { "positionId": 3, "lat": 20.5320, "lng": -100.7980, "speed": 24, "timestamp": "2026-05-22T06:35:00Z" },
      { "positionId": 4, "lat": 20.5340, "lng": -100.7940, "speed": 15, "timestamp": "2026-05-22T06:48:00Z" },
      { "positionId": 5, "lat": 20.5360, "lng": -100.7900, "speed": 0, "timestamp": "2026-05-22T07:00:00Z" },
      { "positionId": 6, "lat": 20.5310, "lng": -100.7920, "speed": 12, "timestamp": "2026-05-22T07:12:00Z" },
      { "positionId": 7, "lat": 20.5270, "lng": -100.8020, "speed": 26, "timestamp": "2026-05-22T07:25:00Z" },
      { "positionId": 8, "lat": 20.5111, "lng": -100.9037, "speed": 44, "timestamp": "2026-05-22T07:48:00Z" }
    ]
  },
  {
    "routeId": "RUTA-13",
    "name": "Sector Norte - Trojes e Irrigación",
    "truckId": 113,
    "status": "EN_RUTA",
    "positions": [
      { "positionId": 1, "lat": 20.5111, "lng": -100.9037, "speed": 0, "timestamp": "2026-05-22T06:12:00Z" },
      { "positionId": 2, "lat": 20.5360, "lng": -100.8190, "speed": 35, "timestamp": "2026-05-22T06:26:00Z" },
      { "positionId": 3, "lat": 20.5420, "lng": -100.8080, "speed": 28, "timestamp": "2026-05-22T06:40:00Z" },
      { "positionId": 4, "lat": 20.5440, "lng": -100.8040, "speed": 14, "timestamp": "2026-05-22T06:54:00Z" },
      { "positionId": 5, "lat": 20.5460, "lng": -100.8000, "speed": 0, "timestamp": "2026-05-22T07:06:00Z" },
      { "positionId": 6, "lat": 20.5410, "lng": -100.8020, "speed": 18, "timestamp": "2026-05-22T07:18:00Z" },
      { "positionId": 7, "lat": 20.5370, "lng": -100.8120, "speed": 25, "timestamp": "2026-05-22T07:30:00Z" },
      { "positionId": 8, "lat": 20.5111, "lng": -100.9037, "speed": 39, "timestamp": "2026-05-22T07:54:00Z" }
    ]
  }
]
''';

// =======================================================
// MODELOS
// =======================================================

class NotificacionConfig {
  final String triggerEvent;
  final String condition;
  final String title;
  final String body;

  NotificacionConfig({
    required this.triggerEvent,
    required this.condition,
    required this.title,
    required this.body,
  });

  factory NotificacionConfig.fromJson(Map<String, dynamic> json) {
    final payload = Map<String, dynamic>.from(json['pushPayload'] ?? {});
    return NotificacionConfig(
      triggerEvent: json['triggerEvent'] ?? '',
      condition: json['condition'] ?? '',
      title: payload['title'] ?? '',
      body: payload['body'] ?? '',
    );
  }
}

class ColoniaZona {
  final String colonia;
  final String routeId;
  final String horarioEstimado;

  ColoniaZona({
    required this.colonia,
    required this.routeId,
    required this.horarioEstimado,
  });

  factory ColoniaZona.fromJson(Map<String, dynamic> json) {
    return ColoniaZona(
      colonia: json['colonia'] ?? '',
      routeId: json['routeId'] ?? '',
      horarioEstimado: json['horarioEstimado'] ?? '',
    );
  }
}

class RoutePosition {
  final int positionId;
  final double lat;
  final double lng;
  final int speed;
  final String timestamp;

  RoutePosition({
    required this.positionId,
    required this.lat,
    required this.lng,
    required this.speed,
    required this.timestamp,
  });

  factory RoutePosition.fromJson(Map<String, dynamic> json) {
    return RoutePosition(
      positionId: json['positionId'] ?? 0,
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
      speed: json['speed'] ?? 0,
      timestamp: json['timestamp'] ?? '',
    );
  }
}

class RutaOficial {
  final String routeId;
  final String name;
  final int truckId;
  final String status;
  final List<RoutePosition> positions;

  RutaOficial({
    required this.routeId,
    required this.name,
    required this.truckId,
    required this.status,
    required this.positions,
  });

  factory RutaOficial.fromJson(Map<String, dynamic> json) {
    final rawPositions = json['positions'] as List? ?? [];
    return RutaOficial(
      routeId: json['routeId'] ?? '',
      name: json['name'] ?? '',
      truckId: json['truckId'] ?? 0,
      status: json['status'] ?? '',
      positions: rawPositions
          .map((e) => RoutePosition.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

class Domicilio {
  final String tipo;
  final String direccion;
  final String colonia;
  final double? lat;
  final double? lng;

  Domicilio({
    required this.tipo,
    required this.direccion,
    required this.colonia,
    this.lat,
    this.lng,
  });

  String get etiqueta {
    final dir = direccion.trim();
    final col = colonia.trim();

    if (dir.isEmpty && col.isEmpty) return tipo;
    if (col.isEmpty) return '$tipo: $dir';
    return '$tipo: $dir, $col';
  }

  String get busqueda => '$tipo $direccion $colonia'.toLowerCase();

  Map<String, dynamic> toJson() => {
        'tipo': tipo,
        'direccion': direccion,
        'colonia': colonia,
        'lat': lat,
        'lng': lng,
      };

  factory Domicilio.fromJson(Map<String, dynamic> json) {
    return Domicilio(
      tipo: json['tipo'] ?? 'Domicilio',
      direccion: json['direccion'] ?? '',
      colonia: json['colonia'] ?? '',
      lat: json['lat'] == null ? null : (json['lat'] as num).toDouble(),
      lng: json['lng'] == null ? null : (json['lng'] as num).toDouble(),
    );
  }
}



class UbicacionMapa {
  final LatLng punto;
  final String direccion;
  final String colonia;

  UbicacionMapa({
    required this.punto,
    required this.direccion,
    required this.colonia,
  });
}

class Servicio {
  final String domicilio;
  final int estrellas;
  final String fecha;

  Servicio({
    required this.domicilio,
    required this.estrellas,
    required this.fecha,
  });

  Map<String, dynamic> toJson() => {
        'domicilio': domicilio,
        'estrellas': estrellas,
        'fecha': fecha,
      };

  factory Servicio.fromJson(Map<String, dynamic> json) {
    return Servicio(
      domicilio: json['domicilio'] ?? '',
      estrellas: json['estrellas'] ?? 0,
      fecha: json['fecha'] ?? '',
    );
  }
}


class AlertaOperativa {
  final String id;
  final String tipo;
  final String titulo;
  final String mensaje;
  final String routeId;
  final String rutaNombre;
  final int truckId;
  final String operador;
  final String estado;
  final String fecha;
  final int prioridad;

  AlertaOperativa({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.routeId,
    required this.rutaNombre,
    required this.truckId,
    required this.operador,
    required this.estado,
    required this.fecha,
    required this.prioridad,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'titulo': titulo,
        'mensaje': mensaje,
        'routeId': routeId,
        'rutaNombre': rutaNombre,
        'truckId': truckId,
        'operador': operador,
        'estado': estado,
        'fecha': fecha,
        'prioridad': prioridad,
      };

  factory AlertaOperativa.fromJson(Map<String, dynamic> json) {
    return AlertaOperativa(
      id: json['id'] ?? '',
      tipo: json['tipo'] ?? 'INFO',
      titulo: json['titulo'] ?? '',
      mensaje: json['mensaje'] ?? '',
      routeId: json['routeId'] ?? '',
      rutaNombre: json['rutaNombre'] ?? '',
      truckId: json['truckId'] ?? 0,
      operador: json['operador'] ?? 'Operador',
      estado: json['estado'] ?? 'Nueva',
      fecha: json['fecha'] ?? '',
      prioridad: json['prioridad'] ?? 1,
    );
  }
}

// =======================================================
// REPOSITORIO LOCAL
// =======================================================

class Repo {
  static List<NotificacionConfig> notificaciones() {
    final raw = jsonDecode(notificacionesJson) as List;
    return raw
        .map((e) => NotificacionConfig.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static List<ColoniaZona> colonias() {
    final raw = jsonDecode(coloniasJson) as List;
    return raw.map((e) => ColoniaZona.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static List<RutaOficial> rutas() {
    final raw = jsonDecode(rutasJson) as List;
    return raw.map((e) => RutaOficial.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static String normalizar(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }

  static LatLng centroColonia(String colonia) {
    final key = normalizar(colonia);

    final centros = <String, LatLng>{
      'zona centro': LatLng(20.5210, -100.8210),
      'las arboledas': LatLng(20.5215, -100.8178),
      'trojes': LatLng(20.5440, -100.8040),
      'san juanico': LatLng(20.5315, -100.8355),
      'los olivos': LatLng(20.5320, -100.7850),
      'rancho seco': LatLng(20.4995, -100.8210),
      'las insurgentes': LatLng(20.5340, -100.7940),
    };

    return centros[key] ?? LatLng(20.5210, -100.8210);
  }

  static String coloniaMasCercana(LatLng punto) {
    final distance = Distance();

    String mejorColonia = colonias().first.colonia;
    double menorDistancia = double.infinity;

    for (final c in colonias()) {
      final centro = centroColonia(c.colonia);
      final metros = distance.as(LengthUnit.Meter, punto, centro);

      if (metros < menorDistancia) {
        menorDistancia = metros;
        mejorColonia = c.colonia;
      }
    }

    return mejorColonia;
  }

  static String coloniaOficialDesdeTexto(String texto, LatLng punto) {
    final normal = normalizar(texto);

    for (final c in colonias()) {
      final col = normalizar(c.colonia);
      if (normal.contains(col)) {
        return c.colonia;
      }
    }

    return coloniaMasCercana(punto);
  }


  static String coordenadasTexto(double? lat, double? lng) {
    if (lat == null || lng == null) return 'Ubicación no seleccionada';
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  static ColoniaZona? coloniaDe(Domicilio? domicilio) {
    if (domicilio == null) return null;

    final texto = normalizar(domicilio.busqueda);

    for (final c in colonias()) {
      final col = normalizar(c.colonia);
      if (texto.contains(col)) {
        return c;
      }
    }

    return null;
  }

  static RutaOficial rutaDe(Domicilio? domicilio) {
    final todas = rutas();
    final colonia = coloniaDe(domicilio);

    if (colonia != null) {
      final match = todas.where((r) => r.routeId == colonia.routeId);
      if (match.isNotEmpty) return match.first;
    }

    return todas.first;
  }

  static String horarioDe(Domicilio? domicilio) {
    final colonia = coloniaDe(domicilio);
    return colonia?.horarioEstimado ?? 'Matutino (06:30 - 07:15)';
  }

  static NotificacionConfig? notificacionPorEvento(String trigger) {
    final lista = notificaciones().where((n) => n.triggerEvent == trigger);
    return lista.isEmpty ? null : lista.first;
  }

  static Future<void> guardarUsuario({
    required String nombre,
    required String telefono,
    required String correo,
    required String rfc,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('nombre', nombre);
    await prefs.setString('telefono', telefono);
    await prefs.setString('correo', correo);
    await prefs.setString('rfc', rfc);
  }

  static Future<Map<String, String>> cargarUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'nombre': prefs.getString('nombre') ?? '',
      'telefono': prefs.getString('telefono') ?? '',
      'correo': prefs.getString('correo') ?? '',
      'rfc': prefs.getString('rfc') ?? '',
    };
  }

  static Future<List<Domicilio>> cargarDomicilios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('domicilios_v4');

    if (raw == null || raw.isEmpty) return [];

    final list = jsonDecode(raw) as List;
    return list.map((e) => Domicilio.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> guardarDomicilios(List<Domicilio> domicilios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'domicilios_v4',
      jsonEncode(domicilios.map((e) => e.toJson()).toList()),
    );
  }

  static Future<void> guardarSugerencia(String texto) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sugerencias') ?? '[]';
    final list = jsonDecode(raw) as List;

    list.insert(0, {
      'texto': texto,
      'fecha': DateTime.now().toIso8601String(),
    });

    await prefs.setString('sugerencias', jsonEncode(list.take(20).toList()));
  }

  static Future<void> guardarServicio(Servicio servicio) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('servicios') ?? '[]';
    final list = jsonDecode(raw) as List;

    list.insert(0, servicio.toJson());

    await prefs.setString('servicios', jsonEncode(list.take(10).toList()));
  }

  static Future<List<Servicio>> cargarServicios() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('servicios') ?? '[]';
    final list = jsonDecode(raw) as List;

    return list.map((e) => Servicio.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Future<void> guardarAlertaOperativa(AlertaOperativa alerta) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('alertas_operativas') ?? '[]';
    final list = jsonDecode(raw) as List;

    list.insert(0, alerta.toJson());

    await prefs.setString('alertas_operativas', jsonEncode(list.take(30).toList()));
  }

  static Future<List<AlertaOperativa>> cargarAlertasOperativas() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('alertas_operativas') ?? '[]';
    final list = jsonDecode(raw) as List;

    return list
        .map((e) => AlertaOperativa.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> limpiarAlertasOperativas() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('alertas_operativas');
  }

  static Future<List<Map<String, dynamic>>> cargarSugerencias() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('sugerencias') ?? '[]';
    final list = jsonDecode(raw) as List;

    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static bool emailValido(String value) {
    final text = value.trim();
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(text);
  }

  static bool direccionValida(String value) {
    final text = value.trim();
    final tieneLetras = RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñ]').hasMatch(text);
    final tieneNumero = RegExp(r'\d').hasMatch(text);
    return text.length >= 8 && tieneLetras && tieneNumero;
  }

  static bool coloniaPermitida(String value) {
    final text = normalizar(value.trim());
    return colonias().any((c) => normalizar(c.colonia) == text);
  }

  static String fechaCorta(DateTime now) {
    final d = now.day.toString().padLeft(2, '0');
    final m = now.month.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    return '$d/$m ${h}:${min}';
  }
}

// =======================================================
// ESTILO
// =======================================================

class AppColors {
  static const green = Color(0xFF2E7D32);
  static const softGreen = Color(0xFFEAF6EA);
  static const bg = Color(0xFFF7FAF4);
  static const red = Color(0xFFC62828);
  static const orange = Color(0xFFEF6C00);
}

class RecolectorApp extends StatelessWidget {
  const RecolectorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Recolector Inteligente',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.green),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          foregroundColor: Colors.black87,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w900,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const SectionTitle(this.title, {super.key, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w900)),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(color: Colors.grey.shade700, fontSize: 15)),
        ],
      ),
    );
  }
}

class AppCard extends StatelessWidget {
  final Widget child;
  final Color? color;

  const AppCard({super.key, required this.child, this.color});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}


// =======================================================
// API SERVICE - CONEXIÓN CON BACKEND FASTAPI
// =======================================================

class ApiSession {
  static String? token;
  static Map<String, dynamic>? user;

  static String get role => (user?['role'] ?? '').toString().toLowerCase();
  static String get name => (user?['name'] ?? 'Usuario').toString();
  static String get email => (user?['email'] ?? '').toString();

  static void save({required String accessToken, required Map<String, dynamic> userData}) {
    token = accessToken;
    user = userData;
  }

  static void clear() {
    token = null;
    user = null;
  }
}

class ApiService {
  // Chrome en la misma computadora donde corre FastAPI.
  static const String apiBase = 'http://127.0.0.1:8000';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$apiBase/auth/login');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim().toLowerCase(),
        'password': password.trim(),
      }),
    ).timeout(const Duration(seconds: 8));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'No se pudo iniciar sesión.';
      try {
        final data = jsonDecode(response.body);
        message = data['detail']?.toString() ?? message;
      } catch (_) {}
      throw Exception(message);
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final token = data['access_token']?.toString();
    final user = Map<String, dynamic>.from(data['user'] ?? {});

    if (token == null || token.isEmpty || user.isEmpty) {
      throw Exception('Respuesta inválida del servidor.');
    }

    ApiSession.save(accessToken: token, userData: user);
    return data;
  }

  static Map<String, String> authHeaders() {
    return {
      'Content-Type': 'application/json',
      if (ApiSession.token != null) 'Authorization': 'Bearer ${ApiSession.token}',
    };
  }

  static Future<bool> health() async {
    try {
      final response = await http
          .get(Uri.parse('$apiBase/public/health'))
          .timeout(const Duration(seconds: 4));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> adminDashboard() async {
    final response = await http.get(
      Uri.parse('$apiBase/admin/dashboard'),
      headers: authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('No se pudo cargar dashboard admin');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static String _errorMessage(http.Response response, String fallback) {
    try {
      final data = jsonDecode(response.body);
      return data['detail']?.toString() ?? fallback;
    } catch (_) {
      return fallback;
    }
  }

  static String fechaDesdeBackend(dynamic value) {
    final raw = value?.toString() ?? '';
    if (raw.length >= 16) {
      return raw.substring(0, 16).replaceAll('T', ' ');
    }
    return raw;
  }

  static AlertaOperativa alertaFromBackend(Map<String, dynamic> json) {
    return AlertaOperativa(
      id: json['id']?.toString() ?? '',
      tipo: json['type']?.toString() ?? 'INFO',
      titulo: json['title']?.toString() ?? 'Alerta operativa',
      mensaje: json['message']?.toString() ?? '',
      routeId: json['route_id']?.toString() ?? '',
      rutaNombre: json['route_name']?.toString() ?? '',
      truckId: (json['truck_id'] as num?)?.toInt() ?? 0,
      operador: json['operator_id'] == null ? 'Sistema' : 'Operador ${json['operator_id']}',
      estado: json['status']?.toString() ?? 'NUEVA',
      fecha: fechaDesdeBackend(json['created_at']),
      prioridad: (json['priority'] as num?)?.toInt() ?? 1,
    );
  }

  static Future<void> ensureCitizenDemoDomicilio() async {
    if (ApiSession.role != 'ciudadano') return;

    final listResponse = await http.get(
      Uri.parse('$apiBase/citizen/domicilios'),
      headers: authHeaders(),
    );

    if (listResponse.statusCode == 200) {
      final list = jsonDecode(listResponse.body) as List;
      if (list.isNotEmpty) return;
    }

    final createResponse = await http.post(
      Uri.parse('$apiBase/citizen/domicilios'),
      headers: authHeaders(),
      body: jsonEncode({
        'tipo': 'Casa principal',
        'direccion': 'Calle Luna 123',
        'colonia': 'Zona Centro',
        'lat': 20.5210,
        'lng': -100.8210,
      }),
    );

    if (createResponse.statusCode < 200 || createResponse.statusCode >= 300) {
      throw Exception(_errorMessage(createResponse, 'No se pudo crear domicilio demo'));
    }
  }

  static Future<List<AlertaOperativa>> citizenAlerts() async {
    await ensureCitizenDemoDomicilio();

    final response = await http.get(
      Uri.parse('$apiBase/citizen/alerts'),
      headers: authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'No se pudieron cargar alertas ciudadanas'));
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => alertaFromBackend(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<AlertaOperativa>> adminAlerts() async {
    final response = await http.get(
      Uri.parse('$apiBase/admin/alerts'),
      headers: authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'No se pudieron cargar alertas admin'));
    }

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => alertaFromBackend(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<List<Map<String, dynamic>>> adminReports() async {
    final response = await http.get(
      Uri.parse('$apiBase/admin/reports'),
      headers: authHeaders(),
    );

    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<Map<String, dynamic>>> operatorRoutes() async {
    final response = await http.get(
      Uri.parse('$apiBase/operator/routes'),
      headers: authHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(_errorMessage(response, 'No se pudieron cargar rutas del operador'));
    }

    final list = jsonDecode(response.body) as List;
    return list.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  static Future<List<AlertaOperativa>> operatorAlerts() async {
    final response = await http.get(
      Uri.parse('$apiBase/operator/alerts'),
      headers: authHeaders(),
    );

    if (response.statusCode != 200) return [];

    final list = jsonDecode(response.body) as List;
    return list
        .map((e) => alertaFromBackend(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> operatorAction({
    required String routeId,
    required String action,
  }) async {
    final response = await http.post(
      Uri.parse('$apiBase/operator/routes/$routeId/$action'),
      headers: authHeaders(),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(_errorMessage(response, 'No se pudo enviar evento operativo'));
    }
  }
}



class GeoService {
  static Future<UbicacionMapa> reverseGeocode({
    required LatLng punto,
    required String coloniaFallback,
  }) async {
    final coloniaCercana = Repo.coloniaMasCercana(punto);

    try {
      final uri = Uri.https(
        'nominatim.openstreetmap.org',
        '/reverse',
        {
          'format': 'jsonv2',
          'lat': punto.latitude.toString(),
          'lon': punto.longitude.toString(),
          'zoom': '18',
          'addressdetails': '1',
          'accept-language': 'es',
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'User-Agent': 'RecolectorInteligenteHackathon/1.0',
        },
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw Exception('No se pudo geocodificar');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = Map<String, dynamic>.from(data['address'] ?? {});

      final calle = (
        address['road'] ??
        address['pedestrian'] ??
        address['footway'] ??
        address['residential'] ??
        address['path'] ??
        address['cycleway'] ??
        ''
      ).toString().trim();

      final numero = (address['house_number'] ?? '').toString().trim();

      final localidadTexto = [
        address['suburb'],
        address['neighbourhood'],
        address['quarter'],
        address['city_district'],
        address['hamlet'],
        address['village'],
        address['town'],
        address['city'],
        data['display_name'],
      ].where((e) => e != null && e.toString().trim().isNotEmpty).join(' ');

      final colonia = Repo.coloniaOficialDesdeTexto(localidadTexto, punto);

      String direccion = '';

      if (calle.isNotEmpty && numero.isNotEmpty) {
        direccion = '$calle $numero';
      } else if (calle.isNotEmpty) {
        direccion = '$calle, cerca de ${punto.latitude.toStringAsFixed(5)}, ${punto.longitude.toStringAsFixed(5)}';
      } else {
        direccion = 'Ubicación seleccionada ${punto.latitude.toStringAsFixed(5)}, ${punto.longitude.toStringAsFixed(5)}';
      }

      return UbicacionMapa(
        punto: punto,
        direccion: direccion,
        colonia: colonia,
      );
    } catch (_) {
      return UbicacionMapa(
        punto: punto,
        direccion: 'Ubicación seleccionada ${punto.latitude.toStringAsFixed(5)}, ${punto.longitude.toStringAsFixed(5)}',
        colonia: coloniaFallback.trim().isNotEmpty ? coloniaFallback.trim() : coloniaCercana,
      );
    }
  }
}

// =======================================================
// LOGIN
// =======================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final pass = TextEditingController();
  bool loading = false;

  bool correoValido(String value) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value.trim());
  }

  Future<void> entrar() async {
    final correo = email.text.trim().toLowerCase();
    final password = pass.text.trim();

    if (correo.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa correo y contraseña')),
      );
      return;
    }

    if (!correoValido(correo)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido. Ejemplo: demo@correo.com')),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await ApiService.login(email: correo, password: password);

      if (!mounted) return;

      final role = ApiSession.role;

      if (role == 'operador') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OperadorPage()),
        );
        return;
      }

      if (role == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminPage()),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error de login: ${e.toString().replaceFirst('Exception: ', '')}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 750;

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: isWide ? 520 : double.infinity),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: AppCard(
              child: Column(
                children: [
                  Container(
                    width: 96,
                    height: 96,
                    decoration: const BoxDecoration(
                      color: AppColors.softGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_outline, size: 60, color: AppColors.green),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Recolector Inteligente',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Horarios claros, alertas privadas y educación para separar residuos.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 17, height: 1.35),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.green.withOpacity(0.25)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.api, color: AppColors.green, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Login conectado al backend FastAPI',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: email,
                    decoration: const InputDecoration(
                      labelText: 'Correo o teléfono',
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: pass,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      prefixIcon: Icon(Icons.lock),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    height: 56,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: loading ? null : () => entrar(),
                      icon: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(
                        loading ? 'Conectando...' : 'Iniciar sesión',
                        style: const TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      email.text = 'demo@correo.com';
                      pass.text = '123456';
                    },
                    child: const Text('Usar cuenta ciudadano'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      email.text = 'operador@demo.com';
                      pass.text = '123456';
                    },
                    icon: const Icon(Icons.engineering),
                    label: const Text('Usar cuenta operador'),
                  ),
                  TextButton(
                    onPressed: () {
                      email.text = 'admin@demo.com';
                      pass.text = '123456';
                    },
                    child: const Text('Ver módulo administrador propuesto'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================
// HOME
// =======================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Domicilio> domicilios = [];
  List<Servicio> servicios = [];
  List<AlertaOperativa> alertas = [];
  Timer? alertTimer;
  String? ultimaAlertaVista;

  @override
  void initState() {
    super.initState();
    cargar();
    alertTimer = Timer.periodic(const Duration(seconds: 5), (_) => cargar(silencioso: true));
  }

  Future<void> cargar({bool silencioso = false}) async {
    final d = await Repo.cargarDomicilios();
    final s = await Repo.cargarServicios();

    List<AlertaOperativa> a = [];
    try {
      a = await ApiService.citizenAlerts();
    } catch (_) {
      a = await Repo.cargarAlertasOperativas();
    }

    if (!mounted) return;

    final nuevaAlerta = a.isNotEmpty && a.first.id != ultimaAlertaVista;

    setState(() {
      domicilios = d;
      servicios = s;
      alertas = a;
    });

    if (nuevaAlerta && silencioso) {
      ultimaAlertaVista = a.first.id;
      final alerta = a.first;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${alerta.titulo}\n${alerta.mensaje}'),
          duration: const Duration(seconds: 5),
          backgroundColor: alerta.prioridad >= 3 ? AppColors.red : AppColors.orange,
        ),
      );
    } else if (a.isNotEmpty) {
      ultimaAlertaVista = a.first.id;
    }
  }

  @override
  void dispose() {
    alertTimer?.cancel();
    super.dispose();
  }

  Widget menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color color = AppColors.green,
  }) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final principal = domicilios.isEmpty ? null : domicilios.first;
    final ruta = Repo.rutaDe(principal);
    final horario = Repo.horarioDe(principal);
    final colonia = Repo.coloniaDe(principal);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recolector Inteligente'),
        actions: [
          IconButton(onPressed: cargar, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ApiSession.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cargar,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              color: AppColors.softGreen,
              child: Row(
                children: [
                  const Icon(Icons.event_available, color: AppColors.green, size: 42),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Ruta asignada', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          ruta.routeId,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          principal == null
                              ? 'Registra tu domicilio para asignar ruta.'
                              : '${colonia?.colonia ?? 'Colonia no validada'} · $horario',
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (alertas.isNotEmpty) ...[
              const SizedBox(height: 8),
              AppCard(
                color: alertas.first.prioridad >= 3 ? const Color(0xFFFFEBEE) : const Color(0xFFFFF8E1),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      alertas.first.prioridad >= 3 ? Icons.warning_amber : Icons.info,
                      color: alertas.first.prioridad >= 3 ? AppColors.red : AppColors.orange,
                      size: 42,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Alerta operativa reciente', style: TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            alertas.first.titulo,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                          ),
                          Text(alertas.first.mensaje),
                          const SizedBox(height: 6),
                          Text(
                            '${alertas.first.routeId} · Camión ${alertas.first.truckId} · ${alertas.first.fecha}',
                            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            Row(
              children: [
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.home_work, color: AppColors.green),
                        const SizedBox(height: 6),
                        const Text('Domicilios', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('${domicilios.length}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.local_shipping, color: AppColors.green),
                        const SizedBox(height: 6),
                        const Text('Camión', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text('${ruta.truckId}', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SectionTitle('Menú principal'),
            menuCard(
              icon: Icons.person,
              title: 'Datos personales',
              subtitle: 'Registra tus datos, colonia y domicilio con mapa.',
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const DatosPage()));
                cargar();
              },
            ),
            menuCard(
              icon: Icons.local_shipping,
              title: 'Seguimiento de basura',
              subtitle: 'Simula eventos oficiales por positionId sin mostrar mapa público.',
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SeguimientoPage()));
                cargar();
              },
            ),
            menuCard(
              icon: Icons.recycling,
              title: 'Guía para la separación',
              subtitle: 'Orgánicos, reciclables, sanitarios y especiales.',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuiaPage()));
              },
            ),
            menuCard(
              icon: Icons.feedback,
              title: 'Buzón de sugerencias',
              subtitle: 'Reporta incidencias o califica el servicio.',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BuzonPage()));
              },
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// MAPA PARA SELECCIONAR DOMICILIO
// =======================================================

class MapPickerPage extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialColonia;

  const MapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialColonia,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  final MapController mapController = MapController();

  late LatLng selected;
  late LatLng coloniaCentro;

  double zoom = 15;
  bool buscandoDireccion = false;

  String direccionDetectada = 'Selecciona un punto en el mapa';
  String coloniaDetectada = 'Zona Centro';

  Timer? geoTimer;

  @override
  void initState() {
    super.initState();

    coloniaDetectada = widget.initialColonia?.trim().isNotEmpty == true
        ? widget.initialColonia!.trim()
        : 'Zona Centro';

    coloniaCentro = Repo.centroColonia(coloniaDetectada);

    selected = LatLng(
      widget.initialLat ?? coloniaCentro.latitude,
      widget.initialLng ?? coloniaCentro.longitude,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      actualizarDireccionDesdeMapa(selected);
    });
  }

  void moverAColonia() {
    final centro = Repo.centroColonia(coloniaDetectada);

    setState(() {
      selected = centro;
      coloniaCentro = centro;
      zoom = 15;
    });

    mapController.move(centro, zoom);
    actualizarDireccionDesdeMapa(centro);
  }

  void ajustarZoom(double delta) {
    final nuevoZoom = (zoom + delta).clamp(12.0, 18.0);

    setState(() {
      zoom = nuevoZoom;
    });

    mapController.move(selected, nuevoZoom);
  }

  void seleccionarPunto(LatLng punto, {bool moverCamara = false}) {
    setState(() {
      selected = punto;
    });

    if (moverCamara) {
      mapController.move(punto, zoom);
    }

    actualizarDireccionDesdeMapa(punto);
  }

  void actualizarDireccionDesdeMapa(LatLng punto) {
    geoTimer?.cancel();

    setState(() {
      buscandoDireccion = true;
    });

    geoTimer = Timer(const Duration(milliseconds: 650), () async {
      final resultado = await GeoService.reverseGeocode(
        punto: punto,
        coloniaFallback: coloniaDetectada,
      );

      if (!mounted) return;

      final sigueSiendoElMismoPunto =
          (selected.latitude - punto.latitude).abs() < 0.00001 &&
          (selected.longitude - punto.longitude).abs() < 0.00001;

      if (!sigueSiendoElMismoPunto) return;

      setState(() {
        direccionDetectada = resultado.direccion;
        coloniaDetectada = resultado.colonia;
        coloniaCentro = Repo.centroColonia(resultado.colonia);
        buscandoDireccion = false;
      });
    });
  }

  void confirmarUbicacion() {
    Navigator.pop(
      context,
      UbicacionMapa(
        punto: selected,
        direccion: direccionDetectada,
        colonia: coloniaDetectada,
      ),
    );
  }

  @override
  void dispose() {
    geoTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar domicilio'),
        actions: [
          IconButton(
            tooltip: 'Centrar en colonia',
            onPressed: moverAColonia,
            icon: const Icon(Icons.my_location),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: selected,
              initialZoom: zoom,
              minZoom: 12,
              maxZoom: 18,
              onTap: (tapPosition, point) {
                seleccionarPunto(point, moverCamara: true);
              },
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    selected = camera.center;
                    zoom = camera.zoom;
                  });

                  actualizarDireccionDesdeMapa(camera.center);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.recolector_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: coloniaCentro,
                    width: 46,
                    height: 46,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.18),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.green, width: 2),
                      ),
                      child: const Icon(
                        Icons.location_city,
                        color: AppColors.green,
                      ),
                    ),
                  ),
                  Marker(
                    point: selected,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      color: AppColors.red,
                      size: 54,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            left: 16,
            right: 16,
            top: 14,
            child: AppCard(
              color: Colors.white.withOpacity(0.94),
              child: Row(
                children: [
                  Icon(
                    buscandoDireccion ? Icons.sync : Icons.touch_app,
                    color: AppColors.green,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      buscandoDireccion
                          ? 'Buscando dirección y localidad...'
                          : 'Mueve el mapa o toca un punto. La dirección y colonia se actualizan automáticamente.',
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 16,
            top: 112,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoomIn',
                  onPressed: () => ajustarZoom(1),
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoomOut',
                  onPressed: () => ajustarZoom(-1),
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),

          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(
                    child: Text(
                      'Confirmar ubicación del domicilio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.home, color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          direccionDetectada,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Row(
                    children: [
                      const Icon(Icons.location_city, color: AppColors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Localidad/colonia: $coloniaDetectada',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Lat: ${selected.latitude.toStringAsFixed(6)} · Lng: ${selected.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: moverAColonia,
                            icon: const Icon(Icons.center_focus_strong),
                            label: const Text('Centrar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: buscandoDireccion ? null : confirmarUbicacion,
                            icon: const Icon(Icons.check),
                            label: const Text('Usar ubicación'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// =======================================================
// DATOS
// =======================================================

class DatosPage extends StatefulWidget {
  const DatosPage({super.key});

  @override
  State<DatosPage> createState() => _DatosPageState();
}

class _DatosPageState extends State<DatosPage> with SingleTickerProviderStateMixin {
  late TabController tab;

  final nombre = TextEditingController();
  final telefono = TextEditingController();
  final correo = TextEditingController();
  final rfc = TextEditingController();

  final direccionPrincipal = TextEditingController();
  final coloniaPrincipal = TextEditingController();

  final direccionExtra = TextEditingController();
  final coloniaExtra = TextEditingController();

  String tipoExtra = 'Negocio';
  String resultado = '';
  List<Domicilio> domicilios = [];

  double? latPrincipal;
  double? lngPrincipal;
  double? latExtra;
  double? lngExtra;

  @override
  void initState() {
    super.initState();
    tab = TabController(length: 2, vsync: this);
    cargar();
  }

  Future<void> cargar() async {
    final usuario = await Repo.cargarUsuario();
    final ds = await Repo.cargarDomicilios();

    nombre.text = usuario['nombre'] ?? '';
    telefono.text = usuario['telefono'] ?? '';
    correo.text = usuario['correo'] ?? '';
    rfc.text = usuario['rfc'] ?? '';

    if (ds.isNotEmpty) {
      final principal = ds.firstWhere(
        (d) => d.tipo == 'Casa principal',
        orElse: () => ds.first,
      );
      direccionPrincipal.text = principal.direccion;
      coloniaPrincipal.text = principal.colonia;
      latPrincipal = principal.lat;
      lngPrincipal = principal.lng;
    }

    if (!mounted) return;

    setState(() {
      domicilios = ds;
    });
  }

  Future<void> abrirMapaPrincipal() async {
    final result = await Navigator.push<UbicacionMapa>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: latPrincipal,
          initialLng: lngPrincipal,
          initialColonia: coloniaPrincipal.text.trim(),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      latPrincipal = result.punto.latitude;
      lngPrincipal = result.punto.longitude;
      direccionPrincipal.text = result.direccion;
      coloniaPrincipal.text = result.colonia;
      resultado = '';
    });
  }

  Future<void> abrirMapaExtra() async {
    final result = await Navigator.push<UbicacionMapa>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: latExtra,
          initialLng: lngExtra,
          initialColonia: coloniaExtra.text.trim(),
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      latExtra = result.punto.latitude;
      lngExtra = result.punto.longitude;
      direccionExtra.text = result.direccion;
      coloniaExtra.text = result.colonia;
    });
  }

  void actualizarMapaPrincipalPorColonia(String? value) {
    final colonia = value ?? '';
    coloniaPrincipal.text = colonia;

    final centro = Repo.centroColonia(colonia);

    setState(() {
      latPrincipal = centro.latitude;
      lngPrincipal = centro.longitude;
      resultado = '';
    });
  }

  void actualizarMapaExtraPorColonia(String? value) {
    final colonia = value ?? '';
    coloniaExtra.text = colonia;

    final centro = Repo.centroColonia(colonia);

    setState(() {
      latExtra = centro.latitude;
      lngExtra = centro.longitude;
    });
  }

  Future<void> guardarRegistro() async {
    final nombreTxt = nombre.text.trim();
    final telefonoTxt = telefono.text.trim();
    final correoTxt = correo.text.trim();
    final direccionTxt = direccionPrincipal.text.trim();
    final coloniaTxt = coloniaPrincipal.text.trim();

    if (nombreTxt.isEmpty || telefonoTxt.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y teléfono son obligatorios')),
      );
      return;
    }

    if (!Repo.emailValido(correoTxt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un correo válido. Ejemplo: usuario@correo.com')),
      );
      return;
    }

    if (!Repo.direccionValida(direccionTxt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa una dirección válida con calle y número.')),
      );
      return;
    }

    if (!Repo.coloniaPermitida(coloniaTxt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una colonia válida de la lista oficial.')),
      );
      return;
    }

    if (latPrincipal == null || lngPrincipal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona tu domicilio en el mapa para validar la ubicación.')),
      );
      return;
    }

    await Repo.guardarUsuario(
      nombre: nombreTxt,
      telefono: telefonoTxt,
      correo: correoTxt,
      rfc: rfc.text.trim(),
    );

    final lista = [...domicilios];

    if (direccionPrincipal.text.trim().isNotEmpty) {
      final principal = Domicilio(
        tipo: 'Casa principal',
        direccion: direccionPrincipal.text.trim(),
        colonia: coloniaPrincipal.text.trim(),
        lat: latPrincipal,
        lng: lngPrincipal,
      );

      final index = lista.indexWhere((d) => d.tipo == 'Casa principal');
      if (index >= 0) {
        lista[index] = principal;
      } else {
        lista.insert(0, principal);
      }
    }

    await Repo.guardarDomicilios(lista);

    if (!mounted) return;

    setState(() {
      domicilios = lista;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Registro guardado')),
    );
  }

  Future<void> agregarDomicilio() async {
    final direccionTxt = direccionExtra.text.trim();
    final coloniaTxt = coloniaExtra.text.trim();

    if (!Repo.direccionValida(direccionTxt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe una dirección válida con calle y número.')),
      );
      return;
    }

    if (!Repo.coloniaPermitida(coloniaTxt)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona una colonia válida de la lista oficial.')),
      );
      return;
    }

    if (latExtra == null || lngExtra == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona este domicilio en el mapa.')),
      );
      return;
    }

    final nuevo = Domicilio(
      tipo: tipoExtra,
      direccion: direccionExtra.text.trim(),
      colonia: coloniaExtra.text.trim(),
      lat: latExtra,
      lng: lngExtra,
    );

    final lista = [...domicilios, nuevo];
    await Repo.guardarDomicilios(lista);

    if (!mounted) return;

    setState(() {
      domicilios = lista;
      direccionExtra.clear();
      coloniaExtra.clear();
      latExtra = null;
      lngExtra = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$tipoExtra agregado')),
    );
  }

  Future<void> eliminarDomicilio(int index) async {
    final lista = [...domicilios]..removeAt(index);
    await Repo.guardarDomicilios(lista);

    if (!mounted) return;

    setState(() {
      domicilios = lista;
    });
  }

  void simularHorarios() {
    final lista = <Domicilio>[];

    if (domicilios.isNotEmpty) {
      lista.addAll(domicilios);
    } else if (direccionPrincipal.text.trim().isNotEmpty) {
      lista.add(
        Domicilio(
          tipo: 'Casa principal',
          direccion: direccionPrincipal.text.trim(),
          colonia: coloniaPrincipal.text.trim(),
          lat: latPrincipal,
          lng: lngPrincipal,
        ),
      );
    }

    if (lista.isEmpty) {
      setState(() {
        resultado = 'Registra al menos un domicilio para desplegar ruta y horario.';
      });
      return;
    }

    final buffer = StringBuffer();

    for (final d in lista) {
      final ruta = Repo.rutaDe(d);
      final colonia = Repo.coloniaDe(d);
      final horario = Repo.horarioDe(d);

      buffer.writeln(d.etiqueta);
      buffer.writeln('Colonia validada: ${colonia?.colonia ?? 'No validada, se asigna ruta demo'}');
      buffer.writeln('Ruta: ${ruta.routeId} · ${ruta.name}');
      buffer.writeln('Camión: ${ruta.truckId}');
      buffer.writeln('Horario: $horario');
      if (d.lat != null && d.lng != null) {
        buffer.writeln('Ubicación: ${d.lat!.toStringAsFixed(5)}, ${d.lng!.toStringAsFixed(5)}');
      }
      buffer.writeln('');
    }

    setState(() {
      resultado = buffer.toString().trim();
    });
  }

  Widget campo({
    required String label,
    required TextEditingController controller,
    IconData? icon,
    TextInputType? keyboard,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: icon == null ? null : Icon(icon),
        ),
      ),
    );
  }

  Widget asignacionZonaCard({
    required String colonia,
    required double? lat,
    required double? lng,
  }) {
    final col = colonia.trim().isEmpty ? 'Zona Centro' : colonia.trim();
    final domicilioDemo = Domicilio(
      tipo: 'Vista previa',
      direccion: 'Domicilio temporal 123',
      colonia: col,
      lat: lat,
      lng: lng,
    );
    final ruta = Repo.rutaDe(domicilioDemo);
    final horario = Repo.horarioDe(domicilioDemo);
    final coloniaValidada = Repo.coloniaDe(domicilioDemo);

    return AppCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: AppColors.softGreen,
                child: Icon(Icons.check_circle, color: AppColors.green),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Datos actualizados automáticamente',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      'Al cambiar colonia se actualiza ruta, horario y mapa.',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.location_city, size: 18),
                label: Text(coloniaValidada?.colonia ?? col),
              ),
              Chip(
                avatar: const Icon(Icons.alt_route, size: 18),
                label: Text(ruta.routeId),
              ),
              Chip(
                avatar: const Icon(Icons.local_shipping, size: 18),
                label: Text('Camión ${ruta.truckId}'),
              ),
              Chip(
                avatar: const Icon(Icons.schedule, size: 18),
                label: Text(horario),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.map, color: AppColors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  lat == null || lng == null
                      ? 'El mapa se precargó al centro de $col. Abre el mapa para ajustar el pin exacto.'
                      : 'Ubicación seleccionada: ${Repo.coordenadasTexto(lat, lng)}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget selectorMapa({
    required VoidCallback onPressed,
    required double? lat,
    required double? lng,
    required String colonia,
  }) {
    final tieneUbicacion = lat != null && lng != null;
    final punto = LatLng(lat ?? Repo.centroColonia(colonia).latitude, lng ?? Repo.centroColonia(colonia).longitude);
    final domicilioDemo = Domicilio(tipo: 'Vista previa', direccion: 'Domicilio seleccionado', colonia: colonia);
    final ruta = Repo.rutaDe(domicilioDemo);
    final horario = Repo.horarioDe(domicilioDemo);

    return AppCard(
      color: AppColors.softGreen,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: AppColors.green, size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubicación en mapa',
                      style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                    ),
                    Text(
                      tieneUbicacion
                          ? 'Coordenadas: ${Repo.coordenadasTexto(lat, lng)}'
                          : 'Selecciona colonia para precargar el mapa.',
                      style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: SizedBox(
              height: 180,
              child: FlutterMap(
                key: ValueKey('preview-$colonia-${lat ?? 0}-${lng ?? 0}'),
                options: MapOptions(
                  initialCenter: punto,
                  initialZoom: 15,
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.example.recolector_app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: punto,
                        width: 70,
                        height: 70,
                        child: Icon(
                          tieneUbicacion ? Icons.location_pin : Icons.location_searching,
                          color: tieneUbicacion ? AppColors.red : AppColors.orange,
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.green.withOpacity(0.20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.alt_route, color: AppColors.green),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '$colonia · ${ruta.routeId} · $horario',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.edit_location_alt),
              label: Text(tieneUbicacion ? 'Ajustar ubicación' : 'Abrir mapa y confirmar'),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tab.dispose();
    nombre.dispose();
    telefono.dispose();
    correo.dispose();
    rfc.dispose();
    direccionPrincipal.dispose();
    coloniaPrincipal.dispose();
    direccionExtra.dispose();
    coloniaExtra.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colonias = Repo.colonias();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos personales'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              ApiSession.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: tab,
          tabs: const [
            Tab(text: 'Registro'),
            Tab(text: 'Domicilios'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tab,
        children: [
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionTitle('Información del usuario'),
              campo(label: 'Nombre completo', controller: nombre, icon: Icons.person),
              campo(label: 'Teléfono', controller: telefono, icon: Icons.phone, keyboard: TextInputType.phone),
              campo(label: 'Correo electrónico', controller: correo, icon: Icons.email, keyboard: TextInputType.emailAddress),
              campo(label: 'RFC opcional', controller: rfc, icon: Icons.badge),
              const SectionTitle('Casa principal'),
              campo(label: 'Domicilio principal', controller: direccionPrincipal, icon: Icons.home),
              DropdownButtonFormField<String>(
                value: coloniaPrincipal.text.trim().isEmpty ? null : coloniaPrincipal.text.trim(),
                decoration: const InputDecoration(
                  labelText: 'Colonia',
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: colonias.map((c) {
                  return DropdownMenuItem(
                    value: c.colonia,
                    child: Text(c.colonia),
                  );
                }).toList(),
                onChanged: actualizarMapaPrincipalPorColonia,
              ),
              const SizedBox(height: 10),
              asignacionZonaCard(
                colonia: coloniaPrincipal.text.trim().isEmpty ? 'Zona Centro' : coloniaPrincipal.text.trim(),
                lat: latPrincipal,
                lng: lngPrincipal,
              ),
              const SizedBox(height: 14),
              selectorMapa(
                onPressed: abrirMapaPrincipal,
                lat: latPrincipal,
                lng: lngPrincipal,
                colonia: coloniaPrincipal.text.trim().isEmpty ? 'Zona Centro' : coloniaPrincipal.text.trim(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: guardarRegistro,
                  icon: const Icon(Icons.save),
                  label: const Text('Guardar registro', style: TextStyle(fontSize: 17)),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: simularHorarios,
                  icon: const Icon(Icons.calendar_month),
                  label: const Text('Ver ruta asignada', style: TextStyle(fontSize: 17)),
                ),
              ),
              if (resultado.isNotEmpty) ...[
                const SizedBox(height: 16),
                AppCard(
                  color: AppColors.softGreen,
                  child: Text(resultado, style: const TextStyle(fontSize: 16.5, height: 1.45)),
                ),
              ],
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionTitle(
                'Más domicilios',
                subtitle: 'Agrega negocios, segunda casa u otros puntos de recolección.',
              ),
              DropdownButtonFormField<String>(
                value: tipoExtra,
                decoration: const InputDecoration(
                  labelText: 'Tipo de domicilio',
                  prefixIcon: Icon(Icons.category),
                ),
                items: const [
                  DropdownMenuItem(value: 'Negocio', child: Text('Negocio')),
                  DropdownMenuItem(value: 'Segunda casa', child: Text('Segunda casa')),
                  DropdownMenuItem(value: 'Otro domicilio', child: Text('Otro domicilio')),
                ],
                onChanged: (value) => setState(() => tipoExtra = value ?? 'Negocio'),
              ),
              const SizedBox(height: 14),
              campo(label: 'Dirección', controller: direccionExtra, icon: Icons.add_location_alt),
              DropdownButtonFormField<String>(
                value: coloniaExtra.text.trim().isEmpty ? null : coloniaExtra.text.trim(),
                decoration: const InputDecoration(
                  labelText: 'Colonia',
                  prefixIcon: Icon(Icons.location_city),
                ),
                items: colonias.map((c) {
                  return DropdownMenuItem(
                    value: c.colonia,
                    child: Text(c.colonia),
                  );
                }).toList(),
                onChanged: actualizarMapaExtraPorColonia,
              ),
              const SizedBox(height: 10),
              asignacionZonaCard(
                colonia: coloniaExtra.text.trim().isEmpty ? 'Zona Centro' : coloniaExtra.text.trim(),
                lat: latExtra,
                lng: lngExtra,
              ),
              const SizedBox(height: 14),
              selectorMapa(
                onPressed: abrirMapaExtra,
                lat: latExtra,
                lng: lngExtra,
                colonia: coloniaExtra.text.trim().isEmpty ? 'Zona Centro' : coloniaExtra.text.trim(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 54,
                child: FilledButton.icon(
                  onPressed: agregarDomicilio,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar domicilio', style: TextStyle(fontSize: 17)),
                ),
              ),
              const SectionTitle('Domicilios registrados'),
              if (domicilios.isEmpty)
                const AppCard(child: Text('Todavía no hay domicilios guardados.'))
              else
                ...List.generate(domicilios.length, (i) {
                  final d = domicilios[i];
                  final ruta = Repo.rutaDe(d);
                  final horario = Repo.horarioDe(d);

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.home_work, color: AppColors.green),
                      title: Text(d.etiqueta, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('${ruta.routeId} · $horario'),
                      trailing: IconButton(
                        onPressed: () => eliminarDomicilio(i),
                        icon: const Icon(Icons.delete_outline, color: AppColors.red),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ],
      ),
    );
  }
}

// =======================================================
// SEGUIMIENTO
// =======================================================

enum EventoCamion { normal, retraso, averia }

class SeguimientoPage extends StatefulWidget {
  const SeguimientoPage({super.key});

  @override
  State<SeguimientoPage> createState() => _SeguimientoPageState();
}

class _SeguimientoPageState extends State<SeguimientoPage> {
  Timer? timer;
  List<Domicilio> domicilios = [];
  Domicilio? seleccionado;

  int paso = 0;
  int estrellas = 0;
  EventoCamion evento = EventoCamion.normal;

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final lista = await Repo.cargarDomicilios();

    if (!mounted) return;

    setState(() {
      domicilios = lista;
      seleccionado = lista.isEmpty ? null : lista.first;
    });
  }

  RutaOficial get ruta => Repo.rutaDe(seleccionado);
  String get horario => Repo.horarioDe(seleccionado);
  List<RoutePosition> get posiciones => ruta.positions;

  int get positionIdActual {
    if (posiciones.isEmpty) return 0;
    return posiciones[paso.clamp(0, posiciones.length - 1)].positionId;
  }

  bool get finalizado {
    if (posiciones.isEmpty) return false;
    return paso >= posiciones.length - 1;
  }

  double get progreso {
    if (posiciones.isEmpty) return 0;
    return (paso + 1) / posiciones.length;
  }

  String get tituloEstado {
    if (evento == EventoCamion.retraso) return 'Retraso técnico: 25 minutos';
    if (evento == EventoCamion.averia) return 'Camión averiado';

    if (positionIdActual == 1) return 'Recolección programada';
    if (positionIdActual == 2) return 'Ruta iniciada';
    if (positionIdActual == 4) return 'El camión pasará en menos de 15 minutos';
    if (positionIdActual == 8) return 'Servicio finalizado';

    return 'Camión en ruta asignada';
  }

  String get mensajeEstado {
    if (seleccionado == null) {
      return 'Primero registra un domicilio en Datos personales.';
    }

    if (evento == EventoCamion.retraso) {
      return 'Conserva tus residuos en casa hasta que se reactive el servicio.';
    }

    if (evento == EventoCamion.averia) {
      return 'Se enviará una notificación cuando haya unidad de reemplazo.';
    }

    if (positionIdActual == 1) {
      return 'Tu ruta asignada es ${ruta.routeId}. Ventana estimada: $horario.';
    }

    if (positionIdActual == 2) {
      return 'El camión salió del relleno sanitario rumbo a tu sector.';
    }

    if (positionIdActual == 4) {
      return 'Es momento de preparar tus residuos. No persigas la unidad ni salgas antes del horario.';
    }

    if (positionIdActual == 8) {
      return 'Servicio concluido. Ya puedes calificar de 1 a 5 estrellas.';
    }

    return 'Se muestra solo el avance operativo de tu ruta, sin mapa público ni rastreo en tiempo real.';
  }

  void iniciar() {
    if (seleccionado == null) {
      aviso('Sin domicilio', 'Registra un domicilio para iniciar el seguimiento.');
      return;
    }

    timer?.cancel();

    setState(() {
      paso = 0;
      estrellas = 0;
      evento = EventoCamion.normal;
    });

    aviso('Seguimiento iniciado', seleccionado!.etiqueta);

    timer = Timer.periodic(const Duration(seconds: 4), (t) {
      if (paso >= posiciones.length - 1) {
        t.cancel();
        return;
      }

      setState(() => paso++);

      dispararNotificacionSegunPositionId();

      if (finalizado) {
        t.cancel();
      }
    });
  }

  void dispararNotificacionSegunPositionId() {
    String? trigger;

    if (positionIdActual == 2) {
      trigger = 'ROUTE_START';
    } else if (positionIdActual == 4) {
      trigger = 'TRUCK_PROXIMITY';
    } else if (positionIdActual == 8) {
      trigger = 'ROUTE_COMPLETED';
    }

    if (trigger == null) return;

    final notificacion = Repo.notificacionPorEvento(trigger);
    if (notificacion == null) return;

    aviso(notificacion.title, notificacion.body);
  }

  void simularRetraso() {
    if (seleccionado == null) {
      aviso('Sin domicilio', 'Selecciona un domicilio primero.');
      return;
    }

    timer?.cancel();

    setState(() {
      evento = EventoCamion.retraso;
    });

    aviso('Retraso técnico', 'Tiempo estimado adicional: 25 minutos.');
  }

  void simularAveria() {
    if (seleccionado == null) {
      aviso('Sin domicilio', 'Selecciona un domicilio primero.');
      return;
    }

    timer?.cancel();

    setState(() {
      evento = EventoCamion.averia;
    });

    aviso('Notificación enviada', 'El camión se averió. Se notificará al celular registrado.');
  }

  Future<void> finalizar() async {
    if (seleccionado == null || posiciones.isEmpty) return;

    timer?.cancel();
    setState(() => paso = posiciones.length - 1);

    dispararNotificacionSegunPositionId();
  }

  Future<void> guardarCalificacion(int valor) async {
    if (!finalizado || seleccionado == null) return;

    setState(() => estrellas = valor);

    final now = DateTime.now();
    final fecha = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    await Repo.guardarServicio(
      Servicio(
        domicilio: seleccionado!.etiqueta,
        estrellas: valor,
        fecha: fecha,
      ),
    );

    if (!mounted) return;
    aviso('Gracias', 'Calificación guardada: $valor/5');
  }

  void reiniciar() {
    timer?.cancel();

    setState(() {
      paso = 0;
      estrellas = 0;
      evento = EventoCamion.normal;
    });
  }

  void aviso(String titulo, String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$titulo\n$mensaje'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget pasoItem(int index) {
    final position = posiciones[index];
    final completado = index < paso;
    final actual = index == paso;

    Color color = Colors.grey.shade300;
    IconData icon = Icons.circle;

    if (completado) {
      color = AppColors.green;
      icon = Icons.check;
    }

    if (actual) {
      color = AppColors.green;
      icon = Icons.local_shipping;

      if (evento == EventoCamion.retraso) {
        color = AppColors.orange;
        icon = Icons.timer;
      }

      if (evento == EventoCamion.averia) {
        color = AppColors.red;
        icon = Icons.warning;
      }
    }

    String texto = 'Punto operativo ${position.positionId}';

    if (position.positionId == 1) texto = 'Inicio en relleno sanitario';
    if (position.positionId == 2) texto = 'Ruta iniciada';
    if (position.positionId == 4) texto = 'Camión cercano a tu zona';
    if (position.positionId == 5) texto = 'Recolección en zona asignada';
    if (position.positionId == 8) texto = 'Retorno y servicio finalizado';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            if (index != posiciones.length - 1)
              Container(
                width: 4,
                height: 44,
                color: completado ? AppColors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              texto,
              style: TextStyle(
                fontSize: actual ? 19 : 17,
                fontWeight: actual ? FontWeight.w900 : FontWeight.w500,
                color: actual ? color : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget rating() {
    return AppCard(
      child: Column(
        children: [
          const Text('Califica el servicio', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final valor = index + 1;

              return IconButton(
                iconSize: 40,
                onPressed: finalizado ? () => guardarCalificacion(valor) : null,
                icon: Icon(
                  index < estrellas ? Icons.star : Icons.star_border,
                  color: finalizado ? Colors.amber : Colors.grey,
                ),
              );
            }),
          ),
          Text(
            finalizado ? 'Selecciona de 1 a 5 estrellas.' : 'Disponible al terminar el seguimiento.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sinDomicilios = domicilios.isEmpty;
    final colonia = Repo.coloniaDe(seleccionado);

    return Scaffold(
      appBar: AppBar(title: const Text('Seguimiento de basura')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            color: AppColors.softGreen,
            child: Column(
              children: [
                const Text('Domicilio del seguimiento', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (sinDomicilios)
                  Column(
                    children: [
                      const Text(
                        'No tienes domicilios registrados.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const DatosPage()));
                          cargar();
                        },
                        icon: const Icon(Icons.add_home),
                        label: const Text('Registrar domicilio'),
                      ),
                    ],
                  )
                else
                  DropdownButtonFormField<Domicilio>(
                    value: seleccionado,
                    decoration: const InputDecoration(
                      labelText: 'Selecciona domicilio',
                      prefixIcon: Icon(Icons.home),
                      fillColor: Colors.white,
                    ),
                    items: domicilios.map((d) {
                      return DropdownMenuItem(
                        value: d,
                        child: Text(d.etiqueta, overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (value) {
                      timer?.cancel();

                      setState(() {
                        seleccionado = value;
                        paso = 0;
                        estrellas = 0;
                        evento = EventoCamion.normal;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                Text(
                  ruta.routeId,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  '${ruta.name}\nCamión ${ruta.truckId} · ${colonia?.colonia ?? 'colonia no validada'}\n$horario',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16.5, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Column(
              children: [
                const Icon(Icons.local_shipping, size: 68, color: AppColors.green),
                const SizedBox(height: 8),
                Text(
                  tituloEstado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                Text(
                  mensajeEstado,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16.5, height: 1.35),
                ),
                const SizedBox(height: 16),
                LinearProgressIndicator(value: progreso, minHeight: 12),
                const SizedBox(height: 8),
                Text(
                  'positionId actual: $positionIdActual',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SectionTitle('Estado privado del servicio'),
          ...List.generate(posiciones.length, pasoItem),
          const SizedBox(height: 12),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: iniciar,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Iniciar simulación', style: TextStyle(fontSize: 17)),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: simularRetraso,
                    icon: const Icon(Icons.timer),
                    label: const Text('Retraso'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: simularAveria,
                    icon: const Icon(Icons.warning),
                    label: const Text('Avería'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: finalizar,
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Finalizar'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton.icon(
                    onPressed: reiniciar,
                    icon: const Icon(Icons.restart_alt),
                    label: const Text('Reiniciar'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          rating(),
          const SizedBox(height: 16),
          const Text(
            'Privacidad: no se muestra mapa con el camión moviéndose en tiempo real. Solo se muestran eventos operativos de la ruta asignada a tu domicilio.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}


// =======================================================
// OPERADOR / CHOFER
// =======================================================

class OperadorPage extends StatefulWidget {
  const OperadorPage({super.key});

  @override
  State<OperadorPage> createState() => _OperadorPageState();
}

class _OperadorPageState extends State<OperadorPage> {
  Timer? timer;
  late List<RutaOficial> rutasAsignadas;
  late RutaOficial rutaSeleccionada;
  int paso = 0;
  bool jornadaActiva = false;
  String estadoRuta = 'Pendiente de iniciar';
  List<AlertaOperativa> historial = [];

  @override
  void initState() {
    super.initState();
    final todas = Repo.rutas();
    rutasAsignadas = todas.where((r) {
      return r.routeId == 'RUTA-01' || r.routeId == 'RUTA-03' || r.routeId == 'RUTA-05';
    }).toList();

    rutaSeleccionada = rutasAsignadas.first;
    cargarHistorial();
  }

  Future<void> cargarHistorial() async {
    List<AlertaOperativa> lista = [];
    try {
      lista = await ApiService.operatorAlerts();
    } catch (_) {
      lista = await Repo.cargarAlertasOperativas();
    }
    if (!mounted) return;
    setState(() => historial = lista);
  }

  RoutePosition get posicionActual {
    return rutaSeleccionada.positions[paso.clamp(0, rutaSeleccionada.positions.length - 1)];
  }

  double get progreso {
    if (rutaSeleccionada.positions.isEmpty) return 0;
    return (paso + 1) / rutaSeleccionada.positions.length;
  }

  String get horarioOperador {
    final first = rutaSeleccionada.positions.first.timestamp;
    final last = rutaSeleccionada.positions.last.timestamp;
    final inicio = first.length >= 16 ? first.substring(11, 16) : '06:00';
    final fin = last.length >= 16 ? last.substring(11, 16) : '08:00';
    return '$inicio - $fin';
  }

  String get nombreOperador => 'Operador José Martínez';

  Future<void> guardarEvento({
    required String tipo,
    required String titulo,
    required String mensaje,
    required int prioridad,
    required String nuevoEstado,
  }) async {
    String action = 'incident';
    if (tipo == 'ROUTE_START') action = 'start';
    if (tipo == 'TRUCK_PROXIMITY') action = 'advance/4';
    if (tipo == 'DELAY') action = 'delay';
    if (tipo == 'MECHANICAL_FAILURE') action = 'breakdown';
    if (tipo == 'INCIDENT') action = 'incident';
    if (tipo == 'ROUTE_COMPLETED') action = 'complete';

    try {
      await ApiService.operatorAction(routeId: rutaSeleccionada.routeId, action: action);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("No se pudo enviar al backend: ${e.toString().replaceFirst('Exception: ', '')}"),
          backgroundColor: AppColors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final alerta = AlertaOperativa(
      id: now.microsecondsSinceEpoch.toString(),
      tipo: tipo,
      titulo: titulo,
      mensaje: mensaje,
      routeId: rutaSeleccionada.routeId,
      rutaNombre: rutaSeleccionada.name,
      truckId: rutaSeleccionada.truckId,
      operador: nombreOperador,
      estado: 'Nueva',
      fecha: Repo.fechaCorta(now),
      prioridad: prioridad,
    );

    await Repo.guardarAlertaOperativa(alerta);

    if (!mounted) return;

    setState(() {
      estadoRuta = nuevoEstado;
    });

    await cargarHistorial();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$titulo\nEnviado al backend y visible para ciudadano/admin.'),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> iniciarJornada() async {
    timer?.cancel();

    setState(() {
      jornadaActiva = true;
      paso = 0;
      estadoRuta = 'Ruta iniciada';
    });

    await guardarEvento(
      tipo: 'ROUTE_START',
      titulo: 'Ruta iniciada por operador',
      mensaje: 'El operador inició la jornada de ${rutaSeleccionada.routeId}.',
      prioridad: 1,
      nuevoEstado: 'Ruta iniciada',
    );

    timer = Timer.periodic(const Duration(seconds: 5), (t) {
      if (!jornadaActiva) {
        t.cancel();
        return;
      }

      if (paso >= rutaSeleccionada.positions.length - 1) {
        t.cancel();
        finalizarJornada();
        return;
      }

      setState(() => paso++);

      if (posicionActual.positionId == 4) {
        guardarEvento(
          tipo: 'TRUCK_PROXIMITY',
          titulo: 'Camión cercano a zona asignada',
          mensaje: 'El operador reportó proximidad operativa para ${rutaSeleccionada.routeId}.',
          prioridad: 2,
          nuevoEstado: 'Camión cercano',
        );
      }
    });
  }

  Future<void> reportarRetraso() async {
    timer?.cancel();
    setState(() => jornadaActiva = false);

    await guardarEvento(
      tipo: 'DELAY',
      titulo: 'Retraso reportado',
      mensaje: 'La ruta presenta un retraso aproximado de 25 minutos.',
      prioridad: 2,
      nuevoEstado: 'Retraso operativo',
    );
  }

  Future<void> reportarAveria() async {
    timer?.cancel();
    setState(() => jornadaActiva = false);

    await guardarEvento(
      tipo: 'MECHANICAL_FAILURE',
      titulo: 'Avería mecánica reportada',
      mensaje: 'El camión ${rutaSeleccionada.truckId} presenta una falla mecánica. Se requiere apoyo logístico.',
      prioridad: 3,
      nuevoEstado: 'Avería mecánica',
    );
  }

  Future<void> reportarIncidenciaLigera() async {
    await guardarEvento(
      tipo: 'INCIDENT',
      titulo: 'Incidencia en ruta',
      mensaje: 'Se registró una incidencia menor: obstrucción vial o punto con exceso de residuos.',
      prioridad: 2,
      nuevoEstado: 'Incidencia registrada',
    );
  }

  Future<void> finalizarJornada() async {
    timer?.cancel();

    setState(() {
      jornadaActiva = false;
      paso = rutaSeleccionada.positions.length - 1;
      estadoRuta = 'Servicio finalizado';
    });

    await guardarEvento(
      tipo: 'ROUTE_COMPLETED',
      titulo: 'Servicio finalizado',
      mensaje: 'El operador finalizó la ruta ${rutaSeleccionada.routeId}.',
      prioridad: 1,
      nuevoEstado: 'Servicio finalizado',
    );
  }

  void cambiarRuta(RutaOficial? ruta) {
    if (ruta == null) return;
    timer?.cancel();

    setState(() {
      rutaSeleccionada = ruta;
      paso = 0;
      jornadaActiva = false;
      estadoRuta = 'Pendiente de iniciar';
    });
  }

  Color colorEstado() {
    if (estadoRuta.contains('Avería')) return AppColors.red;
    if (estadoRuta.contains('Retraso') || estadoRuta.contains('Incidencia')) return AppColors.orange;
    if (estadoRuta.contains('finalizado')) return Colors.blueGrey;
    if (jornadaActiva) return AppColors.green;
    return Colors.grey;
  }

  Widget statCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      height: 58,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label, style: const TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800)),
      ),
    );
  }

  Widget timelineItem(int index) {
    final p = rutaSeleccionada.positions[index];
    final actual = index == paso;
    final done = index < paso;

    Color color = Colors.grey.shade300;
    IconData icon = Icons.radio_button_unchecked;

    if (done) {
      color = AppColors.green;
      icon = Icons.check;
    }

    if (actual) {
      color = colorEstado();
      icon = Icons.local_shipping;
    }

    String titulo = 'Punto operativo ${p.positionId}';
    if (p.positionId == 1) titulo = 'Salida de base';
    if (p.positionId == 2) titulo = 'Ruta en tránsito';
    if (p.positionId == 4) titulo = 'Punto previo a zona ciudadana';
    if (p.positionId == 5) titulo = 'Recolección principal';
    if (p.positionId == 8) titulo = 'Retorno a base';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              backgroundColor: color,
              radius: 18,
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            if (index != rutaSeleccionada.positions.length - 1)
              Container(
                width: 4,
                height: 42,
                color: done ? AppColors.green : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    fontSize: actual ? 18.5 : 16.5,
                    fontWeight: actual ? FontWeight.w900 : FontWeight.w600,
                  ),
                ),
                Text(
                  'positionId ${p.positionId} · Velocidad ${p.speed} km/h',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget alertaItem(AlertaOperativa alerta) {
    Color color = AppColors.green;
    IconData icon = Icons.check_circle;

    if (alerta.prioridad == 2) {
      color = AppColors.orange;
      icon = Icons.timer;
    }

    if (alerta.prioridad >= 3) {
      color = AppColors.red;
      icon = Icons.warning_amber;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(alerta.titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${alerta.routeId} · Camión ${alerta.truckId} · ${alerta.fecha}\n${alerta.mensaje}'),
        isThreeLine: true,
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estadoColor = colorEstado();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel del operador'),
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              timer?.cancel();
              ApiSession.clear();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: cargarHistorial,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppCard(
              color: const Color(0xFFEAF6EA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.green,
                        child: Icon(Icons.engineering, color: Colors.white, size: 36),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(nombreOperador, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
                            const Text('Turno operativo · Unidad municipal'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<RutaOficial>(
                    value: rutaSeleccionada,
                    decoration: const InputDecoration(
                      labelText: 'Ruta asignada',
                      prefixIcon: Icon(Icons.route),
                      fillColor: Colors.white,
                    ),
                    items: rutasAsignadas.map((r) {
                      return DropdownMenuItem(
                        value: r,
                        child: Text('${r.routeId} · Camión ${r.truckId}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: cambiarRuta,
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: estadoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: estadoColor.withOpacity(0.35)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.sensors, color: estadoColor, size: 34),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Estado actual de la jornada', style: TextStyle(fontWeight: FontWeight.w700)),
                              Text(
                                estadoRuta,
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: estadoColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Row(
              children: [
                statCard(icon: Icons.local_shipping, title: 'Camión', value: '${rutaSeleccionada.truckId}', color: AppColors.green),
                statCard(icon: Icons.schedule, title: 'Horario', value: horarioOperador, color: Colors.indigo),
              ],
            ),
            Row(
              children: [
                statCard(icon: Icons.pin_drop, title: 'Punto', value: '${posicionActual.positionId}/8', color: AppColors.orange),
                statCard(icon: Icons.speed, title: 'Velocidad', value: '${posicionActual.speed} km/h', color: Colors.blueGrey),
              ],
            ),

            const SectionTitle('Control rápido', subtitle: 'Eventos que el operador puede enviar al sistema.'),
            actionButton(
              icon: Icons.play_arrow,
              label: jornadaActiva ? 'Jornada en curso' : 'Iniciar jornada',
              color: jornadaActiva ? Colors.grey : AppColors.green,
              onPressed: jornadaActiva ? () {} : iniciarJornada,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: actionButton(
                    icon: Icons.timer,
                    label: 'Retraso',
                    color: AppColors.orange,
                    onPressed: reportarRetraso,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: actionButton(
                    icon: Icons.car_crash,
                    label: 'Avería',
                    color: AppColors.red,
                    onPressed: reportarAveria,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: reportarIncidenciaLigera,
                      icon: const Icon(Icons.report_problem),
                      label: const Text('Incidencia'),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: finalizarJornada,
                      icon: const Icon(Icons.flag),
                      label: const Text('Finalizar'),
                    ),
                  ),
                ),
              ],
            ),

            const SectionTitle('Avance operativo', subtitle: 'Visible para el operador; el ciudadano solo recibe eventos y ETA.'),
            AppCard(
              child: Column(
                children: [
                  LinearProgressIndicator(value: progreso, minHeight: 12),
                  const SizedBox(height: 12),
                  Text(
                    '${rutaSeleccionada.routeId} · ${rutaSeleccionada.name}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Horario de trabajo: $horarioOperador · Estado JSON: ${rutaSeleccionada.status}',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ...List.generate(rutaSeleccionada.positions.length, timelineItem),

            const SectionTitle('Historial de alertas enviadas'),
            if (historial.isEmpty)
              const AppCard(child: Text('Aún no hay alertas operativas registradas.'))
            else
              ...historial.take(8).map(alertaItem),

            const SizedBox(height: 18),
            const Text(
              'Diseño por roles: el operador reporta eventos operativos; el ciudadano recibe mensajes accionables sin rastrear el camión en tiempo real.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// ADMINISTRADOR CONCEPTUAL / FUTURO
// =======================================================

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController tab;
  List<AlertaOperativa> alertas = [];
  List<Map<String, dynamic>> reportes = [];
  List<Servicio> servicios = [];
  List<RutaOficial> rutas = [];

  @override
  void initState() {
    super.initState();
    tab = TabController(length: 4, vsync: this);
    cargar();
  }

  Future<void> cargar() async {
    List<AlertaOperativa> a = [];
    List<Map<String, dynamic>> r = [];

    try {
      a = await ApiService.adminAlerts();
    } catch (_) {
      a = await Repo.cargarAlertasOperativas();
    }

    try {
      final backendReports = await ApiService.adminReports();
      r = backendReports.map((item) {
        return {
          'texto': '[${item['type'] ?? 'Reporte'}] ${item['comment'] ?? ''}',
          'fecha': item['created_at'] ?? '',
          'estado': item['status'] ?? 'NUEVO',
        };
      }).toList();
    } catch (_) {
      r = await Repo.cargarSugerencias();
    }

    final s = await Repo.cargarServicios();

    if (!mounted) return;

    setState(() {
      alertas = a;
      reportes = r;
      servicios = s;
      rutas = Repo.rutas();
    });
  }

  int get alertasCriticas => alertas.where((a) => a.prioridad >= 3).length;
  int get retrasos => alertas.where((a) => a.tipo == 'DELAY').length;
  int get averias => alertas.where((a) => a.tipo == 'MECHANICAL_FAILURE').length;

  double get promedioServicio {
    if (servicios.isEmpty) return 0;
    final total = servicios.fold<int>(0, (sum, s) => sum + s.estrellas);
    return total / servicios.length;
  }

  Future<void> limpiarDemo() async {
    await Repo.limpiarAlertasOperativas();
    await cargar();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Alertas operativas limpiadas para la demo')),
    );
  }

  Widget kpiCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Widget alertaTile(AlertaOperativa alerta) {
    Color color = AppColors.green;
    IconData icon = Icons.check_circle;

    if (alerta.prioridad == 2) {
      color = AppColors.orange;
      icon = Icons.timer;
    }

    if (alerta.prioridad >= 3) {
      color = AppColors.red;
      icon = Icons.warning_amber;
    }

    return Card(
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(alerta.titulo, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('${alerta.routeId} · Camión ${alerta.truckId} · ${alerta.fecha}'),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(alerta.mensaje, style: const TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Chip(label: Text('Tipo: ${alerta.tipo}')),
              const SizedBox(width: 8),
              Chip(label: Text('Prioridad ${alerta.prioridad}')),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Operador: ${alerta.operador}',
              style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget reporteTile(Map<String, dynamic> reporte) {
    final texto = (reporte['texto'] ?? '').toString();
    final fechaRaw = (reporte['fecha'] ?? '').toString();
    final fecha = fechaRaw.length >= 16 ? fechaRaw.substring(0, 16).replaceAll('T', ' ') : fechaRaw;

    IconData icon = Icons.feedback;
    Color color = AppColors.green;

    if (texto.toLowerCase().contains('camión no pasó') || texto.toLowerCase().contains('no pasó')) {
      icon = Icons.cancel;
      color = AppColors.red;
    } else if (texto.toLowerCase().contains('retraso')) {
      icon = Icons.timer;
      color = AppColors.orange;
    }

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(texto, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(fecha.isEmpty ? 'Reporte ciudadano' : fecha),
        trailing: const Chip(label: Text('Nuevo')),
      ),
    );
  }

  Widget rutaTile(RutaOficial ruta) {
    final inicio = ruta.positions.first.timestamp.substring(11, 16);
    final fin = ruta.positions.last.timestamp.substring(11, 16);
    final estadoColor = ruta.status == 'EN_RUTA' ? AppColors.green : Colors.grey;

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: estadoColor.withOpacity(0.12),
          child: Icon(Icons.local_shipping, color: estadoColor),
        ),
        title: Text('${ruta.routeId} · ${ruta.name}', style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('Camión ${ruta.truckId} · $inicio - $fin · ${ruta.positions.length} puntos'),
        trailing: Chip(
          label: Text(ruta.status),
          backgroundColor: estadoColor.withOpacity(0.12),
        ),
      ),
    );
  }

  Widget operatorTile(String name, String ruta, String camion, String status, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(Icons.engineering, color: color),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('$ruta · $camion'),
        trailing: Chip(label: Text(status)),
      ),
    );
  }

  Widget resumenTab() {
    return RefreshIndicator(
      onRefresh: cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            color: AppColors.softGreen,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.green,
                  child: Icon(Icons.admin_panel_settings, color: Colors.white, size: 40),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Centro de control logístico', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
                      SizedBox(height: 4),
                      Text('Panel administrador para supervisar rutas, operadores, camiones y reportes.'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              kpiCard(icon: Icons.alt_route, title: 'Rutas', value: '${rutas.length}', color: AppColors.green),
              kpiCard(icon: Icons.warning_amber, title: 'Críticas', value: '$alertasCriticas', color: AppColors.red),
            ],
          ),
          Row(
            children: [
              kpiCard(icon: Icons.feedback, title: 'Reportes', value: '${reportes.length}', color: AppColors.orange),
              kpiCard(icon: Icons.star, title: 'Servicio', value: promedioServicio == 0 ? '—' : promedioServicio.toStringAsFixed(1), color: Colors.amber),
            ],
          ),
          const SectionTitle('Operadores en turno'),
          operatorTile('José Martínez', 'RUTA-01', 'Camión 101', 'En ruta', AppColors.green),
          operatorTile('María López', 'RUTA-03', 'Camión 103', averias > 0 ? 'Requiere apoyo' : 'Disponible', averias > 0 ? AppColors.red : AppColors.orange),
          operatorTile('Carlos Ramírez', 'RUTA-05', 'Camión 105', retrasos > 0 ? 'Retraso' : 'Programado', retrasos > 0 ? AppColors.orange : Colors.blueGrey),
          const SectionTitle('Acciones administrativas'),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: cargar,
                    icon: const Icon(Icons.sync),
                    label: const Text('Actualizar'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: limpiarDemo,
                    icon: const Icon(Icons.cleaning_services),
                    label: const Text('Limpiar demo'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget alertasTab() {
    return RefreshIndicator(
      onRefresh: cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Alertas operativas', subtitle: 'Eventos enviados desde la interfaz del operador.'),
          if (alertas.isEmpty)
            const AppCard(child: Text('Todavía no hay alertas. Entra como operador y reporta una avería o retraso.'))
          else
            ...alertas.map(alertaTile),
        ],
      ),
    );
  }

  Widget reportesTab() {
    return RefreshIndicator(
      onRefresh: cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Reportes ciudadanos', subtitle: 'Quejas y sugerencias enviadas desde el buzón.'),
          if (reportes.isEmpty)
            const AppCard(child: Text('Todavía no hay reportes ciudadanos.'))
          else
            ...reportes.map(reporteTile),
          const SectionTitle('Calificaciones recientes'),
          if (servicios.isEmpty)
            const AppCard(child: Text('Todavía no hay calificaciones registradas.'))
          else
            ...servicios.map((s) => Card(
                  child: ListTile(
                    leading: const Icon(Icons.star, color: Colors.amber),
                    title: Text(s.domicilio, style: const TextStyle(fontWeight: FontWeight.w800)),
                    subtitle: Text('${s.estrellas}/5 · ${s.fecha}'),
                  ),
                )),
        ],
      ),
    );
  }

  Widget rutasTab() {
    return RefreshIndicator(
      onRefresh: cargar,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle('Rutas y flotilla', subtitle: 'Vista logística general. En producción aquí se reasignan camiones.'),
          ...rutas.map(rutaTile),
          const SizedBox(height: 16),
          const Text(
            'En el backend real este módulo tendría permisos RBAC para crear rutas, asignar operadores y despachar unidades de reemplazo.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administrador'),
        actions: [
          IconButton(onPressed: cargar, icon: const Icon(Icons.refresh)),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () {
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginPage()));
            },
            icon: const Icon(Icons.logout),
          ),
        ],
        bottom: TabBar(
          controller: tab,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Resumen'),
            Tab(icon: Icon(Icons.warning_amber), text: 'Alertas'),
            Tab(icon: Icon(Icons.feedback), text: 'Reportes'),
            Tab(icon: Icon(Icons.alt_route), text: 'Rutas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: tab,
        children: [
          resumenTab(),
          alertasTab(),
          reportesTab(),
          rutasTab(),
        ],
      ),
    );
  }
}




// =======================================================
// BUZÓN
// =======================================================

class BuzonPage extends StatefulWidget {
  const BuzonPage({super.key});

  @override
  State<BuzonPage> createState() => _BuzonPageState();
}

class _BuzonPageState extends State<BuzonPage> {
  final comentario = TextEditingController();
  String tipoReporte = 'Sugerencia';

  Future<void> enviar() async {
    final texto = comentario.text.trim();

    if (texto.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe tu comentario antes de enviarlo')),
      );
      return;
    }

    await Repo.guardarSugerencia('[$tipoReporte] $texto');
    comentario.clear();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reporte enviado correctamente')),
    );
  }

  void limpiar() {
    setState(() {
      tipoReporte = 'Sugerencia';
      comentario.clear();
    });
  }

  @override
  void dispose() {
    comentario.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buzón de sugerencias'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            color: AppColors.softGreen,
            child: Column(
              children: const [
                Icon(Icons.feedback, size: 72, color: AppColors.green),
                SizedBox(height: 12),
                Text(
                  'Tu opinión ayuda a mejorar el servicio',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 8),
                Text(
                  'Envía reportes, quejas o sugerencias sobre la recolección de basura.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16.5),
                ),
              ],
            ),
          ),
          const SectionTitle('Tipo de reporte'),
          DropdownButtonFormField<String>(
            value: tipoReporte,
            decoration: const InputDecoration(
              labelText: 'Selecciona una opción',
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'Sugerencia', child: Text('Sugerencia')),
              DropdownMenuItem(value: 'Queja', child: Text('Queja')),
              DropdownMenuItem(value: 'Retraso del camión', child: Text('Retraso del camión')),
              DropdownMenuItem(value: 'Camión no pasó', child: Text('Camión no pasó')),
              DropdownMenuItem(value: 'Basura no recolectada', child: Text('Basura no recolectada')),
            ],
            onChanged: (value) {
              setState(() {
                tipoReporte = value ?? 'Sugerencia';
              });
            },
          ),
          const SectionTitle('Describe el problema'),
          TextField(
            controller: comentario,
            minLines: 5,
            maxLines: 8,
            decoration: const InputDecoration(
              labelText: 'Comentario',
              hintText: 'Ejemplo: el camión no pasó por mi domicilio el día indicado',
              prefixIcon: Icon(Icons.edit_note),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: enviar,
              icon: const Icon(Icons.send),
              label: const Text('Enviar reporte', style: TextStyle(fontSize: 17)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: limpiar,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Limpiar formulario', style: TextStyle(fontSize: 17)),
            ),
          ),
        ],
      ),
    );
  }
}

// =======================================================
// GUÍA
// ======================= GUÍA =======================

class GuiaPage extends StatelessWidget {
  const GuiaPage({super.key});

  Widget basuraCard(
    BuildContext context,
    String titulo,
    String ejemplo,
    String detalle,
    String consejo,
    IconData icono,
    Color color,
    String imagen,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleGuiaPage(
                titulo: titulo,
                detalle: detalle,
                consejo: consejo,
                icono: icono,
                color: color,
                imagen: imagen,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icono, color: color, size: 34),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 27,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      ejemplo,
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.grey.shade700,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 26, color: Colors.grey.shade700),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guía de separación'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SectionTitle(
            'Separa tu basura fácil',
            subtitle: 'Una guía rápida para reducir contaminación.',
          ),
          const SizedBox(height: 10),
          basuraCard(
            context,
            'Orgánicos',
            'Comida, frutas, verduras',
            'Son residuos naturales. Separarlos ayuda a hacer composta y evita malos olores.',
            'Usa bolsas o contenedores separados y saca tus residuos únicamente dentro del horario indicado por la app.',
            Icons.eco,
            AppColors.green,
            'assets/images/Organico.jpeg',
          ),
          basuraCard(
            context,
            'Reciclables',
            'Cartón, plástico, vidrio',
            'Son materiales que pueden volver a utilizarse si se entregan limpios y secos. Separarlos reduce la basura que llega al relleno sanitario.',
            'Aplasta botellas y cartón para ahorrar espacio. Evita mezclarlos con comida, grasa o líquidos.',
            Icons.recycling,
            Colors.blue,
            'assets/images/Reciclables.jpeg',
          ),
          basuraCard(
            context,
            'Sanitarios',
            'Papel higiénico, pañales',
            'Estos residuos pueden contener bacterias o fluidos. No deben mezclarse con reciclables ni orgánicos.',
            'Colócalos en una bolsa bien cerrada para evitar malos olores y contacto directo con otras personas.',
            Icons.delete,
            Colors.purple,
            'assets/images/Sanitarios.jpeg',
          ),
          basuraCard(
            context,
            'Especiales',
            'Pilas, electrónicos, aceite',
            'Estos residuos pueden contaminar agua, suelo o aire si se mezclan con basura común. Necesitan manejo especial.',
            'No los tires con la basura normal. Guárdalos aparte y llévalos a puntos de recolección autorizados.',
            Icons.warning,
            AppColors.orange,
            'assets/images/Especiales.jpeg',
          ),
        ],
      ),
    );
  }
}

class DetalleGuiaPage extends StatelessWidget {
  final String titulo;
  final String detalle;
  final String consejo;
  final IconData icono;
  final Color color;
  final String imagen;

  const DetalleGuiaPage({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.consejo,
    required this.icono,
    required this.color,
    required this.imagen,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          AppCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 64,
                  backgroundColor: color.withOpacity(0.12),
                  child: Icon(icono, size: 76, color: color),
                ),
                const SizedBox(height: 28),
                Text(
                  titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  detalle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            child: Column(
              children: [
                const Text(
                  'Apoyo visual',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 18),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.asset(
                    imagen,
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                    alignment: Alignment.topCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 320,
                        width: double.infinity,
                        alignment: Alignment.center,
                        color: Colors.grey.shade200,
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'No se encontró la imagen:\n$imagen\n\nRevisa assets/images/ y pubspec.yaml',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          AppCard(
            color: AppColors.softGreen,
            child: Column(
              children: [
                Icon(Icons.info_outline, size: 54, color: color),
                const SizedBox(height: 12),
                const Text(
                  'Consejo práctico',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 10),
                Text(
                  consejo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
