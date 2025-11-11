import 'package:flutter/material.dart';
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

class TripOffer {
  final String id;
  final String origin;
  final String destination;
  final DateTime date;
  final int price; // COP
  final int seatsAvailable; // final (no mutar)
  final String driver;

  TripOffer({
    required this.id,
    required this.origin,
    required this.destination,
    required this.date,
    required this.price,
    required this.seatsAvailable,
    required this.driver,
  });
}

/// ===============================
/// Drawer simple (reemplázalo por el tuyo si ya existe)
/// ===============================
class _AppDrawer extends StatelessWidget {
  final VoidCallback onClose;
  const _AppDrawer({required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Cerrar'),
              onTap: onClose,
            ),
            const Divider(height: 1),
            const ListTile(
              leading: Icon(Icons.person),
              title: Text('Perfil'),
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// Página principal pasajero
/// ===============================
class HomePasajeroPage extends StatefulWidget {
  const HomePasajeroPage({Key? key}) : super(key: key);

  @override
  State<HomePasajeroPage> createState() => _HomePasajeroPageState();
}

class _HomePasajeroPageState extends State<HomePasajeroPage> {
  /// ------ Datos mock (reemplaza por tu origen real)
  final List<TripOffer> _allOffers = [
    TripOffer(
      id: 'A1',
      origin: 'San Fernando',
      destination: 'UAO',
      date: DateTime.now().add(const Duration(hours: 2)),
      price: 3500,
      seatsAvailable: 2,
      driver: 'Laura Gómez',
    ),
    TripOffer(
      id: 'B2',
      origin: 'Centro',
      destination: 'UAO',
      date: DateTime.now().add(const Duration(hours: 3)),
      price: 4000,
      seatsAvailable: 1,
      driver: 'Carlos Ruiz',
    ),
    TripOffer(
      id: 'C3',
      origin: 'Sur',
      destination: 'UAO',
      date: DateTime.now().add(const Duration(hours: 1, minutes: 30)),
      price: 3000,
      seatsAvailable: 3,
      driver: 'María Pérez',
    ),
  ];

  /// ------ Filtros (ajusta para empatar con tu UI existente)
  String? _filterOrigin;
  String? _filterDestination;
  DateTime? _filterDate;
  int? _maxPrice;
  int? _minSeats;

  /// ------ Estado local de reservas y cupos (sin tocar el modelo final)
  final List<String> _reservedIds = [];
  /// delta de asientos por id (p.ej. -1 si reservaste 1 asiento en esa oferta)
  final Map<String, int> _seatDeltaById = {};

  /// ===============================
  /// Helpers de asientos (no mutan el modelo)
  /// ===============================
  int _seatsLeftFor(TripOffer o) {
    final delta = _seatDeltaById[o.id] ?? 0;
    final left = o.seatsAvailable + delta;
    return left < 0 ? 0 : left;
  }

  void _decSeat(String id) {
    _seatDeltaById[id] = (_seatDeltaById[id] ?? 0) - 1;
  }

  void _incSeat(String id) {
    _seatDeltaById[id] = (_seatDeltaById[id] ?? 0) + 1;
  }

  /// ===============================
  /// Lógica de filtrado
  /// ===============================
  List<TripOffer> _filteredOffers() {
    final list = _allOffers.where((o) {
      final matchesOrigin = _filterOrigin == null || _filterOrigin!.isEmpty
          ? true
          : o.origin.toLowerCase().contains(_filterOrigin!.toLowerCase());

      final matchesDestination = _filterDestination == null || _filterDestination!.isEmpty
          ? true
          : o.destination.toLowerCase().contains(_filterDestination!.toLowerCase());

      final matchesDate = _filterDate == null
          ? true
          : (o.date.year == _filterDate!.year &&
              o.date.month == _filterDate!.month &&
              o.date.day == _filterDate!.day);

      final matchesPrice = _maxPrice == null ? true : o.price <= _maxPrice!;
      final seatsLeft = _seatsLeftFor(o);
      final matchesSeats = _minSeats == null ? true : seatsLeft >= _minSeats!;

      return matchesOrigin && matchesDestination && matchesDate && matchesPrice && matchesSeats;
    }).toList();

    list.sort((a, b) => a.date.compareTo(b.date));
    return list;
  }

  /// ===============================
  /// Acciones: Reservar / Cancelar
  /// ===============================
  void _reserve(TripOffer o) {
    final already = _reservedIds.contains(o.id);
    final seatsLeft = _seatsLeftFor(o);

    if (already) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ya reservaste este viaje.')),
      );
      return;
    }
    if (seatsLeft <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay asientos disponibles.')),
      );
      return;
    }

    setState(() {
      _reservedIds.add(o.id);
      _decSeat(o.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('¡Reserva realizada!')),
    );
  }

  void _cancelReservation(TripOffer o) {
    if (!_reservedIds.contains(o.id)) return;

    setState(() {
      _reservedIds.remove(o.id);
      _incSeat(o.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Reserva cancelada.')),
    );
  }

  /// ===============================
  /// UI: Banner superior gris con hamburguesa y nombre
  /// ===============================
  Widget _grayTopBanner(BuildContext context) {
    // TODO: Integra tu SessionProvider para traer el nombre real.
    const displayName = 'Kevin'; // <— reemplaza por tu nombre desde sesión.
    return Container(
      color: kUAORed,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(Icons.menu),
            tooltip: 'Menú',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '¡Hola de nuevo, $displayName!',
              style: const TextStyle(
                color: kTextTitle,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// UI: Card de oferta
  /// ===============================
  Widget _offerCard(TripOffer o) {
    final isReserved = _reservedIds.contains(o.id);
    final seatsLeft = _seatsLeftFor(o);
    final canReserve = seatsLeft > 0 && !isReserved;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.directions_car, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${o.origin} → ${o.destination}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${_formatDate(o.date)} • Conductor: ${o.driver}',
                      style: TextStyle(color: Colors.black.withOpacity(0.6))),
                  const SizedBox(height: 4),
                  Text('Precio: \$${o.price} • Asientos: $seatsLeft',
                      style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton(
              onPressed: canReserve ? () => _reserve(o) : null,
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(isReserved ? 'Reservado' : 'Reservar cupo'),
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// UI: Card de reserva
  /// ===============================
  Widget _reservationCard(TripOffer o) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0.6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.bookmark, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${o.origin} → ${o.destination}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text('${_formatDate(o.date)} • Conductor: ${o.driver}',
                      style: TextStyle(color: Colors.black.withOpacity(0.6))),
                  const SizedBox(height: 4),
                  Text('Precio: \$${o.price}', style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton.icon(
              onPressed: () => _cancelReservation(o),
              icon: const Icon(Icons.close),
              label: const Text('Cancelar'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===============================
  /// UI: Filtros (placeholder sencillo)
  /// Reemplázalo por tus propios widgets si ya los tienes.
  /// ===============================
  Widget _filtersBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título y descripción
          const Text(
            'Buscar viaje',
            style: TextStyle(
              color: kTextTitle,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Filtra y encuentra cupos disponibles según tu origen, destino, fecha, precio y número de asientos.',
            style: TextStyle(color: kTextSubtitle),
          ),
          const SizedBox(height: 12),

          // Origen / Destino
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Origen',
                    prefixIcon: Icon(Icons.place),
                  ),
                  onChanged: (v) => setState(() => _filterOrigin = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Destino',
                    prefixIcon: Icon(Icons.flag),
                  ),
                  onChanged: (v) => setState(() => _filterDestination = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Precio máx / Asientos mín
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Precio máx.',
                    prefixIcon: Icon(Icons.attach_money),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {
                    _maxPrice = v.isEmpty ? null : int.tryParse(v);
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Asientos mín.',
                    prefixIcon: Icon(Icons.event_seat),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) => setState(() {
                    _minSeats = v.isEmpty ? null : int.tryParse(v);
                  }),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Limpiar filtros
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                setState(() {
                  _filterOrigin = null;
                  _filterDestination = null;
                  _filterDate = null;
                  _maxPrice = null;
                  _minSeats = null;
                });
              },
              icon: const Icon(Icons.filter_alt_off),
              label: const Text('Limpiar filtros'),
            ),
          ),
        ],
      ),
    );
  }

  /// ===============================
  /// Utils
  /// ===============================
  String _formatDate(DateTime d) {
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yyyy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yyyy $hh:$mi';
  }

  /// ===============================
  /// BUILD
  /// ===============================
  @override
  Widget build(BuildContext context) {
    final offers = _filteredOffers();
    final reservedTrips = _allOffers.where((o) => _reservedIds.contains(o.id)).toList();

    return Scaffold(
      backgroundColor: kBG,
      drawer: _AppDrawer(onClose: () => Navigator.of(context).pop()),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kUAOOrange,
        foregroundColor: kTextTitle,
        title: const Text(''),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Banner superior gris (con hamburguesa + nombre)
            // Nota: usamos Builder para tener un contexto con Scaffold.of(context)
            Builder(builder: _grayTopBanner),

            // Filtros
            _filtersBar(),

            // Contenido: Lista de ofertas y Mis reservas
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 6),
                    child: Text(
                      'Cupos disponibles',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (offers.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text('No hay ofertas que coincidan con los filtros.'),
                    )
                  else
                    ...offers.map(_offerCard),

                  const SizedBox(height: 16),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: Text(
                      'Mis reservas',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                    ),
                  ),
                  if (reservedTrips.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Text('Aún no has reservado viajes.'),
                    )
                  else
                    ...reservedTrips.map(_reservationCard),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}