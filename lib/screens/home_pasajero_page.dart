import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cuposuao/services/firebase_services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cuposuao/services/session_provider.dart';


/// Color principal de la aplicación (UAO Red)
const Color kUAORed = Color(0xFFD61F14);

const Color kUAORedDark = Color.fromRGBO(138, 20, 40, 1);

const Color kUAORedDark02 = Color.fromARGB(255, 172, 11, 51);

const Color kUAOOrange = Color.fromARGB(255, 255, 130, 108);
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

class HomePasajeroPage extends StatefulWidget {
  const HomePasajeroPage({super.key});

  @override
  State<HomePasajeroPage> createState() => _HomePasajeroPageState();
}

class _HomePasajeroPageState extends State<HomePasajeroPage> {
  // Simula nombre de usuario (traer de tu auth/estado)
  final FirebaseServices _firebaseServices = FirebaseServices();
  
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
            radius: 24, // Tamaño ajustado
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 32, color: kTextTitle),
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
                  Icon(
                    Icons.location_on,
                    size: 14,
                    color: kUAORedDark,
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

  

  // --- Mock data (conéctalo a tu backend) ---
  List<Trip?> _allTrips = [
    Trip(
      id: 'T-001',
      driverName: 'Laura G.',
      origin: 'Cali',
      destination: 'Palmira',
      dateTime: DateTime.now().add(const Duration(hours: 3)),
      price: 18000,
      seatsAvailable: 2,
      allowsLuggage: true,
      rating: 4.8,
      vehicle: 'Kia Picanto',
    ),
    Trip(
      id: 'T-002',
      driverName: 'Santiago P.',
      origin: 'Cali',
      destination: 'Jamundí',
      dateTime: DateTime.now().add(const Duration(hours: 5)),
      price: 15000,
      seatsAvailable: 1,
      allowsLuggage: false,
      rating: 4.5,
      vehicle: 'Chevrolet Sail',
    ),
    Trip(
      id: 'T-003',
      driverName: 'Mariana R.',
      origin: 'Yumbo',
      destination: 'Cali',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      price: 22000,
      seatsAvailable: 3,
      allowsLuggage: true,
      rating: 4.9,
      vehicle: 'Mazda 3',
    ),
    Trip(
      id: 'T-003',
      driverName: 'Joan S.',
      origin: 'Vallegrande',
      destination: 'Autonoma de occidente',
      dateTime: DateTime.now().add(const Duration(days: 1, hours: 2)),
      price: 10000,
      seatsAvailable: 4,
      allowsLuggage: true,
      rating: 4.9,
      vehicle: 'Nissan kicks',
    ),
  ];

  // --- UI State ---
  List<Trip> _filtered = [];
  bool _loading = true;

  // --- Filtros ---
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  DateTime? _selectedDate;
  RangeValues _priceRange = const RangeValues(0, 50000);
  int _minSeats = 1;
  bool? _needsLuggage;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await fetchTrips();
    _applyFilters();
  }

  Future<void> fetchTrips() async {
    setState(() => _loading = true);

    try {
      // 1. Llama a tu nueva función de servicio
      final snapshot = await _firebaseServices.fetchTrips();

      // 2. Convierte los documentos de Firebase a tu modelo 'Trip'
      final List<Trip?> tripsFromDB = snapshot.docs.map((doc) {
        final dataObject = doc.data();
        
        if(dataObject==null){
          return null;
        }
        // Obtiene los datos del documento y fuerza el tipo no-nullable
        final data = dataObject as Map<String, dynamic>;

        // 3. Mapea los campos (¡cuidado con los nulos y tipos!)
        return Trip(
          id: doc.id, // Usa el ID del documento
          driverName: data['id'] as String? ?? 'Conductor',
          origin: data['origen'] as String? ?? 'Origen desconocido',
          destination: data['destino'] as String? ?? 'Destino desconocido',
          
          // ¡Importante! Firebase guarda Timestamp, tu modelo usa DateTime
          dateTime: (data['horaSalida'] as Timestamp?)?.toDate() ?? DateTime.now(), 
          
          price: (data['price'] as num?)?.toInt() ?? 0,
          seatsAvailable: (data['cantidad_Pasajeros'] as num?)?.toInt() ?? 0,
          allowsLuggage: data['allowsLuggage'] as bool? ?? true,
          rating: (data['rating'] as num?)?.toDouble() ?? 4.0, // Maneja números
          vehicle: data['vehicle'] as String? ?? 'Vehículo',
        );
      }).toList(); // Convierte todo a una Lista

      // 4. Actualiza el estado con los datos REALES
      setState(() {
        _loading = false;
        _allTrips = tripsFromDB;
        // _filtered = List.of(_allTrips); // 'applyFilters' se encargará de esto
      });

    } catch (e) {
      print("Error al cargar viajes: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar los viajes: $e'),
            backgroundColor: kUAORed,
          ),
        );
      }
      setState(() {
        _loading = false;
        _allTrips = []; // En caso de error, deja la lista vacía
      });
    }
    
    //await Future.delayed(const Duration(milliseconds: 600));
    
    setState(() {
      _loading = false;
      _filtered = List.of(_allTrips as Iterable<Trip>);
    });
  }

  void _applyFilters() {
    final origin = _originCtrl.text.trim().toLowerCase();
    final dest = _destCtrl.text.trim().toLowerCase();
    final minPrice = _priceRange.start.round();
    final maxPrice = _priceRange.end.round();

    bool sameDay(DateTime a, DateTime b) =>
        a.year == b.year && a.month == b.month && a.day == b.day;

    setState(() {
      _filtered = _allTrips.whereType<Trip>().where((t) {
        final okOrigin =
            origin.isEmpty || t.origin.toLowerCase().contains(origin);
        final okDest =
            dest.isEmpty || t.destination.toLowerCase().contains(dest);
        final okDate = _selectedDate == null
            ? true
            : sameDay(t.dateTime, _selectedDate!);
        final okPrice = t.price >= minPrice && t.price <= maxPrice;
        final okSeats = t.seatsAvailable >= _minSeats;
        final okLuggage = _needsLuggage == null
            ? true
            : t.allowsLuggage == _needsLuggage;

        return okOrigin && okDest && okDate && okPrice && okSeats && okLuggage;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _originCtrl.clear();
      _destCtrl.clear();
      _selectedDate = null;
      _priceRange = const RangeValues(0, 50000);
      _minSeats = 1;
      _needsLuggage = null;
    });
    _applyFilters();
  }

  Future<void> _openFilterSheet() async {
    final tempOrigin = TextEditingController(text: _originCtrl.text);
    final tempDest = TextEditingController(text: _destCtrl.text);
    DateTime? tempDate = _selectedDate;
    RangeValues tempRange = _priceRange;
    int tempSeats = _minSeats;
    bool? tempLuggage = _needsLuggage;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: kBG,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 8,
          ),
          child: StatefulBuilder(
            builder: (ctx, setMState) {
              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _SheetHandleTitle(title: 'Filtros de búsqueda'),
                    const SizedBox(height: 8),

                    // Origen / Destino
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: tempOrigin,
                            decoration: const InputDecoration(
                              labelText: 'Origen',
                              labelStyle: TextStyle(color: kTextSubtitle),
                              prefixIcon: Icon(Icons.trip_origin, color: kUAORed),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: kBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: kUAORed, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: tempDest,
                            decoration: const InputDecoration(
                              labelText: 'Destino',
                              labelStyle: TextStyle(color: kTextSubtitle),
                              prefixIcon: Icon(Icons.flag, color: kUAORed),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: kBorderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: kUAORed, width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Fecha
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kUAORed,
                              side: const BorderSide(color: kUAORed),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              final now = DateTime.now();
                              final picked = await showDatePicker(
                                context: ctx,
                                firstDate: DateTime(now.year, now.month, now.day),
                                lastDate: now.add(const Duration(days: 365)),
                                initialDate: tempDate ?? now,
                                helpText: 'Selecciona una fecha',
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: kUAORed,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: kTextTitle,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) setMState(() => tempDate = picked);
                            },
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              tempDate == null
                                  ? 'Fecha (opcional)'
                                  : '${tempDate!.day.toString().padLeft(2, '0')}/${tempDate!.month.toString().padLeft(2, '0')}/${tempDate!.year}',
                              style: const TextStyle(color: kTextTitle),
                            ),
                          ),
                        ),
                        if (tempDate != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Quitar fecha',
                            onPressed: () => setMState(() => tempDate = null),
                            icon: const Icon(Icons.close, color: kUAORedDark),
                          )
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Rango de precio
                    const Text('Rango de precio (COP)',
                        style: TextStyle(fontWeight: FontWeight.w600, color: kTextTitle)),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: kUAORed,
                        inactiveTrackColor: kBorderColor,
                        thumbColor: kUAORed,
                        overlayColor: kUAORed.withOpacity(0.12),
                        valueIndicatorColor: kUAORedDark,
                      ),
                      child: RangeSlider(
                        values: tempRange,
                        min: 0,
                        max: 100000,
                        divisions: 100,
                        labels: RangeLabels(
                          tempRange.start.round().toString(),
                          tempRange.end.round().toString(),
                        ),
                        onChanged: (v) => setMState(() => tempRange = v),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Chip(
                          label: Text('\$${tempRange.start.round()}',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: kUAORedDark02,
                        ),
                        Chip(
                          label: Text('\$${tempRange.end.round()}',
                              style: const TextStyle(color: Colors.white)),
                          backgroundColor: kUAORedDark02,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Asientos mínimos
                    Row(
                      children: [
                        const Text('Asientos mínimos:',
                            style: TextStyle(fontWeight: FontWeight.w600, color: kTextTitle)),
                        const SizedBox(width: 12),
                        _Stepper(
                          value: tempSeats,
                          min: 1,
                          max: 6,
                          onChanged: (v) => setMState(() => tempSeats = v),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Equipaje
                    const Text('Equipaje',
                        style: TextStyle(fontWeight: FontWeight.w600, color: kTextTitle)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: tempLuggage == null,
                          selectedColor: kUAOOrange.withOpacity(0.2),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: kBorderColor),
                          labelStyle: TextStyle(
                            color: tempLuggage == null ? kUAORedDark : kTextTitle,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setMState(() => tempLuggage = null),
                        ),
                        ChoiceChip(
                          label: const Text('Permite equipaje'),
                          selected: tempLuggage == true,
                          selectedColor: kUAOOrange.withOpacity(0.2),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: kBorderColor),
                          labelStyle: TextStyle(
                            color: tempLuggage == true ? kUAORedDark : kTextTitle,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setMState(() => tempLuggage = true),
                        ),
                        ChoiceChip(
                          label: const Text('Sin equipaje'),
                          selected: tempLuggage == false,
                          selectedColor: kUAOOrange.withOpacity(0.2),
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: kBorderColor),
                          labelStyle: TextStyle(
                            color: tempLuggage == false ? kUAORedDark : kTextTitle,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (_) => setMState(() => tempLuggage = false),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: kUAORed,
                              side: const BorderSide(color: kUAORed),
                              backgroundColor: Colors.white,
                            ),
                            onPressed: () {
                              tempOrigin.clear();
                              tempDest.clear();
                              tempDate = null;
                              tempRange = const RangeValues(0, 50000);
                              tempSeats = 1;
                              tempLuggage = null;
                              setMState(() {});
                            },
                            child: const Text('Limpiar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: kUAORed,
                              foregroundColor: Colors.white,
                              elevation: 0,
                            ),
                            onPressed: () {
                              _originCtrl.text = tempOrigin.text;
                              _destCtrl.text = tempDest.text;
                              _selectedDate = tempDate;
                              _priceRange = tempRange;
                              _minSeats = tempSeats;
                              _needsLuggage = tempLuggage;
                              Navigator.pop(ctx);
                              _applyFilters();
                            },
                            icon: const Icon(Icons.filter_alt),
                            label: const Text('Aplicar filtros'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _onRefresh() async {
    await fetchTrips();
    _applyFilters();
  }

  @override
  void dispose() {
    _originCtrl.dispose();
    _destCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBG,
      appBar: _buildAppBar(),
      drawer: _AppDrawer(onClose: () => Navigator.of(context).pop()),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== Banner superior (gris, con hamburguesa y nombre) =====

            // ===== Título y descripción =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Buscar viaje',
                    style: TextStyle(
                      color: kTextTitle,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Filtra y encuentra cupos disponibles según tu origen, destino, fecha, '
                    'precio y número de asientos.',
                    style: TextStyle(color: kTextSubtitle),
                  ),
                ],
              ),
            ),

            // ===== Barra de búsqueda rápida =====
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _originCtrl,
                      decoration: InputDecoration(
                        hintText: 'Origen',
                        hintStyle: const TextStyle(color: kTextPlaceholder),
                        prefixIcon: const Icon(Icons.trip_origin, color: kUAORed),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kBorderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kUAORed, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _originCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, color: kUAORedDark),
                                onPressed: () {
                                  _originCtrl.clear();
                                  _applyFilters();
                                },
                              ),
                      ),
                      style: const TextStyle(color: kTextTitle),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 18, color: kTextSubtitle),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _destCtrl,
                      decoration: InputDecoration(
                        hintText: 'Destino',
                        hintStyle: const TextStyle(color: kTextPlaceholder),
                        prefixIcon: const Icon(Icons.flag, color: kUAORed),
                        isDense: true,
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kBorderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: const BorderSide(color: kUAORed, width: 1.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        suffixIcon: _destCtrl.text.isEmpty
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.clear, color: kUAORedDark),
                                onPressed: () {
                                  _destCtrl.clear();
                                  _applyFilters();
                                },
                              ),
                      ),
                      style: const TextStyle(color: kTextTitle),
                      onChanged: (_) => _applyFilters(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    onPressed: _openFilterSheet,
                    icon: const Icon(Icons.filter_list),
                    label: const Text('Filtros'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: kUAORed,
                      side: const BorderSide(color: kUAORed),
                    ),
                  ),
                ],
              ),
            ),

            // ===== Chips resumen de filtros =====
            _FilterChipsSummary(
              date: _selectedDate,
              priceRange: _priceRange,
              minSeats: _minSeats,
              luggage: _needsLuggage,
              onClearAll: _clearFilters,
              hasAny: _hasAnyFilterApplied,
            ),

            // ===== Lista =====
            Expanded(
              child: _loading
                  ? const _LoadingList()
                  : RefreshIndicator(
                      color: kUAORed,
                      onRefresh: _onRefresh,
                      child: _filtered.isEmpty
                          ? const _EmptyState()
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                              itemCount: _filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, i) {
                                final t = _filtered[i];
                                return TripCard(
                                  trip: t,
                                  onTap: () {
                                    // TODO: navegar a detalle
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: kUAORed,
        foregroundColor: Colors.white,
        onPressed: _openFilterSheet,
        icon: const Icon(Icons.search),
        label: const Text('Filtrar'),
      ),
    );
  }

  bool get _hasAnyFilterApplied {
    return _originCtrl.text.isNotEmpty ||
        _destCtrl.text.isNotEmpty ||
        _selectedDate != null ||
        _priceRange.start != 0 ||
        _priceRange.end != 50000 ||
        _minSeats > 1 ||
        _needsLuggage != null;
  }
}

// ================= Widgets auxiliares =================



class _AppDrawer extends StatelessWidget {
  const _AppDrawer({required this.onClose});
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Perfil'),
              onTap: onClose,
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Historial'),
              onTap: onClose,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------- Models & Cards ----------

class Trip {
  final String id;
  final String driverName;
  final String origin;
  final String destination;
  final DateTime dateTime;
  final int price; // COP
  final int seatsAvailable;
  final bool allowsLuggage;
  final double rating;
  final String vehicle;

  Trip({
    required this.id,
    required this.driverName,
    required this.origin,
    required this.destination,
    required this.dateTime,
    required this.price,
    required this.seatsAvailable,
    required this.allowsLuggage,
    required this.rating,
    required this.vehicle,
  });
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.onTap});

  final Trip trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final dt = trip.dateTime;
    final date =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    final time =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorderColor),
          ),
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: kUAORed.withOpacity(0.12),
                child: Text(
                  trip.driverName.split(' ').first.characters.first,
                  style: const TextStyle(color: kUAORed, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DefaultTextStyle(
                  style: const TextStyle(color: kTextTitle),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ruta
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${trip.origin} → ${trip.destination}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                                color: kTextTitle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            trip.allowsLuggage ? Icons.work : Icons.block,
                            size: 18,
                            color: trip.allowsLuggage ? kUAOOrange : kTextSubtitle,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Fecha/hora
                      Text('$date  ·  $time', style: const TextStyle(color: kTextSubtitle)),
                      const SizedBox(height: 6),
                      // Vehículo / calificación
                      Row(
                        children: [
                          const Icon(Icons.directions_car, size: 16, color: kTextSubtitle),
                          const SizedBox(width: 4),
                          Text(trip.vehicle, style: const TextStyle(color: kTextTitle)),
                          const SizedBox(width: 12),
                          const Icon(Icons.star, size: 16, color: kUAOOrange),
                          const SizedBox(width: 2),
                          Text(trip.rating.toStringAsFixed(1),
                              style: const TextStyle(color: kTextTitle)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Precio / asientos
                      Row(
                        children: [
                          Chip(
                            label: Text('\$${trip.price}',
                                style: const TextStyle(color: Colors.white)),
                            backgroundColor: kUAORed,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('${trip.seatsAvailable} asientos',
                                style: const TextStyle(color: kTextTitle)),
                            backgroundColor: kBG,
                            side: const BorderSide(color: kBorderColor),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---- Reutilizables del sheet/lista ----

class _SheetHandleTitle extends StatelessWidget {
  const _SheetHandleTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 4,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: kBorderColor,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: kTextTitle),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.search_off, size: 56, color: kTextSubtitle),
            SizedBox(height: 12),
            Text(
              'No encontramos viajes con esos filtros',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: kTextTitle),
            ),
            SizedBox(height: 6),
            Text(
              'Prueba cambiando el rango de precio, la fecha o el número de asientos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: kTextSubtitle),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemBuilder: (_, __) => const _ShimmerBox(height: 96),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemCount: 6,
    );
  }
}

class _ShimmerBox extends StatelessWidget {
  const _ShimmerBox({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: kBorderColor.withOpacity(0.35),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 10,
  });

  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Menos',
          onPressed: value > min ? () => onChanged(value - 1) : null,
          icon: const Icon(Icons.remove_circle_outline, color: kUAORedDark),
        ),
        Text('$value',
            style: const TextStyle(fontWeight: FontWeight.w600, color: kTextTitle)),
        IconButton(
          tooltip: 'Más',
          onPressed: value < max ? () => onChanged(value + 1) : null,
          icon: const Icon(Icons.add_circle_outline, color: kUAORedDark),
        ),
      ],
    );
  }
}

class _FilterChipsSummary extends StatelessWidget {
  const _FilterChipsSummary({
    required this.date,
    required this.priceRange,
    required this.minSeats,
    required this.luggage,
    required this.onClearAll,
    required this.hasAny,
  });

  final DateTime? date;
  final RangeValues priceRange;
  final int minSeats;
  final bool? luggage;
  final VoidCallback onClearAll;
  final bool hasAny;

  @override
  Widget build(BuildContext context) {
    if (!hasAny) return const SizedBox.shrink();

    final chips = <Widget>[];

    if (date != null) {
      chips.add(Chip(
        avatar: const Icon(Icons.calendar_today, size: 16, color: Colors.white),
        label: Text(
          '${date!.day.toString().padLeft(2, '0')}/${date!.month.toString().padLeft(2, '0')}/${date!.year}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: kUAORedDark02,
      ));
    }

    if (priceRange.start != 0 || priceRange.end != 50000) {
      chips.add(Chip(
        avatar: const Icon(Icons.attach_money, size: 16, color: Colors.white),
        label: Text(
          '\$${priceRange.start.round()} - \$${priceRange.end.round()}',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: kUAORed,
      ));
    }

    if (minSeats > 1) {
      chips.add(Chip(
        avatar: const Icon(Icons.event_seat, size: 16, color: kUAORed),
        label: Text('≥ $minSeats asientos', style: const TextStyle(color: kTextTitle)),
        backgroundColor: kBG,
        side: const BorderSide(color: kBorderColor),
      ));
    }

    if (luggage != null) {
      chips.add(Chip(
        avatar: Icon(Icons.work, size: 16, color: luggage! ? kUAOOrange : kTextSubtitle),
        label: Text(luggage! ? 'Con equipaje' : 'Sin equipaje',
            style: const TextStyle(color: kTextTitle)),
        backgroundColor: kBG,
        side: const BorderSide(color: kBorderColor),
      ));
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: chips
                    .map((c) => Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: c,
                        ))
                    .toList(),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: onClearAll,
            style: TextButton.styleFrom(foregroundColor: kUAORed),
            icon: const Icon(Icons.clear_all),
            label: const Text('Limpiar'),
          ),
        ],
      ),
    );
  }
}
