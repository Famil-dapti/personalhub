import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/auth_repository.dart';

final authActionProvider = Provider<AuthActions>((ref) {
  return AuthActions(ref);
});

class AuthActions {
  const AuthActions(this._ref);

  final Ref _ref;

  Future<String?> signIn({required String email, required String password}) async {
    try {
      await _ref.read(authRepositoryProvider).signIn(email: email, password: password);
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<String?> signUp({required String email, required String password}) async {
    try {
      await _ref.read(authRepositoryProvider).signUp(email: email, password: password);
      return null;
    } on Exception catch (e) {
      return e.toString();
    }
  }

  Future<void> signOut() async {
    await _ref.read(authRepositoryProvider).signOut();
  }
}
