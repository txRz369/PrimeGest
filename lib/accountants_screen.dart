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

  Future<void> _newAcc() async {
    final res = await showDialog<_AccResult>(
      context: context,
      builder: (_) => const _AccDialog(),
    );
    if (res != null) {
      await Supa.createAccountant(Accountant(
        id: '',
        name: res.name,
        cargo: res.cargo,
        email: res.email,
      ));
      await _load();
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
                onPressed: _newAcc,
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
                        child: ListTile(
                          leading: CircleAvatar(
                              child: Text(a.name.isEmpty ? 'C' : a.name[0])),
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

class _AccResult {
  final String name;
  final String email;
  final Cargo cargo;
  _AccResult(this.name, this.email, this.cargo);
}

class _AccDialog extends StatefulWidget {
  const _AccDialog();

  @override
  State<_AccDialog> createState() => _AccDialogState();
}

class _AccDialogState extends State<_AccDialog> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  Cargo _cargo = Cargo.junior;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo Contabilista'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Nome')),
            const SizedBox(height: 8),
            TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 8),
            DropdownButtonFormField<Cargo>(
              value: _cargo,
              items: Cargo.values
                  .map((c) => DropdownMenuItem(
                      value: c, child: Text(c.name.toUpperCase())))
                  .toList(),
              onChanged: (v) => setState(() => _cargo = v ?? Cargo.junior),
              decoration: const InputDecoration(labelText: 'Cargo'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(context,
              _AccResult(_name.text.trim(), _email.text.trim(), _cargo)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
