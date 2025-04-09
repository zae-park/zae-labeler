// lib/env.dart

const String appFlavor = String.fromEnvironment('FLAVOR');

bool get isDev => appFlavor == 'development';
bool get isProd => appFlavor == 'production';
