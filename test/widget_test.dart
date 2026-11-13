// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:aula_puntos_senati/main.dart';
import 'package:aula_puntos_senati/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:aula_puntos_senati/features/dashboard/domain/usecases/get_dashboard_metrics.dart';

void main() {
  testWidgets('muestra el dashboard Aula Puntos', (WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<GetDashboardMetrics>.value(
        value: GetDashboardMetrics(_FakeDashboardRepository()),
        child: const AulaPuntosSenatiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AULA PUNTOS'), findsOneWidget);
  });
}

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<Map<String, int>> getDashboardMetrics() async => {
        'grupos': 1,
        'estudiantes': 8,
        'sesiones': 1,
        'participaciones': 0,
        'totalPuntos': 0,
      };
}
