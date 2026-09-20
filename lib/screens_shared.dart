import 'package:flutter/material.dart';

import 'data.dart';
import 'main.dart';
import 'theme.dart';

// ---------------------------------------------------------------------------
// KERANGKA LAYAR
// ---------------------------------------------------------------------------

/// Baris breadcrumb tipis di bawah judul AppBar (pola header mockup Stitch).
class BreadcrumbBar extends StatelessWidget implements PreferredSizeWidget {
  final String text;
  final Color color;

  const BreadcrumbBar({super.key, required this.text, this.color = AppColors.primary});

  @override
  Size get preferredSize => const Size.fromHeight(26);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Colors.white.withValues(alpha: 0.82)),
      ),
    );
  }
}

/// Panel aksi bawah dengan garis pemisah dan safe area.
class BottomBar extends StatelessWidget {
  final List<Widget> children;
  const BottomBar({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.cardBorder)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

/// Cangkang bottom sheet: handle, judul, dan padding yang menghindari keyboard.
class SheetShell extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const SheetShell({super.key, required this.title, this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                gap16,
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle!, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
                ],
                gap16,
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Placeholder ramah untuk daftar kosong.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(color: AppColors.primaryTint, shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: AppColors.primary),
            ),
            gap16,
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 5),
            Text(
              body,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12.8, color: AppColors.textMuted, height: 1.5),
            ),
            if (action != null) ...[gap16, action!],
          ],
        ),
      ),
    );
  }
}

/// Indikator sinkronisasi berdenyut pada header dashboard.
class SyncBadge extends StatefulWidget {
  const SyncBadge({super.key});

  @override
  State<SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends State<SyncBadge> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(begin: 0.35, end: 1).animate(_ctrl),
            child: Container(
              width: 7,
              height: 7,
              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 5),
          const Text(
            'SYNC',
            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }
}

/// Lonceng notifikasi + badge jumlah yang belum dibaca.
class NotificationBell extends StatelessWidget {
  final VoidCallback? onOpened;
  final Color color;

  const NotificationBell({super.key, this.onOpened, this.color = Colors.white});

  @override
  Widget build(BuildContext context) {
    final unread = MockDB().notificationsFor(MockDB().currentUser!.role).where((n) => n.unread).length;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          tooltip: 'Notifikasi',
          color: color,
          onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationScreen()));
            onOpened?.call();
          },
          icon: const Icon(Icons.notifications_none_rounded, size: 25),
        ),
        if (unread > 0)
          Positioned(
            right: 6,
            top: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: Colors.white, width: 1.4),
              ),
              child: Text(
                '$unread',
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
              ),
            ),
          ),
      ],
    );
  }
}

/// Ringkasan SOP K3 pabrik kelapa sawit.
void showSopSheet(BuildContext context) {
  const langkah = [
    ('Briefing shift & serah terima', 'Catat kondisi mesin dari shift sebelumnya sebelum masuk area produksi.'),
    ('Isolasi energi (LOTO)', 'Matikan panel MCC, pasang gembok dan tag atas nama pelaksana.'),
    ('Verifikasi nol energi', 'Pastikan tekanan uap dan putaran poros benar-benar berhenti.'),
    ('Kerjakan sesuai checklist', 'Ikuti urutan poin inspeksi dan catat nilai terukur apa adanya.'),
    ('Pulihkan & lepas LOTO', 'Pasang kembali guard, rapikan area, lalu lepas gembok oleh pemasangnya.'),
  ];

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => SheetShell(
          title: 'SOP K3 Pabrik Kelapa Sawit',
          subtitle: 'Lima langkah wajib sebelum dan sesudah pekerjaan perawatan.',
          child: Column(
            children: [
              for (var i = 0; i < langkah.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(langkah[i].$1, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
                            const SizedBox(height: 2),
                            Text(
                              langkah[i].$2,
                              style: const TextStyle(fontSize: 12.3, color: AppColors.textMuted, height: 1.45),
                            ),
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

// ---------------------------------------------------------------------------
// KATALOG MESIN
// ---------------------------------------------------------------------------

class EquipmentListScreen extends StatefulWidget {
  const EquipmentListScreen({super.key});

  @override
  State<EquipmentListScreen> createState() => _EquipmentListScreenState();
}

class _EquipmentListScreenState extends State<EquipmentListScreen> {
  String _query = '';
  String _filter = 'Semua';

  @override
  Widget build(BuildContext context) {
    var list = MockDB().equipments.toList();
    if (_filter != 'Semua') {
      list = list.where((e) => e.station.replaceAll('Stasiun ', '') == _filter).toList();
    }
    if (_query.isNotEmpty) {
      final q = _query.toLowerCase();
      list = list.where((e) => e.name.toLowerCase().contains(q) || e.code.toLowerCase().contains(q)).toList();
    }

    final stations = ['Semua', ...MockDB().equipments.map((e) => e.station.replaceAll('Stasiun ', '')).toSet()];
    final critical =
        MockDB().equipments.where((e) => e.status == EquipStatus.critical || e.status == EquipStatus.stopped).length;
    final warning = MockDB().equipments.where((e) => e.status == EquipStatus.warning).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Katalog Mesin PKS'),
        bottom: BreadcrumbBar(
          text: '${MockDB().equipments.length} aset terdaftar · $warning perlu perhatian · $critical kritis',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: TextField(
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Cari nama mesin atau kode aset',
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.textMuted),
              ),
            ),
          ),
          PillTabs(
            options: stations,
            selected: _filter,
            onSelected: (f) => setState(() => _filter = f),
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          gap12,
          Expanded(
            child:
                list.isEmpty
                    ? const EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Mesin tidak ditemukan',
                      body: 'Coba kata kunci lain atau pilih stasiun berbeda.',
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: list.length,
                      itemBuilder: (_, i) => _equipmentCard(list[i]),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _equipmentCard(Equipment eq) {
    final color = Labels.equipColor(eq.status);
    final openWo = MockDB().workOrders.where((w) => w.equipment.id == eq.id && w.isOpen).length;
    final tempHot = eq.temperature > eq.tempLimit;
    final vibHigh = eq.vibration > eq.vibLimit;

    return AppCard(
      accent: color,
      onTap: () => _showDetail(eq),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(eq.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
              Tag(Labels.equipStatus(eq.status), color: color),
            ],
          ),
          MetaRow(Icons.qr_code_2_rounded, '${eq.code} · ${eq.line}'),
          MetaRow(Icons.factory_outlined, '${eq.station} · ${eq.capacity}'),
          gap12,
          Row(
            children: [
              _reading(
                Icons.thermostat_rounded,
                '${eq.temperature.toStringAsFixed(1)}°C',
                'maks ${eq.tempLimit.toStringAsFixed(0)}',
                tempHot,
              ),
              const SizedBox(width: 8),
              _reading(
                Icons.vibration_rounded,
                '${eq.vibration.toStringAsFixed(1)} mm/s',
                'maks ${eq.vibLimit.toStringAsFixed(1)}',
                vibHigh,
              ),
              const SizedBox(width: 8),
              _reading(Icons.assignment_rounded, '$openWo WO', 'aktif', false),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reading(IconData icon, String value, String caption, bool alert) {
    final color = alert ? AppColors.danger : AppColors.textPrimary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: alert ? AppColors.dangerTint : AppColors.screenBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 15, color: alert ? AppColors.danger : AppColors.textMuted),
            const SizedBox(height: 3),
            Text(value, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: color)),
            Text(
              caption,
              style: const TextStyle(fontSize: 9.5, color: AppColors.textFaint, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(Equipment eq) {
    final wos =
        MockDB().workOrders.where((w) => w.equipment.id == eq.id).toList()
          ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));
    final brs = MockDB().breakdowns.where((b) => b.equipment.id == eq.id).toList();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => SheetShell(
            title: eq.name,
            subtitle: '${eq.code} · ${eq.station} · ${eq.line}',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tag(Labels.equipStatus(eq.status), color: Labels.equipColor(eq.status), filled: true),
                    const SizedBox(width: 8),
                    Tag('Kapasitas ${eq.capacity}', color: AppColors.textMuted),
                  ],
                ),
                gap16,
                const Text(
                  'RIWAYAT PERINTAH KERJA',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFaint,
                    letterSpacing: 0.5,
                  ),
                ),
                gap8,
                if (wos.isEmpty)
                  const Text(
                    'Belum ada work order untuk aset ini.',
                    style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
                  )
                else
                  for (final w in wos.take(4))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(color: Labels.woStatusColor(w.status), shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${w.id} · ${Labels.woType(w.type)}',
                              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            Fmt.dateShort(w.scheduledAt),
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                if (brs.isNotEmpty) ...[
                  gap12,
                  const Text(
                    'BREAKDOWN TERCATAT',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textFaint,
                      letterSpacing: 0.5,
                    ),
                  ),
                  gap8,
                  for (final b in brs)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '${b.id} · ${Labels.priority(b.priority)} · ${Fmt.relative(b.reportedAt)}',
                        style: const TextStyle(fontSize: 12.3, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
                gap16,
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, size: 19),
                    label: const Text('Tutup'),
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

// ---------------------------------------------------------------------------
// RIWAYAT
// ---------------------------------------------------------------------------

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  DateTimeRange? _range;

  @override
  Widget build(BuildContext context) {
    var entries = MockDB().history;
    if (_range != null) {
      entries =
          entries
              .where(
                (e) =>
                    !e.at.isBefore(dayOnly(_range!.start)) &&
                    !e.at.isAfter(dayOnly(_range!.end).add(const Duration(days: 1))),
              )
              .toList();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Maintenance'),
        bottom: BreadcrumbBar(
          text:
              _range == null
                  ? 'Menampilkan seluruh riwayat (${entries.length} catatan)'
                  : '${Fmt.date(_range!.start)} — ${Fmt.date(_range!.end)} · ${entries.length} catatan',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickRange,
                    icon: const Icon(Icons.date_range_rounded, size: 19),
                    label: Text(_range == null ? 'Pilih Rentang Tanggal' : 'Ubah Rentang'),
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  ),
                ),
                if (_range != null) ...[
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: () => setState(() => _range = null),
                    icon: const Icon(Icons.filter_alt_off_rounded),
                    tooltip: 'Hapus filter tanggal',
                    style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child:
                entries.isEmpty
                    ? const EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'Tidak ada riwayat pada rentang ini',
                      body: 'Pilih rentang tanggal lain untuk melihat catatan perawatan.',
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      itemCount: entries.length,
                      itemBuilder: (_, i) {
                        final e = entries[i];
                        return AppCard(
                          accent: e.color,
                          padding: const EdgeInsets.all(13),
                          child: Row(
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${e.at.day}',
                                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, height: 1),
                                  ),
                                  Text(
                                    Fmt.dateShort(e.at).split(' ').last,
                                    style: const TextStyle(
                                      fontSize: 10.5,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 13),
                              Container(width: 1, height: 34, color: AppColors.cardBorder),
                              const SizedBox(width: 13),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(e.title, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800)),
                                    Text(e.subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                                  ],
                                ),
                              ),
                              Tag(e.status, color: e.color),
                            ],
                          ),
                        );
                      },
                    ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      helpText: 'Rentang riwayat maintenance',
      saveText: 'Terapkan',
      cancelText: 'Batal',
    );
    if (picked != null && mounted) setState(() => _range = picked);
  }
}

// ---------------------------------------------------------------------------
// NOTIFIKASI
// ---------------------------------------------------------------------------

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifs = MockDB().notificationsFor(MockDB().currentUser!.role);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
        bottom: BreadcrumbBar(text: '${notifs.where((n) => n.unread).length} belum dibaca dari ${notifs.length} pesan'),
      ),
      body:
          notifs.isEmpty
              ? const EmptyState(
                icon: Icons.notifications_off_rounded,
                title: 'Belum ada notifikasi',
                body: 'Pemberitahuan tugas, approval, dan breakdown akan tampil di sini.',
              )
              : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                itemCount: notifs.length,
                itemBuilder: (_, i) {
                  final n = notifs[i];
                  return AppCard(
                    padding: const EdgeInsets.all(13),
                    color: n.unread ? AppColors.primaryTint.withValues(alpha: 0.5) : Colors.white,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: n.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(n.icon, size: 20, color: n.color),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      n.title,
                                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, height: 1.3),
                                    ),
                                  ),
                                  if (n.unread)
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(color: AppColors.danger, shape: BoxShape.circle),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                n.subtitle,
                                style: const TextStyle(fontSize: 12.3, color: AppColors.textMuted, height: 1.4),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                Fmt.relative(n.at),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textFaint,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
    );
  }
}

// ---------------------------------------------------------------------------
// PROFIL
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _offlineMode = true;
  bool _pushAlert = true;

  @override
  Widget build(BuildContext context) {
    final user = MockDB().currentUser!;
    final myTasks = MockDB().tasksOf(user);
    final done = myTasks.where((w) => w.status == WOStatus.approved).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                InitialAvatar(user.initials, size: 68),
                gap12,
                Text(user.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                Text(
                  '${user.jobTitle} · NIK ${user.nik}',
                  style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted, fontWeight: FontWeight.w600),
                ),
                gap8,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.place_rounded, size: 15, color: AppColors.primary),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        user.station,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
                if (user.role == Role.technician) ...[
                  gap16,
                  Row(
                    children: [
                      StatTile(label: 'Tugas', value: '${myTasks.length}', color: AppColors.textPrimary),
                      const SizedBox(width: 8),
                      StatTile(label: 'Selesai', value: '$done', color: AppColors.primary),
                      const SizedBox(width: 8),
                      StatTile(
                        label: 'Overdue',
                        value: '${myTasks.where((w) => w.isOverdue).length}',
                        color: AppColors.danger,
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SectionTitle('Preferensi Lapangan', icon: Icons.tune_rounded),
          gap8,
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                SwitchListTile(
                  value: _offlineMode,
                  onChanged: (v) => setState(() => _offlineMode = v),
                  title: const Text('Mode offline lapangan'),
                  subtitle: const Text('Simpan hasil kerja di perangkat lalu sinkron saat sinyal mill kembali.'),
                  secondary: const Icon(Icons.cloud_off_rounded),
                  activeThumbColor: AppColors.primary,
                ),
                const Divider(height: 1),
                SwitchListTile(
                  value: _pushAlert,
                  onChanged: (v) => setState(() => _pushAlert = v),
                  title: const Text('Alarm breakdown darurat'),
                  subtitle: const Text('Getar dan bunyi penuh meski perangkat dalam mode senyap.'),
                  secondary: const Icon(Icons.notifications_active_rounded),
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SectionTitle('Akun & Sistem', icon: Icons.settings_rounded),
          gap8,
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.lock_reset_rounded),
                  title: const Text('Ubah PIN cepat 4 digit'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => showAppSnack(context, 'Form ubah PIN dibuka.', color: AppColors.primary),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.sync_rounded),
                  title: const Text('Status sinkronisasi'),
                  subtitle: Text('Terakhir sinkron ${Fmt.time(DateTime.now())} · server intranet mill'),
                  trailing: const Tag('AKTIF', color: AppColors.primary),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline_rounded),
                  title: const Text('Versi aplikasi'),
                  trailing: const Text(
                    '2.4.1',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: AppColors.danger),
                  title: const Text('Keluar', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w800)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.danger),
                  onTap: _confirmLogout,
                ),
              ],
            ),
          ),
          gap16,
          Center(
            child: Text(
              '${MockDB().companyName} · ${MockDB().millName}',
              style: const TextStyle(fontSize: 11, color: AppColors.textFaint, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Keluar dari PalmCare?'),
            content: const Text('Pekerjaan yang belum tersinkron akan tetap tersimpan di antrean offline perangkat.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger, minimumSize: const Size(110, 46)),
                child: const Text('Keluar'),
              ),
            ],
          ),
    );
    if (ok == true && mounted) {
      MockDB().currentUser = null;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }
}
