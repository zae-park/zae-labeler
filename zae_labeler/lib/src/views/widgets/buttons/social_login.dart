import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final Image logoImg;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const SocialLoginButton({super.key, required this.label, required this.logoImg, required this.backgroundColor, required this.onPressed});

  /// ✅ Google 버튼 팩토리
  factory SocialLoginButton.google({required VoidCallback onPressed}) {
    final logo = _networkLogo('https://upload.wikimedia.org/wikipedia/commons/5/53/Google_%22G%22_Logo.svg');
    return SocialLoginButton(label: "Sign in with Google", logoImg: logo, backgroundColor: Colors.white, onPressed: onPressed);
  }

  /// ✅ GitHub 버튼 팩토리
  factory SocialLoginButton.github({required VoidCallback onPressed}) {
    final logo = _networkLogo('https://github.githubassets.com/assets/GitHub-Mark-ea2971cee799.png');
    return SocialLoginButton(label: "Sign in with GitHub", logoImg: logo, backgroundColor: Colors.black, onPressed: onPressed);
  }

  /// ✅ Kakao 버튼 팩토리
  factory SocialLoginButton.kakao({required VoidCallback onPressed}) {
    final logo = _networkLogo('https://developers.kakao.com/assets/img/about/logos/kakaolink/kakaolink_btn_medium.png');
    return SocialLoginButton(label: "Sign in with Kakao", logoImg: logo, backgroundColor: const Color(0xFFFEE500), onPressed: onPressed);
  }

  /// ✅ Naver 버튼 팩토리
  factory SocialLoginButton.naver({required VoidCallback onPressed}) {
    final logo = _networkLogo('https://ssl.pstatic.net/static/nid/login/login_2022.png');
    return SocialLoginButton(label: "Sign in with Naver", logoImg: logo, backgroundColor: const Color(0xFF03C75A), onPressed: onPressed);
  }

  static Image _networkLogo(String url) =>
      Image.network(url, fit: BoxFit.cover, width: 24, height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 24));

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        minimumSize: const Size(240, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      onPressed: onPressed,
      icon: logoImg,
      label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.black87)),
    );
  }
}
