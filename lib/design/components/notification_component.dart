import 'package:afa/logic/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class NotificationComponent extends StatelessWidget {
  final ScrollController? scrollController;
  const NotificationComponent({this.scrollController, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<NotificationProvider>(
      builder: (context, notificationProvider, child) {
        final notifications = notificationProvider.notifications;

        return Container(
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF063970),
                      Color(0xFF2196F3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Notificaciones',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: notifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(item.date);
                    final isAlert = item.isAlert == true;
                    final isImportant = item.isImportant == true;
                    final isRead = item.isRead;

                    Color bgColor;
                    Color borderColor;
                    Color iconColor;
                    Color? textColor;

                    if (isAlert) {
                      if (isRead) {
                        bgColor = Colors.red.withOpacity(0.05);
                        borderColor = Colors.redAccent;
                        iconColor = Colors.redAccent;
                        textColor = Colors.red[700];
                      } else {
                        bgColor = Colors.red.withOpacity(0.1);
                        borderColor = Colors.red;
                        iconColor = Colors.red;
                        textColor = Colors.red[800];
                      }
                    } else if (isImportant) {
                      if (isRead) {
                        bgColor = Colors.green.withOpacity(0.05);
                        borderColor = Colors.greenAccent;
                        iconColor = Colors.greenAccent;
                        textColor = Colors.green[700];
                      } else {
                        bgColor = Colors.green.withOpacity(0.1);
                        borderColor = Colors.green;
                        iconColor = Colors.green;
                        textColor = Colors.green[800];
                      }
                    } else {
                      bgColor = isRead
                          ? theme.colorScheme.surface
                          : theme.colorScheme.primary.withOpacity(0.1);
                      borderColor = isRead
                          ? theme.disabledColor
                          : theme.colorScheme.primary;
                      iconColor = isRead
                          ? theme.disabledColor
                          : theme.colorScheme.primary;
                      textColor = null;
                    }

                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        notificationProvider.markAsReadByIndex(index);
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: borderColor,
                            width: 1.8,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              isAlert
                                  ? Icons.warning_amber_rounded
                                  : isImportant
                                      ? Icons.check_circle
                                      : isRead
                                          ? Icons.notifications_none
                                          : Icons.notifications_active,
                              color: iconColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.message,
                                    style: theme.textTheme.bodyLarge?.copyWith(
                                      fontWeight: (isRead && !isAlert && !isImportant)
                                          ? FontWeight.normal
                                          : FontWeight.bold,
                                      color: textColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: textColor?.withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!isRead)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: isAlert
                                      ? Colors.redAccent
                                      : isImportant
                                          ? Colors.greenAccent
                                          : theme.colorScheme.secondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
