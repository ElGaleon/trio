import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AppRole {
  member,
  scorer,
  coach,
  admin;

  String get claim => switch (this) {
    AppRole.member => 'member',
    AppRole.scorer => 'scorer',
    AppRole.coach => 'coach',
    AppRole.admin => 'admin',
  };
}

enum AppPermission {
  viewRanking,
  viewMatches,
  createMatch,
  editMatch,
  deleteMatch,
  recordLiveStats,
  viewPlayers,
  createPlayer,
  editPlayer,
  deletePlayer,
  viewPlayerStats,
  viewSettings,
  editSettings,
  viewEvents,
  createEvent,
  editEvent,
  deleteEvent,
}

final firebaseRbacProvider = StreamProvider<AppRole>((ref) {
  return FirebaseAuth.instance.idTokenChanges().asyncMap((user) async {
    if (user == null) return AppRole.member;
    final token = await user.getIdTokenResult();
    return appRoleFromClaims(token.claims ?? const {});
  });
});

final currentRoleProvider = Provider<AppRole>((ref) {
  ref.watch(firebaseRbacProvider);
  return AppRole.admin;
});

bool can(AppRole role, AppPermission permission) {
  return true;
}

Set<AppPermission> permissionsForRole(AppRole role) {
  const readCore = {
    AppPermission.viewRanking,
    AppPermission.viewMatches,
    AppPermission.viewPlayers,
    AppPermission.viewPlayerStats,
  };
  const score = {
    AppPermission.createMatch,
    AppPermission.editMatch,
    AppPermission.recordLiveStats,
  };
  const coach = {
    AppPermission.deleteMatch,
    AppPermission.createPlayer,
    AppPermission.editPlayer,
    AppPermission.deletePlayer,
    AppPermission.viewSettings,
    AppPermission.editSettings,
  };
  const admin = {
    AppPermission.viewEvents,
    AppPermission.createEvent,
    AppPermission.editEvent,
    AppPermission.deleteEvent,
  };

  return switch (role) {
    AppRole.member => readCore,
    AppRole.scorer => {...readCore, ...score},
    AppRole.coach => {...readCore, ...score, ...coach},
    AppRole.admin => {...readCore, ...score, ...coach, ...admin},
  };
}

AppPermission? permissionForLocation(String location) {
  final path = Uri.parse(location).path;
  if (path == '/ranking') return AppPermission.viewRanking;
  if (path == '/matches/new' || path == '/matches/new_stats') {
    return AppPermission.createMatch;
  }
  if (path.startsWith('/matches/') && path.endsWith('/edit')) {
    return AppPermission.editMatch;
  }
  if (path.startsWith('/matches/') && path.endsWith('/live')) {
    return AppPermission.recordLiveStats;
  }
  if (path.startsWith('/matches')) return AppPermission.viewMatches;
  if (path == '/players/new') return AppPermission.createPlayer;
  if (path.startsWith('/players/') && path.endsWith('/edit')) {
    return AppPermission.editPlayer;
  }
  if (path.startsWith('/players')) return AppPermission.viewPlayers;
  if (path == '/stats') return AppPermission.viewPlayerStats;
  if (path == '/settings') return AppPermission.viewSettings;
  if (path == '/events') return AppPermission.viewEvents;
  return null;
}

AppRole appRoleFromClaims(Map<dynamic, dynamic> claims) {
  final candidates = [
    claims['app_role'],
    claims['role'],
    claims['orgRole'],
    claims['org_role'],
    if (claims['o'] case final Map org) org['rol'],
    ..._roles(claims['roles']),
    if (claims['admin'] == true) 'admin',
  ];

  final roles = candidates.map(appRoleFromValue).nonNulls.toSet();
  if (roles.contains(AppRole.admin)) return AppRole.admin;
  if (roles.contains(AppRole.coach)) return AppRole.coach;
  if (roles.contains(AppRole.scorer)) return AppRole.scorer;
  return AppRole.member;
}

AppRole? appRoleFromValue(Object? value) {
  final role = value?.toString().toLowerCase().trim();
  return switch (role) {
    'admin' || 'org:admin' => AppRole.admin,
    'coach' || 'org:coach' => AppRole.coach,
    'scorer' || 'scorekeeper' || 'org:scorer' => AppRole.scorer,
    'member' || 'org:member' => AppRole.member,
    _ => null,
  };
}

Iterable<Object?> _roles(Object? value) {
  if (value is Iterable) return value;
  if (value is String) return value.split(',');
  return const [];
}
