import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';

class WelcomeText extends StatelessWidget {
  const WelcomeText({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedTextKit(
      repeatForever: true,
      pause: Duration.zero, // ✅ No pause at all
      animatedTexts: [
        ColorizeAnimatedText(
          'Welcome to SkillBox',
          textStyle: const TextStyle(
            fontSize: 32, 
            fontWeight: FontWeight.bold,
          ),
          colors: const [
            Colors.yellow, 
            Colors.red,
            Colors.orange,
            Colors.yellow,
          ],
          speed: const Duration(milliseconds: 100), // Faster transition
        ),
      ],
    );
  }
}