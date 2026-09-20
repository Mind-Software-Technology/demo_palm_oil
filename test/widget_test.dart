import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prototype_palm_oil/data.dart';
import 'package:prototype_palm_oil/main.dart';
import 'package:prototype_palm_oil/screens_manage.dart';
import 'package:prototype_palm_oil/screens_shared.dart';
import 'package:prototype_palm_oil/screens_tech.dart';
import 'package:prototype_palm_oil/theme.dart';

void main() {
  setUp(() => MockDB().initMockData());

  _layoutTests();

  testWidgets('login memilih peran lalu masuk ke dashboard teknisi', (tester) async {
    await tester.pumpWidget(const PalmCareApp());
    await tester.pump();

    expect(find.text('PalmCare CMMS'), findsOneWidget);
    expect(find.text('TEKNISI LAPANGAN'), findsOneWidget);

    await tester.tap(find.text('LANJUT MASUK SEBAGAI TEKNISI'));
    // SyncBadge berdenyut terus, jadi pumpAndSettle tidak pernah selesai.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('PERAWATAN RUTIN PKS'), findsOneWidget);
    expect(MockDB().currentUser?.role, Role.technician);
  });

  test('status work order: overdue, due today, dan progres checklist', () {
    final db = MockDB();
    final wo = db.workOrders.firstWhere((w) => w.id == 'WO-2026-1082');

    // Dijadwalkan 09:00 hari ini: overdue hanya setelah jam tersebut lewat.
    expect(wo.isDueToday, isTrue);
    expect(wo.isOverdue, DateTime.now().isAfter(wo.scheduledAt));

    expect(wo.progress, 0);
    wo.checklist[0].isChecked = true;
    wo.checklist[1].isChecked = false;
    expect(wo.answered, 2);
    expect(wo.safeCount, 1);
    expect(wo.findingCount, 1);
    expect(wo.allAnswered, isFalse);

    for (final c in wo.checklist) {
      c.isChecked ??= true;
    }
    expect(wo.allAnswered, isTrue);
    expect(wo.progress, 1);

    // Kembalikan ke kondisi awal agar tes lain tidak terpengaruh.
    for (final c in wo.checklist) {
      c.isChecked = null;
    }
  });

  test('ambang ukur menandai nilai di atas batas aman', () {
    final item = ChecklistItem(
      id: 'X',
      category: 'PENGUKURAN',
      taskName: 'Suhu bearing',
      description: 'Uji ambang',
      measureLabel: 'Suhu terukur',
      measureUnit: '°C',
      measureLimit: 65,
    );
    expect(item.overLimit, isFalse);
    item.measuredValue = 58.4;
    expect(item.overLimit, isFalse);
    item.measuredValue = 71.2;
    expect(item.overLimit, isTrue);
  });

  test('SLA breakdown mengikuti tingkat keparahan', () {
    Breakdown make(WOPriority p) => Breakdown(
      id: 'BR-T',
      equipment: MockDB().equipments.first,
      station: 'Stasiun Kempa (Press)',
      reportedBy: 'Tes',
      issueDescription: 'Uji SLA',
      priority: p,
      status: WOStatus.assigned,
      reportedAt: DateTime.now(),
    );

    expect(make(WOPriority.critical).sla, const Duration(minutes: 15));
    expect(make(WOPriority.high).sla, const Duration(hours: 1));
    expect(make(WOPriority.medium).sla, const Duration(hours: 4));
  });

  testWidgets('kalender bulanan menampilkan penanda dan mengirim hari terpilih', (tester) async {
    final today = dayOnly(DateTime.now());
    DateTime? picked;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MonthCalendar(
            selectedDay: today,
            onDaySelected: (d) => picked = d,
            markersFor: (day) => day.day == today.day ? [AppColors.danger] : const [],
          ),
        ),
      ),
    );
    await tester.pump();

    final target = today.day == 15 ? 16 : 15;
    await tester.tap(find.text('$target'));
    await tester.pump();

    expect(picked, isNotNull);
    expect(picked!.day, target);
  });
}

// ---------------------------------------------------------------------------
// LAYOUT PONSEL
// ---------------------------------------------------------------------------
//
// Layar ponsel 390x844 adalah target sebenarnya aplikasi ini. Tes berikut
// memuat tiap layar pada ukuran tersebut dan gagal bila ada RenderFlex yang
// meluber, karena luberan hanya terlihat saat lebar sempit.

void _layoutTests() {
  Future<void> pumpAt(WidgetTester tester, String name, Widget screen) async {
    tester.view.physicalSize = const Size(390 * 3, 844 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Kumpulkan sendiri semua error layout supaya pesan gagalnya menyebut
    // layar dan widget penyebabnya, bukan cuma "overflowed by N pixels".
    final errors = <String>[];
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      final info = details.informationCollector?.call().map((n) => n.toString()).join(' | ') ?? '';
      errors.add('[$name] ${details.exceptionAsString()} :: $info');
    };

    await tester.pumpWidget(
      MaterialApp(theme: ThemeData(useMaterial3: true, scaffoldBackgroundColor: AppColors.screenBg), home: screen),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    FlutterError.onError = previous;
    expect(errors, isEmpty, reason: errors.join(String.fromCharCode(10)));
  }

  WorkOrder woOpen() => MockDB().workOrders.firstWhere((w) => w.id == 'WO-2026-1082');
  WorkOrder woDone() => MockDB().workOrders.firstWhere((w) => w.id == 'WO-2026-1078');

  group('layout 390x844 tanpa luberan', () {
    testWidgets('login', (t) async {
      await pumpAt(t, 'LoginScreen', const LoginScreen());
    });

    testWidgets('layar teknisi', (t) async {
      MockDB().currentUser = MockDB().technician;
      await pumpAt(t, 'TechDashboard', const TechDashboard());
      await pumpAt(t, 'TechTasks', const TechTasks());
      await pumpAt(t, 'TaskDetailScreen', TaskDetailScreen(workOrder: woOpen()));
      await pumpAt(t, 'ChecklistScreen', ChecklistScreen(workOrder: woOpen()));
      await pumpAt(t, 'EvidenceScreen', EvidenceScreen(workOrder: woDone()));
      await pumpAt(t, 'LaporBreakdownScreen', const LaporBreakdownScreen());
    });

    testWidgets('layar supervisor', (t) async {
      MockDB().currentUser = MockDB().supervisor;
      await pumpAt(t, 'SupDashboard', const SupDashboard());
      await pumpAt(t, 'SupMaintenanceHub', const SupMaintenanceHub());
      await pumpAt(t, 'CreateWorkOrderScreen', CreateWorkOrderScreen(initialDate: DateTime.now()));
    });

    testWidgets('layar manajemen & bersama', (t) async {
      MockDB().currentUser = MockDB().manager;
      await pumpAt(t, 'MgtDashboard', const MgtDashboard());
      await pumpAt(t, 'MgtReportScreen', const MgtReportScreen());
      await pumpAt(t, 'EquipmentListScreen', const EquipmentListScreen());
      await pumpAt(t, 'HistoryScreen', const HistoryScreen());
      await pumpAt(t, 'NotificationScreen', const NotificationScreen());
      await pumpAt(t, 'ProfileScreen', const ProfileScreen());
    });
  });
}
