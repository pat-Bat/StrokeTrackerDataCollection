import 'dart:async';
import 'package:flutter/material.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/manager.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';
import 'package:flutter/services.dart';


class MeasuringScreen extends StatefulWidget {
  final int repetitions;
  final int currentRepetition;
  final Future<void> Function() onNext;
  final Future<void> Function() onLeaveStudy;
  final Future<void> Function(bool useRing) startMeasuring;
  final Future<void> Function() stopMeasuring;
  final Future<void> Function() dispose;
  final String Function(String en,String de) t;
  final ExperimentLogger logger;
  final String recordingId;
  final String taskName;
  final String instruction;
  final bool playSound;
  final Side soundSide;
  final ExperimentManager manager;
  final int timer;
  final bool useRing;
  final int stepsDone;
  final int stepsTotal;

  const MeasuringScreen({
    super.key,
    required this.onLeaveStudy,
    required this.repetitions,
    required this.onNext,
    required this.startMeasuring,
    required this.stopMeasuring,
    required this.currentRepetition,
    required this.logger,
    required this.recordingId,
    required this.taskName,
    required this.instruction,
    required this.playSound,
    required this.soundSide,
    required this.t,
    required this.dispose,
    required this.manager,
    required this.timer,
    required this.useRing,
    required this.stepsTotal,
    required this.stepsDone,
  });

  @override
  State<MeasuringScreen> createState() => _MeasuringScreenState();
}

class _MeasuringScreenState extends State<MeasuringScreen> {
  bool recording = false;
  late final String Function(String en,String de) t;
  int countdown = 10;
  Timer? _timer;
  bool isStarting = false;

  Future<void> playLeft() async {
  await widget.manager.playSound(left:true);
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

Future<void> playRight() async {
  await widget.manager.playSound(left:false);
}

  @override
  void initState() {
    super.initState();
    t = widget.t;
    countdown = widget.timer;

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  Future<void> _startRecording() async {
    
    if (isStarting) return;

    setState(() {
      isStarting = true;
    });
    
    try {
        await widget.startMeasuring(widget.useRing).timeout(
          const Duration(seconds: 10),
        );
      } catch (e) {
        debugPrint("stopMeasuring timed out: $e");
        await widget.stopMeasuring().timeout(const Duration(seconds: 5),);
        setState(() {
          isStarting = false;
        });
        return;
      }

    if (widget.playSound) {
      if(widget.soundSide == Side.right) {
        playRight();
      }

      if (widget.soundSide == Side.left) {
        playLeft();
      }
    }
    try {

      
      setState(() {
      recording = true;
      isStarting = false;
    });
      _startTimer();
      
      widget.logger.logOtherEvent(
        widget.currentRepetition,
        "Start Record of ${widget.taskName}",
        widget.instruction,
        "Recording_Start",
      );
      debugPrint("MEasurement gestartet.");
    } catch (e) {
      debugPrint("Fehler beim Starten der Measurement: $e");
    }
  }

    Future<bool?> _showSaveDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(t("Save Measurement?", "Messung speichern?")),
          content: Text(
              t(
              "Do you want to save this measurement or repeat it?",
              "Möchten Sie diese Messung speichern oder verwerfen und wiederholen?"
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t("Remeasure", "Wiederholen")),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);

              },
              child: Text(t("Save", "Speichern")),
            ),
          ],
        );
      },
    );
  }
  
  Future<void> _stopRecording() async {
    if (!recording) {
      return;
    }
    widget.logger.logOtherEvent(
        widget.currentRepetition,
        "Stop Record of ${widget.taskName}",
        widget.instruction,
        "Recording_Stop",
      );
    await widget.stopMeasuring();
    setState(() {
      recording = false;
    });
    _timer?.cancel();
    

    try {
      
    } catch (e) {
      debugPrint("Fehler beim Stoppen der Videoaufnahme: $e");
    }
    final shouldSave = await _showSaveDialog();

    if (shouldSave == true) {
      
      await widget.onNext();
    } else {
      // discard data and reset
      setState(() {
        countdown = widget.timer;
      });

      debugPrint("Measurement discarded. Ready to remeasure.");}
  }

  

  @override
  void dispose() {
    widget.stopMeasuring();
    _timer?.cancel();
    widget.dispose();
    super.dispose();
  }

  void _startTimer() {
    countdown = widget.timer;

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (countdown == 0) {
        timer.cancel();
        _stopRecording();
      } else {
        setState(() {
          countdown--;
        });
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: 
            Text(
              widget.t(
                "Repetition ${widget.currentRepetition} / ${widget.repetitions}",
                "Wiederholung ${widget.currentRepetition} / ${widget.repetitions}",
              ),),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _onLeavePressed,
            ),

          ],
        ),
        
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                  padding: const EdgeInsets.all(16),
                  child: Card(
                    elevation: 3,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            t("Examiner Instruction", "Anweisung für Untersucher"),
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          buildInstructionText(widget.instruction)
                        ],
                      ),
                    ),
                  ),
                ),

        
              if (recording)
                Expanded(
                  child: Center(
                    child: Text(
                      "$countdown",
                      style: TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Text(
                      t("Press start to begin", "Zum Starten drücken"),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

              // 🔹 Bottom Controls
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    // Status text
                    Text(
                      recording ? t("Recording...", "Aufnahme läuft...") : t("Ready", "Bereit"),
                      style: TextStyle(
                        color: recording ? Colors.red : Colors.grey.shade700,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 12),

                    // Button
                    GestureDetector(
                      onTap: isStarting? null : (recording ? _stopRecording : _startRecording),
                      child: AnimatedContainer(
                        duration: Duration(milliseconds: 200),
                        width: recording ? 90 : 80,
                        height: recording ? 90 : 80,
                        decoration: BoxDecoration(
                          color: recording ? Colors.red : Colors.green,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            )
                          ],
                        ),
                        child: Icon(
                          recording ? Icons.stop : Icons.play_arrow,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    SizedBox(height: 16),

              
                    Text(
                      t(
                        "Repetition ${widget.currentRepetition} / ${widget.repetitions}",
                        "Wiederholung ${widget.currentRepetition} / ${widget.repetitions}"
                      ),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (isStarting)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 20),
                        Text(
                          t("Starting sensors...", "Sensoren werden gestartet..."),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),),
            ],
          ),
        ),
      ));
  }

  Widget buildInstructionText(String text) {
    final regex = RegExp(r'"([^"]*)"');
    final spans = <TextSpan>[];

    int lastMatchEnd = 0;

    for (final match in regex.allMatches(text)) {
      // Text vor den Anführungszeichen
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
          ),
        );
      }

      // Text innerhalb der Anführungszeichen (kursiv)
      spans.add(
        TextSpan(
          text: match.group(0), // inklusive "
          style: const TextStyle(
            fontStyle: FontStyle.italic,
          ),
        ),
      );

      lastMatchEnd = match.end;
    }

    // Restlicher Text
    if (lastMatchEnd < text.length) {
      spans.add(
        TextSpan(
          text: text.substring(lastMatchEnd),
        ),
      );
    }

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        children: spans,
      ),
    );
  }
}