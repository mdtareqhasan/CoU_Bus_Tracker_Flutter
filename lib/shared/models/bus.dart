import 'package:json_annotation/json_annotation.dart';
import '../../l10n/l10n.dart';

part 'bus.g.dart';

@JsonSerializable()
class Bus {
  final int? id;
  final String? busNumber;
  final String? busNameBn;
  final String? busNameEn;
  final String? category;
  final String? driverName;
  final String? driverPhone;
  final String? busImageUrl;
  final String? trackerUrl;
  final bool? isActive;

  const Bus({
    this.id,
    this.busNumber,
    this.busNameBn,
    this.busNameEn,
    this.category,
    this.driverName,
    this.driverPhone,
    this.busImageUrl,
    this.trackerUrl,
    this.isActive,
  });

  factory Bus.fromJson(Map<String, dynamic> json) => _$BusFromJson(json);
  Map<String, dynamic> toJson() => _$BusToJson(this);

  /// Bus name in the active app language, falling back to the other language
  /// and finally to the bus number.
  String get displayBusName {
    final name = localizedBusName;
    if (name != null && name.isNotEmpty) return name;
    return busNumber ?? 'N/A';
  }

  /// Raw bus name in the active app language (no bus-number fallback).
  String? get localizedBusName => _localized(busNameBn, busNameEn);

  /// Picks [bn] or [en] to match the active app language, falling back to the
  /// other language when the preferred one is missing or empty.
  static String? _localized(String? bn, String? en) {
    final preferred = L10n.locale.languageCode == 'bn' ? bn : en;
    final fallback = L10n.locale.languageCode == 'bn' ? en : bn;
    if (preferred != null && preferred.isNotEmpty) return preferred;
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  String get categoryLabel {
    switch (category?.toUpperCase()) {
      case 'BLUE':
        return L10n.current.busCategoryBlue;
      case 'RED':
        return L10n.current.busCategoryRed;
      case 'TEACHER':
        return L10n.current.busCategoryTeacher;
      case 'OFFICER':
        return L10n.current.busCategoryOfficer;
      case 'STAFF':
        return L10n.current.busCategoryStaff;
      default:
        return category ?? '';
    }
  }
}
