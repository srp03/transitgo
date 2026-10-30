import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_flutter/data/models/booking_model.dart';
import 'package:mobile_flutter/data/models/bus_model.dart';
import 'package:mobile_flutter/data/models/route_model.dart';
import 'package:mobile_flutter/data/models/stop_model.dart';

void main() {
  group('TransitGo Data Models Tests', () {
    test('RouteModel parses GTFS backend JSON correctly', () {
      final json = {
        'id': 101,
        'gtfsRouteId': 'TMT_54',
        'routeNumber': '54',
        'routeName': 'Thane Station (W) to Anand Nagar',
        'source': 'Thane Station (W)',
        'destination': 'Anand Nagar',
        'direction': 'UP',
        'agencyId': 'TMT',
        'transportType': 'BUS',
        'stopsCount': 24,
        'fareInfo': 'Fare information unavailable',
        'stops': [
          {
            'id': 1,
            'gtfsStopId': 'TMT_101',
            'name': 'Thane Station (W)',
            'latitude': 19.1860,
            'longitude': 72.9759,
            'sequence': 1
          },
          {
            'id': 2,
            'gtfsStopId': 'TMT_102',
            'name': 'Anand Nagar',
            'latitude': 19.2612,
            'longitude': 72.9641,
            'sequence': 24
          }
        ]
      };

      final route = RouteModel.fromJson(json);
      expect(route.id, 101);
      expect(route.routeNumber, '54');
      expect(route.direction, 'UP');
      expect(route.stops.length, 2);
      expect(route.stops.first.name, 'Thane Station (W)');
      expect(route.stops.last.sequence, 24);
    });

    test('StopModel parses geolocation coordinates correctly', () {
      final json = {
        'id': 55,
        'gtfsStopId': 'TMT_55',
        'name': 'Cadbury Junction',
        'latitude': 19.2014,
        'longitude': 72.9734,
        'distanceKm': 1.8
      };

      final stop = StopModel.fromJson(json);
      expect(stop.id, 55);
      expect(stop.name, 'Cadbury Junction');
      expect(stop.latitude, 19.2014);
      expect(stop.longitude, 72.9734);
      expect(stop.distanceKm, 1.8);
    });

    test('BusLocationModel flags simulated mode correctly', () {
      final json = {
        'busId': 10,
        'vehicleNumber': 'MH-04-TM-1010',
        'routeId': 101,
        'routeNumber': '54',
        'source': 'Thane Station',
        'destination': 'Ghodbunder',
        'latitude': 19.1880,
        'longitude': 72.9760,
        'speed': 28.5,
        'heading': 45.0,
        'timestamp': 1700000000000,
        'currentStopName': 'Thane Station',
        'nextStopName': 'Chendani Koliwada',
        'etaMinutes': 4,
        'status': 'On time',
        'isMock': true,
        'dataLabel': 'Demo / Simulated'
      };

      final bus = BusLocationModel.fromJson(json);
      expect(bus.busId, 10);
      expect(bus.isMock, isTrue);
      expect(bus.dataLabel, 'Demo / Simulated');
      expect(bus.etaMinutes, 4);
    });

    test('BookingModel serialization and QR payload creation', () {
      final json = {
        'id': 1,
        'bookingReference': 'TG20261013ABCD',
        'routeId': 101,
        'routeNumber': '54',
        'routeName': 'Thane Station → Anand Nagar',
        'sourceStop': 'Thane Station',
        'destinationStop': 'Anand Nagar',
        'departureTime': '10:30 AM',
        'passengerCount': 2,
        'fare': 30.0,
        'status': 'CONFIRMED',
        'paymentMethod': 'UPI_DEMO',
        'paymentStatus': 'PAID_DEMO',
        'upiId': 'tester@okhdfcbank',
        'bookedAt': 1700000000000,
        'qrPayload': 'TRANSITGO|TMT|REF:TG20261013ABCD|PAX:2',
        'isDemo': true,
        'notice': 'Demo ticket — Not an official TMT paper ticket'
      };

      final booking = BookingModel.fromJson(json);
      expect(booking.bookingReference, 'TG20261013ABCD');
      expect(booking.passengerCount, 2);
      expect(booking.fare, 30.0);
      expect(booking.isDemo, isTrue);
      expect(booking.qrPayload.contains('TG20261013ABCD'), isTrue);
    });
  });
}
