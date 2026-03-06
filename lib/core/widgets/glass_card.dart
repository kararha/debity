import 'dart:ui';
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blurSigma;
  final double backgroundOpacity;
  final double borderOpacity;
  final EdgeInsetsGeometry padding;

  const GlassCard({
    super.key,
    required this.child,
    this.width = double.infinity,
    this.height,
    this.borderRadius = 20.0,
    this.blurSigma = 15.0,
    this.backgroundOpacity = 0.1,
    this.borderOpacity = 0.2,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          width: width,
          height: height,
          padding: padding,
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, backgroundOpacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Color.fromRGBO(255, 255, 255, borderOpacity),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
