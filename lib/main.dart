import 'package:flutter/material.dart';

void main() {
  runApp(const PalmCareApp());
}

// --- DESIGN TOKENS (mengikuti PalmCare_Mockup.pptx) ---
class AppColors {
  static const primary = Color(0xFF0A4A69);
  static const primaryDark = Color(0xFF083A54);
  static const accentLight = Color(0xFFDCEAF3);
  static const screenBg = Color(0xFFF6F9FB);
  static const cardBorder = Color(0xFFE1EBF2);
  static const statusGreen = Color(0xFF1E8A5F);
  static const statusOrange = Color(0xFFD4900B);
  static const statusRed = Color(0xFFC0392B);
  static const textMuted = Color(0xFF6B7A85);
}

// --- SHARED UI COMPONENTS ---
class StatusDot extends StatelessWidget {
  final Color color;
  const StatusDot({Key? key, required this.color}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  const SectionLabel(this.text, {Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 0.4));
  }
}

class LinkButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  const LinkButton({Key? key, required this.text, required this.onPressed}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
    );
  }
}

class PillFilterTabs extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const PillFilterTabs({Key? key, required this.options, required this.selected, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.cardBorder)),
      child: Row(
        children: options.map((o) {
          final bool isSelected = o == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  o,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ScrollablePillFilterTabs extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  const ScrollablePillFilterTabs({Key? key, required this.options, required this.selected, required this.onSelected}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: options.map((o) {
          final bool isSelected = o == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: GestureDetector(
              onTap: () => onSelected(o),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
                ),
                child: Text(
                  o,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : AppColors.textMuted),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class DashedUploadBox extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final double height;
  const DashedUploadBox({Key? key, required this.label, required this.onTap, this.icon = Icons.folder_open, this.height = 150}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: CustomPaint(
        painter: _DashedBorderPainter(color: AppColors.primary, radius: 12),
        child: Container(
          height: height,
          width: double.infinity,
          decoration: BoxDecoration(color: AppColors.accentLight.withOpacity(0.5), borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(label, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  final double radius;
  _DashedBorderPainter({required this.color, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, size.width, size.height), Radius.circular(radius));
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      double distance = 0;
      const dashWidth = 6.0;
      const dashGap = 4.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(metric.extractPath(distance, next.clamp(0, metric.length)), paint);
        distance = next + dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) => false;
}

class KeyValueTable extends StatelessWidget {
  final List<MapEntry<String, Widget>> rows;
  const KeyValueTable({Key? key, required this.rows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(border: Border.all(color: AppColors.cardBorder), borderRadius: BorderRadius.circular(10)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: AppColors.screenBg,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: const Row(
              children: [
                Expanded(child: Text('Field', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
                Expanded(child: Text('Nilai', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textMuted))),
              ],
            ),
          ),
          for (int i = 0; i < rows.length; i++)
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.cardBorder)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Expanded(child: Text(rows[i].key, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
                  Expanded(child: rows[i].value),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// --- MODELS & ENUMS ---
enum Role { technician, supervisor, management }
enum EquipStatus { operational, warning, critical }
enum WOStatus { assigned, inProgress, waitingVerification, approved, rejected, closed }
enum WOPriority { minor, medium, high, critical }
enum WOType { preventive, breakdown, inspection }

class User {
  final String id;
  final String name;
  final Role role;
  final String station;

  User({required this.id, required this.name, required this.role, required this.station});
}

class Equipment {
  final String id;
  final String name;
  final String code;
  final String station;
  EquipStatus status;

  Equipment({required this.id, required this.name, required this.code, required this.station, required this.status});
}

class ChecklistItem {
  final String id;
  final String category;
  final String taskName;
  bool isChecked;
  String? note;

  ChecklistItem({required this.id, required this.category, required this.taskName, this.isChecked = false});
}

class WorkOrder {
  final String id;
  final Equipment equipment;
  final WOType type;
  final WOPriority priority;
  final User assignedTo;
  final DateTime scheduledDate;
  final int estimatedHours;
  WOStatus status;
  List<ChecklistItem> checklist;
  int evidenceCount;
  String? technicianNote;
  String? rejectReason;

  WorkOrder({
    required this.id,
    required this.equipment,
    required this.type,
    required this.priority,
    required this.assignedTo,
    required this.scheduledDate,
    required this.estimatedHours,
    required this.status,
    required this.checklist,
    this.evidenceCount = 0,
    this.technicianNote,
  });
}

class Breakdown {
  final String id;
  final Equipment equipment;
  final String reportedBy;
  final String issueDescription;
  final WOPriority priority;
  WOStatus status;
  final DateTime reportedAt;

  Breakdown({
    required this.id,
    required this.equipment,
    required this.reportedBy,
    required this.issueDescription,
    required this.priority,
    required this.status,
    required this.reportedAt,
  });
}

// --- MOCK DATABASE ---
class MockDB {
  static final MockDB _instance = MockDB._internal();
  factory MockDB() => _instance;
  MockDB._internal();

  User? currentUser;

  final List<User> users = [
    User(id: 'T1', name: 'Andi (Technician)', role: Role.technician, station: 'Pressing Station'),
    User(id: 'S1', name: 'Budi (Supervisor)', role: Role.supervisor, station: 'All Stations'),
    User(id: 'M1', name: 'Citra (Management)', role: Role.management, station: 'Mill Wide'),
  ];

  final List<Equipment> equipments = [
    Equipment(id: 'E1', name: 'Screw Press #01', code: 'EQ-SP-001', station: 'Pressing Station', status: EquipStatus.operational),
    Equipment(id: 'E2', name: 'Screw Press #02', code: 'EQ-SP-002', station: 'Pressing Station', status: EquipStatus.warning),
    Equipment(id: 'E3', name: 'Boiler #01', code: 'EQ-BL-001', station: 'Utilities', status: EquipStatus.critical),
    Equipment(id: 'E4', name: 'Digester #01', code: 'EQ-DG-001', station: 'Pressing Station', status: EquipStatus.operational),
    Equipment(id: 'E5', name: 'Pump #03', code: 'EQ-PM-003', station: 'Clarification', status: EquipStatus.operational),
  ];

  List<WorkOrder> workOrders = [];
  List<Breakdown> breakdowns = [];
  
  void initMockData() {
    if (workOrders.isNotEmpty) return;
    
    DateTime today = DateTime.now();
    
    // Seed Work Orders
    workOrders.addAll([
      WorkOrder(
        id: 'WO-2026-00921',
        equipment: equipments[1], // Screw Press 02
        type: WOType.preventive,
        priority: WOPriority.medium,
        assignedTo: users[0], // Andi
        scheduledDate: today.subtract(const Duration(days: 1)), // Overdue
        estimatedHours: 2,
        status: WOStatus.assigned,
        checklist: _generateChecklist(),
      ),
      WorkOrder(
        id: 'WO-2026-00919',
        equipment: equipments[2], // Boiler 01
        type: WOType.preventive,
        priority: WOPriority.high,
        assignedTo: users[0],
        scheduledDate: today, // Due Today
        estimatedHours: 4,
        status: WOStatus.inProgress,
        checklist: _generateChecklist(),
      ),
      WorkOrder(
        id: 'WO-2026-00915',
        equipment: equipments[3], // Digester
        type: WOType.inspection,
        priority: WOPriority.minor,
        assignedTo: users[0],
        scheduledDate: today,
        estimatedHours: 1,
        status: WOStatus.waitingVerification,
        checklist: _generateChecklist().map((c) => c..isChecked = true).toList(),
        evidenceCount: 2,
        technicianNote: 'Aman terkendali',
      ),
      WorkOrder(
        id: 'WO-2026-00912',
        equipment: equipments[4], // Pump 03
        type: WOType.preventive,
        priority: WOPriority.medium,
        assignedTo: users[0],
        scheduledDate: today.subtract(const Duration(days: 3)),
        estimatedHours: 3,
        status: WOStatus.approved,
        checklist: _generateChecklist().map((c) => c..isChecked = true).toList(),
      ),
    ]);

    // Seed Breakdowns
    breakdowns.addAll([
      Breakdown(
        id: 'BR-001',
        equipment: equipments[2],
        reportedBy: 'Andi (Technician)',
        issueDescription: 'High Temperature alert, sudden stop.',
        priority: WOPriority.critical,
        status: WOStatus.assigned,
        reportedAt: today.subtract(const Duration(hours: 2)),
      ),
      Breakdown(
        id: 'BR-002',
        equipment: equipments[1],
        reportedBy: 'Andi (Technician)',
        issueDescription: 'Gearbox leakage spotted.',
        priority: WOPriority.high,
        status: WOStatus.inProgress,
        reportedAt: today.subtract(const Duration(days: 1)),
      ),
    ]);
  }

  List<ChecklistItem> _generateChecklist() {
    return [
      ChecklistItem(id: 'C1', category: 'MECHANICAL', taskName: 'Check Bearing Condition'),
      ChecklistItem(id: 'C2', category: 'MECHANICAL', taskName: 'Inspect Gearbox Oil Level'),
      ChecklistItem(id: 'C3', category: 'MECHANICAL', taskName: 'Check Coupling Alignment'),
      ChecklistItem(id: 'C4', category: 'LUBRICATION', taskName: 'Apply Grease to moving parts'),
    ];
  }
}

// --- HELPERS ---
class Helper {
  static Color getStatusColor(dynamic status) {
    if (status == EquipStatus.critical || status == WOStatus.rejected || status == WOPriority.critical) return AppColors.statusRed;
    if (status == EquipStatus.warning || status == WOStatus.inProgress || status == WOStatus.waitingVerification || status == WOPriority.high) return AppColors.statusOrange;
    if (status == EquipStatus.operational || status == WOStatus.approved || status == WOStatus.closed) return AppColors.statusGreen;
    return AppColors.textMuted;
  }

  // Simple Date Formatter to avoid external dependencies in standard environments
  static String formatDate(DateTime date) {
    List<String> months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static Widget statusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(text, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  static bool isOverdue(WorkOrder wo) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final scheduled = DateTime(wo.scheduledDate.year, wo.scheduledDate.month, wo.scheduledDate.day);
    return scheduled.isBefore(today) && 
           (wo.status == WOStatus.assigned || wo.status == WOStatus.inProgress || wo.status == WOStatus.rejected);
  }
  
  static bool isDueToday(WorkOrder wo) {
    final now = DateTime.now();
    return wo.scheduledDate.year == now.year && wo.scheduledDate.month == now.month && wo.scheduledDate.day == now.day &&
           (wo.status == WOStatus.assigned || wo.status == WOStatus.inProgress || wo.status == WOStatus.rejected);
  }
}

// --- MAIN APP ---
class PalmCareApp extends StatelessWidget {
  const PalmCareApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PalmCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.screenBg,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary, primary: AppColors.primary),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.cardBorder),
          ),
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cardBorder)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.accentLight,
          surfaceTintColor: Colors.transparent,
          elevation: 4,
          height: 64,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(fontSize: 11, fontWeight: selected ? FontWeight.w700 : FontWeight.w500, color: selected ? AppColors.primary : AppColors.textMuted);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? AppColors.primary : AppColors.textMuted, size: 22);
          }),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// --- LOGIN SCREEN ---
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  void initState() {
    super.initState();
    MockDB().initMockData();
  }

  void _loginAs(User user) {
    MockDB().currentUser = user;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.engineering, size: 80, color: Colors.white),
              const SizedBox(height: 16),
              const Text('PalmCare', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
              const Text('CMMS Mobile', style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 48),
              const Text('Pilih Role Login:', style: TextStyle(color: Colors.white, fontSize: 16)),
              const SizedBox(height: 16),
              ...MockDB().users.map((user) => Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary),
                    onPressed: () => _loginAs(user),
                    child: Text('Login sebagai ${user.name}'),
                  ),
                ),
              )).toList(),
            ],
          ),
        ),
      ),
    );
  }
}

// --- MAIN NAVIGATION ---
class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);
  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  List<Widget> _getScreens() {
    final role = MockDB().currentUser!.role;
    if (role == Role.technician) {
      return [const TechDashboard(), const TechTasks(), const EquipmentListScreen(), const NotificationScreen(), const ProfileScreen()];
    } else if (role == Role.supervisor) {
      return [const SupDashboard(), const SupMaintenanceHub(), const EquipmentListScreen(), const NotificationScreen(), const ProfileScreen()];
    } else {
      return [const MgtDashboard(), const EquipmentListScreen(), const HistoryScreen(), const MgtReportScreen(), const ProfileScreen()];
    }
  }

  List<NavigationDestination> _getNavItems() {
    final role = MockDB().currentUser!.role;
    if (role == Role.technician) {
      return const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Tasks'),
        NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Equip.'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notif.'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
      ];
    } else if (role == Role.supervisor) {
      return const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.handyman_outlined), selectedIcon: Icon(Icons.handyman), label: 'Maint.'),
        NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Equip.'),
        NavigationDestination(icon: Icon(Icons.notifications_outlined), selectedIcon: Icon(Icons.notifications), label: 'Notif.'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
      ];
    } else {
      return const [
        NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(icon: Icon(Icons.build_outlined), selectedIcon: Icon(Icons.build), label: 'Equip.'),
        NavigationDestination(icon: Icon(Icons.history_outlined), selectedIcon: Icon(Icons.history), label: 'Riwayat'),
        NavigationDestination(icon: Icon(Icons.analytics_outlined), selectedIcon: Icon(Icons.analytics), label: 'Laporan'),
        NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profil'),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _getScreens()[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: _getNavItems(),
      ),
    );
  }
}

// --- SHARED WIDGETS ---
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color color;

  const StatCard({Key? key, required this.title, required this.value, required this.color}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// TECHNICIAN SCREENS
// ==========================================

class TechDashboard extends StatefulWidget {
  const TechDashboard({Key? key}) : super(key: key);
  @override
  State<TechDashboard> createState() => _TechDashboardState();
}

class _TechDashboardState extends State<TechDashboard> {
  @override
  Widget build(BuildContext context) {
    final myTasks = MockDB().workOrders.where((w) => w.assignedTo.id == MockDB().currentUser!.id).toList();
    final total = myTasks.length;
    final dueToday = myTasks.where((w) => Helper.isDueToday(w)).length;
    final overdue = myTasks.where((w) => Helper.isOverdue(w)).length;
    final completed = myTasks.where((w) => w.status == WOStatus.approved || w.status == WOStatus.waitingVerification).length;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Halo, ${MockDB().currentUser!.name.split(' ')[0]}'),
            Text(Helper.formatDate(DateTime.now()), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.normal)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              StatCard(title: 'Total', value: '$total', color: AppColors.primary),
              StatCard(title: 'Due Today', value: '$dueToday', color: AppColors.statusOrange),
              StatCard(title: 'Overdue', value: '$overdue', color: AppColors.statusRed),
              StatCard(title: 'Selesai', value: '$completed', color: AppColors.statusGreen),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel("TODAY'S TASKS"),
          const SizedBox(height: 8),
          ...myTasks.where((w) => Helper.isDueToday(w) || Helper.isOverdue(w)).map((wo) => _buildTaskTile(wo, context)).toList(),
        ],
      ),
    );
  }

  Widget _buildTaskTile(WorkOrder wo, BuildContext context) {
    Color indicatorColor = Helper.isOverdue(wo) ? AppColors.statusRed : (Helper.isDueToday(wo) ? AppColors.statusOrange : AppColors.statusGreen);
    String statusLabel = Helper.isOverdue(wo) ? 'Overdue' : (Helper.isDueToday(wo) ? 'Due Today' : 'Scheduled');

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: StatusDot(color: indicatorColor),
        title: Text('${wo.equipment.name} • ${wo.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text('$statusLabel • ${wo.equipment.station}', style: const TextStyle(color: AppColors.textMuted)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(workOrder: wo)));
          setState(() {});
        },
      ),
    );
  }
}

class TechTasks extends StatefulWidget {
  const TechTasks({Key? key}) : super(key: key);
  @override
  State<TechTasks> createState() => _TechTasksState();
}

class _TechTasksState extends State<TechTasks> {
  String filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    List<WorkOrder> tasks = MockDB().workOrders.where((w) => w.assignedTo.id == MockDB().currentUser!.id).toList();
    if (filter == 'Due Today') tasks = tasks.where((w) => Helper.isDueToday(w)).toList();
    if (filter == 'Overdue') tasks = tasks.where((w) => Helper.isOverdue(w)).toList();
    if (filter == 'Selesai') tasks = tasks.where((w) => w.status == WOStatus.approved || w.status == WOStatus.waitingVerification).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My Tasks')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Cari equipment / work order',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ScrollablePillFilterTabs(
              options: const ['Semua', 'Due Today', 'Overdue', 'Selesai'],
              selected: filter,
              onSelected: (f) => setState(() => filter = f),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final wo = tasks[index];
                Color dotColor = Helper.isOverdue(wo) ? AppColors.statusRed : (wo.status == WOStatus.approved ? AppColors.statusGreen : AppColors.statusOrange);
                return Card(
                  child: ListTile(
                    leading: StatusDot(color: dotColor),
                    title: Text('${wo.id} • ${wo.equipment.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${wo.type.name.toUpperCase()} • ${Helper.formatDate(wo.scheduledDate)}', style: const TextStyle(color: AppColors.textMuted)),
                    trailing: LinkButton(
                      text: 'Lihat',
                      onPressed: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(workOrder: wo)));
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TaskDetailScreen extends StatefulWidget {
  final WorkOrder workOrder;
  const TaskDetailScreen({Key? key, required this.workOrder}) : super(key: key);
  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final wo = widget.workOrder;
    return Scaffold(
      appBar: AppBar(title: Text(wo.id)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('EQUIPMENT'),
          const SizedBox(height: 8),
          Text(wo.equipment.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text('${wo.equipment.station} • ${wo.equipment.code}'),
          const SizedBox(height: 24),
          const SectionLabel('DETAIL WORK ORDER'),
          const SizedBox(height: 8),
          KeyValueTable(
            rows: [
              MapEntry('Type', Text(wo.type.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold))),
              MapEntry('Priority', Text(wo.priority.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Helper.getStatusColor(wo.priority)))),
              MapEntry('Scheduled', Text(Helper.formatDate(wo.scheduledDate), style: const TextStyle(fontWeight: FontWeight.bold))),
              MapEntry('Durasi', Text('${wo.estimatedHours} Jam', style: const TextStyle(fontWeight: FontWeight.bold))),
              MapEntry('Status', Text(wo.status.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Helper.getStatusColor(wo.status)))),
            ],
          ),
          if (wo.status == WOStatus.rejected && wo.rejectReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.statusRed.withOpacity(0.06), border: Border.all(color: AppColors.statusRed), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Alasan Reject:', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusRed)),
                  const SizedBox(height: 4),
                  Text(wo.rejectReason!, style: const TextStyle(color: AppColors.statusRed)),
                ],
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _buildActionButton(wo),
        ),
      ),
    );
  }

  Widget _buildActionButton(WorkOrder wo) {
    if (MockDB().currentUser!.role != Role.technician) return const SizedBox.shrink();

    if (wo.status == WOStatus.assigned || wo.status == WOStatus.rejected) {
      return ElevatedButton(
        onPressed: () {
          setState(() => wo.status = WOStatus.inProgress);
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChecklistScreen(workOrder: wo)));
        },
        child: const Text('Start Maintenance'),
      );
    } else if (wo.status == WOStatus.inProgress) {
      return ElevatedButton(
        onPressed: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => ChecklistScreen(workOrder: wo))),
        child: const Text('Lanjutkan Checklist'),
      );
    }
    return const SizedBox.shrink();
  }

}

class ChecklistScreen extends StatefulWidget {
  final WorkOrder workOrder;
  const ChecklistScreen({Key? key, required this.workOrder}) : super(key: key);
  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  bool get _isAllChecked => widget.workOrder.checklist.every((c) => c.isChecked);

  @override
  Widget build(BuildContext context) {
    Map<String, List<ChecklistItem>> grouped = {};
    for (var item in widget.workOrder.checklist) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Checklist & Inspection')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionLabel(entry.key),
              Card(
                margin: const EdgeInsets.only(top: 8, bottom: 24),
                child: Column(
                  children: entry.value.map((item) => CheckboxListTile(
                    title: Text(item.taskName),
                    value: item.isChecked,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => item.isChecked = val ?? false);
                    },
                  )).toList(),
                ),
              ),
            ],
          );
        }).toList()
        ..add(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionLabel('INSPECTION NOTES'),
              const SizedBox(height: 8),
              TextField(
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan catatan temuan...',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                onChanged: (val) => widget.workOrder.technicianNote = val,
                controller: TextEditingController(text: widget.workOrder.technicianNote),
              ),
              const SizedBox(height: 80),
            ],
          )
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _isAllChecked ? AppColors.primary : Colors.grey,
        onPressed: _isAllChecked ? () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => EvidenceScreen(workOrder: widget.workOrder)));
        } : () {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selesaikan semua checklist terlebih dahulu.')));
        },
        label: const Text('Lanjut ke Evidence', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.arrow_forward, color: Colors.white),
      ),
    );
  }
}

class EvidenceScreen extends StatefulWidget {
  final WorkOrder workOrder;
  const EvidenceScreen({Key? key, required this.workOrder}) : super(key: key);
  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  @override
  Widget build(BuildContext context) {
    int checkedCount = widget.workOrder.checklist.where((c) => c.isChecked).length;
    int totalCount = widget.workOrder.checklist.length;

    return Scaffold(
      appBar: AppBar(title: const Text('Evidence & Submit')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('UPLOAD FOTO BUKTI'),
          const SizedBox(height: 8),
          DashedUploadBox(
            icon: Icons.camera_alt,
            label: 'Tambah Foto (${widget.workOrder.evidenceCount} diunggah)',
            onTap: () {
              setState(() => widget.workOrder.evidenceCount++);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto berhasil ditambahkan (Dummy)')));
            },
          ),
          const SizedBox(height: 32),
          const SectionLabel('RINGKASAN'),
          const SizedBox(height: 8),
          KeyValueTable(
            rows: [
              MapEntry('Checklist Selesai', Text('$checkedCount/$totalCount', style: const TextStyle(fontWeight: FontWeight.bold))),
              MapEntry('Catatan', Text(widget.workOrder.technicianNote?.isNotEmpty == true ? 'Ada temuan' : 'Tidak ada', style: const TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: widget.workOrder.evidenceCount > 0 ? () {
              setState(() {
                widget.workOrder.status = WOStatus.waitingVerification;
              });
              Navigator.of(context).popUntil((route) => route.isFirst);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Work Order disubmit untuk verifikasi.')));
            } : () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Minimal 1 foto evidence wajib diunggah.')));
            },
            style: ElevatedButton.styleFrom(backgroundColor: widget.workOrder.evidenceCount > 0 ? AppColors.primary : Colors.grey),
            child: const Text('Complete Maintenance'),
          ),
        ),
      ),
    );
  }
}

class LaporBreakdownScreen extends StatefulWidget {
  const LaporBreakdownScreen({Key? key}) : super(key: key);
  @override
  State<LaporBreakdownScreen> createState() => _LaporBreakdownScreenState();
}

class _LaporBreakdownScreenState extends State<LaporBreakdownScreen> {
  Equipment? selectedEq;
  WOPriority priority = WOPriority.medium;
  final TextEditingController _descController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lapor Breakdown')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionLabel('PILIH EQUIPMENT'),
          const SizedBox(height: 8),
          DropdownButtonFormField<Equipment>(
            decoration: const InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder()),
            items: MockDB().equipments.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
            onChanged: (val) => setState(() => selectedEq = val),
            value: selectedEq,
            hint: const Text('Pilih...'),
          ),
          const SizedBox(height: 16),
          const SectionLabel('MASALAH'),
          const SizedBox(height: 8),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(hintText: 'Jelaskan kerusakan...'),
          ),
          const SizedBox(height: 16),
          const SectionLabel('PRIORITAS'),
          const SizedBox(height: 8),
          SegmentedButton<WOPriority>(
            segments: const [
              ButtonSegment(value: WOPriority.minor, label: Text('Minor')),
              ButtonSegment(value: WOPriority.medium, label: Text('Major')),
              ButtonSegment(value: WOPriority.critical, label: Text('Critical')),
            ],
            selected: {priority},
            onSelectionChanged: (set) => setState(() => priority = set.first),
          ),
          const SizedBox(height: 24),
          const SectionLabel('FOTO KONDISI (OPSIONAL)'),
          const SizedBox(height: 8),
          DashedUploadBox(
            icon: Icons.camera_alt,
            label: 'Tambah Foto',
            height: 120,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Foto ditambahkan (Dummy)')));
            },
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () {
              if (selectedEq == null || _descController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap lengkapi form.')));
                return;
              }
              MockDB().breakdowns.insert(0, Breakdown(
                id: 'BR-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                equipment: selectedEq!,
                reportedBy: MockDB().currentUser!.name,
                issueDescription: _descController.text,
                priority: priority,
                status: WOStatus.assigned,
                reportedAt: DateTime.now(),
              ));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Breakdown berhasil dilaporkan.')));
            },
            child: const Text('Submit Breakdown', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// SUPERVISOR SCREENS
// ==========================================

class SupDashboard extends StatelessWidget {
  const SupDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final allTasks = MockDB().workOrders;
    final dueToday = allTasks.where((w) => Helper.isDueToday(w)).length;
    final inProgress = allTasks.where((w) => w.status == WOStatus.inProgress).length;
    final overdue = allTasks.where((w) => Helper.isOverdue(w)).length;
    final completed = allTasks.where((w) => w.status == WOStatus.approved).length;

    final criticalIssues = MockDB().breakdowns.where((b) => b.priority == WOPriority.critical && b.status != WOStatus.closed).toList();

    return Scaffold(
      appBar: AppBar(title: Text('Dashboard Supervisor - ${MockDB().currentUser!.name.split(' ')[0]}')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              StatCard(title: 'Due Today', value: '$dueToday', color: AppColors.statusOrange),
              StatCard(title: 'In Progress', value: '$inProgress', color: AppColors.primary),
              StatCard(title: 'Overdue', value: '$overdue', color: AppColors.statusRed),
              StatCard(title: 'Selesai', value: '$completed', color: AppColors.statusGreen),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _kpiCard('PM Compliance', '92.8%', AppColors.statusGreen)),
              const SizedBox(width: 8),
              Expanded(child: _kpiCard('Equip. Health', '96.4%', AppColors.primary)),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel("CRITICAL ISSUES"),
          const SizedBox(height: 8),
          if (criticalIssues.isEmpty) const Text('Tidak ada isu kritikal saat ini.'),
          ...criticalIssues.map((b) => Card(
            color: AppColors.statusRed.withOpacity(0.06),
            child: ListTile(
              leading: const Icon(Icons.warning, color: AppColors.statusRed),
              title: Text(b.equipment.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.statusRed)),
              subtitle: Text(b.issueDescription, style: const TextStyle(color: AppColors.textMuted)),
              trailing: LinkButton(
                text: 'Detail',
                onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Navigasi ke Detail Breakdown'))),
              ),
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

class SupMaintenanceHub extends StatelessWidget {
  const SupMaintenanceHub({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Maintenance Management'),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Jadwal & WO'),
              Tab(text: 'Verifikasi'),
              Tab(text: 'Breakdown'),
              Tab(text: 'Laporan'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            SupScheduleTab(),
            SupVerifyTab(),
            SupBreakdownTab(),
            SupReportTab(),
          ],
        ),
      ),
    );
  }
}

class SupScheduleTab extends StatefulWidget {
  const SupScheduleTab({Key? key}) : super(key: key);
  @override
  State<SupScheduleTab> createState() => _SupScheduleTabState();
}

class _SupScheduleTabState extends State<SupScheduleTab> {
  @override
  Widget build(BuildContext context) {
    final tasks = MockDB().workOrders;
    
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
            child: const Center(child: Text('[ Placeholder Kalender Bulanan ]\nBerisi marker jadwal PM', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted))),
          ),
          const SizedBox(height: 16),
          const SectionLabel('DAFTAR JADWAL MENDATANG'),
          const SizedBox(height: 8),
          ...tasks.where((w) => w.status != WOStatus.approved).map((wo) => Card(
            child: ListTile(
              title: Text(wo.equipment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${wo.type.name.toUpperCase()} • ${Helper.formatDate(wo.scheduledDate)}', style: const TextStyle(color: AppColors.textMuted)),
              trailing: Text(wo.assignedTo.name.split(' ')[0], style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
            ),
          )).toList(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateWODialog(context);
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Buat WO Baru', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  void _showCreateWODialog(BuildContext context) {
    Equipment? eq;
    User? tech;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Buat Work Order Baru'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Equipment>(
                  decoration: const InputDecoration(labelText: 'Equipment'),
                  items: MockDB().equipments.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                  onChanged: (v) => setState(() => eq = v),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<User>(
                  decoration: const InputDecoration(labelText: 'Assign Technician'),
                  items: MockDB().users.where((u) => u.role == Role.technician).map((u) => DropdownMenuItem(value: u, child: Text(u.name))).toList(),
                  onChanged: (v) => setState(() => tech = v),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                if (eq != null && tech != null) {
                  MockDB().workOrders.add(WorkOrder(
                    id: 'WO-NEW-${DateTime.now().second}',
                    equipment: eq!,
                    type: WOType.preventive,
                    priority: WOPriority.medium,
                    assignedTo: tech!,
                    scheduledDate: DateTime.now().add(const Duration(days: 1)),
                    estimatedHours: 2,
                    status: WOStatus.assigned,
                    checklist: [ChecklistItem(id: '1', category: 'General', taskName: 'General Inspection')],
                  ));
                  Navigator.pop(context);
                  this.setState(() {}); // refresh list
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('WO berhasil dibuat & ditugaskan.')));
                }
              },
              child: const Text('Simpan & Assign'),
            ),
          ],
        ),
      ),
    );
  }
}

class SupVerifyTab extends StatefulWidget {
  const SupVerifyTab({Key? key}) : super(key: key);
  @override
  State<SupVerifyTab> createState() => _SupVerifyTabState();
}

class _SupVerifyTabState extends State<SupVerifyTab> {
  @override
  Widget build(BuildContext context) {
    final pending = MockDB().workOrders.where((w) => w.status == WOStatus.waitingVerification).toList();

    if (pending.isEmpty) {
      return const Center(child: Text('Tidak ada pekerjaan menunggu verifikasi.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pending.length,
      itemBuilder: (context, index) {
        final wo = pending[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(wo.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Helper.statusBadge('Menunggu', AppColors.statusOrange),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${wo.equipment.name} • ${wo.assignedTo.name}', style: const TextStyle(color: AppColors.textMuted)),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Checklist: 100%'),
                    Text('Evidence: ${wo.evidenceCount} Foto'),
                  ],
                ),
                if (wo.technicianNote != null && wo.technicianNote!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text('Catatan: "${wo.technicianNote}"', style: const TextStyle(fontStyle: FontStyle.italic, color: AppColors.textMuted)),
                  ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.statusRed, side: const BorderSide(color: AppColors.statusRed)),
                      onPressed: () => _rejectDialog(wo),
                      child: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        setState(() => wo.status = WOStatus.approved);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pekerjaan disetujui.')));
                      },
                      child: const Text('Approve'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _rejectDialog(WorkOrder wo) {
    final tc = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Pekerjaan'),
        content: TextField(
          controller: tc,
          decoration: const InputDecoration(hintText: 'Masukkan alasan penolakan', border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusRed),
            onPressed: () {
              if (tc.text.isNotEmpty) {
                setState(() {
                  wo.status = WOStatus.rejected;
                  wo.rejectReason = tc.text;
                });
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pekerjaan dikembalikan ke Technician.')));
              }
            },
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class SupBreakdownTab extends StatefulWidget {
  const SupBreakdownTab({Key? key}) : super(key: key);
  @override
  State<SupBreakdownTab> createState() => _SupBreakdownTabState();
}

class _SupBreakdownTabState extends State<SupBreakdownTab> {
  String filter = 'Baru';

  @override
  Widget build(BuildContext context) {
    List<Breakdown> breakdowns = MockDB().breakdowns;
    if (filter == 'Baru') {
      breakdowns = breakdowns.where((b) => b.status == WOStatus.assigned).toList();
    } else if (filter == 'Ditangani') {
      breakdowns = breakdowns.where((b) => b.status == WOStatus.inProgress).toList();
    } else {
      breakdowns = breakdowns.where((b) => b.status == WOStatus.closed).toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: PillFilterTabs(
            options: const ['Baru', 'Ditangani', 'Selesai'],
            selected: filter,
            onSelected: (f) => setState(() => filter = f),
          ),
        ),
        Expanded(
          child: breakdowns.isEmpty
              ? const Center(child: Text('Tidak ada laporan.', style: TextStyle(color: AppColors.textMuted)))
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: breakdowns.length,
                  itemBuilder: (context, index) {
                    final b = breakdowns[index];
        return Card(
          child: ListTile(
            leading: Icon(Icons.warning, color: Helper.getStatusColor(b.priority)),
            title: Text(b.equipment.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(b.issueDescription, style: const TextStyle(color: AppColors.textMuted)),
                const SizedBox(height: 4),
                Text('Laporan: ${b.reportedBy} • ${Helper.formatDate(b.reportedAt)}', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
              ],
            ),
            trailing: b.status == WOStatus.assigned
              ? LinkButton(
                  text: 'Assign',
                  onPressed: () {
                    setState(() => b.status = WOStatus.inProgress);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Teknisi di-assign untuk breakdown.')));
                  },
                )
              : Helper.statusBadge('Ditangani', AppColors.primary),
          ),
        );
                  },
                ),
        ),
      ],
    );
  }
}

class SupReportTab extends StatelessWidget {
  const SupReportTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionLabel('RINGKASAN BULAN INI'),
        const SizedBox(height: 8),
        Row(
          children: const [
            StatCard(title: 'Total WO', value: '120', color: AppColors.primary),
            StatCard(title: 'Selesai', value: '108', color: AppColors.statusGreen),
            StatCard(title: 'Overdue', value: '7', color: AppColors.statusRed),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Breakdown per Kategori', style: TextStyle(fontWeight: FontWeight.bold)),
                const Divider(),
                _statRow('Critical', '3', AppColors.statusRed),
                _statRow('Major', '5', AppColors.statusOrange),
                _statRow('Minor', '6', AppColors.textMuted),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fitur Export (Fase 2)'))),
          icon: const Icon(Icons.download),
          label: const Text('Export Laporan (PDF)'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary)),
        ),
      ],
    );
  }

  Widget _statRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)), const SizedBox(width: 8), Text(label)]),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ==========================================
// MANAGEMENT SCREENS
// ==========================================

class MgtDashboard extends StatelessWidget {
  const MgtDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Management Dashboard')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Expanded(child: _kpiCard('PM Compliance', '92.8%', AppColors.statusGreen)),
              const SizedBox(width: 8),
              Expanded(child: _kpiCard('Equip. Health', '96.4%', AppColors.primary)),
            ],
          ),
          const SizedBox(height: 24),
          const SectionLabel('BREAKDOWN BULAN INI'),
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _circleStat('3', 'Critical', AppColors.statusRed),
                  _circleStat('5', 'Major', AppColors.statusOrange),
                  _circleStat('6', 'Minor', AppColors.textMuted),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const SectionLabel('RINGKASAN MAINTENANCE'),
          const SizedBox(height: 8),
          Row(
            children: const [
              StatCard(title: 'Total', value: '120', color: AppColors.primary),
              StatCard(title: 'Selesai', value: '108', color: AppColors.statusGreen),
              StatCard(title: 'Overdue', value: '7', color: AppColors.statusRed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _circleStat(String value, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 60, height: 60,
          decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: color, width: 4)),
          alignment: Alignment.center,
          child: Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.black87)),
      ],
    );
  }
}

class MgtReportScreen extends StatelessWidget {
  const MgtReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan'),
          bottom: const TabBar(tabs: [Tab(text: 'Mingguan'), Tab(text: 'Bulanan')]),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                Expanded(child: _statBox('PM Compliance', '92.8%')),
                const SizedBox(width: 8),
                Expanded(child: _statBox('Breakdown', '14')),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Column(
                children: [
                  _listRow('Total Maintenance', '120'),
                  const Divider(height: 1),
                  _listRow('Selesai', '108'),
                  const Divider(height: 1),
                  _listRow('Overdue', '7', color: AppColors.statusRed),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.cardBorder)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary)),
          Text(title, style: const TextStyle(color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Widget _listRow(String label, String value, {Color? color}) {
    return ListTile(
      title: Text(label),
      trailing: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
    );
  }
}

// ==========================================
// SHARED SCREENS
// ==========================================

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({Key? key}) : super(key: key);
  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  String searchQuery = '';
  String stationFilter = 'Semua';

  @override
  Widget build(BuildContext context) {
    List<Equipment> list = MockDB().equipments.where((e) => e.name.toLowerCase().contains(searchQuery.toLowerCase())).toList();
    if (stationFilter != 'Semua') {
      list = list.where((e) => e.station == stationFilter).toList();
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Equipment')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => searchQuery = v),
              decoration: const InputDecoration(
                hintText: 'Cari equipment...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          if (MockDB().currentUser!.role == Role.supervisor || MockDB().currentUser!.role == Role.management)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ScrollablePillFilterTabs(
                options: const ['Semua', 'Pressing Station', 'Utilities', 'Clarification'],
                selected: stationFilter,
                onSelected: (f) => setState(() => stationFilter = f),
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: list.length,
              itemBuilder: (context, index) {
                final eq = list[index];
                return Card(
                  child: ListTile(
                    leading: StatusDot(color: Helper.getStatusColor(eq.status)),
                    title: Text(eq.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${eq.station} • ${eq.status.name[0].toUpperCase()}${eq.status.name.substring(1)}', style: const TextStyle(color: AppColors.textMuted)),
                    trailing: LinkButton(
                      text: 'Lihat',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Detail ${eq.name} (Read-only Phase 1)')));
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: MockDB().currentUser!.role == Role.technician ? FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporBreakdownScreen())),
        label: const Text('Lapor Breakdown', style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.warning_amber, color: Colors.white),
        backgroundColor: AppColors.statusRed,
      ) : null,
    );
  }
}

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // For management, show a generic list
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Maintenance')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _histCard('04 Sep 2026', 'Screw Press #02', 'Preventive Maintenance', AppColors.statusGreen, 'Approved'),
          _histCard('28 Aug 2026', 'Boiler #01', 'Inspection', AppColors.statusGreen, 'Approved'),
          _histCard('14 Aug 2026', 'Pump #03', 'Breakdown', AppColors.textMuted, 'Closed'),
        ],
      ),
    );
  }

  Widget _histCard(String date, String eq, String type, Color color, String status) {
    return Card(
      child: ListTile(
        leading: StatusDot(color: color),
        title: Text('$date • $eq', style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(type, style: const TextStyle(color: AppColors.textMuted)),
        trailing: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      ),
    );
  }
}

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final role = MockDB().currentUser!.role;
    List<Map<String, String>> notifs = [];
    
    if (role == Role.technician) {
      notifs = [
        {'title': 'Tugas Baru Ditugaskan', 'sub': 'Boiler #01', 'time': '5 menit lalu'},
        {'title': 'Hasil Kerja Disetujui', 'sub': 'Screw Press #02', 'time': '1 jam lalu'},
        {'title': 'Reminder Jadwal', 'sub': 'Digester #01 besok', 'time': '2 jam lalu'},
      ];
    } else if (role == Role.supervisor) {
      notifs = [
        {'title': 'Submission Baru', 'sub': 'Andi • Screw Press #02', 'time': '10 menit lalu'},
        {'title': 'Breakdown Dilaporkan', 'sub': 'Pump #03 • Critical', 'time': '15 menit lalu'},
      ];
    } else {
      notifs = [
        {'title': 'Isu Kritis Terdeteksi', 'sub': 'Boiler #01 • High Temp', 'time': '20 menit lalu'},
        {'title': 'Laporan Siap', 'sub': 'Laporan Bulanan September', 'time': '1 hari lalu'},
      ];
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notifikasi')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifs.length,
        itemBuilder: (context, index) {
          final n = notifs[index];
          return Card(
            child: ListTile(
              title: Text(n['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(n['sub']!, style: const TextStyle(color: AppColors.textMuted)),
              trailing: Text(n['time']!, style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
            ),
          );
        },
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = MockDB().currentUser!;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DashedUploadBox(
            icon: Icons.person,
            label: 'Foto Profil',
            height: 120,
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ganti foto profil (Dummy)'))),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(user.role.name.toUpperCase(), style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          const SectionLabel('AKUN'),
          Card(
            margin: const EdgeInsets.only(top: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Ubah Password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fungsi ubah password'))),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.exit_to_app, color: AppColors.statusRed),
                  title: const Text('Keluar', style: TextStyle(color: AppColors.statusRed)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    MockDB().currentUser = null;
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                  },
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}