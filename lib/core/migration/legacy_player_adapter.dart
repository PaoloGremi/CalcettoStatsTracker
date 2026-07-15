import 'package:hive/hive.dart';

/// Record piatto con lo stesso shape del vecchio `Player` (prima della
/// migrazione a `PlayerModel` con adapter generato). Serve solo a leggere
/// i byte scritti dal vecchio [LegacyPlayerAdapter] durante la migrazione
/// una-tantum in [HiveMigrationService] — non è un modello di dominio.
class LegacyPlayerRecord {
  final String id;
  final String name;
  final String role;
  final String icon;
  final String? imagePath;
  final int mvpCount;
  final int hustleCount;
  final int bestGoalCount;
  final int totalGoals;

  const LegacyPlayerRecord({
    required this.id,
    required this.name,
    required this.role,
    required this.icon,
    this.imagePath,
    this.mvpCount = 0,
    this.hustleCount = 0,
    this.bestGoalCount = 0,
    this.totalGoals = 0,
  });
}

/// Copia byte-per-byte identica del vecchio `PlayerAdapter` scritto a mano
/// (stesso typeId, stessa logica read/write posizionale con i fallback
/// di retrocompatibilità), solo ritargettizzata su [LegacyPlayerRecord]
/// invece che sul modello applicativo. Non va mai modificata: rappresenta
/// il contratto binario dei dati già scritti su disco dagli utenti prima
/// della migrazione a `PlayerModel`.
class LegacyPlayerAdapter extends TypeAdapter<LegacyPlayerRecord> {
  @override
  final int typeId = 0;

  @override
  LegacyPlayerRecord read(BinaryReader reader) {
    final id = reader.readString();
    final name = reader.readString();
    final role = reader.readString();
    final icon = reader.readString();

    // imagePath — retrocompatibile
    String? imagePath;
    try {
      final raw = reader.read();
      if (raw is String && raw.isNotEmpty) imagePath = raw;
    } catch (_) {}

    // mvpCount — retrocompatibile (0 se non presente)
    int mvpCount = 0;
    try {
      final raw = reader.read();
      if (raw is int) mvpCount = raw;
    } catch (_) {}

    // hustleCount — retrocompatibile (0 se non presente)
    int hustleCount = 0;
    try {
      final raw = reader.read();
      if (raw is int) hustleCount = raw;
    } catch (_) {}

    // bestGoalCount — retrocompatibile (0 se non presente)
    int bestGoalCount = 0;
    try {
      final raw = reader.read();
      if (raw is int) bestGoalCount = raw;
    } catch (_) {}

    // totalGoals — retrocompatibile (0 se non presente)
    int totalGoals = 0;
    try {
      final raw = reader.read();
      if (raw is int) totalGoals = raw;
    } catch (_) {}

    return LegacyPlayerRecord(
      id: id,
      name: name,
      role: role,
      icon: icon,
      imagePath: imagePath,
      mvpCount: mvpCount,
      hustleCount: hustleCount,
      bestGoalCount: bestGoalCount,
      totalGoals: totalGoals,
    );
  }

  @override
  void write(BinaryWriter writer, LegacyPlayerRecord obj) {
    writer.writeString(obj.id);
    writer.writeString(obj.name);
    writer.writeString(obj.role);
    writer.writeString(obj.icon);
    writer.write(obj.imagePath ?? '');
    writer.write(obj.mvpCount);
    writer.write(obj.hustleCount);
    writer.write(obj.bestGoalCount);
    writer.write(obj.totalGoals);
  }
}
