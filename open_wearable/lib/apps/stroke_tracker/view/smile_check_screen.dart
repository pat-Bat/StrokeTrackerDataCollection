import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'package:face_detection_tflite/face_detection_tflite.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/manager.dart';
import 'package:opencv_dart/opencv_dart.dart' as cv;

class CameraMeasuringScreen extends StatefulWidget {
  final int repetitions;
  final int currentRepetition;
  final Future<void> Function() onNext;
  final Future<void> Function() onLeaveStudy;
  final Future<void> Function(bool useRing) startMeasuring;
  final Future<void> Function() stopMeasuring;
  final Future<void> Function() dispose;
  final String instruction;
  final String Function(String en,String de) t;
  final FaceDetectorIsolate faceDetector;
  final ExperimentLogger logger;
  final ExperimentManager manager;
  final String recordingId;
  final bool useRing;

  const CameraMeasuringScreen({
    super.key,
    required this.repetitions,
    required this.onNext,
    required this.onLeaveStudy,
    required this.startMeasuring,
    required this.stopMeasuring,
    required this.currentRepetition,
    required this.faceDetector,
    required this.logger,
    required this.recordingId,
    required this.t,
    required this.dispose,
    required this.useRing,
    required this.manager,
    required this.instruction,
  });

  @override
  State<CameraMeasuringScreen> createState() => _CameraMeasuringScreenState();
}

class _CameraMeasuringScreenState extends State<CameraMeasuringScreen> {
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  //bool debugimagesaved = false;
  bool recording = false;
  List<(DateTime, Face,int, int)> faceBuffer = [];
  late final String Function(String en,String de) t;
  bool isStarting = false;

  CameraLensDirection cameraLensDirection = CameraLensDirection.back;
  int millisecBetweenRecordedFrames= 50;

  int countdown = 10;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    t = widget.t;
    _initCamera();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  
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

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      final backCamera = cameras.firstWhere(
        (cam) => cam.lensDirection == cameraLensDirection,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        backCamera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      _initializeControllerFuture = _cameraController!.initialize();

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Kamera konnte nicht initialisiert werden: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (_initializeControllerFuture != null) {
      await _initializeControllerFuture;
    }
    setState(() {
      
      isStarting = true;
    });
    print("started measurement camera");
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
    DateTime lastLoggedTime = DateTime.now().subtract(Duration(seconds: 1));
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      debugPrint("Kamera nicht bereit für Aufnahme.");
      return;
    }
    
    setState(() {
      isStarting = false;
    });
    try {
      await _cameraController!.startImageStream(
        (CameraImage image) async{
          final now = DateTime.now();
          if (now.difference(lastLoggedTime).inMilliseconds <= millisecBetweenRecordedFrames) {
            return;
          }
          lastLoggedTime = now;
          final cv.Mat? mat = await _convertCameraImageToMat(image);
          if (mat != null ) {
            List<Face> faces = await widget.faceDetector.detectFacesFromMat(mat, mode: FaceDetectionMode.standard);
            if (faces.isNotEmpty) {
              Face face = faces.first;
              faceBuffer.add((now, face, mat.height, mat.width));
              /*
              if (!debugimagesaved) {
              _saveDebugMeshImage(mat.clone(), faces.first);
              debugimagesaved = true;
              }
              */
            }
            
            mat.dispose();
            
          } else {
            print("no Image for face recognition");
          }
          

        });
      
      
      
      setState(() {
        recording = true;
      });
      _startTimer();
      widget.logger.logOtherEvent(
        widget.currentRepetition,
        "Start Record of smilingpatient",
        "Smiling Task",
        "Video_Record_Start",
      );
      debugPrint("Videoaufnahme gestartet.");
    } catch (e) {
      widget.stopMeasuring();
      debugPrint("Fehler beim Starten der Videoaufnahme: $e");
    }
  }
  // Erstellt ein Bild und zeichnet alle Landmarks auf diesem mit Nummer auf 
  /* 
  Future<void> _saveDebugMeshImage(cv.Mat mat, Face face) async {
    try {
      final box = face.boundingBox;

      // Draw bounding box

      FaceMesh? landmarks = face.mesh;
      if (landmarks == null) return;

      for (int i = 0; i < landmarks.length; i++) {
        final p = landmarks[i];

        final x = p.x.toInt();
        final y = p.y.toInt();

        // Draw point
        cv.circle(
          mat,
          cv.Point(x, y),
          2,
          cv.Scalar(0, 0, 255), // red
        );

        // Draw index number
        cv.putText(
          mat,
          '$i',
          cv.Point(x + 2, y + 2),
          cv.FONT_HERSHEY_SIMPLEX,
          0.3,
          cv.Scalar(255, 0, 0), // blue text
        );
      }

      // Save image
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/mesh_debug_${DateTime.now().millisecondsSinceEpoch}.png';
      
      cv.imwrite(path, mat);
      
      // Share the file
      
      final params = ShareParams(files: [XFile(path)], text: "debugImage");
      await SharePlus.instance.share(params);
      print("Saved debug image: $path");
    } catch (e) {
      print("Error saving debug image: $e");
    }
  }
  */
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
            "Möchten Sie diese Messung speichern oder wiederholen?"
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
            )
          ],
        );
      },
    );
  }

  Future<void> _stopVideoRecording() async {
    if (!recording) {
      return;
    }
    widget.logger.logOtherEvent(
        widget.currentRepetition,
        "Stop Record of smiling patient",
        "Smiling task",
        "Video_Record_Stop",
      );

    setState(() {
      recording = false;
    });
    _timer?.cancel();
    await widget.stopMeasuring();
    
    
    if (_cameraController == null) {
      return;
    }

    try {
      await _cameraController!.stopImageStream();

      
    } catch (e) {
      debugPrint("Fehler beim Stoppen der Videoaufnahme: $e");
    }

    final shouldSave = await _showSaveDialog();

    if (shouldSave == true) {
      await flushBuffer();
      await widget.onNext();
    } else {
      // discard data and reset
      faceBuffer.clear();

      setState(() {
        countdown = 10;
      });

      debugPrint("Measurement discarded. Ready to remeasure.");}
  }


  @override
  void dispose() {
    if (_cameraController?.value.isStreamingImages ?? false) {
      _cameraController!.stopImageStream();
    }
    widget.stopMeasuring();
    _timer?.cancel();
    _cameraController?.dispose();
    widget.dispose();
    super.dispose();
  }

  /// Converts CameraImage to cv.Mat (BGR) for OpenCV processing.
  ///
  /// Handles multiple pixel formats:
  /// - iOS NV12 (2 planes): YUV420 with interleaved UV
  /// - Android I420 (3 planes): YUV420 with separate U/V planes
  /// - Desktop BGRA/RGBA (1 plane): camera_desktop provides packed 4-channel
  ///   (macOS = BGRA byte order, Linux = RGBA byte order)
  Future<cv.Mat?> _convertCameraImageToMat(CameraImage image) async {
    try {
      final int width = image.width;
      final int height = image.height;

      // Desktop: camera_desktop provides single-plane 4-channel packed format
      if (image.planes.length == 1 &&
          (image.planes[0].bytesPerPixel ?? 1) >= 4) {
        final bytes = image.planes[0].bytes;
        final stride = image.planes[0].bytesPerRow;

        // Create a 4-channel Mat directly from camera bytes (handles stride)
        final matCols = stride ~/ 4;
        final bgraOrRgba =
            cv.Mat.fromList(height, matCols, cv.MatType.CV_8UC4, bytes);

        // Crop out stride padding if present
        final cropped = matCols != width
            ? bgraOrRgba.region(cv.Rect(0, 0, width, height))
            : bgraOrRgba;

        // Native SIMD-accelerated color conversion
        final colorCode = cv.COLOR_RGBA2BGR;
        cv.Mat mat = cv.cvtColor(cropped, colorCode);

        if (!identical(cropped, bgraOrRgba)) cropped.dispose();
        bgraOrRgba.dispose();

        final rotationFlag =
            _rotationFlagForFrame(width: width, height: height);
        if (rotationFlag != null) {
          final rotated = cv.rotate(mat, rotationFlag);
          mat.dispose();
          return rotated;
        }
        return mat;
      }

      // Mobile: YUV420 format
      final int yRowStride = image.planes[0].bytesPerRow;
      final int yPixelStride = image.planes[0].bytesPerPixel ?? 1;

      // Allocate BGR buffer for OpenCV (3 bytes per pixel)
      final bgrBytes = Uint8List(width * height * 3);

      void writePixel(int x, int y, int yp, int up, int vp) {
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);
        final int bgrIdx = (y * width + x) * 3;
        bgrBytes[bgrIdx] = b;
        bgrBytes[bgrIdx + 1] = g;
        bgrBytes[bgrIdx + 2] = r;
      }

      if (image.planes.length == 2) {
        // iOS NV12 format
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel ?? 2;

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final int uvIndex =
                uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
            final int index = y * yRowStride + x * yPixelStride;
            writePixel(
                x,
                y,
                image.planes[0].bytes[index],
                image.planes[1].bytes[uvIndex],
                image.planes[1].bytes[uvIndex + 1],);
          }
        }
      } else if (image.planes.length >= 3) {
        // Android I420 format
        final int uvRowStride = image.planes[1].bytesPerRow;
        final int uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

        for (int y = 0; y < height; y++) {
          for (int x = 0; x < width; x++) {
            final int uvIndex =
                uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
            final int index = y * yRowStride + x * yPixelStride;
            writePixel(x, y, image.planes[0].bytes[index],
                image.planes[1].bytes[uvIndex], image.planes[2].bytes[uvIndex],);
          }
        }
      } else {
        return null;
      }

      // Create cv.Mat from BGR bytes
      cv.Mat mat = cv.Mat.fromList(height, width, cv.MatType.CV_8UC3, bgrBytes);

      // Rotate image for portrait mode so face detector sees upright faces.
      final rotationFlag = _rotationFlagForFrame(width: width, height: height);
      if (rotationFlag != null) {
        final rotated = cv.rotate(mat, rotationFlag);
        mat.dispose();
        return rotated;
      }

      return mat;
    } catch (e) {
      return null;
    }
  }

  Future<void> flushBuffer() async {
    print("Flushing Buffer");
    print("${faceBuffer.length}");
    await ExperimentLogger.logFaceData(faceBuffer, widget.recordingId, widget.currentRepetition);
  }

  int? _rotationFlagForFrame({
    required int width,
    required int height,
  }) {
    final DeviceOrientation orientation = _effectiveDeviceOrientation(context);
    final bool isPortrait = orientation == DeviceOrientation.portraitUp ||
        orientation == DeviceOrientation.portraitDown;

    if (!isPortrait) return null;

    // If the incoming buffer is already portrait, don't rotate it.
    if (height >= width) return null;

    final int? sensor = _cameraController!.description.sensorOrientation;
    if (sensor == 90) {
      return cv.ROTATE_90_COUNTERCLOCKWISE;
    }
    if (sensor == 270) {
      return cv.ROTATE_90_CLOCKWISE;
    }

    return null;
  }
  
  DeviceOrientation _effectiveDeviceOrientation(BuildContext context) {
    final controller = _cameraController;
    if (controller != null) {
      return controller.value.deviceOrientation;
    }

    return MediaQuery.of(context).orientation == Orientation.portrait
        ? DeviceOrientation.portraitUp
        : DeviceOrientation.landscapeLeft;
  }

  void _startTimer() {
  countdown = 10;

  _timer?.cancel();
  _timer = Timer.periodic(Duration(seconds: 1), (timer) {
    if (countdown == 0) {
      timer.cancel();
      _stopVideoRecording();
    } else {
      setState(() {
        countdown--;
      });
    }
  });
}
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: 
          AppBar(
            title: 
                    Text(
                    widget.t(
                      "Repetition ${widget.currentRepetition} / ${widget.repetitions}",
                      "Wiederholung ${widget.currentRepetition} / ${widget.repetitions}",
                    ),),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.exit_to_app),
              onPressed: _onLeavePressed,
            ),

          ],
        ),
        body: Stack(
          children: [


            Padding(
              padding: const EdgeInsets.only(top: 250, bottom: 30),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    
                    FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done &&
                            _cameraController != null &&
                            _cameraController!.value.isInitialized) {

                          return AspectRatio(
                            aspectRatio: _cameraController!.value.aspectRatio,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(30),
                              child: CameraPreview(_cameraController!),
                            ),
                          );
                        }

                        return const CircularProgressIndicator();
                      },
                    ),
                    Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Text(
                            recording ? "$countdown" : "",
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    // Green frame overlay
                    Container(
                      width: 200,
                      height: 220,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.greenAccent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ],
                ),
              ),
            ),


            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Card(
                    elevation: 3,
                    color: Colors.grey.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            t("Examiner Instruction", "Anweisung für Untersucher"),
                            style: TextStyle(
                              color: Colors.deepOrange,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          buildInstructionText(widget.instruction)
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          

            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: isStarting
                      ? null
                      : (recording ? _stopVideoRecording : _startVideoRecording),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: recording ? Colors.red : Colors.green,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      recording ? Icons.stop : Icons.play_arrow,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            


            if (isStarting)
              Container(
                color: Colors.black.withOpacity(0.4),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.white),
                      SizedBox(height: 20),
                      Text(
                        "Sensoren werden gestartet...",
                        style: TextStyle(
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
    );
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
