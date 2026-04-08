import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/supabase_config.dart';

class JuiceWalletScreen extends StatefulWidget {
  const JuiceWalletScreen({super.key});

  @override
  State<JuiceWalletScreen> createState() => _JuiceWalletScreenState();
}

class _JuiceWalletScreenState extends State<JuiceWalletScreen> {
  int _balance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
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

    final wallet = await walletFuture;
    final txData = await txFuture;

    if (mounted) {
      setState(() {
        _balance = (wallet?['balance'] as int?) ?? 0;
        _transactions = List<Map<String, dynamic>>.from(txData);
        _loading = false;
      });
    }
  }

  Future<void> _topUp(int juiceAmount, String priceLabel) async {
    // In production: call server action to create Stripe Checkout session
    // For now: show info that Stripe needs to be configured
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Stripe checkout for $juiceAmount Juice ($priceLabel) — needs API keys configured'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Juice Wallet')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                                '\u{1F9C3}', // juice box emoji
                                style: TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '$_balance',
                                style: theme.textTheme.displaySmall
                                    ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Juice',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: theme
                                      .colorScheme.onPrimaryContainer,
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
                    children: [
                      Expanded(
                          child: _TopUpCard(
                        juice: 10,
                        price: '£1',
                        onTap: () => _topUp(10, '£1'),
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _TopUpCard(
                        juice: 55,
                        price: '£5',
                        bonus: '+10%',
                        onTap: () => _topUp(55, '£5'),
                      )),
                      const SizedBox(width: 8),
                      Expanded(
                          child: _TopUpCard(
                        juice: 120,
                        price: '£10',
                        bonus: '+20%',
                        onTap: () => _topUp(120, '£10'),
                      )),
                    ],
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
                            style: TextStyle(
                                color: theme.colorScheme.outline),
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
                            color: isSpend
                                ? theme.colorScheme.error
                                : Colors.green,
                          ),
                          title: Text(
                            ref.isNotEmpty ? ref : (isSpend ? 'Spent' : 'Purchased'),
                          ),
                          trailing: Text(
                            '${isSpend ? '-' : '+'}$amount',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSpend
                                  ? theme.colorScheme.error
                                  : Colors.green,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
    );
  }
}

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
                    horizontal: 12, vertical: 4),
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
                  style: TextStyle(
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
