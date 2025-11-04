import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cuposuao/screens/create_trip_page.dart';
import 'package:flutter_cuposuao/services/auth_services.dart';
import 'package:flutter_cuposuao/services/firebase_services.dart';

class HomeConductorPage extends StatefulWidget {
  const HomeConductorPage({super.key});

  @override
  State<HomeConductorPage> createState() => _HomeConductorPageState();
}

class _HomeConductorPageState extends State<HomeConductorPage> {
  final AuthService _authService = AuthService();
  final FirebaseServices _firebaseServices = FirebaseServices();
  late Map<String, dynamic> userData = {};
  late Map<String, dynamic> tripsData = {};


//llama a la funcion fetchUserInfo para obtener el nombre del usuario
  @override
  void initState() {
    super.initState();
    checkUserRole();
    checkTrips();
  }

  void checkUserRole() async {
    // 1. Resolver el Future y guardar el resultado del Map en userData
    final data = await _authService.fetchUserInfo();
    if (data != null) {
      print("User data fetched: $data");
      setState(() {
        userData = data;
      });
    }
  }
  void checkTrips() async {
    // Aquí puedes implementar la lógica para verificar el estado de los viajes
    final data = await _firebaseServices.fetchTrips();
    if (data != null) {
      print("Trips data fetched: $data");
      setState(() {
        tripsData = data as Map<String, dynamic>;
      });
      // Procesa los datos de los viajes según sea necesario
    }
  }

  // Colores principales de la aplicación, consistentes con register_page.dart
  static const kUAORed = Color(0xFFD61F14);
  static const kBG = Color(0xFFF6F7FB);

  // Estado para manejar la selección del menú inferior
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí puedes agregar la lógica para navegar a otras pantallas
    // o cambiar el contenido principal basado en la selección.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- Widgets de la UI ---

  /// Construye el AppBar personalizado con el saludo y el avatar del usuario.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: kBG,
      elevation: 0,
      toolbarHeight: 80,
      title: Row(
        children: [
          // Avatar del usuario
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            // En el futuro, reemplazar con la imagen del usuario
            child: Icon(Icons.person, size: 32, color: Colors.grey),
          ),
          const SizedBox(width: 16),
          // Saludo y nombre del usuario
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Hola de nuevo!',
                style: TextStyle(color: Colors.black54, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(userData['nombre'] ?? 'Cargando...',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Icono de notificaciones
        IconButton(
          icon: const Icon(
            Icons.notifications_outlined,
            color: Colors.black54,
            size: 28,
          ),
          onPressed: () {
            // Lógica para mostrar notificaciones
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  /// Construye el cuerpo principal de la pantalla.
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección de viajes
          const Text(
            'Viajes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          // Tarjeta para crear un nuevo viaje
          _buildCrearViajeCard(),
          const SizedBox(height: 24),
          // Título de la sección de historial
          const Text(
            'Historial',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          // Placeholder para el historial de viajes
          _buildHistorialPlaceholder(),
        ],
      ),
    );
  }

  /// Construye la tarjeta que permite al conductor crear un nuevo viaje.
  Widget _buildCrearViajeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '¿A dónde te diriges?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Publica tu próximo viaje y encuentra pasajeros.',
            style: TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 20),
          // Botón para crear el viaje
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const CreateTripPage()),
                        (route) => false,
                      );
                // Lógica para navegar a la pantalla de creación de viaje
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kUAORed,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear Viaje',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Construye un placeholder para mostrar cuando no hay historial de viajes.
  Widget _buildHistorialPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: const [
            Icon(Icons.map_outlined, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Aún no tienes viajes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tus viajes completados aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la barra de navegación inferior.
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Colors.white,
      selectedItemColor: kUAORed,
      unselectedItemColor: Colors.grey[600],
      type: BottomNavigationBarType.fixed, // Mantiene el fondo blanco
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
        BottomNavigationBarItem(
          icon: Icon(Icons.drive_eta),
          label: 'Mis Viajes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat_bubble_outline),
          label: 'Chats',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Perfil',
        ),
      ],
    );
  }
}
