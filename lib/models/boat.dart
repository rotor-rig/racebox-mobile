// import 'dart:convert';

class Boat {
  final String id;
  final String sailNumber;
  final String boatClass;
  final String? shortName;
  final int handicap;
  String? finishTime;
  DateTime? finishDateTime;

  Boat({
    required this.id,
    required this.sailNumber,
    required this.boatClass,
    this.shortName,
    required this.handicap,
    this.finishTime,
    this.finishDateTime,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sailNumber': sailNumber,
      'boatClass': boatClass,
      'shortName': shortName,
      'handicap': handicap,
      'finishTime': finishTime,
      'finishDateTime': finishDateTime?.toIso8601String(),
    };
  }

  factory Boat.fromMap(Map<String, dynamic> map) {
    return Boat(
      id: map['id'],
      sailNumber: map['sailNumber'],
      boatClass: map['boatClass'],
      shortName: map['shortName'],
      handicap: map['handicap'],
      finishTime: map['finishTime'],
      finishDateTime: map['finishDateTime'] != null
          ? DateTime.parse(map['finishDateTime'])
          : null,
    );
  }
}
