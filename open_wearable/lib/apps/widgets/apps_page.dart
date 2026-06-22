import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:open_earable_flutter/open_earable_flutter.dart';
import 'package:open_wearable/apps/audio_response_measure/audio_response_measurement_view.dart';
import 'package:open_wearable/apps/heart_tracker/widgets/heart_tracker_page.dart';
import 'package:open_wearable/apps/posture_tracker/model/earable_attitude_tracker.dart';
import 'package:open_wearable/apps/posture_tracker/view/posture_tracker_view.dart';
import 'package:open_wearable/apps/stroke_tracker/view/app.dart';
import 'package:open_wearable/apps/widgets/select_earable_view.dart';
import 'package:open_wearable/apps/widgets/app_tile.dart';
import 'package:open_wearable/apps/widgets/select_two_earable_view.dart';

class AppInfo {
  final String logoPath;
  final String title;
  final String description;
  final Widget widget;

  AppInfo({
    required this.logoPath,
    required this.title,
    required this.description,
    required this.widget,
  });
}

List<AppInfo> _apps = [
  /*
  AppInfo(
    logoPath: "lib/apps/posture_tracker/assets/logo.png",
    title: "Posture Tracker",
    description: "Get feedback on bad posture",
    widget: SelectEarableView(startApp: (wearable, sensorConfigProvider) {
      return PostureTrackerView(
        EarableAttitudeTracker(
          wearable.requireCapability<SensorManager>(),
          sensorConfigProvider,
          wearable.name.endsWith("L"),
        ),
      );
    },),
  ),
  AppInfo(
    logoPath: "lib/apps/stroke_tracker/assets/logo.png",
    title: "Audio Response",
    description: "Measure and store audio responses",
    widget: SelectTwoEarableView(
      startApp: (wearable, _) {
        
        return AudioResponseMeasurementView(manager: wearable.requireCapability<AudioResponseManager>());
      },
    ),
  ),*/
  AppInfo(
    logoPath: "lib/apps/stroke_tracker/assets/logo.png",
    title: "Stroke Data Collection",
    description: "Session-based data collection with global sensor configs",
    widget: StrokeTrackerView(),
  ),
];

class AppsPage extends StatelessWidget {
  const AppsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: PlatformText("Apps"),
        trailingActions: [
          PlatformIconButton(
            icon: Icon(context.platformIcons.bluetooth),
            onPressed: () {
              context.push('/connect-devices');
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: ListView.builder(
          itemCount: _apps.length,
          itemBuilder: (context, index) {
            return AppTile(app: _apps[index]);
          },
        ),
      ),
    );
  }
}
