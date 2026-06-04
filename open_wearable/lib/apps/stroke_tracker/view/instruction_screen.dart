import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';
import 'package:open_wearable/apps/stroke_tracker/view/repetition_screen.dart';

class EarbudSealTestScreen extends StatefulWidget {
  final String heading;
  final String description;
  final Future<void> Function() onLeaveStudy;
  final String Function(String en, String de) t;
  final Future<Map<String, dynamic>?> Function(bool isLeft) sealCheck;
  final ExperimentLogger logger;
  final VoidCallback onNext;
  final int currentStepNumber;
  final int currentRepetitionNumber;
  final String sessionId;
  
  final int stepsDone;
  final int stepsTotal;

  const EarbudSealTestScreen({
    super.key,
    required this.heading,
    required this.stepsDone,
    required this.stepsTotal,
    required this.description,
    required this.t,
    required this.onNext,
    required this.onLeaveStudy,
    required this.sealCheck,
    required this.logger,
    required this.currentRepetitionNumber,
    required this.currentStepNumber,
    required this.sessionId,

  });

  @override
  _EarbudSealTestScreenState createState() => _EarbudSealTestScreenState();
}

enum EarStep { left, right, ring, done }

class _EarbudSealTestScreenState extends State<EarbudSealTestScreen> {
  Map<String, dynamic>? leftResult;
  Map<String, dynamic>? rightResult;

  bool isMeasuring = false;
  bool ringConfirmed = false;
  bool alertRing = false;
  EarStep step = EarStep.left;

  @override
  void initState() {
    super.initState();

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  Future<void> checkSeal(bool isLeft) async {
  setState(() => isMeasuring = true);

  final result = await widget.sealCheck(isLeft);

  setState(() {
    isMeasuring = false;
    if (isLeft) {
      leftResult = result;
    } else {
      rightResult = result;
    }

  });
}

  void nextStep() {
    switch (step) {
      case EarStep.left:
        setState(() {
          step = EarStep.right;
        });
      case EarStep.right:
        setState(() {
          step = EarStep.ring;
        });
      case EarStep.ring:
        setState(() {
          if(ringConfirmed) {
            step = EarStep.done;
          } else {
            alertRing = true;
          }
        });
      case EarStep.done:
    }
  }

  void pressRingConfirmation() {
    setState(() {
      ringConfirmed = true;
    });
    
  }

  bool get canContinue => leftResult != null && rightResult != null;
  @override
Widget build(BuildContext context) {
  return PopScope(
    canPop: false,
    child: Scaffold(
      
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.t("Earbud Setup", "Einrichtung Sensoren")),
      ),

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            
            LinearProgressIndicator(
              value: step == EarStep.left
                  ? 0.33
                  : step == EarStep.right
                      ? 0.66
                      : 1.0,
            ),

            const SizedBox(height: 20),

            Expanded(
              child: Center(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _buildStep(),
                ),
              ),
            ),

            
            _buildBottomButton(),
          ],
        ),
      ),
    ),
  );
}

Widget _buildBottomButton() {
  switch (step) {

    case EarStep.left:
      return const SizedBox.shrink();

    case EarStep.right:
      return const SizedBox.shrink();

    case EarStep.ring:
      return const SizedBox.shrink();

    case EarStep.done:
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: canContinue ? widget.onNext : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(widget.t("Continue", "Weiter")),
          ),
        ),
      );
  }
}


Widget _buildStep() {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [

      _buildStepCard(),

      const SizedBox(height: 20),

      if (leftResult != null)
        _buildResultCard(widget.t("Left Ear","Linkes Ohr"), leftResult!),

      if (rightResult != null)
        _buildResultCard(widget.t("Right Ear","Rechtes Ohr"), rightResult!),
      
      if(ringConfirmed == true)
        _buildRingResultCard(),
    ],
  );
}

Widget _buildStepCard() {
  switch (step) {

    case EarStep.left:
      return _buildActionCard(
        title: widget.t("Left Ear","Linkes Ohr"),
        subtitle: widget.t(
          "Place left earbud and start test",
          "Linken Ohrhörer einsetzen und testen. Falls die Qualität unter 70 ist versuchen Sie den Hörer besser einzusetzen. Verbessert sich dieser Wert mehrfach nicht können sie fortfahren.",
        ),
        isLoading: isMeasuring,
        onTap: () => checkSeal(true),
      );

    case EarStep.right:
      return _buildActionCard(
        title: widget.t("Right Ear","Rechtes Ohr"),
        subtitle: widget.t(
          "Now test the right earbud",
          "Rechten Ohrhörer einsetzen und testen. Falls die Qualität unter 70 ist versuchen Sie den Hörer besser einzusetzen. Verbessert sich dieser Wert mehrfach nicht können sie fortfahren.",
        ),
        isLoading: isMeasuring,
        onTap: () => checkSeal(false),
      );

    case EarStep.ring:
      return _buildRingActionCard(onTap: pressRingConfirmation);

    case EarStep.done:
      return const Icon(Icons.check_circle, color: Colors.green, size: 80);
  }
}
Widget _buildActionCard({
  required String title,
  required String subtitle,
  required bool isLoading,
  required VoidCallback onTap,
}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            subtitle,
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          SizedBox(
            height: 50,
            width: 400,
            child: Center(
              child: isLoading
                  ? const CircularProgressIndicator()
                  : Row(
                      children: [

                        Expanded(
                          child: ElevatedButton(
                            onPressed: onTap,
                            child: const Text("Test Starten"),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (step == EarStep.left && leftResult == null) ||
                                        (step == EarStep.right &&
                                            rightResult == null)
                                    ? null
                                    : nextStep,
                            child: Text(
                              widget.t(
                                "Next Step",
                                "Nächster Schritt",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
Widget _buildResultCard(String label, Map<String, dynamic> result) {
  final quality = (result['quality'] ?? 0).toString();

  return Card(
    color: Colors.green.shade50,
    child: ListTile(
      leading: const Icon(Icons.hearing, color: Colors.green),
      title: Text(label),
      subtitle: Text(
        widget.t(
          "Quality: $quality/100",
          "Qualität: $quality/100",
        ),
      ),
    ),
  );
}

Widget _buildRingResultCard() {

  return Card(
    color: Colors.green.shade50,
    child: ListTile(
      leading: const Icon(Icons.trip_origin, color: Colors.green),
      title: Text(widget.t("Ring Placement", "Ringplatzierung")),
      subtitle: Text(
        widget.t(
          "Confirmed",
          "Bestätigt",
        ),
      ),
    ),
  );
}

Widget _buildRingActionCard({required VoidCallback onTap}) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [

          Text(
            widget.t("Place the ring", "Ringplatzierung"),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            widget.t("Place the ring on the index finger of the right hand", "Platzieren Sie den Ring an dem Zeigefinger der rechten Hand des Probanden."),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),
          if(alertRing)
          Text(widget.t("Make sure to place the ring and confirm the placement", "Stellen Sie sicher, dass der Ring angebracht ist und bestätigen Sie die Platzierung"),
          style: TextStyle(color: Colors.red),
          ),

          SizedBox(
            height: 50,
            width: 400,
            child: Center(
              child: 
                  Row(
                      children: [

                        Expanded(
                          child: ElevatedButton(
                            onPressed: onTap,
                            child: Text(widget.t("Confirm Ring placement", "Ringplatzierung bestätigen"),
                            textAlign: TextAlign.center,
                            ),
                          ),
                        ),

                        const SizedBox(width: 10),

                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                (step == EarStep.left && leftResult == null) ||
                                        (step == EarStep.right &&
                                            rightResult == null)
                                    ? null
                                    : nextStep,
                            child: Text(
                              widget.t(
                                "Next Step",
                                "Nächster Schritt",
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    ),
  );
}
}