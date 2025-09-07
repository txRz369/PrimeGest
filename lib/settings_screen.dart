import 'package:flutter/material.dart';
import 'supabase_service.dart';

class SettingsScreen extends StatelessWidget {
  final VoidCallback onToggleTheme;
  final bool notifications;
  final VoidCallback onToggleNotifications;

  const SettingsScreen({
    super.key,
    required this.onToggleTheme,
    required this.notifications,
    required this.onToggleNotifications,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final nextNotifyStart = DateTime(now.year, now.month + 1, 15);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: ListView(
        children: [
          SwitchListTile(
            title: const Text('Tema escuro/claro'),
            subtitle: const Text('Alternar Material 3'),
            value: Theme.of(context).brightness == Brightness.dark,
            onChanged: (_) => onToggleTheme(),
          ),
          SwitchListTile(
            title: const Text('Aceitar notificações'),
            subtitle: Text(
                'A partir de ${_fmtDate(nextNotifyStart)}: alertar tarefas do mês anterior em falta.'),
            value: notifications,
            onChanged: (_) => onToggleNotifications(),
          ),
          const Divider(),
          ListTile(
            title: const Text('Sessão'),
            subtitle: Text(Supa.email ?? '-'),
            trailing: const Icon(Icons.info_outline),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
}
