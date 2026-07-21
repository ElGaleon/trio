import 'package:flutter_test/flutter_test.dart';
import 'package:trio/src/features/auth/application/rbac_provider.dart';

void main() {
  test('reads roles from Firebase claims', () {
    expect(appRoleFromClaims({'admin': true}), AppRole.admin);
    expect(appRoleFromClaims({'role': 'scorer'}), AppRole.scorer);
    expect(appRoleFromClaims({'app_role': 'coach'}), AppRole.coach);
    expect(appRoleFromClaims({'orgRole': 'org:admin'}), AppRole.admin);
    expect(
      appRoleFromClaims({
        'o': {'rol': 'admin'},
      }),
      AppRole.admin,
    );
    expect(
      appRoleFromClaims({
        'roles': ['member', 'org:coach'],
      }),
      AppRole.coach,
    );
    expect(appRoleFromClaims({'roles': 'member,org:admin'}), AppRole.admin);
    expect(appRoleFromClaims({'role': 'member'}), AppRole.member);
  });

  test('temporarily allows every permission to authenticated users', () {
    expect(can(AppRole.member, AppPermission.viewRanking), isTrue);
    expect(can(AppRole.member, AppPermission.createMatch), isTrue);

    expect(can(AppRole.scorer, AppPermission.createMatch), isTrue);
    expect(can(AppRole.scorer, AppPermission.recordLiveStats), isTrue);
    expect(can(AppRole.scorer, AppPermission.deletePlayer), isTrue);

    expect(can(AppRole.coach, AppPermission.deleteMatch), isTrue);
    expect(can(AppRole.coach, AppPermission.editSettings), isTrue);
    expect(can(AppRole.coach, AppPermission.viewEvents), isTrue);

    expect(can(AppRole.admin, AppPermission.viewEvents), isTrue);
    expect(can(AppRole.admin, AppPermission.deleteEvent), isTrue);
  });

  test('maps routes to required permissions', () {
    expect(permissionForLocation('/ranking'), AppPermission.viewRanking);
    expect(permissionForLocation('/matches/new'), AppPermission.createMatch);
    expect(permissionForLocation('/matches/abc/edit'), AppPermission.editMatch);
    expect(
      permissionForLocation('/matches/abc/live'),
      AppPermission.recordLiveStats,
    );
    expect(permissionForLocation('/players/new'), AppPermission.createPlayer);
    expect(permissionForLocation('/settings'), AppPermission.viewSettings);
    expect(permissionForLocation('/events'), AppPermission.viewEvents);
  });
}
