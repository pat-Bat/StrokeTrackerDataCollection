
import 'dart:math';

import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/manager.dart';
import 'package:open_wearable/apps/stroke_tracker/model/config.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_protocol.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';
import 'package:open_wearable/apps/stroke_tracker/view/end_page.dart';
import 'package:open_wearable/apps/stroke_tracker/view/instruction_screen.dart';
import 'package:open_wearable/apps/stroke_tracker/view/measuring_page.dart';
import 'package:open_wearable/apps/stroke_tracker/view/repetition_screen.dart';
import 'package:open_wearable/apps/stroke_tracker/view/smile_check_screen.dart';
import 'package:open_wearable/apps/stroke_tracker/view/study_selector.dart';
import 'package:open_wearable/apps/stroke_tracker/view/test_selection.dart';

import 'package:open_wearable/view_models/sensor_configuration_provider.dart';





class StudyRunner extends StatefulWidget {
  final StudyProtocol protocol;
  final ExperimentLogger logger;
  final OpenEarableV2 leftWearable;
  final OpenEarableV2 rightWearable;
  final Wearable ring;
  final SensorConfigurationProvider leftConfigProvider;
  final SensorConfigurationProvider rightConfigProvider;
  final SensorConfigurationProvider ringConfigProvider;

  const StudyRunner({
    super.key,
    required this.protocol,
    required this.logger,
    required this.leftWearable,
    required this.rightWearable,
    required this.leftConfigProvider,
    required this.rightConfigProvider,
    required this.ring,
    required this.ringConfigProvider,
  });

  @override
  State<StudyRunner> createState() => _StudyRunnerState();
}

class _StudyRunnerState extends State<StudyRunner> {
  late final List<StudyStep> _steps;
  int _currentIndex = -1;
  String currentInstruction = "";
  int _stepsDone = 0;
  int _stepsTotal = 0;
  int _repetitionCounter = 1;
  late final FaceDetectorIsolate _faceDetectorIsolate;
  /// Zählt echte Mess-Schritte (1,2,3...)

  late final ExperimentManager _manager;
  late final ExperimentLogger _logger;
  late final ExperimentConfig _expConfig;

  late final Future<void> _loadingFuture;

  @override
  void initState() {
    super.initState();
    _loadConfigureFaceDetector();
    _steps = widget.protocol.getSteps();
    _stepsTotal = widget.protocol.stepsTotal();
    _logger = ExperimentLogger();
    _loadingFuture = _loadConfigAndInitManager();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );

  }

  //takes 100-500ms
  Future<void> _loadConfigureFaceDetector() async {
    try {
      _faceDetectorIsolate = await FaceDetectorIsolate.spawn(
        model: FaceDetectionModel.backCamera,
        performanceConfig: PerformanceConfig.auto(),
        meshPoolSize: 1,
      );
      
    } catch (_) {}
    setState(() {});
  }
  

  Future<void> _loadConfigAndInitManager() async {
    final sensorConfigs = [
      SensorConfig(sensor: "imu", sampleRate: 50),
      SensorConfig(sensor: "pressure", sampleRate: 50),
      SensorConfig(sensor: "microphone", sampleRate: 48000),
      SensorConfig(sensor: "ppg", sampleRate: 50),
      SensorConfig(sensor: "bone_conduction", sampleRate: 1600),
      //SensorConfig(sensor: "temperature", sampleRate: 8),
    ];

    _expConfig = ExperimentConfig(globalSensorConfigs: sensorConfigs); 

    _manager = ExperimentManager(
      logger: _logger,
      expConfig: _expConfig,
      leftWearable: widget.leftWearable,
      leftSensorCfgProvider: widget.leftConfigProvider,
      rightWearable: widget.rightWearable,
      rightSensorCfgProvider: widget.rightConfigProvider,
      ring: widget.ring,
      ringSensorCfgProvider: widget.ringConfigProvider,
    );
  }



  Future<void> _startMeasuring(bool useRing) async {
    //await _manager.deactivateSensors(); // <-- wichtig
    final step = _steps[_currentIndex];
    // final date = DateTime.now().toIso8601String().replaceAll(':', '-');
    final recordingId = 
        "${widget.protocol.sessionId.replaceAll(':', '-')}_Step_${_currentIndex}_rep_${_repetitionCounter}_";

    await _logger.startLogging(false, widget.protocol.sessionId);
    _logger.logTaskStart(_currentIndex, step.heading);

    print("startSensorLogFilePrefix");
    await _manager.setSensorLogFilePrefix(recordingId);
    print("startConfigureSensors");
    await _manager.configureSensors(widget.protocol.sessionId,_currentIndex,_repetitionCounter, useRing);
    print("Sensoren gestartet");
  }

  Future<void> _stopAndConfirm() async {
    await _manager.deactivateSensors();
  }

  void onHeadTurnTest() {
    _jumpToTest(2);
  }

  void onSmileTest() {
    _jumpToTest(0);
  }

  void onTapTest() {
    _jumpToTest(4);
  }

  void _jumpToTest(int index) {
    setState(() {
      _currentIndex = index;
      _repetitionCounter = 1;
    });
  }

  Future<void> _testSelection() async{
    setState(() {
      _currentIndex = -1;
      _repetitionCounter = 1;
    });
  }

  Future<bool?> showContinueDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(widget.protocol.t('Continue?','Weiter?')),
        content: Text(widget.protocol.t('Do you want to continue taking measurements?','Wollen Sie weitere Messung durchführen?')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(widget.protocol.t('No', 'Nein')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.protocol.t('Yes', 'Ja')),
          ),
        ],
      );
    },
  );
}
  void addRepetition() {
    setState(() {
      _steps[_currentIndex].repetitions++;
      _stepsTotal++;
    });
    print("Repcounter:$_repetitionCounter");
    print("steps_reps:${_steps[_currentIndex].repetitions}");
  }

  Future<void> _saveAndAdvance() async {
    _logger.logTaskEnd();
    await _logger.stopAndWriteLogging(false);
    final currentStep = _steps[_currentIndex];
    int maxRepetitions = currentStep.repetitions;
    setState(() {
      if (_steps[_currentIndex].type != StudyStepType.instruction) {
        _stepsDone = _stepsDone + 1;
      }
    });
    await Navigator.push(context, 
    MaterialPageRoute(
    builder: (context) => TaskScreen(
      stepsDone: _stepsDone,
      stepsTotal: _stepsTotal,
      manager: _manager,
      maxRepetition: maxRepetitions, 
      currentRepetition: _repetitionCounter, 
      logger: _logger,
      onLeaveStudy: _leaveStudy,
      currentStepNumber: _currentIndex,
      currentStepTask: _steps[_currentIndex].heading,
      translate: widget.protocol.t,
      addRepetition: addRepetition,
      instruction: currentInstruction,
      ),
      
    ),
    );
    maxRepetitions = currentStep.repetitions;
    setState(() {
      
      
      if (_repetitionCounter < maxRepetitions) {
        // weitere Wiederholung des gleichen Schritts
        print("repeat step");
        _repetitionCounter++;
      } else {
        _repetitionCounter = 1;
        _nextStep();
  

      }
    });
  }

  Future<void> _leaveStudy() async {
    print("leave_Study");
    await _manager.deactivateSensors();

      try {
        _logger.logTaskEnd();
        await _logger.stopAndWriteLogging(false);
      } catch (_) {}
    

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        platformPageRoute(
          context: context,
          builder: (_) => StudySelection(
            leftWearable: widget.leftWearable,
            rightWearable: widget.rightWearable,
            leftConfigProvider: widget.leftConfigProvider,
            rightConfigProvider: widget.rightConfigProvider,
            ring: widget.ring,
            ringConfigProvider: widget.ringConfigProvider,
          ),
        ),
        (route) => route.isFirst,
      );
    }
  }

  Future<void> _nextStep() async {
    print("go to next Step");
    _manager.synchronizeTime();
    if (_currentIndex < _steps.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _leaveStudy();
    }
  }


  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _loadingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return PlatformScaffold(
            body: Center(child: PlatformCircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return PlatformScaffold(
            appBar: PlatformAppBar(title: Text("Fehler")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("${snapshot.error}"),
              ),
            ),
          );
        }

        if(_currentIndex <0) {
          return TestSelectionScreen(onSmileTest: onSmileTest, onHeadTurnTest: onHeadTurnTest, onArmMovementTest: onTapTest,t: widget.protocol.t, onLeaveStudy: _leaveStudy,);
        } else {

        final step = _steps[_currentIndex];
        if (step.type == StudyStepType.instruction) {
          return EarbudSealTestScreen(
            stepsDone: _stepsDone,
            stepsTotal: _stepsTotal,
            sessionId: widget.protocol.sessionId,
            logger: _logger,
            heading: step.heading,
            currentRepetitionNumber: _repetitionCounter,
            currentStepNumber: _currentIndex,
            description: step.description,
            sealCheck: _manager.runSealCheck,
            onNext: _nextStep,
            onLeaveStudy: _leaveStudy,
            t: widget.protocol.t,
          );
        }

        if (step.type == StudyStepType.cameraMeasurement) {
          currentInstruction = "SmileTask";
          return CameraMeasuringScreen(
            currentRepetition: _repetitionCounter,
            onLeaveStudy: _leaveStudy,
            repetitions: step.repetitions, 
            onNext: _saveAndAdvance, 
            startMeasuring: _startMeasuring, 
            stopMeasuring: _stopAndConfirm, 
            logger: _logger,
            faceDetector: _faceDetectorIsolate,
            recordingId: widget.protocol.sessionId,
            t: widget.protocol.t,
            dispose: _manager.deactivateSensors,
            useRing: false,
            manager: _manager,
            );
        }

        if (step.type == StudyStepType.ending) {
          return SummaryScreen(onLeaveStudy: _leaveStudy, t: widget.protocol.t,);
        }
        
        if ( step.type == StudyStepType.measuringTap) {
          final random = Random();
          int index = random.nextInt(2);
          var instruction = _steps[_currentIndex].measuringInstructions[index];
          Side soundside = Side.left;
          switch (index) {
            case 0:
              soundside = Side.right;
            case 1:
              soundside = Side.left;
          }
          currentInstruction = "DoubleTap ${soundside.toString().split(".")[1]} Earable";
          return MeasuringScreen(
            repetitions: step.repetitions,
            stepsDone: _stepsDone,
            stepsTotal: _stepsTotal,
            onLeaveStudy: _leaveStudy, 
            onNext: _saveAndAdvance, 
            startMeasuring: _startMeasuring, 
            stopMeasuring: _stopAndConfirm, 
            currentRepetition: _repetitionCounter, 
            logger: _logger, 
            recordingId: widget.protocol.sessionId, 
            taskName: step.heading, 
            instruction: instruction,
            playSound: step.playSound,
            soundSide: soundside,
            t: widget.protocol.t,
            dispose: _manager.deactivateSensors,
            manager: _manager,
            timer: 10,
            useRing: true,
            );
        }

        if (step.type == StudyStepType.measuringHead) {
          final random = Random();
          int index = random.nextInt(2);
          var instruction = _steps[_currentIndex].measuringInstructions[index];
          Side soundside = Side.left;
          switch (index) {
            case 0:
              soundside = Side.right;
            case 1:
              soundside = Side.left;
          }
          currentInstruction = "Headturn Start at ${soundside.toString().split(".")[1]} the other side";

          return MeasuringScreen(
            stepsDone: _stepsDone,
            stepsTotal: _stepsTotal,
            repetitions: step.repetitions,
            onLeaveStudy: _leaveStudy,
            onNext: _saveAndAdvance, 
            startMeasuring: _startMeasuring, 
            stopMeasuring: _stopAndConfirm, 
            currentRepetition: _repetitionCounter, 
            logger: _logger, 
            recordingId: widget.protocol.sessionId, 
            taskName: step.heading, 
            instruction: instruction,
            playSound: step.playSound,
            soundSide: step.soundside,
            t: widget.protocol.t,
            dispose: _manager.deactivateSensors,
            manager: _manager,
            timer: 15,
            useRing: false,
            );
        }
        return PlatformScaffold(
            appBar: PlatformAppBar(title: Text("Fehler")),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text("${snapshot.error}"),
              ),
            ),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    _faceDetectorIsolate.dispose();
    _manager.deactivateSensors();
    super.dispose();
  }
}
