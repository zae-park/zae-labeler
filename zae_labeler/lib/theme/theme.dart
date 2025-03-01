import 'package:flutter/material.dart';

/// ✅ 전역 테마 및 스타일 설정
class AppTheme {
  /// **기본 색상 팔레트**
  static const Color primaryColor = Colors.blueAccent;
  static const Color secondaryColor = Colors.grey;
  static const Color selectedTextColor = Colors.white;
  static const Color unselectedTextColor = Colors.black87;

  /// **버튼 스타일**
  static BoxDecoration buttonDecoration({required bool isSelected}) {
    return BoxDecoration(
      color: isSelected ? primaryColor : secondaryColor,
      borderRadius: BorderRadius.circular(8.0),
      border: isSelected ? Border.all(color: primaryColor, width: 2.0) : null,
      boxShadow: isSelected ? [BoxShadow(color: primaryColor.withOpacity(0.3), blurRadius: 8, spreadRadius: 2, offset: const Offset(0, 3))] : [],
    );
  }

  /// **텍스트 스타일**
  static TextStyle buttonTextStyle({required bool isSelected}) {
    return TextStyle(color: isSelected ? selectedTextColor : unselectedTextColor, fontSize: 16, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal);
  }
}
