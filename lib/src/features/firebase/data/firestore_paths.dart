class FirestorePaths {
  const FirestorePaths._();

  static const users = 'users';
  static const organizations = 'organizations';

  static String players(String orgId) => '$organizations/$orgId/players';
  static String player(String orgId, String id) => '${players(orgId)}/$id';

  static String matches(String orgId) => '$organizations/$orgId/matches';
  static String match(String orgId, String id) => '${matches(orgId)}/$id';

  static String events(String orgId) => '$organizations/$orgId/events';
  static String event(String orgId, String id) => '${events(orgId)}/$id';

  static String settings(String orgId) => '$organizations/$orgId/settings/app';
}
