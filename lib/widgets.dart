import 'package:flutter/material.dart';
import 'models.dart';
import 'supabase_service.dart';

/// -------------------- InfoBox --------------------
class InfoBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  const InfoBox(
      {super.key,
      required this.title,
      required this.value,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, size: 28),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// -------------------- Novo YearMonthPicker --------------------
class YearMonthPickerButton extends StatelessWidget {
  final DateTime initial;
  final ValueChanged<DateTime> onChanged;
  const YearMonthPickerButton(
      {super.key, required this.initial, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final text =
        '${initial.year.toString()}  •  ${initial.month.toString().padLeft(2, '0')}';
    return OutlinedButton.icon(
      icon: const Icon(Icons.event),
      label: Text(text),
      onPressed: () async {
        final picked = await showDialog<DateTime>(
          context: context,
          builder: (_) => _YearMonthDialog(initial: initial),
        );
        if (picked != null) onChanged(picked);
      },
    );
  }
}

class _YearMonthDialog extends StatefulWidget {
  final DateTime initial;
  const _YearMonthDialog({required this.initial});
  @override
  State<_YearMonthDialog> createState() => _YearMonthDialogState();
}

class _YearMonthDialogState extends State<_YearMonthDialog> {
  late int year = widget.initial.year;

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) => i + 1);
    return AlertDialog(
      title: Row(
        children: [
          IconButton(
              onPressed: () => setState(() => year--),
              icon: const Icon(Icons.chevron_left)),
          Expanded(
              child: Center(
                  child: Text('$year',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)))),
          IconButton(
              onPressed: () => setState(() => year++),
              icon: const Icon(Icons.chevron_right)),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in months)
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, DateTime(year, m, 1)),
                child: SizedBox(
                    width: 70,
                    child: Center(child: Text(m.toString().padLeft(2, '0')))),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
      ],
    );
  }
}

/// -------------------- Avatar/Logo --------------------
class AvatarOrLogo extends StatelessWidget {
  final String? url;
  final String label;
  final double size;
  const AvatarOrLogo(
      {super.key, required this.url, required this.label, this.size = 36});
  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) {
      return CircleAvatar(
          radius: size / 2,
          child: Text(label.isNotEmpty ? label[0].toUpperCase() : '?'));
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 4),
      child: Image.network(url!, width: size, height: size, fit: BoxFit.cover),
    );
  }
}

/// -------------------- CompanyCard + IVA controls --------------------
class CompanyCard extends StatefulWidget {
  final Company company;
  final List<TaskInstance> monthInstances;
  final int year;
  final int month;
  final void Function(TaskInstance) onToggleTask;
  // mantemos a assinatura, mas o controlo IVA grava direto via Supa
  final void Function(TaskInstance,
      {IVAEstado? estado, DateTime? data, double? montante}) onIVAChange;
  final Brightness brightness;

  const CompanyCard({
    super.key,
    required this.company,
    required this.monthInstances,
    required this.year,
    required this.month,
    required this.onToggleTask,
    required this.onIVAChange,
    required this.brightness,
  });

  @override
  State<CompanyCard> createState() => _CompanyCardState();
}

class _CompanyCardState extends State<CompanyCard> {
  bool expanded = false;
  List<Accountant> accountants = [];

  @override
  void initState() {
    super.initState();
    _loadAcc();
  }

  Future<void> _loadAcc() async {
    accountants = await Supa.fetchAccountants();
    if (mounted) setState(() {});
  }

  String _accName(String? id) {
    if (id == null || id.isEmpty) return '—';
    final a = accountants.firstWhere(
      (x) => x.id == id,
      orElse: () =>
          Accountant(id: '', name: '—', cargo: Cargo.junior, email: ''),
    );
    return a.id.isEmpty ? '—' : a.name;
  }

  String _resolvedResponsible(TaskInstance ti) {
    return _accName(
        ti.responsibleId ?? widget.company.taskResponsibleByKey[ti.taskKey]);
  }

  @override
  Widget build(BuildContext context) {
    final doneCount = widget.monthInstances.where((i) => i.done).length;
    return Card(
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide.none,
      ),
      child: ExpansionTile(
        dense: true,
        initiallyExpanded: expanded,
        onExpansionChanged: (v) => setState(() => expanded = v),
        leading: AvatarOrLogo(
            url: widget.company.logoUrl, label: widget.company.name),
        title: Text(widget.company.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            'Imp: ${widget.company.importance} • ${widget.company.nipc} • ${widget.company.periodicidade.name.toUpperCase()}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.task_alt, size: 18),
            const SizedBox(width: 4),
            Text('$doneCount/${widget.monthInstances.length}'),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12, right: 12, bottom: 12),
            child: Column(
              children: [
                for (final ti in widget.monthInstances)
                  _TaskRow(
                    ti: ti,
                    responsibleName: _resolvedResponsible(ti),
                    brightness: widget.brightness,
                    onToggle: () => widget.onToggleTask(ti),
                    onIVAChange: (estado, data, montante) => widget.onIVAChange(
                        ti,
                        estado: estado,
                        data: data,
                        montante: montante),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final TaskInstance ti;
  final String responsibleName;
  final VoidCallback onToggle;
  final void Function(IVAEstado? estado, DateTime? data, double? montante)
      onIVAChange;
  final Brightness brightness;

  const _TaskRow({
    required this.ti,
    required this.responsibleName,
    required this.onToggle,
    required this.onIVAChange,
    required this.brightness,
  });

  @override
  Widget build(BuildContext context) {
    final def = defaultTaskByKey(ti.taskKey);
    final isIVA = def?.isIVA == true;
    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(def?.name ?? ti.taskKey),
      leading: Checkbox(value: ti.done, onChanged: (_) => onToggle()),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(label: Text(responsibleName)),
          if (isIVA)
            _IVAControls(
              ti: ti,
              onChange: onIVAChange,
              onToggleDone: onToggle,
              brightness: brightness,
            ),
        ],
      ),
    );
  }
}

/// =================== IVA (campos independentes) ===================
class _IVAControls extends StatefulWidget {
  final TaskInstance ti;
  final void Function(IVAEstado? estado, DateTime? data, double? montante)
      onChange; // mantido para não quebrar assinaturas externas
  final VoidCallback onToggleDone;
  final Brightness brightness;
  const _IVAControls(
      {required this.ti,
      required this.onChange,
      required this.onToggleDone,
      required this.brightness});

  @override
  State<_IVAControls> createState() => _IVAControlsState();
}

class _IVAControlsState extends State<_IVAControls> {
  String _ivaLabel(IVAEstado s) {
    switch (s) {
      case IVAEstado.aPagar:
        return 'A Pagar';
      case IVAEstado.planoPagar:
        return 'Plano (Pagar)';
      case IVAEstado.recuperar:
        return 'Recuperar';
      case IVAEstado.reembolso:
        return 'Reembolso';
      case IVAEstado.reportar:
        return 'Reportar';
      case IVAEstado.naoTemIVA:
        return 'Não tem IVA';
      case IVAEstado.enviado:
        return 'Enviado';
      case IVAEstado.cessada:
        return 'Cessada';
    }
  }

  Color _ivaColor(IVAEstado s) => colorForIVA(s, widget.brightness);

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  String _formatEuro(num? n) {
    if (n == null) return '';
    final neg = n < 0;
    var s = n.abs().toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromRight = s.length - i;
      buf.write(s[i]);
      final isThousandBoundary = idxFromRight > 1 && idxFromRight % 3 == 1;
      if (isThousandBoundary) buf.write('.');
    }
    final formatted = buf.toString();
    return '${neg ? '-' : ''}$formatted €';
  }

  Widget _pill(String text, {IconData? icon, Color? color}) {
    return Chip(
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(text),
      backgroundColor: (color ?? Colors.transparent).withOpacity(
        color == null ? 0 : 0.15,
      ),
      side: BorderSide(color: color ?? Colors.transparent),
      visualDensity: VisualDensity.compact,
    );
  }

  Future<void> _openDialog() async {
    final ti = widget.ti;

    final result = await showDialog<_IVADialogResult>(
      context: context,
      builder: (_) => _IVADialog(
        initialEstado: ti.ivaEstado,
        initialPeriodicDate: ti.periodicDate,
        initialPeriodicAmount: ti.periodicMontante,
        initialRecapYes: ti.recapitulativa ??
            (ti.recapDate != null || ti.recapMontante != null),
        initialRecapDate: ti.recapDate,
        initialRecapAmount: ti.recapMontante,
      ),
    );

    if (result == null) return;

    // Atualiza o modelo em memória
    setState(() {
      ti.ivaEstado = result.estado ?? ti.ivaEstado;
      ti.periodicDate = result.periodicDate;
      ti.periodicMontante = result.periodicAmount;
      ti.recapitulativa = result.recapYes;
      ti.recapDate = result.recapYes ? result.recapDate : null;
      ti.recapMontante = result.recapYes ? result.recapAmount : null;

      // também manter os campos legados em linha com Periódica (compat)
      ti.data = ti.periodicDate;
      ti.montante = ti.periodicMontante;
    });

    // Persiste diretamente (inclui todos os campos novos)
    await Supa.upsertInstance(ti);

    // Notifica pai (apenas com estado para não quebrar chamadas antigas)
    widget.onChange(ti.ivaEstado, null, null);
  }

  bool get _hasAnyConfig =>
      widget.ti.ivaEstado != null ||
      widget.ti.periodicDate != null ||
      widget.ti.periodicMontante != null ||
      widget.ti.recapDate != null ||
      widget.ti.recapMontante != null ||
      widget.ti.recapitulativa == true;

  @override
  Widget build(BuildContext context) {
    final ti = widget.ti;

    final actionBtn = OutlinedButton(
      onPressed: _openDialog,
      child: Text(_hasAnyConfig ? 'Alterar' : 'Configurar'),
    );

    if (!_hasAnyConfig) return actionBtn;

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _pill('Periódica', icon: Icons.assignment_turned_in),
        if (ti.ivaEstado != null)
          _pill(_ivaLabel(ti.ivaEstado!), color: _ivaColor(ti.ivaEstado!)),
        if (ti.periodicDate != null)
          _pill(_fmtDate(ti.periodicDate!), icon: Icons.event),
        if (ti.periodicMontante != null)
          _pill(_formatEuro(ti.periodicMontante!), icon: Icons.euro),
        const SizedBox(width: 6),
        _pill('Recapitulativa', icon: Icons.rule),
        if (ti.recapitulativa == true && ti.recapDate != null)
          _pill(_fmtDate(ti.recapDate!), icon: Icons.event),
        if (ti.recapitulativa == true && ti.recapMontante != null)
          _pill(_formatEuro(ti.recapMontante!), icon: Icons.euro),
        actionBtn,
      ],
    );
  }
}

class _IVADialogResult {
  final IVAEstado? estado;
  final DateTime? periodicDate;
  final double? periodicAmount;
  final bool recapYes;
  final DateTime? recapDate;
  final double? recapAmount;

  _IVADialogResult({
    required this.estado,
    required this.periodicDate,
    required this.periodicAmount,
    required this.recapYes,
    required this.recapDate,
    required this.recapAmount,
  });
}

class _IVADialog extends StatefulWidget {
  final IVAEstado? initialEstado;

  final DateTime? initialPeriodicDate;
  final double? initialPeriodicAmount;

  final bool initialRecapYes;
  final DateTime? initialRecapDate;
  final double? initialRecapAmount;

  const _IVADialog({
    required this.initialEstado,
    required this.initialPeriodicDate,
    required this.initialPeriodicAmount,
    required this.initialRecapYes,
    required this.initialRecapDate,
    required this.initialRecapAmount,
  });

  @override
  State<_IVADialog> createState() => _IVADialogState();
}

class _IVADialogState extends State<_IVADialog> {
  IVAEstado? estado;

  DateTime? periodicDate;
  final periodicAmountCtrl = TextEditingController();

  bool recapYes = false;
  DateTime? recapDate;
  final recapAmountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    estado = widget.initialEstado;

    periodicDate = widget.initialPeriodicDate;
    if (widget.initialPeriodicAmount != null) {
      periodicAmountCtrl.text =
          widget.initialPeriodicAmount!.toStringAsFixed(0);
    }

    recapYes = widget.initialRecapYes;
    recapDate = widget.initialRecapDate;
    if (widget.initialRecapAmount != null) {
      recapAmountCtrl.text = widget.initialRecapAmount!.toStringAsFixed(0);
    }
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  double? _parseEuro(String s) =>
      double.tryParse(s.replaceAll('.', '').replaceAll(',', '.'));

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurar Declaração de IVA'),
      content: SizedBox(
        width: 760,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // -------- Periódica --------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Declaração Periódica de IVA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<IVAEstado>(
                      value: estado,
                      items: IVAEstado.values
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(_labelEstado(e))))
                          .toList(),
                      onChanged: (v) => setState(() => estado = v),
                      decoration: const InputDecoration(
                          labelText: 'Pagar / reembolso / etc.'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              final now = DateTime.now();
                              final d = await showDatePicker(
                                context: context,
                                firstDate: DateTime(now.year - 1),
                                lastDate: DateTime(now.year + 1),
                                initialDate: periodicDate ?? now,
                              );
                              if (d != null) setState(() => periodicDate = d);
                            },
                            icon: const Icon(Icons.event),
                            label: Text(periodicDate == null
                                ? 'Data (Periódica)'
                                : _fmtDate(periodicDate!)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: periodicAmountCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                labelText: 'Montante Periódica (€)'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // -------- Recapitulativa --------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Declaração Recapitulativa de IVA',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('SIM?'),
                      value: recapYes,
                      onChanged: (v) => setState(() => recapYes = v),
                    ),
                    if (recapYes) ...[
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final now = DateTime.now();
                                final d = await showDatePicker(
                                  context: context,
                                  firstDate: DateTime(now.year - 1),
                                  lastDate: DateTime(now.year + 1),
                                  initialDate: recapDate ?? now,
                                );
                                if (d != null) setState(() => recapDate = d);
                              },
                              icon: const Icon(Icons.event),
                              label: Text(recapDate == null
                                  ? 'Data (Recapitulativa)'
                                  : _fmtDate(recapDate!)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: recapAmountCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Montante Recapitulativa (€)'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Se SIM, preencha data e montante; se NÃO, estes campos são ignorados.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final periodicAmount = _parseEuro(periodicAmountCtrl.text);
            final recapAmount = _parseEuro(recapAmountCtrl.text);

            Navigator.pop(
              context,
              _IVADialogResult(
                estado: estado,
                periodicDate: periodicDate,
                periodicAmount: periodicAmount,
                recapYes: recapYes,
                recapDate: recapDate,
                recapAmount: recapAmount,
              ),
            );
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  String _labelEstado(IVAEstado e) {
    switch (e) {
      case IVAEstado.aPagar:
        return 'A Pagar';
      case IVAEstado.planoPagar:
        return 'Plano (Pagar)';
      case IVAEstado.recuperar:
        return 'Recuperar';
      case IVAEstado.reembolso:
        return 'Reembolso';
      case IVAEstado.reportar:
        return 'Reportar';
      case IVAEstado.naoTemIVA:
        return 'Não tem IVA';
      case IVAEstado.enviado:
        return 'Enviado';
      case IVAEstado.cessada:
        return 'Cessada';
    }
  }
}
