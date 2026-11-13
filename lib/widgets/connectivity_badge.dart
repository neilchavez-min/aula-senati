import 'package:flutter/material.dart';

class ConnectivityBadge extends StatefulWidget {
  const ConnectivityBadge({super.key});

  @override
  State<ConnectivityBadge> createState() => _ConnectivityBadgeState();
}

class _ConnectivityBadgeState extends State<ConnectivityBadge> {
  // Simulación interactiva de estado de conectividad para pruebas Offline / Online
  bool isOnline = false; // Por defecto Offline-First como solicita el sistema SENATI

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        setState(() {
          isOnline = !isOnline;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isOnline
                  ? 'Modo Online: Conectado a la red institucional SENATI'
                  : 'Modo Offline: Operando 100% sobre base de datos local SQLite',
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: isOnline ? const Color(0xFF007A33) : const Color(0xFFC05621),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isOnline ? const Color(0xFFE6F4EA) : const Color(0xFFFEEBC8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline ? const Color(0xFF34A853) : const Color(0xFFDD6B20),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isOnline ? const Color(0xFF34A853) : const Color(0xFFDD6B20),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isOnline ? 'Online (Sincronizado)' : 'Offline (SQLite Activo)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isOnline ? const Color(0xFF137333) : const Color(0xFF9C4221),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
