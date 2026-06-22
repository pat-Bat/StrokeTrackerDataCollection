import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';

class StudyProtocol {
  late String participantId;
  late String sessionId;
  bool isEnglish = false;

  void addParticipantId(String id) {
    participantId = id;
  }

  void addSessionId(String id) {
    sessionId = id.replaceAll(':', '-');
  }

  String t(String en, String de) => isEnglish ? en : de;

  int stepsTotal() {
    int total = 0;
    for (StudyStep step in getSteps()) {
      if (step.type != StudyStepType.instruction) {
        total = total + step.repetitions;
      }
    }
    return total;
  }

  List<StudyStep> getSteps() => [
        StudyStep(
          type: StudyStepType.instruction,
          heading: t("Smiling", "Lächeln"),
        ),
        StudyStep(
          type: StudyStepType.cameraMeasurement,
          repetitions: 15,
          description: t(
              "Align the face inside the Camera",
              "1. Positionieren Sie die Kamera so, dass das Gesicht des Probanden im grünen Rahmen liegt.\n"
                  "2. Starten Sie die Aufnahme\n"
                  "3. Lesen Sie vor: \"Schauen Sie in die Kamera und lächeln Sie mit sichtbaren Zähnen\"\n"
                  "4. Nachdem der Proband mindestens 3 Sekunden gelächelt hat. Lesen Sie vor: \"Hören Sie bitte auf zu lächeln\"\n"
                  "5. Stoppen Sie die Aufnahme."),
        ),
        StudyStep(
          type: StudyStepType.instruction,
          heading: t("Turn Head", "Kopf drehen"),
        ),
        StudyStep(
          type: StudyStepType.measuringHead,
          measuringInstructions: [
            t(
                "Instruct the patient to start with the head in a neutral position, then turn it to the right, back to neutral, and then to the left, and back to neutral.",
                "Lesen Sie vor: \"Bringen Sie Ihren Kopf in eine aufrechte Position und schauen Sie nach vorne.\"\n"
                    "1. Starten Sie die Aufnahme.\n"
                    "2. Lesen Sie vor: \"Drehen Sie Ihren Kopf nach rechts und zurück zur Mitte. Drehen Sie danach Ihren Kopf nach links und zurück zur Mitte.\"\n"
                    "3. Vergewissern Sie sich, dass der Proband die Bewegung vollständig ausgeführt hat.\n"
                    "4. Stoppen Sie die Aufnahme."),
            t(
                "Instruct the patient to start with the head in a neutral position, then turn it to the left, back to neutral, and then to the right, and back to neutral.",
                "Lesen Sie vor: \"Bringen Sie Ihren Kopf in eine aufrechte Position und schauen Sie nach vorne.\"\n"
                    "1. Starten Sie die Aufnahme.\n"
                    "2. Lesen Sie vor: \"Drehen Sie Ihren Kopf nach links und zurück zur Mitte. Drehen Sie danach Ihren Kopf nach rechts und zurück zur Mitte.\"\n"
                    "3. Vergewissern Sie sich, dass der Proband die Bewegung vollständig ausgeführt hat.\n"
                    "4. Stoppen Sie die Aufnahme."),
          ],
          repetitions: 15,
        ),
        StudyStep(
          type: StudyStepType.instruction,
          heading: t("Tap Earables", "Earables antippen"),
        ),
        StudyStep(
          type: StudyStepType.measuringTap,
          measuringInstructions: [
            t(
                "Instruct the patient double-tap the right Earable with the left Hand twice",
                "Lesen Sie vor:\"Legen Sie ihre Hände vor Ihnen hin und bewegen Sie ihren Kopf in der folgenden Aufgabe nicht. Sie werden einen Ton auf einer Seite der Hörer hören, bitte tippen Sie mit Ihrer gegnüberliegendenden Hand zweimal kurz hintereinander auf diesen Hörer.\"\n"
                    "1. Starten Sie die Aufnahme.\n"
                    "2. Warten Sie, bis der Proband die Bewegung ausgeführt hat.\n"
                    "3. Stoppen Sie die Aufnahme."),
            t(
                "Instruct the patient double-tap the right Earable with the left Hand twice",
                "Lesen Sie vor:\"Legen Sie ihre Hände vor Ihnen hin und bewegen Sie ihren Kopf in der folgenden Aufgabe nicht. Sie werden einen Ton auf einer Seite der Hörer hören, bitte tippen Sie mit Ihrer gegnüberliegendenden Hand zweimal kurz hintereinander auf diesen Hörer.\"\n"
                    "1. Starten Sie die Aufnahme.\n"
                    "2. Warten Sie, bis der Proband die Bewegung ausgeführt hat.\n"
                    "3. Stoppen Sie die Aufnahme."),
          ],
          playSound: true,
          soundside: Side.right,
          repetitions: 30,
        ),
        StudyStep(
          type: StudyStepType.instruction,
          heading: t("Counting", "Zählen"),
        ),
        StudyStep(
          type: StudyStepType.countingMeasurement,
          heading: t("Counting", "Zählen"),
          repetitions: 15,
          description: t(
            "1. Start the recording.\n"
                "2. Read aloud: \"Please count backwards clearly from 10 to 0.\"\n"
                "3. Wait until the patient has finished counting.\n"
                "4. Stop the recording.",
            "1. Starten Sie die Aufnahme.\n"
                "2. Lesen Sie vor: \"Bitte zählen Sie laut von 10 bis 0 rückwärts.\"\n"
                "3. Warten Sie, bis der Proband fertig gezählt hat.\n"
                "4. Stoppen Sie die Aufnahme.",
          ),
        ),
        StudyStep(
          type: StudyStepType.instruction,
          heading: t("Animal Sounds", "Tiergeräusche"),
        ),
        StudyStep(
          type: StudyStepType.animalSoundMeasurement,
          heading: t("Animal Sounds", "Tiergeräusche"),
          repetitions: 15,
          description: t(
            "Play each animal sound, then record the patient's response.",
            "Spielen Sie jeden Tierton ab und nehmen Sie die Antwort des Probanden auf.",
          ),
        ),
        StudyStep(type: StudyStepType.ending),
      ];
}
