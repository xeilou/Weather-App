import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'weather_detail_page.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final String apiKey = dotenv.env['WEATHER_API_KEY'] ?? "";

  Map<String, dynamic>? _weatherData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadLastCity();
  }

  Future<void> _loadLastCity() async {
    final prefs = await SharedPreferences.getInstance();
    String? lastCity = prefs.getString('last_city');

    _fetchWeather(lastCity ?? "Manila");
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions are denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions are permanently denied.');
      }

      Position position = await Geolocator.getCurrentPosition();

      String coordString = "${position.latitude},${position.longitude}";
      await _fetchWeather(coordString);
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchWeather(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final Uri url = Uri.parse(
        "https://api.weatherapi.com/v1/forecast.json?key=$apiKey&q=$query&days=8&aqi=no&alerts=no",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          _weatherData = data;
          _isLoading = false;
        });

        final prefs = await SharedPreferences.getInstance();
        String locationName = "${data['location']['name']}";
        await prefs.setString('last_city', locationName);
      } else {
        throw Exception("API Error");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Could not find location or connection error.";
        _isLoading = false;
      });
    }
  }

  void _showSearchModal() {
    String? currentLocationId;
    if (_weatherData != null) {
      final loc = _weatherData!['location'];
      currentLocationId = "${loc['name']}, ${loc['region']}, ${loc['country']}";
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SearchModalContent(
          apiKey: apiKey,
          currentLocationId: currentLocationId,
          onCitySelected: (city) {
            _fetchWeather(city);
            Navigator.pop(context);
          },
          onUseCurrentLocation: () {
            Navigator.pop(context);
            _fetchCurrentLocation();
          },
        ),
      ),
    );
  }

  LinearGradient _getWeatherGradient() {
    if (_weatherData == null) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
      );
    }

    final condition = _weatherData!['current']['condition']['text']
        .toLowerCase();
    final isDay = _weatherData!['current']['is_day'] == 1;

    if (condition.contains('sunny') || condition.contains('clear')) {
      return isDay
          ? const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
            )
          : const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            );
    } else if (condition.contains('cloud')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF757F9A), Color(0xFFD7DDE8)],
      );
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF4A5568), Color(0xFF2D3748)],
      );
    } else if (condition.contains('thunder') || condition.contains('storm')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C3E50), Color(0xFF4A5568)],
      );
    } else if (condition.contains('snow')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE0EAFC), Color(0xFFCFDEF3)],
      );
    } else if (condition.contains('mist') || condition.contains('fog')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF606c88), Color(0xFF3f4c6b)],
      );
    }

    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF1e3c72), Color(0xFF2a5298)],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _getWeatherGradient()),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.white,
                        size: 64,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _fetchWeather("Manila"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withAlpha(20),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text("Retry Default"),
                      ),
                    ],
                  ),
                ),
              )
            : _weatherData == null
            ? const Center(
                child: Text(
                  "Tap the location button to search",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              )
            : _buildWeatherContent(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showSearchModal,
        backgroundColor: Color(0xFF212121),
        child: const Icon(Icons.location_on, color: Colors.white),
      ),
    );
  }

  Widget _buildWeatherContent() {
    final current = _weatherData!['current']; // current weather
    final location = _weatherData!['location'];
    final List allForecastDays = _weatherData!['forecast']['forecastday'];

    final List forecastDays = allForecastDays.length > 1
        ? allForecastDays.sublist(1)
        : [];
    final List displayDays = forecastDays.take(7).toList();
    final List hourly = allForecastDays[0]['hour'];

    String localTime = location['localtime'];
    DateTime parsedTime = DateFormat('yyyy-MM-dd HH:mm').parse(localTime);

    String dateTitle = DateFormat('MMM d').format(parsedTime);

    int currentHourIndex = parsedTime.hour;
    var currentHourData = hourly[currentHourIndex];
    String currentChanceOfRain = "${currentHourData['chance_of_rain']}%";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 20),
        Text( // loc display on top of the home screen
          "${location['name']}, ${location['country']}",
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
          textAlign: TextAlign.center,
        ),
        Text( // status summary beneathe le loc name
          current['condition']['text'],
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white70,
            shadows: [Shadow(color: Colors.black26, blurRadius: 4)],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network("https:${current['condition']['icon']}", scale: 0.6), // cloud icon thing
            Text( // temp stats
              "${current['temp_c'].round()}°C",
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black26, blurRadius: 8)],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.black.withAlpha(80),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn(
                "Humidity",
                "${current['humidity']}%",
                Icons.water_drop,
              ),
              _buildStatColumn("UV Index", "${current['uv']}", Icons.wb_sunny),
              _buildStatColumn(
                "Wind",
                "${current['wind_kph']} km/h",
                Icons.air,
              ), 
              _buildStatColumn(
                "Rain",
                currentChanceOfRain,
                Icons.cloudy_snowing,
              ),
            ],
          ),
        ),
        const SizedBox(height: 25),

        Text(
          "Hourly Forecast ($dateTitle)",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: hourly.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final hour = hourly[index];
              final rawTime = hour['time'];
              final DateTime parsedHour = DateFormat(
                'yyyy-MM-dd HH:mm',
              ).parse(rawTime);
              final String displayTime = DateFormat('h a').format(parsedHour);

              return Container(
                width: 90,
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black.withAlpha(80),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text( // time
                      displayTime,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Image.network( // weather condition icon
                      "https:${hour['condition']['icon']}",
                      width: 32,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      "${hour['temp_c'].round()}°",
                      style: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 5),
                    Row( // percipitatoin
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.water_drop,
                          size: 12,
                          color: Colors.lightBlueAccent,
                        ),
                        Text(
                          "${hour['chance_of_rain']}%",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.lightBlueAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 25),

        Text(
          "Next ${displayDays.length} Days",
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 10),

        ...displayDays.map((dayData) {
          final day = dayData['day'];
          final dateStr = dayData['date'];
          final DateTime date = DateTime.parse(dateStr);
          final String dayName = DateFormat('EEEE').format(date);

          return Card(
            color: Colors.black.withAlpha(40),
            margin: const EdgeInsets.only(bottom: 10),
            shape: null,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WeatherDetailPage(
                      dayData: dayData,
                      locationName: location['name'],
                    ),
                  ),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  child: Row( // 7-day foercast card stuff
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Image.network(
                        "https:${day['condition']['icon']}",
                        width: 40,
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              dayName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              day['condition']['text'],
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: 65,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.water_drop,
                              size: 14,
                              color: Colors.lightBlueAccent,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                "${day['daily_chance_of_rain']}%",
                                style: const TextStyle(
                                  color: Colors.lightBlueAccent,
                                  fontSize: 12,
                                  height: 1.1,
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),

                      Text(
                        "${day['maxtemp_c'].round()}° / ${day['mintemp_c'].round()}°",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),

                      const Icon(
                        Icons.arrow_forward_ios,
                        size: 14,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStatColumn(String label, String value, IconData icon) { // to make that stat row up top
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

class SearchModalContent extends StatefulWidget {
  final String apiKey;
  final Function(String) onCitySelected;
  final VoidCallback onUseCurrentLocation;
  final String? currentLocationId;

  const SearchModalContent({
    super.key,
    required this.apiKey,
    required this.onCitySelected,
    required this.onUseCurrentLocation,
    this.currentLocationId,
  });

  @override
  State<SearchModalContent> createState() => _SearchModalContentState();
}

class _SearchModalContentState extends State<SearchModalContent> {
  final TextEditingController _searchController = TextEditingController();
  List<dynamic> _searchResults = [];
  bool _isSearching = false;

  List<String> _pinnedCities = [];

  @override
  void initState() {
    super.initState();
    _loadPinnedCities();
  }

  Future<void> _loadPinnedCities() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pinnedCities = prefs.getStringList('pinned_cities') ?? [];
    });
  }

  Future<void> _togglePin(String uniqueCityId) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_pinnedCities.contains(uniqueCityId)) {
        _pinnedCities.remove(uniqueCityId);
      } else {
        _pinnedCities.add(uniqueCityId);
      }
    });
    await prefs.setStringList('pinned_cities', _pinnedCities);
  }

  Future<void> _searchCities(String query) async {
    if (query.length < 3) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        "https://api.weatherapi.com/v1/search.json?key=${widget.apiKey}&q=$query",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _searchResults = data.take(5).toList();
        });
      }
    } catch (e) {
      debugPrint("Search error: $e");
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 500,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            "Find Location",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Search",
              filled: true,
              fillColor: Colors.grey[800],
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            onChanged: (val) {
              _searchCities(val);
            },
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _searchController.text.isEmpty
                ? _buildPinnedList()
                : _buildSearchResults(),
          ),
        ],
      ),
    );
  }

  Widget _buildPinnedList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.my_location, color: Colors.greenAccent),
            title: const Text(
              "Use My Current Location",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.greenAccent,
              ),
            ),
            onTap: widget.onUseCurrentLocation,
          ),
          const Divider(height: 10, thickness: 0.5),

          if (widget.currentLocationId != null) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text("Current View", style: TextStyle(color: Colors.grey)),
            ),
            _buildCurrentLocationTile(),
            const Divider(height: 20, thickness: 0.5),
          ],

          if (_pinnedCities.isNotEmpty) ...[
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "Saved Locations",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _pinnedCities.length,
              separatorBuilder: (ctx, i) => const Divider(height: 1),
              itemBuilder: (ctx, i) {
                final fullLocationString = _pinnedCities[i];
                final parts = fullLocationString.split(', ');
                final cityName = parts.isNotEmpty
                    ? parts[0]
                    : fullLocationString;
                final subTitle = parts.length > 1
                    ? parts.sublist(1).join(', ')
                    : '';

                return ListTile(
                  leading: const Icon(Icons.bookmark, color: Colors.yellow),
                  title: Text(
                    cityName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: subTitle.isNotEmpty ? Text(subTitle) : null,
                  trailing: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => _togglePin(fullLocationString),
                  ),
                  onTap: () => widget.onCitySelected(fullLocationString),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCurrentLocationTile() {
    final fullLocationString = widget.currentLocationId!;
    final parts = fullLocationString.split(', ');
    final cityName = parts.isNotEmpty ? parts[0] : fullLocationString;
    final subTitle = parts.length > 1 ? parts.sublist(1).join(', ') : '';

    final isPinned = _pinnedCities.contains(fullLocationString);

    return ListTile(
      leading: const Icon(Icons.map, color: Colors.blueAccent),
      title: Text(
        cityName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subTitle),
      trailing: IconButton(
        icon: Icon(
          isPinned ? Icons.bookmark : Icons.bookmark_border,
          color: isPinned ? Colors.yellow : Colors.grey,
        ),
        onPressed: () => _togglePin(fullLocationString),
      ),
      onTap: () {
        Navigator.pop(context);
      },
    );
  }

  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchResults.isEmpty) {
      return const Center(child: Text("No results found"));
    }

    return ListView.separated(
      itemCount: _searchResults.length,
      separatorBuilder: (ctx, i) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final result = _searchResults[i];
        final name = result['name'];
        final region = result['region'] ?? '';
        final country = result['country'] ?? '';
        final String uniqueId = "$name, $region, $country";
        final isPinned = _pinnedCities.contains(uniqueId);

        return ListTile(
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text("$region, $country"),
          trailing: IconButton(
            icon: Icon(
              isPinned ? Icons.bookmark : Icons.bookmark_border,
              color: isPinned ? Colors.yellow : Colors.grey,
            ),
            onPressed: () => _togglePin(uniqueId),
          ),
          onTap: () {
            widget.onCitySelected(uniqueId);
          },
        );
      },
    );
  }
}
