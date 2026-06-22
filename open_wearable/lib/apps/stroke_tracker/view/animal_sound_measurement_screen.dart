import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/audio_controller.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';

class AnimalSound {
  final String key;
  final String file;
  final String labelEn;
  final String labelDe;
  final IconData icon;

  const AnimalSound({
    required this.key,
    required this.file,
    required this.labelEn,
    required this.labelDe,
    required this.icon,
  });
}

const List<AnimalSound> animalSounds = [
  AnimalSound(key: 'cow', file: 'cow_moo.mp3', labelEn: 'Cow', labelDe: 'Kuh', icon: Icons.pets),
  AnimalSound(key: 'duck', file: 'duck_quack.mp3', labelEn: 'Duck', labelDe: 'Ente', icon: Icons.water_drop),
  AnimalSound(key: 'cat', file: 'cat_meow.mp3', labelEn: 'Cat', labelDe: 'Katze', icon: Icons.pets),
  AnimalSound(key: 'dog', file: 'dog_bark.mp3', labelEn: 'Dog', labelDe: 'Hund', icon: Icons.pets),
];

enum _Phase { idle, playing, starting, recording }

class AnimalSoundMeasurementScreen extends StatefulWidget {
  final int repetitions;
  final int currentRepetition;
  final Future<void> Function(String animalName) startMeasuringForAnimal;
  final Future<void> Function() stopMeasuring;
  final Future<void> Function() onNext;
  final Future<void> Function() onLeaveStudy;
  final Future<void> Function() dispose;
  final AudioController audioController;
  final ExperimentLogger logger;
  final String Function(String en, String de) t;

  const AnimalSoundMeasurementScreen({
    super.key,
    required this.repetitions,
    required this.currentRepetition,
    required this.startMeasuringForAnimal,
    required this.stopMeasuring,
    required this.onNext,
    required this.onLeaveStudy,
    required this.dispose,
    required this.audioController,
    required this.logger,
    required this.t,
  });

  @override
  State<AnimalSoundMeasurementScreen> createState() =>
      _AnimalSoundMeasurementScreenState();
}

class _AnimalSoundMeasurementScreenState
    extends State<AnimalSoundMeasurementScreen> {
  final _random = Random();
  late AnimalSound _currentAnimal;
  _Phase _phase = _Phase.idle;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _pickRandomAnimal();
  }

  void _pickRandomAnimal() {
    _currentAnimal = animalSounds[_random.nextInt(animalSounds.length)];
  }

  Future<void> _playSoundAndRecord() async {
    if (_phase != _Phase.idle) return;
    setState(() => _phase = _Phase.starting);

    // Sensoren zuerst starten
    try {
      await widget.startMeasuringForAnimal(_currentAnimal.key).timeout(
            const Duration(seconds: 15),
          );
    } catch (e) {
      debugPrint("startMeasuring timed out: $e");
      try {
        await widget.stopMeasuring().timeout(const Duration(seconds: 5));
      } catch (_) {}
      if (!mounted) return;
      setState(() => _phase = _Phase.idle);
      return;
    }

    if (!mounted) return;
    setState(() => _phase = _Phase.playing);

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Play ${_currentAnimal.key}",
      "AnimalSound",
      "Sound_Play",
    );

    // Ton abspielen (fire-and-forget)
    widget.audioController.playAssetSound(_currentAnimal.file);

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Start Record ${_currentAnimal.key}",
      "AnimalSound",
      "Recording_Start",
    );

    if (!mounted) return;
    setState(() => _phase = _Phase.recording);
  }

  Future<void> _repeatSound() async {
    if (_phase != _Phase.recording) return;

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Repeat ${_currentAnimal.key}",
      "AnimalSound",
      "Recording_Discard",
    );

    await widget.stopMeasuring();
    await widget.audioController.stopSound();

    if (!mounted) return;
    setState(() => _phase = _Phase.idle);

    await _playSoundAndRecord();
  }

  Future<void> _saveAndAdvance() async {
    if (_phase != _Phase.recording) return;

    widget.logger.logOtherEvent(
      widget.currentRepetition,
      "Stop Record ${_currentAnimal.key}",
      "AnimalSound",
      "Recording_Stop",
    );

    await widget.stopMeasuring();

    if (!mounted) return;
    await widget.onNext();
  }

  Future<void> _onLeavePressed() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.t("Leave Study", "Studie verlassen")),
        content: Text(widget.t(
          "Are you sure you want to leave? Your progress may be lost.",
          "Sind Sie sicher, dass Sie die Studie verlassen möchten?",
        )),
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
      ),
    );
    if (shouldLeave == true) {
      await widget.onLeaveStudy();
    }
  }

  @override
  void dispose() {
    widget.audioController.stopSound();
    widget.stopMeasuring();
    widget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final animal = _currentAnimal;
    final label = t(animal.labelEn, animal.labelDe);

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
                              t("Examiner Instruction", "Anweisung für Untersucher"),
                              style: const TextStyle(
                                color: Colors.deepOrange,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              t(
                                "Press Play to play the animal sound and start recording. Use 'Repeat' to discard and retry, or 'Save' to keep and advance.",
                                "Drücken Sie Play um den Tierton abzuspielen und die Aufnahme zu starten. Mit 'Wiederholen' verwerfen und erneut abspielen, mit 'Speichern' behalten und weiter.",
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
                            Icon(animal.icon, size: 80, color: Colors.brown),
                            const SizedBox(height: 16),
                            Text(
                              label,
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildStatusText(),
                          ],
                        ),
                      ),
                    ),
                    _buildButtons(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              if (_phase == _Phase.playing || _phase == _Phase.starting)
                Container(
                  color: Colors.black.withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          _phase == _Phase.playing
                              ? t("Playing sound...", "Ton wird abgespielt...")
                              : t("Starting sensors...", "Sensoren werden gestartet..."),
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

  Widget _buildStatusText() {
    final t = widget.t;
    String text;
    Color color;
    switch (_phase) {
      case _Phase.idle:
        text = t("Ready — press Play", "Bereit — drücken Sie Play");
        color = Colors.grey.shade700;
      case _Phase.playing:
        text = t("Playing sound...", "Ton wird abgespielt...");
        color = Colors.orange;
      case _Phase.starting:
        text = t("Starting sensors...", "Sensoren starten...");
        color = Colors.orange;
      case _Phase.recording:
        text = t("Recording...", "Aufnahme läuft...");
        color = Colors.red;
    }
    return Text(text,
        style: TextStyle(
            color: color, fontSize: 18, fontWeight: FontWeight.w600));
  }

  Widget _buildButtons() {
    final t = widget.t;
    if (_phase == _Phase.idle) {
      return ElevatedButton.icon(
        onPressed: _playSoundAndRecord,
        icon: const Icon(Icons.play_arrow),
        label: Text(t("Play Sound", "Ton abspielen")),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
        ),
      );
    }
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _phase == _Phase.recording ? _repeatSound : null,
            icon: const Icon(Icons.replay),
            label: Text(t("Repeat", "Wiederholen")),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _phase == _Phase.recording ? _saveAndAdvance : null,
            icon: const Icon(Icons.save),
            label: Text(t("Save", "Speichern")),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
