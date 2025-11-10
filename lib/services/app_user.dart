class AppUser {
  final String uid;
  final String firstName; // primerNombre real
  final String role;      // 'pasajero' | 'conductor'

  const AppUser({
    required this.uid,
    required this.firstName,
    required this.role,
  });
}
