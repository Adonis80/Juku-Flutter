import 'package:flutter/material.dart';

import '../../core/supabase_config.dart';

class WorldBuilderScreen extends StatefulWidget {
  const WorldBuilderScreen({super.key});

  @override
  State<WorldBuilderScreen> createState() => _WorldBuilderScreenState();
}

class _WorldBuilderScreenState extends State<WorldBuilderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  List<Map<String, dynamic>> _objects = [];
  List<Map<String, dynamic>> _cosmetics = [];
  List<Map<String, dynamic>> _zones = [];
  bool _loading = true;
  int _juiceBalance = 0;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final objectsFuture = supabase
        .from('world_object_catalog')
        .select()
        .order('juice_cost', ascending: true);

    final cosmeticsFuture = supabase
        .from('jukumon_cosmetics')
        .select()
        .order('juice_cost', ascending: true);

    final zonesFuture = supabase.from('vr_zones').select();

    final walletFuture = supabase
        .from('juice_wallets')
        .select('balance')
        .eq('user_id', user.id)
        .maybeSingle();

    final results = await Future.wait(
        [objectsFuture, cosmeticsFuture, zonesFuture, walletFuture]);

    if (mounted) {
      setState(() {
        _objects = List<Map<String, dynamic>>.from(results[0] as List);
        _cosmetics = List<Map<String, dynamic>>.from(results[1] as List);
        _zones = List<Map<String, dynamic>>.from(results[2] as List);
        _juiceBalance =
            ((results[3] as Map<String, dynamic>?)?['balance'] as int?) ?? 0;
        _loading = false;
      });
    }
  }

  Future<void> _purchaseObject(Map<String, dynamic> item) async {
    final cost = item['juice_cost'] as int? ?? 0;
    if (_juiceBalance < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough Juice!')),
      );
      return;
    }

    try {
      await supabase.rpc('spend_juice', params: {
        'p_amount': cost,
        'p_reference': 'world_object:${item['id']}',
      });

      await supabase.from('world_objects').insert({
        'catalog_id': item['id'],
        'owner_id': supabase.auth.currentUser!.id,
        'zone_id': _zones.isNotEmpty ? _zones.first['id'] : null,
      });

      setState(() => _juiceBalance -= cost);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Purchased ${item['name']}!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('World Builder'),
        actions: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
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
                  '$_juiceBalance',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Objects'),
            Tab(text: 'Cosmetics'),
            Tab(text: 'Zones'),
            Tab(text: 'Pods'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _ObjectsTab(
                    objects: _objects,
                    balance: _juiceBalance,
                    onPurchase: _purchaseObject),
                _CosmeticsTab(cosmetics: _cosmetics),
                _ZonesTab(zones: _zones),
                const _PodsTab(),
              ],
            ),
    );
  }
}

class _ObjectsTab extends StatelessWidget {
  const _ObjectsTab({
    required this.objects,
    required this.balance,
    required this.onPurchase,
  });

  final List<Map<String, dynamic>> objects;
  final int balance;
  final ValueChanged<Map<String, dynamic>> onPurchase;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (objects.isEmpty) {
      return const Center(child: Text('No objects available'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: objects.length,
      itemBuilder: (context, index) {
        final obj = objects[index];
        final cost = obj['juice_cost'] as int? ?? 0;
        final canAfford = balance >= cost;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    obj['category'] as String? ?? '',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  obj['name'] as String? ?? '',
                  style: theme.textTheme.titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (obj['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    obj['description'] as String,
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.colorScheme.outline,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const Spacer(),
                // Price + buy button
                Row(
                  children: [
                    const Text('\u{1F9C3}', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$cost',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Spacer(),
                    SizedBox(
                      height: 28,
                      child: FilledButton(
                        onPressed: canAfford ? () => onPurchase(obj) : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          textStyle: const TextStyle(fontSize: 12),
                        ),
                        child: const Text('Buy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CosmeticsTab extends StatelessWidget {
  const _CosmeticsTab({required this.cosmetics});

  final List<Map<String, dynamic>> cosmetics;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (cosmetics.isEmpty) {
      return const Center(child: Text('No cosmetics available'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: cosmetics.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final c = cosmetics[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.tertiaryContainer,
              child: const Text('\u{2728}', style: TextStyle(fontSize: 18)),
            ),
            title: Text(c['name'] as String? ?? ''),
            subtitle: Text(
              'Rank: ${c['min_rank'] ?? 'any'} · ${c['juice_cost'] ?? 0} Juice',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            trailing: FilledButton(
              onPressed: () {},
              child: const Text('Buy'),
            ),
          ),
        );
      },
    );
  }
}

class _ZonesTab extends StatelessWidget {
  const _ZonesTab({required this.zones});

  final List<Map<String, dynamic>> zones;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (zones.isEmpty) {
      return const Center(child: Text('No zones available'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: zones.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final z = zones[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primaryContainer,
              child: const Text('\u{1F30D}', style: TextStyle(fontSize: 18)),
            ),
            title: Text(z['name'] as String? ?? ''),
            subtitle: Text(
              'Min rank: ${z['min_rank'] ?? 'any'}',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.outline),
            ),
            trailing: FilledButton(
              onPressed: () {},
              child: const Text('Sponsor'),
            ),
          ),
        );
      },
    );
  }
}

class _PodsTab extends StatelessWidget {
  const _PodsTab();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('\u{1F3E0}', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(
            'Learning Pods',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a private learning pod for 200 Juice',
            style: TextStyle(color: theme.colorScheme.outline),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('Create Pod — 200 Juice'),
          ),
        ],
      ),
    );
  }
}
