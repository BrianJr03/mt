import 'package:test/test.dart';
import 'package:mt/location.dart';

void main() {
  final location = Location(
      timeStampStart: "",
      timeStampEnd: "",
      timeTraveled: Duration.zero,
      startPosition: Location.initPos(),
      endPosition: Location.initPos());

  group("User Location Testing", () {
    test('Meters to Miles Test 1', () {
      final miles = location.metersToMiles(12345);
      expect(miles, 7.67);
    });

    test('Meters to Miles Test 2', () {
      final miles = location.metersToMiles(032398);
      expect(miles, 20.13);
    });
  });
}
