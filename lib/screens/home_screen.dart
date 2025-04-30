import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brigada_radio_streaming/screens/station_detail_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:marquee/marquee.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late AudioPlayer sharedPlayer;
  bool isPlaying = false;
  List<Map<String, String>> stations = [];
  bool isLoading = true;
  bool hasError = false;
  Duration? _playerDuration;
  String? _currentTitle;
  String? _currentStationImage;
  int? _currentIndex;
  String? _currentSubtitle;
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = '';
  Set<String> favorites = {};
  List<dynamic> latestNews = [];

  List<Map<String, String>> get filteredStations {
    if (searchQuery.isEmpty) return stations;
    return stations.where((station) {
      final title = station['title']?.toLowerCase() ?? '';
      final location = station['subtitle']?.toLowerCase() ?? '';
      return title.contains(searchQuery.toLowerCase()) ||
          location.contains(searchQuery.toLowerCase());
    }).toList();
  }

  bool isFavorite(String title) {
    return favorites.contains(title);
  }

  void toggleFavorite(String title) {
    setState(() {
      if (favorites.contains(title)) {
        favorites.remove(title);
      } else {
        favorites.add(title);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    sharedPlayer = AudioPlayer();
    sharedPlayer.playerStateStream.listen((state) {
      final playing = state.playing;
      final processing = state.processingState;

      setState(() {
        isPlaying = playing && processing != ProcessingState.idle;
      });
    });

    sharedPlayer.currentIndexStream.listen((index) {
      if (index != null && index >= 0 && index < stations.length) {
        final station = stations[index];
        setState(() {
          _currentIndex = index;
          _currentTitle = station['title'];
          _currentStationImage = station['image'];
          _currentSubtitle = station['subtitle'];
        });
      }
    });

    fetchStations();
    fetchLatestNews();
  }

  Future<void> fetchLatestNews() async {
    try {
      final response = await http.get(
        Uri.parse('https://brigadanews.ph/wp-json/wp/v2/posts/'),
      );
      if (response.statusCode == 200) {
        setState(() {
          latestNews =
              json.decode(response.body).map<Map<String, dynamic>>((item) {
                final ogImageList = item['yoast_head_json']?['og_image'];
                final thumbnail =
                    (ogImageList != null &&
                            ogImageList is List &&
                            ogImageList.isNotEmpty)
                        ? ogImageList.first['url']
                        : null;

                return {
                  'title': item['title'],
                  'excerpt': item['excerpt'],
                  'thumbnail': thumbnail,
                };
              }).toList();
        });
      }
    } catch (e) {
      debugPrint('❌ Failed to fetch latest news: $e');
    }
  }

  @override
  void dispose() {
    sharedPlayer.dispose();
    super.dispose();
  }

  Future<void> fetchStations() async {
    try {
      final response = await http.get(
        Uri.parse(
          'https://www.brigadanews.ph/fmstreamv2/assets/stationList.json',
        ),
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          stations =
              data.map<Map<String, String>>((item) {
                return {
                  'title':
                      '${item['frequency']} Brigada News FM ${item['stationName']}',
                  'subtitle': item['location'] ?? '',
                  'image':
                      'https://brigadanews.ph/fmstreamv2/assets/stationLogo/${item['stationLogo']}.jpg',
                  'stationName': item['stationName'] ?? '',
                  'stationLogo': item['stationLogo'] ?? '',
                  'frequency': item['frequency'] ?? '',
                  'shoutcastUrl': item['shoutcastUrl'] ?? '',
                  'location': item['location'] ?? '',
                };
              }).toList();
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
      });
    }
  }

  void updateMiniPlayerInfo(int index) {
    if (index >= 0 && index < stations.length) {
      final station = stations[index];
      setState(() {
        _currentIndex = index;
        _currentTitle = station['title'];
        _currentStationImage = station['image'];
        _currentSubtitle = station['subtitle'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            '🎙 Brigada Radio',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 24,
            ),
          ),
          bottom: const TabBar(
            indicatorColor: Colors.red,
            labelColor: Colors.white,
            unselectedLabelColor: Color.fromARGB(153, 133, 133, 133),
            tabs: [
              Tab(text: 'News FM Stations'),
              Tab(text: 'Latest News'),
              Tab(text: 'Favorites'),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: TabBarView(
                    children: [
                      isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : hasError
                          ? const Center(
                            child: Text(
                              'Failed to load stations',
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                          : _buildStationList(context),
                      latestNews.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: latestNews.length,
                            itemBuilder: (context, index) {
                              final news = latestNews[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white10,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      if (news['thumbnail'] != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 10,
                                          ),
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              news['thumbnail'],
                                              height: 180,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        ),
                                      Text(
                                        news['title']?['rendered'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        RegExp(r"<[^>]*>")
                                            .allMatches(
                                              news['excerpt']?['rendered'] ??
                                                  '',
                                            )
                                            .fold(
                                              news['excerpt']?['rendered'] ??
                                                  '',
                                              (previousValue, match) =>
                                                  previousValue.replaceAll(
                                                    match.group(0)!,
                                                    '',
                                                  ),
                                            ),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                      _buildFavoritesList(context),
                    ],
                  ),
                ),
              ],
            ),
            if (_currentIndex != null && isPlaying)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    if (_currentIndex != null &&
                        _currentIndex! < stations.length) {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder:
                              (_) => StationDetailScreen(
                                stationList: stations,
                                currentIndex: _currentIndex!,
                                sharedPlayer: sharedPlayer,
                              ),
                        ),
                        (route) => route.isFirst,
                      );
                    }
                  },
                  child: Container(
                    height: 70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1C1C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            _currentStationImage ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (context, error, stackTrace) => Container(
                                  width: 50,
                                  height: 50,
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white54,
                                  ),
                                ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentTitle ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(
                                height: 18,
                                width: double.infinity,
                                child: Marquee(
                                  text: _currentSubtitle ?? '',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  blankSpace: 60.0,
                                  velocity: 30.0,
                                  pauseAfterRound: Duration(seconds: 1),
                                  startPadding: 10.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStationList(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                searchQuery = value;
              });
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search stations...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white54),
              suffixIcon:
                  searchQuery.isNotEmpty
                      ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white54),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            searchQuery = '';
                          });
                        },
                      )
                      : null,
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(
              bottom: 100,
              top: 0,
              left: 16,
              right: 16,
            ),
            itemCount: filteredStations.length,
            itemBuilder: (context, index) {
              final station = filteredStations[index];
              return _buildStationTile(context, station);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFavoritesList(BuildContext context) {
    final favStations =
        stations.where((s) => favorites.contains(s['title'])).toList();

    if (favStations.isEmpty) {
      return const Center(
        child: Text(
          "No favorites yet.",
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 16, left: 16, right: 16),
      itemCount: favStations.length,
      itemBuilder: (context, index) {
        final station = favStations[index];
        return _buildStationTile(context, station);
      },
    );
  }

  Widget _buildStationTile(BuildContext context, Map<String, String> station) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          station['image']!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder:
              (context, error, stackTrace) => Container(
                color: Colors.grey[800],
                width: 60,
                height: 60,
                child: const Icon(
                  Icons.image_not_supported,
                  color: Colors.white54,
                ),
              ),
        ),
      ),
      title: Text(
        station['title']!,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        station['subtitle']!,
        style: const TextStyle(color: Colors.white54),
      ),
      trailing: IconButton(
        icon: Icon(
          isFavorite(station['title']!)
              ? Icons.favorite
              : Icons.favorite_border,
          color: isFavorite(station['title']!) ? Colors.red : Colors.white54,
        ),
        onPressed: () => toggleFavorite(station['title']!),
      ),
      onTap: () {
        final originalIndex = stations.indexOf(station);
        updateMiniPlayerInfo(originalIndex);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StationDetailScreen(
                  stationList: stations,
                  currentIndex: originalIndex,
                  sharedPlayer: sharedPlayer,
                  onStationChanged: updateMiniPlayerInfo,
                ),
          ),
        );
      },
    );
  }
}
