import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class MatchModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  @HiveField(2)
  List<String> teamA;

  @HiveField(3)
  List<String> teamB;

  @HiveField(4)
  int scoreA;

  @HiveField(5)
  int scoreB;

  @HiveField(6)
  Map<String, double> votes;

  @HiveField(7)
  Map<String, String> comments;

  @HiveField(8)
  String fieldLocation;

  @HiveField(9)
  String mvp;

  @HiveField(10)
  String hustlePlayer;

  @HiveField(11)
  String bestGoalPlayer;

  @HiveField(12)
  Map<String, int> goals; // ✅ gol segnati per giocatore in questa partita

  MatchModel({
    required this.id,
    required this.date,
    required this.teamA,
    required this.teamB,
    this.scoreA = 0,
    this.scoreB = 0,
    Map<String, double>? votes,
    Map<String, String>? comments,
    required this.fieldLocation,
    required this.mvp,
    required this.hustlePlayer,
    this.bestGoalPlayer = '',
    Map<String, int>? goals,
  })  : votes = votes ?? {},
        comments = comments ?? {},
        goals = goals ?? {};
}

class MatchModelAdapter extends TypeAdapter<MatchModel> {
  @override
  final int typeId = 1;

  @override
  MatchModel read(BinaryReader reader) {
    final id = reader.readString();
    final dateMillis = reader.readInt();
    final teamA = List<String>.from(reader.readList());
    final teamB = List<String>.from(reader.readList());
    final scoreA = reader.readInt();
    final scoreB = reader.readInt();
    final votesMap = Map<String, double>.from(reader.readMap());
    final commentsMap = Map<String, String>.from(reader.readMap());
    final fieldLocation = reader.readString();
    final mvp = reader.readString();
    final hustlePlayer = reader.readString();

    // retrocompatibile: '' se non presente nei dati vecchi
    String bestGoalPlayer = '';
    try {
      bestGoalPlayer = reader.readString();
    } catch (_) {}

    // ✅ retrocompatibile: {} se non presente nei dati vecchi
    Map<String, int> goals = {};
    try {
      final raw = reader.readMap();
      goals = raw.map((k, v) => MapEntry(k.toString(), (v as num).toInt()));
    } catch (_) {}

    return MatchModel(
      id: id,
      date: DateTime.fromMillisecondsSinceEpoch(dateMillis),
      teamA: teamA,
      teamB: teamB,
      scoreA: scoreA,
      scoreB: scoreB,
      votes: votesMap,
      comments: commentsMap,
      fieldLocation: fieldLocation,
      mvp: mvp,
      hustlePlayer: hustlePlayer,
      bestGoalPlayer: bestGoalPlayer,
      goals: goals,
    );
  }

  @override
  void write(BinaryWriter writer, MatchModel obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.date.millisecondsSinceEpoch);
    writer.writeList(obj.teamA);
    writer.writeList(obj.teamB);
    writer.writeInt(obj.scoreA);
    writer.writeInt(obj.scoreB);
    writer.writeMap(obj.votes);
    writer.writeMap(obj.comments);
    writer.writeString(obj.fieldLocation);
    writer.writeString(obj.mvp);
    writer.writeString(obj.hustlePlayer);
    writer.writeString(obj.bestGoalPlayer);
    writer.writeMap(obj.goals);
  }
}
