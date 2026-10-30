import 'stop_model.dart';

class RouteModel {
  final int id;
  final String gtfsRouteId;
  final String routeNumber;
  final String routeName;
  final String source;
  final String destination;
  final String direction;
  final String agencyId;
  final String transportType;
  final int stopsCount;
  final String fareInfo;
  final List<StopModel> stops;

  RouteModel({
    required this.id,
    required this.gtfsRouteId,
    required this.routeNumber,
    required this.routeName,
    required this.source,
    required this.destination,
    required this.direction,
    required this.agencyId,
    required this.transportType,
    required this.stopsCount,
    required this.fareInfo,
    this.stops = const [],
  });

  factory RouteModel.fromJson(Map<String, dynamic> json) {
    return RouteModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      gtfsRouteId: json['gtfsRouteId']?.toString() ?? '',
      routeNumber: json['routeNumber']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
      agencyId: json['agencyId']?.toString() ?? 'TMT',
      transportType: json['transportType']?.toString() ?? 'BUS',
      stopsCount: (json['stopsCount'] as num?)?.toInt() ?? 0,
      fareInfo: json['fareInfo']?.toString() ?? 'Fare information unavailable',
      stops: (json['stops'] as List<dynamic>?)
              ?.map((s) => StopModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gtfsRouteId': gtfsRouteId,
      'routeNumber': routeNumber,
      'routeName': routeName,
      'source': source,
      'destination': destination,
      'direction': direction,
      'agencyId': agencyId,
      'transportType': transportType,
      'stopsCount': stopsCount,
      'fareInfo': fareInfo,
      'stops': stops.map((s) => s.toJson()).toList(),
    };
  }

  RouteModel copyWithStops(List<StopModel> newStops) {
    return RouteModel(
      id: id,
      gtfsRouteId: gtfsRouteId,
      routeNumber: routeNumber,
      routeName: routeName,
      source: source,
      destination: destination,
      direction: direction,
      agencyId: agencyId,
      transportType: transportType,
      stopsCount: newStops.isNotEmpty ? newStops.length : stopsCount,
      fareInfo: fareInfo,
      stops: newStops,
    );
  }
}
