import 'package:geolocator/geolocator.dart';
import 'package:mt/toast.dart';

class Location {
  Future<Position> determineCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;
    Toasted toasted = Toasted();

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      String error = 'Location services are disabled.';
      toasted.showToast(error);
      return Future.error(error);
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        String error = 'Location permissions are denied';
        toasted.showToast(error);
        return Future.error(error);
      }
    }

    if (permission == LocationPermission.deniedForever) {
      String error =
          'Location permissions are permanently denied, we cannot request permissions.';
      toasted.showToast(error);
      return Future.error(error);
    }
    return await Geolocator.getCurrentPosition();
  }

  double getMileageBetween(Position start, Position end) {
    double meters = Geolocator.distanceBetween(
        start.latitude, start.longitude, end.latitude, end.longitude);
    return meters * 0.000621371192;
  }
}
