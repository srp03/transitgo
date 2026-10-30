class BusLocationModel {
  final int busId;
  final String vehicleNumber;
  final int routeId;
  final String routeNumber;
  final String source;
  final String destination;
  final String transportType;
  final double latitude;
  final double longitude;
  final double speed;
  final double heading;
  final int timestamp;
  final String currentStopName;
  final String nextStopName;
  final int etaMinutes;
  final String status;
  final String vehicleType;
  final int capacity;
  final String occupancyStatus;
  final bool isMock;
  final String dataLabel;

  BusLocationModel({
    required this.busId,
    required this.vehicleNumber,
    required this.routeId,
    required this.routeNumber,
    required this.source,
    required this.destination,
    required this.transportType,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.heading,
    required this.timestamp,
    required this.currentStopName,
    required this.nextStopName,
    required this.etaMinutes,
    required this.status,
    required this.vehicleType,
    required this.capacity,
    required this.occupancyStatus,
    required this.isMock,
    required this.dataLabel,
  });

  factory BusLocationModel.fromJson(Map<String, dynamic> json) {
    return BusLocationModel(
      busId: (json['busId'] as num?)?.toInt() ?? 0,
      vehicleNumber: json['vehicleNumber']?.toString() ?? 'MH-04-TM-XXXX',
      routeId: (json['routeId'] as num?)?.toInt() ?? 0,
      routeNumber: json['routeNumber']?.toString() ?? '',
      source: json['source']?.toString() ?? '',
      destination: json['destination']?.toString() ?? '',
      transportType: json['transportType']?.toString() ?? 'BUS',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 19.1860,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 72.9759,
      speed: (json['speed'] as num?)?.toDouble() ?? 25.0,
      heading: (json['heading'] as num?)?.toDouble() ?? 0.0,
      timestamp: (json['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      currentStopName: json['currentStopName']?.toString() ?? 'Current Stop',
      nextStopName: json['nextStopName']?.toString() ?? 'Next Stop',
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 5,
      status: json['status']?.toString() ?? 'On time',
      vehicleType: json['vehicleType']?.toString() ?? 'TMT Bus',
      capacity: (json['capacity'] as num?)?.toInt() ?? 40,
      occupancyStatus: json['occupancyStatus']?.toString() ?? 'Moderate',
      isMock: json['isMock'] as bool? ?? true,
      dataLabel: json['dataLabel']?.toString() ?? 'Demo / Simulated',
    );
  }
}
