import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/item.dart';

class ItemBadges extends StatelessWidget {
  final Item item;
  final bool showCondition;
  final bool showExchangeType;

  const ItemBadges({
    super.key,
    required this.item,
    this.showCondition = true,
    this.showExchangeType = true,
  });

  @override
  Widget build(BuildContext context) {
    final badges = <Widget>[];

    if (showCondition) {
      badges.add(_buildChip(
        context,
        icon: _getConditionIcon(item.condition),
        label: _getConditionLabel(item.condition),
      ));
    }

    if (showExchangeType) {
      badges.add(_buildChip(
        context,
        icon: _getExchangeTypeIcon(item.exchangeType),
        label: _getExchangeTypeLabel(item.exchangeType),
      ));
    }

    return Wrap(
      spacing: 8.w,
      runSpacing: 4.h,
      children: badges,
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14.sp,
            color: Theme.of(context).colorScheme.secondary,
          ),
          SizedBox(width: 6.w),
          Text(
            label,
            style: TextStyle(
              color: Theme.of(context).colorScheme.secondary,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConditionIcon(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.likeNew:
        return LucideIcons.sparkles;
      case ItemCondition.used:
        return LucideIcons.package;
      case ItemCondition.needsRepair:
        return LucideIcons.wrench;
    }
  }

  String _getConditionLabel(ItemCondition condition) {
    switch (condition) {
      case ItemCondition.likeNew:
        return 'Como nuevo';
      case ItemCondition.used:
        return 'Usado';
      case ItemCondition.needsRepair:
        return 'Necesita reparación';
    }
  }

  IconData _getExchangeTypeIcon(ExchangeType exchangeType) {
    switch (exchangeType) {
      case ExchangeType.gift:
        return LucideIcons.gift;
      case ExchangeType.exchange:
        return LucideIcons.refreshCw;
    }
  }

  String _getExchangeTypeLabel(ExchangeType exchangeType) {
    switch (exchangeType) {
      case ExchangeType.gift:
        return 'Regalo';
      case ExchangeType.exchange:
        return 'Intercambio';
    }
  }
}
