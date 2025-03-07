import 'package:flutter/material.dart';
import '../models/boat.dart'; // Import Boat  and BoatClass
import '../models/boat_class.dart'; // Import BoatClass

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
      orElse: () => BoatClass(
          className: boat.boatClass,
          shortName: boat.boatClass,
          handicap: 1000,
          priority: false),
    );

    // Determine the display name
    final displayName = boatClass.className.length > 6
        ? boatClass.shortName
        : boatClass.className;

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
