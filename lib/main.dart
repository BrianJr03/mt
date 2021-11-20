import 'dart:io';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Stream<ActivityEvent> activityStream;
  ActivityEvent previousActivity = ActivityEvent.empty();
  final List<ActivityEvent> _events = [];
  ActivityRecognition activityRecognition = ActivityRecognition.instance;

  String _timeStampStart = '';
  String _timeStampEnd = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.request().isGranted) {
        _startTracking();
      }
    } else {
      _startTracking();
    }
  }

  bool inVehicle(ActivityEvent ac) {
    return ac.type == ActivityType.IN_VEHICLE;
  }

  bool onFoot(ActivityEvent ac) {
    return ac.type == ActivityType.ON_FOOT;
  }

  bool onBicycle(ActivityEvent ac) {
    return ac.type == ActivityType.ON_BICYCLE;
  }

  bool isStill(ActivityEvent ac) {
    return ac.type == ActivityType.STILL;
  }

  bool bicycleStarted(ActivityEvent currentActivity) {
    return onBicycle(currentActivity) && !onBicycle(previousActivity);
  }

  bool bicycleEnded(ActivityEvent currentActivity) {
    return !bicycleStarted(currentActivity);
  }

  bool vehicleStarted(ActivityEvent currentActivity) {
    return inVehicle(currentActivity) && !inVehicle(previousActivity);
  }

  bool vehicleEnded(ActivityEvent currentActivity) {
    return !vehicleStarted(currentActivity);
  }

  void _startTracking() {
    activityStream =
        activityRecognition.startStream(runForegroundService: true);
    activityStream.listen(onData);
  }

  void recordActivity(ActivityEvent currentActivity) {
    _events.add(currentActivity);
    previousActivity = currentActivity;
  }

  void onData(ActivityEvent currentActivity) {
    if (vehicleStarted(currentActivity) || bicycleStarted(currentActivity)) {
      setState(() {
        recordActivity(currentActivity);
        _timeStampStart = currentActivity.timeStamp.toString();
        showToast("Start: $_timeStampStart");
      });
    } else if (vehicleEnded(currentActivity) || bicycleEnded(currentActivity) &&
        (isStill(currentActivity) || onFoot(currentActivity))) {
      setState(() {
        recordActivity(currentActivity);
        _timeStampEnd = currentActivity.timeStamp.toString();
        showToast("End: $_timeStampEnd");
      });
    }
  }

  static void showToast(Object msg) {
    Fluttertoast.showToast(
        msg: msg.toString(),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Activity Recognition Demo'),
        ),
        body: Center(
            child: ListView.builder(
                itemCount: _events.length,
                reverse: true,
                itemBuilder: (BuildContext context, int idx) {
                  final entry = _events[idx];
                  return ListTile(
                      leading: Text("${idx + 1}: " +
                          entry.timeStamp.toString().substring(0, 19)),
                      trailing: Text(entry.type.toString().split('.').last));
                })),
      ),
    );
  }
}
