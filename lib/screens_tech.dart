import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data.dart';
import 'screens_shared.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// KARTU WORK ORDER (dipakai dashboard & daftar tugas)
// ---------------------------------------------------------------------------

class WorkOrderCard extends StatelessWidget {
  final WorkOrder wo;
  final VoidCallback onChanged;
  final bool compact;

  const WorkOrderCard({super.key, required this.wo, required this.onChanged, this.compact = false});

  Future<void> _openDetail(BuildContext context) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(workOrder: wo)));
    onChanged();
  }

  Future<void> _startChecklist(BuildContext context) async {
    if (wo.status == WOStatus.assigned || wo.status == WOStatus.rejected) {
      wo.status = WOStatus.inProgress;
      wo.startedAt ??= DateTime.now();
    }
    await Navigator.push(context, MaterialPageRoute(builder: (_) => ChecklistScreen(workOrder: wo)));
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final urgency = Labels.urgency(wo);
    final late = wo.isOverdue;

    return AppCard(
      accent: urgency,
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
      onTap: () => _openDetail(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(Labels.urgencyLabel(wo), color: urgency, filled: late),
              const SizedBox(width: 7),
              Text(
                wo.id,
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
              const Spacer(),
              Icon(
                wo.priority == WOPriority.critical ? Icons.flag_rounded : Icons.flag_outlined,
                size: 16,
                color: Labels.priorityColor(wo.priority),
              ),
            ],
          ),
          gap8,
          Text(
            wo.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              height: 1.28,
              color: AppColors.textPrimary,
            ),
          ),
          MetaRow(Icons.factory_outlined, '${wo.equipment.station} · ${wo.equipment.code}'),
          MetaRow(
            Icons.schedule_rounded,
            late
                ? 'Batas: ${Fmt.time(wo.scheduledAt)} (telat ${Fmt.minutes(wo.lateMinutes)}) · Est. ${Fmt.minutes(wo.estimatedMinutes)}'
                : 'Jadwal: ${Fmt.time(wo.scheduledAt)} · Est. ${Fmt.minutes(wo.estimatedMinutes)}',
            color: late ? AppColors.danger : null,
            weight: late ? FontWeight.w700 : FontWeight.w500,
          ),
          if (wo.status == WOStatus.inProgress) ...[
            gap8,
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: wo.progress,
                      minHeight: 6,
                      backgroundColor: AppColors.screenBg,
                      valueColor: const AlwaysStoppedAnimation(AppColors.amber),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${wo.answered}/${wo.checklist.length}',
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.amberInk),
                ),
              ],
            ),
          ],
          if (wo.status == WOStatus.rejected && wo.rejectReason != null) ...[
            gap8,
            NoticeBox(
              icon: Icons.undo_rounded,
              title: 'Dikembalikan supervisor',
              body: wo.rejectReason,
              color: AppColors.dangerInk,
              background: AppColors.dangerTint,
            ),
          ],
          if (!compact) ...[gap12, _cta(context)],
        ],
      ),
    );
  }

  Widget _cta(BuildContext context) {
    switch (wo.status) {
      case WOStatus.assigned:
        if (wo.isOverdue || wo.isDueToday) {
          return SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startChecklist(context),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text('Mulai Inspeksi Sekarang'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46), textStyle: _ctaText),
            ),
          );
        }
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openDetail(context),
            icon: const Icon(Icons.description_outlined, size: 19),
            label: const Text('Buka Surat Perintah Kerja'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), textStyle: _ctaText),
          ),
        );
      case WOStatus.inProgress:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startChecklist(context),
            icon: const Icon(Icons.pending_actions_rounded, size: 20),
            label: const Text('Lanjutkan Checklist'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.amberInk,
              minimumSize: const Size.fromHeight(46),
              textStyle: _ctaText,
            ),
          ),
        );
      case WOStatus.rejected:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => _startChecklist(context),
            icon: const Icon(Icons.build_circle_rounded, size: 20),
            label: const Text('Perbaiki & Kirim Ulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              minimumSize: const Size.fromHeight(46),
              textStyle: _ctaText,
            ),
          ),
        );
      default:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _openDetail(context),
            icon: const Icon(Icons.visibility_outlined, size: 19),
            label: const Text('Lihat Ringkasan'),
            style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46), textStyle: _ctaText),
          ),
        );
    }
  }

  static const _ctaText = TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800);
}

// ---------------------------------------------------------------------------
// DASHBOARD TEKNISI
// ---------------------------------------------------------------------------

class TechDashboard extends StatefulWidget {
  final ValueChanged<int>? onQuickNav;
  const TechDashboard({super.key, this.onQuickNav});

  @override
  State<TechDashboard> createState() => _TechDashboardState();
}

class _TechDashboardState extends State<TechDashboard> {
  String _filter = 'Semua';
  DateTime _syncedAt = DateTime.now();

  List<WorkOrder> get _myTasks => MockDB().tasksOf(MockDB().currentUser!);

  List<WorkOrder> get _visible {
    final tasks = _myTasks.where((w) => w.isOpen).toList()..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    return switch (_filter) {
      'Harus Selesai' => tasks.where((w) => w.isDueToday).toList(),
      'Overdue' => tasks.where((w) => w.isOverdue).toList(),
      _ => tasks,
    };
  }

  /// Menyegarkan telemetri: pembacaan sensor bergeser sedikit seperti di
  /// lapangan, supaya angka dashboard tidak terlihat beku saat demo.
  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 650));
    final rnd = math.Random();
    for (final e in MockDB().equipments) {
      e.temperature = double.parse((e.temperature + (rnd.nextDouble() - 0.5) * 1.6).toStringAsFixed(1));
      e.vibration = double.parse(math.max(0, e.vibration + (rnd.nextDouble() - 0.5) * 0.4).toStringAsFixed(1));
    }
    if (mounted) setState(() => _syncedAt = DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final user = MockDB().currentUser!;
    final open = _myTasks.where((w) => w.isOpen).toList();
    final dueToday = open.where((w) => w.isDueToday).length;
    final overdue = open.where((w) => w.isOverdue).length;
    final done =
        _myTasks.where((w) => w.status == WOStatus.approved || w.status == WOStatus.waitingVerification).length;

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _header(user),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _briefingCard(),
                  gap16,
                  _quickActions(),
                  gap24,
                  SectionTitle(
                    'Ringkasan Beban Kerja',
                    icon: Icons.insights_rounded,
                    trailingText: 'Update ${Fmt.time(_syncedAt)}',
                  ),
                  gap8,
                  Row(
                    children: [
                      StatTile(
                        label: 'Total',
                        value: '${open.length}',
                        caption: 'Tugas',
                        color: AppColors.textPrimary,
                        selected: _filter == 'Semua',
                        onTap: () => setState(() => _filter = 'Semua'),
                      ),
                      const SizedBox(width: 8),
                      StatTile(
                        label: 'Hari Ini',
                        value: '$dueToday',
                        caption: 'Aktif',
                        color: AppColors.amberInk,
                        selected: _filter == 'Harus Selesai',
                        onTap: () => setState(() => _filter = 'Harus Selesai'),
                      ),
                      const SizedBox(width: 8),
                      StatTile(
                        label: 'Overdue',
                        value: '$overdue',
                        caption: 'Kritis',
                        color: AppColors.danger,
                        selected: _filter == 'Overdue',
                        onTap: () => setState(() => _filter = 'Overdue'),
                      ),
                      const SizedBox(width: 8),
                      StatTile(
                        label: 'Selesai',
                        value: '$done',
                        caption: 'Terverifikasi',
                        color: AppColors.primary,
                        onTap: () => widget.onQuickNav?.call(1),
                      ),
                    ],
                  ),
                  gap24,
                  SectionTitle(
                    'Tugas Utama Shift Ini',
                    icon: Icons.assignment_turned_in_outlined,
                    trailingText: 'Lihat Semua',
                    onTrailingTap: () => widget.onQuickNav?.call(1),
                  ),
                  gap12,
                  PillTabs(
                    options: ['Semua (${open.length})', 'Harus Selesai ($dueToday)', 'Overdue ($overdue)'],
                    selected: switch (_filter) {
                      'Harus Selesai' => 'Harus Selesai ($dueToday)',
                      'Overdue' => 'Overdue ($overdue)',
                      _ => 'Semua (${open.length})',
                    },
                    onSelected: (v) => setState(() => _filter = v.split(' (').first),
                  ),
                  gap12,
                  if (_visible.isEmpty)
                    const EmptyState(
                      icon: Icons.task_alt_rounded,
                      title: 'Tidak ada tugas di filter ini',
                      body: 'Semua pekerjaan pada kategori tersebut sudah tuntas.',
                    )
                  else
                    ..._visible.map((wo) => WorkOrderCard(wo: wo, onChanged: () => setState(() {}))),
                  gap8,
                  _sensorCard(),
                  gap16,
                  _emergencyButton(),
                  gap12,
                  Center(
                    child: Text(
                      '${MockDB().millName} · Terkoneksi ke Server Intranet Mill',
                      style: const TextStyle(fontSize: 11, color: AppColors.textFaint, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(AppUser user) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialAvatar(user.initials, color: Colors.white.withValues(alpha: 0.18), size: 42),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Fmt.greeting()},',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Colors.white.withValues(alpha: 0.78),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          user.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SyncBadge(),
                  const SizedBox(width: 4),
                  NotificationBell(onOpened: () => setState(() {})),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${Fmt.shiftLabel()} · ${user.station}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _briefingCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.spa_rounded, size: 14, color: AppColors.secondary.withValues(alpha: 0.95)),
              const SizedBox(width: 6),
              Text(
                MockDB().millName.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppColors.secondary.withValues(alpha: 0.95),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'PERAWATAN RUTIN PKS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.2),
          ),
          const SizedBox(height: 6),
          Text(
            'Pastikan pelumasan bearing Screw Press dan pengecekan Sterilizer tuntas sebelum jam giling puncak 13.00 WIB.',
            style: TextStyle(fontSize: 12.8, height: 1.45, color: Colors.white.withValues(alpha: 0.82)),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => showSopSheet(context),
            icon: const Icon(Icons.menu_book_rounded, size: 18),
            label: const Text('Lihat SOP K3 Sawit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withValues(alpha: 0.45)),
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickActions() {
    final overdue = _myTasks.where((w) => w.isOverdue).length;
    return Row(
      children: [
        _action(Icons.assignment_rounded, 'Tugas Shift', AppColors.primary, overdue, () => widget.onQuickNav?.call(1)),
        _action(
          Icons.precision_manufacturing_rounded,
          'Mesin PKS',
          AppColors.info,
          0,
          () => widget.onQuickNav?.call(2),
        ),
        _action(Icons.crisis_alert_rounded, 'Lapor Rusak', AppColors.danger, 0, _openBreakdown),
        _action(Icons.history_rounded, 'Riwayat', AppColors.amberInk, 0, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
        }),
      ],
    );
  }

  Widget _action(IconData icon, String label, Color color, int badge, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.inner),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: color.withValues(alpha: 0.22)),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badge > 0)
                    Positioned(
                      right: -3,
                      top: -3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.danger,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.6),
                        ),
                        child: Text(
                          '$badge',
                          style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sensorCard() {
    final sterilizer = MockDB().equipments.firstWhere((e) => e.id == 'E4');
    final press = MockDB().equipments.firstWhere((e) => e.id == 'E1');
    final vibHigh = press.vibration > press.vibLimit;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.neutral, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sensors_rounded, size: 17, color: AppColors.secondary),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Status IoT Sensor Pabrik',
                  style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                ),
              ),
              Text(
                '${MockDB().equipments.length * 2} sensor aktif',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.6)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SensorGauge(
                name: 'Suhu ${sterilizer.name}',
                reading: '${sterilizer.temperature.toStringAsFixed(0)}°C',
                statusLabel: 'Optimal',
                ratio: sterilizer.temperature / sterilizer.tempLimit,
                color: AppColors.secondary,
              ),
              SensorGauge(
                name: 'Vibrasi ${press.name}',
                reading: '${press.vibration.toStringAsFixed(1)} mm/s',
                statusLabel: vibHigh ? 'Tinggi' : 'Normal',
                ratio: press.vibration / press.vibLimit,
                color: vibHigh ? AppColors.amber : AppColors.secondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Tarik layar ke bawah untuk menyegarkan pembacaan telemetri.',
            style: TextStyle(fontSize: 10.5, color: Colors.white.withValues(alpha: 0.5), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _emergencyButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _openBreakdown,
        icon: const Icon(Icons.crisis_alert_rounded, size: 24),
        label: const Text('LAPOR MESIN BREAKDOWN (DARURAT)'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.danger,
          minimumSize: const Size.fromHeight(60),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
    );
  }

  Future<void> _openBreakdown() async {
    HapticFeedback.mediumImpact();
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const LaporBreakdownScreen()));
    if (mounted) setState(() {});
  }
}

// ---------------------------------------------------------------------------
// DAFTAR TUGAS
// ---------------------------------------------------------------------------

class TechTasks extends StatefulWidget {
  const TechTasks({super.key});

  @override
  State<TechTasks> createState() => _TechTasksState();
}

class _TechTasksState extends State<TechTasks> {
  String _filter = 'Semua';
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tasks = MockDB().tasksOf(MockDB().currentUser!);
    tasks = switch (_filter) {
      'Hari Ini' => tasks.where((w) => w.isDueToday).toList(),
      'Overdue' => tasks.where((w) => w.isOverdue).toList(),
      'Dikerjakan' => tasks.where((w) => w.status == WOStatus.inProgress).toList(),
      'Selesai' =>
        tasks.where((w) => w.status == WOStatus.approved || w.status == WOStatus.waitingVerification).toList(),
      _ => tasks,
    };
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      tasks =
          tasks
              .where(
                (w) =>
                    w.title.toLowerCase().contains(q) ||
                    w.id.toLowerCase().contains(q) ||
                    w.equipment.name.toLowerCase().contains(q) ||
                    w.equipment.code.toLowerCase().contains(q),
              )
              .toList();
    }
    tasks.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tugas Saya'),
        actions: [NotificationBell(onOpened: () => setState(() {})), const SizedBox(width: 6)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _query = v),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Cari mesin, kode aset, atau nomor WO',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted),
                suffixIcon:
                    _query.isEmpty
                        ? null
                        : IconButton(
                          icon: const Icon(Icons.close_rounded),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _query = '');
                          },
                        ),
              ),
            ),
          ),
          PillTabs(
            options: const ['Semua', 'Hari Ini', 'Overdue', 'Dikerjakan', 'Selesai'],
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          gap12,
          Expanded(
            child:
                tasks.isEmpty
                    ? const Padding(
                      padding: EdgeInsets.all(20),
                      child: EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Tidak ada tugas ditemukan',
                        body: 'Ubah kata kunci pencarian atau pilih filter lain.',
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: tasks.length,
                      itemBuilder: (_, i) => WorkOrderCard(wo: tasks[i], onChanged: () => setState(() {})),
                    ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// DETAIL PERINTAH KERJA
// ---------------------------------------------------------------------------

class TaskDetailScreen extends StatefulWidget {
  final WorkOrder workOrder;
  const TaskDetailScreen({super.key, required this.workOrder});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  WorkOrder get wo => widget.workOrder;

  @override
  Widget build(BuildContext context) {
    final urgency = Labels.urgency(wo);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Perintah Kerja'),
        bottom: BreadcrumbBar(text: '${wo.assignedTo.jobTitle.split(' — ').last} · ${wo.equipment.station}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Tag(
                wo.priority == WOPriority.critical
                    ? 'PRIORITAS KRITIS'
                    : 'PRIORITAS ${Labels.priority(wo.priority).toUpperCase()}',
                color: Labels.priorityColor(wo.priority),
                icon: Icons.warning_amber_rounded,
              ),
              if (wo.isOverdue) Tag('Terlambat ${Fmt.minutes(wo.lateMinutes)}', color: AppColors.danger, filled: true),
            ],
          ),
          gap8,
          AppCard(
            padding: const EdgeInsets.all(14),
            accent: urgency,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tag(wo.id, color: AppColors.textMuted, icon: Icons.confirmation_number_outlined),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Target: ${Fmt.time(wo.scheduledAt)}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: wo.isOverdue ? AppColors.danger : AppColors.textMuted,
                        ),
                      ),
                    ),
                  ],
                ),
                gap12,
                Text(
                  '${wo.code} · ${Labels.woType(wo.type)}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: AppColors.amberInk,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  wo.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(wo.description, style: const TextStyle(fontSize: 13, height: 1.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          if (wo.status == WOStatus.rejected && wo.rejectReason != null) ...[
            NoticeBox(
              icon: Icons.assignment_late_rounded,
              title: 'Dikembalikan oleh ${wo.issuedBy.firstName}',
              body: wo.rejectReason,
              color: AppColors.dangerInk,
              background: AppColors.dangerTint,
            ),
            gap12,
          ],
          _assetCard(),
          _teamCard(),
          if (wo.lube != null) _lubeCard(wo.lube!),
          if (wo.lotoNote != null) _safetyCard(),
        ],
      ),
      bottomNavigationBar: _bottomBar(),
    );
  }

  Widget _assetCard() {
    final eq = wo.equipment;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Aset Terdaftar', icon: Icons.precision_manufacturing_rounded),
          gap12,
          Container(
            height: 96,
            width: double.infinity,
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.inner)),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              fit: StackFit.expand,
              children: [
                PhotoThumb(seed: eq.id.hashCode, width: double.infinity, height: 96),
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        Tag(
                          'Tag: QR-${eq.code.split('-').last}',
                          color: AppColors.neutral,
                          filled: true,
                          icon: Icons.qr_code_2_rounded,
                        ),
                        Tag(
                          eq.status == EquipStatus.warning ? 'Window Perawatan' : Labels.equipStatus(eq.status),
                          color: Labels.equipColor(eq.status),
                          filled: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          gap12,
          Text(
            eq.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          Text(
            'Kapasitas desain: ${eq.capacity}',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
          gap12,
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _miniInfo(Icons.place_outlined, 'Lokasi', '${eq.station}\n${eq.line}')),
              const SizedBox(width: 10),
              Expanded(
                child: _miniInfo(Icons.factory_outlined, 'Unit Pabrik', '${MockDB().millName}\nKode: ${eq.code}'),
              ),
            ],
          ),
          gap12,
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _scanAsset,
              icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
              label: const Text('Verifikasi Barcode Fisik Mesin'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniInfo(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: AppColors.screenBg, borderRadius: BorderRadius.circular(AppRadius.inner)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: AppColors.primary),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _teamCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Tim Pelaksana',
            icon: Icons.groups_rounded,
            trailingText: 'Durasi est. ${Fmt.minutes(wo.estimatedMinutes)}',
          ),
          gap12,
          _person(wo.assignedTo, 'Lead', AppColors.primary),
          if (wo.helper != null) ...[const SizedBox(height: 8), _person(wo.helper!, 'Pendamping', AppColors.info)],
          gap12,
          Row(
            children: [
              const Icon(Icons.verified_user_outlined, size: 15, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: 'Pemberi tugas: ', style: TextStyle(color: AppColors.textMuted)),
                      TextSpan(
                        text: '${wo.issuedBy.name} (${wo.issuedBy.jobTitle})',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  style: const TextStyle(fontSize: 12.5, height: 1.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _person(AppUser u, String badge, Color color) {
    return Row(
      children: [
        InitialAvatar(u.initials, color: color),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                u.name,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              Text('${u.jobTitle} · NIK ${u.nik}', style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ],
          ),
        ),
        Tag(badge, color: color),
      ],
    );
  }

  Widget _lubeCard(LubeSpec lube) {
    return AppCard(
      color: AppColors.primaryTint,
      borderColor: AppColors.primaryTintStrong,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Spesifikasi & Pelumas', icon: Icons.water_drop_rounded),
          gap12,
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.inner)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'TIPE GREASE STANDAR PKS',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFaint,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lube.grease,
                  style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                Text(lube.greadeNote, style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                const Divider(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Dosis per rumah bearing',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Tag(lube.dose, color: AppColors.amberInk, background: AppColors.amberTint, fontSize: 12),
                  ],
                ),
              ],
            ),
          ),
          gap12,
          Row(
            children: [
              const Expanded(
                child: Text('Titik injeksi pelumasan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
              ),
              Tag('${lube.points.length} Titik Nipple', color: AppColors.primary),
            ],
          ),
          gap8,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < lube.points.length; i++)
                SizedBox(
                  width: (MediaQuery.sizeOf(context).width - 32 - 28 - 8) / 2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                          alignment: Alignment.center,
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            lube.points[i],
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          gap12,
          const Text(
            'PERALATAN WAJIB DISIAPKAN',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textFaint,
              letterSpacing: 0.5,
            ),
          ),
          gap4,
          for (final t in lube.tools)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                  const SizedBox(width: 6),
                  Text(t, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _safetyCard() {
    return AppCard(
      color: AppColors.amberTint,
      borderColor: AppColors.amber.withValues(alpha: 0.4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, size: 18, color: AppColors.amberInk),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Instruksi Keselamatan K3 & LOTO',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.amberInk),
                ),
              ),
            ],
          ),
          gap12,
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.inner)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.danger),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    wo.lotoNote!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (wo.ppe.isNotEmpty) ...[
            gap12,
            const Text(
              'APD WAJIB DI LOKASI PABRIK',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                color: AppColors.amberInk,
                letterSpacing: 0.5,
              ),
            ),
            gap8,
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: [
                for (final p in wo.ppe)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(9)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.health_and_safety_rounded, size: 14, color: AppColors.amberInk),
                        const SizedBox(width: 5),
                        Text(p, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bottomBar() {
    if (MockDB().currentUser!.role != Role.technician) return const SizedBox.shrink();

    final canWork =
        wo.status == WOStatus.assigned || wo.status == WOStatus.inProgress || wo.status == WOStatus.rejected;
    if (!canWork) {
      return BottomBar(
        children: [
          NoticeBox(
            icon: Icons.verified_rounded,
            title: Labels.woStatus(wo.status),
            body: wo.finishedAt == null ? null : 'Dikirim ${Fmt.dateTime(wo.finishedAt!)}',
            color: Labels.woStatusColor(wo.status),
          ),
        ],
      );
    }

    return BottomBar(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () async {
              if (wo.status != WOStatus.inProgress) {
                wo.status = WOStatus.inProgress;
                wo.startedAt ??= DateTime.now();
              }
              await Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => ChecklistScreen(workOrder: wo)),
              );
            },
            icon: const Icon(Icons.checklist_rounded, size: 21),
            label: Text(wo.status == WOStatus.inProgress ? 'LANJUTKAN CHECKLIST' : 'MULAI CHECKLIST INSPEKSI'),
          ),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _reportObstacle,
          icon: const Icon(Icons.report_problem_outlined, size: 18),
          label: const Text('Laporkan Kendala / Sparepart Kurang'),
          style: TextButton.styleFrom(foregroundColor: AppColors.amberInk, minimumSize: const Size.fromHeight(44)),
        ),
      ],
    );
  }

  void _scanAsset() {
    showAppSnack(
      context,
      'Barcode ${wo.equipment.code} cocok dengan aset pada perintah kerja.',
      color: AppColors.primary,
      icon: Icons.qr_code_scanner_rounded,
    );
  }

  Future<void> _reportObstacle() async {
    final ctrl = TextEditingController();
    final sent = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => SheetShell(
            title: 'Laporkan Kendala',
            subtitle: 'Kendala dikirim ke ${wo.issuedBy.name} untuk tindak lanjut.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: 4,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Contoh: bearing pengganti kosong di gudang sparepart.'),
                ),
                gap16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isNotEmpty),
                    child: const Text('Kirim ke Supervisor'),
                  ),
                ),
              ],
            ),
          ),
    );

    if (!mounted) return;
    if (sent == true) {
      MockDB().extraNotifications.insert(
        0,
        AppNotification(
          title: 'Kendala dilaporkan teknisi',
          subtitle: '${wo.id} · ${ctrl.text.trim()}',
          at: DateTime.now(),
          icon: Icons.report_problem_rounded,
          color: AppColors.amberInk,
          unread: true,
        ),
      );
      showAppSnack(context, 'Kendala terkirim ke supervisor.', color: AppColors.primary, icon: Icons.send_rounded);
    } else if (sent == false) {
      showAppSnack(context, 'Isi keterangan kendala terlebih dahulu.', color: AppColors.danger);
    }
  }
}

// ---------------------------------------------------------------------------
// CHECKLIST INSPEKSI
// ---------------------------------------------------------------------------

class ChecklistScreen extends StatefulWidget {
  final WorkOrder workOrder;
  const ChecklistScreen({super.key, required this.workOrder});

  @override
  State<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends State<ChecklistScreen> {
  WorkOrder get wo => widget.workOrder;

  @override
  void initState() {
    super.initState();
    wo.startedAt ??= DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (wo.progress * 100).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checklist Inspeksi'),
        bottom: BreadcrumbBar(text: '${wo.equipment.station} · ${wo.equipment.name}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              Tag(wo.equipment.name, color: AppColors.textMuted, icon: Icons.settings_rounded),
              Tag(wo.id, color: AppColors.textMuted, icon: Icons.confirmation_number_outlined),
              Tag(
                Fmt.shiftLabel().split(' (').first,
                color: AppColors.amberInk,
                background: AppColors.amberTint,
                icon: Icons.schedule_rounded,
              ),
            ],
          ),
          gap12,
          Text(
            wo.title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.25,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${Labels.woType(wo.type)} · Teknisi: ${wo.assignedTo.name} (NIK ${wo.assignedTo.nik})',
            style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
          ),
          gap12,
          AppCard(
            color: AppColors.primaryTint,
            borderColor: AppColors.primaryTintStrong,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PROGRES LAPANGAN',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${wo.answered} dari ${wo.checklist.length} Selesai',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                        height: 1,
                      ),
                    ),
                  ],
                ),
                gap12,
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: wo.progress),
                  duration: const Duration(milliseconds: 400),
                  builder:
                      (_, v, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: LinearProgressIndicator(
                          value: v,
                          minHeight: 9,
                          backgroundColor: Colors.white,
                          valueColor: AlwaysStoppedAnimation(wo.findingCount > 0 ? AppColors.amber : AppColors.primary),
                        ),
                      ),
                ),
                gap12,
                Row(
                  children: [
                    _chipStat(Icons.check_circle_rounded, '${wo.safeCount} Aman', AppColors.primary),
                    const SizedBox(width: 10),
                    _chipStat(Icons.warning_amber_rounded, '${wo.findingCount} Temuan', AppColors.danger),
                    const SizedBox(width: 10),
                    _chipStat(Icons.timer_outlined, Fmt.minutes(wo.workedMinutes), AppColors.textMuted),
                  ],
                ),
              ],
            ),
          ),
          gap8,
          for (var i = 0; i < wo.checklist.length; i++) _itemCard(i, wo.checklist[i]),
          gap8,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle(
                  'Bukti Foto Fisik Mesin',
                  icon: Icons.photo_library_rounded,
                  trailingText: 'Maks. 5 foto',
                ),
                gap12,
                Row(
                  children: [
                    for (final p in wo.evidence.take(3))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PhotoThumb(
                          seed: p.seed,
                          stamp: Fmt.time(p.takenAt).replaceAll(' WIB', ''),
                          flagged: p.finding,
                        ),
                      ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: wo.evidence.length >= 5 ? null : () => _addPhoto('Foto kondisi mesin'),
                        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: const Text('Ambil Foto'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(64),
                          textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  wo.allAnswered
                      ? () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => EvidenceScreen(workOrder: wo)));
                        if (mounted) setState(() {});
                      }
                      : null,
              icon: const Icon(Icons.arrow_forward_rounded, size: 21),
              label: Text(
                wo.allAnswered
                    ? 'LANJUT KE RINGKASAN & SUBMIT'
                    : 'SISA ${wo.checklist.length - wo.answered} POIN BELUM DIJAWAB',
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Center(
            child: Text(
              'Jawaban tersimpan otomatis di antrean offline perangkat.',
              style: TextStyle(fontSize: 11, color: AppColors.textFaint, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chipStat(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }

  Widget _itemCard(int index, ChecklistItem item) {
    final answered = item.isChecked != null;
    final finding = item.isChecked == false;
    final accent = !answered ? AppColors.cardBorder : (finding ? AppColors.danger : AppColors.primary);

    return AppCard(
      borderColor: answered ? accent.withValues(alpha: 0.45) : AppColors.cardBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: answered ? accent : AppColors.screenBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: answered ? accent : AppColors.cardBorder),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: answered ? Colors.white : AppColors.textMuted,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.taskName,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              height: 1.3,
                              color: finding ? AppColors.dangerInk : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (finding) ...[
                          const SizedBox(width: 6),
                          const Tag('ADA TEMUAN', color: AppColors.danger, icon: Icons.warning_amber_rounded),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.description,
                      style: const TextStyle(fontSize: 12.3, height: 1.45, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (item.measureLabel != null) ...[
            gap8,
            InkWell(
              onTap: () => _inputMeasurement(item),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                decoration: BoxDecoration(
                  color:
                      item.measuredValue == null
                          ? AppColors.infoTint
                          : (item.overLimit ? AppColors.dangerTint : AppColors.primaryTint),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color:
                        item.measuredValue == null
                            ? AppColors.info.withValues(alpha: 0.3)
                            : (item.overLimit ? AppColors.danger : AppColors.primary).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      item.measureUnit == '°C' ? Icons.thermostat_rounded : Icons.vibration_rounded,
                      size: 16,
                      color:
                          item.measuredValue == null
                              ? AppColors.info
                              : (item.overLimit ? AppColors.dangerInk : AppColors.primary),
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.measuredValue == null
                            ? '${item.measureLabel} — ketuk untuk isi (batas ${item.measureLimit}${item.measureUnit})'
                            : '${item.measureLabel}: ${item.measuredValue}${item.measureUnit} '
                                '(${item.overLimit ? "Melebihi batas ${item.measureLimit}${item.measureUnit}" : "Normal"})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color:
                              item.measuredValue == null
                                  ? AppColors.info
                                  : (item.overLimit ? AppColors.dangerInk : AppColors.primaryDark),
                        ),
                      ),
                    ),
                    Icon(Icons.edit_rounded, size: 14, color: AppColors.textMuted.withValues(alpha: 0.8)),
                  ],
                ),
              ),
            ),
          ],
          if (finding && item.note != null) ...[
            gap8,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerTint,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CATATAN TEMUAN LAPANGAN',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.dangerInk,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '"${item.note}"',
                    style: const TextStyle(
                      fontSize: 12.3,
                      height: 1.45,
                      fontStyle: FontStyle.italic,
                      color: AppColors.dangerInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Tag(
                        '${item.photoCount} foto temuan',
                        color: AppColors.dangerInk,
                        icon: Icons.photo_camera_rounded,
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => _noteDialog(item),
                        icon: const Icon(Icons.edit_note_rounded, size: 17),
                        label: const Text('Ubah catatan'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.dangerInk,
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          gap12,
          Row(
            children: [
              Expanded(
                child: _decision(
                  'AMAN',
                  Icons.check_circle_rounded,
                  AppColors.primary,
                  item.isChecked == true,
                  () => setState(() {
                    item.isChecked = true;
                    item.note = null;
                  }),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _decision(
                  'ADA TEMUAN',
                  Icons.report_problem_rounded,
                  AppColors.danger,
                  finding,
                  () => _noteDialog(item),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _decision(String label, IconData icon, Color color, bool selected, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.inner),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: 48,
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.inner),
          border: Border.all(color: selected ? color : AppColors.cardBorder, width: selected ? 1.8 : 1.3),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 19, color: selected ? Colors.white : AppColors.textMuted),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _inputMeasurement(ChecklistItem item) async {
    final ctrl = TextEditingController(text: item.measuredValue?.toString() ?? '');
    final value = await showDialog<double>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(item.measureLabel!),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Batas aman: ${item.measureLimit}${item.measureUnit}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                gap12,
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                  decoration: InputDecoration(suffixText: item.measureUnit, hintText: '0.0'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () {
                  final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
                  Navigator.pop(ctx, v);
                },
                style: ElevatedButton.styleFrom(minimumSize: const Size(110, 46)),
                child: const Text('Simpan'),
              ),
            ],
          ),
    );

    if (!mounted || value == null) return;
    setState(() => item.measuredValue = value);
    if (item.overLimit) {
      showAppSnack(
        context,
        'Nilai melebihi batas aman. Tandai poin ini sebagai temuan.',
        color: AppColors.danger,
        icon: Icons.warning_amber_rounded,
      );
    }
  }

  Future<void> _noteDialog(ChecklistItem item) async {
    final ctrl = TextEditingController(text: item.note ?? '');
    var photos = item.photoCount;

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => StatefulBuilder(
            builder:
                (ctx, setSheet) => SheetShell(
                  title: 'Catatan Temuan',
                  subtitle: item.taskName,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: ctrl,
                        maxLines: 4,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Jelaskan temuan: lokasi, indikasi, dan tindakan sementara.',
                        ),
                      ),
                      gap12,
                      Row(
                        children: [
                          for (var i = 0; i < photos; i++)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: PhotoThumb(seed: item.id.hashCode + i, width: 54, height: 54, flagged: true),
                            ),
                          OutlinedButton.icon(
                            onPressed: () => setSheet(() => photos++),
                            icon: const Icon(Icons.add_a_photo_rounded, size: 17),
                            label: const Text('Foto temuan'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size(0, 54),
                              textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                      gap16,
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isNotEmpty),
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                          child: const Text('Simpan Temuan'),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );

    if (!mounted) return;
    if (saved == true) {
      setState(() {
        item.isChecked = false;
        item.note = ctrl.text.trim();
        item.photoCount = photos;
        if (photos > 0 && wo.evidence.length < 5) {
          wo.evidence.add(
            EvidencePhoto(
              caption: 'Temuan: ${item.taskName}',
              takenAt: DateTime.now(),
              finding: true,
              seed: item.id.hashCode,
            ),
          );
        }
      });
    } else if (saved == false) {
      showAppSnack(context, 'Catatan temuan wajib diisi.', color: AppColors.danger);
    }
  }

  void _addPhoto(String caption) {
    setState(() {
      wo.evidence.add(
        EvidencePhoto(caption: caption, takenAt: DateTime.now(), seed: wo.evidence.length + wo.id.hashCode),
      );
    });
    showAppSnack(
      context,
      'Foto tersimpan dengan geotag dan stempel waktu.',
      color: AppColors.primary,
      icon: Icons.photo_camera_rounded,
    );
  }
}

// ---------------------------------------------------------------------------
// BUKTI FOTO & RINGKASAN
// ---------------------------------------------------------------------------

class EvidenceScreen extends StatefulWidget {
  final WorkOrder workOrder;
  const EvidenceScreen({super.key, required this.workOrder});

  @override
  State<EvidenceScreen> createState() => _EvidenceScreenState();
}

class _EvidenceScreenState extends State<EvidenceScreen> {
  WorkOrder get wo => widget.workOrder;
  late final TextEditingController _noteCtrl = TextEditingController(text: wo.technicianNote ?? '');
  bool _signed = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit => wo.evidence.isNotEmpty && _signed;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bukti & Ringkasan'),
        bottom: BreadcrumbBar(text: 'Tahap 3 dari 3 · Verifikasi Final'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          _headerCard(),
          _durationCard(),
          if (wo.findingCount > 0) ...[
            NoticeBox(
              icon: Icons.warning_amber_rounded,
              title: '${wo.safeCount} dari ${wo.checklist.length} aman · ${wo.findingCount} temuan',
              body: 'Perlu perhatian dan validasi supervisor lapangan sebelum ditutup.',
              color: AppColors.amberInk,
              background: AppColors.amberTint,
            ),
            gap12,
          ],
          _summaryCard(),
          _photosCard(),
          _geotagCard(),
          _signatureCard(),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.mark_email_unread_outlined, size: 19, color: AppColors.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notifikasi ke Supervisor',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                      Text(
                        '${wo.issuedBy.name} (${wo.issuedBy.jobTitle})',
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                const Tag('Otomatis', color: AppColors.primary),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _canSubmit ? _submit : null,
              icon: const Icon(Icons.task_alt_rounded, size: 21),
              label: Text(
                _canSubmit
                    ? 'KIRIM & SELESAIKAN INSPEKSI'
                    : (wo.evidence.isEmpty ? 'MINIMAL 1 FOTO BUKTI' : 'TANDA TANGAN DULU'),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_rounded, size: 18),
            label: const Text('Kembali & koreksi checklist'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, minimumSize: const Size.fromHeight(44)),
          ),
        ],
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primaryDark, AppColors.primaryDeep],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(
                wo.id,
                color: Colors.white.withValues(alpha: 0.16),
                icon: Icons.confirmation_number_outlined,
                filled: true,
              ),
              const Spacer(),
              Tag(wo.equipment.station.replaceAll('Stasiun ', ''), color: AppColors.secondary, filled: true),
            ],
          ),
          gap12,
          Text(
            '${wo.equipment.name} · ${wo.equipment.line}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 3),
          Text(wo.title, style: TextStyle(fontSize: 12.5, height: 1.4, color: Colors.white.withValues(alpha: 0.8))),
        ],
      ),
    );
  }

  Widget _durationCard() {
    return AppCard(
      child: Row(
        children: [
          Expanded(child: _metric(Icons.timer_outlined, 'Durasi Kerja', Fmt.minutes(wo.workedMinutes))),
          Container(width: 1, height: 38, color: AppColors.cardBorder),
          Expanded(
            child: _metric(
              Icons.event_available_rounded,
              'Waktu Pengerjaan',
              Fmt.dateTime(wo.startedAt ?? DateTime.now()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: AppColors.primary),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFaint,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Ringkasan Poin Inspeksi',
            icon: Icons.format_list_numbered_rounded,
            trailingText: '${wo.checklist.length} poin dicek',
          ),
          gap12,
          for (var i = 0; i < wo.checklist.length; i++) ...[
            if (i > 0) const Divider(height: 18),
            _summaryRow(i, wo.checklist[i]),
          ],
          gap16,
          const Text(
            'CATATAN AKHIR TEKNISI',
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textFaint,
              letterSpacing: 0.5,
            ),
          ),
          gap8,
          TextField(
            controller: _noteCtrl,
            maxLines: 3,
            onChanged: (v) => wo.technicianNote = v,
            decoration: const InputDecoration(hintText: 'Rekomendasi tindak lanjut untuk supervisor (opsional).'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(int i, ChecklistItem item) {
    final ok = item.isChecked == true;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 21,
          height: 21,
          decoration: BoxDecoration(color: ok ? AppColors.primary : AppColors.danger, shape: BoxShape.circle),
          alignment: Alignment.center,
          child: Text(
            '${i + 1}',
            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.taskName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
              if (item.measuredValue != null)
                Text(
                  '${item.measureLabel}: ${item.measuredValue}${item.measureUnit}'
                  '${item.overLimit ? " (melebihi batas)" : " (normal)"}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: item.overLimit ? AppColors.dangerInk : AppColors.primary,
                  ),
                ),
              if (item.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    '"${item.note}"',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.dangerInk,
                      height: 1.4,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Tag(ok ? 'AMAN' : 'TEMUAN', color: ok ? AppColors.primary : AppColors.danger),
      ],
    );
  }

  Widget _photosCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Bukti Foto Lapangan',
            icon: Icons.photo_library_rounded,
            trailingText: '${wo.evidence.length} foto',
          ),
          gap12,
          if (wo.evidence.isEmpty)
            const NoticeBox(
              icon: Icons.photo_camera_outlined,
              title: 'Belum ada foto bukti',
              body: 'Minimal satu foto wajib dilampirkan sebelum hasil kerja dikirim.',
              color: AppColors.amberInk,
              background: AppColors.amberTint,
            )
          else
            for (var i = 0; i < wo.evidence.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _photoRow(i, wo.evidence[i]),
            ],
          gap12,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed:
                      wo.evidence.length >= 5
                          ? null
                          : () => setState(
                            () => wo.evidence.add(
                              EvidencePhoto(
                                caption: 'Foto bukti ${wo.evidence.length + 1}',
                                takenAt: DateTime.now(),
                                seed: wo.evidence.length + 11,
                              ),
                            ),
                          ),
                  icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                  label: const Text('Foto Baru'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _photoRow(int i, EvidencePhoto p) {
    return Row(
      children: [
        PhotoThumb(
          seed: p.seed,
          stamp: Fmt.time(p.takenAt).replaceAll(' WIB', ''),
          flagged: p.finding,
          width: 62,
          height: 62,
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FOTO BUKTI ${i + 1}',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: p.finding ? AppColors.danger : AppColors.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(p.caption, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.3)),
              const SizedBox(height: 3),
              Row(
                children: [
                  Tag(
                    p.finding ? 'Prioritas' : 'Valid',
                    color: p.finding ? AppColors.danger : AppColors.primary,
                    icon: p.finding ? Icons.priority_high_rounded : Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      Fmt.time(p.takenAt),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Hapus foto',
          onPressed: () => setState(() => wo.evidence.removeAt(i)),
          icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _geotagCard() {
    return AppCard(
      color: AppColors.infoTint,
      borderColor: AppColors.info.withValues(alpha: 0.28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, size: 17, color: AppColors.info),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'Metadata Geotag Tervalidasi',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: AppColors.info),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Lat -0.52184, Long 101.44216 · radius 4 m dari ${wo.equipment.station}',
            style: const TextStyle(fontSize: 12, color: AppColors.info, height: 1.4, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Row(
            children: [
              Icon(Icons.shield_rounded, size: 13, color: AppColors.info),
              SizedBox(width: 5),
              Expanded(
                child: Text(
                  'Watermark otomatis tersemat pada EXIF setiap file foto.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.info, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _signatureCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            'Tanda Tangan Teknisi',
            icon: Icons.draw_rounded,
            trailingText: _signed ? 'Tertandatangani' : 'Otorisasi mandiri',
          ),
          gap12,
          Row(
            children: [
              InitialAvatar(wo.assignedTo.initials),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wo.assignedTo.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                    Text(
                      'NIK ${wo.assignedTo.nik} · ${wo.assignedTo.jobTitle}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
              if (_signed) const Tag('TERTANDATANGANI', color: AppColors.primary, icon: Icons.verified_rounded),
            ],
          ),
          gap12,
          SignaturePad(onChanged: (v) => setState(() => _signed = v)),
          if (_signed)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Ditandatangani digital via handset rugged · ${Fmt.dateTime(DateTime.now())}',
                style: const TextStyle(fontSize: 11, color: AppColors.textFaint, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }

  void _submit() {
    wo.status = WOStatus.waitingVerification;
    wo.finishedAt = DateTime.now();
    wo.signed = true;
    if (wo.findingCount > 0 && wo.equipment.status == EquipStatus.operational) {
      wo.equipment.status = EquipStatus.warning;
    }
    MockDB().extraNotifications.insert(
      0,
      AppNotification(
        title: 'Hasil inspeksi dikirim',
        subtitle: '${wo.id} · menunggu approval ${wo.issuedBy.firstName}',
        at: DateTime.now(),
        icon: Icons.send_rounded,
        color: AppColors.primary,
      ),
    );
    Navigator.of(context).popUntil((r) => r.isFirst);
    showAppSnack(
      context,
      'Hasil inspeksi ${wo.id} terkirim untuk verifikasi supervisor.',
      color: AppColors.primary,
      icon: Icons.task_alt_rounded,
    );
  }
}

// ---------------------------------------------------------------------------
// LAPOR BREAKDOWN DARURAT
// ---------------------------------------------------------------------------

const _gejala = [
  'Poros Macet / Jammed',
  'Kebocoran Oli Panas',
  'Motor Terbakar / Bau Asap',
  'Rantai Konveyor Putus',
  'Vibrasi Ekstrem',
  'Suara Benturan Logam',
];

class LaporBreakdownScreen extends StatefulWidget {
  const LaporBreakdownScreen({super.key});

  @override
  State<LaporBreakdownScreen> createState() => _LaporBreakdownScreenState();
}

class _LaporBreakdownScreenState extends State<LaporBreakdownScreen> {
  String _station = MockDB().equipments.first.station;
  Equipment? _equipment;
  WOPriority? _severity;
  final Set<String> _symptoms = {};
  final _descCtrl = TextEditingController();
  DateTime _occurredAt = DateTime.now();
  int _photos = 0;

  @override
  void initState() {
    super.initState();
    _equipment = MockDB().equipments.firstWhere((e) => e.station == _station);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  List<String> get _stations => MockDB().equipments.map((e) => e.station).toSet().toList();

  bool get _valid => _equipment != null && _severity != null && _descCtrl.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    final inStation = MockDB().equipments.where((e) => e.station == _station).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.dangerInk,
        title: const Text('Lapor Breakdown Mesin'),
        bottom: BreadcrumbBar(text: '${MockDB().millName} · jalur darurat', color: AppColors.dangerInk),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.dangerTint,
              borderRadius: BorderRadius.circular(AppRadius.card),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.crisis_alert_rounded, size: 21, color: AppColors.danger),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'LAPOR KERUSAKAN DARURAT',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.dangerInk,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickOccurredAt,
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.28)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.event_rounded, size: 16, color: AppColors.dangerInk),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            'Waktu kejadian: ${Fmt.dayName(_occurredAt)}, ${Fmt.date(_occurredAt)} · ${Fmt.time(_occurredAt)}',
                            style: const TextStyle(
                              fontSize: 12.3,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const Icon(Icons.edit_calendar_rounded, size: 16, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Laporan ini otomatis menyalakan sinyal sirine dan alert instan ke pager supervisor, asisten pabrik, dan kepala mill.',
                  style: TextStyle(
                    fontSize: 12.3,
                    height: 1.45,
                    color: AppColors.dangerInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          gap16,
          const SectionTitle('Stasiun Pengolahan Pabrik', icon: Icons.factory_rounded),
          gap8,
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _stations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder:
                  (_, i) => ChoiceChipTile(
                    label: _stations[i].replaceAll('Stasiun ', ''),
                    selected: _stations[i] == _station,
                    icon: Icons.location_on_outlined,
                    onTap:
                        () => setState(() {
                          _station = _stations[i];
                          _equipment = MockDB().equipments.firstWhere((e) => e.station == _station);
                        }),
                  ),
            ),
          ),
          gap16,
          const SectionTitle('Unit Mesin Terdampak', icon: Icons.precision_manufacturing_rounded),
          gap8,
          for (final eq in inStation)
            AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              borderColor: _equipment == eq ? AppColors.danger : AppColors.cardBorder,
              color: _equipment == eq ? AppColors.dangerTint : Colors.white,
              onTap: () => setState(() => _equipment = eq),
              child: Row(
                children: [
                  Icon(
                    _equipment == eq ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    size: 21,
                    color: _equipment == eq ? AppColors.danger : AppColors.cardBorder,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${eq.name} · ${eq.line}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Kode aset: ${eq.code}',
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Tag(Labels.equipStatus(eq.status), color: Labels.equipColor(eq.status)),
                ],
              ),
            ),
          gap16,
          Row(
            children: [
              const Expanded(child: SectionTitle('Tingkat Keparahan', icon: Icons.bolt_rounded)),
              Tag(
                _severity == null ? 'WAJIB DIPILIH' : 'TERPILIH',
                color: _severity == null ? AppColors.danger : AppColors.primary,
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Pilih kartu sesuai kondisi nyata di lantai pabrik. Tingkat keparahan menentukan SLA respons tim.',
            style: TextStyle(fontSize: 12.3, color: AppColors.textMuted, height: 1.45),
          ),
          gap12,
          _severityCard(
            WOPriority.medium,
            'MINOR / PERINGATAN',
            'Respons < 4 Jam',
            'Mesin masih berputar, getaran atau bising tidak wajar. TBS tetap terolah tanpa menghentikan jalur produksi.',
            Icons.warning_amber_rounded,
            AppColors.amberInk,
            AppColors.amberTint,
          ),
          _severityCard(
            WOPriority.high,
            'MAJOR / GANGGUAN BESAR',
            'Respons < 1 Jam',
            'Kapasitas press turun di atas 30%, kebocoran minyak hidrolik/CPO, panas motor abnormal, risiko kerusakan fatal.',
            Icons.build_circle_rounded,
            const Color(0xFFB4560A),
            const Color(0xFFFDEEDC),
          ),
          _severityCard(
            WOPriority.critical,
            'CRITICAL / STOP LINE TOTAL',
            'SEGERA! Respons < 15 Menit',
            'Poros macet total, patah atau terbakar, minyak membanjiri lantai kerja, membahayakan personel dan seluruh line berhenti.',
            Icons.dangerous_rounded,
            AppColors.dangerInk,
            AppColors.dangerTint,
          ),
          gap16,
          const SectionTitle('Gejala Kerusakan Cepat', icon: Icons.touch_app_rounded, trailingText: 'Pilih beberapa'),
          const SizedBox(height: 4),
          const Text(
            'Tap cepat dengan sarung tangan untuk menandai temuan.',
            style: TextStyle(fontSize: 12.3, color: AppColors.textMuted),
          ),
          gap12,
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in _gejala)
                ChoiceChipTile(
                  label: g,
                  selected: _symptoms.contains(g),
                  color: AppColors.danger,
                  onTap: () => setState(() => _symptoms.contains(g) ? _symptoms.remove(g) : _symptoms.add(g)),
                ),
            ],
          ),
          gap16,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionTitle('Bukti Kerusakan Aktual', icon: Icons.photo_camera_rounded, trailingText: '$_photos file'),
                gap12,
                Row(
                  children: [
                    for (var i = 0; i < _photos; i++)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: PhotoThumb(seed: 90 + i, width: 58, height: 58, flagged: true),
                      ),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _photos >= 4 ? null : () => setState(() => _photos++),
                        icon: const Icon(Icons.add_a_photo_rounded, size: 18),
                        label: const Text('Tambah Foto'),
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(58)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SectionTitle('Deskripsi Lapangan', icon: Icons.notes_rounded),
          gap8,
          TextField(
            controller: _descCtrl,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText:
                  'Contoh: poros screw press mendadak mengunci saat pengumpan TBS puncak, terdengar bunyi benturan lalu motor trip.',
              errorText:
                  _descCtrl.text.isNotEmpty && _descCtrl.text.trim().length < 10
                      ? 'Minimal 10 karakter agar supervisor paham kondisinya.'
                      : null,
            ),
          ),
          gap16,
          const NoticeBox(
            icon: Icons.lock_rounded,
            title: 'Peringatan K3 Pabrik (Prosedur LOTO)',
            body:
                'Pastikan sudah menekan tombol Emergency Stop dan memasang tag Lockout-Tagout sebelum mendekati mesin yang berhenti darurat.',
            color: AppColors.amberInk,
            background: AppColors.amberTint,
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _valid ? _submit : null,
              icon: const Icon(Icons.campaign_rounded, size: 22),
              label: const Text('KIRIM LAPORAN & BUNYIKAN ALARM'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
                minimumSize: const Size.fromHeight(58),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed:
                () => showAppSnack(
                  context,
                  'Memanggil supervisor via radio HT kanal 3 (speed dial).',
                  color: AppColors.neutral,
                  icon: Icons.radio_rounded,
                ),
            icon: const Icon(Icons.support_agent_rounded, size: 19),
            label: const Text('Hubungi Supervisor (Radio HT / Speed Dial)'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, minimumSize: const Size.fromHeight(44)),
          ),
        ],
      ),
    );
  }

  Widget _severityCard(WOPriority value, String title, String sla, String body, IconData icon, Color ink, Color tint) {
    final selected = _severity == value;
    return AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? tint : Colors.white,
      borderColor: selected ? ink : AppColors.cardBorder,
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _severity = value);
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: ink),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: ink))),
              if (selected) Tag('TERPILIH', color: ink, filled: true),
            ],
          ),
          const SizedBox(height: 6),
          Tag(sla, color: ink, background: Colors.white, icon: Icons.timer_rounded, fontSize: 11),
          const SizedBox(height: 7),
          Text(body, style: const TextStyle(fontSize: 12.3, height: 1.45, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  Future<void> _pickOccurredAt() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now,
      helpText: 'Tanggal kejadian breakdown',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
      helpText: 'Jam kejadian',
      cancelText: 'Batal',
      confirmText: 'Simpan',
    );
    if (!mounted) return;

    setState(() {
      _occurredAt = DateTime(
        date.year,
        date.month,
        date.day,
        time?.hour ?? _occurredAt.hour,
        time?.minute ?? _occurredAt.minute,
      );
      if (_occurredAt.isAfter(DateTime.now())) _occurredAt = DateTime.now();
    });
  }

  void _submit() {
    final eq = _equipment!;
    final breakdown = Breakdown(
      id: 'BR-${DateTime.now().year}-${DateTime.now().millisecondsSinceEpoch.toString().substring(9)}',
      equipment: eq,
      station: _station,
      reportedBy: '${MockDB().currentUser!.name} (${MockDB().currentUser!.jobTitle})',
      issueDescription: _descCtrl.text.trim(),
      symptoms: _symptoms.toList(),
      priority: _severity!,
      status: WOStatus.assigned,
      reportedAt: _occurredAt,
      photoCount: _photos,
    );
    MockDB().breakdowns.insert(0, breakdown);

    eq.status = _severity == WOPriority.critical ? EquipStatus.stopped : EquipStatus.critical;

    MockDB().extraNotifications.insert(
      0,
      AppNotification(
        title: 'Alarm breakdown dikirim',
        subtitle: '${breakdown.id} · ${eq.name} · SLA ${Fmt.minutes(breakdown.sla.inMinutes)}',
        at: DateTime.now(),
        icon: Icons.campaign_rounded,
        color: AppColors.danger,
        unread: true,
      ),
    );

    Navigator.pop(context);
    showAppSnack(
      context,
      'Alarm dibunyikan. ${breakdown.id} terkirim ke supervisor, SLA respons ${Fmt.minutes(breakdown.sla.inMinutes)}.',
      color: AppColors.danger,
      icon: Icons.campaign_rounded,
    );
  }
}
