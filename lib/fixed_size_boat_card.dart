// This file contains the FixedSizeBoatCard widget which is a fixed-size card widget for displaying a boat.
// The card has a fixed width and height and displays the boat's sail number, class name, and finish time.
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
  final VoidCallback onMoveUpOne;
  final VoidCallback onMoveUpTop;
  final List<BoatClass> boatClasses;

  const FixedSizeBoatCard({
    Key? key,
    required this.width,
    required this.height,
    required this.boat,
    required this.hasFinished,
    required this.onTap,
    required this.onUndo,
    required this.onRemove,
    required this.onMoveUpOne,
    required this.onMoveUpTop,
    required this.boatClasses, 
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
          onLongPress: onRemove,
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 24, 2, 2),
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
              // Reorder button in top left corner
              Positioned(
                left: 2,
                top: 2,
                child: GestureDetector(
                  onTap: onMoveUpOne, // move up one place
                  onLongPress: onMoveUpTop, //move to top of list
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        width: 1,
                        color: Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    padding: const EdgeInsets.all(2),
                    child: const Icon(
                      Icons.arrow_back,
                      // color: Colors.red,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Race Number in top right corner
              Positioned(
                top: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  //decoration: BoxDecoration(
                    //color: Colors.blue[100],
                    //borderRadius: BorderRadius.circular(4),
                  //),
                  child: Text(
                    boat.raceNumber?.toString() ?? '',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              // Undo button in bottom right corner
              if (hasFinished)
                Positioned(
                  right: 2,
                  bottom: 2,
                  child: GestureDetector(
                      onTap: onUndo,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            width: 1,
                            color: Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: const Icon(Icons.undo, size: 16),
                      )),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
