import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';

class ArithmeticMeasurementScreen extends StatefulWidget {
  final int repetitions;
  final int currentRepetition;
  final Future<void> Function() onNext;
  final Future<void> Function() onLeaveStudy;
  final Future<void> Function(bool useRing) startMeasuring;
  final Future<void> Function() stopMeasuring;
  final Future<void> Function() dispose;
  final String Function(String en, String de) t;
  final ExperimentLogger logger;
  final String taskName;
  final bool useRing;

  const ArithmeticMeasurementScreen({
    super.key,
    required this.onLeaveStudy,
    required this.repetitions,
    required this.currentRepetition,
    required this.onNext,
    required this.startMeasuring,
    required this.stopMeasuring,
    required this.dispose,
    required this.t,
    required this.logger,
    required this.taskName,
    required this.useRing,
  });

  @override
  State<ArithmeticMeasurementScreen> createState() =>
      _ArithmeticMeasurementScreenState();
}

class _ArithmeticMeasurementScreenState
    extends State<ArithmeticMeasurementScreen> {
  final _random = Random();
  bool _recording = false;
  bool _isStarting = false;
  late String _expression;
  late int _result;
  late final String Function(String en, String de) t;

  @override
  void initState() {
    super.initState();
    t = widget.t;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _generateExpression();
  }

  void _generateExpression() {
    final bool isAddition = _random.nextBool();
    int a, b;
    if (isAddition) {
      a = _random.nextInt(25);
      b = _random.nextInt(25);
      _expression = "$a + $b";
      _result = a + b;
    } else {
      a = _random.nextInt(25);
      b = _random.nextInt(a);
      _expression = "$a - $b";
      _result = a - b;
    }
  }

  Future<void> _onLeavePressed() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t("Leave Study", "Studie verlassen")),
        content: Text(t(
          "Are you sure you want to leave? Your progress may be lost.",
          "Sind Sie sicher, dass Sie die Studie verlassen möchten?",
        )),
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
      ),
    );
    if (shouldLeave == true) {
      await widget.onLeaveStudy();
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _isStarting) return;

    setState(() => _isStarting = true);

    try {
      await widget.startMeasuring(widget.useRing).timeout(
            const Duration(seconds: 15),
          );
    } catch (e) {
      debugPrint("startMeasuring timed out: $e");
      try {
        await widget.stopMeasuring().timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (!mounted) return;
      setState(() => _isStarting = false);
      return;
    }

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Start Record Arithmetic: $_expression = $_result",
      "Arithmetic",
      "Recording_Start",
    );

    if (!mounted) return;
    setState(() {
      _recording = true;
      _isStarting = false;
    });
  }

  Future<bool?> _showSaveDialog() async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(t("Save Measurement?", "Messung speichern?")),
        content: Text(t(
          "Do you want to save this measurement or repeat it?",
          "Möchten Sie diese Messung speichern oder verwerfen und wiederholen?",
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(t("Remeasure", "Wiederholen")),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(t("Save", "Speichern")),
          ),
        ],
      ),
    );
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Stop Record Arithmetic: $_expression = $_result",
      "Arithmetic",
      "Recording_Stop",
    );

    await widget.stopMeasuring();

    if (!mounted) return;
    setState(() => _recording = false);

    final shouldSave = await _showSaveDialog();
    if (shouldSave == true) {
      await widget.onNext();
    } else {
      setState(() => _generateExpression());
    }
  }

  @override
  void dispose() {
    widget.stopMeasuring();
    widget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(t(
            "Repetition ${widget.currentRepetition} / ${widget.repetitions}",
            "Wiederholung ${widget.currentRepetition} / ${widget.repetitions}",
          )),
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _onLeavePressed,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 3,
                      color: Colors.grey.shade50,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              t("Examiner Instruction",
                                  "Anweisung für Untersucher"),
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t(
                                "1. Start the recording.\n"
                                    "2. Read aloud the displayed expression.\n"
                                    "3. Wait for the patient to answer.\n"
                                    "4. Stop the recording.",
                                "1. Starten Sie die Aufnahme.\n"
                                    "2. Lesen Sie die angezeigte Rechenaufgabe vor.\n"
                                    "3. Warten Sie auf die Antwort des Probanden.\n"
                                    "4. Stoppen Sie die Aufnahme.",
                              ),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _expression,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "= ?",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _recording
                                  ? t("Recording...", "Aufnahme läuft...")
                                  : t("Ready", "Bereit"),
                              style: TextStyle(
                                color: _recording
                                    ? Colors.red
                                    : Colors.grey.shade700,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_recording || _isStarting)
                                ? null
                                : _startRecording,
                            icon: const Icon(Icons.fiber_manual_record),
                            label: Text(t("Start Record", "Aufnahme starten")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _recording ? _stopRecording : null,
                            icon: const Icon(Icons.stop),
                            label: Text(t("End Record", "Aufnahme beenden")),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (_isStarting)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          t("Starting sensors...",
                              "Sensoren werden gestartet..."),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
