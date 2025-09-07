import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'models.dart';
import 'supabase_service.dart';
import 'widgets.dart';

class TeamsScreen extends StatefulWidget {
  const TeamsScreen({super.key});
  @override
  State<TeamsScreen> createState() => _TeamsScreenState();
}

class _TeamsScreenState extends State<TeamsScreen> {
  final _picker = ImagePicker();
  List<Team> teams = [];
  List<Accountant> accountants = [];
  List<Company> companies = [];

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Supa.ensureDefaultTeams();
    teams = await Supa.fetchTeams();
    accountants = await Supa.fetchAccountants();
    companies = await Supa.fetchCompanies();
    if (mounted) setState(() {});
  }

  Future<void> _editTeam(Team t) async {
    final members = await Supa.teamMembersIds(t.id);
    final comps = await Supa.teamCompanyIds(t.id);
    final res = await showDialog<_TeamEditResult>(
      context: context,
      builder: (_) => _TeamDialog(
        team: t,
        allAccountants: accountants,
        selectedAccountantIds: members.toSet(),
        allCompanies: companies,
        selectedCompanyIds: comps.toSet(),
      ),
    );
    if (res == null) return;

    // update name/image
    t.name = res.name;
    t.imageUrl = res.imageUrl;
    await Supa.updateTeam(t);
    // members/companies
    await Supa.upsertTeamMembers(t.id, res.selectedAccountantIds.toList());
    await Supa.upsertTeamCompanies(t.id, res.selectedCompanyIds.toList());

    await _loadAll();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Equipa "${t.name}" atualizada.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Equipa',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16),
              itemCount: teams.length,
              itemBuilder: (_, i) {
                final t = teams[i];
                return InkWell(
                  onTap: () => _editTeam(t),
                  child: Card(
                    elevation: 0,
                    surfaceTintColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.outlineVariant),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              AvatarOrLogo(
                                  url: t.imageUrl, label: t.name, size: 48),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(t.name,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _editTeam(t)),
                            ],
                          ),
                          const Spacer(),
                          Wrap(
                            spacing: 8,
                            children: [
                              Chip(label: Text('Contabilistas')),
                              Chip(label: Text('Empresas')),
                            ],
                          )
                        ],
                      ),
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

class _TeamEditResult {
  final String name;
  final String? imageUrl;
  final Set<String> selectedAccountantIds;
  final Set<String> selectedCompanyIds;
  _TeamEditResult(this.name, this.imageUrl, this.selectedAccountantIds,
      this.selectedCompanyIds);
}

class _TeamDialog extends StatefulWidget {
  final Team team;
  final List<Accountant> allAccountants;
  final Set<String> selectedAccountantIds;
  final List<Company> allCompanies;
  final Set<String> selectedCompanyIds;

  const _TeamDialog({
    required this.team,
    required this.allAccountants,
    required this.selectedAccountantIds,
    required this.allCompanies,
    required this.selectedCompanyIds,
  });

  @override
  State<_TeamDialog> createState() => _TeamDialogState();
}

class _TeamDialogState extends State<_TeamDialog> {
  final _name = TextEditingController();
  String? imageUrl;

  @override
  void initState() {
    super.initState();
    _name.text = widget.team.name;
    imageUrl = widget.team.imageUrl;
  }

  Future<void> _uploadImage() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 75);
    if (x == null) return;
    final Uint8List bytes = await x.readAsBytes();
    final url =
        await Supa.uploadLogo(bytes, x.name); // reutilizamos o bucket logos
    setState(() => imageUrl = url);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Editar Equipa'),
      content: SizedBox(
        width: 840,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              AvatarOrLogo(
                  url: imageUrl,
                  label: _name.text.isEmpty ? 'E' : _name.text,
                  size: 44),
              const SizedBox(width: 8),
              Expanded(
                  child: TextField(
                      controller: _name,
                      decoration:
                          const InputDecoration(labelText: 'Nome da equipa'))),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.upload),
                  label: const Text('Imagem')),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                // Contabilistas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Contabilistas',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 260,
                        child: ListView(
                          children: [
                            for (final a in widget.allAccountants)
                              CheckboxListTile(
                                dense: true,
                                title: Text(a.name),
                                subtitle: Text(a.cargo.name.toUpperCase()),
                                value:
                                    widget.selectedAccountantIds.contains(a.id),
                                onChanged: (v) => setState(() => v!
                                    ? widget.selectedAccountantIds.add(a.id)
                                    : widget.selectedAccountantIds
                                        .remove(a.id)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Empresas
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Empresas',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: 260,
                        child: ListView(
                          children: [
                            for (final c in widget.allCompanies)
                              CheckboxListTile(
                                dense: true,
                                title: Text(c.name),
                                subtitle: Text(c.nipc),
                                value: widget.selectedCompanyIds.contains(c.id),
                                onChanged: (v) => setState(() => v!
                                    ? widget.selectedCompanyIds.add(c.id)
                                    : widget.selectedCompanyIds.remove(c.id)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
              context,
              _TeamEditResult(_name.text.trim(), imageUrl,
                  widget.selectedAccountantIds, widget.selectedCompanyIds)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
