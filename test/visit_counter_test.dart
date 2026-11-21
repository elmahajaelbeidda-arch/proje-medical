import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shifa/core/admin_provider.dart';
import 'package:shifa/core/l10n.dart';
import 'package:shifa/core/visit_counter.dart';
import 'package:shifa/features/admin/demo_admins.dart';
import 'package:shifa/models/admin.dart';
import 'package:shifa/widgets/visit_counter.dart';

class FakeBackend implements VisitBackend {
  final recorded = <String>[];
  int total = 100;

  @override
  Future<void> record(String visitorId) async {
    recorded.add(visitorId);
    total++;
  }

  @override
  Future<VisitStats> stats() async => VisitStats(
    totalVisits: total,
    todayVisitors: 7,
    onlineNow: 3,
    registered: 42,
    beneficiaries: 12,
    updatedAt: DateTime(2026, 11, 21, 10, 5),
  );
}

void main() {
  test('server figures are read; hidden figures stay null', () {
    final s = VisitStats.fromJson({
      'total_visits': 46169,
      'today_visitors': 812,
      'online_now': 0,
      'registered': null,
      'beneficiaries': 1300,
    });
    expect(s.totalVisits, 46169);
    expect(s.todayVisitors, 812);
    expect(s.onlineNow, 1, reason: 'the viewer is online');
    expect(s.registered, isNull);
    expect(s.beneficiaries, 1300);
    expect(s.demo, isFalse);
  });

  test('demo figures are marked and grow with time', () async {
    final a = await DemoVisitBackend(clock: () => DateTime(2026, 11, 21, 9))
        .stats();
    final b = await DemoVisitBackend(clock: () => DateTime(2026, 11, 22, 9))
        .stats();
    expect(a.demo, isTrue);
    expect(b.totalVisits, greaterThan(a.totalVisits));
    expect(b.registered!, greaterThanOrEqualTo(a.registered!));
  });

  test('visitor ids are random and anonymous', () {
    final a = newVisitorId(), b = newVisitorId();
    expect(a.length, 32);
    expect(RegExp(r'^[0-9a-f]{32}$').hasMatch(a), isTrue);
    expect(a, isNot(b));
  });

  test('the counter is hidden until the association turns it on', () {
    expect(const AppSettings().showVisitorCounter, isFalse);
    expect(
      AppSettings.fromJson(const AppSettings().toJson()).showVisitorCounter,
      isFalse,
    );
  });

  test('only settings managers change what the counter shows', () {
    final c = ProviderContainer(
      overrides: [adminSeedAccountsProvider.overrideWithValue(demoAdmins())],
    );
    addTearDown(c.dispose);
    final n = c.read(adminProvider.notifier);
    expect(
      () => n.setVisitorCounter(
        visible: false,
        registered: true,
        beneficiaries: true,
      ),
      throwsA(isA<AdminPermissionDenied>()),
    );
    expect(n.login('admin@shifa.mr', 'Admin@2026'), LoginResult.success);
    n.setVisitorCounter(visible: true, registered: false, beneficiaries: true);
    final s = c.read(appSettingsProvider);
    expect(s.showRegisteredCount, isFalse);
    expect(AppSettings.fromJson(s.toJson()).showRegisteredCount, isFalse);
    expect(c.read(adminProvider).audit.first.action, 'au_counter_updated');
  });

  testWidgets('the card records the visit, shows the figures and refreshes', (
    t,
  ) async {
    final backend = FakeBackend();
    final c = ProviderContainer(
      overrides: [
        visitBackendProvider.overrideWithValue(backend),
        visitRefreshProvider.overrideWithValue(const Duration(seconds: 30)),
        appSettingsProvider.overrideWithValue(
          const AppSettings(showVisitorCounter: true),
        ),
      ],
    );
    await t.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp(
          locale: const Locale('ar'),
          supportedLocales: AppStrings.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: Scaffold(
            body: SingleChildScrollView(child: VisitorStatsCard()),
          ),
        ),
      ),
    );
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await t.pump(const Duration(seconds: 1));
    expect(backend.recorded, hasLength(1));
    expect(find.text('101'), findsOneWidget);
    expect(find.text('42'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);

    // Next automatic refresh.
    await t.pump(const Duration(seconds: 30));
    await t.pump(const Duration(seconds: 1));
    expect(backend.recorded, hasLength(2));
    expect(find.text('102'), findsOneWidget);

    await t.pumpWidget(const SizedBox());
    c.dispose();
  });
}
