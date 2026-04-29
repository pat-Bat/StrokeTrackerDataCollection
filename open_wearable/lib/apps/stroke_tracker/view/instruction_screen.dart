import 'dart:async';
import 'package:flutter/material.dart';
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

class _EarbudSealTestScreenState extends State<EarbudSealTestScreen> {
  Map<String, dynamic>? leftResult;
  Map<String, dynamic>? rightResult;

  bool isMeasuringLeft = false;
  bool isMeasuringRight = false;

  void checkSeal(Side side) async{
    setState(() {
      if (side == Side.left) {
        isMeasuringLeft = true;
      } else {
        isMeasuringRight = true;
      }
    });

    // Simulate a delay for measurement
    if(isMeasuringLeft){
      leftResult = await widget.sealCheck(true);
      print(leftResult);
      setState(() {
        isMeasuringLeft = false;
      });
    } else {
      rightResult = await widget.sealCheck(false);
      print(rightResult);
      setState(() {
      isMeasuringRight = false;});
    }

  }

  Future<void> _onLeavePressed() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(widget.t("Leave Study", "Studie verlassen")),
          content: Text(
            widget.t(
              "Are you sure you want to leave? Your progress may be lost.",
              "Sind Sie sicher, dass Sie die Studie verlassen möchten? Ihr Fortschritt könnte verloren gehen.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(widget.t("Cancel", "Abbrechen")),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(widget.t("Leave", "Verlassen")),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true) {
      widget.onLeaveStudy();
    }
  }
  void resetResults() {
    setState(() {
      leftResult = null;
      rightResult = null;
      isMeasuringLeft = false;
      isMeasuringRight = false;
    });
  }

  void goNext() async{
    await widget.logger.startLogging(false, widget.sessionId);
    widget.logger.logOtherEvent(
      widget.currentRepetitionNumber, "Sealquality", "${widget.currentStepNumber}",
       "left: ${leftResult?['quality']}, right${rightResult?['quality']}");
    await widget.logger.stopAndWriteLogging(false);
    widget.onNext();
  }

  Widget _buildResultCard(Map<String, dynamic> result) {
  final theme = Theme.of(context);
  double quality = 0;

  Map<String, dynamic>? firstPeak;
  if (result['points'].isNotEmpty) {
    firstPeak = result['points'].first.cast<String, dynamic>();
  
    (firstPeak!['magnitude'] as num?)?.toDouble() == null ? null :  quality = (firstPeak!['magnitude'] as num?)!.toDouble();
  } else {
    firstPeak = null; // or provide a default
  }
  
  return Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            widget.t('Quality', 'Qualität') + ': ',
            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          Text(
            widget.t('Quality should be above 100. Quality: $quality', 'Qualität sollte über 100 sein. Qualität: $quality'),
            style: theme.textTheme.bodyMedium,
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEarbudSection(Side side, bool isMeasuring, Map<String, dynamic>? result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ElevatedButton(
          onPressed: (isMeasuringLeft || isMeasuringRight) ? null : () => checkSeal(side),
          child: Text(widget.t(
            side == Side.left ? "Check Left Earbud" : "Check Right Earbud",
            side == Side.left ? "Linkes Ohr prüfen" : "Rechtes Ohr prüfen",
          )),
        ),
        const SizedBox(height: 8),
        if (isMeasuring)
          Center(
            child: Column(
              children: [
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
                const SizedBox(height: 8),
                Text(widget.t("Measuring...", "Messung läuft...")),
                const SizedBox(height: 16),
              ],
            ),
          )
        else if (result != null)
          _buildResultCard(result),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
Widget build(BuildContext context) {
  final bool canContinue = leftResult != null && rightResult != null;

  return PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${widget.t("Step", "Schritt")} ${widget.stepsDone} / ${widget.stepsTotal}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: widget.stepsDone/widget.stepsTotal,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _onLeavePressed,
          ),

        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.t("Upcoming Task:", "Aufkommende Aufgabe:"),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(widget.description,
                          style: const TextStyle(fontSize: 18, color: Colors.black87)),
                    ),
                    const SizedBox(height: 24),
                    // Füge dies im SingleChildScrollView ein, direkt nach der Beschreibung
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: Colors.yellow[100], // Hinweisfarbe
                        border: Border.all(color: Colors.orange),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Text(
                        widget.t(
                          "Please make sure to wear the left and right earbuds in the correct ear and the ring on a finger of the right hand of the participant before starting the test.",
                          "Bitte setze die linken und rechten Ohrhörer im richtigen Ohr ein und achte darauf das der Ring an einem Finger der rechten Hand des Teilnehmers sitzt, bevor du den Test startest.",
                        ),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    _buildEarbudSection(Side.left, isMeasuringLeft, leftResult),
                    _buildEarbudSection(Side.right, isMeasuringRight, rightResult),
                    if (!canContinue)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          widget.t(
                            "Please test both earbuds before continuing.",
                            "Bitte teste beide Ohrhörer, bevor du fortfährst.",
                          ),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: resetResults,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.grey[400],
                    ),
                    child: Text(widget.t("Reset Results", "Ergebnisse zurücksetzen")),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: canContinue ? goNext : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(widget.t("Continue", "Weiter")),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    ),
  );
}
}