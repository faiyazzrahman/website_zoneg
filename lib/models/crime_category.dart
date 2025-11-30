// lib/models/crime_category.dart
class CrimeCategory {
  final int id;
  final String name;
  final String? description;
  final String severity; // 'High', 'Medium', 'Low'
  final String? icon;
  final String? color; // Hex color code for UI
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  CrimeCategory({
    required this.id,
    required this.name,
    this.description,
    required this.severity,
    this.icon,
    this.color,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CrimeCategory.fromMap(Map<String, dynamic> map) {
    return CrimeCategory(
      id: map['id'] as int,
      // Handle both 'name' and 'crime_type' fields for backward compatibility
      name: (map['name'] ?? map['crime_type']) as String,
      description: map['description'] as String?,
      severity: map['severity'] as String? ?? 'Low',
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: map['created_at'] != null 
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null 
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'crime_type': name, // Support both field names
      if (description != null) 'description': description,
      'severity': severity,
      if (icon != null) 'icon': icon,
      if (color != null) 'color': color,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper method to get severity icon
  String get severityIcon {
    switch (severity.toLowerCase()) {
      case 'high':
        return '🔴';
      case 'medium':
        return '🟠';
      case 'low':
        return '🟡';
      default:
        return '⚪';
    }
  }

  // Helper method to get severity color with fallback
  String get displayColor {
    if (color != null && color!.isNotEmpty) {
      return color!;
    }

    // Fallback colors based on severity
    switch (severity.toLowerCase()) {
      case 'high':
        return '#F44336'; // Red
      case 'medium':
        return '#FF9800'; // Orange
      case 'low':
        return '#FFC107'; // Amber
      default:
        return '#9E9E9E'; // Grey
    }
  }

  // Helper method to check if category is high priority
  bool get isHighPriority => severity.toLowerCase() == 'high';

  // Helper method to check if category is medium priority
  bool get isMediumPriority => severity.toLowerCase() == 'medium';

  // Helper method to check if category is low priority
  bool get isLowPriority => severity.toLowerCase() == 'low';

  // Create a copy with updated fields
  CrimeCategory copyWith({
    int? id,
    String? name,
    String? description,
    String? severity,
    String? icon,
    String? color,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CrimeCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      severity: severity ?? this.severity,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CrimeCategory &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.severity == severity &&
        other.icon == icon &&
        other.color == color &&
        other.isActive == isActive &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    severity,
    icon,
    color,
    isActive,
    createdAt,
    updatedAt,
  );

  @override
  String toString() =>
      'CrimeCategory('
      'id: $id, '
      'name: $name, '
      'severity: $severity, '
      'isActive: $isActive'
      ')';
}

// Extension for additional utility methods
extension CrimeCategoryExtensions on CrimeCategory {
  // Helper method to get severity priority for sorting
  int get severityPriority {
    switch (severity.toLowerCase()) {
      case 'high':
        return 3;
      case 'medium':
        return 2;
      case 'low':
        return 1;
      default:
        return 0;
    }
  }
}