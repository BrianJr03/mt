import 'dart:io';
import 'package:mt/location.dart';
import 'package:mt/toasted.dart';
import 'package:mt/phone_activity.dart';
import 'package:flutter/material.dart';
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

  final location = Location(
      timeStampStart: "",
      timeStampEnd: "",
      timeTraveled: Duration.zero,
      startPosition: Location.initPos(),
      endPosition: Location.initPos());

  final pA = PhoneActivity(
      events: [],
      activityStream: const Stream.empty(),
      previousActivity: ActivityEvent.empty(),
      activityRecognition: ActivityRecognition.instance);

  String _rideStatus = 'Waiting for Ride to Start...';

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() async {
    if (Platform.isAndroid) {
      if (await Permission.activityRecognition.request().isGranted) {
        pA.startTracking(onData);
      }
    } else {
      pA.startTracking(onData);
    }
  }

  void startRide(ActivityEvent currentActivity) async {
    await location.getCurrentPositon();
    setState(() {
      pA.recordActivity(currentActivity);
      location.timeStampStart = currentActivity.timeStamp.toString();
      _rideStatus = 'Riding...';
      location.startPosition = location.currentPosition;
    });
  }

  void endRide(ActivityEvent currentActivity) async {
    await location.getCurrentPositon();
    setState(() {
      pA.recordActivity(currentActivity);
      location.timeStampEnd = currentActivity.timeStamp.toString();
      _rideStatus = 'Ride ended.';
      location.endPosition = location.currentPosition;
      location.setMileage(location.startPosition, location.endPosition);
    });
  }

  void onData(ActivityEvent currentActivity) async {
    if (pA.vehicleStartDetected(currentActivity)) {
      startRide(currentActivity);
    } else if (pA.vehicleEndDetected(currentActivity)) {
      endRide(currentActivity);
    }
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
                            " @ ${entry.timeStamp.toLocal().toString().substring(11, 16)}"),
                        subtitle: Text(entry.type.toString().substring(13)),
                        trailing: Text("Mileage ${location.metersToMiles(location.mileage)} mi"))
                  ],
                ),
              ));
            }),
      ),
    ));
  }
}
