import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';

class CountingMeasurementScreen extends StatefulWidget {
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
  final String instruction;
  final bool useRing;

  const CountingMeasurementScreen({
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
    required this.instruction,
    required this.useRing,
  });

  @override
  State<CountingMeasurementScreen> createState() =>
      _CountingMeasurementScreenState();
}

class _CountingMeasurementScreenState extends State<CountingMeasurementScreen> {
  bool _recording = false;
  bool _isStarting = false;
  late final String Function(String en, String de) t;

  @override
  void initState() {
    super.initState();
    t = widget.t;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
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
              "Sind Sie sicher, dass Sie die Studie verlassen moechten? Ihr Fortschritt koennte verloren gehen.",
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
      await widget.onLeaveStudy();
    }
  }

  Future<void> _startRecording() async {
    if (_recording || _isStarting) return;

    setState(() {
      _isStarting = true;
    });

    try {
      await widget.startMeasuring(widget.useRing).timeout(
            const Duration(seconds: 10),
          );
    } catch (e) {
      debugPrint("startMeasuring timed out: $e");
      try {
        await widget.stopMeasuring().timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _isStarting = false;
      });
      return;
    }

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Start Record of ${widget.taskName}",
      widget.instruction,
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
      builder: (context) {
        return AlertDialog(
          title: Text(t("Save Measurement?", "Messung speichern?")),
          content: Text(
            t(
              "Do you want to save this measurement or repeat it?",
              "Moechten Sie diese Messung speichern oder verwerfen und wiederholen?",
            ),
          ),
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
        );
      },
    );
  }

  Future<void> _stopRecording() async {
    if (!_recording) return;

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Stop Record of ${widget.taskName}",
      widget.instruction,
      "Recording_Stop",
    );

    await widget.stopMeasuring();

    if (!mounted) return;
    setState(() {
      _recording = false;
    });

    final shouldSave = await _showSaveDialog();
    if (shouldSave == true) {
      await widget.onNext();
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
          title: Text(
            t(
              "Repetition ${widget.currentRepetition} / ${widget.repetitions}",
              "Wiederholung ${widget.currentRepetition} / ${widget.repetitions}",
            ),
          ),
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
                              t(
                                "Examiner Instruction",
                                "Anweisung fuer Untersucher",
                              ),
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.instruction,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
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
                              "10  9  8  7  6  5  4  3  2  1  0",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey.shade900,
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _recording
                                  ? t(
                                      "Recording...",
                                      "Aufnahme laeuft...",
                                    )
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
                            label: Text(
                              t("Start Record", "Aufnahme starten"),
                            ),
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
                    Text(
                      t(
                        "Repetition ${widget.currentRepetition} / ${widget.repetitions}",
                        "Wiederholung ${widget.currentRepetition} / ${widget.repetitions}",
                      ),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
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
                          t(
                            "Starting sensors...",
                            "Sensoren werden gestartet...",
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
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
