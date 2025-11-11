//Imports

import 'package:flutter/material.dart';
import 'package:flutter_cuposuao/services/auth_services.dart';
import 'package:flutter_cuposuao/services/firebase_services.dart';
import 'package:flutter_cuposuao/services/session_provider.dart';
import 'package:lottie/lottie.dart'; // Librería para animaciones Lottie
import 'package:loading_animation_widget/loading_animation_widget.dart'; // Librería para animaciones de carga

import 'package:animated_text_kit/animated_text_kit.dart'; // Librería para animaciones de texto
import 'package:provider/provider.dart'; // Librería para animaciones de texto

import 'package:animated_text_kit/animated_text_kit.dart';

// ------ Modelo de Datos para Rutas ------
// Representa una ruta creada por el conductor.
class Ruta {
  final String zona;
  final String destino;
  final Set<String> puntos;
  final bool esIdaYVuelta;

  Ruta({
    required this.zona,
    required this.destino,
    required this.puntos,
    required this.esIdaYVuelta,
  });
  String get nombreMostrado => '$zona - $destino';

  // Devuelve una cadena con los puntos de recogida, para la tarjeta de cupo activo.
  String get puntosFormateados {
    if (puntos.isEmpty) return "Sin puntos intermedios";
    // Toma los primeros 3 puntos y los une.
    return puntos.take(3).join(', ');
  }
}

// Representa un cupo (viaje) que el conductor va a publicar.
// Asocia una [Ruta] específica con una fecha, hora y número de pasajeros.
class Cupo {
  final Ruta ruta;
  final DateTime fechaHora;
  final String pasajeros;
  final int capacidad;
  final List<Pasajero> listaPasajeros; // La nueva lista

  Cupo({
    required this.ruta,
    required this.fechaHora,
    required this.pasajeros,
    required this.capacidad,
    required this.listaPasajeros,
  });

  // --- ¡AÑADE ESTE MÉTODO COMPLETO DENTRO DE TU CLASE Cupo! ---
  /// Crea una copia de este Cupo pero con los campos reemplazados.
  Cupo copyWith({
    Ruta? ruta,
    DateTime? fechaHora,
    String? pasajeros,
    int? capacidad,
    List<Pasajero>? listaPasajeros,
  }) {
    return Cupo(
      // Si el parámetro 'ruta' NO es nulo, usa el nuevo valor.
      // Si ES nulo, usa el valor antiguo (this.ruta).
      ruta: ruta ?? this.ruta,
      fechaHora: fechaHora ?? this.fechaHora,
      pasajeros: pasajeros ?? this.pasajeros,
      capacidad: capacidad ?? this.capacidad,
      listaPasajeros: listaPasajeros ?? this.listaPasajeros,
    );
  }

  // --- FIN DEL MÉTODO ---
}

// Define el estado de un pasajero en un cupo.
enum PasajeroEstado { confirmado, enEspera, buscando }

// Define el estado del viaje/cupo activo.
enum EstadoViaje { cancelado, buscando, confirmado, iniciado }

/// Representa un pasajero (o un espacio para un pasajero).
class Pasajero {
  final String? id; // ID del backend (opcional para 'buscando')
  final String nombre; // Nombre del pasajero o "Encontrando..."
  final PasajeroEstado estado;

  Pasajero({this.id, required this.nombre, required this.estado});
}

// --- Sistema de Diseño  ---
/// Color principal de la aplicación (UAO Red)
const Color kUAORed = Color(0xFFD61F14);
const Color kUAORedDark = Color.fromRGBO(138, 20, 40, 1);
const Color kUAORedDark02 = Color.fromARGB(255, 172, 11, 51);
const Color kUAOOrange = Color.fromARGB(255, 255, 130, 108);

const Color kBG = Color(0xFFF6F7FB);

/// Color de fondo principal de la aplicación
const Color kTextTitle = Color(0xFF1F1F1F);

/// Color de texto para títulos principales
const Color kTextSubtitle = Colors.black54;

/// Color de texto para subtítulos y cuerpo
const Color kTextPlaceholder = Colors.grey;

/// Color de texto para placeholders o texto grisado
const Color kBorderColor = Color(0xFFE0E0E0);

// --- Widget Principal ---
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // --- Estado General de la UI (Pantalla 'Viajes' es el índice 0) ---
  int _selectedIndex = 0; //

  // --- Estado para la tarjeta "Nuevo Cupo" ---
  DateTime? _selectedDateTime;
  String? _selectedPassengers;
  Ruta? _selectedRuta;

  // --- Estado para la tarjeta "Nueva Ruta" ---
  bool _isCrearRutaVisible = false; // Controla qué tarjeta se muestra
  bool _isIdaYVuelta = false;
  String? _selectedZona;
  late TextEditingController _destinoController;
  Set<String> _selectedPoints = {};

  // --- Lista de rutas guardadas temporalmente ---
  final List<Ruta> _rutasGuardadas = [];
  bool _isLoadingRutas = true;
  // --- Estado para la animación de carga ---
  bool _isCupoLoading = false;
  bool _isCupoLoad = false;
  Cupo? _cupoCreado;

  EstadoViaje _estadoViaje = EstadoViaje.buscando;
  late String id_Viaje = "";
  final FirebaseServices firebaseServices = FirebaseServices();

  final AuthService authService = AuthService();
  // --- Controladores ---
  // Aquí se inicializa el [_destinoController], que es un controlador para el campo de
  // texto donde el conductor ingresa el lugar de destino al crear una nueva ruta.
  @override
  void initState() {
    super.initState();
    _destinoController = TextEditingController();
    _loadUserRoutes();
  }

  // Limpia los recursos asociados al controlador de texto. Es importante llamar a [dispose] en el [_destinoController]
  // para evitar fugas de memoria y liberar los recursos asociados al controlador de texto.
  @override
  void dispose() {
    _destinoController.dispose();
    super.dispose();
  }

  /// Manejador para la barra de navegación inferior
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Aquí se puede agregar lógica de navegación si es necesario
  }

  /// Getter para el texto de fecha y hora y formato
  String get _dateTimeText {
    if (_selectedDateTime == null) {
      return 'Seleccionar fecha y hora';
    }
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Agosto',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final monthName = months[_selectedDateTime!.month - 1];
    return '${_selectedDateTime!.day} de $monthName - ${_selectedDateTime!.hour}:${_selectedDateTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Formatea la fecha y hora para la tarjeta de cupo activo (estilo "Nov 04, 9:30 AM")
  String _formatCupoDateTime(DateTime dt) {
    final months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    final monthName = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour > 12 ? dt.hour - 12 : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';

    // Formato basado en la imagen: "Nov 04, 9:30 AM"
    return '$monthName $day, $hour:$minute $ampm';
  }

  // AÑADE ESTA NUEVA FUNCIÓN EN _HomePageState
  Future<void> _loadUserRoutes() async {
    try {
      final snapshot = await firebaseServices.fetchRoutes();

      final List<Ruta> rutasDesdeDB = snapshot.docs
          .map((doc) {
            // 1. Obtenemos el dato como un 'Object?' genérico
            final dataObject = doc.data();

            // 2. VERIFICAMOS: Si el documento no tiene datos (null)
            // o si NO es un Mapa, lo saltamos.
            if (dataObject == null || dataObject is! Map<String, dynamic>) {
              // Retornamos null para este documento y lo filtramos después
              return null;
            }

            // 3. ¡LA SOLUCIÓN!
            // Le decimos a Dart: "Confía en mí, esto SÍ es un Mapa".
            // Ahora 'data' es un Map<String, dynamic> (no nulo).
            final data = dataObject as Map<String, dynamic>;

            // 4. Ahora tu lógica anterior funciona perfectamente
            // porque 'data' ya no es nulo.
            final List<dynamic> puntosFromDB = data['puntosInteres'] ?? [];
            final Set<String> puntos = puntosFromDB
                .map((punto) => punto.toString())
                .toSet();

            return Ruta(
              zona:
                  data['zona'] ??
                  '', // Con ?? por si el *campo* 'zona' no existe
              destino: data['destino'] ?? '',
              puntos: puntos,
              esIdaYVuelta: data['esIdaYVuelta'] ?? false,
            );
          })
          // 5. Filtramos los 'null' que resultaron de documentos vacíos
          .whereType<Ruta>() // <-- Esto solo deja pasar los objetos 'Ruta'
          .toList();

      // 6. Actualiza el estado con las rutas cargadas
      setState(() {
        _rutasGuardadas.clear();
        _rutasGuardadas.addAll(rutasDesdeDB);
        _isLoadingRutas = false;
      });
    } catch (e) {
      print("Error cargando rutas: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar tus rutas guardadas: $e'),
            backgroundColor: kUAORed,
          ),
        );
      }
      setState(() {
        _isLoadingRutas = false;
      });
    }
  }

  // Funcion que guarda y valida una nueva ruta en la lista temporal `_rutasGuardadas`.
  // y la añade al estado. Luego, limpia los campos del formulario y cambia la vista de nuevo a la tarjeta de "Nuevo Cupo".
  void _guardarNuevaRuta() async {
    if (_selectedZona != null &&
        _destinoController.text.isNotEmpty &&
        _selectedPoints.isNotEmpty) {
      final nuevaRuta = Ruta(
        zona: _selectedZona!,
        destino: _destinoController.text,
        puntos: Set.from(_selectedPoints),
        esIdaYVuelta: _isIdaYVuelta,
      );

      try {
        var rutaNueva = await firebaseServices.createRoute(
          nuevaRuta.zona,
          nuevaRuta.destino,
          nuevaRuta.puntos.toList(),
          nuevaRuta.esIdaYVuelta,
        );
        print('Ruta creada $rutaNueva');

        await _loadUserRoutes();
        setState(() {
          //_rutasGuardadas.add(nuevaRuta);
          // Limpiar campos después de guardar
          _selectedZona = null;
          _destinoController.clear();
          _selectedPoints.clear();
          _isIdaYVuelta = false;
          // Volver a la tarjeta de "Nuevo Cupo"
          _isCrearRutaVisible = false;
        });

        // Mensaje de confirmacion
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ruta guardada con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        print("error creando ruta: $e");
      }
    } else {
      // Mensaje de Error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa todos los campos para guardar la ruta.',
          ),
          backgroundColor: kUAORed,
        ),
      );
    }
  }

  /// Crea, valida y "guarda" un nuevo cupo. Si la validación es exitosa, activa el estado de carga (`_isCupoLoading`),
  /// simula una operación de guardado con un `Future.delayed`, y luego desactiva el estado de carga y limpia los campos del formulario.
  void _crearCupo() async {
    if (_selectedRuta == null ||
        _selectedDateTime == null ||
        _selectedPassengers == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, completa todos los campos para crear el cupo.',
          ),
          backgroundColor: kUAORed,
        ),
      );
      return;
    }

    final int capacidad = int.tryParse(_selectedPassengers!.split(' ')[0]) ?? 0;
    // Genera la lista inicial de pasajeros "buscando"
    final List<Pasajero> initialPasajeros = List.generate(
      capacidad,
      (index) => Pasajero(
        nombre: 'Encontrando pasajero...',
        estado: PasajeroEstado.buscando,
      ),
    );

    final nuevoCupo = Cupo(
      ruta: _selectedRuta!,
      fechaHora: _selectedDateTime!,
      pasajeros: _selectedPassengers!,
      capacidad: capacidad, // Guarda el entero
      listaPasajeros: initialPasajeros, // Guarda la lista inicial
    );
    final user = context.read<SessionProvider>().current;
    try {
      final cupoBD = await firebaseServices.createTrip(
        nuevoCupo.fechaHora,
        nuevoCupo.capacidad,
        nuevoCupo.listaPasajeros,
        nuevoCupo.ruta.nombreMostrado,
        _selectedRuta!.zona,
        _selectedRuta!.destino,
        _estadoViaje.toString(),
        user!.vehicle,
        user.firstName,
      );
      if (cupoBD == null) {
        return;
      } else {
        print('Cupo confirmado con ID: $cupoBD');
        setState(() {
          _isCupoLoading = true;
          id_Viaje = cupoBD;
        });
        Future.delayed(const Duration(seconds: 5), () {
          if (mounted) {
            // Verificar que el widget todavía está en el árbol.
            setState(() {
              _isCupoLoading = false;
              _isCupoLoad = true;
              _selectedRuta = null;
              _selectedDateTime = null;
              _selectedPassengers = null;
            });

            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                // Verificar que el widget todavía está en el árbol.
                setState(() {
                  _isCupoLoad = false;
                  _cupoCreado = nuevoCupo;
                  _estadoViaje = EstadoViaje.buscando;
                });
              }
            });
          }
        });
      }
    } catch (e) {
      print("Error al crear el viaje desde el front: $e");
      if (mounted) {
        // 7. Si falla, detén la carga y muestra un error
        setState(() {
          _isCupoLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear el cupo: $e'),
            backgroundColor: kUAORed,
          ),
        );
        return null;
      }
    }
    // Llama a confirmar el cupo
  }

  void _cancelarCupo() {
    setState(() {
      _cupoCreado = null;
      _estadoViaje = EstadoViaje.cancelado;
    });
    firebaseServices.updateTripStatus(id_Viaje, _estadoViaje.toString());
    // Opcional: Mostrar un SnackBar de confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cupo cancelado.'),
        backgroundColor: kTextSubtitle,
      ),
    );
  }

  // Confirma el cupo y lo transforma en un viaje "no iniciado".
  Future<String?> _confirmarCupo() async {
    // Aquí iría la llamada al backend para crear el viaje.
    // El backend debería devolver el viaje creado.

    /*print(
      "Llamando al backend: Crear Viaje con cupo ID: ${_cupoCreado!.ruta.nombreMostrado}",
    );*/

    setState(() {
      _estadoViaje = EstadoViaje.confirmado; // Cambia el estado
    });
  }

  // Cambia el estado del viaje de "no iniciado" a "iniciado".
  void _iniciarViaje() {
    // Aquí iría la llamada al backend para actualizar el estado del viaje.
    print(
      "Llamando al backend: Iniciar Viaje ID: ${_cupoCreado!.ruta.nombreMostrado}",
    );

    setState(() {
      _estadoViaje = EstadoViaje.iniciado; // Cambia el estado
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('¡Viaje iniciado! Que tengas un buen recorrido.'),
        backgroundColor: kUAORedDark, // Usar un color informativo
      ),
    );
  }

  // --- Estructura Principal de la UI ---
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
  // AppBar personalizado.
  PreferredSizeWidget _buildAppBar() {
    final user = context.watch<SessionProvider>().current;
    final firstName = user?.firstName ?? 'Usuario';

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
            radius: 24,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 32, color: kTextPlaceholder),
          ),
          const SizedBox(width: 12),
          // Saludo y ubicación
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '¡Hola de nuevo $firstName!',
                style: const TextStyle(
                  color: kTextTitle,
                  fontSize: 18,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: const [
                  Icon(Icons.location_on, size: 14, color: kUAORedDark),
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
      titleSpacing: 0,
    );
  }

  /// Cuerpo principal de la pantalla.
  Widget _buildBody() {
    // Se usa SingleChildScrollView para evitar overflow si el contenido crece
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        // Título de la sección de viajes
        children: [
          const Text(
            'Viajes',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: kTextTitle,
              fontFamily: 'Inter',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _cupoCreado != null
                ? 'Esperando a los pasajeros que se unan'
                : 'Publica tu proximo cupo y encuentra pasajeros',
            style: TextStyle(
              fontSize: 14,
              fontFamily: 'Inter',
              color: kTextSubtitle,
            ),
          ),
          const SizedBox(height: 8),

          // --- Lógica de Tarjetas Colapsables ---
          AnimatedCrossFade(
            // Tarjeta "Nuevo Cupo"
            firstChild: _buildSeccionCupo(),
            // Tarjeta "Nueva Ruta"
            secondChild: _buildCrearRutaCard(),
            // El estado `_isCrearRutaVisible` decide cuál mostrar
            crossFadeState: _isCrearRutaVisible
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 300),
            firstCurve: Curves.easeInOut,
            secondCurve: Curves.easeInOut,
          ),
          const SizedBox(height: 24),
          // Solo mostrar el botón si no hay un cupo activo
          if (_cupoCreado == null)
            Column(
              children: [_buildToggleRutaButton(), const SizedBox(height: 24)],
            ),
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
          _buildHistorialPlaceholder(), // Reutilizado de home_conductor_page
        ],
      ),
    );
  }

  Widget _buildSeccionCupo() {
    if (_isCupoLoading) {
      return _buildLoadingCard();
    }
    if (_isCupoLoad) {
      return _buildLoadCard(message: 'Cupo publicado con éxito!');
    }
    /*if (_cupoCreado != null) {
      return _buildCupoActivoCard(_cupoCreado!, _estadoViaje);
    }*/

    // --- ESTA ES LA LÓGICA CLAVE ---
    // Si tenemos un cupo activo (con ID), empezamos a escuchar
    if (_cupoCreado != null && id_Viaje.isNotEmpty) {
      print("cupo es diferente de null y id_viaje no esta vacio");
      return StreamBuilder<List<Pasajero>>(
        // 1. Llama a tu nueva función de Stream
        stream: firebaseServices.escucharPasajerosDelViaje(id_Viaje!),

        builder: (context, snapshot) {
          // Mientras carga la lista por primera vez
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: kUAORed),
            );
          }

          // Si el stream da un error
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          // Si tenemos datos (¡incluso si es una lista vacía!)
          if (snapshot.hasData) {
            // 3. ¡Esta es tu lista de pasajeros en tiempo real!
            final List<Pasajero> pasajerosEnVivo = snapshot.data!;

            // 4. Actualizamos el cupo local con la nueva lista
            // (Necesitas un método copyWith en tu clase Cupo)
            final cupoActualizado = _cupoCreado!.copyWith(
              listaPasajeros: pasajerosEnVivo,
            );

            // 5. Mostramos la tarjeta con los datos frescos
            return _buildCupoActivoCard(
              cupoActualizado,
              _estadoViaje, // El estado local (buscando, confirmado...)
            );
          }

          // Estado por defecto (no debería pasar si el stream funciona)
          return const Center(child: Text('Cargando cupo...'));
        },
      );
    }
    return _buildCrearCupoCard();
  }

  // --- Tarjeta para "Nuevo Cupo" ---
  Widget _buildCrearCupoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          // La sombra que queremos ver
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 6,
              spreadRadius: 0,
              offset: Offset(0, 3),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 6,
              spreadRadius: 0,
              offset: Offset(0, 3),
            ),
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

            // --- Fila para seleccionar una Ruta ---
            Row(
              children: [
                const Icon(
                  Icons.directions_car_filled,
                  color: kUAORed,
                  size: 28,
                ),
                const SizedBox(width: 12),
                // Si no hay rutas, muestra un chip deshabilitado. Si hay rutas, muestra un PopupMenuButton para seleccionarlas.
                if (_rutasGuardadas.isEmpty)
                  _buildSelectChip(
                    label: 'Crea una ruta primero',
                    hasDropdown: false,
                  )
                else
                  PopupMenuButton<Ruta>(
                    onSelected: (Ruta rutaSeleccionada) {
                      setState(() {
                        _selectedRuta = rutaSeleccionada;
                      });
                    },
                    itemBuilder: (BuildContext context) {
                      return _rutasGuardadas.map((Ruta ruta) {
                        return PopupMenuItem<Ruta>(
                          value: ruta,
                          child: Text(ruta.nombreMostrado),
                        );
                      }).toList();
                    },
                    child: _buildSelectChip(
                      // Muestra el nombre de la ruta seleccionada o un texto por defecto.
                      label:
                          _selectedRuta?.nombreMostrado ??
                          'Selecciona una ruta',
                      hasDropdown: true,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // --- Fila para Día y Hora ---
            Row(
              children: [
                const Icon(Icons.access_time_filled, color: kUAORed, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: kBorderColor),
                    ),
                    child: InkWell(
                      onTap: () async {
                        final DateTime? date = await showDatePicker(
                          context: context,
                          initialDate: _selectedDateTime ?? DateTime.now(),
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

            // --- Fila para Número de Pasajeros ---
            Row(
              children: [
                const Icon(Icons.people, color: kUAORed, size: 28),
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
                      _selectedPassengers =
                          ('$value pasajero${value > 1 ? "s" : ""}');
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- Botón principal de acción ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _crearCupo, // Llama a la nueva función
                style: ElevatedButton.styleFrom(
                  backgroundColor: kUAORed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Crear Cupo',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Tarjeta cupo activo  ---
  Widget _buildCupoActivoCard(Cupo cupo, EstadoViaje estado) {
    // --- Cálculo de progreso ---
    final int totalCapacidad = cupo.capacidad;
    final int pasajerosConfirmados = cupo.listaPasajeros
        .where((p) => p.estado == PasajeroEstado.confirmado)
        .length;
    // Previene división por cero si la capacidad es 0
    final double progress = (totalCapacidad > 0)
        ? (pasajerosConfirmados / totalCapacidad)
        : 0.0;

    // --- Condiciones del botón "Confirmar" ---
    final bool cupoLleno = pasajerosConfirmados == totalCapacidad;
    final bool esTiempoAnticipacion = DateTime.now().isAfter(
      cupo.fechaHora.subtract(const Duration(hours: 2)),
    );
    final bool puedeConfirmar = cupoLleno && esTiempoAnticipacion;

    final bool mostrarUIConfirmada =
        (estado == EstadoViaje.confirmado || estado == EstadoViaje.iniciado);

    // Estilo de texto principal para esta tarjeta
    const TextStyle titleStyle = TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.bold,
      color: kBG,
      fontFamily: 'Inter',
    );
    // Estilo de texto secundario para esta tarjeta
    const TextStyle infoStyle = TextStyle(
      fontSize: 16,
      color: kBG,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kUAORedDark02,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(60, 64, 67, 0.2),
              blurRadius: 5,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color.fromRGBO(60, 64, 67, 0.1),
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Sección Cupo ---
            const Text('Cupo', style: titleStyle),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.map_outlined,
              // Usamos los puntos formateados de la ruta
              text: cupo.ruta.puntosFormateados,
              style: infoStyle,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.access_time_filled_outlined,
              // Usamos el nuevo formateador de fecha
              text: _formatCupoDateTime(cupo.fechaHora),
              style: infoStyle,
            ),

            const SizedBox(height: 24),

            // --- Sección Pasajeros ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('Pasajeros', style: titleStyle),
                // --- Ocultar contador si el viaje está confirmado
                if (!mostrarUIConfirmada)
                  Text(
                    '$pasajerosConfirmados de $totalCapacidad',
                    style: infoStyle.copyWith(
                      color: kBG,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // --- Barra de Progreso Animada ---
            if (!mostrarUIConfirmada)
              Container(
                height: 6,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: kBG.withOpacity(0.3), // Color de fondo (track)
                  borderRadius: BorderRadius.circular(3),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            width: constraints.maxWidth * progress,
                            decoration: BoxDecoration(
                              color: kUAOOrange, // Color de la barra activa
                              borderRadius: BorderRadius.circular(3),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),

            // --- Lista dinámica de Pasajeros ---
            Column(
              children: cupo.listaPasajeros.map((pasajero) {
                return Padding(
                  // Añade espacio solo por debajo de cada fila
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPasajeroRow(pasajero, estado),
                );
              }).toList(),
            ),

            const SizedBox(height: 8),

            // --- Botón Cancelar Cupo ---
            SizedBox(
              width: double.infinity,
              child: _buildBotonPrincipalCupo(cupo, estado, puedeConfirmar),
            ),
          ],
        ),
      ),
    );
  }

  // ---- botón de acción principal para la tarjeta de cupo activo ---
  Widget _buildBotonPrincipalCupo(
    Cupo cupo,
    EstadoViaje estado,
    bool puedeConfirmar,
  ) {
    // Caso 01: El viaje ya está INICIADO
    if (estado == EstadoViaje.iniciado) {
      return ElevatedButton.icon(
        onPressed: null, // Deshabilitado, el viaje está en curso
        style: ElevatedButton.styleFrom(
          backgroundColor: kUAOOrange.withAlpha(50),
          foregroundColor: kBG.withAlpha(70),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: Icon(Icons.check, color: kBG.withAlpha(70)),
        label: const Text(
          'Viaje En Curso',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Caso 2: El viaje está CONFIRMADO (listo para iniciar)
    if (estado == EstadoViaje.confirmado) {
      return ElevatedButton.icon(
        onPressed: _iniciarViaje, // NUEVA ACCIÓN
        style: ElevatedButton.styleFrom(
          backgroundColor: kUAOOrange,
          foregroundColor: kBG,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.play_arrow, color: kBG),
        label: const Text(
          'Iniciar Viaje',
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Caso 3: El cupo está BUSCANDO y SÍ CUMPLE condiciones para confirmar
    if (estado == EstadoViaje.buscando && puedeConfirmar) {
      return ElevatedButton.icon(
        onPressed: _confirmarCupo,
        style: ElevatedButton.styleFrom(
          backgroundColor: kUAOOrange,
          foregroundColor: kBG,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        icon: const Icon(Icons.check_circle_outline, color: kBG),
        label: const Text(
          'Confirmar Cupo', // Nuevo Texto
          style: TextStyle(
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // Caso 4: Buscando viaje, no cumple condiciones
    return ElevatedButton(
      onPressed: _cancelarCupo,
      style: ElevatedButton.styleFrom(
        backgroundColor: kUAOOrange,
        foregroundColor: kBG,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      child: const Text(
        'Cancelar Cupo',
        style: TextStyle(
          fontSize: 16,
          fontFamily: 'Inter',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // --- Widget auxiliar para mostrar una fila de información en la tarjeta de cupo activo. ---
  Widget _buildInfoRow({
    required IconData icon,
    required String text,
    required TextStyle style,
  }) {
    return Row(
      children: [
        Icon(icon, color: kBG, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: style, overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  // Widget auxiliar para mostrar una fila de pasajero en la tarjeta de cupo activo.
  Widget _buildPasajeroRow(Pasajero pasajero, EstadoViaje estadoViaje) {
    // Determina el estilo basado en el estado del pasajero
    bool esConfirmado = pasajero.estado == PasajeroEstado.confirmado;
    bool mostrarBotonRechazar =
        esConfirmado && (estadoViaje == EstadoViaje.buscando);

    return Row(
      children: [
        Icon(Icons.person_outline, color: kBG, size: 24),
        const SizedBox(width: 12),
        Text(
          pasajero.nombre, // Usa el nombre del modelo
          style: TextStyle(
            fontSize: 16,
            // Texto blanco si está confirmado, gris si está buscando
            color: esConfirmado ? kBG : kBorderColor,
            fontFamily: 'Inter',
            fontWeight: esConfirmado ? FontWeight.w500 : FontWeight.normal,
            fontStyle: esConfirmado ? FontStyle.normal : FontStyle.italic,
          ),
        ),
        const Spacer(),
        if (mostrarBotonRechazar) // Muestra el botón solo si está confirmado
          ElevatedButton(
            onPressed: () {
              // TODO: Implementar lógica para rechazar pasajero
              // (ej. llamar al backend con pasajero.id)
              firebaseServices.deletePassengerFromTrip(id_Viaje,pasajero.id!,pasajero.nombre,1);
              print("Rechazar pasajero con ID: ${pasajero.id}");
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kBG,
              foregroundColor: const Color.fromARGB(255, 0, 0, 0),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Rechazar'),
          ),
      ],
    );
  }

  // --- Tarjeta Anamacion de carga  ---
  Widget _buildLoadingCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 6,
              spreadRadius: 0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación de Lottie desde una URL.
            Lottie.network(
              'https://lottie.host/8bd84439-c5ad-496a-94d9-997354e1e851/hLPHFdiRvA.json',
              width: 256,
            ),
            // Animación de puntos progresivos.
            LoadingAnimationWidget.staggeredDotsWave(
              color: kUAORedDark02,
              size: 48,
            ),
            const SizedBox(height: 24),
            // Texto informativo.
            const Text(
              'Publicando tu cupo...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: kTextTitle,
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Tarjeta Animacion de exito  ---
  Widget _buildLoadCard({required String message}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              blurRadius: 6,
              spreadRadius: 0,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animación de Lottie desde una URL.
            Lottie.network(
              'https://lottie.host/332642b0-def2-4876-bcde-4d260813e934/BHfkPEd2N3.json',
              width: 154,
            ),
            const SizedBox(height: 24),
            // Texto informativo.
            AnimatedTextKit(
              animatedTexts: [
                BounceAnimatedText(
                  message,
                  textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: kTextTitle,
                    fontFamily: 'Inter',
                  ),
                ),
              ],
              totalRepeatCount: 1,
              pause: const Duration(milliseconds: 100),
              displayFullTextOnTap: true,
              stopPauseOnTap: true,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // --- Widget auxiliar para los chips de selección dentro de la tarjeta ---
  Widget _buildSelectChip({
    IconData? icon,
    required String label,
    bool hasDropdown = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kBG,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: kBorderColor),
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
      ),
    );
  }

  // --- Tarjeta para "Nuevo Ruta" ---
  Widget _buildCrearRutaCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kUAORedDark02,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Color.fromRGBO(60, 64, 67, 0.2),
              blurRadius: 5,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
            BoxShadow(
              color: Color.fromRGBO(60, 64, 67, 0.1),
              blurRadius: 6,
              spreadRadius: 2,
              offset: Offset(0, 2),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nueva Ruta',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: kBG, // Texto blanco
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),

            // --- Fila para seleccionar la zona ---
            PopupMenuButton<String>(
              child: _buildNegativeSelectChip(
                icon: Icons.map_outlined,
                label: _selectedZona ?? 'Zona a la que te diriges',
                hasDropdown: true,
              ),
              itemBuilder: (context) =>
                  ['Norte', 'Sur-Centro', 'Sur', 'Oriente', 'Oeste']
                      .map(
                        (zona) => PopupMenuItem<String>(
                          value: zona,
                          child: Text(zona),
                        ),
                      )
                      .toList(),
              onSelected: (value) {
                setState(() {
                  _selectedZona = value;
                });
              },
            ),
            const SizedBox(height: 16),

            // --- Fila para ingresar el barrio al que se dirige ---
            _buildNegativeTextField(
              controller: _destinoController,
              icon: Icons.home_outlined, // Icono del PDF
              hintText: 'Barrio de destino',
            ),
            const SizedBox(height: 16),

            // --- Fila para ingresar los puntos a los que se dirige ---
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNegativeSelectChip(
                  icon: Icons.route_outlined,
                  label: 'Puntos a los que te diriges',
                  hasDropdown: true,
                  isSelected: _selectedPoints.isNotEmpty,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => StatefulBuilder(
                        builder: (context, setStateDialog) => AlertDialog(
                          title: Text(
                            'Selecciona los puntos',
                            style: TextStyle(
                              color: kTextTitle,
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            // Lista de puntos con selección
                            children: [
                              ...[
                                'Punto A',
                                'Punto B',
                                'Punto C',
                                'Punto D',
                              ].map((punto) {
                                bool isSelected = _selectedPoints.contains(
                                  punto,
                                );
                                // Widget para cada punto
                                return Container(
                                  margin: EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? kUAORedDark.withAlpha(10)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? kUAORedDark
                                          : kBorderColor,
                                      width: 1,
                                    ),
                                  ),
                                  // Lista de selección
                                  child: ListTile(
                                    leading: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.circle_outlined,
                                      color: isSelected
                                          ? kUAORedDark
                                          : kTextSubtitle,
                                    ),
                                    title: Text(
                                      punto,
                                      style: TextStyle(
                                        color: isSelected
                                            ? kUAORedDark
                                            : kTextTitle,
                                        fontWeight: isSelected
                                            ? FontWeight.w400
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    // Manejador de selección
                                    onTap: () {
                                      setStateDialog(() {
                                        setState(() {
                                          if (isSelected) {
                                            _selectedPoints.remove(punto);
                                          } else {
                                            _selectedPoints.add(punto);
                                          }
                                        });
                                      });
                                    },
                                  ),
                                );
                              }),
                              // Muestra el número de puntos seleccionados
                              if (_selectedPoints.isNotEmpty) ...[
                                SizedBox(height: 22),
                                Text(
                                  'Puntos seleccionados: ${_selectedPoints.length}',
                                  style: TextStyle(
                                    color: kTextTitle,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          // Botón para cerrar el diálogo
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                foregroundColor: kUAORedDark,
                              ),
                              child: Text('Cerrar'),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                // Muestra los puntos seleccionados como chips
                if (_selectedPoints.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _selectedPoints
                        .map(
                          (punto) => Chip(
                            label: Text(punto),
                            deleteIcon: Icon(Icons.close, size: 16),
                            onDeleted: () {
                              setState(() {
                                _selectedPoints.remove(punto);
                              });
                            },
                            backgroundColor: kUAORedDark.withAlpha(20),
                            labelStyle: TextStyle(color: kUAORedDark),
                            deleteIconColor: kUAORedDark,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // --- Checkbox para "Ida y Vuelta" ---
            _buildNegativeCheckbox(
              label: 'Marcar ruta como ida y vuelta',
              value: _isIdaYVuelta,
              onChanged: (bool? newValue) {
                setState(() {
                  _isIdaYVuelta = newValue ?? false;
                });
              },
            ),
            const SizedBox(height: 24),

            // --- Mapa de vista previa ---
            Container(
              height: 232,
              decoration: BoxDecoration(
                color: kUAORedDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(child: Icon(Icons.map, color: kBG, size: 50)),
            ),
            const SizedBox(height: 24),

            // --- Botón principal de acción ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  _guardarNuevaRuta();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: kUAORedDark,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                icon: const Icon(Icons.add),
                label: const Text(
                  'Crear Ruta',
                  style: TextStyle(
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Widget auxiliar para los chips de selección dentro de la tarjeta Ruta ---
  Widget _buildNegativeSelectChip({
    required IconData icon,
    required String label,
    bool hasDropdown = false,
    bool isSelected = false,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: kBG,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: kUAORedDark02, width: 2)
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: kTextTitle, size: 24),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: kTextTitle,
                fontSize: 16,
                fontFamily: 'Inter',
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(Icons.check_circle, color: kUAORedDark02, size: 20)
            else if (hasDropdown)
              const Icon(
                Icons.keyboard_arrow_down,
                color: kTextTitle,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para el campo de texto Ruta ---
  Widget _buildNegativeTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hintText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: kBG,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: kTextTitle),
        // Texto que escribe el usuario
        decoration: InputDecoration(
          icon: Icon(icon, color: kTextTitle, size: 24),
          border: InputBorder.none,
          hintText: hintText,
          hintStyle: const TextStyle(
            color: kTextTitle,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // --- Widget auxiliar para el Checkbox Ruta ---
  Widget _buildNegativeCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Row(
      children: [
        Theme(
          data: Theme.of(context).copyWith(unselectedWidgetColor: kUAOOrange),
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: kUAOOrange,
            checkColor: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: kBG,
            fontSize: 16,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // --- Botón para alternar entre las tarjetas ---
  Widget _buildToggleRutaButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          // Lógica para alternar las tarjetas
          setState(() {
            _isCrearRutaVisible = !_isCrearRutaVisible;
          });
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: kUAORed,
          side: const BorderSide(color: kUAORed, width: 1.5),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        // El icono y el texto cambian según el estado
        icon: Icon(
          _isCrearRutaVisible ? Icons.directions_car_outlined : Icons.add,
          size: 20,
        ),
        label: Text(
          _isCrearRutaVisible ? 'Crear un "Nuevo Cupo"' : 'Crea una nueva ruta',
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // --- Placeholder para el historial de viajes ---
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

  // --- Barra de navegación inferior ---
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      backgroundColor: Colors.white,
      selectedItemColor: kUAORed,
      unselectedItemColor: kTextPlaceholder,
      type: BottomNavigationBarType.fixed, // Mantiene el fondo blanco
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.directions_car),
          label: 'Viajes',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Actividad',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
