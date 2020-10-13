import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_hyperpay/flutter_hyperpay.dart';
import 'package:http/http.dart';
import 'package:uni_links/uni_links.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

enum UniLinksType { string, uri }

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';
  String _checkoutID = 'Unknown';
  String _checkoutResult = 'Unknown';
  String _initialLink;
  String _latestLink = 'Unknown';
  Uri _latestUri;
  Uri _initialUri;
  UniLinksType _type = UniLinksType.string;
  StreamSubscription _sub;

  var client = Client();

  @override
  void initState() {
    super.initState();
    initPlatformState();
    initPlatformStateUri();
  }

  Future<void> initPlatformState() async {
    String platformVersion;

    try {
      platformVersion = await FlutterHyperpay.platformVersion;
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Hyperpay Plugin'),
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Center(
              child: Text('Running on: $_platformVersion\n'),
            ),
            RaisedButton(
              onPressed: () async {
                await _getCheckoutFromTestServer();
              },
              child: Text("GET CHECKOUT ID"),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("CheckoutID: $_checkoutID"),
            ),
            Visibility(
              visible: _checkoutID != null,
              child: RaisedButton(
                onPressed: () async {
                  await openPaymentGateway();
                },
                child: Text("OPEN CHECKOUT FORM"),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text("Checkout Result: $_checkoutResult"),
            ),
          ],
        ),
      ),
    );
  }

  Future _getCheckoutFromTestServer() async {
    try {
      var uriResponse = await client.get(
        'http://52.59.56.185:80/token?amount=49.99&paymentType=PA&testMode=INTERNAL&currency=EUR&notificationUrl=http://52.59.56.185:80/notification',
      );
      String checkoutID = jsonDecode(uriResponse.body)["checkoutId"];
      setState(() {
        _checkoutID = checkoutID;
      });
    } finally {
      client.close();
    }
  }

  Future<void> initPlatformStateForStringUniLinks() async {
    // Attach a listener to the links stream
    _sub = getLinksStream().listen((String link) {
      if (!mounted) return;
      setState(() {
        _latestLink = link ?? 'Unknown';
        _latestUri = null;
        try {
          if (link != null) _latestUri = Uri.parse(link);
        } on FormatException {}
      });
    }, onError: (Object err) {
      if (!mounted) return;
      setState(() {
        _latestLink = 'Failed to get latest link: $err.';
        _latestUri = null;
      });
    });

    // Attach a second listener to the stream
    getLinksStream().listen((String link) async {
      print('got link: $link');
      if (Platform.isIOS) await FlutterHyperpay.closeCheckout();
    }, onError: (Object err) {
      print('got err: $err');
    });

    // Get the latest link
    // Platform messages may fail, so we use a try/catch PlatformException.
    try {
      _initialLink = await getInitialLink();
      print('initial link: $_initialLink');
      if (_initialLink != null) _initialUri = Uri.parse(_initialLink);
    } on PlatformException {
      _initialLink = 'Failed to get initial link.';
      _initialUri = null;
    } on FormatException {
      _initialLink = 'Failed to parse the initial link as Uri.';
      _initialUri = null;
    }
  }

  Future<void> initPlatformStateUri() async {
    if (_type == UniLinksType.string) {
      await initPlatformStateForStringUniLinks();
    }
  }

  Future openPaymentGateway() async {
    String tempResult = await FlutterHyperpay.checkoutActitvity(
        checkoutID: _checkoutID,
        languageCodeAndroid: "en_US",
        languageCodeIos: "en",
        callbackURL: "hyperpaycheckout");
    setState(() {
      _checkoutResult = tempResult;
    });
  }
}
