// lib/service.dart
import 'models.dart';

/// Conta de utilizador para autenticação básica.
class UserAccount {
  final String username;
  final String password;
  final UserRole role;
  final String? accountantId; // liga a um Accountant quando role = contabilista

  const UserAccount({
    required this.username,
    required this.password,
    required this.role,
    this.accountantId,
  });
}

/// Serviço de autenticação em memória (demo).
class AuthService {
  UserAccount? _current;

  UserAccount? get current => _current;
  bool get isLoggedIn => _current != null;
  bool get isAdmin => _current?.role == UserRole.admin;
  String? get currentAccountantId => _current?.accountantId;

  // Credenciais base de demonstração
  final List<UserAccount> _users = const [
    UserAccount(username: 'admin', password: 'admin', role: UserRole.admin),
    UserAccount(
      username: 'c1',
      password: '1234',
      role: UserRole.contabilista,
      accountantId: 'acc-1', // deve existir em seed
    ),
  ];

  /// Tenta autenticar; devolve mensagem de erro ou `null` se OK.
  String? login(String username, String password) {
    final u = _users.firstWhere(
      (e) => e.username == username && e.password == password,
      orElse: () =>
          const UserAccount(username: '', password: '', role: UserRole.admin),
    );
    if (u.username.isEmpty) return 'Credenciais inválidas';
    _current = u;
    return null;
  }

  /// Termina sessão.
  void logout() {
    _current = null;
  }
}
