class BoatClass {
  final String className;
  final String shortName;
  final int handicap;
  final bool priority;

  BoatClass({
    required this.className,
    required this.shortName,
    required this.handicap,
    required this.priority,
  });

  factory BoatClass.fromJson(Map<String, dynamic> json) {
    return BoatClass(
      className: json['className'],
      shortName: json['shortName'],
      handicap: json['handicap'],
      priority: json['priority'],
    );
  }
}
