import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';
import 'package:marquee/marquee.dart';

class StationDetailScreen extends StatefulWidget {
  final List<Map<String, String>> stationList;
  final int currentIndex;
  final AudioPlayer sharedPlayer;
  final ValueChanged<int>? onStationChanged;

  const StationDetailScreen({
    required this.stationList,
    required this.currentIndex,
    required this.sharedPlayer,
    this.onStationChanged,
    super.key,
  });

  @override
  State<StationDetailScreen> createState() => _StationDetailScreenState();
}

class _StationDetailScreenState extends State<StationDetailScreen> {
  late int currentIndex;
  bool isBuffering = false;
  bool isPlaying = false;
  String? streamErrorMessage;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.currentIndex;
    _initPlayer();

    // Monitor stream status
    widget.sharedPlayer.playbackEventStream.listen(
      (event) {
        debugPrint("🎧 status = ${event.processingState}");
      },
      onError: (e, stack) {
        debugPrint('❌ Playback error: $e');
      },
    );
  }

  Future<void> _initPlayer() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());
    await _loadCurrentStation();
  }

  Future<void> _loadCurrentStation() async {
    final station = widget.stationList[currentIndex];
    final rawUrl = station['shoutcastUrl'];

    if (rawUrl == null || rawUrl.isEmpty) {
      debugPrint('⚠️ No shoutcastUrl provided for this station');
      setState(() {
        streamErrorMessage = 'Streaming for this station is not available yet.';
        isPlaying = false;
        isBuffering = false;
      });
      return;
    }

    final streamUrl = '$rawUrl/play.mp3';
    debugPrint('🎧 Stream URL: $streamUrl');

    setState(() {
      isBuffering = true;
      streamErrorMessage = null;
    });

    try {
      await widget.sharedPlayer.setAudioSource(
        AudioSource.uri(
          Uri.parse(streamUrl),
          headers: {
            'User-Agent':
                'Mozilla/5.0 (Linux; Android 11; Mobile; rv:102.0) Gecko/102.0 Firefox/102.0',
            'Accept': '*/*',
            'Icy-Metadata': '1',
          },
        ),
      );
      await widget.sharedPlayer.play();

      setState(() {
        isPlaying = true;
        isBuffering = false;
      });
    } catch (e) {
      debugPrint('❌ Error playing stream: $e');
      setState(() {
        streamErrorMessage = 'Streaming for this station is not available yet.';
        isPlaying = false;
        isBuffering = false;
      });
      final stationName =
          widget.stationList[currentIndex]['title'] ?? 'This station';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$stationName is having issues right now. Please come back later.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _togglePlayPause() async {
    setState(() {
      isBuffering = true;
    });

    if (isPlaying) {
      await widget.sharedPlayer.pause();
    } else {
      await widget.sharedPlayer.play();
    }

    setState(() {
      isPlaying = !isPlaying;
      isBuffering = false;
    });
  }

  void _goToNext() {
    setState(() {
      currentIndex = (currentIndex + 1) % widget.stationList.length;
    });
    widget.onStationChanged?.call(currentIndex);
    _loadCurrentStation();
  }

  void _goToPrevious() {
    setState(() {
      currentIndex =
          (currentIndex - 1 + widget.stationList.length) %
          widget.stationList.length;
    });
    widget.onStationChanged?.call(currentIndex);
    _loadCurrentStation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
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
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
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
            if (isPlaying)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),

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

            Container(
              height: 20,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Marquee(
                text: currentStation['subtitle'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                scrollAxis: Axis.horizontal,
                blankSpace: 50.0,
                velocity: 30.0,
                pauseAfterRound: Duration(seconds: 1),
                startPadding: 10.0,
                accelerationDuration: Duration(seconds: 1),
                accelerationCurve: Curves.linear,
                decelerationDuration: Duration(milliseconds: 500),
                decelerationCurve: Curves.easeOut,
              ),
            ),

            const SizedBox(height: 30),

            // Progress Bar
            StreamBuilder<Duration>(
              stream: widget.sharedPlayer.positionStream,
              builder: (context, snapshot) {
                final position = snapshot.data ?? Duration.zero;
                final duration =
                    widget.sharedPlayer.duration ?? Duration(seconds: 1);

                return Column(
                  children: [
                    Slider(
                      min: 0,
                      max: duration.inMilliseconds.toDouble(),
                      value:
                          position.inMilliseconds
                              .clamp(0, duration.inMilliseconds)
                              .toDouble(),
                      activeColor: Colors.white,
                      inactiveColor: Colors.white24,
                      onChanged: (value) {
                        widget.sharedPlayer.seek(
                          Duration(milliseconds: value.toInt()),
                        );
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(position),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
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
                        Container(
                          width: 64,
                          height: 64,
                          child:
                              isBuffering
                                  ? const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                  : IconButton(
                                    icon: Icon(
                                      isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      size: 64,
                                      color: Colors.white,
                                    ),
                                    onPressed: _togglePlayPause,
                                  ),
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
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
