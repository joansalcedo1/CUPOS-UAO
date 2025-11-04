import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cuposuao/screens/login_page.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cuposuao/services/auth_services.dart';

class ConductorRegisterPage extends StatefulWidget {
  const ConductorRegisterPage({super.key});

  @override
  State<ConductorRegisterPage> createState() => _ConductorRegisterPageState();
}

class _ConductorRegisterPageState extends State<ConductorRegisterPage> {
  // ======= NUEVO: 2 formularios / 2 páginas =======
  final _pageCtrl = PageController();
  int _page = 0;

  final _formKeyPage1 = GlobalKey<FormState>();
  final _formKeyPage2 = GlobalKey<FormState>();

  // Colores
  static const kUAORed = Color(0xFFD61F14);
  static const kBG = Color(0xFFF6F7FB);

  // Controladores (página 1)
  final TextEditingController primerNombreCtrl = TextEditingController();
  final TextEditingController segundoNombreCtrl = TextEditingController();
  final TextEditingController primerApellidoCtrl = TextEditingController();
  final TextEditingController segundoApellidoCtrl = TextEditingController();
  final TextEditingController correoCtrl = TextEditingController();
  final TextEditingController contrasenaCtrl = TextEditingController();
  final TextEditingController identificacionCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();

  // Controladores (página 2)
  final TextEditingController placaCtrl = TextEditingController();
  final TextEditingController modeloCtrl = TextEditingController();
  final TextEditingController colorCtrl = TextEditingController();
  final TextEditingController anioCtrl = TextEditingController();

  //instancias de firebase: componente en auth_services
  final AuthService _authService = AuthService();

  // Estado común
  final List<String> _tiposId = const [
    'Tarjeta de Identidad',
    'Cédula de Ciudadanía',
    'Cédula de Extranjería',
    'Pasaporte',
    'PEP',
    'Otro',
  ];
  String? _tipoIdSeleccionado;
  bool _saving = false;
  ImageProvider? _avatarImage;
  bool _verContrasena = false;

  // ===== NUEVO: Placeholders adjuntos (UI) =====
  ImageProvider? licenciaImg;
  ImageProvider? vehiculoFrenteImg;
  ImageProvider? tarjetaPropImg;
  String? soatFileName;

  @override
  void dispose() {
    primerNombreCtrl.dispose();
    segundoNombreCtrl.dispose();
    primerApellidoCtrl.dispose();
    segundoApellidoCtrl.dispose();
    correoCtrl.dispose();
    contrasenaCtrl.dispose();
    identificacionCtrl.dispose();
    telefonoCtrl.dispose();

    placaCtrl.dispose();
    modeloCtrl.dispose();
    colorCtrl.dispose();
    anioCtrl.dispose();

    _pageCtrl.dispose();
    super.dispose();
  }

  // Image & file pickers
  // Nota: si tu entorno no tiene instalado el toolkit de Android Studio
  // o no configuraste el SDK/permissions, las funciones de cámara/galería
  // pueden no funcionar en el emulador o al construir para Android.
  // Aquí solo habilitamos la UI para seleccionar; no subimos ni guardamos archivos.
  final ImagePicker _picker = ImagePicker();

  /// Muestra el bottom sheet con acciones para elegir imagen o documento.
  /// [tipo] identifica el campo destino: 'avatar','licencia','vehiculo','tarjeta','soat'
  void _showEditPhotoSheet(String tipo, [String titulo = 'Editar foto']) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 6),
                Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (tipo == 'soat' || tipo == 'tarjeta' || tipo == 'licencia')
                  ListTile(
                    leading: const Icon(Icons.attach_file_outlined),
                    title: const Text('Seleccionar archivo (PDF, imagen)'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickDocument();
                    },
                  )
                else ...[
                  ListTile(
                    leading: const Icon(Icons.photo_library_outlined),
                    title: const Text('Elegir desde galería'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImage(ImageSource.gallery, tipo);
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.photo_camera_outlined),
                    title: const Text('Tomar foto'),
                    onTap: () async {
                      Navigator.pop(context);
                      await _pickImage(ImageSource.camera, tipo);
                    },
                  ),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Abre cámara o galería y guarda una vista previa en memoria (no persiste).
  Future<void> _pickImage(ImageSource source, String tipo) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return; // usuario canceló

      final file = File(picked.path);
      setState(() {
        final img = FileImage(file);
        if (tipo == 'avatar') {
          _avatarImage = img;
        } else if (tipo == 'licencia') {
          licenciaImg = img;
        } else if (tipo == 'vehiculo') {
          vehiculoFrenteImg = img;
        } else if (tipo == 'tarjeta') {
          tarjetaPropImg = img;
        }
      });
    } catch (e) {
      // Muestra feedback simple
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error abriendo la cámara/galería: $e')),
        );
      }
    }
  }

  /// Permite elegir un documento (SOAT). Guarda solo el nombre para UI.
  Future<void> _pickDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      );
      if (result == null) return; // canceló
      setState(() {
        soatFileName = result.files.single.name;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error seleccionando archivo: $e')),
        );
      }
    }
  }

  // -------- Validaciones ----------
  String? _noVacio(String? v, {required String campo}) {
    if (v == null || v.trim().isEmpty) return '$campo es obligatorio';
    return null;
  }

  String? _correoUAO(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Correo institucional es obligatorio';
    final regex = RegExp(r'^[A-Za-z0-9._%+-]+@uao\.edu\.co$');
    if (!regex.hasMatch(value)) return 'El correo debe terminar en @uao.edu.co';
    return null;
  }

  String? _contrasena(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'La contraseña es obligatoria';
    if (value.length < 6)
      return 'La contraseña debe tener al menos 6 caracteres';
    return null;
  }

  String? _telefono(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Número de teléfono es obligatorio';
    if (value.length < 7)
      return 'Número de teléfono demasiado corto (mín. 7 dígitos)';
    if (value.length > 15)
      return 'Número de teléfono demasiado largo (máx. 15 dígitos)';
    return null;
  }

  String? _identificacion(String? v) {
    if (_tipoIdSeleccionado == null)
      return 'Selecciona el tipo de identificación';
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Número de identificación es obligatorio';
    if (value.length < 6)
      return 'Número de identificación demasiado corto (mín. 6 dígitos)';
    return null;
  }

  // ===== Validaciones página 2 =====
  String? _placa(String? v) {
    final value = (v ?? '').trim().toUpperCase();
    if (value.isEmpty) return 'Placa es obligatoria';
    // Valida algo tipo ABC123 ó ABC12D (muy general)
    final rx = RegExp(r'^[A-Z]{3}\d{2,3}[A-Z0-9]?$');
    if (!rx.hasMatch(value)) return 'Formato de placa no válido';
    return null;
  }

  String? _modelo(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty)
      return 'Modelo del vehículo es obligatorio (ej. "Nissan March")';
    return null;
  }

  String? _color(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Color del vehículo es obligatorio';
    return null;
  }

  String? _anio(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Año del vehículo es obligatorio';
    if (!RegExp(r'^\d{4}$').hasMatch(value)) return 'Año debe tener 4 dígitos';
    final anio = int.tryParse(value) ?? 0;
    if (anio < 1980 || anio > DateTime.now().year + 1) {
      return 'Año fuera de rango';
    }
    return null;
  }

  InputDecoration _dec(
    String label, {
    IconData? icon,
    String? hint,
    bool compactError = true,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon) : null,
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE6E6E6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kUAORed, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kUAORed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kUAORed, width: 1.4),
      ),
      // Oculta texto y alto del error (solo borde rojo)
      errorStyle: compactError ? const TextStyle(height: 0, fontSize: 0) : null,
    );
  }

  // ===== Errores del form (solo página 1) para el popup existente =====
  List<String> _erroresDeFormularioPage1() {
    final errores = <String>[];
    void add(String? e) {
      if (e != null && e.trim().isNotEmpty) errores.add(e);
    }

    add(_noVacio(primerNombreCtrl.text, campo: 'Primer nombre'));
    add(_noVacio(primerApellidoCtrl.text, campo: 'Primer apellido'));
    add(_correoUAO(correoCtrl.text));
    add(_contrasena(contrasenaCtrl.text));
    add(
      _tipoIdSeleccionado == null
          ? 'Selecciona el tipo de identificación'
          : null,
    );
    add(_identificacion(identificacionCtrl.text));
    add(_telefono(telefonoCtrl.text));
    return errores.toSet().toList();
  }

  // ===== Errores del form (página 2) - solo campos texto/númricos =====
  List<String> _erroresDeFormularioPage2() {
    final errores = <String>[];
    void add(String? e) {
      if (e != null && e.trim().isNotEmpty) errores.add(e);
    }

    // Validaciones de la página 2 (placa, modelo, color, anio)
    add(_placa(placaCtrl.text));
    add(_modelo(modeloCtrl.text));
    add(_color(colorCtrl.text));
    add(_anio(anioCtrl.text));

    return errores.toSet().toList();
  }

  Future<void> _guardar() async {
    // Valida ambas páginas antes de enviar
    // Use null-safe access: currentState puede ser null si el Form aún no está montado.
   // final ok1 = _formKeyPage1.currentState?.validate() ?? false;
    final ok2 = _formKeyPage2.currentState?.validate() ?? false;
    /*if (!ok1) {
    final faltan = _erroresDeFormularioPage1();
    if (faltan.isNotEmpty) {
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
          actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
          title: Row(
            children: const [
              Icon(Icons.error_outline, color: kUAORed, size: 26),
              SizedBox(width: 8),
              Text('Faltan datos', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kUAORed)),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              'Por favor corrige o completa:\n\n• ${faltan.join('\n• ')}',
              style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
            ),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: kUAORed,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('Entendido', style: TextStyle(fontSize: 15)),
            ),
          ],
        ),
      );
    }
    // navega a página 1
    _goToPage(1);
    
    return;
  }*/
    if (!ok2) {
      final faltan = _erroresDeFormularioPage2();
      if (faltan.isNotEmpty) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
            contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            actionsPadding: const EdgeInsets.only(right: 12, bottom: 8),
            title: Row(
              children: const [
                Icon(Icons.error_outline, color: kUAORed, size: 26),
                SizedBox(width: 8),
                Text(
                  'Faltan datos',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: kUAORed,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'Por favor corrige o completa:\n\n• ${faltan.join('\n• ')}',
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                  color: Colors.black87,
                ),
              ),
            ),
            actions: [
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: kUAORed,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text('Entendido', style: TextStyle(fontSize: 15)),
              ),
            ],
          ),
        );
      }
      _goToPage(1);
      return;
    } else {
      setState(() => _saving = true);

      final payload = {
        // Página 1
        'primerNombre': primerNombreCtrl.text.trim(),
        'segundoNombre': segundoNombreCtrl.text.trim(),
        'primerApellido': primerApellidoCtrl.text.trim(),
        'segundoApellido': segundoApellidoCtrl.text.trim(),
        'correo': correoCtrl.text.trim(),
        'contrasena': contrasenaCtrl.text.trim(),
        'tipoId': _tipoIdSeleccionado,
        'numeroId': identificacionCtrl.text.trim(),
        'telefono': telefonoCtrl.text.trim(),
        // Página 2
        'placa': placaCtrl.text.trim().toUpperCase(),
        'modelo': modeloCtrl.text.trim(),
        'color': colorCtrl.text.trim(),
        'anio': anioCtrl.text.trim(),
        // Adjuntos (placeholders)
        'licenciaAdjunta': licenciaImg != null,
        'fotoVehiculoFrenteAdjunta': vehiculoFrenteImg != null,
        'tarjetaPropAdjunta': tarjetaPropImg != null,
        'soatAdjunto': soatFileName ?? '',
      };
      // ignore: avoid_print
      print(payload);

      String rol = "conductor";
      try {
        final user = await _authService.registerWithEmailAndPassword(
          payload['correo']!.toString(),
          payload['contrasena']!.toString(),
          payload['primerNombre']!.toString(),
          payload['segundoNombre']!.toString(),
          payload['primerApellido']!.toString(),
          payload['segundoApellido']!.toString(),
          payload['tipoId']!.toString(),
          payload['numeroId']!.toString(),
          payload['telefono']!.toString(),
          rol,
          payload['placa']!.toString(),
          payload['modelo']!.toString(),
          payload['color']!.toString(),
          payload['anio']!.toString()
        );

        if (user != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Cuenta de $rol creada con exito :)")),
          );
        }
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _saving = false);

        String errorMessage;
        if (e.code == 'weak-password') {
          errorMessage = 'La contraseña es demasiado débil.';
        } else if (e.code == 'email-already-in-use') {
          errorMessage = 'Ya existe una cuenta con este correo institucional.';
        } else if (e.code == 'invalid-email-domain') {
          // Error personalizado de validación (RF-001)
          errorMessage = 'El correo debe terminar en @uao.edu.co.';
        } else {
          errorMessage = 'Ocurrió un error al registrar: ${e.message}';
        }

        // Forma propia de flutter para mostrar errores
        /*FlutterError.onError = (details) {
        FlutterError.presentError(details);
        if (kReleaseMode) exit(1);
      };*/
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
        print(errorMessage);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hubo un fallo general creando el usuario')),
        );
        print(e.toString());
        if (!mounted) return;
      }

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      setState(() => _saving = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );

      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      setState(() => _saving = false);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  void _goToPage(int index) {
    setState(() => _page = index);
    _pageCtrl.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_page == 0) {
      final ok = _formKeyPage1.currentState?.validate() ?? false;
      if (!ok) {
        final faltan = _erroresDeFormularioPage1();
        if (faltan.isNotEmpty) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: const [
                  Icon(Icons.error_outline, color: kUAORed, size: 26),
                  SizedBox(width: 8),
                  Text(
                    'Faltan datos',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: kUAORed,
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(
                  'Por favor corrige o completa:\n\n• ${faltan.join('\n• ')}',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: kUAORed,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Entendido',
                    style: TextStyle(fontSize: 15),
                  ),
                ),
              ],
            ),
          );
        }
        return;
      }
      _goToPage(1);
    } else {
      _goToPage(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      body: Stack(
        children: [
          // ---------- Encabezado ----------
          Container(
            height: 260,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [kUAORed, Color(0xFFE23A2F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _page == 0
                          ? 'Registro Conductor'
                          : 'Información del Conductor',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Avatar editable (solo UI)
                    GestureDetector(
                      // Pasamos 'avatar' como tipo para que la función guarde la preview en _avatarImage
                      onTap: () => _showEditPhotoSheet(
                        'avatar',
                        'Editar foto de perfil',
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(.2),
                            ),
                            child: CircleAvatar(
                              radius: 46,
                              backgroundColor: Colors.white,
                              backgroundImage: _avatarImage,
                              child: _avatarImage == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 48,
                                      color: Colors.grey,
                                    )
                                  : null,
                            ),
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                              padding: const EdgeInsets.all(3),
                              child: const CircleAvatar(
                                radius: 14,
                                backgroundColor: Colors.black87,
                                child: Icon(
                                  Icons.photo_camera,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ---------- Card con PageView (2 páginas) ----------
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 180, 20, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x1A000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Indicador 1/2
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _Dot(active: _page == 0),
                        const SizedBox(width: 8),
                        _Dot(active: _page == 1),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Contenido deslizante
                    SizedBox(
                      height:
                          520, // alto fijo para que entre todo con scroll interno
                      child: PageView(
                        controller: _pageCtrl,
                        physics: const BouncingScrollPhysics(),
                        onPageChanged: (i) => setState(() => _page = i),
                        children: [
                          // ======== PÁGINA 1: DATOS PERSONALES ========
                          SingleChildScrollView(
                            child: Form(
                              key: _formKeyPage1,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: primerNombreCtrl,
                                    decoration: _dec('Primer nombre *'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        _noVacio(v, campo: 'Primer nombre'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: segundoNombreCtrl,
                                    decoration: _dec(
                                      'Segundo nombre (opcional)',
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: primerApellidoCtrl,
                                    decoration: _dec('Primer apellido *'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    validator: (v) =>
                                        _noVacio(v, campo: 'Primer apellido'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: segundoApellidoCtrl,
                                    decoration: _dec(
                                      'Segundo apellido (opcional)',
                                    ),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: correoCtrl,
                                    decoration: _dec(
                                      'Correo institucional (@uao.edu.co) *',
                                      icon: Icons.email_outlined,
                                    ),
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    validator: _correoUAO,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: contrasenaCtrl,
                                    obscureText: !_verContrasena,
                                    decoration:
                                        _dec(
                                          'Contraseña *',
                                          icon: Icons.lock_outline,
                                        ).copyWith(
                                          suffixIcon: IconButton(
                                            icon: Icon(
                                              _verContrasena
                                                  ? Icons.visibility_outlined
                                                  : Icons
                                                        .visibility_off_outlined,
                                              color: Colors.grey[600],
                                            ),
                                            onPressed: () => setState(
                                              () => _verContrasena =
                                                  !_verContrasena,
                                            ),
                                          ),
                                        ),
                                    textInputAction: TextInputAction.done,
                                    validator: _contrasena,
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    value: _tipoIdSeleccionado,
                                    isExpanded: true,
                                    decoration: _dec(
                                      'Tipo de identificación *',
                                      icon: Icons.badge_outlined,
                                    ),
                                    items: _tiposId
                                        .map(
                                          (e) => DropdownMenuItem(
                                            value: e,
                                            child: Text(e),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) =>
                                        setState(() => _tipoIdSeleccionado = v),
                                    validator: (v) =>
                                        v == null ? 'Selecciona un tipo' : null,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: identificacionCtrl,
                                    decoration: _dec(
                                      'Número de identificación *',
                                    ),
                                    keyboardType: TextInputType.number,
                                    textInputAction: TextInputAction.next,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    validator: _identificacion,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: telefonoCtrl,
                                    decoration: _dec(
                                      'Número de teléfono *',
                                      icon: Icons.phone_outlined,
                                      hint: 'Ej: 3001234567',
                                    ),
                                    keyboardType: TextInputType.phone,
                                    textInputAction: TextInputAction.done,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(15),
                                    ],
                                    validator: _telefono,
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),

                          // ======== PÁGINA 2: INFO CONDUCTOR ========
                          SingleChildScrollView(
                            child: Form(
                              key: _formKeyPage2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Adjuntos (UI)
                                  _AttachTile(
                                    title: 'Licencia de conducción',
                                    subtitle:
                                        'Adjuntar tu licencia de conduccion en ambas caras',
                                    icon: Icons.credit_card,
                                    onTap: () => _showEditPhotoSheet(
                                      'licencia',
                                      'Adjuntar licencia de conducción',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _AttachTile(
                                    title: 'Foto del vehículo (frente)',
                                    subtitle: 'Adjuntar foto (próximamente)',
                                    icon: Icons.directions_car,
                                    onTap: () => _showEditPhotoSheet(
                                      'vehiculo',
                                      'Adjuntar foto del vehículo (frente)',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextFormField(
                                    controller: placaCtrl,
                                    decoration: _dec(
                                      'Placa del vehículo *',
                                      hint: 'Ej: ABC123',
                                    ),
                                    textCapitalization:
                                        TextCapitalization.characters,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'[A-Za-z0-9]'),
                                      ),
                                    ],
                                    validator: _placa,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: modeloCtrl,
                                    decoration: _dec(
                                      'Modelo del vehículo *',
                                      hint: 'Ej: Nissan March, Kia Picanto',
                                    ),
                                    textInputAction: TextInputAction.next,
                                    validator: _modelo,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: colorCtrl,
                                    decoration: _dec('Color del vehículo *'),
                                    textCapitalization:
                                        TextCapitalization.words,
                                    textInputAction: TextInputAction.next,
                                    validator: _color,
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: anioCtrl,
                                    decoration: _dec(
                                      'Año del vehículo *',
                                      hint: 'Ej: 2018',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(4),
                                    ],
                                    validator: _anio,
                                  ),
                                  const SizedBox(height: 8),
                                  _AttachTile(
                                    title: 'Tarjeta de propiedad',
                                    subtitle: 'Adjuntar foto (próximamente)',
                                    icon: Icons.assignment_ind_outlined,
                                    onTap: () => _showEditPhotoSheet(
                                      'tarjeta',
                                      'Adjuntar tarjeta de propiedad',
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _AttachTile(
                                    title: 'SOAT',
                                    subtitle: 'Adjuntar archivo (próximamente)',
                                    icon: Icons.picture_as_pdf_outlined,
                                    onTap: () => _showEditPhotoSheet(
                                      'soat',
                                      'Adjuntar SOAT',
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Botonera inferior
                    Row(
                      children: [
                        if (_page == 1)
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => _goToPage(0),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: kUAORed),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                              ),
                              child: const Text(
                                'Anterior',
                                style: TextStyle(
                                  color: kUAORed,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        if (_page == 1) const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _saving
                                ? null
                                : (_page == 0 ? _next : _guardar),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kUAORed,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: _saving
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    _page == 0 ? 'Siguiente' : 'Registrar',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Link a login
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 6),
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        children: [
                          const Text(
                            '¿Ya tienes cuenta? ',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => const LoginPage(),
                                ),
                              );
                            },
                            child: const Text(
                              'Inicia sesión',
                              style: TextStyle(
                                color: kUAORed,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Widgets auxiliares ----------
class _Dot extends StatelessWidget {
  final bool active;
  const _Dot({required this.active});
  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 8,
      width: active ? 22 : 8,
      decoration: BoxDecoration(
        color: active ? const Color(0xFFD61F14) : const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }
}

class _AttachTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const _AttachTile({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      tileColor: Colors.white,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFF2F2F2),
        child: Icon(icon, color: Colors.black87),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.black54)),
      trailing: const Icon(Icons.attach_file),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }
}
