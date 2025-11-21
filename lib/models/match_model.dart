import 'package:hive/hive.dart';

@HiveType(typeId: 1)
class MatchModel extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  DateTime date;

  // Liste di ID dei giocatori per ogni squadra
  @HiveField(2)
  List<String> teamA;

  @HiveField(3)
  List<String> teamB;

  @HiveField(4)
  int scoreA;

  @HiveField(5)
  int scoreB;

  // Mappa voti: key = playerId, value = voto (int)
  @HiveField(6)
  Map<String, double> votes;

  @HiveField(7)
  Map<String, String> comments;

  @HiveField(8)
  String fieldLocation;

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
  }) : votes = votes ?? {},
        comments = comments ?? {};
    
}

// Adapter manuale per Hive
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
  }
}
