// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:environment_sensors/environment_sensors.dart';
import 'package:location/location.dart';
import 'package:local_auth/local_auth.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sensors Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, this.title}) : super(key: key);

  final String? title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _tempAvailable = false;
  bool _humidityAvailable = false;
  bool _lightAvailable = false;
  bool _pressureAvailable = false;
  bool _serviceEnabled = false;
  LocationData? _locationData = null;
  PermissionStatus _permissionGranted = PermissionStatus.denied;

  final environmentSensors = EnvironmentSensors();

  List<double>? _accelerometerValues;
  List<double>? _userAccelerometerValues;
  List<double>? _gyroscopeValues;
  List<double>? _magnetometerValues;
  final _streamSubscriptions = <StreamSubscription<dynamic>>[];

  Future<void> initPlatformState() async {
    bool tempAvailable;
    bool humidityAvailable;
    bool lightAvailable;
    bool pressureAvailable;

    tempAvailable = await environmentSensors
        .getSensorAvailable(SensorType.AmbientTemperature);
    humidityAvailable =
        await environmentSensors.getSensorAvailable(SensorType.Humidity);
    lightAvailable =
        await environmentSensors.getSensorAvailable(SensorType.Light);
    pressureAvailable =
        await environmentSensors.getSensorAvailable(SensorType.Pressure);

    Location location = new Location();

    bool serviceEnabled;
    PermissionStatus permissionGranted = PermissionStatus.granted;
    LocationData? locationData;

    serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
    }

    permissionGranted = await location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await location.requestPermission();
      if (permissionGranted == PermissionStatus.granted) {
        locationData = await location.getLocation();
      }
    } else {
      locationData = await location.getLocation();
    }

    setState(() {
      _tempAvailable = tempAvailable;
      _humidityAvailable = humidityAvailable;
      _lightAvailable = lightAvailable;
      _pressureAvailable = pressureAvailable;
      _permissionGranted = permissionGranted;
      _serviceEnabled = serviceEnabled;
      _locationData = locationData;
    });
  }

  @override
  Widget build(BuildContext context) {
    LocalAuthentication auth = LocalAuthentication();

    String _authorized = 'Not Authorized';
    bool _isAuthenticating = false;

    Future<void> _authenticateWithBiometrics() async {
      bool authenticated = false;
      try {
        setState(() {
          _isAuthenticating = true;
          _authorized = 'Authenticating';
        });
        authenticated = await auth.authenticate(
          localizedReason:
              'Scan your fingerprint (or face or whatever) to authenticate',
          options: const AuthenticationOptions(
            stickyAuth: true,
            biometricOnly: true,
          ),
        );
        setState(() {
          _isAuthenticating = false;
          _authorized = 'Authenticating';
        });
      } on PlatformException catch (e) {
        print(e);
        setState(() {
          _isAuthenticating = false;
          _authorized = 'Error - ${e.message}';
        });
        return;
      }
      if (!mounted) {
        return;
      }

      final String message = authenticated ? 'Authorized' : 'Not Authorized';
      setState(() {
        _authorized = message;
      });
    }

    final accelerometer =
        _accelerometerValues?.map((double v) => v.toStringAsFixed(1)).toList();
    final gyroscope =
        _gyroscopeValues?.map((double v) => v.toStringAsFixed(1)).toList();
    final userAccelerometer = _userAccelerometerValues
        ?.map((double v) => v.toStringAsFixed(1))
        .toList();
    final magnetometer =
        _magnetometerValues?.map((double v) => v.toStringAsFixed(1)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Senzori u flutteru'), actions: <Widget>[
        ElevatedButton(
            onPressed: _authenticateWithBiometrics,
            child: Row(mainAxisSize: MainAxisSize.min, children: <Widget>[
              Text(_isAuthenticating
                  ? 'Cancel'
                  : 'Otisak prsta'),
              const Icon(Icons.fingerprint)
            ]))
      ]),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Accelerometer: $accelerometer'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('UserAccelerometer: $userAccelerometer'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Gyroscope: $gyroscope'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Magnetometer: $magnetometer'),
              ],
            ),
          ),
          (_tempAvailable)
              ? StreamBuilder<double>(
                  stream: environmentSensors.humidity,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  'Humidity: ${snapshot.data!.toStringAsFixed(2)}%')
                            ]));
                  })
              : const Text('No relative humidity sensor found'),
          (_humidityAvailable)
              ? StreamBuilder<double>(
                  stream: environmentSensors.temperature,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  'Temperature: ${snapshot.data!.toStringAsFixed(2)}')
                            ]));
                  })
              : const Text('No temperature sensor found'),
          (_lightAvailable)
              ? StreamBuilder<double>(
                  stream: environmentSensors.light,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  'Light: ${snapshot.data!.toStringAsFixed(2)}')
                            ]));
                  })
              : const Text('No light sensor found'),
          (_pressureAvailable)
              ? StreamBuilder<double>(
                  stream: environmentSensors.pressure,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData)
                      return const CircularProgressIndicator();
                    return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              Text(
                                  'Pressure: ${snapshot.data!.toStringAsFixed(2)}')
                            ]));
                  })
              : const Text('No pressure sensor found'),
          (_serviceEnabled == true &&
                  _permissionGranted == PermissionStatus.granted)
              ? Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Lokacija: longitude: ${_locationData?.longitude}  latitude: ${_locationData?.latitude}  speed: ${_locationData?.speed}, altittude: ${_locationData?.altitude}',
                    overflow: TextOverflow.visible,
                  ))
              : const Text('Lokacija nije dozvoljena'),
          //ElevatedButton(onPressed: initPlatformState , child: Text('Get'))
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
  }

  @override
  void initState() {
    super.initState();
    environmentSensors.pressure.listen((pressure) {
      print(pressure.toString());
    });
    initPlatformState();
    _streamSubscriptions.add(
      accelerometerEvents.listen(
        (AccelerometerEvent event) {
          setState(() {
            _accelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      gyroscopeEvents.listen(
        (GyroscopeEvent event) {
          setState(() {
            _gyroscopeValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      userAccelerometerEvents.listen(
        (UserAccelerometerEvent event) {
          setState(() {
            _userAccelerometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
    _streamSubscriptions.add(
      magnetometerEvents.listen(
        (MagnetometerEvent event) {
          setState(() {
            _magnetometerValues = <double>[event.x, event.y, event.z];
          });
        },
      ),
    );
  }
}
