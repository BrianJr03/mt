import 'dart:io';
import 'package:mt/Toast.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'location.dart';

void main() => runApp(const MyApp());

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final List<ActivityEvent> _events = [];
  late Stream<ActivityEvent> activityStream;
  ActivityEvent previousActivity = ActivityEvent.empty();
  ActivityRecognition activityRecognition = ActivityRecognition.instance;

  Toasted toasted = Toasted();
  Location location = Location();

  late String _timeStampStart;
  late String _timeStampEnd;

  Position _startLocation = _initPos();
  Position _endLocation = _initPos();

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

  static Position _initPos() {
    return Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0);
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

  bool isStarted(ActivityEvent currentActivity, Function(ActivityEvent) f) {
    // * Detects only the first event of its type
    // * as there can be consecutive events of the same type
    return f(currentActivity) && !f(previousActivity);
  }

  bool rideEnded(ActivityEvent currentActivity,
      {required Function(ActivityEvent) previous}) {
    // * Detects the end of a ride by determining
    // * when the user is on foot and the previous
    // * activity matches what is specfied
    return onFoot(currentActivity) && previous(previousActivity);
  }

  bool onFootStarted(ActivityEvent currentActivity) {
    return isStarted(currentActivity, onFoot);
  }

  bool onFootEnded(ActivityEvent currentActivity,
      {required Function(ActivityEvent) previous}) {
    return isStill(currentActivity) && previous(previousActivity);
  }

  bool bicycleStarted(ActivityEvent currentActivity) {
    return isStarted(currentActivity, onBicycle);
  }

  bool bicycleEnded(ActivityEvent currentActivity) {
    return rideEnded(currentActivity, previous: onBicycle);
  }

  bool vehicleStarted(ActivityEvent currentActivity) {
    return isStarted(currentActivity, inVehicle);
  }

  bool vehicleEnded(ActivityEvent currentActivity) {
    return rideEnded(currentActivity, previous: inVehicle);
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

  void onData(ActivityEvent currentActivity) async {
    if (vehicleStarted(currentActivity)) {
      setState(() async {
        recordActivity(currentActivity);
        _timeStampStart = currentActivity.timeStamp.toString();
        toasted.showToast("Start: $_timeStampStart");
        _rideStatus = 'Riding...';
        _startLocation = await location.determineCurrentPosition();
      });
    } else if (vehicleEnded(currentActivity)) {
      setState(() async {
        recordActivity(currentActivity);
        _timeStampEnd = currentActivity.timeStamp.toString();
        toasted.showToast("End: $_timeStampEnd");
        _rideStatus = 'Ride ended.';
        _endLocation = await location.determineCurrentPosition();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text(_rideStatus),
        ),
        body: Center(
            child: Column(
          children: [
            Row(children: [
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                    "Distanced Traveled: ${location.getMileageBetween(_startLocation, _endLocation)}",
                    style: const TextStyle(fontSize: 25)),
              )
            ]),
            ListView.builder(
                itemCount: _events.length,
                reverse: true,
                itemBuilder: (BuildContext context, int idx) {
                  final entry = _events[idx];
                  return ListTile(
                      leading: Text("${idx + 1}: " +
                          entry.timeStamp.toString().substring(0, 19)),
                      trailing: Text(entry.type.toString().split('.').last));
                }),
          ],
        )),
      ),
    );
  }
}
