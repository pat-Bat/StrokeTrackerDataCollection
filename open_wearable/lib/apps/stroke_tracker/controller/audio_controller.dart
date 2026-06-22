import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_wearable/view_models/sensor_configuration_provider.dart';

class AudioController {
  static const String sdCardDirectory = "StrokeApp/";
  static const String _soundAssetPath = 'lib/apps/stroke_tracker/assets/sounds';
  final AudioPlayer _player = AudioPlayer();

  Future<void> playAssetSound(String filename) async {
    try {
      final byteData = await rootBundle.load('$_soundAssetPath/$filename');
      await _player.play(BytesSource(byteData.buffer.asUint8List()));
    } catch (e) {
      print("Error playing sound $filename: $e");
    }
  }

  Future<void> stopSound() async {
    await _player.stop();
  }

  void dispose() {
    _player.dispose();
  }

  String buildFilePrefix(String sessionPrefix, {required bool isLeft}) {
    final side = isLeft ? 'L' : 'R';
    return "${sdCardDirectory}${side}${sessionPrefix}_";
  }

  String buildAnimalFilePrefix(
    String sessionCompact,
    String animalName, {
    required bool isLeft,
  }) {
    final side = isLeft ? 'L' : 'R';
    return "${sdCardDirectory}${side}${sessionCompact}_${animalName}_";
  }

  void enableMicrophoneRecording(
    SensorConfigurationProvider cfgProvider,
    Map<String, SensorConfiguration> sensorIdToCfgMap,
  ) {
    const micSensorId = "Microphones";
    if (!sensorIdToCfgMap.containsKey(micSensorId)) return;
    final cfg = sensorIdToCfgMap[micSensorId]!;
    if (cfg is SensorFrequencyConfiguration) {
      final values =
          cfgProvider.getSensorConfigurationValues(cfg, distinct: true);
      for (var v in values) {
        if (v is SensorFrequencyConfigurationValue) {
          print("Mic available freq: ${v.frequencyHz} Hz");
        }
      }
      if (values.isNotEmpty) {
        cfgProvider.addSensorConfiguration(cfg, values.first);
        print("Mic selected: ${values.first}");
      }
    }
    if (cfg is ConfigurableSensorConfiguration &&
        cfg.availableOptions.contains(RecordSensorConfigOption())) {
      cfgProvider.addSensorConfigurationOption(cfg, RecordSensorConfigOption());
    }
  }
}
