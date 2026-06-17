import 'package:flutter/material.dart';
import 'package:open_wearable/apps/stroke_tracker/controller/logger.dart';
import 'dart:io';
import 'package:share_plus/share_plus.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Downloads")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "Downloads Ready!",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              const Text(
                "Your recordings and logs are ready. Export them below.",
                style: TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 50),

              // ================= LOGS =================
              ElevatedButton.icon(
                onPressed: () => _exportAll("logs"),
                icon: const Icon(Icons.description),
                label: const Text("Export Logs"),
              ),

              const SizedBox(height: 20),

              // ================= FACEMESH =================
              ElevatedButton.icon(
                onPressed: () => _exportAll("mesh"),
                icon: const Icon(Icons.face),
                label: const Text("Export FaceMesh Data"),
              ),

              const SizedBox(height: 20),

              // ================= AUDIO =================
              ElevatedButton.icon(
                onPressed: () => _exportAll("audio"),
                icon: const Icon(Icons.mic),
                label: const Text("Export Audio (WAV)"),
              ),

              const Spacer(),

              ElevatedButton(
                onPressed: _deleteLogs,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text("Delete Logs"),
              ),
            ],
          ),
        ),
      ),
    );
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

  // ================= DELETE =================
  Future<void> _deleteLogs() async {
    await ExperimentLogger.deleteAllLogFiles();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All logs deleted")),
      );
    }
  }
}
