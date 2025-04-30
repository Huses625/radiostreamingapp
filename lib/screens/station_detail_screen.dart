import 'package:flutter/material.dart';

class StationDetailScreen extends StatefulWidget {
  final List<Map<String, String>> stationList;
  final int currentIndex;

  const StationDetailScreen({
    super.key,
    required this.stationList,
    required this.currentIndex,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
  }

  void _goToNext() {
    setState(() {
      currentIndex = (currentIndex + 1) % widget.stationList.length;
    });
  }

  void _goToPrevious() {
    setState(() {
      currentIndex =
          (currentIndex - 1 + widget.stationList.length) %
          widget.stationList.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStation = widget.stationList[currentIndex];

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          const SizedBox(height: 20),

          const Text(
            'NOW PLAYING',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 12,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),

          // Subtitle Animated
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder:
                (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.5, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
            child: Text(
              currentStation['subtitle']!,
              key: ValueKey(currentStation['subtitle']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Image Animated
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder:
                (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(1, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
            child: ClipRRect(
              key: ValueKey(currentStation['image']),
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                currentStation['image']!,
                width: MediaQuery.of(context).size.width * 0.7,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Title Animated
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            transitionBuilder:
                (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.5, 0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
            child: Text(
              currentStation['title']!,
              key: ValueKey(currentStation['title']),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Playback slider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: Column(
              children: [
                Slider(
                  value: 0.09,
                  min: 0,
                  max: 1,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (value) {},
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "0:09",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                    Text(
                      "4:25",
                      style: TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Playback controls
          Padding(
            padding: const EdgeInsets.only(bottom: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.skip_previous,
                    size: 32,
                    color: Colors.white,
                  ),
                  onPressed: _goToPrevious,
                ),
                const Icon(
                  Icons.play_circle_fill,
                  size: 64,
                  color: Colors.white,
                ),
                IconButton(
                  icon: const Icon(
                    Icons.skip_next,
                    size: 32,
                    color: Colors.white,
                  ),
                  onPressed: _goToNext,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
