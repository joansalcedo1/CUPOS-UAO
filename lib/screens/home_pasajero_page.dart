import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_cuposuao/services/session_provider.dart';
import 'package:lottie/lottie.dart';


/// Color principal de la aplicación (UAO Red)
const Color kUAORed = Color(0xFFD61F14);

const Color kUAORedDark = Color.fromRGBO(138, 20, 40, 1);

const Color kUAORedDark02 = Color(0xFFAC0B33);

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
  //control local de reservas simuladas 
  final Set<String> _reservedIds = <String>{};
  //cuántos asientos reservó el usuario por viaje
  final Map<String, int> _reservedQty = <String, int>{};
  int _unseenReservations = 0;

  void _reserveTrip(Trip t, int qty) {
    if (_reservedIds.contains(t.id)) return;
    setState(() {
      _reservedIds.add(t.id);
      _reservedQty[t.id] = qty;
      _reservedTrips.add({
        'trip': t,
        'qty': qty,
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reservaste $qty asiento(s) con ${t.driverName}.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  void _cancelReservation(String tripId, {int? qty}) {
  final current = _reservedQty[tripId] ?? 0;
  if (current <= 0) return;

  final toCancel = (qty == null || qty <= 0 || qty > current) ? current : qty;
  final remaining = current - toCancel;

  setState(() {
    if (remaining <= 0) {
      _reservedIds.remove(tripId);
      _reservedQty.remove(tripId);
      _reservedTrips.removeWhere((r) => r['trip'].id == tripId);
    } else {
      _reservedQty[tripId] = remaining;
      final idx = _reservedTrips.indexWhere((r) => r['trip'].id == tripId);
      if (idx != -1) {
        _reservedTrips[idx]['qty'] = remaining;
      }
    }
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        remaining <= 0
          ? 'Reserva cancelada.'
          : 'Cancelaste $toCancel asiento(s). Quedan $remaining.'
      ),
      duration: const Duration(seconds: 2),
    ),
  );
}

void _openReserveSheet(Trip t) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      int qty = 1; // por defecto
      final maxQty = t.seatsAvailable.clamp(0, 6); // limita a 6 por UX si quieres

      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setMState) {
            final dt = t.dateTime;
            final date = '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')}/${dt.year}';
            final time = '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
            final total = t.price * qty;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tirita
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: kBorderColor, borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const Text('Confirmar reserva',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextTitle)),
                const SizedBox(height: 12),

                // Conductor
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: kUAORed.withOpacity(0.12),
                    child: Text(t.driverName.split(' ').first.characters.first,
                        style: const TextStyle(color: kUAORed, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(t.driverName, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${t.vehicle}  •  $date  •  $time'),
                ),

                const SizedBox(height: 8),

                // Selector de asientos
                Row(
                  children: [
                    const Text('Asientos', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Menos',
                      onPressed: qty > 1 ? () => setMState(() => qty--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$qty', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    IconButton(
                      tooltip: 'Más',
                      onPressed: qty < maxQty ? () => setMState(() => qty++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Total
                Row(
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Chip(
                      label: Text('\$$total', style: const TextStyle(color: Colors.white)),
                      backgroundColor: kUAORed,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Acciones
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kUAORed),
                          foregroundColor: kUAORed,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (t.seatsAvailable <= 0) ? null : () async {
                          Navigator.pop(ctx);       // cierra el sheet
                          _reserveTrip(t, qty);
                          _unseenReservations++;     // guarda la reserva (ya existente) 【0: L3-L12】
                          await _showReservationSuccessDialog(); // muestra modal con check
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kUAORed, foregroundColor: Colors.white,
                        ),
                        child: const Text('Reservar ahora'),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      );
    },
  );
}

void _openCancelSheet(Trip t) {
  final reserved = _reservedQty[t.id] ?? 0;
  if (reserved <= 0) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('No tienes asientos reservados en este viaje.')),
    );
    return;
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      int qty = 1; // por defecto cancelar 1
      final maxQty = reserved;

      return Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 12,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
        ),
        child: StatefulBuilder(
          builder: (ctx, setMState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: kBorderColor, borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Cancelar asientos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: kTextTitle),
                ),
                const SizedBox(height: 8),
                Text(
                  'Tienes $reserved asiento(s) reservados. ¿Cuántos deseas cancelar?',
                  style: const TextStyle(color: kTextSubtitle),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => setMState(() {
                        if (qty > 1) qty--;
                      }),
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Expanded(
                      child: Slider(
                        min: 1,
                        max: maxQty.toDouble(),
                        divisions: (maxQty > 1) ? (maxQty - 1) : 1,
                        value: qty.toDouble(),
                        label: '$qty',
                        onChanged: (v) => setMState(() => qty = v.round()),
                        activeColor: kUAORed,
                        thumbColor: kUAORed,
                      ),
                    ),
                    IconButton(
                      onPressed: () => setMState(() {
                        if (qty < maxQty) qty++;
                      }),
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: kUAORed),
                          foregroundColor: kUAORed,
                        ),
                        child: const Text('Volver'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _cancelReservation(t.id, qty: qty);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kUAORed, foregroundColor: Colors.white,
                        ),
                        child: const Text('Confirmar'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _cancelReservation(t.id); // cancela todo
                    },
                    child: const Text(
                      'Cancelar todos los asientos',
                      style: TextStyle(color: kTextSubtitle, decoration: TextDecoration.underline),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
              ],
            );
          },
        ),
      );
    },
  );
}




  // Simula nombre de usuario (traer de tu auth/estado)
  int _selectedIndex = 0;

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

  Widget _buildBottomNavigationBar() {
  final int badgeCount = _unseenReservations; //  ahora usa “no vistas”
  Widget _withBadge(Widget icon) {
    if (badgeCount <= 0) return icon;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        icon,
        Positioned(
          right: -6,
          top: -2,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Text(
              badgeCount > 99 ? '99+' : '$badgeCount',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  return BottomNavigationBar(
    currentIndex: _selectedIndex,
    onTap: _onItemTapped, //  usa el handler de arriba
    selectedItemColor: kUAORed,
    unselectedItemColor: kTextPlaceholder,
    items: [
      const BottomNavigationBarItem(
        icon: Icon(Icons.directions_car),
        label: 'Viajes',
      ),
      BottomNavigationBarItem(
        icon: _withBadge(const Icon(Icons.bookmark_added_outlined)),
        label: 'Mis reservas',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person),
        label: 'Perfil',
      ),
    ],
  );
}



  Widget _buildTripsSection() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
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
                  prefixIcon:
                      const Icon(Icons.trip_origin, color: kUAORed),
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
                    borderSide:
                        const BorderSide(color: kUAORed, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _originCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear,
                              color: kUAORedDark),
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
            const Icon(Icons.arrow_forward,
                size: 18, color: kTextSubtitle),
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
                    borderSide:
                        const BorderSide(color: kUAORed, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  suffixIcon: _destCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear,
                              color: kUAORedDark),
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

      // ===== Lista de viajes =====
      Expanded(
        child: _loading
            ? const _LoadingList()
            : RefreshIndicator(
                color: kUAORed,
                onRefresh: _onRefresh,
                child: _filtered.isEmpty
                    ? const _EmptyState()
                    : ListView.separated(
                        padding:
                            const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: _filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (ctx, i) {
                          final t = _filtered[i];
                          return TripCard(
                            trip: t,
                            onTap: () {},
                            onReserve: () => _openReserveSheet(t),
                            reserved: _reservedIds.contains(t.id),
                          );
                        },
                      ),
              ),
      ),
    ],
  );
}

  Widget _buildMyReservations() {
  if (_reservedTrips.isEmpty) {
    return const Center(
      child: Text('Aún no has hecho reservas.',
          style: TextStyle(color: kTextSubtitle)),
    );
  }

  return ListView.separated(
    padding: const EdgeInsets.all(16),
    separatorBuilder: (_, __) => const SizedBox(height: 12),
    itemCount: _reservedTrips.length,
    itemBuilder: (ctx, i) {
      final r = _reservedTrips[i];
      final t = r['trip'] as Trip;
      final qty = r['qty'] as int;
      final total = t.price * qty;
      final dt = t.dateTime;
      final date =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      final time =
          '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.origin} → ${t.destination}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: kTextTitle)),
              const SizedBox(height: 4),
              Text('$date  •  $time',
                  style: const TextStyle(color: kTextSubtitle)),

              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person, size: 18, color: kUAORedDark),
                  const SizedBox(width: 4),
                  Text(t.driverName,
                      style: const TextStyle(
                          color: kTextTitle, fontWeight: FontWeight.w500)),
                ],
              ),

              const SizedBox(height: 8),
              Row(
                children: [
                  Chip(
                    label: Text('$qty asiento(s)',
                        style: const TextStyle(color: kTextTitle)),
                    backgroundColor: kBG,
                    side: const BorderSide(color: kBorderColor),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text('\$$total',
                        style: const TextStyle(color: Colors.white)),
                    backgroundColor: kUAORed,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _openCancelSheet(t),
                    icon: const Icon(Icons.cancel_outlined),
                    label: const Text('Cancelar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kUAORed,
                      side: const BorderSide(color: kUAORed),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                'Abriendo chat con ${t.driverName}...')),
                      );
                    },
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('Chat'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kUAORed,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildProfileSection() {
  return const Center(
    child: Text('Sección de perfil (pendiente)',
        style: TextStyle(color: kTextSubtitle)),
  );
}


  // --- Mock data (conéctalo a tu backend) ---
  final List<Trip> _allTrips = [
    Trip(
      id: 'T-001',
      driverName: 'Laura G.',
      origin: 'UAO',
      destination: 'Flora',
      dateTime: DateTime.now().add(const Duration(hours: 3)),
      price: 8000,
      seatsAvailable: 2,
      
      rating: 4.8,
      vehicle: 'Kia Picanto',
    ),
    Trip(
      id: 'T-002',
      driverName: 'Santiago P.',
      origin: 'UAO',
      destination: 'Valle del lili',
      dateTime: DateTime.now().add(const Duration(hours: 5)),
      price: 5000,
      seatsAvailable: 1,
      
      rating: 4.5,
      vehicle: 'Chevrolet Sail',
    ),
    Trip(
      id: 'T-003',
      driverName: 'Mariana R.',
      origin: 'San Antonio',
      destination: 'UAO',
      dateTime: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
      price: 6000,
      seatsAvailable: 3,
      
      rating: 4.9,
      vehicle: 'Mazda 3',
    ),
  ];

  // --- UI State ---
  List<Trip> _filtered = [];
  bool _loading = true;
  // Guardar reservas (viaje + cantidad)
  final List<Map<String, dynamic>> _reservedTrips = [];

  // --- Filtros ---
  final _originCtrl = TextEditingController();
  final _destCtrl = TextEditingController();
  DateTime? _selectedDate;
  RangeValues _priceRange = const RangeValues(0, 15000);
  int _minSeats = 1;
  bool? _needsLuggage;

Future<void> _showReservationSuccessDialog() async {
  // Modal centrado, no cerrable tocando el fondo
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Animación de check (usa tu .lottie)
              Lottie.network(
                'https://lottie.host/1989f0e5-fbf8-4173-9803-a021f1246a10/MGitSE9klX.json',
                width: 300,
                repeat: true,
              ),
              const SizedBox(height: 8),
              const Text(
                '¡Reserva creada!',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Puedes verla en Mis reservas',
                style: TextStyle(color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kUAORedDark02,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Listo'),
              )
            ],
          ),
        ),
      );
    },
  );
}


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
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _loading = false;
      _filtered = List.of(_allTrips);
    });
  }

  /// Manejador para la barra de navegación inferior
 void _onItemTapped(int index) {
  setState(() {
    _selectedIndex = index;
    if (index == 1) {
      _unseenReservations = 0; // se limpia al entrar al apartado
    }
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
      _filtered = _allTrips.where((t) {
        final okOrigin =
            origin.isEmpty || t.origin.toLowerCase().contains(origin);
        final okDest =
            dest.isEmpty || t.destination.toLowerCase().contains(dest);
        final okDate = _selectedDate == null
            ? true
            : sameDay(t.dateTime, _selectedDate!);
        final okPrice = t.price >= minPrice && t.price <= maxPrice;
        final okSeats = t.seatsAvailable >= _minSeats;
        

        return okOrigin && okDest && okDate && okPrice && okSeats;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _originCtrl.clear();
      _destCtrl.clear();
      _selectedDate = null;
      _priceRange = const RangeValues(0, 15000);
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
                        max: 15000,
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
                              tempRange = const RangeValues(0, 15000);
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

    // ======== CONTENIDO PRINCIPAL ========
    body: SafeArea(
      child: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildTripsSection(),     // 0 - Buscar viaje
          _buildMyReservations(),   // 1 - Mis reservas
          _buildProfileSection(),   // 2 - Perfil
        ],
      ),
    ),

    // FAB solo visible en la pestaña de “Viajes”
    floatingActionButton: _selectedIndex == 0
        ? FloatingActionButton.extended(
            backgroundColor: kUAORed,
            foregroundColor: Colors.white,
            onPressed: _openFilterSheet,
            icon: const Icon(Icons.search),
            label: const Text('Filtrar'),
          )
        : null,

    bottomNavigationBar: _buildBottomNavigationBar(),
  );
}

  bool get _hasAnyFilterApplied {
    return _originCtrl.text.isNotEmpty ||
        _destCtrl.text.isNotEmpty ||
        _selectedDate != null ||
        _priceRange.start != 0 ||
        _priceRange.end != 15000 ||
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
    
    required this.rating,
    required this.vehicle,
  });
}

class TripCard extends StatelessWidget {
  const TripCard({
    super.key,
    required this.trip,
    this.onTap,
    this.onReserve,   
    this.reserved = false, 
  });

  final Trip trip;
  final VoidCallback? onTap;
  final VoidCallback? onReserve; 
  final bool reserved;           

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
                      // Precio / asientos
                      Row(
                        children: [
                          Chip(
                            label: Text('\$${trip.price}', style: const TextStyle(color: Colors.white)),
                            backgroundColor: kUAORed,
                            visualDensity: VisualDensity.compact,
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text('${trip.seatsAvailable} asientos', style: const TextStyle(color: kTextTitle)),
                            backgroundColor: kBG,
                            side: const BorderSide(color: kBorderColor),
                            visualDensity: VisualDensity.compact,
                          ),
                          const Spacer(),

                          // === BOTÓN RESERVAR ===
                          SizedBox(
                            height: 36,
                            child: ElevatedButton(
                              // si no pasas onReserve, no lo deshabilites para que VEAS el botón
                              onPressed: (trip.seatsAvailable <= 0)
                                  ? null
                                  : (onReserve ?? () {}),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kUAORed,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: const StadiumBorder(),
                                elevation: 0,
                                minimumSize: const Size(110, 36), // ancho mínimo para que no “desaparezca”
                              ),
                              child: Text(reserved ? 'Reservado' : 'Reservar'),
                            ),
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

    if (priceRange.start != 0 || priceRange.end != 15000) {
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
