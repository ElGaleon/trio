import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skrim/src/features/organizations/application/organization_providers.dart';
import 'package:skrim/src/features/organizations/domain/organization.dart';

void main() {
  const organizations = [
    Organization(
      id: 'org-a',
      name: 'Alpha',
      ownerId: 'user-1',
      members: ['user-1'],
    ),
    Organization(
      id: 'org-b',
      name: 'Beta',
      ownerId: 'user-2',
      members: ['user-1', 'user-2'],
    ),
  ];

  test('selects the only available organization automatically', () {
    expect(selectOrganization([organizations.first], null)?.id, 'org-a');
  });

  test('does not select automatically when multiple organizations exist', () {
    expect(selectOrganization(organizations, null), isNull);
  });

  test('selects only the requested organization', () {
    expect(selectOrganization(organizations, 'org-b')?.name, 'Beta');
  });

  test('ignores selections that are no longer available', () {
    expect(selectOrganization(organizations, 'missing'), isNull);
  });

  test(
    'loads the last selected organization from shared preferences',
    () async {
      SharedPreferences.setMockInitialValues({'lastOrganizationId': 'org-b'});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(selectedOrganizationIdProvider), isNull);
      await Future<void>.delayed(Duration.zero);

      expect(container.read(selectedOrganizationIdProvider), 'org-b');
    },
  );

  test('saves the selected organization in shared preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(selectedOrganizationIdProvider.notifier).set('org-a');
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lastOrganizationId'), 'org-a');
  });
}
