import 'package:flutter/material.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_wearable/view_models/sensor_configuration_provider.dart';
import 'package:open_wearable/view_models/wearables_provider.dart';
import 'package:provider/provider.dart';

class SelectEarableView extends StatelessWidget {
  final Widget Function(
    OpenEarableV2 right,
    SensorConfigurationProvider rightConfig,
    OpenEarableV2 left,
    SensorConfigurationProvider leftConfig,
    Wearable ring,
    SensorConfigurationProvider ringConfig,
  ) startApp;

  const SelectEarableView({super.key, required this.startApp});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<WearablesProvider>();

    final wearables = prov.wearables.whereType<OpenEarableV2>().toList();
    final allWearables = prov.wearables;
    _logWearables(allWearables);
    return FutureBuilder<_EarablePair>(
      future: _resolveEarables(wearables, allWearables),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Error detecting earables")),
          );
        }

        final pair = snapshot.data!;
        final left = pair.left;
        final right = pair.right;
        final ring = pair.ring;

        final hasLeft = left != null;
        final hasRight = right != null;
        final hasRing = ring != null;
        final bothConnected = hasLeft && hasRight && hasRing;

        if (!bothConnected) {
          return Scaffold(
            appBar: AppBar(title: const Text("Select Earables")),
            body: Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning, color: Colors.red, size: 40),
                    const SizedBox(height: 10),
                    const Text(
                      "Missing devices",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(_buildMissingText(hasLeft, hasRight, hasRing)),
                    const SizedBox(height: 20),
                    const Text(
                      "Please connect both left and right earables.",
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // All CONNECTED → START APP
        return startApp(
          right,
          prov.getSensorConfigurationProvider(right),
          left,
          prov.getSensorConfigurationProvider(left),
          ring,
          prov.getSensorConfigurationProvider(ring),
        );
      },
    );
  }

  /// 🔍 Resolve left/right asynchronously
  Future<_EarablePair> _resolveEarables(
      List<OpenEarableV2> wearables, List<Wearable> allWearables) async {
    OpenEarableV2? left;
    OpenEarableV2? right;
    Wearable? ring;
    for (var wearable in allWearables) {
      if (wearable.name.contains("BCL")) {
        ring = wearable;
      }
    }
    for (var wearable in wearables) {
      final position = await wearable.position;

      if (position == DevicePosition.left) {
        left = wearable;
      } else if (position == DevicePosition.right) {
        right = wearable;
      }
    }

    return _EarablePair(left: left, right: right, ring: ring);
  }

  String _buildMissingText(bool hasLeft, bool hasRight, bool hasRing) {
    if (!hasLeft && !hasRight && !hasRing) {
      return "Left/Right earable and ring not connected.";
    } else if (!hasLeft) {
      return "Left earable is not connected.";
    } else if (!hasRight) {
      return "Right earable is not connected.";
    } else {
      return "Ring is not connected.";
    }
  }

  void _logWearables(List<Wearable> wearables) {
    for (var wearable in wearables) {
      print(wearable.name + " " + wearable.deviceId);
      for (Sensor sensor
          in wearable.requireCapability<SensorManager>().sensors) {
        print(
            "${sensor.sensorName} ${sensor.axisNames.reduce((a, b) => a + b)}");
      }
    }
  }
}

class _EarablePair {
  final OpenEarableV2? left;
  final OpenEarableV2? right;
  final Wearable? ring;

  _EarablePair({this.left, this.right, this.ring});
}
