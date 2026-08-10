import 'package:json_annotation/json_annotation.dart';

part 'bus.g.dart';

@JsonSerializable()
class Bus {
  final int? id;
  final String? busNumber;
  final String? busName;
  final String? category;
  final String? route;
  final String? driverName;
  final String? driverPhone;
  final String? busImageUrl;
  final String? trackerUrl;
  final bool? isActive;

  const Bus({
    this.id,
    this.busNumber,
    this.busName,
    this.category,
    this.route,
    this.driverName,
    this.driverPhone,
    this.busImageUrl,
    this.trackerUrl,
    this.isActive,
  });

  factory Bus.fromJson(Map<String, dynamic> json) => _$BusFromJson(json);
  Map<String, dynamic> toJson() => _$BusToJson(this);

  String get displayBusName {
    if (busName != null && busName!.isNotEmpty) return busName!;
    return busNumber ?? 'N/A';
  }

  String get categoryLabel {
    switch (category?.toUpperCase()) {
      case 'BLUE':
        return 'নীল';
      case 'RED':
        return 'লাল';
      case 'TEACHER':
        return 'শিক্ষক';
      case 'OFFICER':
        return 'অফিসার';
      case 'STAFF':
        return 'স্টাফ';
      default:
        return category ?? '';
    }
  }
}
