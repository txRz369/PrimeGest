import 'package:flutter/material.dart';
import 'models.dart';
import 'repository.dart';
import 'auth.dart';
import 'ui/controlo_interno_page.dart';
import 'ui/empresas_page.dart';
import 'ui/contabilistas_page.dart';
import 'ui/equipas_page.dart';
import 'ui/tarefas_page.dart';
import 'supabase_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supa.init(); // <— inicializa Supabase
  runApp(const AppRoot());
}

/// AppState central com InheritedNotifier (sem pacotes externos)
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState notifier, required Widget child})
      : super(notifier: notifier, child: child);

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found in context');
    return scope!.notifier!;
  }
}

class AppState extends ChangeNotifier {
  final Repository repo = Repository();
  final AuthService auth = AuthService();
  DateTime _selectedMonth = DateUtils.dateOnly(
    DateTime(DateTime.now().year, DateTime.now().month, 1),
  );

  DateTime get selectedMonth => _selectedMonth;
  void setMonth(DateTime m) {
    _selectedMonth = DateUtils.dateOnly(DateTime(m.year, m.month, 1));
    notifyListeners();
  }

  bool get isAdmin => auth.currentUser?.isAdmin == true;

  List<Empresa> visibleEmpresas() {
    final user = auth.currentUser;
    if (user == null) return const [];
    return repo.empresasForUser(user);
  }

  void logout() {
    auth.logout();
    notifyListeners();
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});
  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  late final AppState state;

  @override
  void initState() {
    super.initState();
    state = AppState();
    state.repo.seed(); // dados exemplo
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      notifier: state,
      child: MaterialApp(
        title: 'Controlo de Tarefas',
        theme: ThemeData(
          colorSchemeSeed: Colors.indigo,
          useMaterial3: true,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        debugShowCheckedModeBanner: false,
        initialRoute: '/login',
        routes: {
          '/login': (_) => const LoginPage(),
          '/controlo': (_) => const ControloInternoPage(),
          '/empresas': (_) => const EmpresasPage(),
          '/contabilistas': (_) => const ContabilistasPage(),
          '/equipas': (_) => const EquipasPage(),
          '/tarefas': (_) => const TarefasPage(),
        },
        onGenerateRoute: (settings) {
          // fallback
          return MaterialPageRoute(builder: (_) => const ControloInternoPage());
        },
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final userCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;
  String? error;

  void doLogin() async {
    setState(() {
      loading = true;
      error = null;
    });
    final app = AppScope.of(context);
    final ok = await app.auth.login(
      app.repo,
      userCtrl.text.trim(),
      passCtrl.text,
    );
    setState(() => loading = false);
    if (ok) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/controlo');
    } else {
      setState(() => error = 'Credenciais inválidas.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            color: color.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: AutofillGroup(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.task_alt, size: 48),
                    const SizedBox(height: 12),
                    Text(
                      'App Controlo de Tarefas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: userCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Utilizador',
                      ),
                      autofillHints: const [AutofillHints.username],
                      onSubmitted: (_) => doLogin(),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      decoration: const InputDecoration(labelText: 'Senha'),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      onSubmitted: (_) => doLogin(),
                    ),
                    const SizedBox(height: 12),
                    if (error != null)
                      Text(error!, style: TextStyle(color: color.error)),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: loading ? null : doLogin,
                      icon: loading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: const Text('Entrar'),
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('Admin: utilizador "admin", senha "admin"'),
                    const SizedBox(height: 4),
                    const Text(
                      'Contabilistas de exemplo: "ines", "joao", "maria" (senha "1234")',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
