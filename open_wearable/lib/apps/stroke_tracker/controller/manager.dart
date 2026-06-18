import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/audio_controller.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'package:open_wearable/apps/stroke_tracker/model/config.dart';
import 'package:open_wearable/view_models/sensor_configuration_provider.dart';
import 'package:path_provider/path_provider.dart';

class ExperimentManager extends ChangeNotifier {
  final ExperimentLogger logger;
  final ExperimentConfig expConfig;
  final OpenEarableV2 leftWearable;
  final OpenEarableV2 rightWearable;
  final Wearable ring;
  final SensorConfigurationProvider leftSensorCfgProvider;
  final SensorConfigurationProvider rightSensorCfgProvider;
  final SensorConfigurationProvider ringSensorCfgProvider;

  late List<SensorConfiguration> _leftSensorCfgs;
  late List<SensorConfiguration> _rightSensorCfgs;

  late Map<String, SensorConfiguration> _leftSensorIdToCfgMap;
  late Map<String, SensorConfiguration> _rightSensorIdToCfgMap;

  final AudioController _audioController = AudioController();

  late ImuCsvWriter _imuCsvWriter;

  Completer<void>? _leftReady;
  Completer<void>? _rightReady;
  Completer<void>? _ringReady;

  bool startedConfigs = false;

  StreamSubscription<SensorValue>? _leftSubscription;
  StreamSubscription<SensorValue>? _rightSubscription;
  StreamSubscription<SensorValue>? _ringSubscription;

  ExperimentManager({
    required this.logger,
    required this.expConfig,
    required this.leftWearable,
    required this.leftSensorCfgProvider,
    required this.rightWearable,
    required this.rightSensorCfgProvider,
    required this.ring,
    required this.ringSensorCfgProvider,
  }) {
    if (leftWearable is SensorConfigurationManager) {
      _leftSensorCfgs =
          (leftWearable as SensorConfigurationManager).sensorConfigurations;
      _leftSensorIdToCfgMap = {};
      for (var cfg in _leftSensorCfgs) {
        _leftSensorIdToCfgMap[cfg.name] = cfg;
      }
    } else {
      throw Exception(
        "The left wearable does not support sensor configuration",
      );
    }
    if (rightWearable is SensorConfigurationManager) {
      _rightSensorCfgs =
          (rightWearable as SensorConfigurationManager).sensorConfigurations;
      _rightSensorIdToCfgMap = {};
      for (var configuration in _rightSensorCfgs) {
        _rightSensorIdToCfgMap[configuration.name] = configuration;
      }
    } else {
      throw Exception(
        "The right wearable does not support sensor configuration",
      );
    }
  }

  Future<void> setSensorLogFilePrefix(String prefix) async {
    if (leftWearable is! EdgeRecorderManager) {
      throw Exception(
        "The left wearable does not support setting a log file prefix",
      );
    }
    if (rightWearable is! EdgeRecorderManager) {
      throw Exception(
        "The right wearable does not support setting a log file prefix",
      );
    }
    await Future.wait([
      (leftWearable as EdgeRecorderManager).setFilePrefix(_audioController.buildFilePrefix(prefix, isLeft: true)),
      (rightWearable as EdgeRecorderManager).setFilePrefix(_audioController.buildFilePrefix(prefix, isLeft: false)),
    ]);
  }

  SensorFrequencyConfigurationValue? _findBestMatch(
    List<SensorConfigurationValue> values,
    SensorConfig experimentSensorConfig,
  ) {
    SensorFrequencyConfigurationValue? bestMatch;
    double minDiff = 1000000;
    for (var value in values) {
      if (value is SensorFrequencyConfigurationValue) {
        double diff =
            (value.frequencyHz - experimentSensorConfig.sampleRate).abs();
        if (diff < minDiff) {
          minDiff = diff;
          bestMatch = value;
        }
        if (minDiff == 0) {
          break;
        }
      }
    }
    return bestMatch;
  }

  void _setConfigProvider(
    String? sensorId,
    SensorConfigurationProvider cfgProvider,
    Map<String, SensorConfiguration<SensorConfigurationValue>>
        sensorIdToConfigMap,
    SensorConfig experimentSensorConfig,
  ) {
    if (sensorId != null && sensorIdToConfigMap.containsKey(sensorId)) {
      final cfg = sensorIdToConfigMap[sensorId]!;
      if (cfg is SensorFrequencyConfiguration) {
        List<SensorConfigurationValue> values =
            cfgProvider.getSensorConfigurationValues(cfg, distinct: true);

        // Find the closest sample rate
        final bestMatch = _findBestMatch(values, experimentSensorConfig);

        if (bestMatch != null) {
          cfgProvider.addSensorConfiguration(
            cfg,
            bestMatch,
          );
        }
      }

      // for all sensors enable recording
      // for skin temp sensor enable streaming
      if (cfg is ConfigurableSensorConfiguration) {
        if (cfg.availableOptions.contains(RecordSensorConfigOption())) {
          cfgProvider.addSensorConfigurationOption(
            cfg,
            RecordSensorConfigOption(),
          );
          print("record_Option activated${cfg.name}");
        }
        if (sensorId == "9-Axis IMU" &&
            cfg.availableOptions.contains(StreamSensorConfigOption())) {
          cfgProvider.addSensorConfigurationOption(
            cfg,
            StreamSensorConfigOption(),
          );
        }
      }
    }
  }

  /// Configure sensors based on global configuration
  Future<
          (
            List<
                (
                  SensorConfiguration<SensorConfigurationValue>,
                  SensorConfigurationValue
                )>,
            List<
                (
                  SensorConfiguration<SensorConfigurationValue>,
                  SensorConfigurationValue
                )>
          )>
      configureSensors(
          String sessionId, int taskNumber, int repetitionNumber, bool useRing,
          {bool useAudio = false}) async {
    if (startedConfigs) {
      return (
        <(
          SensorConfiguration<SensorConfigurationValue>,
          SensorConfigurationValue
        )>[],
        <(
          SensorConfiguration<SensorConfigurationValue>,
          SensorConfigurationValue
        )>[],
      );
    }
    if (leftWearable is! SensorConfigurationManager) {
      throw Exception(
        "The left wearable does not support sensor configuration",
      );
    }
    if (rightWearable is! SensorConfigurationManager) {
      throw Exception(
        "The right wearable does not support sensor configuration",
      );
    }

    // Configure each sensor according to the global configuration
    for (var sensorConfig in expConfig.globalSensorConfigs) {
      final sensorName = sensorConfig.sensor.toLowerCase();

      // Get the sensor ID from the configuration
      final sensorId = expConfig.getSensorId(sensorName);

      _setConfigProvider(
        sensorId,
        leftSensorCfgProvider,
        _leftSensorIdToCfgMap,
        sensorConfig,
      );
      _setConfigProvider(
        sensorId,
        rightSensorCfgProvider,
        _rightSensorIdToCfgMap,
        sensorConfig,
      );
    }

    if (useAudio) {
      _audioController.enableMicrophoneRecording(leftSensorCfgProvider, _leftSensorIdToCfgMap);
      _audioController.enableMicrophoneRecording(rightSensorCfgProvider, _rightSensorIdToCfgMap);
    }

    if (useRing) {
      _imuCsvWriter = ImuCsvWriter();
      await _imuCsvWriter.init(sessionId, taskNumber, repetitionNumber);
    }
    _leftReady = Completer<void>();
    _rightReady = Completer<void>();
    _ringReady = Completer<void>();
    var leftSelectedCfgs = leftSensorCfgProvider.getSelectedConfigurations();
    for (var entry in leftSelectedCfgs) {
      SensorConfiguration config = entry.$1;
      SensorConfigurationValue value = entry.$2;
      config.setConfiguration(value);
    }

    var rightSelectedCfgs = rightSensorCfgProvider.getSelectedConfigurations();
    for (var entry in rightSelectedCfgs) {
      SensorConfiguration config = entry.$1;
      SensorConfigurationValue value = entry.$2;
      config.setConfiguration(value);
    }

    final sensorManager = ring.requireCapability<SensorManager>();
    final Sensor accelSensor = sensorManager.sensors.firstWhere(
        (s) => s.sensorName.toLowerCase() == "accelerometer".toLowerCase());

    final Set<SensorConfiguration> configurations = {};
    configurations.addAll(accelSensor.relatedConfigurations);

    for (final SensorConfiguration configuration in configurations) {
      if (configuration is ConfigurableSensorConfiguration &&
          configuration.availableOptions.contains(StreamSensorConfigOption())) {
        ringSensorCfgProvider.addSensorConfigurationOption(
            configuration, StreamSensorConfigOption());
      }
      List<SensorConfigurationValue> values = ringSensorCfgProvider
          .getSensorConfigurationValues(configuration, distinct: true);
      ringSensorCfgProvider.addSensorConfiguration(configuration, values.first);
      configuration.setConfiguration(
          ringSensorCfgProvider.getSelectedConfigurationValue(configuration)!);
    }

    _ringSubscription = accelSensor.sensorStream.listen((data) {
      if (!(_ringReady!.isCompleted)) {
        _ringReady!.complete();
        print("ring sensor started");
        logger.logSyncRingEvent(data.timestamp);
      }
      if (data is SensorDoubleValue) {
        final double ax = data.values[0];
        final double ay = data.values[1];
        final double az = data.values[2];
        if (useRing) {
          _imuCsvWriter.write(data.timestamp, ax, ay, az);
        }
      }
    });

    if (leftWearable is SensorManager) {
      List<Sensor> sensors = (leftWearable as SensorManager).sensors;
      for (var sensor in sensors) {
        if (sensor.sensorName.toLowerCase() == "accelerometer".toLowerCase()) {
          _leftSubscription = sensor.sensorStream.listen(
            (SensorValue value) {
              if (!(_leftReady!.isCompleted)) {
                _leftReady!.complete();
                print("Left sensor started");
                logger.logSyncLeftEvent(value.timestamp);
              }
            },
            onDone: () async => _leftSubscription?.cancel(),
            onError: (error) async {
              print('Right streaming error: $error');
              await _leftSubscription?.cancel();
            },
          );
        }
      }
    }

    if (rightWearable is SensorManager) {
      List<Sensor> sensors = (rightWearable as SensorManager).sensors;
      for (var sensor in sensors) {
        if (sensor.sensorName.toLowerCase() == "accelerometer".toLowerCase()) {
          _rightSubscription = sensor.sensorStream.listen(
            (SensorValue value) {
              if (!(_rightReady!.isCompleted)) {
                _rightReady!.complete();
                print("Right sensor started");
                logger.logSyncRightEvent(value.timestamp);
              }
            },
            onDone: () async => _rightSubscription?.cancel(),
            onError: (error) async {
              print('Right streaming error: $error');
              await _rightSubscription?.cancel();
            },
          );
        }
      }
    }

    if (useRing) {
      await Future.wait([
        _leftReady!.future,
        _rightReady!.future,
        _ringReady!.future,
      ]);
    } else {
      await Future.wait([
        _leftReady!.future,
        _rightReady!.future,
      ]);
    }

    String leftSelectedCfgsString = leftSelectedCfgs.map(
      (entry) {
        String name = entry.$1.name;
        String frequency = entry.$2 is SensorFrequencyConfigurationValue
            ? "${(entry.$2 as SensorFrequencyConfigurationValue).frequencyHz}Hz"
            : "configured";
        return "$name: $frequency";
      },
    ).join("; ");

    String rightSelectedCfgsString = rightSelectedCfgs.map(
      (entry) {
        String name = entry.$1.name;
        String frequency = entry.$2 is SensorFrequencyConfigurationValue
            ? "${(entry.$2 as SensorFrequencyConfigurationValue).frequencyHz}Hz"
            : "configured";
        return "$name: $frequency";
      },
    ).join("; ");

    print(leftSelectedCfgsString);
    print(rightSelectedCfgsString);
    startedConfigs = false;
    return (leftSelectedCfgs, rightSelectedCfgs);
  }

  Future<void> playSound({required bool left}) async {
    OpenEarableV2 wearable = left ? leftWearable : rightWearable;
    try {
      final AudioResponseManager? manager =
          wearable.getCapability<AudioResponseManager>();
      if (manager == null) {
        throw StateError(
          'Audio response capability not available on ${wearable.name}.',
        );
      }
      await manager.measureAudioResponse(
        const <String, dynamic>{},
      );
    } catch (error) {
      print('Sound check failed: ${error}');
    }
  }

  Future<void> synchronizeTime() async {
    leftWearable.requireCapability<TimeSynchronizable>().synchronizeTime();
    rightWearable.requireCapability<TimeSynchronizable>().synchronizeTime();
    ring.requireCapability<TimeSynchronizable>().synchronizeTime();
  }

  /// Deactivate all configured sensors
  Future<void> deactivateSensors() async {
    print("deactivated sensors");
    await _leftSubscription?.cancel();
    await _rightSubscription?.cancel();
    await _ringSubscription?.cancel();

    /*
    // Deactivate each configured sensor by removing their options
    for (var sensorConfig in expConfig.globalSensorConfigs) {
      final sensorName = sensorConfig.sensor.toLowerCase();
      final sensorId = expConfig.getSensorId(sensorName);

      if (sensorId != null && _leftSensorIdToCfgMap.containsKey(sensorId)) {
        final cfg = _leftSensorIdToCfgMap[sensorId]!;
        if (cfg is ConfigurableSensorConfiguration) {
          // Remove streaming option to disable the sensor
          leftSensorCfgProvider.removeSensorConfigurationOption(
            cfg,
            RecordSensorConfigOption(),
          );
          leftSensorCfgProvider.removeSensorConfigurationOption(
            cfg,
            StreamSensorConfigOption(),
          );
          var value = leftSensorCfgProvider.getSelectedConfigurationValue(cfg);
          if (value != null) {
            cfg.setConfiguration(
              value as ConfigurableSensorConfigurationValue,
            );
          }
        }
      }

      if (sensorId != null && _rightSensorIdToCfgMap.containsKey(sensorId)) {
        final cfg = _rightSensorIdToCfgMap[sensorId]!;
        if (cfg is ConfigurableSensorConfiguration) {
          // Remove streaming option to disable the sensor
          rightSensorCfgProvider.removeSensorConfigurationOption(
            cfg,
            RecordSensorConfigOption(),
          );
          rightSensorCfgProvider.removeSensorConfigurationOption(
            cfg,
            StreamSensorConfigOption(),
          );
          var value = rightSensorCfgProvider.getSelectedConfigurationValue(cfg);
          if (value != null) {
            cfg.setConfiguration(
              value as ConfigurableSensorConfigurationValue,
            );
          }
        }
      }
    } */
    await Future.wait([
      ringSensorCfgProvider.turnOffAllSensors(),
      rightSensorCfgProvider.turnOffAllSensors(),
      leftSensorCfgProvider.turnOffAllSensors(),
    ]);
  }

  Future<Map<String, dynamic>?> runSealCheck(bool isLeft) async {
    OpenEarableV2 wearable = isLeft ? leftWearable : rightWearable;
    Map<String, dynamic>? data;
    try {
      final AudioResponseManager? manager =
          wearable.getCapability<AudioResponseManager>();
      if (manager == null) {
        throw StateError(
          'Audio response capability not available on ${wearable.name}.',
        );
      }
      data = await manager.measureAudioResponse(
        const <String, dynamic>{},
      );
    } catch (error) {
      print('Seal check failed: ${error}');
    }
    return data;
  }
}

class ImuCsvWriter {
  late File _file;
  late IOSink _sink;

  Future<void> init(String sessionId, int taskId, int repetitionNumber) async {
    var now = DateTime.now();

    final dir = await getApplicationDocumentsDirectory();
    _file = File(
        '${dir.path}/${sessionId}_task_${taskId}_rep_${repetitionNumber}_${now.minute}:${now.second}_imulog.csv');

    // Write header if new
    if (!await _file.exists()) {
      await _file.writeAsString('timestamp,ax,ay,az\n');
    }

    _sink = _file.openWrite(mode: FileMode.append);
  }

  void write(int timestamp, double ax, double ay, double az) {
    _sink.writeln('$timestamp,$ax,$ay,$az');
  }

  Future<void> close() async {
    await _sink.flush();
    await _sink.close();
  }
}
