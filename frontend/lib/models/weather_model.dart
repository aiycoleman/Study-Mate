class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final String cityName;
  final DateTime timestamp;

  const WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.cityName,
    required this.timestamp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['main'] as String,
      icon: json['weather'][0]['icon'] as String,
      cityName: json['name'] as String,
      timestamp: DateTime.now(),
    );
  }
}
