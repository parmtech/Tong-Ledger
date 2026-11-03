import 'package:flutter/material.dart';

import '../../domain/budget_plan.dart';
import '../../domain/money.dart';

/// Independent budget editor; persistence is performed through onSave.
class BudgetEditorPage extends StatefulWidget {
  const BudgetEditorPage({
    super.key, required this.initial, required this.onSave,
  });
  final BudgetPlan initial;
  final Future<bool> Function(BudgetPlan) onSave;

  @override
  State<BudgetEditorPage> createState() => _BudgetEditorPageState();
}

class _CategoryDraft {
  _CategoryDraft(String title, String amount)
      : title = TextEditingController(text: title),
        amount = TextEditingController(text: amount);
  final TextEditingController title;
  final TextEditingController amount;
  void dispose() {
    title.dispose();
    amount.dispose();
  }
}

class _BudgetEditorPageState extends State<BudgetEditorPage> {
  static const _gold = Color(0xFFC8AE7D);
  late final TextEditingController _name;
  late final TextEditingController _income;
  late final List<_CategoryDraft> _rows;
  late BudgetPeriod _period;
  late DateTime _start;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final plan = widget.initial;
    _name = TextEditingController(text: plan.name);
    _income = TextEditingController(
      text: Money(plan.incomeCents).aud
          .replaceFirst(r'A
    _period = plan.period;
    _start = plan.startDate;
    _rows = [
      for (final a in plan.allocations)
        _newRow(a.category, Money(a.plannedCents).aud
            .replaceAll(r'A$', '').replaceAll(',', '')),
    ];
    _income.addListener(_refresh);
  }

  _CategoryDraft _newRow(String title, String amount) {
    final result = _CategoryDraft(title, amount);
    result.amount.addListener(_refresh);
    return result;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  BudgetPlan _read() {
    final income = Money.tryParse(_income.text);
    if (income == null || income.cents < 0) {
      throw const FormatException('Enter a valid planned income.');
    }
    final categories = <BudgetAllocation>[];
    for (final row in _rows) {
      final amount = Money.tryParse(row.amount.text);
      if (amount == null || amount.cents < 0) {
        throw const FormatException('Each category needs a valid AUD amount.');
      }
      categories.add(BudgetAllocation(
        category: row.title.text.trim(), plannedCents: amount.cents,
      ));
    }
    final result = BudgetPlan(
      id: widget.initial.id, name: _name.text.trim(),
      incomeCents: income.cents, period: _period, startDate: _start,
      templateId: widget.initial.templateId, allocations: categories,
    );
    result.validate();
    return result;
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _start = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    if (_saving) return;
    BudgetPlan plan;
    try {
      plan = _read();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    if (plan.isOverallocated) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Budget exceeds income'),
          content: Text('Your allocations exceed income by '
              '${Money(-plan.unallocatedCents).aud}. Save anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Adjust'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Save with warning'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final success = await widget.onSave(plan);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Save failed. Your edits are still here.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    BudgetPlan? preview;
    try {
      preview = _read();
    } on FormatException {
      // Partial field values will be validated on save.
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Editor'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check), label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('YOUR PERSONAL BUDGET',
              style: TextStyle(color: _gold, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            TextField(
              controller: _name, maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Budget name', border: OutlineInputBorder()),
            ),
            TextField(
              controller: _income,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Planned income', prefixText: r'A$ ',
                border: OutlineInputBorder(),
                helperText: 'Budgeting does not change real account balances.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BudgetPeriod>(
              initialValue: _period,
              decoration: const InputDecoration(
                labelText: 'Pay / budget cycle', border: OutlineInputBorder()),
              items: [
                for (final item in BudgetPeriod.values)
                  DropdownMenuItem(value: item, child: Text(item.name)),
              ],
              onChanged: _saving ? null : (value) {
                if (value != null) setState(() => _period = value);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: _gold),
              title: const Text('Cycle start date'),
              subtitle: Text('${_start.day}/${_start.month}/${_start.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _saving ? null : _changeDate,
            ),
            Card(
              color: const Color(0xFF1B2633),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALLOCATION OVERVIEW',
                      style: TextStyle(color: _gold)),
                    const SizedBox(height: 8),
                    Text('Allocated: ${preview == null ? "—" : Money(preview.allocatedCents).aud}'),
                    Text('Remaining: ${preview == null ? "—" : Money(preview.unallocatedCents).aud}'),
                    if (preview?.isOverallocated ?? false)
                      const Text('Warning: allocations exceed planned income.',
                        style: TextStyle(color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Categories',
                  style: Theme.of(context).textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: _saving || _rows.length >= 100 ? null : () {
                    setState(() => _rows.add(_newRow('New category', '0.00')));
                  },
                  icon: const Icon(Icons.add), label: const Text('Add'),
                ),
              ],
            ),
            for (var index = 0; index < _rows.length; index++)
              Padding(
                key: ObjectKey(_rows[index]),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _rows[index].title,
                        decoration: const InputDecoration(
                          labelText: 'Category', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rows[index].amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'AUD', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove category', icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () {
                        final removed = _rows.removeAt(index);
                        removed.dispose();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_error!,
                  style: const TextStyle(color: Colors.orangeAccent)),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.lock_outline),
              label: Text(_saving ? 'Saving…' : 'Save my budget'),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
, '').replaceAll(',', ''),
    );
    _period = plan.period;
    _start = plan.startDate;
    _rows = [
      for (final a in plan.allocations)
        _newRow(a.category, Money(a.plannedCents).aud
            .replaceAll('A$', '').replaceAll(',', '')),
    ];
    _income.addListener(_refresh);
  }

  _CategoryDraft _newRow(String title, String amount) {
    final result = _CategoryDraft(title, amount);
    result.amount.addListener(_refresh);
    return result;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  BudgetPlan _read() {
    final income = Money.tryParse(_income.text);
    if (income == null || income.cents < 0) {
      throw const FormatException('Enter a valid planned income.');
    }
    final categories = <BudgetAllocation>[];
    for (final row in _rows) {
      final amount = Money.tryParse(row.amount.text);
      if (amount == null || amount.cents < 0) {
        throw const FormatException('Each category needs a valid AUD amount.');
      }
      categories.add(BudgetAllocation(
        category: row.title.text.trim(), plannedCents: amount.cents,
      ));
    }
    final result = BudgetPlan(
      id: widget.initial.id, name: _name.text.trim(),
      incomeCents: income.cents, period: _period, startDate: _start,
      templateId: widget.initial.templateId, allocations: categories,
    );
    result.validate();
    return result;
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _start = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    if (_saving) return;
    BudgetPlan plan;
    try {
      plan = _read();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    if (plan.isOverallocated) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Budget exceeds income'),
          content: Text('Your allocations exceed income by '
              '${Money(-plan.unallocatedCents).aud}. Save anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Adjust'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Save with warning'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final success = await widget.onSave(plan);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Save failed. Your edits are still here.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    BudgetPlan? preview;
    try {
      preview = _read();
    } on FormatException {
      // Partial field values will be validated on save.
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Editor'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check), label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('YOUR PERSONAL BUDGET',
              style: TextStyle(color: _gold, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            TextField(
              controller: _name, maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Budget name', border: OutlineInputBorder()),
            ),
            TextField(
              controller: _income,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Planned income', prefixText: 'A$ ',
                border: OutlineInputBorder(),
                helperText: 'Budgeting does not change real account balances.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BudgetPeriod>(
              initialValue: _period,
              decoration: const InputDecoration(
                labelText: 'Pay / budget cycle', border: OutlineInputBorder()),
              items: [
                for (final item in BudgetPeriod.values)
                  DropdownMenuItem(value: item, child: Text(item.name)),
              ],
              onChanged: _saving ? null : (value) {
                if (value != null) setState(() => _period = value);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: _gold),
              title: const Text('Cycle start date'),
              subtitle: Text('${_start.day}/${_start.month}/${_start.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _saving ? null : _changeDate,
            ),
            Card(
              color: const Color(0xFF1B2633),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALLOCATION OVERVIEW',
                      style: TextStyle(color: _gold)),
                    const SizedBox(height: 8),
                    Text('Allocated: ${preview == null ? "—" : Money(preview.allocatedCents).aud}'),
                    Text('Remaining: ${preview == null ? "—" : Money(preview.unallocatedCents).aud}'),
                    if (preview?.isOverallocated ?? false)
                      const Text('Warning: allocations exceed planned income.',
                        style: TextStyle(color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Categories',
                  style: Theme.of(context).textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: _saving || _rows.length >= 100 ? null : () {
                    setState(() => _rows.add(_newRow('New category', '0.00')));
                  },
                  icon: const Icon(Icons.add), label: const Text('Add'),
                ),
              ],
            ),
            for (var index = 0; index < _rows.length; index++)
              Padding(
                key: ObjectKey(_rows[index]),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _rows[index].title,
                        decoration: const InputDecoration(
                          labelText: 'Category', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rows[index].amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'AUD', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove category', icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () {
                        final removed = _rows.removeAt(index);
                        removed.dispose();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_error!,
                  style: const TextStyle(color: Colors.orangeAccent)),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.lock_outline),
              label: Text(_saving ? 'Saving…' : 'Save my budget'),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
, '').replaceAll(',', '')),
    ];
    _income.addListener(_refresh);
  }

  _CategoryDraft _newRow(String title, String amount) {
    final result = _CategoryDraft(title, amount);
    result.amount.addListener(_refresh);
    return result;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  BudgetPlan _read() {
    final income = Money.tryParse(_income.text);
    if (income == null || income.cents < 0) {
      throw const FormatException('Enter a valid planned income.');
    }
    final categories = <BudgetAllocation>[];
    for (final row in _rows) {
      final amount = Money.tryParse(row.amount.text);
      if (amount == null || amount.cents < 0) {
        throw const FormatException('Each category needs a valid AUD amount.');
      }
      categories.add(BudgetAllocation(
        category: row.title.text.trim(), plannedCents: amount.cents,
      ));
    }
    final result = BudgetPlan(
      id: widget.initial.id, name: _name.text.trim(),
      incomeCents: income.cents, period: _period, startDate: _start,
      templateId: widget.initial.templateId, allocations: categories,
    );
    result.validate();
    return result;
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _start = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    if (_saving) return;
    BudgetPlan plan;
    try {
      plan = _read();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    if (plan.isOverallocated) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Budget exceeds income'),
          content: Text('Your allocations exceed income by '
              '${Money(-plan.unallocatedCents).aud}. Save anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Adjust'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Save with warning'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final success = await widget.onSave(plan);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Save failed. Your edits are still here.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    BudgetPlan? preview;
    try {
      preview = _read();
    } on FormatException {
      // Partial field values will be validated on save.
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Editor'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check), label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('YOUR PERSONAL BUDGET',
              style: TextStyle(color: _gold, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            TextField(
              controller: _name, maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Budget name', border: OutlineInputBorder()),
            ),
            TextField(
              controller: _income,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Planned income', prefixText: 'A$ ',
                border: OutlineInputBorder(),
                helperText: 'Budgeting does not change real account balances.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BudgetPeriod>(
              initialValue: _period,
              decoration: const InputDecoration(
                labelText: 'Pay / budget cycle', border: OutlineInputBorder()),
              items: [
                for (final item in BudgetPeriod.values)
                  DropdownMenuItem(value: item, child: Text(item.name)),
              ],
              onChanged: _saving ? null : (value) {
                if (value != null) setState(() => _period = value);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: _gold),
              title: const Text('Cycle start date'),
              subtitle: Text('${_start.day}/${_start.month}/${_start.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _saving ? null : _changeDate,
            ),
            Card(
              color: const Color(0xFF1B2633),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALLOCATION OVERVIEW',
                      style: TextStyle(color: _gold)),
                    const SizedBox(height: 8),
                    Text('Allocated: ${preview == null ? "—" : Money(preview.allocatedCents).aud}'),
                    Text('Remaining: ${preview == null ? "—" : Money(preview.unallocatedCents).aud}'),
                    if (preview?.isOverallocated ?? false)
                      const Text('Warning: allocations exceed planned income.',
                        style: TextStyle(color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Categories',
                  style: Theme.of(context).textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: _saving || _rows.length >= 100 ? null : () {
                    setState(() => _rows.add(_newRow('New category', '0.00')));
                  },
                  icon: const Icon(Icons.add), label: const Text('Add'),
                ),
              ],
            ),
            for (var index = 0; index < _rows.length; index++)
              Padding(
                key: ObjectKey(_rows[index]),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _rows[index].title,
                        decoration: const InputDecoration(
                          labelText: 'Category', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rows[index].amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'AUD', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove category', icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () {
                        final removed = _rows.removeAt(index);
                        removed.dispose();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_error!,
                  style: const TextStyle(color: Colors.orangeAccent)),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.lock_outline),
              label: Text(_saving ? 'Saving…' : 'Save my budget'),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
, '').replaceAll(',', ''),
    );
    _period = plan.period;
    _start = plan.startDate;
    _rows = [
      for (final a in plan.allocations)
        _newRow(a.category, Money(a.plannedCents).aud
            .replaceAll('A$', '').replaceAll(',', '')),
    ];
    _income.addListener(_refresh);
  }

  _CategoryDraft _newRow(String title, String amount) {
    final result = _CategoryDraft(title, amount);
    result.amount.addListener(_refresh);
    return result;
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _name.dispose();
    _income.dispose();
    for (final row in _rows) {
      row.dispose();
    }
    super.dispose();
  }

  BudgetPlan _read() {
    final income = Money.tryParse(_income.text);
    if (income == null || income.cents < 0) {
      throw const FormatException('Enter a valid planned income.');
    }
    final categories = <BudgetAllocation>[];
    for (final row in _rows) {
      final amount = Money.tryParse(row.amount.text);
      if (amount == null || amount.cents < 0) {
        throw const FormatException('Each category needs a valid AUD amount.');
      }
      categories.add(BudgetAllocation(
        category: row.title.text.trim(), plannedCents: amount.cents,
      ));
    }
    final result = BudgetPlan(
      id: widget.initial.id, name: _name.text.trim(),
      incomeCents: income.cents, period: _period, startDate: _start,
      templateId: widget.initial.templateId, allocations: categories,
    );
    result.validate();
    return result;
  }

  Future<void> _changeDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || picked == null) return;
    setState(() => _start = DateTime.utc(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    if (_saving) return;
    BudgetPlan plan;
    try {
      plan = _read();
    } on FormatException catch (error) {
      setState(() => _error = error.message);
      return;
    }
    if (plan.isOverallocated) {
      final proceed = await showDialog<bool>(
        context: context,
        builder: (dialog) => AlertDialog(
          title: const Text('Budget exceeds income'),
          content: Text('Your allocations exceed income by '
              '${Money(-plan.unallocatedCents).aud}. Save anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog, false),
              child: const Text('Adjust'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialog, true),
              child: const Text('Save with warning'),
            ),
          ],
        ),
      );
      if (proceed != true || !mounted) return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final success = await widget.onSave(plan);
      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() => _error = 'Save failed. Your edits are still here.');
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not save. Please retry.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    BudgetPlan? preview;
    try {
      preview = _read();
    } on FormatException {
      // Partial field values will be validated on save.
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget Editor'),
        actions: [
          TextButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check), label: const Text('Save'),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('YOUR PERSONAL BUDGET',
              style: TextStyle(color: _gold, letterSpacing: 1.5)),
            const SizedBox(height: 14),
            TextField(
              controller: _name, maxLength: 100,
              decoration: const InputDecoration(
                labelText: 'Budget name', border: OutlineInputBorder()),
            ),
            TextField(
              controller: _income,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Planned income', prefixText: 'A$ ',
                border: OutlineInputBorder(),
                helperText: 'Budgeting does not change real account balances.',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BudgetPeriod>(
              initialValue: _period,
              decoration: const InputDecoration(
                labelText: 'Pay / budget cycle', border: OutlineInputBorder()),
              items: [
                for (final item in BudgetPeriod.values)
                  DropdownMenuItem(value: item, child: Text(item.name)),
              ],
              onChanged: _saving ? null : (value) {
                if (value != null) setState(() => _period = value);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event, color: _gold),
              title: const Text('Cycle start date'),
              subtitle: Text('${_start.day}/${_start.month}/${_start.year}'),
              trailing: const Icon(Icons.edit_calendar),
              onTap: _saving ? null : _changeDate,
            ),
            Card(
              color: const Color(0xFF1B2633),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ALLOCATION OVERVIEW',
                      style: TextStyle(color: _gold)),
                    const SizedBox(height: 8),
                    Text('Allocated: ${preview == null ? "—" : Money(preview.allocatedCents).aud}'),
                    Text('Remaining: ${preview == null ? "—" : Money(preview.unallocatedCents).aud}'),
                    if (preview?.isOverallocated ?? false)
                      const Text('Warning: allocations exceed planned income.',
                        style: TextStyle(color: Colors.orangeAccent)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: Text('Categories',
                  style: Theme.of(context).textTheme.titleLarge)),
                TextButton.icon(
                  onPressed: _saving || _rows.length >= 100 ? null : () {
                    setState(() => _rows.add(_newRow('New category', '0.00')));
                  },
                  icon: const Icon(Icons.add), label: const Text('Add'),
                ),
              ],
            ),
            for (var index = 0; index < _rows.length; index++)
              Padding(
                key: ObjectKey(_rows[index]),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        controller: _rows[index].title,
                        decoration: const InputDecoration(
                          labelText: 'Category', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _rows[index].amount,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'AUD', isDense: true,
                          border: OutlineInputBorder()),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove category', icon: const Icon(Icons.close),
                      onPressed: _saving ? null : () {
                        final removed = _rows.removeAt(index);
                        removed.dispose();
                        setState(() {});
                      },
                    ),
                  ],
                ),
              ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(_error!,
                  style: const TextStyle(color: Colors.orangeAccent)),
              ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.lock_outline),
              label: Text(_saving ? 'Saving…' : 'Save my budget'),
            ),
            const SizedBox(height: 28),
          ],
        ),
      ),
    );
  }
}
