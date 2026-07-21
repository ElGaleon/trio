import 'package:flutter_test/flutter_test.dart';
import 'package:trio/src/features/organizations/application/organization_providers.dart';
import 'package:trio/src/features/organizations/domain/organization.dart';

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
}
