import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(const SailingRaceTimerApp());
}

class SailingRaceTimerApp extends StatelessWidget {
  const SailingRaceTimerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Racebox Mobile', // Updated window title
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const RaceTimerScreen(),
    );
  }
}

class Boat {
  final String id;
  final String sailNumber;
  final String boatClass;
  final String? shortName; // Added shortName field
  String? finishTime; // Stores actual time of day as string
  DateTime? finishDateTime; // Stores the actual DateTime of finish

  Boat({
    required this.id,
    required this.sailNumber,
    required this.boatClass,
    this.shortName,
    this.finishTime,
    this.finishDateTime,
  });

  // Convert a Boat object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sailNumber': sailNumber,
      'boatClass': boatClass,
      'shortName': shortName,
      'finishTime': finishTime,
      'finishDateTime': finishDateTime?.toIso8601String(),
    };
  }

  // Extract a Boat object from a Map object
  factory Boat.fromMap(Map<String, dynamic> map) {
    return Boat(
      id: map['id'],
      sailNumber: map['sailNumber'],
      boatClass: map['boatClass'],
      shortName: map['shortName'],
      finishTime: map['finishTime'],
      finishDateTime: map['finishDateTime'] != null
          ? DateTime.parse(map['finishDateTime'])
          : null,
    );
  }
}

class BoatClass {
  final String className;
  final String shortName;
  final int handicap;

  BoatClass({
    required this.className,
    required this.shortName,
    required this.handicap,
  });

  factory BoatClass.fromJson(Map<String, dynamic> json) {
    return BoatClass(
      className: json['className'],
      shortName: json['shortName'],
      handicap: json['handicap'],
    );
  }
}

class RaceTimerScreen extends StatefulWidget {
  const RaceTimerScreen({Key? key}) : super(key: key);

  @override
  State<RaceTimerScreen> createState() => _RaceTimerScreenState();
}

class _RaceTimerScreenState extends State<RaceTimerScreen> {
  List<Boat> boats = [];
  int raceTime = 0;
  DateTime? startTime;
  String currentTimeDisplay = '';
  DateTime? userDefinedStartTime;
  List<BoatClass> boatClasses = [];
  List<String> boatClassOptions = [];

  // Fixed dimensions for boat cards
  static const double boatCardWidth = 100.0;
  static const double boatCardHeight = 80.0;
  static const double boatCardSpacing = 8.0;

  // Format for displaying time of day
  final timeFormat = DateFormat('HH:mm:ss');

  // Format for displaying start time
  String get formattedStartTime {
    if (startTime != null) {
      return timeFormat.format(startTime!);
    } else {
      return '00:00:00';
    }
  }

  @override
  void initState() {
    super.initState();
    loadBoatClasses();
    loadState();
    // Initialize current time display
    updateCurrentTimeDisplay();

    // Start a separate timer for updating the current time display
    // This runs regardless of race status
    Future.delayed(const Duration(seconds: 1), updateCurrentTimeDisplay);

    // Start the race timer if startTime is already set
    if (startTime != null) {
      updateRaceTimer();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Update the current time display
  void updateCurrentTimeDisplay() {
    if (mounted) {
      setState(() {
        currentTimeDisplay = timeFormat.format(DateTime.now());
      });
      // Schedule the next update
      Future.delayed(const Duration(seconds: 1), updateCurrentTimeDisplay);
    }
  }

  void setUserDefinedStartTime(DateTime startTime) {
    setState(() {
      this.startTime = startTime;
      raceTime = 0; // Reset race time when start time is set
    });
    updateRaceTimer(); // Start the race timer
  }

  void updateRaceTimer() {
    if (mounted) {
      setState(() {
        if (startTime != null) {
          final now = DateTime.now();
          raceTime = now.difference(startTime!).inSeconds;
        } else {
          raceTime = 0;
        }
      });
      Future.delayed(const Duration(seconds: 1), updateRaceTimer);
    }
  }

  void addBoat(String sailNumber, String boatClass, String shortName) {
    setState(() {
      // Ensure unique ID by using timestamp + random component
      final uniqueId = '${DateTime.now().millisecondsSinceEpoch}_$sailNumber';
      boats.add(Boat(
        id: uniqueId,
        sailNumber: sailNumber,
        boatClass: boatClass,
        shortName: shortName.isNotEmpty ? shortName : null, // Ensure shortName is assigned
      ));
    });
    saveState();
  }

  // Updated to record actual time of day
  void recordFinish(String boatId) {
    // Find the boat with the matching ID
    final boatIndex = boats.indexWhere((boat) => boat.id == boatId);

    if (boatIndex != -1 && boats[boatIndex].finishTime == null) {
      final now = DateTime.now();
      final formattedTime = timeFormat.format(now);

      setState(() {
        boats[boatIndex].finishTime = formattedTime;
        boats[boatIndex].finishDateTime = now;

        // Show a snackbar with undo option
        final boat = boats[boatIndex];
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${boat.shortName ?? boat.boatClass} ${boat.sailNumber} finished at $formattedTime'),
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                undoFinish(boat.id);
              },
            ),
          ),
        );
      });
      saveState();
    }
  }

  void undoFinish(String boatId) {
    // Find the boat with the matching ID
    final boatIndex = boats.indexWhere((boat) => boat.id == boatId);

    if (boatIndex != -1) {
      setState(() {
        final boat = boats[boatIndex];
        boat.finishTime = null;
        boat.finishDateTime = null;

        // Show confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Finish time for ${boat.boatClass} ${boat.sailNumber} has been removed'),
            duration: const Duration(seconds: 2),
          ),
        );
      });
      saveState();
    }
  }

  void removeBoat(String boatId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Removal'),
          content: const Text('Are you sure you want to remove this boat?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  boats.removeWhere((boat) => boat.id == boatId);
                });
                saveState();
                Navigator.of(context).pop();
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  // Format elapsed time for the race timer display
  String formatElapsedTime(int timeInSeconds) {
    final isNegative = timeInSeconds < 0;
    final absTimeInSeconds = timeInSeconds.abs();
    final hours = (absTimeInSeconds ~/ 3600).toString().padLeft(2, '0');
    final minutes =
        ((absTimeInSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final seconds = (absTimeInSeconds % 60).toString().padLeft(2, '0');
    return '${isNegative ? '-' : ''}$hours:$minutes:$seconds';
  }

  // Export results sorted by finish time
  Future<void> exportResults() async {
    // Sort boats by finish time
    final finishedBoats = boats
        .where((boat) => boat.finishDateTime != null)
        .toList()
      ..sort((a, b) => a.finishDateTime!.compareTo(b.finishDateTime!));

    if (finishedBoats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No finished boats to export'),
        ),
      );
      return;
    }

    // Create CSV content
    String csvContent = 'Position,Sail Number,Class,Finish Time\n';
    for (int i = 0; i < finishedBoats.length; i++) {
      final boat = finishedBoats[i];
      csvContent +=
          '${i + 1},${boat.sailNumber},${boat.boatClass},${boat.finishTime}\n';
    }

    // In a real app, we would save this to a file
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${finishedBoats.length} results would be exported'),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showAddBoatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AddBoatDialog(
          predefinedClasses: boatClassOptions,
          onAddBoat: (sailNumber, boatClass, shortName) {
            addBoat(sailNumber, boatClass, shortName); // Ensure shortName is passed here
          },
        );
      },
    );
  }

  void _showSetStartTimeDialog() {
    DateTime selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Set Race Start Time'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Start Time (HH:mm:ss)',
                  hintText: 'e.g. 14:30:00',
                ),
                onChanged: (value) {
                  final timeParts = value.split(':');
                  if (timeParts.length >= 2) {
                    final now = DateTime.now();
                    final hours = int.parse(timeParts[0]);
                    final minutes = int.parse(timeParts[1]);
                    final seconds =
                        timeParts.length == 3 ? int.parse(timeParts[2]) : 0;
                    selectedDate = DateTime(
                      now.year,
                      now.month,
                      now.day,
                      hours,
                      minutes,
                      seconds,
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setUserDefinedStartTime(selectedDate);
                Navigator.of(context).pop();
              },
              child: const Text('Set'),
            ),
          ],
        );
      },
    );
  }

  void resetRace() {
    setState(() {
      boats.clear();
      startTime = null;
      raceTime = 0;
    });
    saveState();
  }

  void _showResetConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Reset'),
          content: const Text(
              'Are you sure you want to reset the race? This will remove all boats and the start time.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                resetRace();
                Navigator.of(context).pop();
              },
              child: const Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final boatsJson = jsonEncode(boats.map((boat) => boat.toMap()).toList());
    await prefs.setString('boats', boatsJson);
    await prefs.setInt('raceTime', raceTime);
    await prefs.setString('startTime', startTime?.toIso8601String() ?? '');
  }

  Future<void> loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final boatsJson = prefs.getString('boats');
    if (boatsJson != null) {
      final List<dynamic> boatsList = jsonDecode(boatsJson);
      boats = boatsList.map((boatMap) => Boat.fromMap(boatMap)).toList();
    }
    raceTime = prefs.getInt('raceTime') ?? 0;
    final startTimeString = prefs.getString('startTime');
    if (startTimeString != null && startTimeString.isNotEmpty) {
      startTime = DateTime.parse(startTimeString);
    }
    setState(() {});
    
    // Start the race timer if startTime is already set
    if (startTime != null) {
      updateRaceTimer();
    }
  }

  Future<void> loadBoatClasses() async {
    final String response =
        await rootBundle.loadString('assets/boat_classes.json');
    final List<dynamic> data = jsonDecode(response);
    setState(() {
      boatClasses = data.map((json) => BoatClass.fromJson(json)).toList();
      boatClassOptions.clear();
      boatClassOptions.addAll(boatClasses.map((bc) => bc.className));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Racebox Mobile'), // Updated main program title
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: exportResults,
            tooltip: 'Export Results',
          ),
          IconButton(
            icon: const Icon(Icons.access_time),
            onPressed: _showSetStartTimeDialog,
            tooltip: 'Set Start Time',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _showResetConfirmationDialog,
            tooltip: 'Reset Race',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Race Timer Card
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth < 600) {
                      // Stack vertically if the width is less than 600
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Start Time:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            formattedStartTime,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Elapsed:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            formatElapsedTime(raceTime),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current Time:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            currentTimeDisplay,
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Default horizontal layout
                      return Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Start Time:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Elapsed:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Text(
                                'Current Time:',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formattedStartTime,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                formatElapsedTime(raceTime),
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                              Text(
                                currentTimeDisplay,
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Boats Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Boats',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: boats.isEmpty
                        ? const Center(
                            child: Text(
                              'No boats added yet.\nTap + to add a boat.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          )
                        : SingleChildScrollView(
                            child: Wrap(
                              spacing: boatCardSpacing,
                              runSpacing: boatCardSpacing,
                              children: boats.map((boat) {
                                final hasFinished = boat.finishTime != null;
                                return FixedSizeBoatCard(
                                  width: boatCardWidth,
                                  height: boatCardHeight,
                                  boat: boat,
                                  hasFinished: hasFinished,
                                  onTap: () => recordFinish(boat.id),
                                  onUndo: () => undoFinish(boat.id),
                                  onRemove: () => removeBoat(boat.id),
                                  boatClasses: boatClasses, // Add this line
                                );
                              }).toList(),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddBoatDialog,
        tooltip: 'Add Boat',
        child: const Icon(Icons.add),
      ),
    );
  }
}

// Fixed-size boat card widget with absolute dimensions
class FixedSizeBoatCard extends StatelessWidget {
  final double width;
  final double height;
  final Boat boat;
  final bool hasFinished;
  final VoidCallback onTap;
  final VoidCallback onUndo;
  final VoidCallback onRemove;
  final List<BoatClass> boatClasses; // Add this line

  const FixedSizeBoatCard({
    Key? key,
    required this.width,
    required this.height,
    required this.boat,
    required this.hasFinished,
    required this.onTap,
    required this.onUndo,
    required this.onRemove,
    required this.boatClasses, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Find the boat class object
    final boatClass = boatClasses.firstWhere(
      (bc) => bc.className == boat.boatClass,
      orElse: () => BoatClass(className: boat.boatClass, shortName: boat.boatClass, handicap: 1000),
    );

    // Determine the display name
    final displayName = boatClass.className.length > 6 ? boatClass.shortName : boatClass.className;

    return SizedBox(
      width: width,
      height: height,
      child: Card(
        margin: EdgeInsets.zero,
        color: hasFinished ? Colors.green[100] : null,
        shape: hasFinished
            ? RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: Colors.green[700]!,
                  width: 1,
                ),
              )
            : null,
        child: InkWell(
          onTap: hasFinished ? null : onTap,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Compact layout for small card
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            boat.sailNumber,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayName,
                      style: TextStyle(
                        color: Colors.grey[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (hasFinished)
                      Text(
                        boat.finishTime ?? '',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    else
                      const Text(
                        'Tap to finish',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              // Small delete button in corner
              Positioned(
                right: 0,
                top: 0,
                child: GestureDetector(
                  onTap: onRemove,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.close,
                      color: Colors.red,
                      size: 12,
                    ),
                  ),
                ),
              ),
              // Undo button in bottom right corner
              if (hasFinished)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: onUndo,
                    child: const Icon(Icons.undo, size: 16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddBoatDialog extends StatefulWidget {
  final List<String> predefinedClasses;
  final Function(String, String, String) onAddBoat;

  AddBoatDialog({required this.predefinedClasses, required this.onAddBoat});

  @override
  _AddBoatDialogState createState() => _AddBoatDialogState();
}

class _AddBoatDialogState extends State<AddBoatDialog> {
  final _sailNumberController = TextEditingController();
  final _classController = TextEditingController();
  final _shortNameController = TextEditingController(); // Add this line
  bool _isCustomClass = false;
  bool _isSailNumberValid = true;
  bool _isClassValid = true;

  @override
  void initState() {
    super.initState();
    if (widget.predefinedClasses.isNotEmpty) {
      _classController.text = widget.predefinedClasses.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Boat'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _sailNumberController,
            decoration: InputDecoration(
              labelText: 'Sail Number',
              errorText: _isSailNumberValid ? null : 'Sail Number is required',
            ),
          ),
          Row(
            children: [
              const Text('Custom Class'),
              Switch(
                value: _isCustomClass,
                onChanged: (bool value) {
                  setState(() {
                    _isCustomClass = value;
                    if (!_isCustomClass) {
                      _classController.text = widget.predefinedClasses.first;
                    } else {
                      _classController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          if (_isCustomClass)
            TextField(
              controller: _classController,
              decoration: InputDecoration(
                labelText: 'Custom Class',
                errorText: _isClassValid ? null : 'Class is required',
              ),
            )
          else
            DropdownButtonFormField<String>(
              value: _classController.text,
              items: widget.predefinedClasses.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _classController.text = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'Class',
              ),
            ),
          TextField(
            controller: _shortNameController, // Add this line
            decoration: const InputDecoration(
              labelText: 'Short Name', // Add this line
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _isSailNumberValid = _sailNumberController.text.isNotEmpty;
              _isClassValid =
                  !_isCustomClass || _classController.text.isNotEmpty;
            });

            if (_isSailNumberValid && _isClassValid) {
              final sailNumber = _sailNumberController.text;
              final boatClass = _classController.text;
              final shortName = _shortNameController.text; // Add this line
              widget.onAddBoat(sailNumber, boatClass, shortName); // Add this line
              Navigator.of(context).pop();
            }
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _sailNumberController.dispose();
    _classController.dispose();
    _shortNameController.dispose(); // Add this line
    super.dispose();
  }
}
