
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Ejemplo de función para obtener información del usuario
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

  Future<String> createTrip(int cantPasajeros,List<String> pasajeros,String origen,String destino) async {
    // 1. Obtener la referencia del nuevo documento (esto genera el ID)
    final docRef = _db.collection('viajes').doc();

    // 2. Obtener el ID generado
    final String viajeId = docRef.id;

    // 3. Escribir los datos usando la referencia
    await docRef.set({
      'conductorId': _auth.currentUser?.uid,
      'viajeId': viajeId, // Opcional: guardar el ID dentro del documento
      'cantidad pasajeros': cantPasajeros,
      'pasajeros': pasajeros,
      'origen': origen,
      'destino': destino,
      'horaCreacion': DateTime.now(),
      'estado': 'finalizado', //manejar 3 estados: pendiente, en curso, completado
    });

    if (docRef.id.isEmpty) {
      throw Exception('Error al crear el viaje');
    }
    // 4. Retornar el ID del viaje
    return viajeId;
  }

  Future<void> updateTripStatus(String viajeId, String nuevoEstado) async {
    await _db.collection('viajes').doc(viajeId).update({
      'estado': nuevoEstado,
    });
  }

  Future<void> addPassengerToTrip(String viajeId, String pasajeroId) async {
    await _db.collection('viajes').doc(viajeId).update({
      'pasajeros': FieldValue.arrayUnion([pasajeroId]),
    });
  }
   

  Future<QuerySnapshot<Object?>> fetchTrips() async {
    QuerySnapshot snapshot = await _db.collection('viajes').get();
    for (var doc in snapshot.docs) {
      print(doc.data());
    }
    return snapshot;
  }
}
