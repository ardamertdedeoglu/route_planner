import 'package:flutter_test/flutter_test.dart';
import 'package:route_planner/main.dart';

void main() {
  testWidgets('App starts and shows home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const RoutePlannerApp());
    expect(find.text('Gezilerim'), findsOneWidget);
  });
}
