import 'package:fit_tool/src/profile/messages/device_settings_message.dart';
import 'package:fit_tool/src/profile/messages/record_message.dart';
import 'package:fit_tool/src/profile/messages/hrv_message.dart';
import 'package:fit_tool/src/profile/messages/hr_message.dart';
import 'package:fit_tool/src/profile/messages/monitoring_info_message.dart';
import 'package:fit_tool/src/profile/messages/gps_metadata_message.dart';
import 'package:fit_tool/src/profile/messages/segment_point_message.dart';
import 'package:fit_tool/src/profile/messages/session_message.dart';
import 'package:fit_tool/src/profile/messages/lap_message.dart';
import 'package:fit_tool/src/profile/messages/segment_lap_message.dart';
import 'package:fit_tool/src/profile/messages/aviation_attitude_message.dart';
import 'package:fit_tool/src/profile/messages/three_d_sensor_calibration_message.dart';
import 'package:test/test.dart';

/// Tests that List<double>? getters properly cast field.getValues() to List<double>.
/// This verifies the fix for the List<dynamic> to List<double> cast bug.
void main() {
  group('List<double> cast fix', () {
    test('DeviceSettingsMessage.timeZoneOffset returns List<double>', () {
      final message = DeviceSettingsMessage();
      message.timeZoneOffset = [1.0, 2.0, 3.0];

      final result = message.timeZoneOffset;

      expect(result, isA<List<double>>());
      expect(result, equals([1.0, 2.0, 3.0]));
      // Verify we can use it as List<double> without runtime errors
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(6.0));
    });

    test('RecordMessage.speed1s returns List<double>', () {
      final message = RecordMessage();
      message.speed1s = [1.5, 2.5, 3.5];

      final result = message.speed1s;

      expect(result, isA<List<double>>());
      expect(result, equals([1.5, 2.5, 3.5]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(7.5));
    });

    test('HrvMessage.time returns List<double>', () {
      final message = HrvMessage();
      message.time = [0.5, 0.6, 0.7];

      final result = message.time;

      expect(result, isA<List<double>>());
      expect(result, equals([0.5, 0.6, 0.7]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(1.8, 0.001));
    });

    test('HrMessage.eventTimestamp returns List<double>', () {
      final message = HrMessage();
      message.eventTimestamp = [100.0, 200.0, 300.0];

      final result = message.eventTimestamp;

      expect(result, isA<List<double>>());
      expect(result, equals([100.0, 200.0, 300.0]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(600.0));
    });

    test('MonitoringInfoMessage.cyclesToDistance returns List<double>', () {
      final message = MonitoringInfoMessage();
      message.cyclesToDistance = [0.001, 0.002, 0.003];

      final result = message.cyclesToDistance;

      expect(result, isA<List<double>>());
      expect(result, equals([0.001, 0.002, 0.003]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(0.006, 0.0001));
    });

    test('GpsMetadataMessage.velocity returns List<double>', () {
      final message = GpsMetadataMessage();
      message.velocity = [5.0, 10.0, 15.0];

      final result = message.velocity;

      expect(result, isA<List<double>>());
      expect(result, equals([5.0, 10.0, 15.0]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(30.0));
    });

    test('SegmentPointMessage.leaderTime returns List<double>', () {
      final message = SegmentPointMessage();
      message.leaderTime = [120.5, 125.3, 130.1];

      final result = message.leaderTime;

      expect(result, isA<List<double>>());
      expect(result, equals([120.5, 125.3, 130.1]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(375.9, 0.001));
    });

    test('SessionMessage.timeInHrZone returns List<double>', () {
      final message = SessionMessage();
      message.timeInHrZone = [60.0, 120.0, 180.0, 240.0, 300.0];

      final result = message.timeInHrZone;

      expect(result, isA<List<double>>());
      expect(result, equals([60.0, 120.0, 180.0, 240.0, 300.0]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(900.0));
    });

    test('LapMessage.timeInHrZone returns List<double>', () {
      final message = LapMessage();
      message.timeInHrZone = [30.0, 60.0, 90.0];

      final result = message.timeInHrZone;

      expect(result, isA<List<double>>());
      expect(result, equals([30.0, 60.0, 90.0]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(180.0));
    });

    test('SegmentLapMessage.timeInHrZone returns List<double>', () {
      final message = SegmentLapMessage();
      message.timeInHrZone = [45.0, 90.0, 135.0];

      final result = message.timeInHrZone;

      expect(result, isA<List<double>>());
      expect(result, equals([45.0, 90.0, 135.0]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(270.0));
    });

    test('AviationAttitudeMessage.pitch returns List<double>', () {
      final message = AviationAttitudeMessage();
      message.pitch = [0.1, 0.2, 0.3];

      final result = message.pitch;

      expect(result, isA<List<double>>());
      expect(result!.length, equals(3));
      // Values may differ slightly due to field scale factor
      expect(result[0], closeTo(0.1, 0.001));
      expect(result[1], closeTo(0.2, 0.001));
      expect(result[2], closeTo(0.3, 0.001));
      final sum = result.fold<double>(0, (a, b) => a + b);
      expect(sum, closeTo(0.6, 0.01));
    });

    test('ThreeDSensorCalibrationMessage.orientationMatrix returns List<double>', () {
      final message = ThreeDSensorCalibrationMessage();
      message.orientationMatrix = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0];

      final result = message.orientationMatrix;

      expect(result, isA<List<double>>());
      expect(result, equals([1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]));
      final sum = result!.fold<double>(0, (a, b) => a + b);
      expect(sum, equals(3.0));
    });
  });
}
