import 'package:flutter/material.dart';

import '../domain/budget_templates.dart';
import '../domain/demo_data.dart';
import '../domain/finance_models.dart';
import '../domain/ledger_engine.dart';
import '../domain/money.dart';
import '../storage/finance_book_codec.dart';
import '../storage/finance_store.dart';
import '../storage/secure_finance_store.dart';

const _navy = Color(0xFF0C1117);
const _graphite = Color(0xFF1B2633);
const _gold = Color(0xFFC8AE7D);

/// Early encrypted-local-data prototype; not a production-ready release.
class TongLedgerApp extends StatelessWidget {
  const TongLedgerApp({super.key, this.store});

  final FinanceStore? store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tong Ledger',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: _navy,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _gold,
          brightness: Brightness.dark,
        ),
      ),
      home: LedgerShell(store: store),
    );
  }
}

class LedgerShell extends StatefulWidget {
  const LedgerShell({super.key, this.store});

  final FinanceStore? store;

  @override
  State<LedgerShell> createState() => _LedgerShellState();
}

class _LedgerShellState extends State<LedgerShell> {
  FinanceBook _book = FinanceBook();
  late final FinanceStore _store;
  bool _loading = true;
  bool _demo = false;
  bool _busy = false;
  String? _loadError;
  int _selectedTab = 0;
  int _serial = 0;
  BudgetTemplate _activeTemplate = budgetTemplates[7];

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? SecureFinanceStore();
    _restore();
  }

  Future<void> _restore() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final restored = await _store.load();
      if (!mounted) return;
      setState(() {
        _book = restored;
        _demo = false;
        _activeTemplate = budgetTemplates.firstWhere(
          (t) => t.id == restored.selectedBudgetTemplateId,
          orElse: () => budgetTemplates[7],
        );
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error.toString();
        _loading = false;
      });
    }
  }

  void _enterDemo() {
    setState(() {
      _book = createDemoBook();
      _activeTemplate = budgetTemplates[7];
      _demo = true;
      _selectedTab = 0;
    });
  }

  Future<void> _commit(void Function(FinanceBook) edit) async {
    if (_busy || _loading || _loadError != null) return;
    setState(() => _busy = true);
    try {
      final next = FinanceBookCodec.decode(FinanceBookCodec.encode(_book));
      edit(next);
      // A bad mutation cannot be written or appear in the live UI.
      FinanceBookCodec.decode(FinanceBookCodec.encode(next));
      if (!_demo) await _store.save(next);
      if (!mounted) return;
      setState(() {
        _book = next;
        _activeTemplate = budgetTemplates.firstWhere(
          (t) => t.id == next.selectedBudgetTemplateId,
          orElse: () => budgetTemplates[7],
        );
      });
      _message(_demo
          ? 'Demo-only change; not saved.'
          : 'Saved in your encrypted local vault.');
    } catch (error) {
      _message('Could not save. Existing data was preserved: ${error.toString()}');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _id() {
    _serial++;
    return '${DateTime.now().microsecondsSinceEpoch}-$_serial';
  }

  void _message(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  Future<Map<String, String>?> _form(
    String title,
    List<(String, String)> fields,
  ) async {
    final values = <String, String>{
      for (final field in fields) field.$1: '',
    };
    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final field in fields)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: TextFormField(
                      onChanged: (value) => values[field.$1] = value.trim(),
                      keyboardType: [
                        'amount', 'opening', 'limit', 'owed',
                        'outstanding', 'instalment', 'interest',
                      ].contains(field.$1)
                          ? const TextInputType.numberWithOptions(decimal: true)
                          : TextInputType.text,
                      decoration: InputDecoration(
                        labelText: field.$2,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                Text(_demo
                    ? 'Demo mode: changes will NOT be saved.'
                    : 'Saved only in this device\'s encrypted vault.'),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, {...values}),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<T?> _choose<T>(
    String title,
    List<T> options,
    String Function(T) display,
  ) {
    if (options.isEmpty) {
      _message('Add a record in this section first.');
      return Future<T?>.value(null);
    }
    return showModalBottomSheet<T>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          height: 360,
          child: ListView(
            children: [
              ListTile(title: Text(title)),
              for (final option in options)
                ListTile(
                  title: Text(display(option)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(sheetContext, option),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int? _cents(Map<String, String> values, String key, {bool zeroOk = false}) {
    final money = Money.tryParse(values[key] ?? '');
    if (money == null || money.cents < 0 ||
        (!zeroOk && money.cents == 0)) {
      _message('Please enter a valid positive AUD amount for $key.');
      return null;
    }
    return money.cents;
  }

  Future<void> _post(LedgerEntry entry) async {
    await _commit((book) => book.entries.add(entry));
  }

  Future<void> _addBank() async {
    final fields = await _form('Add institution', [('name', 'Bank or lender name')]);
    if (!mounted || fields == null) return;
    final name = fields['name'] ?? '';
    if (name.isEmpty) {
      _message('A name is required.');
      return;
    }
    await _commit((book) => book.institutions.add(Institution(id: _id(), name: name)));
  }

  Future<void> _addAccount() async {
    final bank = await _choose(
      'Which institution?', _book.institutions, (Institution b) => b.name,
    );
    if (!mounted || bank == null) return;
    final fields = await _form('New cash account', [
      ('name', 'Account nickname'),
      ('opening', 'Opening balance (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final balance = _cents(fields, 'opening', zeroOk: true);
    if (balance == null) return;
    if ((fields['name'] ?? '').isEmpty) {
      _message('Name required.');
      return;
    }
    await _commit((book) => book.accounts.add(CashAccount(
      id: _id(),
      name: fields['name']!,
      institutionId: bank.id,
      openingCents: balance,
    )));
  }

  Future<void> _addCard() async {
    final bank = await _choose(
      'Credit-card issuer', _book.institutions, (Institution b) => b.name,
    );
    if (!mounted || bank == null) return;
    final fields = await _form('New credit card', [
      ('name', 'Card nickname'),
      ('limit', 'Credit limit (AUD)'),
      ('owed', 'Current owed (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final limit = _cents(fields, 'limit', zeroOk: true);
    final owed = _cents(fields, 'owed', zeroOk: true);
    if (limit == null || owed == null) return;
    if ((fields['name'] ?? '').isEmpty) {
      _message('Name required.');
      return;
    }
    await _commit((book) => book.cards.add(CreditCardAccount(
      id: _id(),
      name: fields['name']!,
      limitCents: limit,
      openingOwedCents: owed,
      institutionId: bank.id,
    )));
  }

  Future<void> _addLoan() async {
    final fields = await _form('New loan (bank or private lender)', [
      ('name', 'Loan nickname'),
      ('lender', 'Lender / company name'),
      ('bank', 'Linked existing bank name (optional)'),
      ('outstanding', 'Outstanding principal (AUD)'),
      ('instalment', 'Regular instalment (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final outstanding = _cents(fields, 'outstanding', zeroOk: true);
    final instalment = _cents(fields, 'instalment', zeroOk: true);
    if (outstanding == null || instalment == null) return;
    if ((fields['name'] ?? '').isEmpty ||
        (fields['lender'] ?? '').isEmpty) {
      _message('Loan and lender names are required.');
      return;
    }
    final bankName = (fields['bank'] ?? '').trim().toLowerCase();
    final bankMatches = _book.institutions.where(
      (bank) => bank.name.toLowerCase() == bankName,
    ).toList();
    if (bankName.isNotEmpty && bankMatches.isEmpty) {
      _message('Existing bank not found; leave blank for a private lender.');
      return;
    }
    await _commit((book) => book.loans.add(LoanAccount(
      id: _id(),
      institutionId: bankMatches.isEmpty ? null : bankMatches.first.id,
      name: fields['name']!,
      lenderName: fields['lender']!,
      openingOutstandingCents: outstanding,
      instalmentCents: instalment,
    )));
  }

  Future<void> _addExpense() async {
    final account = await _choose(
      'Paid from which account?', _book.accounts, (CashAccount a) => a.name,
    );
    if (!mounted || account == null) return;
    final fields = await _form('Add cash expense', [
      ('amount', 'Amount (AUD)'),
      ('category', 'Spending category'),
    ]);
    if (!mounted || fields == null) return;
    final amount = _cents(fields, 'amount');
    if (amount == null) return;
    await _post(LedgerEntry(
      id: _id(), type: LedgerType.cashExpense,
      amountCents: amount, sourceAccountId: account.id,
      category: fields['category'], at: DateTime.now().toUtc(),
    ));
  }

  Future<void> _addIncome() async {
    final account = await _choose(
      'Receiving account', _book.accounts, (CashAccount a) => a.name,
    );
    if (!mounted || account == null) return;
    final fields = await _form('Record received income', [
      ('amount', 'Received amount (AUD)'),
      ('category', 'Employer / source'),
    ]);
    if (!mounted || fields == null) return;
    final amount = _cents(fields, 'amount');
    if (amount == null) return;
    await _post(LedgerEntry(
      id: _id(), type: LedgerType.income,
      amountCents: amount, destinationAccountId: account.id,
      category: fields['category'], at: DateTime.now().toUtc(),
    ));
  }

  Future<void> _addCardPurchase() async {
    final card = await _choose(
      'Paid with which credit card?',
      _book.cards, (CreditCardAccount c) => c.name,
    );
    if (!mounted || card == null) return;
    final fields = await _form('Add card purchase', [
      ('amount', 'Purchase amount (AUD)'), ('category', 'Spending category'),
    ]);
    if (!mounted || fields == null) return;
    final amount = _cents(fields, 'amount');
    if (amount == null) return;
    await _post(LedgerEntry(
      id: _id(), type: LedgerType.cardPurchase,
      cardId: card.id, amountCents: amount,
      category: fields['category'], at: DateTime.now().toUtc(),
    ));
  }

  Future<void> _addCardPayment() async {
    final account = await _choose(
      'Pay from which account?', _book.accounts, (CashAccount a) => a.name,
    );
    if (!mounted || account == null) return;
    final card = await _choose(
      'Pay which card?', _book.cards, (CreditCardAccount c) => c.name,
    );
    if (!mounted || card == null) return;
    final fields = await _form('Card repayment', [
      ('amount', 'Payment amount (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final amount = _cents(fields, 'amount');
    if (amount == null) return;
    await _post(LedgerEntry(
      id: _id(), type: LedgerType.cardPayment, amountCents: amount,
      sourceAccountId: account.id, cardId: card.id,
      at: DateTime.now().toUtc(),
    ));
  }

  Future<void> _addLoanPayment() async {
    final account = await _choose(
      'Pay from account', _book.accounts, (CashAccount a) => a.name,
    );
    if (!mounted || account == null) return;
    final loan = await _choose(
      'Choose loan', _book.loans, (LoanAccount l) => l.name,
    );
    if (!mounted || loan == null) return;
    final fields = await _form('Record loan repayment', [
      ('amount', 'Total payment (AUD)'),
      ('interest', 'Interest portion (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final amount = _cents(fields, 'amount');
    final interest = _cents(fields, 'interest', zeroOk: true);
    if (amount == null || interest == null) return;
    await _post(LedgerEntry(
      id: _id(), type: LedgerType.loanPayment, amountCents: amount,
      interestCents: interest, sourceAccountId: account.id,
      loanId: loan.id, at: DateTime.now().toUtc(),
    ));
  }

  Future<void> _addTransfer() async {
    final from = await _choose(
      'Transfer from', _book.accounts, (CashAccount a) => a.name,
    );
    if (!mounted || from == null) return;
    final targets = _book.accounts
        .where((account) => account.id != from.id).toList();
    final to = await _choose(
      'Transfer to', targets, (CashAccount a) => a.name,
    );
    if (!mounted || to == null) return;
    final fields = await _form('Transfer between my accounts', [
      ('amount', 'Transfer amount (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final amount = _cents(fields, 'amount');
    if (amount == null) return;
    await _post(LedgerEntry(
      id: _id(), type: LedgerType.transfer,
      amountCents: amount, sourceAccountId: from.id,
      destinationAccountId: to.id, at: DateTime.now().toUtc(),
    ));
  }

  Future<void> _addAsset() async {
    final fields = await _form('Add an asset', [
      ('name', 'Asset name (car, house, investment...)'),
      ('value', 'Estimated current value (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final value = _cents(fields, 'value', zeroOk: true);
    if (value == null) return;
    final name = (fields['name'] ?? '').trim();
    if (name.isEmpty) {
      _message('Asset name is required.');
      return;
    }
    await _commit((book) => book.assets.add(AssetRecord(
      id: _id(), name: name, valuationCents: value,
      asOf: DateTime.now().toUtc(),
    )));
  }

  Future<void> _addIncomeSource() async {
    final destination = await _choose(
      'Which account receives income?',
      _book.accounts, (CashAccount a) => a.name,
    );
    if (!mounted || destination == null) return;
    final fields = await _form('Add expected income source', [
      ('name', 'Employer, business or source'),
      ('amount', 'Expected take-home amount (AUD)'),
      ('cadence', 'Frequency (weekly / fortnightly / monthly / irregular)'),
    ]);
    if (!mounted || fields == null) return;
    final amount = _cents(fields, 'amount');
    if (amount == null) return;
    final name = (fields['name'] ?? '').trim();
    final cadence = (fields['cadence'] ?? '').trim().toLowerCase();
    const allowed = ['weekly', 'fortnightly', 'monthly', 'irregular'];
    if (name.isEmpty || !allowed.contains(cadence)) {
      _message('Please provide a name and a supported frequency.');
      return;
    }
    await _commit((book) => book.incomeSources.add(IncomeSource(
      id: _id(), name: name, expectedCents: amount,
      cadence: cadence, destinationAccountId: destination.id,
    )));
  }

  void _showActions() {
    if (_busy || _loading || _loadError != null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            ListTile(title: Text(_demo ? 'Add to Demo Ledger' : 'Add to Local Vault')),
            _action(sheetContext, Icons.account_balance, 'Bank / institution', _addBank),
            _action(sheetContext, Icons.account_balance_wallet, 'Cash account', _addAccount),
            _action(sheetContext, Icons.swap_horiz, 'Transfer between accounts', _addTransfer),
            _action(sheetContext, Icons.directions_car, 'Asset / valuation', _addAsset),
            _action(sheetContext, Icons.work_outline, 'Income source and frequency', _addIncomeSource),
            _action(sheetContext, Icons.credit_card, 'Credit card', _addCard),
            _action(sheetContext, Icons.payments, 'Loan (private lender supported)', _addLoan),
            _action(sheetContext, Icons.shopping_cart, 'Cash expense', _addExpense),
            _action(sheetContext, Icons.call_received, 'Received income', _addIncome),
            _action(sheetContext, Icons.shopping_bag, 'Card purchase', _addCardPurchase),
            _action(sheetContext, Icons.credit_score, 'Card payment', _addCardPayment),
            _action(sheetContext, Icons.receipt_long, 'Loan repayment', _addLoanPayment),
          ],
        ),
      ),
    );
  }

  Widget _action(
    BuildContext sheetContext,
    IconData icon,
    String label,
    Future<void> Function() action,
  ) {
    return ListTile(
      leading: Icon(icon, color: _gold),
      title: Text(label),
      onTap: () {
        Navigator.pop(sheetContext);
        action();
      },
    );
  }

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
    child: Text(title, style: const TextStyle(
      fontSize: 19, color: _gold, fontWeight: FontWeight.w700,
    )),
  );

  Widget _metric(String title, int cents, IconData icon) {
    return SizedBox(
      width: 168,
      child: Card(
        color: _graphite,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: _gold),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 4),
              Text(Money(cents).aud, style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.w700,
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _home(FinanceSnapshot snapshot) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('WELCOME TO TONG LEDGER',
          style: TextStyle(color: _gold, letterSpacing: 1.6)),
        const SizedBox(height: 5),
        const Text('Your financial world, clearly organised.',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        _heading(_demo ? 'Financial overview • Fictional example' : 'Financial overview • Manual records'),
        Wrap(spacing: 8, runSpacing: 8, children: [
          _metric('Cash accounts', snapshot.cashCents, Icons.account_balance_wallet),
          _metric('Credit cards owed', snapshot.creditCardDebtCents, Icons.credit_card),
          _metric('Loans owed', snapshot.loanDebtCents, Icons.payments_outlined),
          _metric('Estimated net worth', snapshot.netWorthCents, Icons.show_chart),
        ]),
        _heading('Your active budget preview'),
        Card(
          color: _graphite,
          child: ListTile(
            leading: const Icon(Icons.pie_chart_outline, color: _gold),
            title: Text(_activeTemplate.name),
            subtitle: Text('${_activeTemplate.group} • custom allocations coming later'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              setState(() => _selectedTab = 2);
            },
          ),
        ),
        _heading('Recent activity'),
        for (final entry in _book.entries.reversed.take(5))
          ListTile(
            leading: const Icon(Icons.receipt_long, color: _gold),
            title: Text(entry.category ?? entry.type.name),
            subtitle: Text(entry.type.name),
            trailing: Text(Money(entry.amountCents).aud),
          ),
        const SizedBox(height: 15),
        Text(_demo
          ? 'All balances are fictional and not saved.'
          : 'These are manually entered estimates, not live bank balances.',
          style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _money(FinanceSnapshot snapshot) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _heading('Banks & cash accounts'),
        for (final bank in _book.institutions) ...[
          ListTile(
            leading: const Icon(Icons.account_balance, color: _gold),
            title: Text(bank.name),
            subtitle: Text('Manually added institution'),
          ),
          for (final account in _book.accounts
              .where((account) => account.institutionId == bank.id))
            ListTile(
              contentPadding: const EdgeInsets.only(left: 36, right: 10),
              title: Text(account.name),
              subtitle: Text(account.kind.name),
              trailing: Text(Money(snapshot.accounts[account.id] ?? 0).aud),
            ),
        ],
        _heading('Credit cards'),
        for (final card in _book.cards)
          ListTile(
            leading: const Icon(Icons.credit_card, color: _gold),
            title: Text(card.name),
            subtitle: Text('Available: ${Money(card.limitCents - (snapshot.cardsOwed[card.id] ?? 0)).aud}'),
            trailing: Text(Money(snapshot.cardsOwed[card.id] ?? 0).aud),
          ),
        _heading('Loans — bank or independent lender'),
        for (final loan in _book.loans)
          ListTile(
            leading: const Icon(Icons.payments_outlined, color: _gold),
            title: Text(loan.name),
            subtitle: Text(loan.lenderName),
            trailing: Text(Money(snapshot.loansOutstanding[loan.id] ?? 0).aud),
          ),
        _heading('Assets (dated estimates)'),
        for (final asset in _book.assets)
          ListTile(
            leading: const Icon(Icons.directions_car, color: _gold),
            title: Text(asset.name),
            subtitle: Text('As of ${asset.asOf.toIso8601String().substring(0, 10)}'),
            trailing: Text(Money(asset.valuationCents).aud),
          ),
        _heading('Income sources — forecasts only'),
        for (final source in _book.incomeSources)
          ListTile(
            leading: const Icon(Icons.work_outline, color: _gold),
            title: Text(source.name),
            subtitle: Text(source.cadence),
            trailing: Text(Money(source.expectedCents).aud),
          ),
        const SizedBox(height: 90),
      ],
    );
  }

  Future<void> _showBudget(BudgetTemplate template) async {
    final example = template.amountsFor(400000);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(template.name),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Example on A\$4,000 take-home income. Preview only.'),
                const SizedBox(height: 12),
                for (final allocation in template.allocations.entries)
                  ListTile(
                    dense: true,
                    title: Text(allocation.key),
                    subtitle: Text('${allocation.value}%'),
                    trailing: Text(Money(example[allocation.key] ?? 0).aud),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
          FilledButton(
            onPressed: () async {
              await _commit((book) => book.selectedBudgetTemplateId = template.id);
              if (dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: Text(_demo ? 'Use in demo' : 'Save plan selection'),
          ),
        ],
      ),
    );
  }

  Widget _plans() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _heading('30 ready-made budget plans'),
        const Padding(
          padding: EdgeInsets.all(8),
          child: Text('Select a real budget plan. Selection is saved; category editing is coming in the next milestone.'),
        ),
        for (final group in budgetCollections) ...[
          _heading(group),
          for (final plan in budgetTemplates.where((item) => item.group == group))
            Card(
              color: plan.id == _activeTemplate.id ? _graphite : null,
              child: ListTile(
                leading: const Icon(Icons.auto_awesome_outlined, color: _gold),
                title: Text(plan.name),
                subtitle: const Text('100% editable allocation plan • preview'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showBudget(plan),
              ),
            ),
        ],
      ],
    );
  }

  Widget _insights(FinanceSnapshot snapshot) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _heading(_demo ? 'Insights — fictional demo' : 'Insights — locally recorded'),
        _metric('Recorded income', snapshot.incomeCents, Icons.trending_up),
        _metric('Recorded spending', snapshot.expenseCents, Icons.trending_down),
        _metric('Current cash', snapshot.cashCents, Icons.account_balance_wallet),
        const SizedBox(height: 16),
        const Text('Future: monthly trends, cash-flow chart, goals, '
          'debt forecasts and explainable safe-to-spend calculations.'),
      ],
    );
  }

  Widget _more() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _heading('Learn Tong Ledger'),
        const ListTile(
          leading: Icon(Icons.menu_book_outlined, color: _gold),
          title: Text('Quick start'),
          subtitle: Text('Add bank → accounts → cards → loans → budget plan'),
        ),
        const ListTile(
          leading: Icon(Icons.school_outlined, color: _gold),
          title: Text('Full Academy'),
          subtitle: Text('Eight lessons planned; full tutorials in GitHub docs'),
        ),
        _heading('Local data and demo'),
        ListTile(
          leading: const Icon(Icons.swap_horiz, color: _gold),
          title: Text(_demo ? 'Return to my encrypted vault' : 'Explore fictional demo'),
          subtitle: Text(_demo
              ? 'Discard this demo session and reload stored information.'
              : 'Your saved data is kept unchanged while in demo mode.'),
          onTap: _demo ? _restore : _enterDemo,
        ),
        const ListTile(
          leading: Icon(Icons.shield_outlined, color: _gold),
          title: Text('Local encryption enabled — beta'),
          subtitle: Text('No bank connection or cloud sync. Secure backup, '
              'biometric lock and release security review are still pending.'),
        ),
        const ListTile(
          leading: Icon(Icons.code, color: _gold),
          title: Text('Open source • Apache 2.0'),
          subtitle: Text('Tong Ledger by ParmTech • Android-first Flutter'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_loadError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Tong Ledger — Vault locked')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 48, color: _gold),
                const SizedBox(height: 16),
                const Text('Your encrypted records could not be opened. '
                    'No data has been reset or overwritten.'),
                const SizedBox(height: 8),
                SelectableText(_loadError!),
                const SizedBox(height: 16),
                FilledButton(onPressed: _restore, child: const Text('Try again')),
              ],
            ),
          ),
        ),
      );
    }
    final snapshot = calculateLedger(_book);
    final pages = [
      _home(snapshot),
      _money(snapshot),
      _plans(),
      _insights(snapshot),
      _more(),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: _navy,
        title: const Text('TONG LEDGER',
            style: TextStyle(color: _gold, letterSpacing: 1.1)),
        actions: [
          IconButton(
            onPressed: _busy ? null : _showActions,
            tooltip: 'Add finance record',
            icon: const Icon(Icons.add_circle_outline, color: _gold),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xFF493A20),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(_demo
              ? 'DEMO • FICTIONAL • NOT SAVED'
              : 'PRIVATE LOCAL VAULT • BETA • BACKUP NOT READY',
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: pages[_selectedTab]),
        ],
      ),
      floatingActionButton: _selectedTab <= 1
          ? FloatingActionButton.extended(
              onPressed: _busy ? null : _showActions,
              icon: const Icon(Icons.add),
              label: Text(_busy ? 'Saving...' : 'Add record'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTab,
        onDestinationSelected: (index) => setState(() => _selectedTab = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.account_balance_outlined), label: 'Money'),
          NavigationDestination(icon: Icon(Icons.donut_large_outlined), label: 'Plans'),
          NavigationDestination(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }
}
