num asNum(Object? value) {
  if (value is num) return value;
  return num.tryParse('$value') ?? 0;
}

int asInt(Object? value) => asNum(value).round();

double asDouble(Object? value) => asNum(value).toDouble();

String formatCompactNumber(Object? value) {
  final number = asNum(value);
  final abs = number.abs();
  if (abs >= 1000000) {
    return '${(number / 1000000).toStringAsFixed(abs >= 10000000 ? 0 : 1)}M';
  }
  if (abs >= 1000) {
    return '${(number / 1000).toStringAsFixed(abs >= 10000 ? 0 : 1)}K';
  }
  return number.round().toString();
}

String formatPercent(Object? value) => '${asDouble(value).toStringAsFixed(1)}%';

String formatRank(Object? value) {
  final badge = asInt(value);
  if (badge <= 0) return 'Unranked';
  final tier = badge ~/ 10;
  final subrank = badge % 10;
  const tierNames = {
    1: 'Initiate',
    2: 'Seeker',
    3: 'Alchemist',
    4: 'Arcanist',
    5: 'Ritualist',
    6: 'Emissary',
    7: 'Archon',
    8: 'Oracle',
    9: 'Phantom',
    10: 'Ascendant',
    11: 'Eternus',
  };
  final name = tierNames[tier] ?? 'Badge $tier';
  return subrank > 0 ? '$name $subrank' : name;
}
