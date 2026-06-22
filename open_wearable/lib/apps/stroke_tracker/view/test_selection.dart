import 'package:flutter/material.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';

class TestSelectionScreen extends StatelessWidget {
  final VoidCallback onSmileTest;
  final VoidCallback onHeadTurnTest;
  final VoidCallback onArmMovementTest;
  final VoidCallback onCountingTest;
  final VoidCallback onAnimalSoundTest;
  final String Function(String en, String de) t;
  final VoidCallback onLeaveStudy;
  final List<StudyStep> steps;

  const TestSelectionScreen({
    super.key,
    required this.onSmileTest,
    required this.onHeadTurnTest,
    required this.onArmMovementTest,
    required this.onCountingTest,
    required this.onAnimalSoundTest,
    required this.t,
    required this.onLeaveStudy,
    required this.steps,
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
                  t("Please choose a test", "Bitte wählen Sie einen Test aus"),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
                _buildTestCard(
                    title: t("Smile", "1. Lächeln"),
                    subtitle:
                        t("Check Facial Symmetrie", "Gesichtssymmetrie prüfen"),
                    icon: Icons.sentiment_satisfied_alt,
                    onTap: onSmileTest,
                    completed: steps[0].repetitionsDone - 1,
                    max: steps[0].repetitions),
                const SizedBox(height: 16),
                _buildTestCard(
                    title: t("Headturn", "2. Kopfdrehung"),
                    subtitle: t("Capture Head Movement",
                        "Bewegung des Kopfes erfassen"),
                    icon: Icons.rotate_right,
                    onTap: onHeadTurnTest,
                    completed: steps[1].repetitionsDone - 1,
                    max: steps[1].repetitions),
                const SizedBox(height: 16),
                _buildTestCard(
                    title: t("Raise arms", "3. Armanhebung"),
                    subtitle:
                        t("Analyse Arm Movement", "Armbewegungen analysieren"),
                    icon: Icons.accessibility_new,
                    onTap: onArmMovementTest,
                    completed: steps[2].repetitionsDone - 1,
                    max: steps[2].repetitions),
                const SizedBox(height: 16),
                _buildTestCard(
                  title: t("Counting", "4. Zählen"),
                  subtitle: t(
                      "Record counting backwards", "Rückwärtszählen aufnehmen"),
                  icon: Icons.record_voice_over,
                  onTap: onCountingTest,
                  completed: steps[3].repetitionsDone - 1,
                  max: steps[3].repetitions,
                ),
                const SizedBox(height: 16),
                _buildTestCard(
                  title: t("Animal Sounds", "5. Tiergeräusche"),
                  subtitle: t(
                      "Play sounds and record response", "Töne abspielen und Antwort aufnehmen"),
                  icon: Icons.pets,
                  onTap: onAnimalSoundTest,
                  completed: steps[4].repetitionsDone - 1,
                  max: steps[4].repetitions,
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      bool? leave = true;
                      if (!studyReady()) {
                        leave = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(
                              t("Leave Study?", "Studie verlassen?"),
                            ),
                            content: Text(
                              t("Not all repetitions are completed. Do you really want to leave?",
                                  "Nicht alle Wiederholungen wurden abgeschlossen. Möchten Sie die Studie wirklich verlassen?"),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(t("Cancel", "Abbrechen")),
                              ),
                              FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(t("Leave", "Verlassen")),
                              ),
                            ],
                          ),
                        );
                      }
                      if (leave == true) {
                        onLeaveStudy();
                      }
                    },
                    icon: const Icon(Icons.exit_to_app),
                    label: Text(
                      t("Leave Study", "Studie verlassen"),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ));
  }

  bool studyReady() {
    bool isReady = true;
    for (var step in steps) {
      if (step.repetitionsDone - 1 < step.repetitions) {
        isReady = false;
      }
    }
    return isReady;
  }

  Widget _buildTestCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required int completed,
    required int max,
  }) {
    final progress = max > 0 ? completed / max : 0.0;

    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
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
                  Text(
                    '$completed/$max',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_ios),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
