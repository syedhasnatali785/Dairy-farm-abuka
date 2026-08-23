import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>(
  (ref) => FirebaseAuth.instance,
);
final authStateProvider = StreamProvider<User?>(
  (ref) => ref.watch(firebaseAuthProvider).authStateChanges(),
);
final authProvider = NotifierProvider<AuthNotifier, AsyncValue<User?>>(
  AuthNotifier.new,
);

class AuthNotifier extends Notifier<AsyncValue<User?>> {
  FirebaseAuth get _auth => ref.read(firebaseAuthProvider);
  @override
  AsyncValue<User?> build() {
    return AsyncData(_auth.currentUser);
  }

  Future<UserCredential?> login({
    required String email,
    required String password,
  }) async {
    state = AsyncLoading();
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } on FirebaseException catch (e, stackTrace) {
      state = AsyncError(_firebaseError(e), stackTrace);
    }
    return null;
  }

  Future<bool> register({
    required String email,
    required String password,
  }) async {
    state = AsyncLoading();
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      state = AsyncData(credential.user);
      return true;
    } on FirebaseAuthException catch (e, stackTrace) {
      state = AsyncError(_firebaseError(e), stackTrace);

      return false;
    } catch (e, stackTrace) {
      state = AsyncError(e, stackTrace);
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    state = const AsyncData(null);
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  String _firebaseError(FirebaseException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Enter a valid email address.';

      case 'weak-password':
        return 'Password is too weak.';

      case 'user-not-found':
        return 'No account found with this email.';

      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';

      case 'too-many-requests':
        return 'Too many attempts. Try again later.';

      case 'network-request-failed':
        return 'Check your internet connection.';

      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
