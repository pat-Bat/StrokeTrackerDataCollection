import 'package:flutter/material.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/manager.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';
import 'package:open_wearable/apps/stroke_tracker/view/sealcheck.dart';

class LikertChoice extends StatefulWidget{
  final Function(int) onScoreChanged;
  final int initialScore;
  final String Function(String en,String de) t;
  LikertChoice({super.key, required this.onScoreChanged, required this.initialScore, required this.t});

  @override
  State<LikertChoice> createState() {
    return _LikertChoiceState();
  }
}

class _LikertChoiceState extends State<LikertChoice> {
  late final String Function(String en,String de) t;
  int score = 0;

  @override
  void initState() {
    super.initState();
    score = widget.initialScore;
    t = widget.t;
  }

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: <ButtonSegment<int>>[
        ButtonSegment<int>(
          value: 1,
          label: Text(t("Likely absent", "Wahrscheinlich nicht vorhanden")),
        ),
        ButtonSegment<int>(
          value: 2,
          label: Text(t("Somewhat likely absent", "Eher nicht vorhanden")),
        ),
        ButtonSegment<int>(
          value: 3,
          label: Text(t("Indeterminate", "Unklar")),
        ),
        ButtonSegment<int>(
          value: 4,
          label: Text(t("Somewhat likely present", "Eher vorhanden")),
        ),
        ButtonSegment<int>(
          value: 5,
          label: Text(t("Likely present", "Wahrscheinlich vorhanden")),
        ),
      ],
      selected: <int>{score},
      onSelectionChanged: (Set<int> newSelection) {
        setState(() {
          score = newSelection.first;
        });
        widget.onScoreChanged(newSelection.first);
      },
      showSelectedIcon: false,
    );
  }
}


class TaskScreen extends StatefulWidget{
  final int currentRepetition;
  final int maxRepetition;
  final int currentStepNumber;
  final String currentStepTask;
  final ExperimentLogger logger;
  final ExperimentManager manager;
  final VoidCallback addRepetition;
  final int stepsDone;
  final int stepsTotal;
  final Future<void> Function() onLeaveStudy;
  final String Function(String en,String de) translate;

  const TaskScreen({
    super.key,
    required this.onLeaveStudy,
    required this.maxRepetition,
    required this.currentRepetition,
    required this.logger,
    required this.currentStepNumber,
    required this.currentStepTask,
    required this.translate,
    required this.manager,
    required this.stepsDone,
    required this.stepsTotal,
    required this.addRepetition,
  });

  @override
  State<TaskScreen> createState() => _TaskScreenState();
}

class _TaskScreenState extends State<TaskScreen> {
  late Widget _likertWidget;
  int score = 0;
  Side? selectedSide;
  bool wrongSelection = false;
  late final String Function(String en,String de) t;

  @override
  void initState() {
    super.initState();
    t = widget.translate;
    _likertWidget = _buildLikertScale();
    
  }

  Future<void> _onLeavePressed() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t("Leave Study", "Studie verlassen")),
          content: Text(
            t(
              "Are you sure you want to leave? Your progress may be lost.",
              "Sind Sie sicher, dass Sie die Studie verlassen möchten? Ihr Fortschritt könnte verloren gehen.",
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t("Cancel", "Abbrechen")),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t("Leave", "Verlassen")),
            ),
          ],
        );
      },
    );

    if (shouldLeave == true) {
      widget.onLeaveStudy();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
    child: Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${t("Step", "Schritt")} ${widget.stepsDone} / ${widget.stepsTotal}'),
            const SizedBox(height: 4),
            LinearProgressIndicator(
              value: widget.stepsDone/widget.stepsTotal,
              backgroundColor: Colors.grey[300],
              color: Colors.blue,
            ),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: Icon(Icons.hearing), // or any icon you like
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SimpleSealCheckScreen(
                    t: t,
                    sealCheck: widget.manager.runSealCheck,
                  ),
                ),
              );}),
          IconButton(
            icon: const Icon(Icons.exit_to_app),
            onPressed: _onLeavePressed,
          ),

        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t(
                "Repetition ${widget.currentRepetition} of ${widget.maxRepetition}",
                "Wiederholung ${widget.currentRepetition} von ${widget.maxRepetition}"
              ),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                t(
                  "Please rate the pathology severity on a scale from 1 (no impairment) to 5 (severe impairment).",
                  "Bitte bewerten Sie den Schweregrad der Pathologie auf einer Skala von 1 (keine Beeinträchtigung) bis 5 (schwere Beeinträchtigung)."
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 30),
            Padding(padding: EdgeInsetsGeometry.only(left: 20,right: 20),
              child: _likertWidget,
            )
            ,
            if (score >= 4) _buildSideSelector(),
            if (!canGoNext())
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  t(
                    "Please complete all required selections",
                    "Bitte treffen Sie alle erforderlichen Auswahlmöglichkeiten"
                  ),
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            if (widget.currentRepetition < widget.maxRepetition)
            ElevatedButton(
              onPressed: canGoNext() ? pressExitButton : null,
              child: Text(
                 t("Start/Repeat Task", "Nächse Wiederholung Starten")
              ),
            ),
            if (widget.currentRepetition >= widget.maxRepetition)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                onPressed: canGoNext() ? () {
                    widget.addRepetition();
                    pressExitButton();
                   }  : null,
                child: Text(
                  t("Start/Repeat Task", "Nächste Wiederholung Starten")
                ),),
                SizedBox(width: 10),
                ElevatedButton(
                  onPressed: canGoNext() ? pressExitButton : null,
                  child: Text(
                    t("Start/Repeat Task", "Zur Nächsten Aufgabe")
                  ),)
              ],
            )
          ],
        ),
      ),
    ));
  }

  Widget _buildLikertScale(){

    return LikertChoice(onScoreChanged: onScoreChanged, initialScore: 0, t: widget.translate,);
  }

  void onScoreChanged(int newScore) {
    setState(() {
      score = newScore;
    });
  }

  

  bool canGoNext() {
    return score > 0 ? (score >= 4 ? (selectedSide != null? true :false) : true) : false;
  }

  Widget _buildSideSelector() {
    return Column(
      children: [
        const SizedBox(height: 20),
        Text(
                t(
          "Which side is the impairment (From perspective of the Proband)?",
          "Welche Gesichtshälfte ist betroffen (Sicht des Probanden)?"
        ),
          style: TextStyle(fontSize: 18),
        ),
        const SizedBox(height: 10),

        SegmentedButton<Side>(
          segments: <ButtonSegment<Side>>[
            ButtonSegment(
              value: Side.left,
              label: Text(t("Left", "Links")),
              icon: Icon(Icons.arrow_left),
            ),
            ButtonSegment(
              value: Side.right,
              label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t("Right", "Rechts")),
                SizedBox(width: 4),
                Icon(Icons.arrow_right),
              ],
            ),
            ),
          ],
          selected: selectedSide != null ? {selectedSide!} : <Side>{},
          multiSelectionEnabled: false,
          emptySelectionAllowed: true, 
          onSelectionChanged: (Set<Side> newSelection) {
            setState(() {
              selectedSide = newSelection.isNotEmpty ? newSelection.first : null;
            });
          },
        ),
      ],
    );
  }



  void pressExitButton(){
    
    widget.logger.logOtherEvent(widget.currentRepetition, "Evaluation", widget.currentStepTask, score.toString());
    if(selectedSide != null && score >= 4) {
      widget.logger.logOtherEvent(widget.currentRepetition, "Side of impairment", widget.currentStepTask, selectedSide.toString().split(".").last);
    }
    Navigator.of(context).pop();
  }

}