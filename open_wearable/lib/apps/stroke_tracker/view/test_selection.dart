import 'package:flutter/material.dart';

class TestSelectionScreen extends StatelessWidget {
  final VoidCallback onSmileTest;
  final VoidCallback onHeadTurnTest;
  final VoidCallback onArmMovementTest;
  final String Function(String en,String de) t;
  final VoidCallback onLeaveStudy;

  const TestSelectionScreen({
    super.key,
    required this.onSmileTest,
    required this.onHeadTurnTest,
    required this.onArmMovementTest,
    required this.t,
    required this.onLeaveStudy,
  });


  @override
  Widget build(BuildContext context) {
    return PopScope(
    canPop: false,
    child: Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t("Please choose a test","Bitte wählen Sie einen Test aus"),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            _buildTestCard(
              title: t("Smile","1. Lächeln"),
              subtitle: t("Check Facial Symmetrie","Gesichtssymmetrie prüfen"),
              icon: Icons.sentiment_satisfied_alt,
              onTap: onSmileTest,
            ),

            const SizedBox(height: 16),

            _buildTestCard(
              title: t("Headturn","2. Kopfdrehung"),
              subtitle: t("Capture Head Movement","Bewegung des Kopfes erfassen"),
              icon: Icons.rotate_right,
              onTap: onHeadTurnTest,
            ),

            const SizedBox(height: 16),

            _buildTestCard(
              title: t("Raise arms","3. Armanhebung"),
              subtitle: t("Analyse Arm Movement","Armbewegungen analysieren"),
              icon: Icons.accessibility_new,
              onTap: onArmMovementTest,
            ),
            

    
          ],
        ),
      ),
    ));
  }

  Widget _buildTestCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(
                icon,
                size: 40,
                color: Colors.blue,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios),
            ],
          ),
        ),
      ),
    );
  }
}