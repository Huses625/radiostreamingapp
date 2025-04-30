import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:brigada_radio_streaming/screens/station_detail_screen.dart';
import 'package:marquee/marquee.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isPlaying = false;
  List<Map<String, String>> stations = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchStations();
  }

  Future<void> fetchStations() async {
  try {
    final response = await http.get(
      Uri.parse('https://www.brigadanews.ph/fmstreamv2/assets/stationList.json'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);

      setState(() {
        stations = data.map<Map<String, String>>((item) {
          // Debug log the whole object
          debugPrint('📦 Station: ${jsonEncode(item)}');

          // Warn if shoutcastUrl is missing or empty
          if (item['shoutcastUrl'] == null || item['shoutcastUrl'].toString().isEmpty) {
            debugPrint('⚠️ Missing shoutcastUrl for: ${item['stationName']}');
          }

          return {
            'title': '${item['frequency']} Brigada News FM ${item['stationName']}',
            'subtitle': item['location'] ?? '',
            'image': 'https://brigadanews.ph/fmstreamv2/assets/stationLogo/${item['stationLogo']}.jpg',
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
    debugPrint('❌ Exception: $e');
    setState(() {
      hasError = true;
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
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
            tabs: [Tab(text: 'News FM Stations'), Tab(text: 'Latest News')],
          ),
        ),
        body: Stack(
          children: [
            TabBarView(
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
                const Center(
                  child: Text(
                    "No items yet.",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),

            if (!isLoading && stations.isNotEmpty)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => StationDetailScreen(
                              stationList: stations,
                              currentIndex: 0,
                            ),
                      ),
                    );
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
                            stations[0]['image']!,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stations[0]['title']!,
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
                                  text: stations[0]['subtitle']!,
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
                        IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause_circle : Icons.play_circle,
                            color: Colors.white,
                            size: 32,
                          ),
                          onPressed: () {
                            setState(() {
                              isPlaying = !isPlaying;
                            });
                          },
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
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 16, left: 16, right: 16),
      itemCount: stations.length,
      itemBuilder: (context, index) {
        final station = stations[index];
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
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder:
                    (_) => StationDetailScreen(
                      stationList: stations,
                      currentIndex: index,
                    ),
              ),
            );
          },
        );
      },
    );
  }
}
