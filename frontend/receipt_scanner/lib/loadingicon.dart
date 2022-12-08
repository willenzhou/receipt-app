import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingIcon extends StatelessWidget {
  final double durationInSeconds;
  const LoadingIcon({super.key, required this.durationInSeconds});

  @override
  Widget build(BuildContext context) {
    return SpinKitPouringHourGlassRefined(
        color: Colors.blue,
        size: 50.0,
        duration: Duration(
            seconds: durationInSeconds.toInt(),
            milliseconds: (durationInSeconds % 1).toInt() * 1000));
  }
}
