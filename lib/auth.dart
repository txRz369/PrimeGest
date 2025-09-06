import 'models.dart';
import 'repository.dart';
import 'supabase_config.dart';

class AuthService {
  User? currentUser;

  Future<bool> login(Repository repo, String username, String password) async {
    // usa email + password (username será o email)
    try {
      final res = await Supa.client.auth
          .signInWithPassword(email: username.trim(), password: password);
      if (res.session == null) return false;

      // ler profile (para saber se é admin)
      final uid = res.user!.id;
      final p = await Supa.client
          .from('profiles')
          .select()
          .eq('user_id', uid)
          .maybeSingle();
      final isAdmin = (p?['is_admin'] ?? false) == true;
      currentUser = isAdmin
          ? User.admin()
          : User.contabilista(
              contabilistaId: uid, username: p?['username'] ?? username.trim());
      return true;
    } catch (_) {
      return false;
    }
  }

  void logout() {
    currentUser = null;
    Supa.client.auth.signOut();
  }
}
