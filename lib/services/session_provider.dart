import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/app_user.dart';
import '../services/auth_services.dart';

class SessionProvider extends ChangeNotifier {
  AppUser? _current;
  AppUser? get current => _current;

  Future<void> loadCurrentUser() async {
    final authUser = FirebaseAuth.instance.currentUser;
    if (authUser == null) {
      _current = null;
      notifyListeners();
      return;
    }

    final data = await AuthService().fetchUserInfo(); // Map<String,dynamic>?
    if (data == null) {
      _current = null;
      notifyListeners();
      return;
    }

    final rolField = data['rol'];
    final role = (rolField is List && rolField.isNotEmpty)
        ? rolField.first.toString()
        : (rolField?.toString() ?? 'pasajero');

    // --- INICIO DE LA CORRECCIÓN ---
    final vehicleField = data['modelo_Vehiculo'];
    print("El carro es: $vehicleField");

    // Comprobamos si es un String Y si no está vacío
    final vehicle = (vehicleField is String && vehicleField.isNotEmpty)
        ? vehicleField // Si es, usamos el valor
        : 'Carrooo'; // Si no (es null, no es String, o está vacío), usamos el default
    // --- FIN DE LA CORRECCIÓN ---

    // Preferimos 'primerNombre'; si no, derivamos de 'nombre'
    final rawName = (data['primerNombre'] ?? data['nombre'] ?? 'Usuario')
        .toString()
        .trim();
    final firstName = rawName.isEmpty
        ? 'Usuario'
        : rawName.split(RegExp(r'\s+')).first;

    _current = AppUser(
      uid: authUser.uid,
      firstName: firstName,
      role: role,
      vehicle: vehicle,
    );
    notifyListeners();
  }

  void clear() {
    _current = null;
    notifyListeners();
  }
}
