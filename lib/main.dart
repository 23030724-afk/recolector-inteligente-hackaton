import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const RecolectorApp());
}

// ======================= JSON LOCAL DE RUTAS =======================

const String rutasJson = '''
[
  {
    "id": "centro",
    "zona": "Centro",
    "keywords": ["centro", "luna", "calle luna", "primer cuadro"],
    "dias": ["Lunes", "Miércoles", "Viernes"],
    "inicio": "07:00 AM",
    "fin": "09:00 AM",
    "proxima": "Lunes",
    "eta": "15 minutos",
    "consejo": "Saca tus residuos 15 minutos antes de la llegada estimada."
  },
  {
    "id": "norte",
    "zona": "Norte",
    "keywords": ["norte", "industrial", "negocio", "bodega"],
    "dias": ["Martes", "Jueves"],
    "inicio": "08:00 AM",
    "fin": "10:00 AM",
    "proxima": "Martes",
    "eta": "20 minutos",
    "consejo": "Compacta cartón y separa reciclables antes de la recolección."
  },
  {
    "id": "sur",
    "zona": "Sur",
    "keywords": ["sur", "jardines", "flores"],
    "dias": ["Miércoles", "Sábado"],
    "inicio": "09:00 AM",
    "fin": "11:00 AM",
    "proxima": "Miércoles",
    "eta": "18 minutos",
    "consejo": "Mantén los residuos cerrados para evitar dispersión."
  },
  {
    "id": "poniente",
    "zona": "Poniente",
    "keywords": ["poniente", "sol", "atardecer", "segunda casa"],
    "dias": ["Lunes", "Jueves", "Sábado"],
    "inicio": "10:00 AM",
    "fin": "12:00 PM",
    "proxima": "Jueves",
    "eta": "25 minutos",
    "consejo": "Coloca los residuos en un punto visible y accesible."
  },
  {
    "id": "general",
    "zona": "General",
    "keywords": [],
    "dias": ["Lunes", "Jueves"],
    "inicio": "08:00 AM",
    "fin": "10:00 AM",
    "proxima": "Lunes",
    "eta": "20 minutos",
    "consejo": "Registra calle y colonia para mejorar la asignación de ruta."
  }
]
''';

// ======================= MODELOS =======================

class Ruta {
  final String id;
  final String zona;
  final List<String> keywords;
  final List<String> dias;
  final String inicio;
  final String fin;
  final String proxima;
  final String eta;
  final String consejo;

  Ruta({
    required this.id,
    required this.zona,
    required this.keywords,
    required this.dias,
    required this.inicio,
    required this.fin,
    required this.proxima,
    required this.eta,
    required this.consejo,
  });

  factory Ruta.fromJson(Map<String, dynamic> json) {
    return Ruta(
      id: json['id'] ?? '',
      zona: json['zona'] ?? '',
      keywords: List<String>.from(json['keywords'] ?? []),
      dias: List<String>.from(json['dias'] ?? []),
      inicio: json['inicio'] ?? '',
      fin: json['fin'] ?? '',
      proxima: json['proxima'] ?? '',
      eta: json['eta'] ?? '',
      consejo: json['consejo'] ?? '',
    );
  }

  String get diasTexto => dias.join(', ');
  String get horario => '$inicio - $fin';
}

class Domicilio {
  final String tipo;
  final String direccion;
  final String colonia;

  Domicilio({
    required this.tipo,
    required this.direccion,
    required this.colonia,
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
      };

  factory Domicilio.fromJson(Map<String, dynamic> json) {
    return Domicilio(
      tipo: json['tipo'] ?? 'Domicilio',
      direccion: json['direccion'] ?? '',
      colonia: json['colonia'] ?? '',
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

// ======================= REPOSITORIO =======================

class Repo {
  static List<Ruta> rutas() {
    final raw = jsonDecode(rutasJson) as List;
    return raw.map((e) => Ruta.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  static Ruta rutaDe(Domicilio? domicilio) {
    final todas = rutas();
    final general = todas.firstWhere((r) => r.id == 'general');

    if (domicilio == null) return general;

    final texto = domicilio.busqueda;

    for (final ruta in todas) {
      if (ruta.id == 'general') continue;

      for (final key in ruta.keywords) {
        if (texto.contains(key.toLowerCase())) {
          return ruta;
        }
      }
    }

    return general;
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
    final raw = prefs.getString('domicilios_v3');

    if (raw != null && raw.isNotEmpty) {
      final list = jsonDecode(raw) as List;
      return list.map((e) => Domicilio.fromJson(Map<String, dynamic>.from(e))).toList();
    }

    final principal = prefs.getString('domicilio') ?? '';
    final colonia = prefs.getString('colonia') ?? '';
    final negocio = prefs.getString('negocio') ?? '';
    final segundaCasa = prefs.getString('segundaCasa') ?? '';
    final otro = prefs.getString('otroDomicilio') ?? '';

    final domicilios = <Domicilio>[];

    if (principal.trim().isNotEmpty) {
      domicilios.add(Domicilio(tipo: 'Casa principal', direccion: principal, colonia: colonia));
    }
    if (negocio.trim().isNotEmpty) {
      domicilios.add(Domicilio(tipo: 'Negocio', direccion: negocio, colonia: ''));
    }
    if (segundaCasa.trim().isNotEmpty) {
      domicilios.add(Domicilio(tipo: 'Segunda casa', direccion: segundaCasa, colonia: ''));
    }
    if (otro.trim().isNotEmpty) {
      domicilios.add(Domicilio(tipo: 'Otro domicilio', direccion: otro, colonia: ''));
    }

    return domicilios;
  }

  static Future<void> guardarDomicilios(List<Domicilio> domicilios) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'domicilios_v3',
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

// ======================= ESTILO =======================

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
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
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

// ======================= LOGIN =======================

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
                    'Recolección privada, horarios claros y seguimiento sin exponer ubicación exacta.',
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

// ======================= HOME =======================

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
                        const Text('Próxima recolección', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          '${ruta.proxima} · ${ruta.horario}',
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          principal == null
                              ? 'Registra tu domicilio para personalizar la ruta.'
                              : 'Zona ${ruta.zona} · ${principal.tipo}',
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
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(height: 6),
                        const Text('Última calificación', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text(
                          servicios.isEmpty ? '—' : '${servicios.first.estrellas}/5',
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
                        ),
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
              subtitle: 'Registra información, domicilios, días y horarios.',
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const DatosPage()));
                cargar();
              },
            ),
            menuCard(
              icon: Icons.local_shipping,
              title: 'Seguimiento de basura',
              subtitle: 'Selecciona domicilio y simula eventos del camión.',
              onTap: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SeguimientoPage()));
                cargar();
              },
            ),
            menuCard(
              icon: Icons.recycling,
              title: 'Guía para la separación',
              subtitle: 'Clasifica residuos orgánicos, reciclables y especiales.',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const GuiaPage()));
              },
            ),
            menuCard(
              icon: Icons.feedback,
              title: 'Buzón de sugerencias',
              subtitle: 'Envía quejas, reportes o comentarios del servicio.',
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const BuzonPage()));
              },
            ),
            if (servicios.isNotEmpty) ...[
              const SectionTitle('Último servicio'),
              AppCard(
                child: ListTile(
                  leading: const Icon(Icons.history, color: AppColors.green),
                  title: Text(servicios.first.domicilio),
                  subtitle: Text('Calificación ${servicios.first.estrellas}/5 · ${servicios.first.fecha}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ======================= BUZÓN =======================

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
              label: const Text(
                'Enviar reporte',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 54,
            child: OutlinedButton.icon(
              onPressed: limpiar,
              icon: const Icon(Icons.cleaning_services),
              label: const Text(
                'Limpiar formulario',
                style: TextStyle(fontSize: 17),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ======================= DATOS =======================

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
    }

    if (!mounted) return;

    setState(() {
      domicilios = ds;
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
    );

    final lista = [...domicilios, nuevo];
    await Repo.guardarDomicilios(lista);

    if (!mounted) return;

    setState(() {
      domicilios = lista;
      direccionExtra.clear();
      coloniaExtra.clear();
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
        ),
      );
    }

    if (lista.isEmpty) {
      setState(() {
        resultado = 'Registra al menos un domicilio para desplegar días y horarios.';
      });
      return;
    }

    final buffer = StringBuffer();

    for (final d in lista) {
      final ruta = Repo.rutaDe(d);
      buffer.writeln(d.etiqueta);
      buffer.writeln('Zona: ${ruta.zona}');
      buffer.writeln('Días: ${ruta.diasTexto}');
      buffer.writeln('Horario: ${ruta.horario}');
      buffer.writeln('Próxima recolección: ${ruta.proxima}');
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
              campo(label: 'RFC (opcional)', controller: rfc, icon: Icons.badge),
              const SectionTitle('Casa principal'),
              campo(label: 'Domicilio principal', controller: direccionPrincipal, icon: Icons.home),
              campo(label: 'Colonia', controller: coloniaPrincipal, icon: Icons.location_city),
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
                  label: const Text('Simular días y horarios', style: TextStyle(fontSize: 17)),
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
              campo(label: 'Colonia o referencia', controller: coloniaExtra, icon: Icons.location_city),
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

                  return Card(
                    child: ListTile(
                      leading: const Icon(Icons.home_work, color: AppColors.green),
                      title: Text(d.etiqueta, style: const TextStyle(fontWeight: FontWeight.w800)),
                      subtitle: Text('Zona ${ruta.zona} · ${ruta.diasTexto} · ${ruta.horario}'),
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

// ======================= SEGUIMIENTO =======================

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

  final List<String> pasosBase = const [
    'Recolección programada',
    'Camión cercano',
    'Llegando a tu zona',
    'Recolección en proceso',
    'Servicio finalizado',
  ];

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

  Ruta get ruta => Repo.rutaDe(seleccionado);

  List<String> get pasos {
    final lista = [...pasosBase];

    if (evento == EventoCamion.retraso) {
      lista.insert(2, 'Retraso técnico · Tiempo estimado: 25 minutos');
    }

    if (evento == EventoCamion.averia) {
      lista.insert(2, 'Camión averiado · Notificación enviada al celular');
    }

    return lista;
  }

  bool get finalizado => paso >= pasos.length - 1;
  String get estado => pasos[paso.clamp(0, pasos.length - 1)];
  double get progreso => (paso + 1) / pasos.length;

  String get tituloEstado {
    if (estado.startsWith('Retraso')) return 'Retraso técnico: 25 minutos';
    if (estado.startsWith('Camión averiado')) return 'Camión averiado';
    if (estado == 'Camión cercano') return 'El camión pasará en ${ruta.eta}';
    return estado;
  }

  String get mensajeEstado {
    if (seleccionado == null) {
      return 'Primero registra un domicilio en Datos personales.';
    }

    if (estado.startsWith('Retraso')) {
      return 'Conserva tus residuos en casa hasta que se reactive el servicio.';
    }

    if (estado.startsWith('Camión averiado')) {
      return 'Se enviará una notificación al teléfono registrado cuando haya unidad de reemplazo.';
    }

    if (estado == 'Recolección programada') {
      return 'Próxima recolección el día ${ruta.proxima}, de ${ruta.horario}.';
    }

    if (estado == 'Camión cercano' || estado == 'Llegando a tu zona') {
      return ruta.consejo;
    }

    if (estado == 'Recolección en proceso') {
      return 'Mantén despejada la banqueta y evita perseguir al camión.';
    }

    return 'Servicio concluido. Ya puedes calificar de 1 a 5 estrellas.';
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
      if (paso >= pasos.length - 1) {
        t.cancel();
        return;
      }

      setState(() => paso++);

      if (finalizado) {
        t.cancel();
        aviso('Servicio finalizado', 'Ya puedes calificar el servicio.');
      }
    });
  }

  void simularRetraso() {
    if (seleccionado == null) {
      aviso('Sin domicilio', 'Selecciona un domicilio primero.');
      return;
    }

    timer?.cancel();

    setState(() {
      evento = EventoCamion.retraso;
      paso = 2;
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
      paso = 2;
    });

    aviso('Notificación enviada', 'El camión se averió. Se notificará al celular registrado.');
  }

  Future<void> finalizar() async {
    if (seleccionado == null) return;

    timer?.cancel();
    setState(() => paso = pasos.length - 1);

    aviso('Servicio finalizado', 'La calificación ya está habilitada.');
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
      SnackBar(content: Text('$titulo\n$mensaje'), duration: const Duration(seconds: 4)),
    );
  }

  Widget pasoItem(int index) {
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

      if (pasos[index].startsWith('Retraso')) {
        color = AppColors.orange;
        icon = Icons.timer;
      }

      if (pasos[index].startsWith('Camión averiado')) {
        color = AppColors.red;
        icon = Icons.warning;
      }
    }

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
            if (index != pasos.length - 1)
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
              pasos[index],
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
                  'Próxima recolección el día ${ruta.proxima}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Zona ${ruta.zona} · ${ruta.diasTexto}\nHorario estimado: ${ruta.horario}',
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
              ],
            ),
          ),
          const SectionTitle('Estado del servicio'),
          ...List.generate(pasos.length, pasoItem),
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
            'Privacidad: no se muestra mapa ni ubicación exacta del camión; solo eventos operativos y tiempos estimados.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }
}

// ======================= GUÍA =======================

class GuiaPage extends StatelessWidget {
  const GuiaPage({super.key});

  Widget basuraCard(
    BuildContext context,
    String titulo,
    String ejemplo,
    String detalle,
    IconData icono,
    Color color,
  ) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.12),
          child: Icon(icono, color: color),
        ),
        title: Text(titulo, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
        subtitle: Text(ejemplo),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetalleGuiaPage(
                titulo: titulo,
                detalle: detalle,
                icono: icono,
                color: color,
              ),
            ),
          );
        },
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
        padding: const EdgeInsets.all(16),
        children: [
          const SectionTitle(
            'Separa tu basura fácil',
            subtitle: 'Una guía rápida para reducir contaminación.',
          ),
          basuraCard(
            context,
            'Orgánicos',
            'Comida, frutas, verduras',
            'Son residuos naturales. Separarlos ayuda a hacer composta y evita malos olores.',
            Icons.eco,
            AppColors.green,
          ),
          basuraCard(
            context,
            'Reciclables',
            'Cartón, plástico, vidrio',
            'Pueden volver a usarse. Separarlos reduce basura y ayuda al medio ambiente.',
            Icons.recycling,
            Colors.blue,
          ),
          basuraCard(
            context,
            'Sanitarios',
            'Papel higiénico, pañales',
            'Deben ir separados porque pueden tener bacterias y no se reciclan.',
            Icons.delete,
            Colors.purple,
          ),
          basuraCard(
            context,
            'Especiales',
            'Pilas, electrónicos, aceite',
            'No deben mezclarse porque contaminan mucho y necesitan manejo especial.',
            Icons.warning,
            AppColors.orange,
          ),
        ],
      ),
    );
  }
}

class DetalleGuiaPage extends StatelessWidget {
  final String titulo;
  final String detalle;
  final IconData icono;
  final Color color;

  const DetalleGuiaPage({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(titulo)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: color.withOpacity(0.12),
                child: Icon(icono, size: 58, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                titulo,
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 16),
              Text(
                detalle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
