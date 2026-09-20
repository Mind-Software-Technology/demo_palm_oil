import 'package:flutter/material.dart';

import 'data.dart';
import 'screens_shared.dart';
import 'screens_tech.dart';
import 'theme.dart';

// ===========================================================================
// SUPERVISOR
// ===========================================================================

class SupDashboard extends StatefulWidget {
  final ValueChanged<int>? onQuickNav;
  const SupDashboard({super.key, this.onQuickNav});

  @override
  State<SupDashboard> createState() => _SupDashboardState();
}

class _SupDashboardState extends State<SupDashboard> {
  @override
  Widget build(BuildContext context) {
    final db = MockDB();
    final all = db.workOrders;
    final dueToday = all.where((w) => w.isDueToday).length;
    final inProgress = all.where((w) => w.status == WOStatus.inProgress).length;
    final overdue = all.where((w) => w.isOverdue).length;
    final pending = db.pendingVerification;
    final criticals =
        db.breakdowns.where((b) => b.status != WOStatus.closed && b.priority.index >= WOPriority.high.index).toList();

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() {});
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _header(db.currentUser!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _kpi(
                          'Kepatuhan PM',
                          '${db.pmCompliance.toStringAsFixed(1)}%',
                          'Target 90%',
                          db.pmCompliance >= 90 ? AppColors.primary : AppColors.amberInk,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _kpi(
                          'Kesehatan Aset',
                          '${db.equipmentHealth.toStringAsFixed(1)}%',
                          '${db.equipments.length} mesin dipantau',
                          AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  gap16,
                  const SectionTitle('Beban Kerja Tim Hari Ini', icon: Icons.groups_rounded),
                  gap8,
                  Row(
                    children: [
                      StatTile(
                        label: 'Hari Ini',
                        value: '$dueToday',
                        caption: 'Terjadwal',
                        color: AppColors.amberInk,
                        onTap: () => widget.onQuickNav?.call(1),
                      ),
                      const SizedBox(width: 8),
                      StatTile(
                        label: 'Berjalan',
                        value: '$inProgress',
                        caption: 'Dikerjakan',
                        color: AppColors.info,
                        onTap: () => widget.onQuickNav?.call(1),
                      ),
                      const SizedBox(width: 8),
                      StatTile(
                        label: 'Overdue',
                        value: '$overdue',
                        caption: 'Kritis',
                        color: AppColors.danger,
                        onTap: () => widget.onQuickNav?.call(1),
                      ),
                      const SizedBox(width: 8),
                      StatTile(
                        label: 'Approval',
                        value: '$pending',
                        caption: 'Menunggu',
                        color: AppColors.primary,
                        onTap: () => widget.onQuickNav?.call(1),
                      ),
                    ],
                  ),
                  if (pending > 0) ...[
                    gap16,
                    NoticeBox(
                      icon: Icons.fact_check_rounded,
                      title: '$pending hasil inspeksi menunggu approval',
                      body: 'Verifikasi sebelum akhir shift agar WO bisa ditutup pada hari yang sama.',
                      color: AppColors.amberInk,
                      background: AppColors.amberTint,
                      action: ElevatedButton.icon(
                        onPressed: () => widget.onQuickNav?.call(1),
                        icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                        label: const Text('Buka Antrean Verifikasi'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.amberInk,
                          minimumSize: const Size(0, 42),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                  gap24,
                  SectionTitle(
                    'Isu Kritis Lantai Pabrik',
                    icon: Icons.crisis_alert_rounded,
                    trailingText: '${criticals.length} aktif',
                  ),
                  gap8,
                  if (criticals.isEmpty)
                    const EmptyState(
                      icon: Icons.verified_rounded,
                      title: 'Tidak ada isu kritis',
                      body: 'Seluruh stasiun beroperasi dalam batas normal.',
                    )
                  else
                    for (final b in criticals) BreakdownCard(breakdown: b, onChanged: () => setState(() {})),
                  gap8,
                  const SectionTitle('Status Stasiun', icon: Icons.factory_rounded),
                  gap8,
                  _stationHealth(),
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
          child: Row(
            children: [
              InitialAvatar(user.initials, color: Colors.white.withValues(alpha: 0.18), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Kendali Maintenance · ${Fmt.dayName(DateTime.now())}',
                      style: TextStyle(
                        fontSize: 12,
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
        ),
      ),
    );
  }

  Widget _kpi(String title, String value, String caption, Color color) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              color: AppColors.textFaint,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color, height: 1.1)),
          Text(caption, style: const TextStyle(fontSize: 11, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _stationHealth() {
    final byStation = <String, List<Equipment>>{};
    for (final e in MockDB().equipments) {
      byStation.putIfAbsent(e.station, () => []).add(e);
    }

    return AppCard(
      child: Column(
        children: [
          for (final entry in byStation.entries) ...[
            if (entry.key != byStation.keys.first) const Divider(height: 18),
            Row(
              children: [
                Expanded(
                  child: Text(
                    entry.key.replaceAll('Stasiun ', ''),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
                for (final e in entry.value)
                  Padding(
                    padding: const EdgeInsets.only(left: 5),
                    child: Tooltip(
                      message: '${e.name} · ${Labels.equipStatus(e.status)}',
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(color: Labels.equipColor(e.status), shape: BoxShape.circle),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Kartu breakdown dengan aksi assign / tutup.
class BreakdownCard extends StatelessWidget {
  final Breakdown breakdown;
  final VoidCallback onChanged;

  const BreakdownCard({super.key, required this.breakdown, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final b = breakdown;
    final color = Labels.priorityColor(b.priority);
    final elapsed = DateTime.now().difference(b.reportedAt);
    final slaBreached = b.status == WOStatus.assigned && elapsed > b.sla;

    return AppCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Tag(Labels.priority(b.priority).toUpperCase(), color: color, filled: true),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  b.id,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                ),
              ),
              const SizedBox(width: 7),
              Tag(Labels.woStatus(b.status), color: Labels.woStatusColor(b.status)),
            ],
          ),
          gap8,
          Text(
            '${b.equipment.name} · ${b.station.replaceAll('Stasiun ', '')}',
            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(b.issueDescription, style: const TextStyle(fontSize: 12.5, height: 1.45, color: AppColors.textMuted)),
          if (b.symptoms.isNotEmpty) ...[
            gap8,
            Wrap(spacing: 6, runSpacing: 6, children: [for (final s in b.symptoms) Tag(s, color: color)]),
          ],
          MetaRow(Icons.person_outline_rounded, 'Pelapor: ${b.reportedBy}'),
          MetaRow(
            slaBreached ? Icons.alarm_rounded : Icons.timer_outlined,
            slaBreached
                ? 'SLA ${Fmt.minutes(b.sla.inMinutes)} TERLAMPAUI · ${Fmt.relative(b.reportedAt)}'
                : 'Dilaporkan ${Fmt.relative(b.reportedAt)} · SLA ${Fmt.minutes(b.sla.inMinutes)}',
            color: slaBreached ? AppColors.danger : null,
            weight: slaBreached ? FontWeight.w800 : FontWeight.w500,
          ),
          if (b.handledBy != null) MetaRow(Icons.engineering_rounded, 'Ditangani: ${b.handledBy}'),
          if (MockDB().currentUser!.role == Role.supervisor && b.status != WOStatus.closed) ...[
            gap12,
            Row(
              children: [
                if (b.status == WOStatus.assigned)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        b.status = WOStatus.inProgress;
                        b.handledBy = MockDB().technician.name;
                        onChanged();
                        showAppSnack(
                          context,
                          '${MockDB().technician.firstName} ditugaskan menangani ${b.id}.',
                          color: AppColors.primary,
                          icon: Icons.engineering_rounded,
                        );
                      },
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                      label: const Text('Assign Teknisi'),
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    ),
                  )
                else
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        b.status = WOStatus.closed;
                        if (b.equipment.status != EquipStatus.operational) {
                          b.equipment.status = EquipStatus.warning;
                        }
                        onChanged();
                        showAppSnack(
                          context,
                          'Breakdown ${b.id} ditutup.',
                          color: AppColors.primary,
                          icon: Icons.check_rounded,
                        );
                      },
                      icon: const Icon(Icons.task_alt_rounded, size: 19),
                      label: const Text('Tutup Laporan'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(46)),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HUB MAINTENANCE SUPERVISOR
// ---------------------------------------------------------------------------

class SupMaintenanceHub extends StatelessWidget {
  const SupMaintenanceHub({super.key});

  @override
  Widget build(BuildContext context) {
    final pending = MockDB().pendingVerification;
    final open = MockDB().openBreakdowns;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Manajemen Maintenance'),
          actions: [NotificationBell(), const SizedBox(width: 6)],
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              const Tab(text: 'Jadwal & WO'),
              Tab(text: pending > 0 ? 'Verifikasi ($pending)' : 'Verifikasi'),
              Tab(text: open > 0 ? 'Breakdown ($open)' : 'Breakdown'),
              const Tab(text: 'Laporan'),
            ],
          ),
        ),
        body: const TabBarView(children: [SupScheduleTab(), SupVerifyTab(), SupBreakdownTab(), SupReportTab()]),
      ),
    );
  }
}

// --- Jadwal dengan kalender sungguhan ---------------------------------------

class SupScheduleTab extends StatefulWidget {
  const SupScheduleTab({super.key});

  @override
  State<SupScheduleTab> createState() => _SupScheduleTabState();
}

class _SupScheduleTabState extends State<SupScheduleTab> {
  DateTime _selected = dayOnly(DateTime.now());

  List<WorkOrder> _woOn(DateTime day) =>
      MockDB().workOrders.where((w) => dayOnly(w.scheduledAt) == dayOnly(day)).toList()
        ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

  @override
  Widget build(BuildContext context) {
    final dayTasks = _woOn(_selected);

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
        children: [
          MonthCalendar(
            selectedDay: _selected,
            onDaySelected: (d) => setState(() => _selected = d),
            markersFor: (day) => _woOn(day).map((w) => Labels.urgency(w)).toList(),
          ),
          Row(
            children: [
              Expanded(
                child: SectionTitle(
                  '${Fmt.dayName(_selected)}, ${Fmt.date(_selected)}',
                  icon: Icons.event_note_rounded,
                ),
              ),
              Tag('${dayTasks.length} WO', color: AppColors.primary),
            ],
          ),
          gap12,
          if (dayTasks.isEmpty)
            EmptyState(
              icon: Icons.event_available_rounded,
              title: 'Tidak ada jadwal di tanggal ini',
              body: 'Pilih tanggal lain pada kalender atau buat work order baru.',
              action: OutlinedButton.icon(
                onPressed: _createWorkOrder,
                icon: const Icon(Icons.add_rounded, size: 19),
                label: const Text('Buat WO untuk tanggal ini'),
              ),
            )
          else
            for (final wo in dayTasks) _scheduleCard(wo),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createWorkOrder,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Buat WO Baru'),
      ),
    );
  }

  Widget _scheduleCard(WorkOrder wo) {
    final color = Labels.urgency(wo);
    return AppCard(
      accent: color,
      onTap: () async {
        await Navigator.push(context, MaterialPageRoute(builder: (_) => TaskDetailScreen(workOrder: wo)));
        if (mounted) setState(() {});
      },
      child: Row(
        children: [
          Column(
            children: [
              Text(
                Fmt.time(wo.scheduledAt).replaceAll(' WIB', ''),
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, height: 1.1),
              ),
              Text(
                Fmt.minutes(wo.estimatedMinutes),
                style: const TextStyle(fontSize: 10, color: AppColors.textMuted, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(width: 1, height: 38, color: AppColors.cardBorder),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(wo.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.3)),
                const SizedBox(height: 2),
                Text(
                  '${wo.id} · ${wo.equipment.name}',
                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Tag(Labels.woStatus(wo.status), color: Labels.woStatusColor(wo.status)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        wo.assignedTo.firstName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _createWorkOrder() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => CreateWorkOrderScreen(initialDate: _selected)),
    );
    if (created == true && mounted) setState(() {});
  }
}

/// Form pembuatan work order dengan pemilih tanggal & jam sungguhan.
class CreateWorkOrderScreen extends StatefulWidget {
  final DateTime initialDate;
  const CreateWorkOrderScreen({super.key, required this.initialDate});

  @override
  State<CreateWorkOrderScreen> createState() => _CreateWorkOrderScreenState();
}

class _CreateWorkOrderScreenState extends State<CreateWorkOrderScreen> {
  final _titleCtrl = TextEditingController();
  Equipment? _equipment;
  AppUser _assignee = MockDB().technician;
  WOType _type = WOType.preventive;
  WOPriority _priority = WOPriority.medium;
  late DateTime _date = widget.initialDate;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  int _minutes = 30;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  bool get _valid => _equipment != null && _titleCtrl.text.trim().length >= 5;

  @override
  Widget build(BuildContext context) {
    final scheduled = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Work Order'),
        bottom: const BreadcrumbBar(text: 'Penjadwalan perawatan · supervisor'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SectionTitle('Pekerjaan', icon: Icons.assignment_rounded),
          gap8,
          TextField(
            controller: _titleCtrl,
            onChanged: (_) => setState(() {}),
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Contoh: Pelumasan bearing conveyor nut plant',
              labelText: 'Judul perintah kerja',
            ),
          ),
          gap16,
          const SectionTitle('Mesin Sasaran', icon: Icons.precision_manufacturing_rounded),
          gap8,
          DropdownButtonFormField<Equipment>(
            initialValue: _equipment,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Pilih aset'),
            items: [
              for (final e in MockDB().equipments)
                DropdownMenuItem(value: e, child: Text('${e.name} · ${e.code}', overflow: TextOverflow.ellipsis)),
            ],
            onChanged: (v) => setState(() => _equipment = v),
          ),
          gap16,
          const SectionTitle('Jadwal Pelaksanaan', icon: Icons.event_rounded),
          gap8,
          Row(
            children: [
              Expanded(
                child: _pickerField(
                  icon: Icons.calendar_month_rounded,
                  label: 'Tanggal',
                  value: '${Fmt.dayName(_date)}, ${Fmt.date(_date)}',
                  onTap: _pickDate,
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 118,
                child: _pickerField(
                  icon: Icons.schedule_rounded,
                  label: 'Jam mulai',
                  value: _time.format(context),
                  onTap: _pickTime,
                ),
              ),
            ],
          ),
          gap12,
          AppCard(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text('Estimasi durasi', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    ),
                    Tag(Fmt.minutes(_minutes), color: AppColors.primary),
                  ],
                ),
                Slider(
                  value: _minutes.toDouble(),
                  min: 15,
                  max: 240,
                  divisions: 15,
                  label: Fmt.minutes(_minutes),
                  onChanged: (v) => setState(() => _minutes = v.round()),
                ),
              ],
            ),
          ),
          const SectionTitle('Jenis & Prioritas', icon: Icons.flag_rounded),
          gap8,
          PillTabs(
            options: WOType.values.map(Labels.woType).toList(),
            selected: Labels.woType(_type),
            onSelected: (v) => setState(() => _type = WOType.values.firstWhere((t) => Labels.woType(t) == v)),
          ),
          gap8,
          PillTabs(
            options: WOPriority.values.map(Labels.priority).toList(),
            selected: Labels.priority(_priority),
            onSelected: (v) => setState(() => _priority = WOPriority.values.firstWhere((p) => Labels.priority(p) == v)),
          ),
          gap16,
          const SectionTitle('Penugasan', icon: Icons.engineering_rounded),
          gap8,
          for (final u in [MockDB().technician, MockDB.helper])
            AppCard(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              borderColor: _assignee.id == u.id ? AppColors.primary : AppColors.cardBorder,
              color: _assignee.id == u.id ? AppColors.primaryTint : Colors.white,
              onTap: () => setState(() => _assignee = u),
              child: Row(
                children: [
                  InitialAvatar(u.initials),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                        Text(
                          '${u.jobTitle} · ${MockDB().tasksOf(u).where((w) => w.isOpen).length} tugas aktif',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _assignee.id == u.id ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: _assignee.id == u.id ? AppColors.primary : AppColors.cardBorder,
                  ),
                ],
              ),
            ),
          gap8,
          NoticeBox(
            icon: Icons.info_outline_rounded,
            title: 'Ringkasan jadwal',
            body:
                '${Fmt.dayName(scheduled)}, ${Fmt.date(scheduled)} pukul ${Fmt.time(scheduled)} · '
                'estimasi ${Fmt.minutes(_minutes)} · ${_assignee.firstName}',
            color: AppColors.info,
          ),
        ],
      ),
      bottomNavigationBar: BottomBar(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _valid ? () => _save(scheduled) : null,
              icon: const Icon(Icons.save_rounded, size: 21),
              label: const Text('SIMPAN & TUGASKAN'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pickerField({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: InputDecorator(
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20)),
        child: Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 365)),
      helpText: 'Tanggal pelaksanaan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      helpText: 'Jam mulai pekerjaan',
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked != null && mounted) setState(() => _time = picked);
  }

  void _save(DateTime scheduled) {
    final db = MockDB();
    final seq = 1100 + db.workOrders.length;
    final wo = WorkOrder(
      id: 'WO-${scheduled.year}-$seq',
      code: 'PM-MEC-${(seq % 90).toString().padLeft(2, '0')}',
      title: _titleCtrl.text.trim(),
      description: 'Dibuat oleh ${db.currentUser!.name} melalui penjadwalan maintenance.',
      equipment: _equipment!,
      type: _type,
      priority: _priority,
      assignedTo: _assignee,
      issuedBy: db.supervisor,
      scheduledAt: scheduled,
      estimatedMinutes: _minutes,
      status: WOStatus.assigned,
      checklist: [
        ChecklistItem(
          id: '${seq}a',
          category: 'KESELAMATAN',
          taskName: 'Isolasi energi & pasang tag LOTO',
          description: 'Pastikan sumber daya terkunci sebelum pekerjaan dimulai.',
        ),
        ChecklistItem(
          id: '${seq}b',
          category: 'PELAKSANAAN',
          taskName: _titleCtrl.text.trim(),
          description: 'Kerjakan sesuai standar perawatan ${_equipment!.name}.',
        ),
        ChecklistItem(
          id: '${seq}c',
          category: 'PENUTUP',
          taskName: 'Uji fungsi & rapikan area kerja',
          description: 'Jalankan mesin sesaat dan pastikan tidak ada kelainan.',
        ),
      ],
      ppe: const ['Helm Safety PKS', 'Sarung Tangan Heavy-Duty', 'Sepatu Anti Minyak'],
      lotoNote: 'Terapkan prosedur LOTO pada panel ${_equipment!.code} sebelum pekerjaan dimulai.',
    );
    db.workOrders.add(wo);
    db.extraNotifications.insert(
      0,
      AppNotification(
        title: 'Work order baru ditugaskan',
        subtitle: '${wo.id} · ${wo.title}',
        at: DateTime.now(),
        icon: Icons.assignment_turned_in_rounded,
        color: AppColors.primary,
        unread: true,
      ),
    );

    Navigator.pop(context, true);
    showAppSnack(
      context,
      '${wo.id} dijadwalkan ${Fmt.date(scheduled)} pukul ${Fmt.time(scheduled)} untuk ${_assignee.firstName}.',
      color: AppColors.primary,
      icon: Icons.event_available_rounded,
    );
  }
}

// --- Verifikasi hasil kerja -------------------------------------------------

class SupVerifyTab extends StatefulWidget {
  const SupVerifyTab({super.key});

  @override
  State<SupVerifyTab> createState() => _SupVerifyTabState();
}

class _SupVerifyTabState extends State<SupVerifyTab> {
  @override
  Widget build(BuildContext context) {
    final pending =
        MockDB().workOrders.where((w) => w.status == WOStatus.waitingVerification).toList()
          ..sort((a, b) => (b.finishedAt ?? b.scheduledAt).compareTo(a.finishedAt ?? a.scheduledAt));

    if (pending.isEmpty) {
      return Container(
        color: AppColors.screenBg,
        child: const EmptyState(
          icon: Icons.verified_rounded,
          title: 'Antrean verifikasi kosong',
          body: 'Semua hasil inspeksi teknisi sudah diverifikasi.',
        ),
      );
    }

    return Container(
      color: AppColors.screenBg,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: pending.length,
        itemBuilder: (_, i) => _verifyCard(pending[i]),
      ),
    );
  }

  Widget _verifyCard(WorkOrder wo) {
    return AppCard(
      accent: wo.findingCount > 0 ? AppColors.amber : AppColors.primary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(wo.id, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800)),
              const Spacer(),
              const Tag('MENUNGGU APPROVAL', color: AppColors.amberInk, background: AppColors.amberTint),
            ],
          ),
          gap8,
          Text(wo.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w800, height: 1.3)),
          MetaRow(Icons.engineering_rounded, '${wo.assignedTo.name} · ${wo.equipment.name}'),
          MetaRow(
            Icons.timer_outlined,
            'Durasi ${Fmt.minutes(wo.workedMinutes)} · dikirim ${Fmt.relative(wo.finishedAt ?? DateTime.now())}',
          ),
          gap12,
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(color: AppColors.screenBg, borderRadius: BorderRadius.circular(AppRadius.inner)),
            child: Row(
              children: [
                _verifyStat('Checklist', '${wo.answered}/${wo.checklist.length}', AppColors.textPrimary),
                _verifyStat('Aman', '${wo.safeCount}', AppColors.primary),
                _verifyStat(
                  'Temuan',
                  '${wo.findingCount}',
                  wo.findingCount > 0 ? AppColors.danger : AppColors.textMuted,
                ),
                _verifyStat('Foto', '${wo.evidence.length}', AppColors.info),
              ],
            ),
          ),
          if (wo.evidence.isNotEmpty) ...[
            gap12,
            Row(
              children: [
                for (final p in wo.evidence.take(4))
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PhotoThumb(
                      seed: p.seed,
                      stamp: Fmt.time(p.takenAt).replaceAll(' WIB', ''),
                      flagged: p.finding,
                      width: 56,
                      height: 56,
                    ),
                  ),
                if (wo.signed)
                  const Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Tag('DITANDATANGANI', color: AppColors.primary, icon: Icons.draw_rounded),
                    ),
                  ),
              ],
            ),
          ],
          for (final item in wo.checklist.where((c) => c.isChecked == false)) ...[
            gap8,
            NoticeBox(
              icon: Icons.report_problem_rounded,
              title: item.taskName,
              body: item.note,
              color: AppColors.dangerInk,
              background: AppColors.dangerTint,
            ),
          ],
          if (wo.technicianNote != null && wo.technicianNote!.trim().isNotEmpty) ...[
            gap8,
            Text(
              'Catatan teknisi: "${wo.technicianNote}"',
              style: const TextStyle(
                fontSize: 12.3,
                fontStyle: FontStyle.italic,
                color: AppColors.textMuted,
                height: 1.45,
              ),
            ),
          ],
          gap12,
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _reject(wo),
                  icon: const Icon(Icons.undo_rounded, size: 19),
                  label: const Text('Kembalikan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.danger,
                    side: const BorderSide(color: AppColors.danger, width: 1.4),
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _approve(wo),
                  icon: const Icon(Icons.check_circle_rounded, size: 19),
                  label: const Text('Setujui'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _verifyStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _approve(WorkOrder wo) {
    setState(() {
      wo.status = WOStatus.approved;
      if (wo.findingCount == 0 && wo.equipment.status == EquipStatus.warning) {
        wo.equipment.status = EquipStatus.operational;
      }
    });
    showAppSnack(context, '${wo.id} disetujui dan ditutup.', color: AppColors.primary, icon: Icons.verified_rounded);
  }

  Future<void> _reject(WorkOrder wo) async {
    final ctrl = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => SheetShell(
            title: 'Kembalikan ke Teknisi',
            subtitle: '${wo.id} · ${wo.assignedTo.name}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: ctrl,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(hintText: 'Alasan pengembalian, misal: foto bukti kurang jelas.'),
                ),
                gap16,
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, ctrl.text.trim().isNotEmpty),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                    child: const Text('Kembalikan Pekerjaan'),
                  ),
                ),
              ],
            ),
          ),
    );

    if (!mounted) return;
    if (ok == true) {
      setState(() {
        wo.status = WOStatus.rejected;
        wo.rejectReason = ctrl.text.trim();
      });
      showAppSnack(
        context,
        '${wo.id} dikembalikan ke ${wo.assignedTo.firstName}.',
        color: AppColors.danger,
        icon: Icons.undo_rounded,
      );
    } else if (ok == false) {
      showAppSnack(context, 'Alasan pengembalian wajib diisi.', color: AppColors.danger);
    }
  }
}

// --- Breakdown --------------------------------------------------------------

class SupBreakdownTab extends StatefulWidget {
  const SupBreakdownTab({super.key});

  @override
  State<SupBreakdownTab> createState() => _SupBreakdownTabState();
}

class _SupBreakdownTabState extends State<SupBreakdownTab> {
  String _filter = 'Baru';

  @override
  Widget build(BuildContext context) {
    final all = MockDB().breakdowns;
    final list = switch (_filter) {
      'Baru' => all.where((b) => b.status == WOStatus.assigned).toList(),
      'Ditangani' => all.where((b) => b.status == WOStatus.inProgress).toList(),
      _ => all.where((b) => b.status == WOStatus.closed).toList(),
    };

    return Container(
      color: AppColors.screenBg,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: PillTabs(
              scrollable: false,
              options: [
                'Baru (${all.where((b) => b.status == WOStatus.assigned).length})',
                'Ditangani (${all.where((b) => b.status == WOStatus.inProgress).length})',
                'Selesai (${all.where((b) => b.status == WOStatus.closed).length})',
              ],
              selected: switch (_filter) {
                'Ditangani' => 'Ditangani (${all.where((b) => b.status == WOStatus.inProgress).length})',
                'Selesai' => 'Selesai (${all.where((b) => b.status == WOStatus.closed).length})',
                _ => 'Baru (${all.where((b) => b.status == WOStatus.assigned).length})',
              },
              onSelected: (v) => setState(() => _filter = v.split(' (').first),
            ),
          ),
          Expanded(
            child:
                list.isEmpty
                    ? const EmptyState(
                      icon: Icons.inbox_rounded,
                      title: 'Tidak ada laporan',
                      body: 'Belum ada breakdown pada kategori ini.',
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => BreakdownCard(breakdown: list[i], onChanged: () => setState(() {})),
                    ),
          ),
        ],
      ),
    );
  }
}

// --- Laporan supervisor -----------------------------------------------------

class SupReportTab extends StatelessWidget {
  const SupReportTab({super.key});

  @override
  Widget build(BuildContext context) {
    final db = MockDB();
    final all = db.workOrders;
    final selesai = all.where((w) => w.status == WOStatus.approved).length;
    final overdue = all.where((w) => w.isOverdue).length;
    final byPriority = {for (final p in WOPriority.values) p: db.breakdowns.where((b) => b.priority == p).length};

    return Container(
      color: AppColors.screenBg,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          const SectionTitle('Ringkasan Periode Berjalan', icon: Icons.summarize_rounded),
          gap8,
          Row(
            children: [
              StatTile(label: 'Total WO', value: '${all.length}', color: AppColors.textPrimary),
              const SizedBox(width: 8),
              StatTile(label: 'Selesai', value: '$selesai', color: AppColors.primary),
              const SizedBox(width: 8),
              StatTile(label: 'Overdue', value: '$overdue', color: AppColors.danger),
              const SizedBox(width: 8),
              StatTile(label: 'Breakdown', value: '${db.breakdowns.length}', color: AppColors.amberInk),
            ],
          ),
          gap16,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Penyelesaian WO 7 Hari Terakhir', icon: Icons.show_chart_rounded),
                gap16,
                TrendBars(
                  labels: List.generate(7, (i) {
                    final d = DateTime.now().subtract(Duration(days: 6 - i));
                    return Fmt.dayName(d).substring(0, 3);
                  }),
                  values: const [4, 6, 5, 7, 3, 6, 5],
                ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Breakdown per Tingkat Keparahan', icon: Icons.pie_chart_rounded),
                gap12,
                for (final p in WOPriority.values.reversed)
                  BarRow(
                    label: Labels.priority(p),
                    value: byPriority[p] ?? 0,
                    max: (byPriority.values.isEmpty ? 1 : byPriority.values.reduce((a, b) => a > b ? a : b)).clamp(
                      1,
                      999,
                    ),
                    color: Labels.priorityColor(p),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed:
                  () => showAppSnack(
                    context,
                    'Laporan periode disiapkan untuk diekspor.',
                    color: AppColors.primary,
                    icon: Icons.download_rounded,
                  ),
              icon: const Icon(Icons.download_rounded, size: 20),
              label: const Text('Ekspor Laporan Maintenance'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            ),
          ),
        ],
      ),
    );
  }
}

// ===========================================================================
// MANAJEMEN
// ===========================================================================

class MgtDashboard extends StatefulWidget {
  final ValueChanged<int>? onQuickNav;
  const MgtDashboard({super.key, this.onQuickNav});

  @override
  State<MgtDashboard> createState() => _MgtDashboardState();
}

class _MgtDashboardState extends State<MgtDashboard> {
  String _period = 'Minggu Ini';

  @override
  Widget build(BuildContext context) {
    final db = MockDB();
    final mult = _period == 'Minggu Ini' ? 1 : (_period == 'Bulan Ini' ? 4 : 12);
    final totalWo = 32 * mult;
    final selesai = (totalWo * 0.9).round();

    final segments = [
      (label: 'Critical', value: 3 * mult, color: AppColors.danger),
      (label: 'Major', value: 5 * mult, color: AppColors.amber),
      (label: 'Minor', value: 6 * mult, color: AppColors.info),
    ];
    final breakdownCount = segments.fold<int>(0, (a, b) => a + b.value);
    // Periode lebih panjang meratakan lonjakan, jadi uptime & MTTR ikut bergeser.
    final uptime = 96.2 + (mult == 1 ? 0 : (mult == 4 ? 0.5 : 0.9));
    final mttr = 1.8 - (mult == 1 ? 0 : (mult == 4 ? 0.1 : 0.2));

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await Future<void>.delayed(const Duration(milliseconds: 500));
          if (mounted) setState(() {});
        },
        child: ListView(
          padding: EdgeInsets.zero,
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _header(db.currentUser!),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PillTabs(
                    options: const ['Minggu Ini', 'Bulan Ini', 'Tahun Berjalan'],
                    selected: _period,
                    onSelected: (v) => setState(() => _period = v),
                  ),
                  gap16,
                  Row(
                    children: [
                      Expanded(
                        child: _bigKpi(
                          'Kepatuhan PM',
                          '${db.pmCompliance.toStringAsFixed(1)}%',
                          Icons.verified_rounded,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _bigKpi(
                          'Kesehatan Aset',
                          '${db.equipmentHealth.toStringAsFixed(1)}%',
                          Icons.favorite_rounded,
                          AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  gap12,
                  Row(
                    children: [
                      Expanded(
                        child: _bigKpi(
                          'Uptime Pabrik',
                          '${uptime.toStringAsFixed(1)}%',
                          Icons.bolt_rounded,
                          AppColors.amberInk,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _bigKpi(
                          'MTTR',
                          '${mttr.toStringAsFixed(1)} Jam',
                          Icons.timelapse_rounded,
                          AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  gap24,
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SectionTitle('Komposisi Breakdown', icon: Icons.pie_chart_rounded, trailingText: _period),
                        gap16,
                        Row(
                          children: [
                            DonutChart(segments: segments, centerValue: '$breakdownCount', centerLabel: 'kejadian'),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  for (final s in segments)
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 10,
                                            height: 10,
                                            decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              s.label,
                                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                          Text(
                                            '${s.value}',
                                            style: TextStyle(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w800,
                                              color: s.color,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle('Tren Penyelesaian Work Order', icon: Icons.show_chart_rounded),
                        gap16,
                        TrendBars(
                          labels: const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'],
                          values: [4.0 * mult, 6.0 * mult, 5.0 * mult, 7.0 * mult, 3.0 * mult, 6.0 * mult, 5.0 * mult],
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                  const SectionTitle('Ringkasan Maintenance', icon: Icons.summarize_rounded),
                  gap8,
                  Row(
                    children: [
                      StatTile(label: 'Total WO', value: '$totalWo', color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      StatTile(label: 'Selesai', value: '$selesai', color: AppColors.primary),
                      const SizedBox(width: 8),
                      StatTile(label: 'Overdue', value: '${totalWo - selesai}', color: AppColors.danger),
                    ],
                  ),
                  gap24,
                  SectionTitle(
                    'Aset Perlu Perhatian',
                    icon: Icons.warning_amber_rounded,
                    trailingText: 'Lihat semua',
                    onTrailingTap: () => widget.onQuickNav?.call(1),
                  ),
                  gap8,
                  for (final e in db.equipments.where((e) => e.status != EquipStatus.operational))
                    AppCard(
                      accent: Labels.equipColor(e.status),
                      padding: const EdgeInsets.all(13),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                                Text(
                                  '${e.station} · ${e.code}',
                                  style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          Tag(Labels.equipStatus(e.status), color: Labels.equipColor(e.status), filled: true),
                        ],
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
          colors: [AppColors.primaryDark, AppColors.primaryDeep],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          child: Row(
            children: [
              InitialAvatar(user.initials, color: Colors.white.withValues(alpha: 0.18), size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dashboard Eksekutif · ${MockDB().millName}',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: Colors.white.withValues(alpha: 0.75),
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
              const Tag('READ-ONLY', color: Colors.white24, filled: true),
              NotificationBell(onOpened: () => setState(() {})),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigKpi(String title, String value, IconData icon, Color color) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title.toUpperCase(),
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
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color, height: 1.1)),
        ],
      ),
    );
  }
}

// --- Laporan manajemen ------------------------------------------------------

class MgtReportScreen extends StatefulWidget {
  const MgtReportScreen({super.key});

  @override
  State<MgtReportScreen> createState() => _MgtReportScreenState();
}

class _MgtReportScreenState extends State<MgtReportScreen> {
  late DateTimeRange _range = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 29)),
    end: DateTime.now(),
  );

  int get _days => _range.duration.inDays + 1;

  @override
  Widget build(BuildContext context) {
    final db = MockDB();
    final scale = _days / 30;
    final totalWo = (120 * scale).round();
    final selesai = (108 * scale).round();
    final overdue = totalWo - selesai;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan Kinerja'),
        bottom: BreadcrumbBar(text: '${Fmt.date(_range.start)} — ${Fmt.date(_range.end)} · $_days hari'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range_rounded, size: 20),
              label: const Text('Ubah Periode Laporan'),
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            ),
          ),
          gap16,
          Row(
            children: [
              StatTile(label: 'Total WO', value: '$totalWo', color: AppColors.textPrimary),
              const SizedBox(width: 8),
              StatTile(label: 'Selesai', value: '$selesai', color: AppColors.primary),
              const SizedBox(width: 8),
              StatTile(label: 'Overdue', value: '$overdue', color: AppColors.danger),
              const SizedBox(width: 8),
              StatTile(label: 'Kepatuhan', value: '${db.pmCompliance.toStringAsFixed(0)}%', color: AppColors.info),
            ],
          ),
          gap16,
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitle('Kinerja per Stasiun', icon: Icons.factory_rounded),
                gap12,
                for (final s in const [
                  ('Kempa (Press)', 34, AppColors.primary),
                  ('Sterilizer', 21, AppColors.info),
                  ('Thresher', 18, AppColors.secondary),
                  ('Nut & Kernel', 15, AppColors.amber),
                  ('Boiler & Utilitas', 12, AppColors.danger),
                ])
                  BarRow(
                    label: s.$1,
                    value: (s.$2 * scale).round(),
                    max: (34 * scale).round().clamp(1, 999),
                    color: s.$3,
                    suffix: ' WO',
                  ),
              ],
            ),
          ),
          AppCard(
            child: Column(
              children: [
                _row('Rata-rata waktu penyelesaian', '${(1.8 + scale * 0.1).toStringAsFixed(1)} Jam'),
                const Divider(height: 18),
                _row('Breakdown tercatat', '${(14 * scale).round()} kejadian'),
                const Divider(height: 18),
                _row('Downtime akibat breakdown', '${(9.4 * scale).toStringAsFixed(1)} Jam'),
                const Divider(height: 18),
                _row('Kepatuhan APD & LOTO', '98%'),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  () => showAppSnack(
                    context,
                    'Laporan ${Fmt.date(_range.start)} — ${Fmt.date(_range.end)} disiapkan untuk diekspor.',
                    color: AppColors.primary,
                    icon: Icons.picture_as_pdf_rounded,
                  ),
              icon: const Icon(Icons.picture_as_pdf_rounded, size: 20),
              label: const Text('EKSPOR LAPORAN (PDF)'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
      ],
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range,
      helpText: 'Periode laporan kinerja',
      saveText: 'Terapkan',
      cancelText: 'Batal',
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }
}
