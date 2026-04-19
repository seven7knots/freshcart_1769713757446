import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';
import '../../../l10n/generated/app_localizations.dart';

class SpecialInstructionsWidget extends StatelessWidget {
  final TextEditingController controller;
  final int maxLength;

  const SpecialInstructionsWidget({
    super.key,
    required this.controller,
    this.maxLength = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'note_add',
                color: colorScheme.primary,
                size: 24,
              ),
              SizedBox(width: 3.w),
              Flexible(child: Text(
                AppLocalizations.of(context)!.specialInstructions,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ), maxLines: 1, overflow: TextOverflow.ellipsis)),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            AppLocalizations.of(context)!.addDeliveryNotesForTheDriver,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
          SizedBox(height: 2.h),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 4,
                    maxLength: maxLength,
                    decoration: InputDecoration(
                      hintText:
                          'e.g., Leave at the front door, Ring the bell twice, etc.',
                      hintStyle: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      filled: true,
                      fillColor: colorScheme.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.outline.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.all(3.w),
                      counterText: '',
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '${value.text.length}/$maxLength',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: value.text.length > maxLength * 0.8
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
