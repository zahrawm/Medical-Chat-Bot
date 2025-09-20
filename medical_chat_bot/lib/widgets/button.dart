import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final Widget child;
  final IconData? icon;
  final Color color;
  final Color? disabledColor;
  final Color? textColor;
  final Color? disabledTextColor;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const MyButton({
    super.key,
    required this.child,
    this.icon,
    required this.color,
    this.disabledColor,
    this.textColor,
    this.disabledTextColor,
    required this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final buttonWidth = screenWidth * 0.85;
    final buttonHeight = screenHeight * 0.065;
    final iconSize = screenWidth * 0.055;

    // Determine colors based on enabled state
    final backgroundColor = isEnabled ? color : (disabledColor ?? Colors.greenAccent[400]);
    final foregroundColor = isEnabled ? (textColor ?? Colors.white) : (disabledTextColor ?? Colors.grey[200]);

    return MaterialButton(
      onPressed: isEnabled ? onPressed : null,
      color: backgroundColor,
      textColor: foregroundColor,
      disabledColor: disabledColor ?? Colors.greenAccent[100],
      disabledTextColor: disabledTextColor ?? Colors.grey[200],
      minWidth: buttonWidth,
      height: buttonHeight < 50 ? 50 : buttonHeight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.025),
      ),
      elevation: isEnabled ? 2 : 0,
      highlightElevation: isEnabled ? 4 : 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize < 16 ? 16 : iconSize,
              color: foregroundColor,
            ),
            SizedBox(width: screenWidth * 0.02),
          ],
          child,

        ],
      ),
    );
  }
}