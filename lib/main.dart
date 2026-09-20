import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'data.dart';
import 'screens_manage.dart';
import 'screens_shared.dart';
import 'screens_tech.dart';
import 'theme.dart';

void main() {
  runApp(const PalmCareApp());
}

class PalmCareApp extends StatelessWidget {
  const PalmCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    final text = GoogleFonts.interTextTheme(
      Typography.material2021().black.apply(bodyColor: AppColors.textPrimary, displayColor: AppColors.textPrimary),
    );

    return MaterialApp(
      title: 'PalmCare CMMS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: AppColors.screenBg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
          tertiary: AppColors.amber,
          error: AppColors.danger,
          surface: Colors.white,
        ),
        textTheme: text,
        splashFactory: InkSparkle.splashFactory,
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: false,
          systemOverlayStyle: SystemUiOverlayStyle.light,
          titleTextStyle: text.titleLarge?.copyWith(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          dividerColor: Colors.transparent,
          labelStyle: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
          unselectedLabelStyle: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          iconColor: AppColors.primary,
          titleTextStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
          subtitleTextStyle: TextStyle(fontSize: 12.3, color: AppColors.textMuted, height: 1.4),
        ),
        dividerTheme: const DividerThemeData(color: AppColors.cardBorder, thickness: 1, space: 1),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFDDE4E1),
            disabledForegroundColor: AppColors.textFaint,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
            minimumSize: const Size.fromHeight(54),
            padding: const EdgeInsets.symmetric(horizontal: 18),
            textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
            elevation: 0,
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
            minimumSize: const Size.fromHeight(50),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            side: const BorderSide(color: AppColors.cardBorder, width: 1.4),
            textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          hintStyle: const TextStyle(color: AppColors.textFaint, fontSize: 13.5, height: 1.4),
          labelStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.inner),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.inner),
            borderSide: const BorderSide(color: AppColors.cardBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.inner),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.inner),
            borderSide: const BorderSide(color: AppColors.danger, width: 1.4),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card)),
          titleTextStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          contentTextStyle: const TextStyle(fontSize: 13.5, color: AppColors.textMuted, height: 1.5),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          extendedTextStyle: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
        ),
        sliderTheme: const SliderThemeData(
          activeTrackColor: AppColors.primary,
          thumbColor: AppColors.primary,
          inactiveTrackColor: AppColors.primaryTintStrong,
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: Colors.white,
          indicatorColor: AppColors.primaryTint,
          surfaceTintColor: Colors.transparent,
          elevation: 8,
          height: 70,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return TextStyle(
              fontSize: 11.5,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textMuted,
            );
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            final selected = states.contains(WidgetState.selected);
            return IconThemeData(color: selected ? AppColors.primary : AppColors.textMuted, size: 24);
          }),
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

// ---------------------------------------------------------------------------
// LOGIN / PILIH PERAN
// ---------------------------------------------------------------------------

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  AppUser? _selected;

  @override
  void initState() {
    super.initState();
    MockDB().initMockData();
    _selected = MockDB().technician;
  }

  void _enter() {
    MockDB().currentUser = _selected;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigation()));
  }

  ({String title, String badge, Color badgeColor, String desc, String scope, IconData icon}) _roleInfo(AppUser u) {
    final db = MockDB();
    switch (u.role) {
      case Role.technician:
        final open = db.tasksOf(u).where((w) => w.isOpen).length;
        return (
          title: 'TEKNISI LAPANGAN',
          badge: '$open Tugas Menunggu',
          badgeColor: AppColors.primary,
          desc: 'Eksekusi perawatan rutin, checklist mesin, dan lapor breakdown darurat.',
          scope: u.station,
          icon: Icons.engineering_rounded,
        );
      case Role.supervisor:
        return (
          title: 'SUPERVISOR',
          badge: '${db.pendingVerification} Perlu Approval',
          badgeColor: AppColors.amberInk,
          desc: 'Assign work order, validasi hasil inspeksi, dan monitoring tim lapangan.',
          scope: u.station,
          icon: Icons.fact_check_rounded,
        );
      case Role.management:
        return (
          title: 'MILL MANAGER',
          badge: 'Read-Only',
          badgeColor: AppColors.textMuted,
          desc: 'Pantau uptime mesin, breakdown rate, dan KPI perawatan pabrik.',
          scope: u.station,
          icon: Icons.insights_rounded,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0, 0.32],
            colors: [AppColors.primaryTint, Colors.white],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  children: [
                    Center(child: PalmCareMark(size: 64, background: Colors.white)),
                    gap12,
                    const Center(
                      child: Text(
                        'PalmCare CMMS',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Center(
                      child: Text(
                        'Sistem Perawatan Mesin Pabrik Kelapa Sawit (PKS)',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    Center(
                      child: Text(
                        MockDB().companyName,
                        style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w800),
                      ),
                    ),
                    gap24,
                    Center(
                      child: Tag(
                        'PILIH PERAN ANDA',
                        color: AppColors.amberInk,
                        background: AppColors.amberTint,
                        icon: Icons.touch_app_rounded,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Center(
                      child: Text(
                        'Sentuh kartu peran Anda untuk masuk ke sistem',
                        style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ),
                    gap16,
                    for (final u in MockDB().users) _roleCard(u),
                    gap8,
                    Row(
                      children: [
                        Expanded(child: _altMethod(Icons.nfc_rounded, 'Tap Kartu RFID / NFC')),
                        const SizedBox(width: 10),
                        Expanded(child: _altMethod(Icons.dialpad_rounded, 'PIN Cepat 4-Digit')),
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _selected == null ? null : _enter,
                        icon: const Icon(Icons.login_rounded, size: 21),
                        label: Text(
                          _selected == null
                              ? 'PILIH PERAN TERLEBIH DAHULU'
                              : 'LANJUT MASUK SEBAGAI ${_roleWord(_selected!.role)}',
                        ),
                      ),
                    ),
                    gap12,
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 2,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Mode Offline Aktif',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.amberInk),
                            ),
                          ],
                        ),
                        const Text(
                          'Versi 2.4.1 (Sync Pabrik Siap)',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Unit ${MockDB().millName} · Terkoneksi ke Server Intranet Mill',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 10.5, color: AppColors.textFaint, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _roleWord(Role r) => switch (r) {
    Role.technician => 'TEKNISI',
    Role.supervisor => 'SUPERVISOR',
    Role.management => 'MILL MANAGER',
  };

  Widget _roleCard(AppUser u) {
    final info = _roleInfo(u);
    final selected = _selected?.id == u.id;

    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(13),
      color: selected ? AppColors.primaryTint : Colors.white,
      borderColor: selected ? AppColors.primary : AppColors.cardBorder,
      onTap: () => setState(() => _selected = u),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: selected ? AppColors.primary : AppColors.primaryTint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(info.icon, size: 22, color: selected ? Colors.white : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Tag(info.badge, color: info.badgeColor, background: Colors.white, icon: Icons.circle, fontSize: 10.5),
                const SizedBox(height: 6),
                Text(info.desc, style: const TextStyle(fontSize: 12, height: 1.45, color: AppColors.textMuted)),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.factory_outlined, size: 13, color: AppColors.textFaint),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        info.scope,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textFaint),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
            size: 23,
            color: selected ? AppColors.primary : AppColors.cardBorder,
          ),
        ],
      ),
    );
  }

  Widget _altMethod(IconData icon, String label) {
    return InkWell(
      onTap:
          () => showAppSnack(
            context,
            '$label tersedia pada perangkat rugged dengan reader terpasang.',
            color: AppColors.neutral,
            icon: icon,
          ),
      borderRadius: BorderRadius.circular(AppRadius.inner),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.inner),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, size: 19, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// NAVIGASI UTAMA
// ---------------------------------------------------------------------------

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  List<Widget> get _screens {
    switch (MockDB().currentUser!.role) {
      case Role.technician:
        return [TechDashboard(onQuickNav: _go), const TechTasks(), const EquipmentListScreen(), const ProfileScreen()];
      case Role.supervisor:
        return [
          SupDashboard(onQuickNav: _go),
          const SupMaintenanceHub(),
          const EquipmentListScreen(),
          const ProfileScreen(),
        ];
      case Role.management:
        return [
          MgtDashboard(onQuickNav: _go),
          const EquipmentListScreen(),
          const MgtReportScreen(),
          const ProfileScreen(),
        ];
    }
  }

  List<NavigationDestination> get _destinations {
    switch (MockDB().currentUser!.role) {
      case Role.technician:
        return const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment_rounded),
            label: 'Tugas',
          ),
          NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon: Icon(Icons.precision_manufacturing_rounded),
            label: 'Alat/Mesin',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ];
      case Role.supervisor:
        return const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.handyman_outlined),
            selectedIcon: Icon(Icons.handyman_rounded),
            label: 'Maintenance',
          ),
          NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon: Icon(Icons.precision_manufacturing_rounded),
            label: 'Alat/Mesin',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ];
      case Role.management:
        return const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.precision_manufacturing_outlined),
            selectedIcon: Icon(Icons.precision_manufacturing_rounded),
            label: 'Alat/Mesin',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics_rounded),
            label: 'Laporan',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _go,
        destinations: _destinations,
      ),
    );
  }
}
