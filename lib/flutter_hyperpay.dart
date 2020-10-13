import 'dart:async';

import 'package:flutter/services.dart';

class FlutterHyperpay {
  static const MethodChannel _channel = const MethodChannel('flutter_hyperpay');

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<String> checkoutActitvity(
      {String checkoutID, String languageCodeIos, String languageCodeAndroid, String callbackURL}) async {
    final String version = await _channel.invokeMethod('checkoutActivity', {
      "checkoutID": checkoutID,
      "languageCodeIos": languageCodeIos,
      "languageCodeAndroid": languageCodeAndroid,
      "callbackURL": callbackURL,
      "callbackIos": "$callbackURL://result"
    });
    return version;
  }

  static Future<String> closeCheckout() async {
    final String version = await _channel
        .invokeMethod('closeCheckout');
    return version;
  }
}
