class StopModel {
  final int id;
  final String gtfsStopId;
  final String name;
  final double latitude;
  final double longitude;
  final int? sequence;
  final String? arrivalTime;
  final String? departureTime;
  final double? distanceKm;

  StopModel({
    required this.id,
    required this.gtfsStopId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.sequence,
    this.arrivalTime,
    this.departureTime,
    this.distanceKm,
  });

  factory StopModel.fromJson(Map<String, dynamic> json) {
    return StopModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      gtfsStopId: json['gtfsStopId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Stop',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      sequence: (json['sequence'] as num?)?.toInt(),
      arrivalTime: json['arrivalTime']?.toString(),
      departureTime: json['departureTime']?.toString(),
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'gtfsStopId': gtfsStopId,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'sequence': sequence,
      'arrivalTime': arrivalTime,
      'departureTime': departureTime,
      'distanceKm': distanceKm,
    };
  }
}

class RouteSummaryModel {
  final int id;
  final String gtfsRouteId;
  final String routeNumber;
  final String routeName;
  final String source;
  final String destination;
  final String direction;

  RouteSummaryModel({
    required this.id,
    required this.gtfsRouteId,
    required this.routeNumber,
    required this.routeName,
    required this.source,
    required this.destination,
    required this.direction,
  });

  factory RouteSummaryModel.fromJson(Map<String, dynamic> json) {
    return RouteSummaryModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      gtfsRouteId: json['gtfsRouteId']?.toString() ?? '',
      routeNumber: json['routeNumber']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      direction: json['direction']?.toString() ?? '',
    );
  }
}

class StopWithRoutesModel {
  final int id;
  final String gtfsStopId;
  final String name;
  final double latitude;
  final double longitude;
  final double? distanceKm;
  final List<RouteSummaryModel> routes;

  StopWithRoutesModel({
    required this.id,
    required this.gtfsStopId,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.distanceKm,
    required this.routes,
  });

  factory StopWithRoutesModel.fromJson(Map<String, dynamic> json) {
    return StopWithRoutesModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      gtfsStopId: json['gtfsStopId']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Stop',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      distanceKm: (json['distanceKm'] as num?)?.toDouble(),
      routes: (json['routes'] as List<dynamic>?)
              ?.map((r) => RouteSummaryModel.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
