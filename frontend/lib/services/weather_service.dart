import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_model.dart';

class WeatherService {
  static const String _apiKey = 'bd5e378503939ddaee76f12ad7a97608'; // Free API key
  static const String _baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Belize coordinates - targeting Belize City as the main city
  static const double _belizeLat = 17.5045;
  static const double _belizeLon = -88.1962;

  Future<WeatherData> getCurrentWeather() async {
    try {
      final url = '$_baseUrl/weather?lat=$_belizeLat&lon=$_belizeLon&appid=$_apiKey&units=metric';

      print('WeatherService: Fetching weather from $url');

      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 10),
      );

      print('WeatherService: Response status: ${response.statusCode}');
      print('WeatherService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to fetch weather data: ${response.statusCode}');
      }
    } catch (e) {
      print('WeatherService: Error fetching weather: $e');
      // Return fallback weather data for Belize
      return WeatherData(
        temperature: 28.0,
        description: 'Sunny',
        icon: '01d',
        cityName: 'Belize City',
        timestamp: DateTime.now(),
      );
    }
  }

  String getWeatherIcon(String iconCode) {
    // Map weather icons to emojis
    switch (iconCode) {
      case '01d':
      case '01n':
        return '☀️';
      case '02d':
      case '02n':
        return '⛅';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
        return '🌦️';
      case '10d':
      case '10n':
        return '🌧️';
      case '11d':
      case '11n':
        return '⛈️';
      case '13d':
      case '13n':
        return '❄️';
      case '50d':
      case '50n':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  String getTimeOfDay() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }

  String getFormattedTime() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);

    return '${displayHour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $period';
  }

  String getStudyMotivation(String weather) {
    switch (weather.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return 'Beautiful day! Great for outdoor study sessions.';
      case 'rain':
      case 'drizzle':
        return 'Perfect weather for indoor studying with some coffee!';
      case 'clouds':
      case 'cloudy':
        return 'Nice and cool - ideal for focused study time.';
      case 'thunderstorm':
        return 'Cozy weather for deep focus and concentration.';
      default:
        return 'Another great day to learn something new!';
    }
  }
}
