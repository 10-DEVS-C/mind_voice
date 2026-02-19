import 'package:flutter/material.dart';

class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Resultados IA",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Último Resumen",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                SizedBox(height: 10),
                Text(
                  "La discusión se centró en la optimización de procesos mediante IA. Los puntos clave incluyen la reducción de latencia en la nube.",
                  style: TextStyle(color: Colors.white70, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _infoCard(
                  context,
                  Icons.biotech,
                  "Mind Map",
                  "14 Nodos",
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _infoCard(context, Icons.share, "Compartir", "PDF, MD"),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text(
            "Próximos pasos",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _stepItem("Definir arquitectura de servicios."),
          _stepItem("Revisar costos de AWS Transcribe."),
        ],
      ),
    );
  }

  Widget _infoCard(
    BuildContext context,
    IconData icon,
    String title,
    String sub,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blueAccent, size: 20),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            sub,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _stepItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(color: Colors.blueGrey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
