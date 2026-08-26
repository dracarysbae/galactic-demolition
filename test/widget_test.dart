import 'package:flutter_test/flutter_test.dart';

import 'package:galactic_demolition/main.dart';

void main() {
  testWidgets('App builds without throwing', (WidgetTester tester) async {
    await tester.pumpWidget(const GalacticDemolitionApp());
    await tester.pump();
  });
}
