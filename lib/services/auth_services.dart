import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  // Inicializa las instancias de Firebase que usarás
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String requiredDomain = 'uao.edu.co';

  // =======================================================
  // FUNCIÓN 1: Registro (Crea el usuario en Auth y la base inicial en Firestore)
  // =======================================================

  Future<User?> registerWithEmailAndPassword(
    String email,
    String password,
    String firstName,
    String secondName,
    String firstLastName,
    String secondlastName,
    final tipoID,
    String numeroID,
    String telefono,
    String rol,
    String? placa,
    String? modelo,
    String? color,
    String? anio
  ) async {
    // 1. Validación de Dominio
    if (!email.endsWith('@$requiredDomain')) {
      throw FirebaseAuthException(
        code: 'invalid-email-domain',
        message: 'Solo se permiten correos institucionales @$requiredDomain.',
      );
    }

    // 2. Creación en Firebase Auth
    UserCredential result = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = result.user;

    if (user != null) {
      await user.sendEmailVerification();
      // 3. Creación del Documento Básico en Firestore
      // Se guarda aquí la data mínima y el rol inicial

      if (rol == "conductor") {
        await _db.collection('usuarios').doc(user.uid).set({
          'idUsuario': user.uid,
          'correo': email,
          'nombre': firstName + secondName,
          'apellidos': firstLastName + secondlastName,
          'tipoID': tipoID,
          'numeroID': numeroID,
          'telefono': telefono,
          'rol': [rol],
          'placa_Vehiculo': placa,
          'modelo_Vehiculo': modelo,
          'color_Vehiculo': color,
          'anio_Vehiculo': anio
        });
    
      } else if (rol == "pasajero") {
        await _db.collection('usuarios').doc(user.uid).set({
          'idUsuario': user.uid,
          'correo': email,
          'nombre': firstName + secondName,
          'apellidos': firstLastName + secondlastName,
          'tipoID': tipoID,
          'numeroID': numeroID,
          'telefono': telefono,
          'rol': [rol],
        });
      }
    }

    return user;
  }

  // =======================================================
  // FUNCIÓN 2: Actualización de Perfil
  // =======================================================
  Future<void> updateBasicProfile(Map<String, dynamic> data) async {
    String? userId = _auth.currentUser?.uid;
    // Solo actualiza si hay un usuario autenticado
    if (userId != null) {
      // Llama a la función .update() de Firestore para actualizar el documento existente
      await _db.collection('usuarios').doc(userId).update(data);
    }
  }

  Future<User?> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    // La lógica de la sesión es estándar de Firebase Auth
    // Se puede agregar una verificación de si el correo pertenece al dominio @uao.edu.co aquí también si no se hizo en el registro.
    User? user = (await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    )).user;
    if (user != null && !user.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message:
            'Por favor verifica tu correo electrónico antes de iniciar sesión.',
      );
    } else {
      return user;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<String?> getCurrentUser() async {
    return _auth.currentUser?.uid;
  }

  Future<Map<String, dynamic>?> fetchUserInfo() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      return doc.data()!;
    } else {
      print("No user data found for uid: $uid");
      return null;
    }
  }

  // ... (Puedes agregar aquí signInWithEmailAndPassword, signOut, etc.)
}


