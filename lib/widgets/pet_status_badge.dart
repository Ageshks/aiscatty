import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// Premium pill badge showing the pet's adoption status.
class PetStatusBadge extends StatelessWidget {
  const PetStatusBadge({super.key, required this.status, this.compact = false});
  final String? status;
  final bool compact;

  String get _label {
    switch (PetStatus.normalise(status)) {
      case PetStatus.pending:
        return 'Adoption Pending';
      case PetStatus.adopted:
        return 'Adopted ❤️';
      default:
        return 'Available for Adoption';
    }
  }

  Color get _color {
    switch (PetStatus.normalise(status)) {
      case PetStatus.pending:
        return AppColors.blue; // warm mochaccino
      case PetStatus.adopted:
        return Colors.green.shade700;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 8 : 12, vertical: compact ? 3 : 6),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Text(
        _label,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 10 : 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Convenience helpers shared across pages.
class PetStatus {
  static const available = 'available';
  static const pending = 'pending';
  static const adopted = 'adopted';

  /// Canonical status for any stored variant.
  ///
  /// Older listings (and hand edited documents) may store 'Available',
  /// 'Adoption Pending', 'Adopted ❤️', 'adoption in progress', … — comparing
  /// those raw strings against 'available' silently hides the pets, so every
  /// reader goes through here instead.
  static String normalise(dynamic raw) {
    final text = (raw?.toString() ?? '').trim().toLowerCase();
    if (text.isEmpty) return available;

    if (text.contains('available') || text.contains('active')) {
      return available;
    }
    if (text.contains('pending') ||
        text.contains('progress') ||
        text.contains('reserved') ||
        text.contains('hold')) {
      return pending;
    }
    if (text.contains('adopt') ||
        text.contains('sold') ||
        text.contains('done') ||
        text.contains('closed')) {
      return adopted;
    }
    return available;
  }

  /// Safe status read — missing/unknown fields default to available.
  static String of(Map<String, dynamic> data) =>
      normalise(data['status']);

  static bool isAvailable(Map<String, dynamic> data) =>
      of(data) == available;

  static String? videoUrlOf(Map<String, dynamic> data) {
    final url = data['statusVideoUrl']?.toString() ?? '';
    return url.isEmpty ? null : url;
  }
}
