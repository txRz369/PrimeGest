import 'package:flutter/material.dart';
import 'models.dart';
import 'supabase_service.dart';

class AccountantsScreen extends StatefulWidget {
  const AccountantsScreen({super.key});
  @override
  State<AccountantsScreen> createState() => _AccountantsScreenState();
}

class _AccountantsScreenState extends State<AccountantsScreen> {
  List<Accountant> list = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    list = await Supa.fetchAccountants();
    if (mounted) setState(() {});
  }

  Future<void> _newAccountant() async {
    final a = await showDialog<Accountant>(
      context: context,
      builder: (_) => const _AccountantDialog(),
    );
    if (a == null) return;
    // cria registo na tabela accountants (não cria utilizador Auth)
    await Supa.createAccountant(a, '');
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contabilista criado.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              const Text('Contabilistas',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Spacer(),
              FilledButton.icon(
                onPressed: _newAccountant,
                icon: const Icon(Icons.add),
                label: const Text('Novo'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text('Sem contabilistas.'))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final a = list[i];
                      return Card(
                        elevation: 0,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide.none,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.badge),
                          title: Text(a.name),
                          subtitle: Text(
                              '${a.cargo.name.toUpperCase()} • ${a.email}'),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountantDialog extends StatefulWidget {
  const _AccountantDialog();

  @override
  State<_AccountantDialog> createState() => _AccountantDialogState();
}

class _AccountantDialogState extends State<_AccountantDialog> {
  final name = TextEditingController();
  final email = TextEditingController();
  final pass = TextEditingController();
  Cargo cargo = Cargo.junior;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Contabilista'),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 8),
            DropdownButtonFormField<Cargo>(
              value: cargo,
              items: Cargo.values
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c.name.toUpperCase())))
                  .toList(),
              onChanged: (v) => setState(() => cargo = v ?? Cargo.junior),
              decoration: const InputDecoration(labelText: 'Cargo'),
            ),
            const SizedBox(height: 8),
            TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            TextField(
              controller: pass,
              decoration: const InputDecoration(
                  labelText: 'Senha (guardada apenas para referência)'),
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final a = Accountant(
                id: 'tmp',
                name: name.text.trim(),
                cargo: cargo,
                email: email.text.trim());
            Navigator.pop(context, a);
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
