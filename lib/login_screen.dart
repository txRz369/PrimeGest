import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import 'permissions.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoggedIn;
  const LoginScreen({super.key, required this.onLoggedIn});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController(text: 'teixeiradev22@gmail.com');
  final passCtrl = TextEditingController(text: '1234');
  bool loading = false;
  String? error;

  Future<void> _login() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final e = emailCtrl.text.trim();
      final p = passCtrl.text;
      await Supa.signIn(e, p);
      if (!Permissions.isAdmin(e)) {
        // utilizadores normais: navegação limitada (HomeShell trata)
      }
      widget.onLoggedIn();
    } on AuthException catch (ex) {
      setState(() => error = ex.message);
    } catch (_) {
      setState(() => error = 'Falha no login.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Entrar',
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                      decoration: const InputDecoration(labelText: 'Email'),
                      controller: emailCtrl),
                  const SizedBox(height: 8),
                  TextField(
                      decoration: const InputDecoration(labelText: 'Senha'),
                      controller: passCtrl,
                      obscureText: true),
                  const SizedBox(height: 16),
                  if (error != null)
                    Text(error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: loading ? null : _login,
                    icon: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.login),
                    label: const Text('Entrar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
