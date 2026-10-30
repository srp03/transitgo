class ScheduleModel {
  final int id;
  final int tripIndex;
  final String departureTime;
  final String? arrivalTime;
  final int routeId;

  ScheduleModel({
    required this.id,
    required this.tripIndex,
    required this.departureTime,
    this.arrivalTime,
    required this.routeId,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      tripIndex: (json['tripIndex'] as num?)?.toInt() ?? 0,
      departureTime: json['departureTime']?.toString() ?? '',
      arrivalTime: json['arrivalTime']?.toString(),
      routeId: (json['routeId'] as num?)?.toInt() ?? 0,
    );
  }
}
