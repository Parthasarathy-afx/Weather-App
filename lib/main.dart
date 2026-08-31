import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

void main() {
  runApp(const VarshAura());
}

class VarshAura extends StatelessWidget {
  const VarshAura({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "VarshAura",
      theme: ThemeData(
        useMaterial3: true,
      ),
      home: const WeatherHomePage(),
    );
  }
}

class WeatherHomePage extends StatefulWidget {
  const WeatherHomePage({super.key});

  @override
  State<WeatherHomePage> createState() => _WeatherHomePageState();
}

class _WeatherHomePageState extends State<WeatherHomePage> {
  final TextEditingController searchController = TextEditingController();

  String city = "Loading...";
  double temp = 0;
  String condition = "";
  int humidity = 0;
  double wind = 0;

  List forecast = [];

  bool loading = true;

  //  OPENWEATHER API KEY
  final String apiKey = "551ddea90fe1cb6729e9dfe1b7be14b1";

  @override
  void initState() {
    super.initState();

    getLocationWeather();
  }

  //  GET LIVE LOCATION WEATHER
  Future<void> getLocationWeather() async {
    try {
      bool serviceEnabled;
      LocationPermission permission;

      serviceEnabled = await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        searchWeather("Coimbatore");
        return;
      }

      permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        searchWeather("Coimbatore");
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      await getWeather(
        position.latitude,
        position.longitude,
      );
    } catch (e) {
      print(e);

      searchWeather("Coimbatore");
    }
  }

  // 🌦 GET WEATHER
  Future<void> getWeather(double lat, double lon) async {
    try {
      final url =
          "https://api.openweathermap.org/data/2.5/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          if (city == "Loading..." || city.isEmpty) {
            city = data['city']['name'];
          }

          temp = data['list'][0]['main']['temp'].toDouble();

          condition = data['list'][0]['weather'][0]['main'];

          humidity = data['list'][0]['main']['humidity'];

          wind = data['list'][0]['wind']['speed'].toDouble();

          forecast = data['list'];

          loading = false;
        });
      } else {
        setState(() {
          loading = false;
        });
      }
    } catch (e) {
      print(e);

      setState(() {
        loading = false;
      });
    }
  }

  // 🔍 SEARCH WEATHER + AUTO DETECT
  Future<void> searchWeather(String cityName) async {
    try {
      cityName = cityName.trim();

      if (cityName.isEmpty) return;

      setState(() {
        loading = true;
      });

      final geoUrl =
          "https://api.openweathermap.org/geo/1.0/direct?q=${Uri.encodeComponent(cityName)}&limit=10&appid=$apiKey";

      final geoRes = await http.get(Uri.parse(geoUrl));

      final geoData = jsonDecode(geoRes.body);

      // ❌ CITY NOT FOUND
      if (geoData.isEmpty) {
        setState(() {
          loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("\"$cityName\" not found"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );

        return;
      }

      // ✅ BEST MATCH
      double lat = geoData[0]['lat'];
      double lon = geoData[0]['lon'];

      String cityResult = geoData[0]['name'];
      String? state = geoData[0]['state'];
      String country = geoData[0]['country'];

      city = state != null && state.isNotEmpty
          ? "$cityResult, $state"
          : "$cityResult, $country";

      await getWeather(lat, lon);
    } catch (e) {
      print(e);

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Something went wrong"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  //  DYNAMIC COLOR
  Color getThemeColor() {
    if (condition.contains("Rain")) {
      return Colors.blueAccent;
    } else if (condition.contains("Cloud")) {
      return Colors.blueGrey;
    } else if (condition.contains("Clear")) {
      return Colors.orangeAccent;
    } else {
      return Colors.deepPurple;
    }
  }

  //  WEATHER ICON
  IconData getWeatherIcon() {
    if (condition.contains("Rain")) {
      return Icons.thunderstorm;
    } else if (condition.contains("Cloud")) {
      return Icons.cloud;
    } else if (condition.contains("Clear")) {
      return Icons.wb_sunny;
    } else {
      return Icons.cloud_queue;
    }
  }

  @override
  Widget build(BuildContext context) {
    Color themeColor = getThemeColor();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: const Text(
          "VarshAura",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 28,
            letterSpacing: 1,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              themeColor.withOpacity(0.9),
              themeColor.withOpacity(0.5),
              Colors.black87,
            ],
          ),
        ),
        child: loading
            ? const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              )
            : forecast.isEmpty
                ? const Center(
                    child: Text(
                      "No Weather Data",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                      ),
                    ),
                  )
                : SafeArea(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        bool isWeb = constraints.maxWidth > 700;

                        return SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Center(
                            child: SizedBox(
                              width: isWeb ? 700 : double.infinity,
                              child: Column(
                                children: [
                                  const SizedBox(height: 20),

                                  // 🔍 SEARCH BOX
                                  GlassCard(
                                    child: TextField(
                                      controller: searchController,
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                      onSubmitted: (value) {
                                        searchWeather(value);
                                      },
                                      decoration: InputDecoration(
                                        hintText: "Search city...",
                                        hintStyle: const TextStyle(
                                          color: Colors.white70,
                                        ),
                                        filled: true,
                                        fillColor:
                                            Colors.white.withOpacity(0.05),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          vertical: 18,
                                        ),
                                        prefixIcon: const Icon(
                                          Icons.search,
                                          color: Colors.white,
                                        ),
                                        suffixIcon: IconButton(
                                          icon: const Icon(
                                            Icons.send,
                                            color: Colors.white,
                                          ),
                                          onPressed: () {
                                            if (searchController.text
                                                .trim()
                                                .isNotEmpty) {
                                              searchWeather(
                                                searchController.text.trim(),
                                              );
                                            }
                                          },
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(25),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 30),

                                  // 🌦 MAIN WEATHER CARD
                                  GlassCard(
                                    child: Column(
                                      children: [
                                        Text(
                                          city,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 20),
                                        Icon(
                                          getWeatherIcon(),
                                          size: 120,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          "${temp.toStringAsFixed(1)}°C",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 72,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1,
                                          ),
                                        ),
                                        Text(
                                          condition,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  const SizedBox(height: 25),

                                  // 📊 INFO GRID
                                  GridView.count(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    crossAxisCount: isWeb ? 3 : 2,
                                    crossAxisSpacing: 15,
                                    mainAxisSpacing: 15,
                                    childAspectRatio: 1.3,
                                    children: [
                                      infoCard(
                                        "Humidity",
                                        "$humidity%",
                                        Icons.water_drop,
                                      ),
                                      infoCard(
                                        "Wind",
                                        "$wind km/h",
                                        Icons.air,
                                      ),
                                      infoCard(
                                        "Condition",
                                        condition,
                                        Icons.cloud,
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 30),

                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      "5 Day Forecast",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  // 📅 FORECAST
                                  SizedBox(
                                    height: 210,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 5,
                                      itemBuilder: (context, index) {
                                        int dataIndex = index * 8;

                                        if (dataIndex >= forecast.length) {
                                          return const SizedBox();
                                        }

                                        final item = forecast[dataIndex];

                                        final date = DateFormat('EEE').format(
                                          DateTime.parse(item['dt_txt']),
                                        );

                                        final t = item['main']['temp']
                                            .toStringAsFixed(1);

                                        final c = item['weather'][0]['main'];

                                        return Container(
                                          width: 140,
                                          margin: const EdgeInsets.only(
                                            right: 15,
                                          ),
                                          child: GlassCard(
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  date,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                const Icon(
                                                  Icons.cloud,
                                                  color: Colors.white,
                                                  size: 45,
                                                ),
                                                const SizedBox(height: 10),
                                                Text(
                                                  "$t°C",
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 28,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  c,
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  // 📦 INFO CARD
  Widget infoCard(
    String title,
    String value,
    IconData icon,
  ) {
    return GlassCard(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 40,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// ✨ GLASS CARD
class GlassCard extends StatelessWidget {
  final Widget child;

  const GlassCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 15,
          sigmaY: 15,
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.white.withOpacity(0.10),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
