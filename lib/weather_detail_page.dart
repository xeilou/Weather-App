import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class WeatherDetailPage extends StatelessWidget {
  final Map<String, dynamic> dayData;
  final String locationName;

  const WeatherDetailPage({
    super.key,
    required this.dayData,
    required this.locationName,
  });

  LinearGradient _getWeatherGradient() {
    final day = dayData['day'];
    final condition = day['condition']['text'].toLowerCase();

    if (condition.contains('sunny') || condition.contains('clear')) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
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
    final day = dayData['day'];
    final dateStr = dayData['date'];
    final DateTime date = DateTime.parse(dateStr);
    final String fullDate = DateFormat('EEEE, MMMM d').format(date);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: _getWeatherGradient()),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        locationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text(
                        fullDate,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Image.network(
                        "https:${day['condition']['icon']}",
                        scale: 0.5,
                      ),
                      Text(
                        "${day['avgtemp_c'].round()}°C",
                        style: const TextStyle(
                          fontSize: 60,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 8),
                          ],
                        ),
                      ),
                      Text(
                        day['condition']['text'],
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.white70,
                          shadows: [
                            Shadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),

                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 600),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(80),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(
                              children: [
                                _detailRow(
                                  "Max Temp",
                                  "${day['maxtemp_c']}°C",
                                  Icons.thermostat,
                                  Colors.white,
                                ),
                                Divider(color: Colors.white.withAlpha(30)),
                                _detailRow(
                                  "Min Temp",
                                  "${day['mintemp_c']}°C",
                                  Icons.ac_unit,
                                  Colors.white,
                                ),
                                Divider(color: Colors.white.withAlpha(30)),
                                _detailRow(
                                  "Chance of Rain",
                                  "${day['daily_chance_of_rain']}%",
                                  Icons.water_drop,
                                  Colors.white,
                                ),
                                Divider(color: Colors.white.withAlpha(30)),
                                _detailRow(
                                  "UV Index",
                                  "${day['uv']}",
                                  Icons.wb_sunny,
                                  Colors.white,
                                ),
                                Divider(color: Colors.white.withAlpha(30)),
                                _detailRow(
                                  "Max Wind",
                                  "${day['maxwind_kph']} km/h",
                                  Icons.air,
                                  Colors.white,
                                ),
                                Divider(color: Colors.white.withAlpha(30)),
                                _detailRow(
                                  "Humidity",
                                  "${day['avghumidity']}%",
                                  Icons.opacity,
                                  Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
