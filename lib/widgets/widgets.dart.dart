// lib/widgets.dart
import 'package:flutter/material.dart';
import 'models.dart';

/// Picker simples de Mês/Ano (em memória).
class MonthYearPicker extends StatelessWidget {
  final int year;
  final int month; // 1-12
  final void Function(int year, int month) onChanged;

  const MonthYearPicker({
    super.key,
    required this.year,
    required this.month,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final years = List<int>.generate(7, (i) => DateTime.now().year - 3 + i);
    final months = List<int>.generate(12, (i) => i + 1);

    return Wrap(
      spacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Icon(Icons.calendar_month),
        DropdownButton<int>(
          value: month,
          onChanged: (v) => v == null ? null : onChanged(year, v),
          items: months
              .map(
                (m) => DropdownMenuItem(
                  value: m,
                  child: Text(m.toString().padLeft(2, '0')),
                ),
              )
              .toList(),
        ),
        DropdownButton<int>(
          value: year,
          onChanged: (v) => v == null ? null : onChanged(v, month),
          items: years
              .map((y) => DropdownMenuItem(value: y, child: Text(y.toString())))
              .toList(),
        ),
      ],
    );
  }
}

/// Lista de tarefas com checkboxes e descrição opcional.
class TaskChecklist extends StatelessWidget {
  final List<Task> tasks;
  final Set<String> doneIds;
  final void Function(String taskId) onToggle;

  const TaskChecklist({
    super.key,
    required this.tasks,
    required this.doneIds,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12.0),
        child: Text('Sem tarefas atribuídas.'),
      );
    }
    return Column(
      children: tasks
          .map(
            (t) => CheckboxListTile(
              value: doneIds.contains(t.id),
              onChanged: (_) => onToggle(t.id),
              title: Text(t.nome),
              subtitle: t.descricao == null ? null : Text(t.descricao!),
            ),
          )
          .toList(),
    );
  }
}
