import 'package:flutter/material.dart';

import '../domain/budget_templates.dart';
import '../domain/demo_data.dart';
import '../domain/finance_models.dart';
import '../domain/ledger_engine.dart';
import '../domain/money.dart';

const _navy = Color(0xFF0C1117);
const _graphite = Color(0xFF1B2633);
const _gold = Color(0xFFC8AE7D);

/// This UI is a developer preview; ALL balances are fictional and unsaved.
class TongLedgerApp extends StatelessWidget {
  const TongLedgerApp({super.key});

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
      home: const LedgerShell(),
    );
  }
}

class LedgerShell extends StatefulWidget {
  const LedgerShell({super.key});

  @override
  State<LedgerShell> createState() => _LedgerShellState();
}

class _LedgerShellState extends State<LedgerShell> {
  final FinanceBook _book = createDemoBook();
  int _selectedTab = 0;
  int _serial = 0;
  BudgetTemplate _activeTemplate = budgetTemplates[7];

  String _id() {
    _serial++;
    return DateTime.now().microsecondsSinceEpoch.toString() +
        '-' + _serial.toString();
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
    final controllers = <String, TextEditingController>{
      for (final field in fields) field.$1: TextEditingController(),
    };
    final response = await showDialog<Map<String, String>>(
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
                    child: TextField(
                      controller: controllers[field.$1],
                      decoration: InputDecoration(
                        labelText: field.$2,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
                const Text('DEMO ONLY — changes disappear after app restart.'),
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
            onPressed: () => Navigator.pop(dialogContext, {
              for (final field in fields)
                field.$1: controllers[field.$1]!.text.trim(),
            }),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    for (final controller in controllers.values) {
      controller.dispose();
    }
    return response;
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
      _message('Please enter a valid positive AUD amount for ' + key + '.');
      return null;
    }
    return money.cents;
  }

  void _post(LedgerEntry entry) {
    _book.entries.add(entry);
    try {
      calculateLedger(_book);
      setState(() {});
      _message('Demo transaction recorded (not saved).');
    } on LedgerException catch (error) {
      _book.entries.removeLast();
      _message(error.message);
    }
  }

  Future<void> _addBank() async {
    final fields = await _form('Add institution', [('name', 'Bank or lender name')]);
    if (!mounted || fields == null) return;
    final name = fields['name'] ?? '';
    if (name.isEmpty) return _message('A name is required.');
    setState(() => _book.institutions.add(Institution(id: _id(), name: name)));
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
    if ((fields['name'] ?? '').isEmpty) return _message('Name required.');
    setState(() => _book.accounts.add(CashAccount(
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
    if ((fields['name'] ?? '').isEmpty) return _message('Name required.');
    setState(() => _book.cards.add(CreditCardAccount(
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
      ('outstanding', 'Outstanding principal (AUD)'),
      ('instalment', 'Regular instalment (AUD)'),
    ]);
    if (!mounted || fields == null) return;
    final outstanding = _cents(fields, 'outstanding', zeroOk: true);
    final instalment = _cents(fields, 'instalment', zeroOk: true);
    if (outstanding == null || instalment == null) return;
    if ((fields['name'] ?? '').isEmpty ||
        (fields['lender'] ?? '').isEmpty) {
      return _message('Loan and lender names are required.');
    }
    setState(() => _book.loans.add(LoanAccount(
      id: _id(),
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
    _post(LedgerEntry(
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
    _post(LedgerEntry(
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
    _post(LedgerEntry(
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
    _post(LedgerEntry(
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
    _post(LedgerEntry(
      id: _id(), type: LedgerType.loanPayment, amountCents: amount,
      interestCents: interest, sourceAccountId: account.id,
      loanId: loan.id, at: DateTime.now().toUtc(),
    ));
  }

  void _showActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const ListTile(title: Text('Add to Demo Ledger')),
            _action(sheetContext, Icons.account_balance, 'Bank / institution', _addBank),
            _action(sheetContext, Icons.account_balance_wallet, 'Cash account', _addAccount),
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
        _heading('Financial overview • Fictional example'),
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
            subtitle: Text(_activeTemplate.group + ' • editable plan coming later'),
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
        const Text('Sample balances are fictional. No data is saved or bank-connected.',
          style: TextStyle(color: Colors.white70)),
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
            subtitle: Text('Available: ' +
                Money(card.limitCents - (snapshot.cardsOwed[card.id] ?? 0)).aud),
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
            subtitle: Text('As of ' + asset.asOf.toIso8601String().substring(0, 10)),
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
                    subtitle: Text(allocation.value.toString() + '%'),
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
            onPressed: () {
              setState(() => _activeTemplate = template);
              Navigator.pop(dialogContext);
            },
            child: const Text('Use in demo'),
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
          child: Text('Select an actual spending plan, not a visual theme. '
              'Budget editing, cloning and persistence come in later milestones.'),
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
        _heading('Insights — demo ledger only'),
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
        _heading('Privacy and security status'),
        const ListTile(
          leading: Icon(Icons.shield_outlined, color: _gold),
          title: Text('Prototype: NO encrypted persistence yet'),
          subtitle: Text('No signup, no bank connection, all changes in memory. '
              'Do not add real financial information.'),
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
            onPressed: _showActions,
            tooltip: 'Add demo record',
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
            child: const Text('DEMO • NOT SAVED • DO NOT ENTER REAL DATA',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
          Expanded(child: pages[_selectedTab]),
        ],
      ),
      floatingActionButton: _selectedTab <= 1
          ? FloatingActionButton.extended(
              onPressed: _showActions,
              icon: const Icon(Icons.add),
              label: const Text('Add demo record'),
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
