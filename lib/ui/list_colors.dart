import 'package:flutter/material.dart';

export '../storage/database.dart' show listColorKeys;

/// Tones for one list color: [chip] for the chip and ▾ grid tile, [row] for
/// sentence rows (and the overview row), [rowActive] for the tapped/speaking
/// row, [stripe] for accents (swatches, the overview stripe).
class ListColor {
  const ListColor({
    required this.chip,
    required this.row,
    required this.rowActive,
    required this.stripe,
  });
  final Color chip;
  final Color row;
  final Color rowActive;
  final Color stripe;
}

// key -> (hue-ish light tones: chip, row, rowActive, stripe)
const _light = <String, ListColor>{
  'blue': ListColor(
    chip: Color(0xFFBBDCFF),
    row: Color(0xFFE3F0FF),
    rowActive: Color(0xFFB3D7FF),
    stripe: Color(0xFF4A90E2),
  ),
  'green': ListColor(
    chip: Color(0xFFBDE8C4),
    row: Color(0xFFE4F5E7),
    rowActive: Color(0xFFB5E3BD),
    stripe: Color(0xFF3FA356),
  ),
  'orange': ListColor(
    chip: Color(0xFFFFD6A8),
    row: Color(0xFFFFEEDB),
    rowActive: Color(0xFFFFCF99),
    stripe: Color(0xFFE8820C),
  ),
  'purple': ListColor(
    chip: Color(0xFFDCC8F5),
    row: Color(0xFFF0E8FA),
    rowActive: Color(0xFFD6BFF3),
    stripe: Color(0xFF8E5CD0),
  ),
  'teal': ListColor(
    chip: Color(0xFFB0E6E2),
    row: Color(0xFFDDF4F2),
    rowActive: Color(0xFFA6E1DC),
    stripe: Color(0xFF1E9C94),
  ),
  'pink': ListColor(
    chip: Color(0xFFFFC9DB),
    row: Color(0xFFFFE8F0),
    rowActive: Color(0xFFFFBFD4),
    stripe: Color(0xFFE0457F),
  ),
  'yellow': ListColor(
    chip: Color(0xFFFFF0A0),
    row: Color(0xFFFFF8D6),
    rowActive: Color(0xFFFFEE90),
    stripe: Color(0xFFD1AB00),
  ),
  'brown': ListColor(
    chip: Color(0xFFE2CBB8),
    row: Color(0xFFF2E7DE),
    rowActive: Color(0xFFDCC2AB),
    stripe: Color(0xFF9A6B45),
  ),
  'red': ListColor(
    chip: Color(0xFFFFC2BD),
    row: Color(0xFFFFE6E4),
    rowActive: Color(0xFFFFB5AE),
    stripe: Color(0xFFD32F2F),
  ),
};

// Dark theme: the same hues, dark tones (text is light there).
const _dark = <String, ListColor>{
  'blue': ListColor(
    chip: Color(0xFF1F354D),
    row: Color(0xFF162433),
    rowActive: Color(0xFF223B57),
    stripe: Color(0xFF6BAAF0),
  ),
  'green': ListColor(
    chip: Color(0xFF214028),
    row: Color(0xFF172A1C),
    rowActive: Color(0xFF244C2E),
    stripe: Color(0xFF6CCB82),
  ),
  'orange': ListColor(
    chip: Color(0xFF4D3515),
    row: Color(0xFF332412),
    rowActive: Color(0xFF5A3C17),
    stripe: Color(0xFFF2A04A),
  ),
  'purple': ListColor(
    chip: Color(0xFF382950),
    row: Color(0xFF261C34),
    rowActive: Color(0xFF422F63),
    stripe: Color(0xFFB48AEB),
  ),
  'teal': ListColor(
    chip: Color(0xFF16403D),
    row: Color(0xFF102B29),
    rowActive: Color(0xFF194D49),
    stripe: Color(0xFF4CC9C0),
  ),
  'pink': ListColor(
    chip: Color(0xFF50293B),
    row: Color(0xFF351C26),
    rowActive: Color(0xFF602E44),
    stripe: Color(0xFFF07BA6),
  ),
  'yellow': ListColor(
    chip: Color(0xFF433C11),
    row: Color(0xFF2E290E),
    rowActive: Color(0xFF504817),
    stripe: Color(0xFFE6C830),
  ),
  'brown': ListColor(
    chip: Color(0xFF433022),
    row: Color(0xFF2E2216),
    rowActive: Color(0xFF503A29),
    stripe: Color(0xFFC49470),
  ),
  'red': ListColor(
    chip: Color(0xFF52211E),
    row: Color(0xFF361716),
    rowActive: Color(0xFF63282A),
    stripe: Color(0xFFF2766E),
  ),
};

/// Tones for a palette [key]; null or an unknown key (e.g. from a newer app
/// version) gives the neutral tones of the theme.
ListColor listColor(BuildContext context, String? key) {
  final scheme = Theme.of(context).colorScheme;
  final dark = scheme.brightness == Brightness.dark;
  final found = (dark ? _dark : _light)[key];
  if (found != null) return found;
  return ListColor(
    chip: scheme.surfaceContainerHigh,
    row: scheme.surfaceContainerHighest,
    rowActive: scheme.primaryContainer,
    stripe: scheme.outline,
  );
}

/// Tones for a key and brightness without a BuildContext (tests).
ListColor? listColorFor(String key, Brightness brightness) =>
    (brightness == Brightness.dark ? _dark : _light)[key];

/// Alpha of the greyed-out text of a `said` row. Deliberately clearly dimmer
/// than unsaid text (the row also fades and shows a check mark), since the
/// point is seeing at a glance what is left; still readable on the faded row.
const saidTextAlpha = 0.6;
