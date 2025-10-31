import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatInput extends StatefulWidget {
  final TextEditingController controller;
  final Function(String)? onSend;
  final bool isLoading;
  final bool enabled;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isLoading = false,
    this.enabled = true,
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = widget.controller.text.trim().isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!widget.enabled)
              Container(
                padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                margin: EdgeInsets.only(bottom: 8.h),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16.sp,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Este item ya fue marcado como entregado',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    enabled: widget.enabled,
                    decoration: InputDecoration(
                      hintText: widget.enabled 
                          ? 'Escribe un mensaje...'
                          : 'No se pueden enviar más mensajes',
                      hintStyle: TextStyle(
                        color: widget.enabled
                            ? colorScheme.onSurfaceVariant
                            : colorScheme.onSurfaceVariant.withOpacity(0.5),
                        fontSize: 16.sp,
                      ),
                      filled: true,
                      fillColor: widget.enabled
                          ? colorScheme.surfaceContainerLow
                          : colorScheme.surfaceContainerHighest,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant,
                          width: 1,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: colorScheme.outlineVariant.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide(
                          color: colorScheme.primary,
                          width: 2,
                        ),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 16.h,
                      ),
                    ),
                    style: TextStyle(
                      fontSize: 16.sp,
                      color: widget.enabled
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                    maxLines: null,
                    textCapitalization: TextCapitalization.sentences,
                    onSubmitted: widget.enabled && _hasText && widget.onSend != null
                        ? (value) => _sendMessage()
                        : null,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                SizedBox(width: 12.w),
                Container(
                  width: 48.w,
                  height: 48.w,
                  decoration: BoxDecoration(
                    color: widget.enabled && _hasText && !widget.isLoading
                        ? colorScheme.primary
                        : colorScheme.outline.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12.r),
                    boxShadow: widget.enabled && _hasText && !widget.isLoading
                        ? [
                            BoxShadow(
                              color: colorScheme.primary.withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: IconButton(
                    onPressed: widget.enabled && _hasText && !widget.isLoading && widget.onSend != null
                        ? _sendMessage
                        : null,
                    icon: widget.isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                colorScheme.onPrimary,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.send_rounded,
                            size: 20.sp,
                            color: widget.enabled && _hasText
                                ? colorScheme.onPrimary
                                : colorScheme.outline,
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = widget.controller.text.trim();
    if (text.isNotEmpty && widget.onSend != null) {
      widget.onSend!(text);
    }
  }
}
