import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Design token hasil style guide Stitch "PalmCare CMMS Mobile".
/// Primary #1B8354 · Secondary #2EAA68 · Tertiary #F59E0B · Neutral #0F172A.
class AppColors {
  static const primary = Color(0xFF1B8354);
  static const primaryDark = Color(0xFF145F3E);
  static const primaryDeep = Color(0xFF0B4630);
  static const secondary = Color(0xFF2EAA68);
  static const primaryTint = Color(0xFFE6F3EC);
  static const primaryTintStrong = Color(0xFFCFE7DA);

  // Amber Stitch dipakai untuk fill/ikon. Untuk teks di atas tint dipakai
  // turunan gelapnya supaya kontras lolos WCAG AA (pengguna lapangan 40-50+).
  static const amber = Color(0xFFF59E0B);
  static const amberInk = Color(0xFF945707);
  static const amberTint = Color(0xFFFEF4E3);

  static const danger = Color(0xFFC0362B);
  static const dangerInk = Color(0xFF981A11);
  static const dangerTint = Color(0xFFFDEDEB);

  static const info = Color(0xFF1B6FA8);
  static const infoTint = Color(0xFFE8F2F9);

  static const neutral = Color(0xFF0F172A);
  static const textPrimary = Color(0xFF13211C);
  static const textMuted = Color(0xFF5C6B65);
  static const textFaint = Color(0xFF8B9A94);
  static const screenBg = Color(0xFFF3F6F4);
  static const cardBorder = Color(0xFFE1E8E4);

  // Alias status supaya pemakaian di layar tetap terbaca semantik.
  static const statusGreen = primary;
  static const statusOrange = amber;
  static const statusRed = danger;
}

class AppRadius {
  static const card = 18.0;
  static const inner = 12.0;
  static const pill = 999.0;
}

/// Jarak vertikal standar antar blok konten.
const gap4 = SizedBox(height: 4);
const gap8 = SizedBox(height: 8);
const gap12 = SizedBox(height: 12);
const gap16 = SizedBox(height: 16);
const gap24 = SizedBox(height: 24);

/// Snackbar seragam: ikon + warna semantik, mengambang di atas bottom nav.
void showAppSnack(
  BuildContext context,
  String message, {
  Color color = AppColors.neutral,
  IconData icon = Icons.info_outline_rounded,
}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: color,
      duration: const Duration(seconds: 3),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
      content: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, height: 1.35)),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// KOMPONEN DASAR
// ---------------------------------------------------------------------------

/// Chip kecil berisi label status / meta. Pola dominan di seluruh mockup Stitch.
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final Color? background;
  final IconData? icon;
  final bool filled;
  final double fontSize;

  const Tag(
    this.text, {
    super.key,
    this.color = AppColors.primary,
    this.background,
    this.icon,
    this.filled = false,
    this.fontSize = 11.5,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filled ? color : (background ?? color.withValues(alpha: 0.10));
    final fg = filled ? Colors.white : color;
    final label = Text(
      text,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w800, color: fg, letterSpacing: 0.2),
    );

    return Container(
      padding: EdgeInsets.symmetric(horizontal: icon == null ? 9 : 8, vertical: 4.5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7)),
      // Chip selalu selebar isinya: dipakai di dalam Row dan daftar horizontal
      // yang lebarnya tak terbatas, sehingga anak ber-flex tidak boleh dipakai.
      // Teks panjang dipecah jadi beberapa chip di sisi pemanggil.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: fontSize + 2.5, color: fg), const SizedBox(width: 4)],
          label,
        ],
      ),
    );
  }
}

/// Judul seksi: ikon + label tebal, opsional aksi/hitungan di kanan.
class SectionTitle extends StatelessWidget {
  final String text;
  final IconData? icon;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final Color color;

  const SectionTitle(
    this.text, {
    super.key,
    this.icon,
    this.trailingText,
    this.onTrailingTap,
    this.color = AppColors.textPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 18, color: AppColors.primary), const SizedBox(width: 7)],
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.1),
          ),
        ),
        if (trailingText != null)
          InkWell(
            onTap: onTrailingTap,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: Text(
                trailingText!,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: onTrailingTap == null ? AppColors.textMuted : AppColors.primary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Kartu putih standar. `accent` menambah bar warna di tepi kiri (pola
/// status-at-a-glance dari mockup daftar work order).
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? accent;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.accent,
    this.color = Colors.white,
    this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final body = Padding(padding: padding, child: child);
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
        boxShadow: [
          BoxShadow(color: AppColors.neutral.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child:
              accent == null
                  ? body
                  : IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [Container(width: 5, color: accent), Expanded(child: body)],
                    ),
                  ),
        ),
      ),
    );
  }
}

/// Baris meta kecil: ikon + teks abu, dipakai untuk stasiun / jadwal / SLA.
class MetaRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final FontWeight weight;

  const MetaRow(this.icon, this.text, {super.key, this.color, this.weight = FontWeight.w500});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(top: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(fontSize: 12.5, color: c, fontWeight: weight, height: 1.35))),
        ],
      ),
    );
  }
}

/// Kotak angka ringkasan. Bisa ditekan supaya dashboard benar-benar interaktif.
class StatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? caption;
  final Color color;
  final bool selected;
  final VoidCallback? onTap;

  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.caption,
    required this.color,
    this.selected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: onTap != null,
        selected: selected,
        label: '$label $value ${caption ?? ''}',
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.inner),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? color.withValues(alpha: 0.10) : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.inner),
              border: Border.all(color: selected ? color : AppColors.cardBorder, width: selected ? 1.8 : 1),
            ),
            child: Column(
              children: [
                Text(
                  label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textFaint,
                    letterSpacing: 0.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 3),
                Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color, height: 1.1)),
                if (caption != null)
                  Text(
                    caption!,
                    style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    textAlign: TextAlign.center,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Deretan pill filter. `scrollable` untuk opsi yang panjang.
class PillTabs extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelected;
  final bool scrollable;
  final EdgeInsetsGeometry padding;

  const PillTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.scrollable = true,
    this.padding = EdgeInsets.zero,
  });

  Widget _pill(String o) {
    final isSelected = o == selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isSelected ? AppColors.primary : AppColors.cardBorder),
      ),
      alignment: Alignment.center,
      child: Text(
        o,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isSelected ? Colors.white : AppColors.textMuted,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!scrollable) {
      return Padding(
        padding: padding,
        child: Row(
          children: [
            for (final o in options) ...[
              Expanded(child: GestureDetector(onTap: () => onSelected(o), child: _pill(o))),
              if (o != options.last) const SizedBox(width: 8),
            ],
          ],
        ),
      );
    }
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: padding,
        itemCount: options.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => GestureDetector(onTap: () => onSelected(options[i]), child: _pill(options[i])),
      ),
    );
  }
}

/// Chip pilihan multi-select (gejala kerusakan, APD, dsb).
class ChoiceChipTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;
  final IconData? icon;

  const ChoiceChipTile({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = AppColors.primary,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? color : AppColors.cardBorder, width: selected ? 1.6 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              selected ? Icons.check_rounded : (icon ?? Icons.add_rounded),
              size: 15,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner informasi / peringatan dengan ikon dan warna semantik.
class NoticeBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? body;
  final Color color;
  final Color? background;
  final Widget? action;

  const NoticeBox({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    required this.color,
    this.background,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.inner),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: color, height: 1.3)),
                if (body != null) ...[
                  const SizedBox(height: 3),
                  Text(body!, style: TextStyle(fontSize: 12.5, color: color.withValues(alpha: 0.92), height: 1.42)),
                ],
                if (action != null) ...[const SizedBox(height: 8), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatar inisial.
class InitialAvatar extends StatelessWidget {
  final String initials;
  final Color color;
  final double size;

  const InitialAvatar(this.initials, {super.key, this.color = AppColors.primary, this.size = 38});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials, style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
    );
  }
}

// ---------------------------------------------------------------------------
// FOTO SIMULASI
// ---------------------------------------------------------------------------

/// Placeholder foto lapangan. Tanpa kamera/aset nyata, tetap ditampilkan
/// sebagai bingkai berstempel waktu supaya alur bukti foto terbaca jujur.
class PhotoThumb extends StatelessWidget {
  final int seed;
  final String? stamp;
  final double width;
  final double height;
  final bool flagged;
  final VoidCallback? onTap;

  const PhotoThumb({
    super.key,
    required this.seed,
    this.stamp,
    this.width = 64,
    this.height = 64,
    this.flagged = false,
    this.onTap,
  });

  static const _palettes = [
    [Color(0xFF3F5B4C), Color(0xFF16261E)],
    [Color(0xFF4A4438), Color(0xFF221E17)],
    [Color(0xFF39505C), Color(0xFF17232A)],
    [Color(0xFF5A4A36), Color(0xFF26201A)],
  ];

  @override
  Widget build(BuildContext context) {
    final p = _palettes[seed % _palettes.length];
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(colors: p, begin: Alignment.topLeft, end: Alignment.bottomRight),
          border: Border.all(color: flagged ? AppColors.danger : Colors.transparent, width: 1.6),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CustomPaint(painter: _MachineSketch(seed)),
            Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(Icons.photo_camera_rounded, size: 13, color: Colors.white.withValues(alpha: 0.75)),
              ),
            ),
            if (stamp != null)
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  color: Colors.black.withValues(alpha: 0.55),
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 3),
                  child: Text(
                    stamp!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _MachineSketch extends CustomPainter {
  final int seed;
  _MachineSketch(this.seed);

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(seed * 7919);
    final paint =
        Paint()
          ..color = Colors.white.withValues(alpha: 0.10)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (0.2 + rnd.nextDouble() * 0.7);
      canvas.drawLine(Offset(0, y), Offset(size.width, y - rnd.nextDouble() * 8), paint);
    }
    canvas.drawCircle(
      Offset(size.width * 0.68, size.height * 0.36),
      size.width * 0.16,
      paint..color = Colors.white.withValues(alpha: 0.14),
    );
  }

  @override
  bool shouldRepaint(covariant _MachineSketch oldDelegate) => oldDelegate.seed != seed;
}

// ---------------------------------------------------------------------------
// TANDA TANGAN
// ---------------------------------------------------------------------------

/// Papan tanda tangan sungguhan: goresan jari direkam dan bisa dihapus.
class SignaturePad extends StatefulWidget {
  final ValueChanged<bool> onChanged;
  final double height;

  const SignaturePad({super.key, required this.onChanged, this.height = 128});

  @override
  State<SignaturePad> createState() => _SignaturePadState();
}

class _SignaturePadState extends State<SignaturePad> {
  final List<List<Offset>> _strokes = [];

  bool get _hasInk => _strokes.any((s) => s.length > 1);

  void _notify() => widget.onChanged(_hasInk);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppColors.screenBg,
            borderRadius: BorderRadius.circular(AppRadius.inner),
            border: Border.all(color: _hasInk ? AppColors.primary : AppColors.cardBorder, width: _hasInk ? 1.6 : 1),
          ),
          clipBehavior: Clip.antiAlias,
          child: GestureDetector(
            onPanStart: (d) => setState(() => _strokes.add([d.localPosition])),
            onPanUpdate:
                (d) => setState(() {
                  if (_strokes.isEmpty) _strokes.add([]);
                  _strokes.last.add(d.localPosition);
                }),
            onPanEnd: (_) => _notify(),
            child: CustomPaint(
              painter: _SignaturePainter(_strokes),
              child: Center(
                child:
                    _hasInk
                        ? null
                        : const Text(
                          'Tanda tangan di sini',
                          style: TextStyle(color: AppColors.textFaint, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
              ),
            ),
          ),
        ),
        if (_hasInk)
          TextButton.icon(
            onPressed: () {
              setState(_strokes.clear);
              _notify();
            },
            icon: const Icon(Icons.refresh_rounded, size: 17),
            label: const Text('Ulangi tanda tangan'),
            style: TextButton.styleFrom(foregroundColor: AppColors.textMuted, minimumSize: const Size(0, 40)),
          ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  _SignaturePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = AppColors.neutral
          ..strokeWidth = 2.6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke;
    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (final p in stroke.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// KALENDER BULANAN
// ---------------------------------------------------------------------------

const _bulanId = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Kalender bulanan interaktif dengan penanda jadwal per hari.
/// Dibuat sendiri (bukan paket) supaya penandanya bisa ikut warna prioritas
/// work order dan tetap nol dependensi tambahan.
class MonthCalendar extends StatefulWidget {
  final DateTime selectedDay;
  final ValueChanged<DateTime> onDaySelected;

  /// Warna penanda untuk satu hari (maksimal 3 titik ditampilkan).
  final List<Color> Function(DateTime day) markersFor;

  const MonthCalendar({super.key, required this.selectedDay, required this.onDaySelected, required this.markersFor});

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month = DateTime(widget.selectedDay.year, widget.selectedDay.month);

  @override
  void didUpdateWidget(covariant MonthCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final sel = widget.selectedDay;
    if (sel.year != _month.year || sel.month != _month.month) {
      _month = DateTime(sel.year, sel.month);
    }
  }

  void _shift(int delta) => setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final today = dayOnly(DateTime.now());
    final selected = dayOnly(widget.selectedDay);
    final first = DateTime(_month.year, _month.month, 1);
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = first.weekday - 1; // Senin = 0
    final totalCells = ((leading + daysInMonth) / 7).ceil() * 7;

    return AppCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              _navButton(Icons.chevron_left_rounded, () => _shift(-1), 'Bulan sebelumnya'),
              Expanded(
                child: Text(
                  '${_bulanId[_month.month - 1]} ${_month.year}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              _navButton(Icons.chevron_right_rounded, () => _shift(1), 'Bulan berikutnya'),
            ],
          ),
          gap4,
          Row(
            children: [
              for (final d in const ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'])
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: d == 'Min' ? AppColors.danger.withValues(alpha: 0.7) : AppColors.textFaint,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          for (var row = 0; row < totalCells ~/ 7; row++)
            Row(
              children: [
                for (var col = 0; col < 7; col++)
                  Expanded(child: _cell(row * 7 + col - leading + 1, daysInMonth, today, selected)),
              ],
            ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              _legend(AppColors.danger, 'Kritis'),
              _legend(AppColors.amber, 'Prioritas'),
              _legend(AppColors.primary, 'Terjadwal'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _navButton(IconData icon, VoidCallback onTap, String tooltip) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(icon, size: 24),
      tooltip: tooltip,
      color: AppColors.primary,
      style: IconButton.styleFrom(backgroundColor: AppColors.primaryTint, minimumSize: const Size(40, 40)),
    );
  }

  Widget _legend(Color c, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textMuted, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _cell(int dayNum, int daysInMonth, DateTime today, DateTime selected) {
    if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox(height: 44);

    final date = DateTime(_month.year, _month.month, dayNum);
    final isToday = date == today;
    final isSelected = date == selected;
    final markers = widget.markersFor(date).take(3).toList();

    return Semantics(
      selected: isSelected,
      button: true,
      label: '$dayNum ${_bulanId[_month.month - 1]}, ${markers.length} jadwal',
      child: InkWell(
        onTap: () => widget.onDaySelected(date),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: 44,
          margin: const EdgeInsets.all(1.5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : (isToday ? AppColors.primaryTint : Colors.transparent),
            borderRadius: BorderRadius.circular(10),
            border: isToday && !isSelected ? Border.all(color: AppColors.primary, width: 1.4) : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '$dayNum',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected || isToday ? FontWeight.w800 : FontWeight.w600,
                  color:
                      isSelected
                          ? Colors.white
                          : (date.weekday == DateTime.sunday ? AppColors.danger : AppColors.textPrimary),
                ),
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (final c in markers)
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(color: isSelected ? Colors.white : c, shape: BoxShape.circle),
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
}

// ---------------------------------------------------------------------------
// GRAFIK RINGAN
// ---------------------------------------------------------------------------

/// Batang horizontal untuk perbandingan kategori (breakdown per jenis, dll).
class BarRow extends StatelessWidget {
  final String label;
  final int value;
  final int max;
  final Color color;
  final String? suffix;

  const BarRow({
    super.key,
    required this.label,
    required this.value,
    required this.max,
    required this.color,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = max == 0 ? 0.0 : value / max;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              Text('$value${suffix ?? ''}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
            ],
          ),
          const SizedBox(height: 5),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder:
                (_, v, __) => ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: v,
                    minHeight: 9,
                    backgroundColor: AppColors.screenBg,
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Grafik batang vertikal 7 titik untuk tren mingguan.
class TrendBars extends StatelessWidget {
  final List<String> labels;
  final List<double> values;
  final Color color;
  final String Function(double)? valueLabel;

  const TrendBars({
    super.key,
    required this.labels,
    required this.values,
    this.color = AppColors.primary,
    this.valueLabel,
  });

  @override
  Widget build(BuildContext context) {
    final max = values.isEmpty ? 1.0 : values.reduce(math.max);
    return SizedBox(
      height: 132,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < values.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    valueLabel?.call(values[i]) ?? values[i].toStringAsFixed(0),
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: max == 0 ? 0 : values[i] / max),
                    duration: Duration(milliseconds: 500 + i * 60),
                    curve: Curves.easeOutCubic,
                    builder:
                        (_, v, __) => Container(
                          height: 78 * v + 4,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [color, color.withValues(alpha: 0.55)],
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6),
                              bottom: Radius.circular(2),
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textFaint),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Cincin donat dengan angka di tengah (komposisi breakdown / OEE).
class DonutChart extends StatelessWidget {
  final List<({String label, int value, Color color})> segments;
  final String centerValue;
  final String centerLabel;
  final double size;

  const DonutChart({
    super.key,
    required this.segments,
    required this.centerValue,
    required this.centerLabel,
    this.size = 132,
  });

  @override
  Widget build(BuildContext context) {
    final total = segments.fold<int>(0, (a, b) => a + b.value);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder:
          (_, t, __) => SizedBox(
            width: size,
            height: size,
            child: CustomPaint(
              painter: _DonutPainter(segments, total, t),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      centerValue,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                    Text(
                      centerLabel,
                      style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ),
          ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<({String label, int value, Color color})> segments;
  final int total;
  final double t;

  _DonutPainter(this.segments, this.total, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(9, 9, size.width - 18, size.height - 18);
    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.butt;

    if (total == 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = AppColors.screenBg);
      return;
    }

    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = (s.value / total) * math.pi * 2 * t;
      canvas.drawArc(rect, start + 0.02, math.max(sweep - 0.04, 0), false, paint..color = s.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.t != t || oldDelegate.total != total;
}

/// Kartu sensor IoT dengan bar nilai relatif terhadap ambang batas.
class SensorGauge extends StatelessWidget {
  final String name;
  final String reading;
  final String statusLabel;
  final double ratio; // 0..1 terhadap ambang bahaya
  final Color color;

  const SensorGauge({
    super.key,
    required this.name,
    required this.reading,
    required this.statusLabel,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(11),
        margin: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(AppRadius.inner),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.72),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Flexible(
                  child: Text(
                    reading,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    statusLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio.clamp(0.0, 1.0)),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder:
                  (_, v, __) => ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: v,
                      minHeight: 5,
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      valueColor: AlwaysStoppedAnimation(color),
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// LOGO
// ---------------------------------------------------------------------------

/// Lambang PalmCare: daun sawit di dalam gerigi, titik buah oranye di tengah.
class PalmCareMark extends StatelessWidget {
  final double size;
  final Color color;
  final Color? background;

  const PalmCareMark({super.key, this.size = 72, this.color = AppColors.primary, this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: size * 0.045),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.settings_rounded, size: size * 0.62, color: color.withValues(alpha: 0.22)),
          Icon(Icons.spa_rounded, size: size * 0.44, color: color),
          Positioned(
            bottom: size * 0.20,
            child: Container(
              width: size * 0.13,
              height: size * 0.13,
              decoration: const BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
            ),
          ),
        ],
      ),
    );
  }
}
