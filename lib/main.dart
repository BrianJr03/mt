import 'dart:io';
import 'package:intl/intl.dart';
import 'package:mt/toasted.dart';
import 'package:mt/phone_activity.dart';
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
  final toasted = Toasted();

  final pA = PhoneActivity(
      events: List.empty(),
      activityStream: const Stream.empty(),
      previousActivity: ActivityEvent.empty(),
      activityRecognition: ActivityRecognition.instance);

  late String _timeStampStart;
  late String _timeStampEnd;

  Duration _timeTraveled = Duration.zero;

  Position _startLocation = _initPos();
  Position _endLocation = _initPos();

  String _rideStatus = 'Detecting Activity...';

  late Position currentPosition = _initPos();

  double _mileage = 0.0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    await _getCurrentLocation();
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.request().isGranted) {
        pA.startTracking(onData);
      }
    } else {
      pA.startTracking(onData);
    }
  }

  static Position _initPos() {
    return const Position(
        longitude: 0,
        latitude: 0,
        timestamp: null,
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

  void onData(ActivityEvent currentActivity) async {
    if (pA.vehicleStarted(currentActivity)) {
    await _getCurrentLocation();
    setState(() {
      pA.recordActivity(currentActivity);
      _timeStampStart = currentActivity.timeStamp.toString();
      _rideStatus = 'Riding...';
      _startLocation = currentPosition;
    });
    } else if (pA.vehicleEnded(currentActivity)) {
    await _getCurrentLocation();
    setState(() {
      pA.recordActivity(currentActivity);
      _timeStampEnd = currentActivity.timeStamp.toString();
      _rideStatus = 'Ride ended.';
      _endLocation = currentPosition;
      updateMileage(_startLocation, _endLocation);
    });
    }
  }

  void updateMileage(Position start, Position end) {
    double meters = Geolocator.distanceBetween(
        start.latitude, start.longitude, end.latitude, end.longitude);
    _mileage = double.parse((meters * 0.000621371192).toStringAsFixed(2));
  }

  void updateTravelTime() {
    var format = DateFormat("HH:mm:ss");
    var startTime = format.parse(_timeStampStart.substring(11, 19));
    var endTime = format.parse(_timeStampEnd.substring(11, 19));
    _timeTraveled = endTime.difference(startTime);
  }

  String formatTimeStamp(String timeStamp) {
    var format = DateFormat.yMd().add_jm();
    return format.parse(timeStamp).toString();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        home: Scaffold(
      appBar: AppBar(title: Text(_rideStatus)),
      body: Center(
        child: ListView.builder(
            itemCount: pA.events.length,
            reverse: false,
            itemBuilder: (BuildContext context, int idx) {
              final entry = pA.events[idx];
              return Card(
                  child: InkWell(
                splashColor: Colors.blue.withAlpha(30),
                onLongPress: () {},
                child: Column(
                  children: [
                    ListTile(
                        leading: Text("${idx + 1}"),
                        title: Text(entry.timeStamp
                                .toString()
                                .substring(0, 10) +
                            " @ ${entry.timeStamp.toString().substring(11, 16)}"),
                        subtitle: Text(entry.type.toString().substring(13)),
                        trailing: Text("Mileage $_mileage mi"))
                  ],
                ),
              ));
            }),
      ),
    ));
  }
}
