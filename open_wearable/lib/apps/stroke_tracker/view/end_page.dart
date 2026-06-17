import 'package:flutter/material.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class SummaryScreen extends StatefulWidget {
  final VoidCallback onLeaveStudy;
  final String Function(String en, String de) t;
  const SummaryScreen({super.key, required this.onLeaveStudy, required this.t});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: false,
        child: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    widget.t("Study Completed!", "Studie abgeschlossen!"),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    widget.t(
                        "Your recordings and logs are ready. Export them below.",
                        "Ihr Aufnahmen sind bereit. Sie können diese nun exportieren."),
                    style: TextStyle(fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 50),
                  ElevatedButton.icon(
                    onPressed: () => _showExportDialog(type: "logs"),
                    icon: const Icon(Icons.description),
                    label: const Text("Export Logs"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showExportDialog(type: "facemesh"),
                    icon: const Icon(Icons.face),
                    label: const Text("Export FaceMesh Data"),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showExportDialog(type: "audio"),
                    icon: const Icon(Icons.mic),
                    label: Text(widget.t(
                        "Export Audio (WAV)", "Audio exportieren (WAV)")),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsetsGeometry.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: widget.onLeaveStudy,
                      child: const Text("Exit"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  Future<void> _showExportDialog({required String type}) async {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(widget.t("Export Data", "Daten Exportieren")),
          content: Text(widget.t("Choose what you want to export",
              "Wählen Sie die zu exportierenden Daten")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _exportSingle(type);
              },
              child: Text(widget.t("Current File", "Daten dieser Studie")),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _exportAll(type);
              },
              child: Text(widget.t("All Files", "Alle Daten")),
            ),
          ],
        );
      },
    );
  }

  Future<void> _exportSingle(String type) async {
    List<File> files;

    if (type == "logs") {
      files = await ExperimentLogger.getAllLogFiles();
    } else if (type == "audio") {
      files = await ExperimentLogger.getAllAudioFiles();
    } else {
      files = await ExperimentLogger.getAllFaceData();
    }

    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No files found")),
        );
      }

      final file = files.last;

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
        ),
      );
    }
  }

  Future<void> _exportAll(String type) async {
    List<File> files;

    if (type == "logs") {
      files = await ExperimentLogger.getAllLogFiles();
    } else if (type == "audio") {
      files = await ExperimentLogger.getAllAudioFiles();
    } else {
      files = await ExperimentLogger.getAllFaceData();
    }
    if (files.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No files found")),
        );
        return;
      }
    }

    final xFiles = files.map((f) => XFile(f.path)).toList();

    await SharePlus.instance.share(
      ShareParams(
        files: xFiles,
      ),
    );
  }
}
