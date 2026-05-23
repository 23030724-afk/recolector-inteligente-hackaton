import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  void entrar() {
    if (email.text.trim().isEmpty || pass.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa correo y contraseña')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomePage()),
    );
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
                      onPressed: entrar,
                      icon: const Icon(Icons.login),
                      label: const Text('Iniciar sesión', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      email.text = 'demo@correo.com';
                      pass.text = '123456';
                    },
                    child: const Text('Usar cuenta demo'),
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

  @override
  void initState() {
    super.initState();
    cargar();
  }

  Future<void> cargar() async {
    final d = await Repo.cargarDomicilios();
    final s = await Repo.cargarServicios();

    if (!mounted) return;

    setState(() {
      domicilios = d;
      servicios = s;
    });
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

  const MapPickerPage({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late LatLng selected;

  @override
  void initState() {
    super.initState();
    selected = LatLng(widget.initialLat ?? 20.5210, widget.initialLng ?? -100.8210);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seleccionar domicilio'),
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: selected,
              initialZoom: 14,
              onTap: (tapPosition, point) {
                setState(() => selected = point);
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
                    point: selected,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_pin,
                      color: AppColors.red,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 18,
            child: AppCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Toca el mapa para colocar tu domicilio',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${selected.latitude.toStringAsFixed(6)} · Lng: ${selected.longitude.toStringAsFixed(6)}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.pop(context, selected);
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Usar esta ubicación'),
                    ),
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
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: latPrincipal,
          initialLng: lngPrincipal,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      latPrincipal = result.latitude;
      lngPrincipal = result.longitude;
    });
  }

  Future<void> abrirMapaExtra() async {
    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerPage(
          initialLat: latExtra,
          initialLng: lngExtra,
        ),
      ),
    );

    if (result == null) return;

    setState(() {
      latExtra = result.latitude;
      lngExtra = result.longitude;
    });
  }

  Future<void> guardarRegistro() async {
    if (nombre.text.trim().isEmpty || telefono.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nombre y teléfono son obligatorios')),
      );
      return;
    }

    await Repo.guardarUsuario(
      nombre: nombre.text.trim(),
      telefono: telefono.text.trim(),
      correo: correo.text.trim(),
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
    if (direccionExtra.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el domicilio a agregar')),
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

  Widget selectorMapa({
    required VoidCallback onPressed,
    required double? lat,
    required double? lng,
  }) {
    return AppCard(
      color: AppColors.softGreen,
      child: Column(
        children: [
          const Text(
            'Ubicación en mapa',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            lat == null || lng == null
                ? 'Aún no has seleccionado ubicación.'
                : 'Lat: ${lat.toStringAsFixed(6)} · Lng: ${lng.toStringAsFixed(6)}',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.map),
              label: const Text('Abrir mapa'),
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
                onChanged: (value) {
                  coloniaPrincipal.text = value ?? '';
                },
              ),
              const SizedBox(height: 14),
              selectorMapa(
                onPressed: abrirMapaPrincipal,
                lat: latPrincipal,
                lng: lngPrincipal,
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
                onChanged: (value) {
                  coloniaExtra.text = value ?? '';
                },
              ),
              const SizedBox(height: 14),
              selectorMapa(
                onPressed: abrirMapaExtra,
                lat: latExtra,
                lng: lngExtra,
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
