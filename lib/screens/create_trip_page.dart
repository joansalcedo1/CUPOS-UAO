import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cuposuao/screens/home_conductor_page.dart';
import 'package:flutter_cuposuao/services/firebase_services.dart'; // Importar el servicio

// Color de referencia usado en tu tema
const Color kUAORed = Color(0xFFD61F14);

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key});

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseServices _viajesService = FirebaseServices();

  // Controladores y variables de estado
  final TextEditingController origenController = TextEditingController();
  final TextEditingController destinoController = TextEditingController();
  int? cantidadPasajeros;
  bool _isSaving = false;

  // Lógica para el botón de registro
  Future<void> _submitTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _viajesService.createTrip(
        cantidadPasajeros!,
        ['Nicki', 'Joan', 'Hans zimmer', 'Daniela'],
        origenController.text.trim(),
        destinoController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Viaje creado con éxito.')),
        );
        // Redirigir o volver a la pantalla anterior
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeConductorPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Error al crear el viaje: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // Decoración de campos de texto reutilizable
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: kUAORed, width: 2.0),
        borderRadius: BorderRadius.all(Radius.circular(10)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Viaje'),
        backgroundColor: kUAORed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Detalles del trayecto',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kUAORed,
                ),
              ),
              const SizedBox(height: 20),

              // Campo Origen
              TextFormField(
                controller: origenController,
                decoration: _inputDecoration(
                  'Punto de Origen (Ej: Ciudad Jardín)',
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'El origen es obligatorio'
                    : null,
              ),
              const SizedBox(height: 20),

              // Campo Destino
              TextFormField(
                controller: destinoController,
                decoration: _inputDecoration(
                  'Punto de Destino (Ej: Universidad Autónoma)',
                ),
                validator: (v) => (v == null || v.isEmpty)
                    ? 'El destino es obligatorio'
                    : null,
              ),
              const SizedBox(height: 20),

              // Campo Cantidad de Pasajeros
              DropdownButtonFormField<int>(
                decoration: _inputDecoration('Capacidad de Pasajeros'),
                value: cantidadPasajeros,
                hint: const Text('Selecciona la capacidad máxima'),
                items:
                    List.generate(6, (i) => i + 1) // Genera opciones de 1 a 6
                        .map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text('$value pasajeros'),
                          );
                        })
                        .toList(),
                onChanged: (int? newValue) {
                  setState(() {
                    cantidadPasajeros = newValue;
                  });
                },
                validator: (value) =>
                    (value == null) ? 'Selecciona una capacidad' : null,
              ),
              const SizedBox(height: 40),

              // Botón de Confirmación
              ElevatedButton(
                onPressed: () {
                  _isSaving ? null : _submitTrip();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: kUAORed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 5,
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : const Text(
                        'Confirmar Viaje',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
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
