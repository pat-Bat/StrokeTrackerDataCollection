import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:flutter/material.dart';
import 'package:open_wearable/apps/stroke_tracker/model/study_step.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:typed_data';

/// Represents a single step event
class StepEvent {
  final int blockNumber;
  final String taskId;
  final DateTime startTime;
  DateTime? endTime;
  final int relativeStartTime;
  int? relativeEndTime;

  StepEvent({
    required this.blockNumber,
    required this.taskId,
    required this.startTime,
    this.endTime,
    required this.relativeStartTime,
    this.relativeEndTime,
  });

  List<String> toCsvRow(String sessionID) {
    return [
      sessionID,
      blockNumber.toString(),
      taskId,
      startTime.toIso8601String(),
      endTime?.toIso8601String() ?? '',
      relativeStartTime.toString(),
      relativeEndTime?.toString() ?? '',
    ];
  }
}

class OtherEvent {
  final int blockNumber;
  final String instruction;
  final String taskId;
  final int timestamp;
  final int relativeTime;
  final String eventType;

  OtherEvent({
    required this.blockNumber,
    required this.instruction,
    required this.taskId,
    required this.timestamp,
    required this.relativeTime,
    required this.eventType,
  });

  List<String> toCsvRow(String sessionID) {
    return [
      sessionID,
      blockNumber.toString(),
      instruction,
      taskId,
      timestamp.toString(),
      relativeTime.toString(),
      eventType,
    ];
  }
}

class SyncEvent {
  final int deviceTimestamp;
  final DateTime phoneTimestamp;
  final int relativePhoneTime;
  SyncEvent({
    required this.deviceTimestamp,
    required this.phoneTimestamp,
    required this.relativePhoneTime,
  });

  List<String> toCsvRow(String sessionID) {
    return [
      sessionID,
      deviceTimestamp.toString(),
      phoneTimestamp.toIso8601String(),
      relativePhoneTime.toString(),
    ];
  }
}

class LabelEvent {
  final int labelValue;
  final int taskID;
  final int repetition;
  final Side? symptomSide;
  final String instruction;
  LabelEvent(
      {required this.labelValue,
      required this.taskID,
      required this.repetition,
      required this.instruction,
      required this.symptomSide});

  List<String> toCsvRow(String sessionID) {
    return [
      sessionID,
      taskID.toString(),
      repetition.toString(),
      instruction,
      labelValue.toString(),
      symptomSide.toString()
    ];
  }
}

/// Logger for ExperimentManager
class ExperimentLogger extends ChangeNotifier {
  static const String _stepsCsvHeader =
      'SessionID,Block,Task,DurationS,StartTime,EndTime,RelativeStartMS,RelativeEndMS';
  static const String _otherCsvHeader =
      'SessionID,Block,Task,Time,RelativeTimeMS,EventType,Value';

  static const String _labelCsvHeader =
      'SessionID,TaskID,Repetition,instruction,Value,Impairmentside';
  static const String _syncCsvHeader =
      'SessionID,DeviceTimestamp,PhoneTimestamp,RelativePhoneTimeMS,Side';

  late File _syncCsvFile;
  late File _stepsCsvFile;
  late File _otherCsvFile;
  late File _labelCsvFile;

  late String sessionID;
  late DateTime _sessionStartTime;
  final List<(SyncEvent, String)> _syncEvents = [];
  final List<StepEvent> _stepEvents = [];
  final List<OtherEvent> _otherEvents = [];
  final List<LabelEvent> _label = [];

  File get csvFile => _stepsCsvFile;

  Future<void> startLogging(bool sync, String newSessionID) async {
    sessionID = newSessionID;
    final dir = await getApplicationDocumentsDirectory();

    _stepsCsvFile = File('${dir.path}/steps_log.csv');
    _otherCsvFile = File('${dir.path}/other_log.csv');
    _syncCsvFile = File('${dir.path}/sync_log.csv');
    _labelCsvFile = File('${dir.path}/label_log.csv');

    if (!await _syncCsvFile.exists()) {
      await _syncCsvFile.writeAsString(_syncCsvHeader);
    }
    if (!await _stepsCsvFile.exists()) {
      await _stepsCsvFile.writeAsString(_stepsCsvHeader);
    }

    if (!await _otherCsvFile.exists()) {
      await _otherCsvFile.writeAsString(_otherCsvHeader);
    }

    if (!await _labelCsvFile.exists()) {
      await _labelCsvFile.writeAsString(_labelCsvHeader);
    }
    _sessionStartTime = DateTime.now();
  }

  void logSyncLeftEvent(int deviceTimestamp) {
    _logSyncEvent(deviceTimestamp, "L");
  }

  void logSyncRightEvent(int deviceTimestamp) {
    _logSyncEvent(deviceTimestamp, "R");
  }

  void logSyncRingEvent(int deviceTimestamp) {
    _logSyncEvent(deviceTimestamp, "O");
  }

  void _logSyncEvent(int deviceTimestamp, String side) {
    final now = DateTime.now();
    final relative = now.difference(_sessionStartTime).inMilliseconds;

    final event = SyncEvent(
      deviceTimestamp: deviceTimestamp,
      phoneTimestamp: now,
      relativePhoneTime: relative,
    );

    _syncEvents.add((event, side));

    print("SYNC $side: ${event.toCsvRow(sessionID)}");
  }

  void logOtherEvent(
    int blockNumber,
    String instruction,
    String taskId,
    String eventType,
  ) {
    final now = DateTime.now();
    final relative = now.difference(_sessionStartTime).inMilliseconds;
    final event = OtherEvent(
      blockNumber: blockNumber,
      instruction: instruction,
      taskId: taskId,
      timestamp: now.microsecondsSinceEpoch,
      relativeTime: relative,
      eventType: eventType,
    );
    print(event.toCsvRow(sessionID));
    _otherEvents.add(event);
  }

  void logLabel(
      int taskID, int value, Side? side, int repetition, String instruction) {
    final event = LabelEvent(
        labelValue: value,
        taskID: taskID,
        repetition: repetition,
        symptomSide: side,
        instruction: instruction);
    _label.add(event);
  }

  void logTaskStart(
    int blockNumber,
    String taskId,
  ) {
    final now = DateTime.now();
    final relative = now.difference(_sessionStartTime).inMilliseconds;
    final event = StepEvent(
      blockNumber: blockNumber,
      taskId: taskId,
      startTime: now,
      relativeStartTime: relative,
    );
    print(event.toCsvRow(sessionID));
    _stepEvents.add(event);
  }

  void logTaskEnd() {
    if (_stepEvents.isEmpty) return;
    final now = DateTime.now();
    final relative = now.difference(_sessionStartTime).inMilliseconds;
    final event = _stepEvents.last;
    event.endTime = now;
    event.relativeEndTime = relative;
    print(event.toCsvRow(sessionID));
  }

  void discardLastTask() {
    if (_stepEvents.isNotEmpty) _stepEvents.removeLast();
  }

  Future<void> stopAndWriteLogging(bool sync) async {
    print("Finalizing experiment");

    final converter = ListToCsvConverter();
    final syncRows = <List<String>>[];

    for (final (event, side) in _syncEvents) {
      final row = event.toCsvRow(sessionID)..add(side);
      syncRows.add(row);
    }

    final syncCsvData = converter.convert(syncRows);

    final stepsRows = <List<String>>[];
    for (final e in _stepEvents) {
      stepsRows.add(e.toCsvRow(sessionID));
    }
    final otherRows = <List<String>>[];
    for (final e in _otherEvents) {
      otherRows.add(e.toCsvRow(sessionID));
    }

    final labelRows = <List<String>>[];
    for (final e in _label) {
      labelRows.add(e.toCsvRow(sessionID));
    }

    final stepsCsvData = converter.convert(stepsRows);
    final otherCsvData = converter.convert(otherRows);
    final labelCsvData = converter.convert(labelRows);

    await Future.wait([
      if (stepsRows.isNotEmpty)
        _stepsCsvFile.writeAsString("\n$stepsCsvData", mode: FileMode.append),
      if (otherRows.isNotEmpty)
        _otherCsvFile.writeAsString("\n$otherCsvData", mode: FileMode.append),
      if (syncRows.isNotEmpty)
        _syncCsvFile.writeAsString("\n$syncCsvData", mode: FileMode.append),
      if (labelRows.isNotEmpty)
        _labelCsvFile.writeAsString("\n$labelCsvData", mode: FileMode.append),
    ]);

    _stepEvents.clear();
    _otherEvents.clear();
    _syncEvents.clear();
    _label.clear();
  }

  /// Get all log files in the documents directory
  static Future<List<File>> getAllLogFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = <File>[];

    try {
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('log.csv')) {
          files.add(entity);
        }
      }
    } catch (e) {
      print('Error listing log files: $e');
    }

    // Sort by modification date, newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  /// Delete a log file
  static Future<void> deleteLogFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> clearAppDocumentsDirectory() async {
    final dir = await getApplicationDocumentsDirectory();

    if (await dir.exists()) {
      final files = dir.listSync();

      for (final file in files) {
        try {
          if (file is File) {
            await file.delete();
          } else if (file is Directory) {
            await file.delete(recursive: true);
          }
        } catch (e) {
          print("Error deleting $file: $e");
        }
      }
    }
    print("ApplicationDocumentsDirectory cleared");
  }

  static Future<void> deleteAllLogFiles() async {
    final dir = await getApplicationDocumentsDirectory();

    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    await dir.create();
  }

  static Future<void> copyToOther(String dirPath) async {
    List<File> sourceFiles = await getAllLogFiles();
    for (File file in sourceFiles) {
      String targetPath = "$dirPath/${file.path.split("/").last}";
      final targetFile = File(targetPath);

      // Make sure the directory exists
      await Directory(dirPath).create(recursive: true);

      // Delete target if it exists (overwrite safely)
      await targetFile.writeAsString(await file.readAsString());
    }
  }

  static String boundingBoxToString(BoundingBox box) {
    return [
      box.topLeft.x,
      box.topLeft.y,
      box.topRight.x,
      box.topRight.y,
      box.bottomLeft.x,
      box.bottomLeft.y,
      box.bottomRight.x,
      box.bottomRight.y
    ].join(',');
  }

  static String faceMeshToString(FaceMesh mesh) {
    final values = <String>[];

    List<Point> points = mesh.points;
    List<String> point = [];

    for (var p in points) {
      point.add(p.x.toString());
      point.add(p.y.toString());
      point.add(p.z.toString());
      values.add(point.join(','));
      point = [];
    }

    return values.join(',');
  }

  static Future<void> logFaceData(
    List<(DateTime, Face, int, int)> faces,
    String sessionId,
    int repetition,
  ) async {
    await logFaceDataBinary(faces, sessionId, repetition);
    /*
    final csvRows = <String>[];

    for (final (time, face, height, width) in faces) {
      if (face.mesh != null) {
        final row =
            '$sessionId,'
            '$repetition,'
            '${time.toIso8601String()},'
            '$width,'
            '$height,'
            '${boundingBoxToString(face.boundingBox)},'
            '${faceMeshToString(face.mesh!)}';

        csvRows.add(row);
      }
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${sessionId}_faces.csv');
    if (!await file.exists()) {
      List<String> header = [];
      header.add("SessionId");
      header.add("RepetitionNumber");
      header.add("TimeStamp");
      header.add("Imagewidth");
      header.add("Imageheight");
      header.add("box.left_x,box.left_y,box.top_x,box.top_y,box.right_x,box.right_y,box.bottom_x,box.bottom_y");
      
      for (int i = 0; i < 468; i++) {
        header.add("${i}_x,${i}_y,${i}_z");
      }
      await file.writeAsString('${header.join(",")}\n');
    }
    // append correctly
    final sink = file.openWrite(mode: FileMode.append);
    
    for (final row in csvRows) {
      sink.writeln(row);
    }

    await sink.flush();
    await sink.close(); */
  }

  static Future<void> logFaceDataBinary(
    List<(DateTime, Face, int, int)> faces,
    String sessionId,
    int repetition,
  ) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/${sessionId}_faces.bin');

    final sink = file.openWrite(mode: FileMode.append);

    for (final (time, face, height, width) in faces) {
      if (face.mesh == null) continue;

      final builder = BytesBuilder();

      // repetition
      final repetitionData = ByteData(4)
        ..setInt32(0, repetition, Endian.little);
      builder.add(repetitionData.buffer.asUint8List());

      // timestamp (microseconds since epoch)
      final timestampData = ByteData(8)
        ..setInt64(
          0,
          time.microsecondsSinceEpoch,
          Endian.little,
        );
      builder.add(timestampData.buffer.asUint8List());

      // image dimensions
      final dimData = ByteData(8)
        ..setInt32(0, width, Endian.little)
        ..setInt32(4, height, Endian.little);
      builder.add(dimData.buffer.asUint8List());

      // bounding box
      final box = face.boundingBox;

      final bboxData = Float32List.fromList([
        box.topLeft.x,
        box.topLeft.y,
        box.topRight.x,
        box.topRight.y,
        box.bottomRight.x,
        box.bottomRight.y,
        box.bottomLeft.x,
        box.bottomLeft.y
      ]);

      builder.add(bboxData.buffer.asUint8List());

      // landmarks
      final points = face.mesh!.points;

      final landmarkData = Float32List(points.length * 2);

      for (int i = 0; i < points.length; i++) {
        landmarkData[i * 2] = points[i].x.toDouble();
        landmarkData[i * 2 + 1] = points[i].y.toDouble();
      }

      builder.add(landmarkData.buffer.asUint8List());

      sink.add(builder.takeBytes());
    }

    await sink.flush();
    await sink.close();
  }

  static Future<List<File>> getAllAudioFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = <File>[];
    try {
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith('.wav')) {
          files.add(entity);
        }
      }
    } catch (e) {
      print('Error listing audio files: $e');
    }
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }

  static Future<List<File>> getAllFaceData() async {
    final directory = await getApplicationDocumentsDirectory();
    final files = <File>[];

    try {
      await for (final entity in directory.list()) {
        if (entity is File &&
            (entity.path.endsWith('faces.csv') ||
                entity.path.endsWith('faces.bin'))) {
          files.add(entity);
        }
      }
    } catch (e) {
      print('Error listing log files: $e');
    }

    // Sort by modification date, newest first
    files.sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    return files;
  }
}
