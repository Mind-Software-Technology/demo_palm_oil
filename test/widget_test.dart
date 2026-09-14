import 'package:flutter_test/flutter_test.dart';

import 'package:prototype_palm_oil/main.dart';

void main() {
  testWidgets('Login screen shows PalmCare title', (WidgetTester tester) async {
    await tester.pumpWidget(const PalmCareApp());

    expect(find.text('PalmCare'), findsOneWidget);
  });
}
