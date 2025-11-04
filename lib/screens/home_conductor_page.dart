import 'package:flutter/material.dart';

// --- Sistema de Diseño (Basado en home_conductor_page.dart) ---

/// Color principal de la aplicación (UAO Red)
const Color kUAORed = Color(0xFFD61F14);
/// Color de fondo principal de la aplicación
const Color kBG = Color(0xFFF6F7FB);
/// Color de texto para títulos principales
const Color kTextTitle = Color(0xFF1F1F1F); // Un negro más suave que Colors.black87
/// Color de texto para subtítulos y cuerpo
const Color kTextSubtitle = Colors.black54;
/// Color de texto para placeholders o texto grisado
const Color kTextPlaceholder = Colors.grey;
/// Color para bordes o divisores sutiles
const Color kBorderColor = Color(0xFFE0E0E0);

// --- Widget Principal ---

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Estado para manejar la selección del menú inferior
  int _selectedIndex = 0; // 'Viajes' es el índice 0
  DateTime? _selectedDateTime; // Variable para almacenar la fecha y hora seleccionada
  String? _selectedPassengers; // Variable para almacenar el número de pasajeros seleccionados

  String get _dateTimeText {
    if (_selectedDateTime == null) {
      return 'Seleccionar fecha y hora';
    }
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Agosto', 'Sep', 'Oct', 'Nov', 'Dic'];
    final monthName = months[_selectedDateTime!.month - 1];
    return '${_selectedDateTime!.day} de $monthName - ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}';
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí se puede agregar lógica de navegación si es necesario
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG, // Aplicado color de fondo del sistema de diseño
      appBar: _buildAppBar(), // Se reemplazó el Padding por un AppBar
      body: _buildBody(), // El cuerpo ahora está en un método separado
      bottomNavigationBar:
          _buildBottomNavigationBar(), // Se reemplazó el Container por BottomNavigationBar
    );
  }

  // --- Widgets de la UI (Reestructurados como en home_conductor_page.dart) ---

  /// Construye el AppBar personalizado.
  /// Mantiene los elementos del wireframe original (menu, avatar, saludo, ubicación)
  /// pero con el estilo del sistema de diseño.
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      leadingWidth: 72, 
      backgroundColor: kBG,
      elevation: 0,
      toolbarHeight: 100,
      leading: IconButton(
        icon: const Icon(Icons.menu, color: kTextSubtitle, size: 32),
        onPressed: () {
          // TODO: Implementar menú (Drawer)
        },
      ),
      title: Row(
        children: [
          // Avatar del usuario
          const CircleAvatar(
            radius: 24, // Tamaño ajustado
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 32, color: kTextPlaceholder),
          ),
          const SizedBox(width: 12),
          // Saludo y ubicación
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '¡Hola de nuevo Juan David!',
                style: TextStyle(
                  color: kTextSubtitle,
                  fontSize: 18,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: kTextTitle,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Universidad Autonoma de Occidente',
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'Inter',
                      color: kTextTitle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      titleSpacing: 0, // Ajuste para alinear con el avatar
    );
  }

  /// Construye el cuerpo principal de la pantalla.
  Widget _buildBody() {
    // Se usa SingleChildScrollView para evitar overflow si el contenido crece
    return SingleChildScrollView(
      // Padding estándar del sistema de diseño
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título de la sección de viajes
          const Text(
            'Viajes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextTitle,
              fontFamily: 'Inter',
            ),
          ),const SizedBox(height: 4),
          // Subtítulo
          const Text(
            'Publica tu proximo cupo y encuentra pasajeros',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              color: kTextSubtitle,
            ),
          ),
          const SizedBox(height: 24),
          // Tarjeta para crear un nuevo "cupo" (viaje)
          _buildCrearCupoCard(),
          const SizedBox(height: 24),
          // Botón para crear nueva ruta
          _buildNuevaRutaButton(),
          const SizedBox(height: 24),
          // Título de la sección de historial
          const Text(
            'Historial',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: kTextTitle,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          // Placeholder para el historial de viajes
          _buildHistorialPlaceholder(), // Reutilizado de home_conductor_page
        ],
      ),
    );
  }

  /// Construye la tarjeta para "Nuevo Cupo", manteniendo la estructura
  /// del wireframe pero con el estilo del sistema de diseño.
  Widget _buildCrearCupoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20), // Padding estándar
      decoration: BoxDecoration(
        color: Colors.white, // Fondo blanco para tarjetas
        borderRadius: BorderRadius.circular(24), // Bordes redondeados estándar
        boxShadow: const [ // Sombra estándar
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nuevo cupo',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: kTextTitle,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.directions_car_filled, color: kUAORed, size: 32),
              const SizedBox(width: 12),
              _buildSelectChip(label: 'Selecciona una ruta', hasDropdown: true,),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Fila para Día y Hora
            Row(
            children: [
              const Icon(Icons.access_time_filled, color: kUAORed, size: 32),
              const SizedBox(width: 12),
              Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kBorderColor),
                ),
                child: InkWell(
                onTap: () async {
                  final DateTime? date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 1)),
                  );
                  if (date != null) {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (time != null) {
                      final DateTime picked = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time.hour,
                        time.minute,
                      );
                        setState(() {
                        _selectedDateTime = picked;
                        });
                    }
                  }
                },
                child: Row(
                  children: [
                  Text(
                    _dateTimeText,
                    style: const TextStyle(
                    color: kTextTitle,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.keyboard_arrow_down,
                    color: kTextSubtitle,
                    size: 20,
                  ),
                  ],
                ),
                ),
              ),
              ),
            ],
            ),
          const SizedBox(height: 16),

          // Selección de pasajeros
            Row(
            children: [
              const Icon(Icons.people, color: kUAORed, size: 32),
              const SizedBox(width: 12),
              PopupMenuButton<int>(
              child: _buildSelectChip(
                label: '${_selectedPassengers ?? "Numero de pasajeros:"}',
                hasDropdown: true,
              ),
              itemBuilder: (context) => [1, 2, 3, 4].map((count) {
                return PopupMenuItem<int>(
                value: count,
                child: Text('$count pasajero${count > 1 ? "s" : ""}'),
                );
              }).toList(),
              onSelected: (value) {
                setState(() {
                _selectedPassengers = ('$value pasajero${value > 1 ? "s" : ""}');
                });
              },
              ),
            ],
            ),
          const SizedBox(height: 24),

          // Botón principal de acción
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // Lógica para crear el cupo
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kUAORed, // Color primario
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24), // Borde redondeado
                ),
              ),
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'Crear Cupo',
                style: TextStyle(
                    color: Colors.white, fontSize: 16, fontFamily: 'Inter'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Widget auxiliar para los chips de selección dentro de la tarjeta.
  Widget _buildSelectChip({
    IconData? icon,
    required String label,
    bool hasDropdown = false,
    bool isPrimary = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // El color primario (gris claro) es para los chips principales,
        // el secundario (borde) es para los chips más pequeños (Día/Hora).
        color: isPrimary ? kBG : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isPrimary ? null : Border.all(color: kBorderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: kUAORed, size: 20),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: const TextStyle(
              color: kTextTitle,
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasDropdown) ...[
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: kTextSubtitle,
              size: 20,
            ),
          ],
        ],
      ),
    );
  }

  /// Construye el botón secundario para "Crear nueva ruta".
  Widget _buildNuevaRutaButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Lógica para crear una nueva ruta
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: kUAORed, // Color del texto y el icono
          side: const BorderSide(color: kUAORed, width: 1.2), // Borde
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.add, size: 20),
        label: const Text(
          'Crea una nueva ruta',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Construye un placeholder para mostrar cuando no hay historial de viajes.
  /// Se reutiliza el estilo de `home_conductor_page.dart` pero con el
  /// icono original de `home_page.dart`.
  Widget _buildHistorialPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: const [
            Icon(
              Icons.map_outlined, // Icono del wireframe original
              size: 60,
              color: kTextPlaceholder, // Color del sistema de diseño
            ),
            SizedBox(height: 12),
            Text(
              'Aún no tienes viajes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: kTextSubtitle,
                fontFamily: 'Inter',
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Tus viajes completados aparecerán aquí.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: kTextPlaceholder,
                fontFamily: 'Inter',
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Construye la barra de navegación inferior.
  /// Utiliza el widget `BottomNavigationBar` del sistema de diseño,
  /// pero con los items del wireframe original.
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Colors.white,
      selectedItemColor: kUAORed, // Color activo del sistema de diseño
      unselectedItemColor: kTextPlaceholder, // Color inactivo
      type: BottomNavigationBarType.fixed, // Mantiene el fondo blanco
      items: const <BottomNavigationBarItem>[
        // Items del wireframe original
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Viajes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Actividad',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }
}
