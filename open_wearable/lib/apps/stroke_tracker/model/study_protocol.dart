import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';

class StudyProtocol {
  late String participantId;
  late String sessionId;
  bool isEnglish = false;

  void addParticipantId(String id){
    participantId  = id;
  }

  void addSessionId(String id) {
    sessionId = id.replaceAll(':', '-');
  }

  String t(String en, String de) => isEnglish ? en : de;

  int stepsTotal () {
    int total = 0;
    for (StudyStep step in getSteps()) {
      if (step.type != StudyStepType.instruction){
        total = total + step.repetitions;
      }
    }
    return total;
  }
  List<StudyStep> getSteps() => [
  StudyStep(
    type: StudyStepType.instruction,
    heading: t("Smiling", "Lächeln"),
    description: t(
      "After pressing the start-button, wait until the countdown starts, after the countdown starts instruct the patient to smile",
      "„Drücken Sie den Start-Knopf, warten Sie, bis der Countdown beginnt, und sobald der Countdown startet, weisen Sie den Patienten an, zu lächeln.“"
    ),
  ),
  StudyStep(
    type: StudyStepType.cameraMeasurement,
    repetitions: 3,
  ),
  StudyStep(
    type: StudyStepType.instruction,
    heading: t("Turn Head", "Kopf drehen"),
    description: t(
      "During the recording the patient needs to turn the head",
      "Während der Aufnahme soll der patient den Kopf drehen"
    ),
  ),
  StudyStep(
    type: StudyStepType.measuringHead,
    measuringInstructions: [
      t(
        "Instruct the patient to start with the head in a neutral position, then turn it to the right, back to neutral, and then to the left, and back to neutral.",
        "Den Patienten anweisen, den Kopf zunächst in die neutrale Position zu bringen, dann nach rechts zu drehen, zurück zur Neutralstellung und anschließend nach links und zurück zur Neutralstellung"
      ),
      t(
        "Instruct the patient to start with the head in a neutral position, then turn it to the left, back to neutral, and then to the right, and back to neutral.",
        "Den Patienten anweisen, den Kopf zunächst in die neutrale Position zu bringen, dann nach links zu drehen, zurück zur Neutralstellung und anschließend nach rechts und zurück zur Neutralstellung."
      ),
    ],
    repetitions: 3,
  ),
  StudyStep(
    type: StudyStepType.instruction,
    heading: t("Tap Earables", "Earables antippen"),
    description: t(
      "During the recording double-tap one earable with the opposing arm twice",
      "Während der Aufnahme ein Earable mit dem gegenüberliegenden Arm zweimal schnell hintereinander antippen"
    ),
  ),
  StudyStep(
    type: StudyStepType.measuringTap,
    measuringInstructions: [
      t(
        "Instruct the patient double-tap the right Earable with the left Hand twice",
        "Den Patienten anweisen, das rechte Earable mit der linken Hand zweimal schnell hintereinander anzutippen"
      ),
    ],
    playSound: true,
    soundside: Side.right,
    repetitions: 1,
  ),
  StudyStep(
    type: StudyStepType.measuringTap,
    measuringInstructions: [
      t(
        "Instruct the patient double-tap the left Earable with the right Hand twice",
        "Den Patienten anweisen, das linke Earable mit der rechten Hand zweimal schnell hintereinander anzutippen"
      ),
    ],
    playSound: true,
    soundside: Side.left,
    repetitions: 1,
  ),
    StudyStep(
    type: StudyStepType.measuringTap,
    measuringInstructions: [
      t(
        "Instruct the patient double-tap the right Earable with the left Hand twice",
        "Den Patienten anweisen, das rechte Earable mit der linken Hand zweimal schnell hintereinander anzutippen"
      ),
    ],
    playSound: true,
    soundside: Side.right,
    repetitions: 1,
  ),
  StudyStep(
    type: StudyStepType.measuringTap,
    measuringInstructions: [
      t(
        "Instruct the patient double-tap the left Earable with the right Hand twice",
        "Den Patienten anweisen, das linke Earable mit der rechten Hand zweimal schnell hintereinander anzutippen"
      ),
    ],
    playSound: true,
    soundside: Side.left,
    repetitions: 1,
  ),StudyStep(
    type: StudyStepType.measuringTap,
    measuringInstructions: [
      t(
        "Instruct the patient double-tap the right Earable with the left Hand",
        "Den Patienten anweisen, das rechte Earable mit der linken Hand zweimal schnell hintereinander anzutippen"
      ),
    ],
    playSound: true,
    soundside: Side.right,
    repetitions: 1,
  ),
  StudyStep(
    type: StudyStepType.measuringTap,
    measuringInstructions: [
      t(
        "Instruct the patient double-tap the left Earable with the right Hand twice",
        "Den Patienten anweisen, das linke Earable mit der rechten Hand zweimal schnell hintereinander anzutippen"
      ),
    ],
    playSound: true,
    soundside: Side.left,
    repetitions: 1,
  ),
  
    StudyStep(type: StudyStepType.ending),
    ];
}
