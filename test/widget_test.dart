// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:tuemergencia/core/auth/app_session.dart';
import 'package:tuemergencia/core/navigation/app_navigation.dart';
import 'package:tuemergencia/core/navigation/app_routes.dart';
import 'package:tuemergencia/features/auth/domain/models/role.dart';
import 'package:tuemergencia/main.dart';

void main() {
  testWidgets('App starts smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TuEmergenciaApp());
    await tester.pumpAndSettle();

    expect(find.text('Hola, Juan'), findsOneWidget);
    expect(find.text('Acciones esenciales'), findsOneWidget);
    expect(find.text('Servicios complementarios'), findsOneWidget);
  });

  test('navigation destinations are filtered by role', () {
    final patientRoutes = AppRoutes.destinationsForRole(
      Role.patient,
    ).map((destination) => destination.path).toSet();
    final doctorRoutes = AppRoutes.destinationsForRole(
      Role.doctor,
    ).map((destination) => destination.path).toSet();
    final pharmacyRoutes = AppRoutes.destinationsForRole(
      Role.pharmacy,
    ).map((destination) => destination.path).toSet();

    expect(patientRoutes, contains(AppRoutes.dashboard));
    expect(patientRoutes, contains(AppRoutes.patientProfile));
    expect(patientRoutes, contains(AppRoutes.ambulanceCheckout));
    expect(patientRoutes, isNot(contains(AppRoutes.pharmacy)));
    expect(patientRoutes, isNot(contains(AppRoutes.doctorDashboard)));

    expect(doctorRoutes, contains(AppRoutes.doctorDashboard));
    expect(doctorRoutes, contains(AppRoutes.medicalHistory));
    expect(doctorRoutes, isNot(contains(AppRoutes.pharmacyAdmin)));

    expect(pharmacyRoutes, contains(AppRoutes.pharmacyAdmin));
    expect(pharmacyRoutes, contains(AppRoutes.fullInventory));
    expect(pharmacyRoutes, isNot(contains(AppRoutes.dashboard)));
  });

  test('all navigation destinations are registered routes', () {
    for (final destination in AppRoutes.destinations) {
      expect(
        AppRoutes.routes,
        contains(destination.path),
        reason: '${destination.path} must be present in AppRoutes.routes',
      );
    }

    expect(AppRoutes.normalize(AppRoutes.videoCall), AppRoutes.appointments);
    expect(
      AppRoutes.normalize(AppRoutes.tracking),
      AppRoutes.ambulanceCheckout,
    );
    expect(AppRoutes.routes, contains(AppRoutes.erIncomingAlias));
    expect(AppRoutes.routes, contains(AppRoutes.ambulanceDriverAlias));
  });

  test('role home routes are registered', () {
    for (final role in Role.values) {
      final homeRoute = AppNavigation.homeRouteForRole(role);
      expect(
        AppRoutes.routes,
        contains(homeRoute),
        reason: '$role home route must be registered',
      );
      expect(
        AppRoutes.isAllowedForRole(homeRoute, role),
        isTrue,
        reason: '$role must be allowed to view its home route',
      );
    }
  });

  testWidgets('root module back returns to role home', (
    WidgetTester tester,
  ) async {
    AppSession.setRole(Role.patient);

    await tester.pumpWidget(
      MaterialApp(initialRoute: AppRoutes.pharmacy, routes: AppRoutes.routes),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    expect(find.text('Hola, Juan'), findsOneWidget);
    expect(find.text('Buscador Inteligente'), findsNothing);
  });
}
