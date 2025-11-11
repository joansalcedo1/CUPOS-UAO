import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ejemplo de función para obtener información del usuario actual
  Future<Map<String, dynamic>?> fetchUserInfo() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _db
          .collection('usuarios')
          .doc(user.uid)
          .get();
      return doc.data() as Map<String, dynamic>?;
    }
    return null;
  }
///Funcion para buscar el nombre de cualquier usuario por el id
  Future<String?> fetchUserNameById(String idUsuario) async {
    // 1. Verificación simple del parámetro
    if (idUsuario.isEmpty) {
      print("Error: El ID de usuario proporcionado está vacío.");
      return null;
    }

    try {
      // 2. Apuntar al documento del usuario usando el ID proporcionado
      // Colección 'usuarios' -> Documento (con idUsuario)
      DocumentSnapshot<Map<String, dynamic>> doc = await _db
          .collection('usuarios')
          .doc(idUsuario)
          .get();

      // 3. Verificar si el documento existe
      if (doc.exists) {
        // 4. Obtener los datos y devolver el campo 'nombre'
        // Tu BD muestra el campo como "nombre: Juan David"
        String? nombre = doc.data()?['nombre'];

        return nombre;
      } else {
        print("Error: No se encontró un documento con el ID: $idUsuario");
        return null;
      }
    } catch (e) {
      print("Error al obtener el nombre del usuario por ID: $e");
      return null;
    }
  }

  Future<String> createRoute(
    String zona,
    String destino,
    List<String> puntosInteres,
    bool esIdaYVuelta,
  ) async {
    User? user = _auth.currentUser;

    final docRef = _db
        .collection('usuarios')
        .doc(user?.uid)
        .collection('rutas')
        .doc();
    final String rutaId = docRef.id;

    await docRef.set({
      'rutaId': rutaId,
      'zona': zona,
      'destino': destino,
      'puntosInteres': puntosInteres,
      'horaCreacion': DateTime.now(),
      'esIdaYVuelta': esIdaYVuelta,
    });

    if (docRef.id.isEmpty) {
      throw Exception('Error al crear la ruta');
    }
    return rutaId;
  }

  Future<String?> createTrip(
    DateTime horaSalida,
    int cantPasajeros,
    List<String> pasajeros,
    String ruta,
    String origen,
    String destino,
    String estado,
    String vehiculo,
    String firstName,
  ) async {
    // 1. Obtener la referencia del nuevo documento (esto genera el ID)
    final docRef = _db.collection('viajes').doc();

    // 2. Obtener el ID generado
    final String viajeId = docRef.id;
    try {
      await docRef.set({
        'conductorId': _auth.currentUser?.uid,
        'viajeId': viajeId, // Opcional: guardar el ID dentro del documento
        'horaSalida': horaSalida,
        'cantidad_Pasajeros': cantPasajeros,
        'pasajeros': pasajeros,
        'ruta': ruta,
        'Origen': origen,
        'destino': destino,
        'horaCreacion': DateTime.now(),
        'estado': estado, //manejar 3 estados: confirmado, en curso, completado
        'vehiculo': vehiculo,
        'nombreConductor': firstName,
      });
    } catch (e) {
      throw Exception('Error al crear el viaje desde el catch de services: $e');
    }
    // 3. Escribir los datos usando la referencia
    if (docRef.id.isEmpty) {
      print('Error al crear el viaje: ID vacío');
      return null;
    }
    // 4. Retornar el ID del viaje
    print('Viaje creado con ID: $viajeId');
    return viajeId;
  }

  Future<void> updateTripStatus(String viajeId, String nuevoEstado) async {
    await _db.collection('viajes').doc(viajeId).update({'estado': nuevoEstado});
  }

  Future<void> addPassengerToTrip(String viajeId, String pasajeroId) async {
    String? nombreUsuario = await fetchUserNameById(pasajeroId);

    await _db.collection('viajes').doc(viajeId).update({
      'pasajeros': FieldValue.arrayUnion([nombreUsuario]),
    });
  }

  Future<QuerySnapshot<Object?>> fetchRoutes() async {
    // Llama a .get() sobre la colección 'rutas'
    QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .collection('usuarios')
        .doc(_auth.currentUser?.uid)
        .collection('rutas')
        .get();

    // Este bucle ahora sí funcionará
    for (var doc in snapshot.docs) {
      print('Ruta encontrada: ${doc.data()}');
    }
    return snapshot;
  }

  Future<QuerySnapshot<Object?>> fetchTrips() async {
    QuerySnapshot snapshot = await _db.collection('viajes').get();
    for (var doc in snapshot.docs) {
      print(doc.data());
    }
    return snapshot;
  }
}
