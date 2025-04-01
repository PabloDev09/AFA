import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:afa/logic/providers/user_route_provider.dart';

class ChatComponent extends StatelessWidget {
  const ChatComponent({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<UserRouteProvider>(
      builder: (context, userRouteProvider, child) {
        final notifications = userRouteProvider.notifications;
        return Container(
          padding: const EdgeInsets.all(10),
          height: 200,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: Column(
            children: [
              const Text(
                "Chat de Notificaciones",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Expanded(
                child: ListView.builder(
                  reverse: true,
                  itemCount: notifications.length,
                  itemBuilder: (context, index) {
                    // No usamos const en el Text porque el contenido es dinámico
                    return ListTile(
                      title: Text(notifications[index]),
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
