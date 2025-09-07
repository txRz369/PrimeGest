import 'package:flutter/material.dart';
import 'supabase_service.dart';
import 'task_control_screen.dart';
import 'companies_screen.dart';
import 'accountants_screen.dart';
import 'teams_screen.dart';
import 'settings_screen.dart';
import 'permissions.dart';

class HomeShell extends StatefulWidget {
  final VoidCallback onToggleTheme;
  final bool notifications;
  final VoidCallback onToggleNotifications;

  const HomeShell({
    super.key,
    required this.onToggleTheme,
    required this.notifications,
    required this.onToggleNotifications,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int index = 0;

  Future<void> _logout() async {
    await Supa.signOut();
    if (!mounted) return; // evita usar context após await
    // Fecha tudo e volta ao primeiro ecrã (login)
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = Permissions.isAdmin(Supa.email);

    final items = <_NavItem>[
      _NavItem('Controlo', Icons.checklist_rtl, const TaskControlScreen()),
      if (isAdmin)
        _NavItem('Empresas', Icons.apartment, const CompaniesScreen()),
      if (isAdmin)
        _NavItem('Contabilistas', Icons.badge, const AccountantsScreen()),
      if (isAdmin) _NavItem('Equipa', Icons.groups, const TeamsScreen()),
      _NavItem(
        'Definições',
        Icons.settings,
        SettingsScreen(
          onToggleTheme: widget.onToggleTheme,
          notifications: widget.notifications,
          onToggleNotifications: widget.onToggleNotifications,
        ),
      ),
    ];

    // Sem AppBar — conteúdo encostado ao topo
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) => setState(() => index = i),
            labelType: NavigationRailLabelType.all,
            leading: const SizedBox(height: 8),
            // botão de logout no fundo (lado esquerdo, em baixo)
            trailing: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: IconButton(
                tooltip: 'Terminar sessão',
                onPressed: _logout,
                icon: const Icon(Icons.logout),
              ),
            ),
            destinations: [
              for (final it in items)
                NavigationRailDestination(
                  icon: Icon(it.icon),
                  label: Text(it.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          // área de conteúdo
          Expanded(child: items[index].page),
        ],
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final Widget page;
  _NavItem(this.label, this.icon, this.page);
}
