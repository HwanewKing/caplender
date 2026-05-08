// Smoke tests are deferred until we have Supabase mocking infrastructure
// (Phase 2 step 7+). The full widget tree calls bootstrap() / AuthService /
// AppSettings.create(), which require platform channels not available in the
// default test environment.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('placeholder — pending Supabase mock setup', () {
    expect(true, isTrue);
  });
}
