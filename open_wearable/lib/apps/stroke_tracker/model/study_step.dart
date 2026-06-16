//to distinguishe different screens during the study

import 'dart:math';

enum StudyStepType {
  instruction,
  measuringHead,
  measuringTap,
  cameraMeasurement,
  ending
}

enum Side { left, right }

class StudyStep {
  final StudyStepType type;
  final String heading;
  final String pathToImage;
  final String description;
  int repetitions;
  int repetitionsDone = 1;
  final List<String> measuringInstructions;
  final bool debugMode;
  final bool secondaryDescription;
  final String secondaryDescriptionString;
  late final List<int> instructionOrder;
  final bool playSound;
  final Side soundside;

  StudyStep({
    required this.type,
    this.heading = "",
    this.playSound = false,
    this.soundside = Side.left,
    this.pathToImage = "",
    this.description = "",
    this.repetitions = 1,
    this.measuringInstructions = const [""],
    this.debugMode = false,
    this.secondaryDescription = false,
    this.secondaryDescriptionString = "",
  }) {
    final random = Random(DateTime.now().second); // seed = timestamp

    instructionOrder = List.generate(repetitions, (_) {
      return 0 + random.nextInt(measuringInstructions.length);
    });
  }
}
