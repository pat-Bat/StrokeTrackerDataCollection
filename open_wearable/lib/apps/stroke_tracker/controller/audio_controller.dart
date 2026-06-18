import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_wearable/view_models/sensor_configuration_provider.dart';

class AudioController {
  static const String sdCardDirectory = "StrokeApp/";

  String buildFilePrefix(String sessionPrefix, {required bool isLeft}) {
    final side = isLeft ? 'L' : 'R';
    return "${sdCardDirectory}${side}${sessionPrefix}_";
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
      if (values.isNotEmpty) {
        cfgProvider.addSensorConfiguration(cfg, values.last);
      }
    }
    if (cfg is ConfigurableSensorConfiguration &&
        cfg.availableOptions.contains(RecordSensorConfigOption())) {
      cfgProvider.addSensorConfigurationOption(cfg, RecordSensorConfigOption());
    }
  }
}
