import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';
import 'payment_service.dart';

class JuiceWalletScreen extends StatefulWidget {
  const JuiceWalletScreen({super.key});

  @override
  State<JuiceWalletScreen> createState() => _JuiceWalletScreenState();
}

class _JuiceWalletScreenState extends State<JuiceWalletScreen>
    with SingleTickerProviderStateMixin {
  int _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  List<Map<String, dynamic>> _paymentMethods = [];
  List<Map<String, dynamic>> _settlements = [];
  bool _loading = true;

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final walletFuture = supabase
        .from('juice_wallets')
        .select('balance')
        .eq('user_id', user.id)
        .maybeSingle();

    final txFuture = supabase
        .from('juice_transactions')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(30);

    final methodsFuture = PaymentService.instance.getPaymentMethods();
    final settlementsFuture = PaymentService.instance.getSettlements();

    final wallet = await walletFuture;
    final txData = await txFuture;
    final methods = await methodsFuture;
    final settlements = await settlementsFuture;

    if (mounted) {
      setState(() {
        _balance = (wallet?['balance'] as int?) ?? 0;
        _transactions = List<Map<String, dynamic>>.from(txData);
        _paymentMethods = methods;
        _settlements = settlements;
        _loading = false;
      });
    }
  }

  Future<void> _topUp(JuiceTier tier) async {
    final success = await PaymentService.instance.topUpWithCard(
      juiceAmount: tier.juice,
      amountPence: tier.pricePence,
    );

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tier.juice} Juice purchased! Crediting...'),
            backgroundColor: Colors.green,
          ),
        );
        // Reload after a short delay to allow webhook processing
        Future.delayed(const Duration(seconds: 2), _load);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled or failed')),
        );
      }
    }
  }

  Future<void> _addCard() async {
    final success = await PaymentService.instance.saveCard();
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Card saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      _load();
    }
  }

  Future<void> _setupDirectDebit() async {
    final launched = await PaymentService.instance.setupGoCardlessMandate();
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Direct Debit setup page')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Juice Wallet'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Wallet'),
            Tab(text: 'Payment'),
            Tab(text: 'Settlements'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildWalletTab(theme),
                _buildPaymentTab(theme),
                _buildSettlementsTab(theme),
              ],
            ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab 1: Wallet — balance + top-up + history
  // ─────────────────────────────────────────────
  Widget _buildWalletTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Balance card
          Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Your Balance',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            '\u{1F9C3}',
                            style: TextStyle(fontSize: 32),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '$_balance',
                            style: theme.textTheme.displaySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Juice',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )
              .animate()
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95)),
          const SizedBox(height: 20),

          // Top-up options
          Text(
            'Get Juice',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: juiceTiers.map((tier) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: tier == juiceTiers.first ? 0 : 4,
                    right: tier == juiceTiers.last ? 0 : 4,
                  ),
                  child: _TopUpCard(
                    juice: tier.juice,
                    price: tier.priceLabel,
                    bonus: tier.bonus,
                    onTap: () => _topUp(tier),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Transaction history
          Row(
            children: [
              Text(
                'History',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '${_transactions.length} transactions',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (_transactions.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No transactions yet',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
              ),
            )
          else
            ..._transactions.map((tx) {
              final isSpend = tx['type'] == 'spend';
              final amount = tx['amount'] as int? ?? 0;
              final ref = tx['reference'] as String? ?? '';

              return Card(
                child: ListTile(
                  leading: Icon(
                    isSpend
                        ? Icons.remove_circle_outline
                        : Icons.add_circle_outline,
                    color: isSpend ? theme.colorScheme.error : Colors.green,
                  ),
                  title: Text(
                    ref.isNotEmpty ? ref : (isSpend ? 'Spent' : 'Purchased'),
                  ),
                  trailing: Text(
                    '${isSpend ? '-' : '+'}$amount',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSpend ? theme.colorScheme.error : Colors.green,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab 2: Payment methods — add card / direct debit
  // ─────────────────────────────────────────────
  Widget _buildPaymentTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payment Methods',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add a card for instant top-ups, or set up Direct Debit for lower fees on weekly settlements.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),

          // Existing payment methods
          if (_paymentMethods.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No payment methods added yet',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
              ),
            )
          else
            ..._paymentMethods.map((pm) {
              final isCard = pm['type'] == 'stripe_card';
              final isDefault = pm['is_default'] == true;
              final label = pm['label'] as String? ?? 'Unknown';
              final id = pm['id'] as String;

              return Card(
                child: ListTile(
                  leading: Icon(
                    isCard ? Icons.credit_card : Icons.account_balance,
                    color: theme.colorScheme.primary,
                  ),
                  title: Text(label),
                  subtitle: Text(
                    isCard ? 'Card' : 'Direct Debit',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isDefault)
                        Chip(
                          label: const Text(
                            'Default',
                            style: TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        )
                      else
                        TextButton(
                          onPressed: () async {
                            await PaymentService.instance.setDefaultMethod(id);
                            _load();
                          },
                          child: const Text(
                            'Set default',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, size: 20),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Remove payment method?'),
                              content: Text('Remove $label?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Remove'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await PaymentService.instance.removeMethod(id);
                            _load();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 20),

          // Add payment method buttons
          Text(
            'Add Method',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _AddMethodCard(
                  icon: Icons.credit_card,
                  title: 'Card',
                  subtitle: 'Visa, Mastercard',
                  onTap: _addCard,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _AddMethodCard(
                  icon: Icons.account_balance,
                  title: 'Direct Debit',
                  subtitle: 'Lower fees',
                  onTap: _setupDirectDebit,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Fee comparison info
          Card(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Fee Comparison',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Card: 2.9% + 30p per top-up\n'
                    'Direct Debit: 0.5% + 20p (capped £4)\n\n'
                    'Tips accumulate weekly — one settlement every Sunday.',
                    style: TextStyle(fontSize: 12, height: 1.5),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Tab 3: Settlements — weekly settlement history
  // ─────────────────────────────────────────────
  Widget _buildSettlementsTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Settlements',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tips are settled every Sunday at 23:00 UTC. Charges or payouts depend on your net balance.',
            style: TextStyle(fontSize: 13, color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),

          if (_settlements.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No settlements yet',
                    style: TextStyle(color: theme.colorScheme.outline),
                  ),
                ),
              ),
            )
          else
            ..._settlements.map((s) {
              final amountPence = s['amount_pence'] as int? ?? 0;
              final isPayout = amountPence > 0;
              final weekStart = s['week_start'] as String? ?? '';
              final status = s['status'] as String? ?? 'pending';
              final methodType = s['method_type'] as String? ?? '';

              final statusColor = switch (status) {
                'completed' => Colors.green,
                'failed' => theme.colorScheme.error,
                'processing' => Colors.orange,
                _ => theme.colorScheme.outline,
              };

              return Card(
                child: ListTile(
                  leading: Icon(
                    isPayout ? Icons.arrow_downward : Icons.arrow_upward,
                    color: isPayout ? Colors.green : theme.colorScheme.error,
                  ),
                  title: Text(
                    isPayout ? 'Payout' : 'Charge',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    'Week of $weekStart\n'
                    '${methodType == 'stripe_card' ? 'Card' : 'Direct Debit'}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  isThreeLine: true,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '£${(amountPence.abs() / 100).toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isPayout
                              ? Colors.green
                              : theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Reusable widgets
// ──────────────────────────────────────────────

class _TopUpCard extends StatelessWidget {
  const _TopUpCard({
    required this.juice,
    required this.price,
    this.bonus,
    required this.onTap,
  });

  final int juice;
  final String price;
  final String? bonus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Text(
                '$juice',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Text('Juice', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  price,
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              if (bonus != null) ...[
                const SizedBox(height: 4),
                Text(
                  bonus!,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AddMethodCard extends StatelessWidget {
  const _AddMethodCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(icon, size: 32, color: theme.colorScheme.primary),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small Juice balance pill for AppBar
class JuiceBalancePill extends StatefulWidget {
  const JuiceBalancePill({super.key});

  @override
  State<JuiceBalancePill> createState() => _JuiceBalancePillState();
}

class _JuiceBalancePillState extends State<JuiceBalancePill> {
  int _balance = 0;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('juice_wallets')
        .select('balance')
        .eq('user_id', user.id)
        .maybeSingle();

    if (mounted) {
      setState(() => _balance = (data?['balance'] as int?) ?? 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/wallet'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F9C3}', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 4),
            Text(
              '$_balance',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
