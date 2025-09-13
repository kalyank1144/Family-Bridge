import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../../features/auth/providers/auth_providers.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  final userType = ref.watch(userTypeProvider).maybeWhen(data: (d) => d, orElse: () => null);
  return AppTheme.forUser(userType);
});
