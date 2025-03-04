class Boat {
  final String id;
  final String sailNumber;
  final String boatClass;
  String? finishTime;
  int? finishSeconds;

  Boat({
    required this.id,
    required this.sailNumber,
    required this.boatClass,
    this.finishTime,
    this.finishSeconds,
  });
}

