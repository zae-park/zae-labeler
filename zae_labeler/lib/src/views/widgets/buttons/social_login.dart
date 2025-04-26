import 'package:flutter/material.dart';

class SocialLoginButton extends StatelessWidget {
  final String label;
  final String logoUrl;
  final Color backgroundColor;
  final VoidCallback onPressed;

  const SocialLoginButton({super.key, required this.label, required this.logoUrl, required this.backgroundColor, required this.onPressed});

  /// ✅ Google 버튼 팩토리
  factory SocialLoginButton.google({required VoidCallback onPressed}) {
    return SocialLoginButton(
      label: "Sign in with Google",
      logoUrl: 'http://pngimg.com/uploads/google/google_PNG19635.png',
      backgroundColor: Colors.white,
      onPressed: onPressed,
    );
  }

  /// ✅ GitHub 버튼 팩토리
  factory SocialLoginButton.github({required VoidCallback onPressed}) {
    return SocialLoginButton(
      label: "Sign in with GitHub",
      logoUrl: 'https://github.githubassets.com/assets/GitHub-Mark-ea2971cee799.png',
      backgroundColor: Colors.black,
      onPressed: onPressed,
    );
  }

  // /// ✅ Kakao 버튼 팩토리
  // factory SocialLoginButton.kakao({required VoidCallback onPressed}) {
  //   final logo = _networkLogo('https://developers.kakao.com/assets/img/about/logos/kakaolink/kakaolink_btn_medium.png');
  //   return SocialLoginButton(label: "Sign in with Kakao", logoImg: logo, backgroundColor: const Color(0xFFFEE500), onPressed: onPressed);
  // }

  // /// ✅ Naver 버튼 팩토리
  // factory SocialLoginButton.naver({required VoidCallback onPressed}) {
  //   final logo = _networkLogo('https://ssl.pstatic.net/static/nid/login/login_2022.png');
  //   return SocialLoginButton(label: "Sign in with Naver", logoImg: logo, backgroundColor: const Color(0xFF03C75A), onPressed: onPressed);
  // }

  // static Image _networkLogo(String url) =>
  //     Image.network(url, fit: BoxFit.cover, width: 24, height: 24, errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 24));

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(backgroundColor: backgroundColor, minimumSize: const Size(240, 48), padding: const EdgeInsets.symmetric(horizontal: 12)),
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            logoUrl,
            width: 24,
            height: 24,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const SizedBox(width: 24, height: 24); // 로딩 중에도 공간 확보
            },
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, size: 24),
          ),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 16, color: backgroundColor.computeLuminance() > 0.5 ? Colors.black : Colors.white)),
        ],
      ),
    );
  }
}
