import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:app/authentication.dart';
import 'package:app/models/invoice.dart';
import 'package:flutter/material.dart';
import 'package:app/app_builder.dart';
import 'package:app/events.dart';
import 'dart:convert';

import 'package:url_launcher/url_launcher.dart'
  if (dart.library.html) 'package:app/web_launcher.dart';

class PushNotificationsManager {

  PushNotificationsManager._();

  factory PushNotificationsManager() => _instance;

  static final PushNotificationsManager _instance = PushNotificationsManager._();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  bool _initialized = false;

  Future<void> init() async {
    if (!_initialized) {
      await _initializeSocket();
      await _initializeFireBase();

      _initialized = true;
    }
  }

  void _triggerSocketMessage(message) {
    Events.trigger(message['event'], message['payload']);
  }

  void _initializeSocket() async {
    var url = "https://ws.anypayinc.com?token=${Authentication.token}";
    IO.Socket socket = IO.io(url, <String, dynamic>{ 'transports': ['websocket'] });
    socket.on('connect', (_) => print("SOCKET CONNECTED!"));
    socket.on('error', (_) => print("SOCKET ERROR! $_"));
    socket.on('message', _triggerSocketMessage);
    Events.on('grab_and_go.payment', (data) {
      var invoice = Invoice.fromMap({
        'denomination_amount_paid': data['amount'],
        'item_name': data['item_name'],
        'uid': data['invoice_id'],
      });
			AppBuilder.openDialog("${invoice.paidAmountWithDenomination()} PAID", "Grab n Go ${invoice.itemName ?? "item"}",
        buttons: [{
          'text': 'Open Invoice',
          'onPressed': () {
            AppBuilder.openPath("/invoices/${invoice.uid}");
          },
        }]
      );
		});
  }

  void _initializeFireBase() async {
    print("INIT FIREBASE");
    // For iOS request permission first.
    _firebaseMessaging.requestNotificationPermissions();
    _firebaseMessaging.configure(
      // onBackgroundMessage: handlerForWhenAppIsInBackground,
      // onMessage: handlerForWhenAppIsOpen,
      onLaunch: (Map<String, dynamic> message) async {
        var data = message['data'] ?? message;
        AppBuilder.openPath(data['path']);
      },
      onResume: (Map<String, dynamic> message) async {
        var data = message['data'] ?? message;
        AppBuilder.openPath(data['path']);
      },
    );

    String token = await _firebaseMessaging.getToken();
    print("FirebaseMessaging token: $token");
  }

}