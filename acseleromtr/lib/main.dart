import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

const _eventChannel = EventChannel("accelerometer_jni");
const _methodChannel = MethodChannel("accelerometer_jni_method");

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String data = "Ожидание данных...";
  double x = 0, y = 0, z = 0;
  int randomNumber = 0;

  @override
  void initState() {
    super.initState();

    _eventChannel.receiveBroadcastStream().listen((event) {
      setState(() {
        data = event.toString();

        final match = RegExp(r'X:\s*(-?\d+(\.\d+)?),\s*Y:\s*(-?\d+(\.\d+)?),\s*Z:\s*(-?\d+(\.\d+)?)')
            .firstMatch(data);
        if (match != null) {
          x = double.parse(match.group(1)!);
          y = double.parse(match.group(3)!);
          z = double.parse(match.group(5)!);
        }
      });
    });

    _methodChannel.invokeMethod("startAccelerometer");
  }

  void generateRandomFromSensor() {
    final rng = Random();
    final modifier = ((x + y + z) * 1000).abs().round();
    setState(() {
      randomNumber = rng.nextInt(100) ^ modifier;
    });
  }


  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text("JNI Акселерометр")),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(data, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: generateRandomFromSensor,
                child: const Text("Сгенерировать число"),
              ),
              const SizedBox(height: 16),
              Text("Число: $randomNumber", style: const TextStyle(fontSize: 22)),
            ],
          ),
        ),
      ),
    );
  }
}
