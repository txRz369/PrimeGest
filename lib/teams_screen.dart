import 'package:flutter/material.dart';
import 'models.dart';
import 'supabase_service.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});
  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  List<Team> teams = [];
  List<Accountant> accountants = [];
  List<Company> companies = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final t = await Supa.fetchTeams();
    final a = await Supa.fetchAccountants();
    final c = await Supa.fetchCompanies();
    teams = t;
    accountants = a;
    companies = c;
    if (mounted) setState(() {});
  }

  Future<void> _editTeam(Team team) async {
    final res = await showDialog<_TeamAssign>(
      context: context,
      builder: (_) => _TeamDialog(
        team: team,
        accountants: accountants,
        companies: companies,
      ),
    );
    if (res == null) return;
    await Supa.upsertTeamMembers(team.id, res.accountantIds);
    await Supa.upsertTeamCompanies(team.id, res.companyIds);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Equipa "${team.name}" atualizada.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const Text('Equipa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: teams.isEmpty
                ? const Center(child: Text('Sem equipas.'))
                : ListView.separated(
                    itemCount: teams.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final t = teams[i];
                      return Card(
                        elevation: 0,
                        surfaceTintColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide.none,
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.group),
                          title: Text(t.name),
                          trailing: IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editTeam(t),
                          ),
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

class _TeamAssign {
  final List<String> accountantIds;
  final List<String> companyIds;
  _TeamAssign(this.accountantIds, this.companyIds);
}

class _TeamDialog extends StatefulWidget {
  final Team team;
  final List<Accountant> accountants;
  final List<Company> companies;

  const _TeamDialog(
      {required this.team, required this.accountants, required this.companies});

  @override
  State<_TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends State<_TeamDialog> {
  final Set<String> accSel = {};
  final Set<String> compSel = {};

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Equipa • ${widget.team.name}'),
      content: SizedBox(
        width: 720,
        child: Row(
          children: [
            // contabilistas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contabilistas',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final a in widget.accountants)
                          CheckboxListTile(
                            dense: true,
                            title: Text(a.name),
                            subtitle: Text(a.cargo.name.toUpperCase()),
                            value: accSel.contains(a.id),
                            onChanged: (v) => setState(() =>
                                v! ? accSel.add(a.id) : accSel.remove(a.id)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // empresas
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Empresas',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final c in widget.companies)
                          CheckboxListTile(
                            dense: true,
                            title: Text(c.name),
                            subtitle: Text(c.nipc),
                            value: compSel.contains(c.id),
                            onChanged: (v) => setState(() =>
                                v! ? compSel.add(c.id) : compSel.remove(c.id)),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () => Navigator.pop(
              context, _TeamAssign(accSel.toList(), compSel.toList())),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
