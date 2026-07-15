/// Entity di dominio per un giocatore: nessuna dipendenza da Hive o da
/// altri dettagli del layer dati. `role` resta una stringa libera ('P',
/// 'D', 'C', 'A') invece di un enum tipizzato per restare bit-compatibile
/// con `PlayerModel`/il resto del codebase non ancora migrato — introdurre
/// un enum è un miglioramento futuro indipendente (vedi roadmap).
class Player {
  final String id;
  final String name;
  final String role;
  final String icon;
  final String? imagePath;
  final int mvpCount;
  final int hustleCount;
  final int bestGoalCount;
  final int totalGoals;

  const Player({
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

  Player copyWith({
    String? name,
    String? role,
    String? icon,
    String? imagePath,
  }) {
    return Player(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      icon: icon ?? this.icon,
      imagePath: imagePath ?? this.imagePath,
      mvpCount: mvpCount,
      hustleCount: hustleCount,
      bestGoalCount: bestGoalCount,
      totalGoals: totalGoals,
    );
  }
}
