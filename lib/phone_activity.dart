import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';

class PhoneActivity {
  PhoneActivity(
      {required List<ActivityEvent> events,
      required Stream<ActivityEvent> activityStream,
      required ActivityEvent previousActivity,
      required ActivityRecognition activityRecognition}) {
    this.events;
    this.activityStream;
    this.previousActivity;
    this.activityRecognition;
  }

  List<ActivityEvent> events = [];
  Stream<ActivityEvent> activityStream = const Stream.empty();
  ActivityEvent previousActivity = ActivityEvent.empty();
  ActivityRecognition activityRecognition = ActivityRecognition.instance;

  bool isStill(ActivityEvent ac) {
    return ac.type == ActivityType.STILL;
  }

  bool onBicycle(ActivityEvent ac) {
    return ac.type == ActivityType.ON_BICYCLE;
  }

  bool onFoot(ActivityEvent ac) {
    return ac.type == ActivityType.ON_FOOT;
  }

  bool inVehicle(ActivityEvent ac) {
    return ac.type == ActivityType.IN_VEHICLE;
  }

  void startTracking(Function(ActivityEvent)? onData) {
    activityStream =
        activityRecognition.startStream(runForegroundService: true);
    activityStream.listen(onData);
  }

  void recordActivity(ActivityEvent currentActivity) {
    events.add(currentActivity);
    previousActivity = currentActivity;
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
}
