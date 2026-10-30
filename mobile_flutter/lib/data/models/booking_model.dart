class BookingModel {
  final int id;
  final String bookingReference;
  final int routeId;
  final String routeNumber;
  final String routeName;
  final String sourceStop;
  final String destinationStop;
  final String departureTime;
  final int passengerCount;
  final double fare;
  final String status;
  final String paymentMethod;
  final String paymentStatus;
  final String upiId;
  final int bookedAt;
  final String qrPayload;
  final bool isDemo;
  final String notice;

  BookingModel({
    required this.id,
    required this.bookingReference,
    required this.routeId,
    required this.routeNumber,
    required this.routeName,
    required this.sourceStop,
    required this.destinationStop,
    required this.departureTime,
    required this.passengerCount,
    required this.fare,
    required this.status,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.upiId,
    required this.bookedAt,
    required this.qrPayload,
    this.isDemo = true,
    this.notice = 'Demo ticket — Not an official TMT paper ticket',
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      bookingReference: json['bookingReference']?.toString() ?? '',
      routeId: (json['routeId'] as num?)?.toInt() ?? 0,
      routeNumber: json['routeNumber']?.toString() ?? '',
      routeName: json['routeName']?.toString() ?? '',
      sourceStop: json['sourceStop']?.toString() ?? '',
      destinationStop: json['destinationStop']?.toString() ?? '',
      departureTime: json['departureTime']?.toString() ?? '',
      passengerCount: (json['passengerCount'] as num?)?.toInt() ?? 1,
      fare: (json['fare'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'CONFIRMED',
      paymentMethod: json['paymentMethod']?.toString() ?? 'UPI_DEMO',
      paymentStatus: json['paymentStatus']?.toString() ?? 'PAID_DEMO',
      upiId: json['upiId']?.toString() ?? '',
      bookedAt: (json['bookedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      qrPayload: json['qrPayload']?.toString() ?? '',
      isDemo: json['isDemo'] as bool? ?? true,
      notice: json['notice']?.toString() ?? 'Demo ticket — Not an official TMT paper ticket',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'bookingReference': bookingReference,
      'routeId': routeId,
      'routeNumber': routeNumber,
      'routeName': routeName,
      'sourceStop': sourceStop,
      'destinationStop': destinationStop,
      'departureTime': departureTime,
      'passengerCount': passengerCount,
      'fare': fare,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'upiId': upiId,
      'bookedAt': bookedAt,
      'qrPayload': qrPayload,
      'isDemo': isDemo,
      'notice': notice,
    };
  }
}

class CreateBookingRequest {
  final int routeId;
  final String sourceStop;
  final String destinationStop;
  final String departureTime;
  final int passengerCount;
  final double? fare;
  final String? upiId;

  CreateBookingRequest({
    required this.routeId,
    required this.sourceStop,
    required this.destinationStop,
    required this.departureTime,
    this.passengerCount = 1,
    this.fare,
    this.upiId,
  });

  Map<String, dynamic> toJson() {
    return {
      'routeId': routeId,
      'sourceStop': sourceStop,
      'destinationStop': destinationStop,
      'departureTime': departureTime,
      'passengerCount': passengerCount,
      if (fare != null) 'fare': fare,
      if (upiId != null) 'upiId': upiId,
    };
  }
}
