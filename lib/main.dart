// lib/main.dart
import 'package:flutter/material.dart';
import 'app_state.dart';
import 'pages.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final state = AppState();

  @override
  void initState() {
    super.initState();
    state.seedIfEmpty();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: state,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Controlo de Tarefas',
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: Colors.teal,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        routes: {'/': (_) => const Shell(), '/login': (_) => const LoginPage()},
        initialRoute: '/login',
      ),
    );
  }
}

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);

    // Se não estiver autenticado, volta ao login
    if (!state.auth.isLoggedIn) {
      Future.microtask(
        () => Navigator.of(context).pushReplacementNamed('/login'),
      );
      return const SizedBox.shrink();
    }

    final isAdmin = state.auth.isAdmin;

    // Páginas
    final pagesAdmin = const [
      InternalControlPage(),
      CompaniesPage(),
      AccountantsPage(),
      TeamsPage(),
      TasksPage(),
    ];
    final pagesCont = const [InternalControlPage()];
    final pages = isAdmin ? pagesAdmin : pagesCont;

    // Corrige índice fora de faixa
    if (_index >= pages.length) _index = pages.length - 1;
    if (_index < 0) _index = 0;

    return Scaffold(
      appBar: AppBar(
        title: Text(_titleForIndex(_index, isAdmin: isAdmin)),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: () {
              state.auth.logout();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      drawer: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              ListTile(
                leading: const CircleAvatar(
                  child: Icon(Icons.admin_panel_settings),
                ),
                title: Text(isAdmin ? 'Admin' : 'Contabilista'),
                subtitle: Text(isAdmin ? 'Acesso total' : 'Acesso restrito'),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _navItems(isAdmin: isAdmin).length,
                  itemBuilder: (context, i) {
                    final item = _navItems(isAdmin: isAdmin)[i];
                    return ListTile(
                      selected: _index == i,
                      leading: Icon(item.icon),
                      title: Text(item.label),
                      onTap: () {
                        setState(() => _index = i);
                        Navigator.pop(context); // fecha o drawer
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: pages[_index],
    );
  }

  String _titleForIndex(int i, {required bool isAdmin}) {
    final items = _navItems(isAdmin: isAdmin);
    if (i < 0 || i >= items.length) return 'Controlo Interno';
    return items[i].label;
  }

  List<_NavItem> _navItems({required bool isAdmin}) => isAdmin
      ? const [
          _NavItem('Controlo Interno', Icons.fact_check),
          _NavItem('Empresas', Icons.apartment),
          _NavItem('Contabilistas', Icons.people),
          _NavItem('Equipas', Icons.groups),
          _NavItem('Tarefas', Icons.task),
        ]
      : const [_NavItem('Controlo Interno', Icons.fact_check)];
}

class _NavItem {
  final String label;
  final IconData icon;
  const _NavItem(this.label, this.icon);
}
