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
  final Map<String, List<Accountant>> membersByTeam = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Supa.ensureDefaultTeams();
    teams = await Supa.fetchTeams();
    accountants = await Supa.fetchAccountants();

    membersByTeam.clear();
    for (final t in teams) {
      final ids = await Supa.teamMembersIds(t.id);
      final members = accountants.where((a) => ids.contains(a.id)).toList();
      membersByTeam[t.id] = members;
    }
    if (mounted) setState(() {});
  }

  Future<void> _editTeam(Team t) async {
    final selectedIds =
        (membersByTeam[t.id]?.map((e) => e.id).toSet()) ?? <String>{};

    final res = await showDialog<_TeamEditResult>(
      context: context,
      builder: (_) => _TeamDialog(
        team: t,
        allAccountants: accountants,
        selectedAccountantIds: selectedIds,
      ),
    );
    if (res == null) return;

    // update name/image
    t.name = res.name;
    t.imageUrl = res.imageUrl;
    await Supa.updateTeam(t);
    // members
    await Supa.upsertTeamMembers(t.id, res.selectedAccountantIds.toList());

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
                // cartões mais “baixinhos”
                childAspectRatio: 2.6,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
              ),
              itemCount: teams.length,
              itemBuilder: (_, i) {
                final t = teams[i];
                final members = membersByTeam[t.id] ?? const [];
                return Card(
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
                              onPressed: () => _editTeam(t),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: members.isEmpty
                              ? const Text('Sem contabilistas atribuídos.',
                                  style: TextStyle(fontSize: 12))
                              : SingleChildScrollView(
                                  child: Wrap(
                                    spacing: 6,
                                    runSpacing: 6,
                                    children: [
                                      for (final a in members)
                                        Chip(
                                          visualDensity: VisualDensity.compact,
                                          label: Text(a.name),
                                        ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
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
  _TeamEditResult(this.name, this.imageUrl, this.selectedAccountantIds);
}

class _TeamDialog extends StatefulWidget {
  final Team team;
  final List<Accountant> allAccountants;
  final Set<String> selectedAccountantIds;

  const _TeamDialog({
    required this.team,
    required this.allAccountants,
    required this.selectedAccountantIds,
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
        width: 680,
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
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Contabilistas',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ),
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
                      value: widget.selectedAccountantIds.contains(a.id),
                      onChanged: (v) => setState(() => v!
                          ? widget.selectedAccountantIds.add(a.id)
                          : widget.selectedAccountantIds.remove(a.id)),
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
              context,
              _TeamEditResult(
                  _name.text.trim(), imageUrl, widget.selectedAccountantIds)),
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
