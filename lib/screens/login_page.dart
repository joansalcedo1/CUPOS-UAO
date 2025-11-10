import 'package:flutter/material.dart';
import 'package:flutter_cuposuao/screens/select_rol_register_page.dart';
import 'package:flutter_cuposuao/screens/home_conductor_page.dart';
import 'package:flutter_cuposuao/screens/home_pasajero_page.dart';
import 'package:flutter_cuposuao/services/auth_services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cuposuao/services/session_provider.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController userController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final AuthService _authService = AuthService();

  bool _obscurePassword = true;

  void _login() async {
  if (!_formKey.currentState!.validate()) return;

  final username = userController.text.trim();
  final email = '$username@uao.edu.co';
  final password = passController.text.trim();

  try {
    // 1) Autenticar
    final user = await _authService.signInWithEmailAndPassword(email, password);
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo iniciar sesión')),
      );
      return;
    }

    // 2) Cargar perfil en el Provider
    final session = context.read<SessionProvider>();
    await session.loadCurrentUser();

    // 3) Navegar por rol
    final role = session.current?.role ?? 'pasajero';
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inicio de sesión exitoso')),
    );

    if (role == 'conductor') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePasajeroPage()),
      );
    }
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'user-not-found':
        errorMessage = "El correo no está registrado.";
        break;
      case 'wrong-password':
        errorMessage = "Contraseña incorrecta. Intenta de nuevo.";
        break;
      case 'user-disabled':
        errorMessage = "Tu cuenta ha sido deshabilitada.";
        break;
      default:
        errorMessage = "Error de inicio de sesión: ${e.code}";
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(errorMessage)),
    );
  } catch (_) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hubo un error: no se pudo conectar con el servidor')),
    );
  }
}



  void _register() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SelectRolRegisterPage()),
    );
  }

  void _loginWithGoogle() {
    // Aquí luego puedes integrar Google Sign-In
    print('Inicio de sesión con Google');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Iniciando sesión con Google...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Cupos UAO',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,

                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'Images/LogoCuposUAO.png',
                  height: 200, // ajusta el tamaño según necesites
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Acceso institucional UAO',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                // Campo usuario
                TextFormField(
                  controller: userController,
                  decoration: const InputDecoration(
                    labelText: 'Usuario (sin @uao.edu.co)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu usuario';
                    }
                    if (value.contains('@')) {
                      return 'No incluyas el dominio (@uao.edu.co)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Campo contraseña
                TextFormField(
                  controller: passController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ingresa tu contraseña';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                // Botones de login y registro en fila
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Botón de registrarse
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _register,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: Color(0xFFD61F14)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Registrarse',
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFFD61F14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Botón de iniciar sesión
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD61F14),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Iniciar sesión',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Divider con texto
                Row(
                  children: const [
                    Expanded(child: Divider(thickness: 1)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text('O'),
                    ),
                    Expanded(child: Divider(thickness: 1)),
                  ],
                ),
                const SizedBox(height: 20),

                // Botón de Google
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loginWithGoogle,
                    icon: Image.network(
                      'https://upload.wikimedia.org/wikipedia/commons/thumb/2/2f/Google_2015_logo.svg/1200px-Google_2015_logo.svg.png',
                      height: 20,
                    ),
                    label: const Text(
                      '',
                      style: TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Texto inferior
                const Text(
                  'Solo se permiten correos institucionales @uao.edu.co',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
