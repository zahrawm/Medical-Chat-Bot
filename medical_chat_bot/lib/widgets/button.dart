import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final String text;
  final IconData? icon;
  final Color color;
  final VoidCallback onPressed;

  const MyButton({
    super.key,
    required this.text,
    this.icon,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonWidth = screenWidth * 0.85;
    final buttonHeight = screenHeight * 0.065;
    final fontSize = screenWidth * 0.045;
    final iconSize = screenWidth * 0.055;
    return MaterialButton(
      onPressed: onPressed ,
           color: color,
      textColor: Colors.white,
      minWidth: buttonWidth,
      height: buttonHeight < 50 ? 50 : buttonHeight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize < 14 ? 14 : fontSize,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
