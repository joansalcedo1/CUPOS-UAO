//import 'dart:nativewrappers/_internal/vm/lib/internal_patch.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cuposuao/screens/login_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_cuposuao/services/auth_services.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  // Colores
  static const kUAORed = Color(0xFFD61F14);
  static const kBG = Color(0xFFF6F7FB);
  //instancias de firebase: componente en auth_services
  final AuthService _authService = AuthService();
  // Controladores
  final TextEditingController primerNombreCtrl = TextEditingController();
  final TextEditingController segundoNombreCtrl = TextEditingController();
  final TextEditingController primerApellidoCtrl = TextEditingController();
  final TextEditingController segundoApellidoCtrl = TextEditingController();
  final TextEditingController correoCtrl = TextEditingController();
  final TextEditingController contrasenaCtrl = TextEditingController();
  final TextEditingController identificacionCtrl = TextEditingController();
  final TextEditingController telefonoCtrl = TextEditingController();

  // Estado
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
  ImageProvider? _avatarImage; // en el futuro: foto real del usuario
  bool _verContrasena = false;

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
    super.dispose();
  }

  void _showEditPhotoSheet() {
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
              children: const [
                SizedBox(height: 6),
                Text(
                  'Editar foto de perfil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 12),
                ListTile(
                  leading: Icon(Icons.photo_library_outlined),
                  title: Text('Elegir desde galería (próximamente)'),
                ),
                ListTile(
                  leading: Icon(Icons.photo_camera_outlined),
                  title: Text('Tomar foto (próximamente)'),
                ),
                SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
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
    if (value.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres';
    }
    return null;
  }

  String? _telefono(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Número de teléfono es obligatorio';
    if (value.length < 7) {
      return 'Número de teléfono demasiado corto (mín. 7 dígitos)';
    }
    if (value.length > 15) {
      return 'Número de teléfono demasiado largo (máx. 15 dígitos)';
    }
    return null;
  }

  String? _identificacion(String? v) {
    if (_tipoIdSeleccionado == null) {
      return 'Selecciona el tipo de identificación';
    }
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Número de identificación es obligatorio';
    if (value.length < 6) {
      return 'Número de identificación demasiado corto (mín. 6 dígitos)';
    }
    // Límite máximo ya lo controla el LengthLimitingTextInputFormatter
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
        // ← asegúrate de tenerlo
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

  List<String> _erroresDeFormulario() {
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

    // Evita duplicados por si coinciden mensajes
    return errores.toSet().toList();
  }

  Future<void> _guardar() async {
    final esValido = _formKey.currentState!.validate();

    if (!esValido) {
      final faltan = _erroresDeFormulario();
      if (faltan.isNotEmpty) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor:
                Colors.white, // Fondo consistente con el formulario
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

      return;
    }

    setState(() => _saving = true);

    /*final payload = {
      'primerNombre': primerNombreCtrl.text.trim(),
      'segundoNombre': segundoNombreCtrl.text.trim(),
      'primerApellido': primerApellidoCtrl.text.trim(),
      'segundoApellido': segundoApellidoCtrl.text.trim(),
      'correo': correoCtrl.text.trim(),
      'contrasena': contrasenaCtrl.text.trim(),
      'tipoId': _tipoIdSeleccionado,
      'numeroId': identificacionCtrl.text.trim(),
      'telefono': telefonoCtrl.text.trim(),
    };
    // ignore: avoid_print
    print(payload);*/


    String primerNombre = primerNombreCtrl.text.trim();
    String segundoNombre = segundoNombreCtrl.text.trim();
    String primerApellido = primerApellidoCtrl.text.trim();
    String segundoApellido = segundoApellidoCtrl.text.trim();
    String correo = correoCtrl.text.trim();
    String contrasena = contrasenaCtrl.text.trim();
    final tipoId = _tipoIdSeleccionado;
    String numeroId = identificacionCtrl.text.trim();
    String telefono = telefonoCtrl.text.trim();

    String rol = "pasajero";
    String fullName =
        "$primerNombre $segundoNombre $primerApellido $segundoApellido";

    try {
      final user = await _authService.registerWithEmailAndPassword(
        correo,
        contrasena,
        fullName,
        tipoId,
        numeroId,
        telefono,
        rol,
      );

      if (user != null) {
        ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Cuenta creada con exito :)")));

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
      print(
        errorMessage
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar( SnackBar(content: Text('Hubo un fallo general creando el usuario')));
      if (!mounted) return;
    }

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    setState(() => _saving = false);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      body: Stack(
        children: [
          // ---------- Encabezado con degradado, logo y título ----------
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
                    const Text(
                      'Registro Pasajero',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Avatar editable (solo UI)
                    GestureDetector(
                      onTap: _showEditPhotoSheet,
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
                              backgroundImage:
                                  _avatarImage, // null => muestra el ícono
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

          // ---------- Card con formulario ----------
          Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 180, 20, 24),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: primerNombreCtrl,
                        decoration: _dec('Primer nombre *'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => _noVacio(v, campo: 'Primer nombre'),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: segundoNombreCtrl,
                        decoration: _dec('Segundo nombre (opcional)'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: primerApellidoCtrl,
                        decoration: _dec('Primer apellido *'),
                        textCapitalization: TextCapitalization.words,
                        textInputAction: TextInputAction.next,
                        validator: (v) => _noVacio(v, campo: 'Primer apellido'),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: segundoApellidoCtrl,
                        decoration: _dec('Segundo apellido (opcional)'),
                        textCapitalization: TextCapitalization.words,
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
                                      : Icons.visibility_off_outlined,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() {
                                    _verContrasena = !_verContrasena;
                                  });
                                },
                              ),
                            ),
                        textInputAction: TextInputAction.done,
                        validator: _contrasena,
                      ),
                      const SizedBox(height: 12),

                      DropdownButtonFormField<String>(
                        initialValue: _tipoIdSeleccionado,
                        isExpanded: true,
                        decoration: _dec(
                          'Tipo de identificación *',
                          icon: Icons.badge_outlined,
                        ),
                        items: _tiposId
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
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
                        decoration: _dec('Número de identificación *'),
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
                      const SizedBox(height: 18),

                      // Botón
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _guardar,
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
                              : const Text(
                                  'Registrar',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
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
          ),
        ],
      ),
    );
  }
}
