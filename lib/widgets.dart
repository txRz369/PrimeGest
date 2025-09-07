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
    final a = accountants.firstWhere(
      (x) => x.id == id,
      orElse: () =>
          Accountant(id: '', name: '—', cargo: Cargo.junior, email: ''),
    );
    return a.id.isEmpty ? '—' : a.name;
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
                    responsibleName: _accName(ti.responsibleId),
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

class _RecapRes {
  final bool isYes;
  final DateTime? date;
  final double? amount;
  _RecapRes(this.isYes, this.date, this.amount);
}

class _RecapDialog extends StatefulWidget {
  const _RecapDialog();
  @override
  State<_RecapDialog> createState() => _RecapDialogState();
}

class _RecapDialogState extends State<_RecapDialog> {
  bool yes = true;
  DateTime? date;
  final amount = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Recapitulativa (Declaração IVA)'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
              value: yes,
              onChanged: (v) => setState(() => yes = v),
              title: const Text('Sim?')),
          if (yes) ...[
            TextField(
                controller: amount,
                decoration: const InputDecoration(labelText: 'Montante'),
                keyboardType: TextInputType.number),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () async {
                final now = DateTime.now();
                final d = await showDatePicker(
                    context: context,
                    firstDate: DateTime(now.year - 1),
                    lastDate: DateTime(now.year + 1),
                    initialDate: now);
                if (d != null) setState(() => date = d);
              },
              icon: const Icon(Icons.date_range),
              label: Text(date == null
                  ? 'Data'
                  : '${date!.day}-${date!.month}-${date!.year}'),
            ),
          ],
          const SizedBox(height: 4),
          const Text(
              'Se escolher "Não", a tarefa fica validada automaticamente.',
              style: TextStyle(fontSize: 12)),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: () {
            final amt = double.tryParse(
                amount.text.replaceAll('.', '').replaceAll(',', '.'));
            Navigator.pop(context, _RecapRes(yes, date, amt));
          },
          child: const Text('Confirmar'),
        ),
      ],
    );
  }
}

class _IVAControls extends StatefulWidget {
  final TaskInstance ti;
  final void Function(IVAEstado? estado, DateTime? data, double? montante)
      onChange;
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
  final _montanteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.ti.montante != null) {
      _montanteCtrl.text = widget.ti.montante!.toStringAsFixed(0);
    }
  }

  @override
  void didUpdateWidget(covariant _IVAControls oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.ti.montante != oldWidget.ti.montante &&
        widget.ti.montante != null) {
      _montanteCtrl.text = widget.ti.montante!.toStringAsFixed(0);
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final ti = widget.ti;

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        DropdownButton<IVAEstado>(
          value: ti.ivaEstado,
          hint: const Text('Estado IVA'),
          items: IVAEstado.values
              .map((e) => DropdownMenuItem(value: e, child: Text(_ivaLabel(e))))
              .toList(),
          onChanged: (v) {
            setState(() => ti.ivaEstado = v);
            widget.onChange(v, null, null);
          },
        ),
        if (ti.ivaEstado != null)
          Chip(
            label: Text(_ivaLabel(ti.ivaEstado!)),
            backgroundColor: _ivaColor(ti.ivaEstado!).withOpacity(0.2),
            side: BorderSide(color: _ivaColor(ti.ivaEstado!)),
          ),
        OutlinedButton.icon(
          onPressed: () async {
            final now = DateTime.now();
            final d = await showDatePicker(
                context: context,
                firstDate: DateTime(now.year - 1),
                lastDate: DateTime(now.year + 1),
                initialDate: ti.data ?? now);
            if (d != null) {
              setState(() => ti.data = d);
              widget.onChange(null, d, null);
            }
          },
          icon: const Icon(Icons.event),
          label: Text(ti.data == null
              ? 'Data'
              : '${ti.data!.day}-${ti.data!.month}-${ti.data!.year}'),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: _montanteCtrl,
            decoration: const InputDecoration(labelText: 'Montante'),
            keyboardType: TextInputType.number,
            onSubmitted: (v) {
              final parsed =
                  double.tryParse(v.replaceAll('.', '').replaceAll(',', '.'));
              if (parsed != null) {
                setState(() => ti.montante = parsed);
                widget.onChange(null, null, parsed);
              }
            },
          ),
        ),
        if (ti.recapitulativa == true && ti.montante != null)
          Chip(label: Text(_formatEuro(ti.montante))),
        OutlinedButton.icon(
          icon: const Icon(Icons.rule),
          label: const Text('Recapitulativa?'),
          onPressed: () async {
            final res = await showDialog<_RecapRes>(
              context: context,
              builder: (_) => const _RecapDialog(),
            );
            if (res == null) return;

            if (res.isYes) {
              setState(() {
                ti.recapitulativa = true;
                if (res.amount != null) ti.montante = res.amount;
                if (res.date != null) ti.data = res.date;
              });
              widget.onChange(null, res.date, res.amount);
            } else {
              setState(() => ti.recapitulativa = false);
              widget.onToggleDone();
            }
          },
        ),
      ],
    );
  }
}
