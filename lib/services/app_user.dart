class AppUser {
  final String uid;
  final String firstName; // primerNombre real
  final String role;      // 'pasajero' | 'conductor'
  final String vehicle;

  const AppUser({
    required this.uid,
    required this.firstName,
    required this.role,
    required this.vehicle
  });
}
