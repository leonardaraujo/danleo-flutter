import 'package:flutter/material.dart';

class SplashImage extends StatelessWidget {
  final double width;
  final double height;
  final BoxFit fit;

  const SplashImage({
    super.key,
    this.width = 200.0,
    this.height = 200.0,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/splash/splash_image.png',
      width: width,
      height: height,
      fit: fit,
    );
  }
}
