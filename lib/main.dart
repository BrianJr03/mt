import 'dart:io';
import 'package:mt/toasted.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';

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

  late String _timeStampStart;
  late String _timeStampEnd;

  Position _startLocation = _initPos();
  Position _endLocation = _initPos();

  String _rideStatus = 'Detecting Activity...';

  late Position currentPosition = _initPos();

  double _mileage = 0.0;
  final List<double> _mileageList = [];

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await _getCurrentLocation();
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

  _getCurrentLocation() {
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setState(() {
        currentPosition = position;
      });
    });
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
        await _getCurrentLocation();
        _startLocation = currentPosition;
      });
    } else if (vehicleEnded(currentActivity)) {
      setState(() async {
        recordActivity(currentActivity);
        _timeStampEnd = currentActivity.timeStamp.toString();
        toasted.showToast("End: $_timeStampEnd");
        _rideStatus = 'Ride ended.';
        await _getCurrentLocation();
        _endLocation = currentPosition;
        updateMileage(_startLocation, _endLocation);
      });
    }
  }

  void updateMileage(Position start, Position end) {
    double meters = Geolocator.distanceBetween(
        start.latitude, start.longitude, end.latitude, end.longitude);
    _mileage = double.parse((meters * 0.000621371192).toStringAsFixed(2));
    _mileageList.add(_mileage);
    _mileage = 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: Text(_rideStatus)),
      body: Center(
        child: ListView.builder(
            itemCount: _events.length,
            reverse: true,
            itemBuilder: (BuildContext context, int idx) {
              final entry = _events[idx];
              final mileage = _mileageList[idx];
              return ListTile(
                  leading: Text("${idx + 1}: " +
                      entry.timeStamp.toString().substring(0, 19)),
                  trailing:
                      Text("\nMileage \n$mileage mi"));
            }),
      ),
    ));
  }
}
