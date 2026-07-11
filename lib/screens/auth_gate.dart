import 'package:flutter/material.dart';
import '../services/auth_provider.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'training_record_list.dart';

/// ログイン状態に応じてログイン画面と一覧画面を切り替えるゲート
class AuthGate extends StatelessWidget {
  final AuthService? authServiceOverride;

  const AuthGate({super.key, this.authServiceOverride});

  @override
  Widget build(BuildContext context) {
    final auth = authServiceOverride ?? authService;
    return StreamBuilder<bool>(
      stream: auth.signedInChanges,
      initialData: auth.isSignedIn,
      builder: (context, snapshot) {
        final isSignedIn = snapshot.data ?? false;
        if (!isSignedIn) {
          return LoginScreen(authServiceOverride: authServiceOverride);
        }
        return TrainingRecordList(authServiceOverride: authServiceOverride);
      },
    );
  }
}
