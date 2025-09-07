import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import '../repository.dart';
import 'widgets.dart';

enum _TaskFilter { todas, pendentes, concluidas }

class ControloInternoPage extends StatefulWidget {
  const ControloInternoPage({super.key});

  @override
  State<ControloInternoPage> createState() => _ControloInternoPageState();
}

class _ControloInternoPageState extends State<ControloInternoPage> {
  String q = '';
  _TaskFilter filtro = _TaskFilter.todas;
  bool soPendentes = false; // “controlo” rápido

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final repo = app.repo;
    final empresasAll = app.visibleEmpresas();
    final ym = ymKey(app.selectedMonth);

    // Pesquisa por nome/NIF
    final empresas = empresasAll
        .where((e) =>
            e.nome.toLowerCase().contains(q.toLowerCase()) || e.nif.contains(q))
        .toList();

    // KPIs (podem ser 0/0 na 1ª renderização; atualizam à medida que as caches carregam)
    int totalTasks = 0;
    int totalFeitas = 0;
    for (final e in empresas) {
      final tasks = repo.tarefasDaEmpresa(e.id);
      totalTasks += tasks.length;
      for (final t in tasks) {
        if (repo.isConcluida(e.id, t.id, ym)) totalFeitas++;
      }
    }
    final double pct = totalTasks == 0 ? 0 : totalFeitas / totalTasks;

    return AppScaffold(
      title: '', // sem título — AppBar mostra o logotipo (widgets.dart)
      showMonthBar: true,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: empresas.isEmpty
            ? const _EmptyState()
            : Column(
                children: [
                  // Barra de pesquisa + “controlo” rápido
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.search),
                            hintText: 'Procurar empresa por nome/NIF',
                          ),
                          onChanged: (v) => setState(() => q = v),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // “Controlo” rápido: alternar só pendentes
                      Tooltip(
                        message: 'Mostrar apenas pendentes',
                        child: FilterChip(
                          label: const Text('Só pendentes'),
                          avatar: const Icon(Icons.hourglass_bottom, size: 18),
                          selected: soPendentes,
                          onSelected: (v) => setState(() => soPendentes = v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filtros em chips (todas/pendentes/concluídas)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      children: [
                        ChoiceChip(
                          label: const Text('Todas'),
                          selected: filtro == _TaskFilter.todas,
                          onSelected: (_) =>
                              setState(() => filtro = _TaskFilter.todas),
                        ),
                        ChoiceChip(
                          label: const Text('Pendentes'),
                          selected: filtro == _TaskFilter.pendentes,
                          onSelected: (_) =>
                              setState(() => filtro = _TaskFilter.pendentes),
                        ),
                        ChoiceChip(
                          label: const Text('Concluídas'),
                          selected: filtro == _TaskFilter.concluidas,
                          onSelected: (_) =>
                              setState(() => filtro = _TaskFilter.concluidas),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // KPI cards
                  SizedBox(
                    height: 96,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _KpiCard(
                          icon: Icons.domain,
                          label: 'Empresas',
                          value: empresas.length.toString(),
                        ),
                        _KpiCard(
                          icon: Icons.task_alt,
                          label: 'Tarefas feitas',
                          value: '$totalFeitas',
                          subtitle: totalTasks == 0
                              ? '—'
                              : 'de $totalTasks (${(pct * 100).toStringAsFixed(0)}%)',
                          trailing: LinearProgressIndicator(
                            value: pct.clamp(0, 1),
                          ),
                        ),
                        _KpiCard(
                          icon: Icons.pending_actions,
                          label: 'Pendentes',
                          value: (totalTasks - totalFeitas).toString(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Lista
                  Expanded(
                    child: ListView.separated(
                      itemCount: empresas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _EmpresaCard(
                        emp: empresas[i],
                        repo: repo,
                        ym: ym,
                        filtro: soPendentes ? _TaskFilter.pendentes : filtro,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String? subtitle;
  final Widget? trailing;
  const _KpiCard({
    required this.icon,
    required this.label,
    required this.value,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 260,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        color: cs.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(label, style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w700)),
                ],
              ),
              if (subtitle != null || trailing != null) ...[
                const SizedBox(height: 6),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                if (trailing != null) ...[
                  const SizedBox(height: 6),
                  trailing!,
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EmpresaCard extends StatelessWidget {
  final Empresa emp;
  final Repository repo;
  final String ym;
  final _TaskFilter filtro;

  const _EmpresaCard({
    required this.emp,
    required this.repo,
    required this.ym,
    required this.filtro,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = repo.tarefasDaEmpresa(emp.id);
    final feitas = tasks.where((t) => repo.isConcluida(emp.id, t.id, ym));
    final porFazer = tasks.length - feitas.length;
    final p = tasks.isEmpty ? 0.0 : feitas.length / tasks.length;

    ImageProvider? logo;
    if (emp.logoUrl != null && emp.logoUrl!.isNotEmpty) {
      logo = NetworkImage(emp.logoUrl!);
    }

    // aplica o filtro escolhido
    List<Tarefa> list = tasks;
    if (filtro == _TaskFilter.pendentes) {
      list = tasks.where((t) => !repo.isConcluida(emp.id, t.id, ym)).toList();
    } else if (filtro == _TaskFilter.concluidas) {
      list = tasks.where((t) => repo.isConcluida(emp.id, t.id, ym)).toList();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 8),
          leading: CircleAvatar(
            backgroundImage: logo,
            child: logo == null ? const Icon(Icons.apartment) : null,
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  '${emp.nome}  •  ${emp.nif}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              ImportanciaPill(emp.importancia),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    label: Text(emp.periodicidade.label),
                  ),
                  const SizedBox(width: 6),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.bar_chart, size: 16),
                    label: Text(
                      '${feitas.length}/${tasks.length} feitas • $porFazer por fazer',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: p.clamp(0, 1)),
              const SizedBox(height: 6),
            ],
          ),
          childrenPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
          children: [
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Sem tarefas para mostrar.'),
              )
            else
              Material(
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                child: ListView.separated(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final t = list[i];
                    final checked = repo.isConcluida(emp.id, t.id, ym);
                    return CheckboxListTile(
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(t.nome),
                      subtitle: t.descricao == null ? null : Text(t.descricao!),
                      value: checked,
                      onChanged: (v) {
                        repo.marcarConclusao(emp.id, t.id, ym, v == true);
                        // refresca esta ExpansionTile
                        (context as Element).markNeedsBuild();
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 48, color: cs.primary),
          const SizedBox(height: 8),
          Text(
            'Sem empresas visíveis para o seu acesso.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Crie uma empresa e atribua-a a uma equipa onde o contabilista pertença.',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
