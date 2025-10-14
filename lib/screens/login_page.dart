import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Ingresa tu nombre de usuario sin el "@uao.edu.co"',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.all(5.0),
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'joan.salcedo...',
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            const Text(
              'Ingresa tu contraseña',
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Ejemplo: mostrar el texto en consola
          print('Usuario: ${controller.text}');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
