import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'world_service.dart';

/// All language zones with presence counts.
final worldZonesProvider = FutureProvider<List<WorldZone>>(
  (ref) => WorldService.instance.getZones(),
);

/// Members currently in a pod.
final podMembersProvider = FutureProvider.family<List<PodMember>, String>(
  (ref, zoneId) => WorldService.instance.getPodMembers(zoneId),
);

/// Card drops in a zone.
final cardDropsProvider = FutureProvider.family<List<CardDrop>, String>(
  (ref, zoneId) => WorldService.instance.getCardDrops(zoneId),
);

/// Object catalog.
final worldCatalogProvider = FutureProvider<List<WorldObject>>(
  (ref) => WorldService.instance.getCatalog(),
);

/// User's Juice balance.
final worldJuiceProvider = FutureProvider<int>(
  (ref) => WorldService.instance.getJuiceBalance(),
);

/// Current pod the user is in.
final currentPodProvider = FutureProvider<String?>(
  (ref) => WorldService.instance.getCurrentPodId(),
);

/// Cosmetics catalog.
final worldCosmeticsProvider = FutureProvider<List<Map<String, dynamic>>>(
  (ref) => WorldService.instance.getCosmetics(),
);
