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

  String _rideStatus = 'Detecting Activity...';

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

  bool isStarted(ActivityEvent currentActivity, Function(ActivityEvent) f) {
    // * Detects only the first event of its type in _events
    // * as there can be consecutive events of the same type
    return f(currentActivity) && !f(previousActivity);
  }

  bool rideEnded(ActivityEvent currentActivity) {
    // * Detects the end of a ride by determining
    // * if the user is on foot
    return onFoot(currentActivity);
  }

  bool bicycleStarted(ActivityEvent currentActivity) {
    return isStarted(currentActivity, onBicycle);
  }

  bool vehicleStarted(ActivityEvent currentActivity) {
    return isStarted(currentActivity, inVehicle);
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
    if (bicycleStarted(currentActivity)) {
      setState(() {
        recordActivity(currentActivity);
        _timeStampStart = currentActivity.timeStamp.toString();
        showToast("Start: $_timeStampStart");
        _rideStatus = 'Riding...';
      });
    } else if (rideEnded(currentActivity)) {
      setState(() {
        recordActivity(currentActivity);
        _timeStampEnd = currentActivity.timeStamp.toString();
        showToast("End: $_timeStampEnd");
        _rideStatus = 'Ride ended.';
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
          title: Text(_rideStatus),
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
