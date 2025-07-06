import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';

class NotificationBadge extends StatelessWidget {
  final Widget child;
  final double? top;
  final double? right;
  final Color? badgeColor;
  final Color? textColor;
  final double? size;

  const NotificationBadge({
    Key? key,
    required this.child,
    this.top,
    this.right,
    this.badgeColor,
    this.textColor,
    this.size,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, _) {
        final count = provider.unreadCount;

        if (count == 0) {
          return child;
        }

        return Stack(
          children: [
            child,
            Positioned(
              top: top ?? 0,
              right: right ?? 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: badgeColor ?? Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: Colors.white,
                    width: 1,
                  ),
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  count > 99 ? '99+' : count.toString(),
                  style: TextStyle(
                    color: textColor ?? Colors.white,
                    fontSize: size ?? 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NotificationIcon extends StatelessWidget {
  final VoidCallback? onTap;
  final Color? iconColor;
  final double? iconSize;

  const NotificationIcon({
    Key? key,
    this.onTap,
    this.iconColor,
    this.iconSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: NotificationBadge(
        top: 2,
        right: 2,
        child: Icon(
          Icons.notifications,
          color: iconColor ?? Colors.white,
          size: iconSize ?? 24,
        ),
      ),
    );
  }
}

class NotificationButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String? text;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const NotificationButton({
    Key? key,
    this.onPressed,
    this.text,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NotificationBadge(
      top: -8,
      right: -8,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.notifications),
        label: Text(text ?? 'Thông báo'),
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
      ),
    );
  }
}
