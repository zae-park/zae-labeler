import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final Image logoImg;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const SocialLoginButton({super.key, required this.label, required this.logoImg, required this.backgroundColor, required this.onPressed});

  /// ✅ Google 버튼 팩토리
  factory SocialLoginButton.google({required VoidCallback onPressed}) {
    final logo = Image.network('http://pngimg.com/uploads/google/google_PNG19635.png', fit: BoxFit.cover);
    return SocialLoginButton(label: "Sign in with Google", logoImg: logo, backgroundColor: Colors.white, onPressed: onPressed);
  }

  /// ✅ GitHub 버튼 팩토리
  factory SocialLoginButton.github({required VoidCallback onPressed}) {
    final logo = Image.network('https://github.githubassets.com/assets/GitHub-Mark-ea2971cee799.png', fit: BoxFit.cover);
    return SocialLoginButton(label: "Sign in with GitHub", logoImg: logo, backgroundColor: Colors.black, onPressed: onPressed);
  }

  /// ✅ Kakao 버튼 팩토리
  factory SocialLoginButton.kakao({required VoidCallback onPressed}) {
    final logo = Image.network('', fit: BoxFit.cover);
    return SocialLoginButton(label: "Sign in with Kakao", logoImg: logo, backgroundColor: Colors.black, onPressed: onPressed);
  }

  /// ✅ Naver 버튼 팩토리
  factory SocialLoginButton.naver({required VoidCallback onPressed}) {
    final logo = Image.network('', fit: BoxFit.cover);
    return SocialLoginButton(label: "Sign in with Naver", logoImg: logo, backgroundColor: Colors.black, onPressed: onPressed);
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(backgroundColor: backgroundColor, minimumSize: const Size(240, 48), padding: const EdgeInsets.symmetric(horizontal: 16)),
      onPressed: onPressed,
      icon: logoImg,
      label: Text(label, style: const TextStyle(fontSize: 16)),
    );
  }
}
