import 'package:flutter/material.dart';

import 'theme.dart';

// ---------------------------------------------------------------------------
// ENUM & MODEL
// ---------------------------------------------------------------------------

enum Role { technician, supervisor, management }

enum EquipStatus { operational, warning, critical, stopped }

enum WOStatus { assigned, inProgress, waitingVerification, approved, rejected, closed }

enum WOPriority { minor, medium, high, critical }

enum WOType { preventive, breakdown, inspection }

class AppUser {
  final String id;
  final String name;
  final String nik;
  final String jobTitle;
  final String station;
  final Role role;

  const AppUser({
    required this.id,
    required this.name,
    required this.nik,
    required this.jobTitle,
    required this.station,
    required this.role,
  });

  String get initials {
    final parts = name.replaceAll(RegExp(r'^(Ir\.|Drs\.)\s*'), '').trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 2).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get firstName => name.replaceAll(RegExp(r'^(Ir\.|Drs\.)\s*'), '').split(' ').first;
}

class Equipment {
  final String id;
  final String name;
  final String code;
  final String station;
  final String line;
  final String capacity;
  EquipStatus status;

  /// Pembacaan sensor lapangan terakhir.
  double temperature;
  double vibration;
  final double tempLimit;
  final double vibLimit;

  Equipment({
    required this.id,
    required this.name,
    required this.code,
    required this.station,
    required this.line,
    required this.capacity,
    required this.status,
    this.temperature = 0,
    this.vibration = 0,
    this.tempLimit = 90,
    this.vibLimit = 7.1,
  });
}

class ChecklistItem {
  final String id;
  final String category;
  final String taskName;
  final String description;

  /// Nilai terukur yang harus dicatat teknisi (mis. suhu bearing).
  final String? measureLabel;
  final String? measureUnit;
  final double? measureLimit;
  double? measuredValue;

  /// null = belum dijawab, true = AMAN, false = ADA TEMUAN.
  bool? isChecked;
  String? note;
  int photoCount;

  ChecklistItem({
    required this.id,
    required this.category,
    required this.taskName,
    required this.description,
    this.measureLabel,
    this.measureUnit,
    this.measureLimit,
    this.measuredValue,
    this.isChecked,
    this.note,
    this.photoCount = 0,
  });

  bool get overLimit => measuredValue != null && measureLimit != null && measuredValue! > measureLimit!;

  ChecklistItem copy() => ChecklistItem(
    id: id,
    category: category,
    taskName: taskName,
    description: description,
    measureLabel: measureLabel,
    measureUnit: measureUnit,
    measureLimit: measureLimit,
  );
}

class LubeSpec {
  final String grease;
  final String greadeNote;
  final String dose;
  final List<String> points;
  final List<String> tools;

  const LubeSpec({
    required this.grease,
    required this.greadeNote,
    required this.dose,
    required this.points,
    required this.tools,
  });
}

class EvidencePhoto {
  final String caption;
  final DateTime takenAt;
  final bool finding;
  final int seed;

  EvidencePhoto({required this.caption, required this.takenAt, this.finding = false, required this.seed});
}

class WorkOrder {
  final String id;
  final String code;
  final String title;
  final String description;
  final Equipment equipment;
  final WOType type;
  WOPriority priority;
  AppUser assignedTo;
  final AppUser? helper;
  final AppUser issuedBy;
  DateTime scheduledAt;
  final int estimatedMinutes;
  WOStatus status;
  List<ChecklistItem> checklist;
  final LubeSpec? lube;
  final List<String> ppe;
  final String? lotoNote;

  List<EvidencePhoto> evidence;
  String? technicianNote;
  String? rejectReason;
  DateTime? startedAt;
  DateTime? finishedAt;
  bool signed;

  WorkOrder({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.equipment,
    required this.type,
    required this.priority,
    required this.assignedTo,
    this.helper,
    required this.issuedBy,
    required this.scheduledAt,
    required this.estimatedMinutes,
    required this.status,
    required this.checklist,
    this.lube,
    this.ppe = const [],
    this.lotoNote,
    List<EvidencePhoto>? evidence,
    this.technicianNote,
    this.rejectReason,
    this.startedAt,
    this.finishedAt,
    this.signed = false,
  }) : evidence = evidence ?? [];

  int get answered => checklist.where((c) => c.isChecked != null).length;
  int get safeCount => checklist.where((c) => c.isChecked == true).length;
  int get findingCount => checklist.where((c) => c.isChecked == false).length;
  bool get allAnswered => checklist.isNotEmpty && answered == checklist.length;
  double get progress => checklist.isEmpty ? 0 : answered / checklist.length;

  /// Menit kerja aktual; sebelum selesai memakai jam berjalan.
  int get workedMinutes {
    if (startedAt == null) return 0;
    return (finishedAt ?? DateTime.now()).difference(startedAt!).inMinutes;
  }

  bool get isOpen => status == WOStatus.assigned || status == WOStatus.inProgress || status == WOStatus.rejected;

  bool get isOverdue => isOpen && scheduledAt.isBefore(DateTime.now());

  bool get isDueToday {
    final n = DateTime.now();
    return isOpen && scheduledAt.year == n.year && scheduledAt.month == n.month && scheduledAt.day == n.day;
  }

  int get lateMinutes => isOverdue ? DateTime.now().difference(scheduledAt).inMinutes : 0;
}

class Breakdown {
  final String id;
  final Equipment equipment;
  final String station;
  final String reportedBy;
  final String issueDescription;
  final List<String> symptoms;
  final WOPriority priority;
  WOStatus status;
  final DateTime reportedAt;
  String? handledBy;
  final int photoCount;

  Breakdown({
    required this.id,
    required this.equipment,
    required this.station,
    required this.reportedBy,
    required this.issueDescription,
    this.symptoms = const [],
    required this.priority,
    required this.status,
    required this.reportedAt,
    this.handledBy,
    this.photoCount = 0,
  });

  /// Target respons sesuai SLA pabrik.
  Duration get sla => switch (priority) {
    WOPriority.critical => const Duration(minutes: 15),
    WOPriority.high => const Duration(hours: 1),
    WOPriority.medium => const Duration(hours: 4),
    WOPriority.minor => const Duration(hours: 8),
  };
}

class AppNotification {
  final String title;
  final String subtitle;
  final DateTime at;
  final IconData icon;
  final Color color;
  final bool unread;

  const AppNotification({
    required this.title,
    required this.subtitle,
    required this.at,
    required this.icon,
    required this.color,
    this.unread = false,
  });
}

class HistoryEntry {
  final DateTime at;
  final String title;
  final String subtitle;
  final String status;
  final Color color;

  const HistoryEntry({
    required this.at,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.color,
  });
}

// ---------------------------------------------------------------------------
// FORMAT
// ---------------------------------------------------------------------------

class Fmt {
  static const _bulanPendek = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  static const _hari = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];

  static String date(DateTime d) => '${d.day} ${_bulanPendek[d.month - 1]} ${d.year}';

  static String dateShort(DateTime d) => '${d.day} ${_bulanPendek[d.month - 1]}';

  static String dayName(DateTime d) => _hari[d.weekday - 1];

  static String time(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';

  static String dateTime(DateTime d) => '${dateShort(d)}, ${time(d)}';

  static String minutes(int m) {
    if (m < 60) return '$m Menit';
    final h = m ~/ 60;
    final rest = m % 60;
    return rest == 0 ? '$h Jam' : '$h Jam $rest Menit';
  }

  static String relative(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lalu';
    if (diff.inHours < 24) return '${diff.inHours} jam lalu';
    if (diff.inDays == 1) return 'Kemarin';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return date(d);
  }

  static String greeting() {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat Pagi';
    if (h < 15) return 'Selamat Siang';
    if (h < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  static String shiftLabel() {
    final h = DateTime.now().hour;
    if (h >= 7 && h < 15) return 'Shift Pagi (07.00 - 15.00)';
    if (h >= 15 && h < 23) return 'Shift Sore (15.00 - 23.00)';
    return 'Shift Malam (23.00 - 07.00)';
  }
}

// ---------------------------------------------------------------------------
// LABEL & WARNA STATUS
// ---------------------------------------------------------------------------

class Labels {
  static String priority(WOPriority p) => switch (p) {
    WOPriority.minor => 'Minor',
    WOPriority.medium => 'Medium',
    WOPriority.high => 'Major',
    WOPriority.critical => 'Critical',
  };

  static Color priorityColor(WOPriority p) => switch (p) {
    WOPriority.minor => AppColors.primary,
    WOPriority.medium => AppColors.info,
    WOPriority.high => AppColors.amber,
    WOPriority.critical => AppColors.danger,
  };

  static String woStatus(WOStatus s) => switch (s) {
    WOStatus.assigned => 'Ditugaskan',
    WOStatus.inProgress => 'Dikerjakan',
    WOStatus.waitingVerification => 'Menunggu Verifikasi',
    WOStatus.approved => 'Disetujui',
    WOStatus.rejected => 'Dikembalikan',
    WOStatus.closed => 'Selesai',
  };

  static Color woStatusColor(WOStatus s) => switch (s) {
    WOStatus.assigned => AppColors.info,
    WOStatus.inProgress => AppColors.amber,
    WOStatus.waitingVerification => AppColors.amberInk,
    WOStatus.approved => AppColors.primary,
    WOStatus.rejected => AppColors.danger,
    WOStatus.closed => AppColors.textMuted,
  };

  static String woType(WOType t) => switch (t) {
    WOType.preventive => 'Preventive Routine',
    WOType.breakdown => 'Breakdown',
    WOType.inspection => 'Inspeksi',
  };

  static String equipStatus(EquipStatus s) => switch (s) {
    EquipStatus.operational => 'Operasional',
    EquipStatus.warning => 'Perlu Perhatian',
    EquipStatus.critical => 'Kritis',
    EquipStatus.stopped => 'Berhenti',
  };

  static Color equipColor(EquipStatus s) => switch (s) {
    EquipStatus.operational => AppColors.primary,
    EquipStatus.warning => AppColors.amber,
    EquipStatus.critical => AppColors.danger,
    EquipStatus.stopped => AppColors.neutral,
  };

  /// Warna urgensi work order: merah terlambat, amber hari ini, hijau terjadwal.
  static Color urgency(WorkOrder wo) {
    if (wo.status == WOStatus.approved || wo.status == WOStatus.closed) return AppColors.primary;
    if (wo.isOverdue) return AppColors.danger;
    if (wo.isDueToday) return AppColors.amber;
    return AppColors.primary;
  }

  static String urgencyLabel(WorkOrder wo) {
    if (wo.status == WOStatus.approved) return 'SELESAI';
    if (wo.status == WOStatus.waitingVerification) return 'DIVERIFIKASI';
    if (wo.status == WOStatus.rejected) return 'DIKEMBALIKAN';
    if (wo.isOverdue) return 'OVERDUE';
    if (wo.isDueToday) return 'DUE TODAY';
    return 'TERJADWAL';
  }
}

// ---------------------------------------------------------------------------
// DATA CONTOH
// ---------------------------------------------------------------------------

class MockDB {
  static final MockDB _instance = MockDB._internal();
  factory MockDB() => _instance;
  MockDB._internal();

  String get millName => 'PKS Sawit Prima Mandiri';
  String get companyName => 'PT Sawit Lestari Raya';

  AppUser? currentUser;

  static const stations = [
    'Stasiun Penerimaan TBS',
    'Stasiun Sterilizer',
    'Stasiun Thresher',
    'Stasiun Kempa (Press)',
    'Stasiun Klarifikasi',
    'Stasiun Nut & Kernel',
    'Stasiun Boiler & Utilitas',
  ];

  final List<AppUser> users = const [
    AppUser(
      id: 'T1',
      name: 'Budi Santoso',
      nik: '8412',
      jobTitle: 'Mekanik Senior — Teknisi 1',
      station: 'Stasiun Thresher & Kempa',
      role: Role.technician,
    ),
    AppUser(
      id: 'S1',
      name: 'Ir. Agus Setiawan',
      nik: '5120',
      jobTitle: 'Asisten Maintenance',
      station: 'Seluruh Lini Pabrik PKS',
      role: Role.supervisor,
    ),
    AppUser(
      id: 'M1',
      name: 'Citra Handayani',
      nik: '2077',
      jobTitle: 'Mill Manager',
      station: 'Dashboard Eksekutif & Audit OEE',
      role: Role.management,
    ),
  ];

  static const helper = AppUser(
    id: 'T2',
    name: 'Hendra Nugroho',
    nik: '8677',
    jobTitle: 'Mekanik Helper',
    station: 'Stasiun Kempa (Press)',
    role: Role.technician,
  );

  AppUser get technician => users[0];
  AppUser get supervisor => users[1];
  AppUser get manager => users[2];

  final List<Equipment> equipments = [
    Equipment(
      id: 'E1',
      name: 'Screw Press #02',
      code: 'EQ-PKS-PRS020',
      station: 'Stasiun Kempa (Press)',
      line: 'Line B · Bay #3',
      capacity: '30 Ton TBS / Jam',
      status: EquipStatus.warning,
      temperature: 58.4,
      vibration: 4.8,
      tempLimit: 65,
      vibLimit: 4.5,
    ),
    Equipment(
      id: 'E2',
      name: 'Screw Press #01',
      code: 'EQ-PKS-PRS010',
      station: 'Stasiun Kempa (Press)',
      line: 'Line A · Bay #1',
      capacity: '30 Ton TBS / Jam',
      status: EquipStatus.operational,
      temperature: 52.1,
      vibration: 2.6,
      tempLimit: 65,
      vibLimit: 4.5,
    ),
    Equipment(
      id: 'E3',
      name: 'Digester #01',
      code: 'EQ-PKS-DG010',
      station: 'Stasiun Kempa (Press)',
      line: 'Line A · Bay #2',
      capacity: '3.200 Liter',
      status: EquipStatus.operational,
      temperature: 91.5,
      vibration: 3.1,
      tempLimit: 100,
      vibLimit: 4.5,
    ),
    Equipment(
      id: 'E4',
      name: 'Sterilizer #01',
      code: 'EQ-PKS-STR010',
      station: 'Stasiun Sterilizer',
      line: 'Vessel 1',
      capacity: '10 Lori / Siklus',
      status: EquipStatus.operational,
      temperature: 132,
      vibration: 0.8,
      tempLimit: 145,
      vibLimit: 3,
    ),
    Equipment(
      id: 'E5',
      name: 'Depericarper Fan',
      code: 'EQ-PKS-DPF010',
      station: 'Stasiun Nut & Kernel',
      line: 'Nut Plant',
      capacity: '18.000 m³/Jam',
      status: EquipStatus.operational,
      temperature: 44.2,
      vibration: 3.4,
      tempLimit: 70,
      vibLimit: 5,
    ),
    Equipment(
      id: 'E6',
      name: 'Boiler #01',
      code: 'EQ-PKS-BLR010',
      station: 'Stasiun Boiler & Utilitas',
      line: 'Unit Uap Utama',
      capacity: '20 Ton Uap / Jam',
      status: EquipStatus.critical,
      temperature: 318,
      vibration: 2.2,
      tempLimit: 300,
      vibLimit: 4,
    ),
    Equipment(
      id: 'E7',
      name: 'Thresher Drum #01',
      code: 'EQ-PKS-THR010',
      station: 'Stasiun Thresher',
      line: 'Line A',
      capacity: '30 Ton TBS / Jam',
      status: EquipStatus.operational,
      temperature: 48.6,
      vibration: 3.9,
      tempLimit: 70,
      vibLimit: 5,
    ),
  ];

  List<WorkOrder> workOrders = [];
  List<Breakdown> breakdowns = [];
  final List<AppNotification> extraNotifications = [];

  Equipment equipmentById(String id) => equipments.firstWhere((e) => e.id == id);

  void initMockData() {
    if (workOrders.isNotEmpty) return;
    final now = DateTime.now();
    DateTime at(int addDays, int hour, int minute) => DateTime(now.year, now.month, now.day + addDays, hour, minute);

    workOrders.addAll([
      WorkOrder(
        id: 'WO-2026-1082',
        code: 'PM-MEC-04',
        title: 'Inspeksi & Pelumasan Bearing Screw Press #02',
        description:
            'Pencegahan overheat dan penggantian grease berkala bearing utama jalur pengepresan kelapa sawit Line B.',
        equipment: equipments[0],
        type: WOType.preventive,
        priority: WOPriority.critical,
        assignedTo: users[0],
        helper: helper,
        issuedBy: users[1],
        scheduledAt: at(0, 9, 0),
        estimatedMinutes: 30,
        status: WOStatus.assigned,
        checklist: _pressChecklist(),
        lube: const LubeSpec(
          grease: 'Shell Gadus S2 V220 2',
          greadeNote: 'Extreme Pressure Lithium EP',
          dose: '150 Gram / Housing',
          points: [
            'Front Bearing — Tekanan Pompa',
            'Rear Bearing — Casing Ujung',
            'Drive Shaft — Gearbox Coupling',
            'Thrust Bearing — Penyerap Beban',
          ],
          tools: ['Grease Gun Manual Hi-Press', 'Kunci Ring 24mm', 'Kain Majun Pembersih'],
        ),
        ppe: ['Helm Safety PKS', 'Kacamata Bening', 'Sarung Tangan Heavy-Duty', 'Sepatu Anti Minyak'],
        lotoNote:
            'WAJIB terapkan prosedur LOTO (Lock Out Tag Out) pada Panel MCC Ruang Kontrol sebelum melepas baut penutup pelindung kopling screw press.',
      ),
      WorkOrder(
        id: 'WO-2026-1085',
        code: 'PM-MEC-11',
        title: 'Cek Getaran & Suhu Motor Digester #01',
        description:
            'Pemantauan kondisi motor penggerak digester untuk mencegah kegagalan bearing saat jam giling puncak.',
        equipment: equipments[2],
        type: WOType.inspection,
        priority: WOPriority.high,
        assignedTo: users[0],
        issuedBy: users[1],
        scheduledAt: at(0, 11, 30),
        estimatedMinutes: 20,
        status: WOStatus.assigned,
        checklist: _digesterChecklist(),
        ppe: ['Helm Safety PKS', 'Ear Plug', 'Sepatu Anti Minyak'],
        lotoNote: 'Pengukuran dilakukan saat mesin berjalan. Jaga jarak aman dari kopling berputar.',
      ),
      WorkOrder(
        id: 'WO-2026-1089',
        code: 'PM-MEC-22',
        title: 'Pembersihan Saringan Depericarper Fan',
        description:
            'Pembersihan serat dan cangkang yang menyumbat saringan agar efisiensi pemisahan nut tetap terjaga.',
        equipment: equipments[4],
        type: WOType.preventive,
        priority: WOPriority.medium,
        assignedTo: users[0],
        helper: helper,
        issuedBy: users[1],
        scheduledAt: at(0, 14, 0),
        estimatedMinutes: 40,
        status: WOStatus.assigned,
        checklist: _fanChecklist(),
        ppe: ['Helm Safety PKS', 'Masker Debu', 'Sarung Tangan Heavy-Duty'],
        lotoNote: 'Matikan panel fan dan pasang tag LOTO sebelum membuka housing saringan.',
      ),
      WorkOrder(
        id: 'WO-2026-1078',
        code: 'PM-MEC-08',
        title: 'Inspeksi Katup Uap Sterilizer #01',
        description: 'Pemeriksaan kebocoran uap dan kalibrasi katup pengaman vessel sterilizer.',
        equipment: equipments[3],
        type: WOType.inspection,
        priority: WOPriority.medium,
        assignedTo: users[0],
        issuedBy: users[1],
        scheduledAt: at(-1, 8, 0),
        estimatedMinutes: 45,
        status: WOStatus.waitingVerification,
        checklist: _sterilizerChecklist(answered: true),
        technicianNote: 'Seal katup pengaman mulai getas, direkomendasikan penggantian pada shutdown berikutnya.',
        evidence: [
          EvidencePhoto(caption: 'Kondisi katup pengaman vessel', takenAt: at(-1, 8, 32), seed: 3),
          EvidencePhoto(caption: 'Seal getas pada dudukan katup', takenAt: at(-1, 8, 41), finding: true, seed: 1),
        ],
        startedAt: at(-1, 8, 5),
        finishedAt: at(-1, 8, 48),
        signed: true,
        ppe: ['Helm Safety PKS', 'Sarung Tangan Tahan Panas'],
      ),
      WorkOrder(
        id: 'WO-2026-1074',
        code: 'PM-MEC-03',
        title: 'Pelumasan Bearing Thresher Drum #01',
        description: 'Pelumasan berkala bearing drum penebah dan pengecekan kekencangan rantai.',
        equipment: equipments[6],
        type: WOType.preventive,
        priority: WOPriority.minor,
        assignedTo: users[0],
        issuedBy: users[1],
        scheduledAt: at(-3, 10, 0),
        estimatedMinutes: 35,
        status: WOStatus.approved,
        checklist: _sterilizerChecklist(answered: true),
        evidence: [EvidencePhoto(caption: 'Bearing drum setelah grease', takenAt: at(-3, 10, 25), seed: 0)],
        startedAt: at(-3, 10, 2),
        finishedAt: at(-3, 10, 33),
        signed: true,
      ),
      WorkOrder(
        id: 'WO-2026-1092',
        code: 'PM-MEC-15',
        title: 'Kalibrasi Sensor Tekanan Boiler #01',
        description: 'Kalibrasi transmitter tekanan drum uap dan verifikasi alarm high-pressure.',
        equipment: equipments[5],
        type: WOType.preventive,
        priority: WOPriority.high,
        assignedTo: users[0],
        issuedBy: users[1],
        scheduledAt: at(2, 8, 30),
        estimatedMinutes: 60,
        status: WOStatus.assigned,
        checklist: _sterilizerChecklist(),
        ppe: ['Helm Safety PKS', 'Sarung Tangan Tahan Panas', 'Ear Plug'],
        lotoNote: 'Koordinasi dengan operator boiler sebelum isolasi transmitter.',
      ),
      WorkOrder(
        id: 'WO-2026-1094',
        code: 'PM-MEC-07',
        title: 'Penggantian Belt Conveyor Nut Plant',
        description: 'Penggantian belt yang mulai retak pada conveyor pengumpan nut cracker.',
        equipment: equipments[4],
        type: WOType.preventive,
        priority: WOPriority.medium,
        assignedTo: users[0],
        issuedBy: users[1],
        scheduledAt: at(4, 13, 0),
        estimatedMinutes: 90,
        status: WOStatus.assigned,
        checklist: _fanChecklist(),
        ppe: ['Helm Safety PKS', 'Sarung Tangan Heavy-Duty'],
      ),
    ]);

    breakdowns.addAll([
      Breakdown(
        id: 'BR-2026-041',
        equipment: equipments[5],
        station: 'Stasiun Boiler & Utilitas',
        reportedBy: 'Budi Santoso (Teknisi 1)',
        issueDescription:
            'Alarm suhu tinggi pada drum uap, tekanan drop mendadak dan burner trip berulang dalam 20 menit terakhir.',
        symptoms: ['Motor Terbakar / Bau Asap', 'Vibrasi Ekstrem'],
        priority: WOPriority.critical,
        status: WOStatus.assigned,
        reportedAt: now.subtract(const Duration(minutes: 38)),
        photoCount: 2,
      ),
      Breakdown(
        id: 'BR-2026-040',
        equipment: equipments[0],
        station: 'Stasiun Kempa (Press)',
        reportedBy: 'Hendra Nugroho (Mekanik Helper)',
        issueDescription: 'Rembesan oli gearbox terlihat menetes di lantai kerja sekitar poros output reducer.',
        symptoms: ['Kebocoran Oli Panas'],
        priority: WOPriority.high,
        status: WOStatus.inProgress,
        reportedAt: now.subtract(const Duration(hours: 6)),
        handledBy: 'Budi Santoso',
        photoCount: 1,
      ),
      Breakdown(
        id: 'BR-2026-038',
        equipment: equipments[6],
        station: 'Stasiun Thresher',
        reportedBy: 'Budi Santoso (Teknisi 1)',
        issueDescription: 'Rantai konveyor penebah kendur sehingga TBS tersangkut pada ujung drum.',
        symptoms: ['Rantai Konveyor Putus'],
        priority: WOPriority.medium,
        status: WOStatus.closed,
        reportedAt: now.subtract(const Duration(days: 2, hours: 3)),
        handledBy: 'Hendra Nugroho',
      ),
    ]);
  }

  // --- Ringkasan untuk dashboard -------------------------------------------

  List<WorkOrder> tasksOf(AppUser u) => workOrders.where((w) => w.assignedTo.id == u.id).toList();

  int get pendingVerification => workOrders.where((w) => w.status == WOStatus.waitingVerification).length;

  int get openBreakdowns => breakdowns.where((b) => b.status != WOStatus.closed).length;

  /// Kepatuhan preventive maintenance: WO preventif selesai tepat waktu.
  double get pmCompliance {
    final pm = workOrders.where((w) => w.type != WOType.breakdown).toList();
    if (pm.isEmpty) return 0;
    final done = pm.where((w) => w.status == WOStatus.approved || w.status == WOStatus.waitingVerification).length;
    // Basis historis 112 WO bulan berjalan supaya angka tetap masuk akal.
    return ((done + 104) / (pm.length + 112)) * 100;
  }

  double get equipmentHealth {
    if (equipments.isEmpty) return 0;
    final score = equipments.fold<double>(0, (a, e) {
      return a +
          switch (e.status) {
            EquipStatus.operational => 100,
            EquipStatus.warning => 74,
            EquipStatus.critical => 38,
            EquipStatus.stopped => 0,
          };
    });
    return score / equipments.length;
  }

  List<AppNotification> notificationsFor(Role role) {
    final list = <AppNotification>[...extraNotifications];

    if (role == Role.technician) {
      for (final wo in tasksOf(technician)) {
        if (wo.status == WOStatus.rejected) {
          list.add(
            AppNotification(
              title: 'Pekerjaan dikembalikan supervisor',
              subtitle: '${wo.id} · ${wo.rejectReason ?? "Perlu perbaikan"}',
              at: DateTime.now().subtract(const Duration(minutes: 12)),
              icon: Icons.undo_rounded,
              color: AppColors.danger,
              unread: true,
            ),
          );
        } else if (wo.status == WOStatus.approved) {
          list.add(
            AppNotification(
              title: 'Hasil kerja disetujui',
              subtitle: '${wo.id} · ${wo.equipment.name}',
              at: wo.finishedAt ?? DateTime.now(),
              icon: Icons.verified_rounded,
              color: AppColors.primary,
            ),
          );
        } else if (wo.isOverdue) {
          list.add(
            AppNotification(
              title: 'Tugas melewati batas waktu',
              subtitle: '${wo.id} · terlambat ${Fmt.minutes(wo.lateMinutes)}',
              at: wo.scheduledAt,
              icon: Icons.alarm_rounded,
              color: AppColors.danger,
              unread: true,
            ),
          );
        }
      }
    } else if (role == Role.supervisor) {
      for (final wo in workOrders.where((w) => w.status == WOStatus.waitingVerification)) {
        list.add(
          AppNotification(
            title: 'Hasil inspeksi menunggu approval',
            subtitle: '${wo.assignedTo.firstName} · ${wo.equipment.name}',
            at: wo.finishedAt ?? DateTime.now(),
            icon: Icons.fact_check_rounded,
            color: AppColors.amberInk,
            unread: true,
          ),
        );
      }
    }

    for (final b in breakdowns.where((b) => b.status != WOStatus.closed)) {
      list.add(
        AppNotification(
          title: 'Breakdown ${Labels.priority(b.priority).toUpperCase()} dilaporkan',
          subtitle: '${b.equipment.name} · ${b.station}',
          at: b.reportedAt,
          icon: Icons.crisis_alert_rounded,
          color: Labels.priorityColor(b.priority),
          unread: b.status == WOStatus.assigned,
        ),
      );
    }

    list.sort((a, b) => b.at.compareTo(a.at));
    return list;
  }

  List<HistoryEntry> get history {
    final entries = <HistoryEntry>[];
    for (final wo in workOrders.where((w) => w.status == WOStatus.approved || w.status == WOStatus.closed)) {
      entries.add(
        HistoryEntry(
          at: wo.finishedAt ?? wo.scheduledAt,
          title: '${wo.equipment.name} · ${wo.id}',
          subtitle: Labels.woType(wo.type),
          status: 'Disetujui',
          color: AppColors.primary,
        ),
      );
    }
    for (final b in breakdowns.where((b) => b.status == WOStatus.closed)) {
      entries.add(
        HistoryEntry(
          at: b.reportedAt,
          title: '${b.equipment.name} · ${b.id}',
          subtitle: 'Breakdown ${Labels.priority(b.priority)}',
          status: 'Ditutup',
          color: AppColors.textMuted,
        ),
      );
    }
    // Riwayat arsip agar layar tidak kosong pada demo.
    final now = DateTime.now();
    entries.addAll([
      HistoryEntry(
        at: now.subtract(const Duration(days: 16)),
        title: 'Screw Press #01 · WO-2026-1041',
        subtitle: 'Preventive Routine',
        status: 'Disetujui',
        color: AppColors.primary,
      ),
      HistoryEntry(
        at: now.subtract(const Duration(days: 23)),
        title: 'Boiler #01 · WO-2026-1020',
        subtitle: 'Inspeksi',
        status: 'Disetujui',
        color: AppColors.primary,
      ),
      HistoryEntry(
        at: now.subtract(const Duration(days: 37)),
        title: 'Sterilizer #01 · BR-2026-029',
        subtitle: 'Breakdown Major',
        status: 'Ditutup',
        color: AppColors.textMuted,
      ),
    ]);
    entries.sort((a, b) => b.at.compareTo(a.at));
    return entries;
  }

  // --- Checklist ------------------------------------------------------------

  List<ChecklistItem> _pressChecklist() => [
    ChecklistItem(
      id: 'P1',
      category: 'PERSIAPAN',
      taskName: 'Pembersihan Nipple Grease & Housing Bearing',
      description: 'Bersihkan sisa lumpur dan minyak sawit kering sebelum injeksi gemuk baru.',
    ),
    ChecklistItem(
      id: 'P2',
      category: 'PENGUKURAN',
      taskName: 'Suhu Housing Bearing Sebelum Pelumasan',
      description: 'Cek dengan infrared thermometer sebelum grease diinjeksi.',
      measureLabel: 'Suhu terukur',
      measureUnit: '°C',
      measureLimit: 65,
    ),
    ChecklistItem(
      id: 'P3',
      category: 'PELUMASAN',
      taskName: 'Injeksi Grease Shell Gadus S2 (150 gr)',
      description: 'Pompa gemuk pelumas merata ke 4 titik bearing sampai gemuk baru keluar tipis.',
    ),
    ChecklistItem(
      id: 'P4',
      category: 'PEMERIKSAAN',
      taskName: 'Cek Kebocoran Oil Seal Reducer Gearbox',
      description: 'Periksa apakah ada rembesan oli di seal poros input dan output gearbox.',
    ),
    ChecklistItem(
      id: 'P5',
      category: 'PENUTUP',
      taskName: 'Pemasangan Kembali Guard Safety Cover',
      description: 'Pastikan semua baut pengaman kencang dan penutup terpasang kokoh sebelum daya diaktifkan.',
    ),
  ];

  List<ChecklistItem> _digesterChecklist() => [
    ChecklistItem(
      id: 'D1',
      category: 'PENGUKURAN',
      taskName: 'Ukur Vibrasi Motor Penggerak',
      description: 'Tempelkan vibration pen pada rumah bearing sisi kopling.',
      measureLabel: 'Vibrasi terukur',
      measureUnit: 'mm/s',
      measureLimit: 4.5,
    ),
    ChecklistItem(
      id: 'D2',
      category: 'PENGUKURAN',
      taskName: 'Suhu Bearing Motor Digester',
      description: 'Pengukuran non-kontak pada dua sisi bearing motor.',
      measureLabel: 'Suhu terukur',
      measureUnit: '°C',
      measureLimit: 70,
    ),
    ChecklistItem(
      id: 'D3',
      category: 'PEMERIKSAAN',
      taskName: 'Kekencangan Baut Pondasi & Kopling',
      description: 'Periksa baut pondasi motor dan elemen kopling dari keretakan.',
    ),
    ChecklistItem(
      id: 'D4',
      category: 'PEMERIKSAAN',
      taskName: 'Kebisingan Abnormal Gearbox Digester',
      description: 'Dengarkan suara dengung atau benturan logam saat beban penuh.',
    ),
  ];

  List<ChecklistItem> _fanChecklist() => [
    ChecklistItem(
      id: 'F1',
      category: 'KESELAMATAN',
      taskName: 'Isolasi Panel & Pasang Tag LOTO',
      description: 'Matikan MCB fan, pasang gembok dan tag atas nama teknisi pelaksana.',
    ),
    ChecklistItem(
      id: 'F2',
      category: 'PEMBERSIHAN',
      taskName: 'Bersihkan Saringan dari Serat & Cangkang',
      description: 'Sikat dan semprot saringan hingga aliran udara tidak tertahan.',
    ),
    ChecklistItem(
      id: 'F3',
      category: 'PEMERIKSAAN',
      taskName: 'Cek Keausan & Balance Impeller',
      description: 'Periksa sudu dari aus tidak merata dan retak pada pangkal.',
    ),
    ChecklistItem(
      id: 'F4',
      category: 'PEMERIKSAAN',
      taskName: 'Ketegangan Belt & Kondisi Pulley',
      description: 'Ukur defleksi belt dan periksa alur pulley dari aus.',
    ),
  ];

  List<ChecklistItem> _sterilizerChecklist({bool answered = false}) {
    final items = [
      ChecklistItem(
        id: 'S1',
        category: 'PEMERIKSAAN',
        taskName: 'Cek Kebocoran Uap pada Sambungan Pipa',
        description: 'Telusuri sambungan flange dan packing pintu vessel.',
      ),
      ChecklistItem(
        id: 'S2',
        category: 'PENGUKURAN',
        taskName: 'Verifikasi Tekanan Kerja Vessel',
        description: 'Bandingkan gauge lapangan dengan pembacaan ruang kontrol.',
        measureLabel: 'Tekanan terukur',
        measureUnit: 'bar',
        measureLimit: 3.2,
      ),
      ChecklistItem(
        id: 'S3',
        category: 'PEMERIKSAAN',
        taskName: 'Kondisi Katup Pengaman (Safety Valve)',
        description: 'Periksa seal dan uji angkat manual sesuai SOP.',
      ),
      ChecklistItem(
        id: 'S4',
        category: 'PENUTUP',
        taskName: 'Rapikan Area & Lepas Tag LOTO',
        description: 'Pastikan area bersih dan seluruh gembok dilepas oleh pemasang.',
      ),
    ];
    if (answered) {
      for (final i in items) {
        i.isChecked = true;
      }
      items[2].isChecked = false;
      items[2].note = 'Seal katup pengaman getas, rekomendasi ganti saat shutdown berikutnya.';
      items[2].photoCount = 1;
      items[1].measuredValue = 2.9;
    }
    return items;
  }
}
