import 'package:geolocator/geolocator.dart';
import 'api_client.dart';

// ── DTOs ─────────────────────────────────────────────────────────────────────

class CurrentWeather {
  final double temperature;
  final double feelsLike;
  final double humidity;
  final double windSpeed;
  final double windDirection;
  final int weatherCode;
  final double precipitation;
  final double uvIndex;

  const CurrentWeather({
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.windDirection,
    required this.weatherCode,
    required this.precipitation,
    required this.uvIndex,
  });

  factory CurrentWeather.fromJson(Map<String, dynamic> j) => CurrentWeather(
    temperature:   (j['temperature']   as num).toDouble(),
    feelsLike:     (j['feelsLike']     as num).toDouble(),
    humidity:      (j['humidity']      as num).toDouble(),
    windSpeed:     (j['windSpeed']     as num).toDouble(),
    windDirection: (j['windDirection'] as num).toDouble(),
    weatherCode:   (j['weatherCode']   as num).toInt(),
    precipitation: (j['precipitation'] as num).toDouble(),
    uvIndex:       (j['uvIndex']       as num).toDouble(),
  );
}

class DailyForecast {
  final String date;
  final int weatherCode;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;
  final int precipitationProbability;

  const DailyForecast({
    required this.date,
    required this.weatherCode,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.precipitationProbability,
  });

  factory DailyForecast.fromJson(Map<String, dynamic> j) => DailyForecast(
    date:                    j['date'] as String,
    weatherCode:             (j['weatherCode']              as num).toInt(),
    tempMax:                 (j['tempMax']                  as num).toDouble(),
    tempMin:                 (j['tempMin']                  as num).toDouble(),
    precipitationSum:        (j['precipitationSum']         as num).toDouble(),
    precipitationProbability:(j['precipitationProbability'] as num).toInt(),
  );
}

class WeatherData {
  final double latitude;
  final double longitude;
  final String locationName;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final double soilTemperature;
  final double soilMoisture;

  const WeatherData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.current,
    required this.daily,
    required this.soilTemperature,
    required this.soilMoisture,
  });

  factory WeatherData.fromJson(Map<String, dynamic> j) => WeatherData(
    latitude:        (j['latitude']  as num).toDouble(),
    longitude:       (j['longitude'] as num).toDouble(),
    locationName:    j['locationName'] as String,
    current:         CurrentWeather.fromJson(j['current'] as Map<String, dynamic>),
    daily:           (j['daily'] as List<dynamic>)
                       .map((e) => DailyForecast.fromJson(e as Map<String, dynamic>))
                       .toList(),
    soilTemperature: (j['soilTemperature'] as num).toDouble(),
    soilMoisture:    (j['soilMoisture']    as num).toDouble(),
  );
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String weatherDescription(int code) {
  if (code == 0) return 'Clear Sky';
  if (code == 1) return 'Mainly Clear';
  if (code == 2) return 'Partly Cloudy';
  if (code == 3) return 'Overcast';
  if (code <= 48) return 'Foggy';
  if (code <= 55) return 'Drizzle';
  if (code <= 65) return 'Rain';
  if (code <= 67) return 'Freezing Rain';
  if (code <= 75) return 'Snow';
  if (code <= 82) return 'Rain Showers';
  if (code <= 86) return 'Snow Showers';
  if (code == 95) return 'Thunderstorm';
  return 'Thunderstorm';
}

String weatherEmoji(int code) {
  if (code == 0) return '☀️';
  if (code <= 2) return '⛅';
  if (code == 3) return '☁️';
  if (code <= 48) return '🌫️';
  if (code <= 55) return '🌦️';
  if (code <= 65) return '🌧️';
  if (code <= 75) return '❄️';
  if (code <= 82) return '🌦️';
  if (code == 95) return '⛈️';
  return '⛈️';
}

/// Generate farming-specific advisories from real weather data.
List<(String, bool)> farmingAdvisories(WeatherData w) {
  final c = w.current;
  final tomorrow = w.daily.isNotEmpty ? w.daily[0] : null;
  final advisories = <(String, bool)>[];

  final rainProb = tomorrow?.precipitationProbability ?? 0;
  if (rainProb >= 70) {
    advisories.add(('Rain expected ($rainProb% chance) — avoid pesticide/fertiliser spraying.', false));
  } else if (rainProb >= 40) {
    advisories.add(('Moderate rain chance ($rainProb%) — plan field work for the morning.', true));
  }

  if (c.windSpeed >= 20) {
    advisories.add(('High winds (${c.windSpeed.toStringAsFixed(0)} km/h) — avoid spraying operations.', false));
  } else if (c.windSpeed <= 10) {
    advisories.add(('Calm winds — good conditions for pesticide/fungicide spraying.', true));
  }

  if (c.uvIndex >= 8) {
    advisories.add(('Very high UV (${c.uvIndex.toStringAsFixed(0)}) — avoid fieldwork between 11 am–3 pm.', false));
  }

  if (c.temperature >= 38) {
    advisories.add(('Extreme heat (${c.temperature.toStringAsFixed(0)}°C) — irrigate crops early morning or evening.', false));
  } else if (c.temperature >= 30 && c.humidity < 40) {
    advisories.add(('Hot and dry — monitor crop water stress, consider irrigation.', false));
  }

  if (w.soilMoisture < 0.15) {
    advisories.add(('Low soil moisture — irrigation recommended for standing crops.', false));
  } else if (w.soilMoisture >= 0.30) {
    advisories.add(('Good soil moisture levels — suitable for sowing and transplanting.', true));
  }

  if (c.precipitation == 0 && rainProb < 30 && c.humidity > 80) {
    advisories.add(('High humidity with no rain — watch for fungal disease in crops.', false));
  }

  if (advisories.isEmpty) {
    advisories.add(('Weather conditions look favourable for general farm operations today.', true));
  }

  return advisories;
}

// ── Service ───────────────────────────────────────────────────────────────────

// Default location: Hyderabad, Telangana
const _defaultLat = 17.385;
const _defaultLon = 78.4867;

class WeatherService {
  final _client = ApiClient();

  /// Try to get GPS position; returns null silently if unavailable.
  Future<({double lat, double lon})?> _tryGetLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) { return null; }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) { return null; }

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
          timeLimit: Duration(seconds: 12),
        ),
      );
      return (lat: pos.latitude, lon: pos.longitude);
    } catch (_) {
      return null;
    }
  }

  /// Fetch weather via the REST API, which proxies Open-Meteo server-side.
  Future<WeatherData> fetchWeather() async {
    final gps = await _tryGetLocation();
    final lat = gps?.lat ?? _defaultLat;
    final lon = gps?.lon ?? _defaultLon;

    final res = await _client.dio.get(
      '/api/Weather',
      queryParameters: {'lat': lat, 'lon': lon},
    );

    return WeatherData.fromJson(res.data as Map<String, dynamic>);
  }
}
