import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

enum ItemStatus {
  available,
  exchanged,
  paused,
}

enum ItemCondition {
  likeNew,
  used,
  needsRepair,
}

enum ExchangeType {
  gift,
  exchange,
}

class Item {
  final String id;
  final String ownerId;
  final String title;
  final String? description;
  final ItemStatus status;
  final ItemCondition condition;
  final ExchangeType exchangeType;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Item({
    required this.id,
    required this.ownerId,
    required this.title,
    this.description,
    this.status = ItemStatus.available,
    this.condition = ItemCondition.used,
    this.exchangeType = ExchangeType.exchange,
    required this.createdAt,
    this.updatedAt,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    try {
      return Item(
        id: json['id'] as String,
        ownerId: json['owner_id'] as String,
        title: json['title'] as String,
        description: json['description'] as String?,
        status: ItemStatus.values.firstWhere(
          (v) => v.name == (json['status'] ?? 'available'),
          orElse: () => ItemStatus.available,
        ),
        condition: _parseCondition(json['condition'] as String?),
        exchangeType: _parseExchangeType(json['exchange_type'] as String?),
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: json['updated_at'] != null 
            ? DateTime.parse(json['updated_at'] as String)
            : null,
      );
    } catch (e) {
      print('❌ [Item.fromJson] Error: $e');
      print('🔍 [Item.fromJson] JSON keys: ${json.keys}');
      print('🔍 [Item.fromJson] Full JSON: $json');
      rethrow;
    }
  }

  static ItemCondition _parseCondition(String? value) {
    return parseItemCondition(value);
  }

  static ExchangeType _parseExchangeType(String? value) {
    return parseExchangeType(value);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'status': status.name,
      'condition': itemConditionToString(condition),
      'exchange_type': exchangeTypeToString(exchangeType),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? ownerId,
    String? title,
    String? description,
    ItemStatus? status,
    ItemCondition? condition,
    ExchangeType? exchangeType,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      condition: condition ?? this.condition,
      exchangeType: exchangeType ?? this.exchangeType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isActive => status == ItemStatus.available;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item &&
        other.id == id &&
        other.ownerId == ownerId &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.condition == condition &&
        other.exchangeType == exchangeType &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      ownerId,
      title,
      description,
      status,
      condition,
      exchangeType,
      createdAt,
      updatedAt,
    );
  }

  @override
  String toString() {
    return 'Item(id: $id, ownerId: $ownerId, title: $title, description: $description, status: $status, condition: $condition, exchangeType: $exchangeType, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

// Extension methods for UI labels in Spanish
extension ItemConditionExtension on ItemCondition {
  String get label {
    switch (this) {
      case ItemCondition.likeNew:
        return 'Nuevo';
      case ItemCondition.used:
        return 'Usado';
      case ItemCondition.needsRepair:
        return 'A reparar';
    }
  }

  String get icon {
    switch (this) {
      case ItemCondition.likeNew:
        return '✨';
      case ItemCondition.used:
        return '📦';
      case ItemCondition.needsRepair:
        return '🔧';
    }
  }

  IconData get iconData {
    switch (this) {
      case ItemCondition.likeNew:
        return LucideIcons.sparkles;
      case ItemCondition.used:
        return LucideIcons.package;
      case ItemCondition.needsRepair:
        return LucideIcons.wrench;
    }
  }
}

extension ExchangeTypeExtension on ExchangeType {
  String get label {
    switch (this) {
      case ExchangeType.gift:
        return 'Regalar';
      case ExchangeType.exchange:
        return 'Intercambiar';
    }
  }

  String get icon {
    switch (this) {
      case ExchangeType.gift:
        return '🎁';
      case ExchangeType.exchange:
        return '🔄';
    }
  }

  IconData get iconData {
    switch (this) {
      case ExchangeType.gift:
        return LucideIcons.gift;
      case ExchangeType.exchange:
        return LucideIcons.refreshCw;
    }
  }
}

// Helper functions for parsing and converting enums
ItemCondition parseItemCondition(String? value) {
  switch (value) {
    case 'like_new':
      return ItemCondition.likeNew;
    case 'needs_repair':
      return ItemCondition.needsRepair;
    case 'used':
    default:
      return ItemCondition.used;
  }
}

ExchangeType parseExchangeType(String? value) {
  switch (value) {
    case 'gift':
      return ExchangeType.gift;
    case 'exchange':
    default:
      return ExchangeType.exchange;
  }
}

String itemConditionToString(ItemCondition condition) {
  switch (condition) {
    case ItemCondition.likeNew:
      return 'like_new';
    case ItemCondition.used:
      return 'used';
    case ItemCondition.needsRepair:
      return 'needs_repair';
  }
}

String exchangeTypeToString(ExchangeType type) {
  switch (type) {
    case ExchangeType.gift:
      return 'gift';
    case ExchangeType.exchange:
      return 'exchange';
  }
}
