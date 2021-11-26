import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';

class Location {
  String timeStampStart = "";
  String timeStampEnd = "";

  Duration timeTraveled = Duration.zero;

  Position startPosition = initPos();
  Position endPosition = initPos();

  Position currentPosition = initPos();

  double mileage = 0.0;

  Location(
      {required String timeStampStart,
      required String timeStampEnd,
      required Duration timeTraveled,
      required Position startPosition,
      required Position endPosition}) {
    this.timeStampStart;
    this.timeStampEnd;
    this.timeTraveled;
    this.startPosition;
    this.endPosition;
  }

  static Position initPos() {
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

  getCurrentPositon() {
    Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.best,
            forceAndroidLocationManager: true)
        .then((Position position) {
      setPosition(position);
    });
  }

  void setPosition(Position position) {
    currentPosition = position;
  }

  String formatTimeStamp(String timeStamp) {
    var format = DateFormat.yMd().add_jm();
    return format.parse(timeStamp).toString();
  }

  double getMetersBetween(Position start, Position end) {
    return Geolocator.distanceBetween(
        start.latitude, start.longitude, end.latitude, end.longitude);
  }

  double metersToMiles(double meters) {
    return double.parse((meters * 0.000621371192).toStringAsFixed(2));
  }

  void setMileage(Position start, Position end) {
    mileage = metersToMiles(getMetersBetween(start, end));
  }

  void setTravelTime() {
    var format = DateFormat("HH:mm:ss");
    var startTime = format.parse(timeStampStart.substring(11, 19));
    var endTime = format.parse(timeStampEnd.substring(11, 19));
    timeTraveled = endTime.difference(startTime);
  }
}
