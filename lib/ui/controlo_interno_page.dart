import 'package:flutter/material.dart';
import '../main.dart';
import '../models.dart';
import '../repository.dart';
import 'widgets.dart';

class ControloInternoPage extends StatelessWidget {
  const ControloInternoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final repo = app.repo;
    final empresas = app.visibleEmpresas();
    final ym = ymKey(app.selectedMonth);

    return AppScaffold(
      title: 'Controlo Interno — ${ym.replaceAll('-', '/')}',
      showMonthBar: true,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: empresas.isEmpty
            ? const Center(
                child: Text('Sem empresas visíveis para o seu acesso.'),
              )
            : ListView.separated(
                itemCount: empresas.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) =>
                    _EmpresaCard(emp: empresas[i], repo: repo, ym: ym),
              ),
      ),
    );
  }
}

class _EmpresaCard extends StatelessWidget {
  final Empresa emp;
  final Repository repo;
  final String ym;
  const _EmpresaCard({required this.emp, required this.repo, required this.ym});

  @override
  Widget build(BuildContext context) {
    final tasks = repo.tarefasDaEmpresa(emp.id);
    final prog = repo.progressoEmpresaMes(emp.id, ym);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(label: Text(emp.periodicidade.label)),
                const SizedBox(width: 6),
                Chip(
                  avatar: const Icon(Icons.bar_chart, size: 16),
                  label: Text(
                    '${prog.feitas}/${prog.total} feitas • ${prog.porFazer} por fazer',
                  ),
                ),
              ],
            ),
            const Divider(),
            if (tasks.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Sem tarefas atribuídas a esta empresa.'),
              )
            else
              Column(
                children: tasks
                    .map(
                      (t) => CheckboxListTile(
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(t.nome),
                        subtitle:
                            t.descricao == null ? null : Text(t.descricao!),
                        value: repo.isConcluida(emp.id, t.id, ym),
                        onChanged: (v) {
                          repo.marcarConclusao(emp.id, t.id, ym, v == true);
                          // refresh visual
                          (context as Element).markNeedsBuild();
                        },
                      ),
                    )
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
