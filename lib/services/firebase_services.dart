import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_cuposuao/screens/home_conductor_page.dart';

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
      'precio': priceForZone(zona),
    });

    if (docRef.id.isEmpty) {
      throw Exception('Error al crear la ruta');
    }
    return rutaId;
  }

  Future<String?> createTrip(
    DateTime horaSalida,
    int cantPasajeros,
    List<Pasajero> pasajeros,
    String ruta,
    String origen,
    String destino,
    String estado,
    String vehiculo,
    String firstName,
    int price,
  ) async {
    // 1. Obtener la referencia del nuevo documento (esto genera el ID)
    final docRef = _db.collection('viajes').doc();

    // 2. Obtener el ID generado
    final String viajeId = docRef.id;
    //convertir en un mapa los pasajeros
    final List<Map<String, dynamic>> pasajerosMapList = pasajeros.map((p) {
      // Por cada objeto Pasajero, creamos un Map
      return {
        'id': p.id, // El ID del pasajero (será null al inicio)
        'nombre': p.nombre, // "Encontrando pasajero..."
        'estado': p.estado.toString(), // "PasajeroEstado.buscando"
        'cantidad': 1, // Asumimos que cada slot "buscando" es 1 cupo
      };
    }).toList();
    try {
      await docRef.set({
        'conductorId': _auth.currentUser?.uid,
        'viajeId': viajeId, // Opcional: guardar el ID dentro del documento
        'horaSalida': horaSalida,
        'cantidad_Pasajeros': cantPasajeros,
        'pasajeros': pasajerosMapList,
        'ruta': ruta,
        'Origen': origen,
        'destino': destino,
        'horaCreacion': DateTime.now(),
        'estado': estado, //manejar 3 estados: confirmado, en curso, completado
        'vehiculo': vehiculo,
        'nombreConductor': firstName,
        'precio': price,
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

  Future<void> addPassengerToTrip(String viajeId,String pasajeroId,String pasajeroName,int qty,) async {
    
    // 1. Prepara el objeto Map que vas a añadir a la lista
    final passengerData = {
      'id': pasajeroId,
      'nombre': pasajeroName,
      'estado': 'confirmado', // O el estado que manejes
      'cantidad': qty,
    };

    // 2. Apunta al documento del viaje
    final tripRef = _db
        .collection(
          'viajes',
        ) // O 'viajes_publicados', el nombre de tu colección
        .doc(viajeId);

    // 3. Ejecuta la transacción en Firebase
    await tripRef.update({
      // Añade el 'passengerData' a la lista 'pasajeros'
      'pasajeros': FieldValue.arrayUnion([passengerData]),

      // Resta la cantidad de 'cantidad_Pasajeros'
      'cantidad_Pasajeros': FieldValue.increment(-qty),
    });
  }


///Elimina un pasajero de la lista de un viaje y re-suma los asientos disponibles.
Future<void> deletePassengerFromTrip(
  String viajeId,String pasajeroId,String pasajeroName,int qty,
) async {
  final passengerData = {
      'id': pasajeroId,
      'nombre': pasajeroName,
      'estado': 'confirmado', 
      'cantidad': qty,
    };
  final tripRef = _db
      .collection(
        'viajes',
      ) 
      .doc(viajeId);

  await tripRef.update({
    'pasajeros': FieldValue.arrayRemove([passengerData]),
    'cantidad_Pasajeros': FieldValue.increment(qty),
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
///Función para escuchar en tiempo real los pasajeros del viaje
  Stream<List<Pasajero>> escucharPasajerosDelViaje(String viajeId) {
  
  // 1. Apunta al documento y usa .snapshots() para escuchar
  final streamDelDocumento = _db.collection('viajes').doc(viajeId).snapshots();

  // 2. Transforma el stream: debe convertir el DocumentSnapshot en una List<Pasajero>
  return streamDelDocumento.map((snapshot) {
    
    // Si el documento es borrado o no existe
    if (!snapshot.exists) {
      return []; // Devuelve lista vacía
    }

    final data = snapshot.data();
    if (data == null) {
      return [];
    }

    // 3. Extrae la lista 'pasajeros' (igual que en la función Future)
    final List<dynamic> pasajerosFromDB = data['pasajeros'] ?? [];

    // 4. Convierte (parsea) cada Mapa a un objeto Pasajero
    final List<Pasajero> listaDePasajeros = pasajerosFromDB.map((pasajeroData) {
      return Pasajero(
        id: pasajeroData['id'],
        nombre: pasajeroData['nombre'] ?? 'Pasajero',
        estado: (pasajeroData['estado'] == 'PasajeroEstado.confirmado')
            ? PasajeroEstado.confirmado
            : PasajeroEstado.buscando,
      );
    }).toList();
    print("Escuchando los pasajeros del viaje");
    return listaDePasajeros;
  });
}
}
