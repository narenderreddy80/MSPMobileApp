import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

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
}

class DailyForecast {
  final String date;       // "2025-03-22"
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
}

class WeatherData {
  final double latitude;
  final double longitude;
  final String locationName;
  final CurrentWeather current;
  final List<DailyForecast> daily;
  final double soilTemperature;   // °C at 0 cm
  final double soilMoisture;      // m³/m³ — 0 to ~0.5

  const WeatherData({
    required this.latitude,
    required this.longitude,
    required this.locationName,
    required this.current,
    required this.daily,
    required this.soilTemperature,
    required this.soilMoisture,
  });
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

// Default location: Hyderabad (used when GPS is unavailable)
const _defaultLat = 17.385;
const _defaultLon = 78.4867;
const _defaultLocationName = 'Hyderabad, Telangana';

class WeatherService {
  final _dio = Dio();

  /// Try to get GPS position; returns null if unavailable (no throw).
  Future<({double lat, double lon, String name})?> _tryGetLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

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
      return (lat: pos.latitude, lon: pos.longitude, name: '');
    } catch (_) {
      return null;
    }
  }

  /// Reverse geocode lat/lon to a human-readable name via Nominatim.
  Future<String> _getLocationName(double lat, double lon) async {
    try {
      final res = await _dio.get(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {'lat': lat, 'lon': lon, 'format': 'json'},
        options: Options(headers: {'User-Agent': 'MSPFarmersApp/1.0'}),
      );
      final addr = res.data['address'] as Map<String, dynamic>;
      final city = addr['city'] ?? addr['town'] ?? addr['village'] ??
                   addr['county'] ?? addr['state_district'] ?? '';
      final state = addr['state'] ?? '';
      if (city.isNotEmpty && state.isNotEmpty) return '$city, $state';
      if (state.isNotEmpty) return state;
      return 'Your Location';
    } catch (_) {
      return 'Your Location';
    }
  }

  /// Fetch full weather data. Falls back to Hyderabad if GPS unavailable.
  Future<WeatherData> fetchWeather() async {
    final gps = await _tryGetLocation();

    final double lat;
    final double lon;
    final String locationName;

    if (gps != null) {
      lat = gps.lat;
      lon = gps.lon;
      locationName = await _getLocationName(lat, lon);
    } else {
      lat = _defaultLat;
      lon = _defaultLon;
      locationName = _defaultLocationName;
    }

    final weatherRes = await _dio.get(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': lat,
        'longitude': lon,
        'current': 'temperature_2m,relative_humidity_2m,apparent_temperature,'
            'precipitation,weather_code,wind_speed_10m,wind_direction_10m,uv_index',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min,'
            'precipitation_sum,precipitation_probability_max',
        'hourly': 'soil_temperature_0cm,soil_moisture_0_to_1cm',
        'timezone': 'auto',
        'forecast_days': 7,
        'wind_speed_unit': 'kmh',
      },
    );

    final data = weatherRes.data as Map<String, dynamic>;
    final cur = data['current'] as Map<String, dynamic>;
    final daily = data['daily'] as Map<String, dynamic>;
    final hourly = data['hourly'] as Map<String, dynamic>;

    final current = CurrentWeather(
      temperature:   (cur['temperature_2m']    as num).toDouble(),
      feelsLike:     (cur['apparent_temperature'] as num).toDouble(),
      humidity:      (cur['relative_humidity_2m'] as num).toDouble(),
      windSpeed:     (cur['wind_speed_10m']     as num).toDouble(),
      windDirection: (cur['wind_direction_10m'] as num).toDouble(),
      weatherCode:   (cur['weather_code']       as num).toInt(),
      precipitation: (cur['precipitation']      as num).toDouble(),
      uvIndex:       (cur['uv_index']           as num).toDouble(),
    );

    final dates  = daily['time']                        as List<dynamic>;
    final codes  = daily['weather_code']                as List<dynamic>;
    final maxT   = daily['temperature_2m_max']          as List<dynamic>;
    final minT   = daily['temperature_2m_min']          as List<dynamic>;
    final precip = daily['precipitation_sum']           as List<dynamic>;
    final prob   = daily['precipitation_probability_max'] as List<dynamic>;

    final forecasts = List.generate(dates.length, (i) => DailyForecast(
      date: dates[i] as String,
      weatherCode: (codes[i] as num).toInt(),
      tempMax: (maxT[i] as num).toDouble(),
      tempMin: (minT[i] as num).toDouble(),
      precipitationSum: ((precip[i] ?? 0.0) as num).toDouble(),
      precipitationProbability: ((prob[i] ?? 0) as num).toInt(),
    ));

    // Take first non-null hourly soil reading
    final soilTemps     = hourly['soil_temperature_0cm'] as List<dynamic>;
    final soilMoistures = hourly['soil_moisture_0_to_1cm'] as List<dynamic>;
    final soilTemp = soilTemps.firstWhere((v) => v != null, orElse: () => 25.0);
    final soilMois = soilMoistures.firstWhere((v) => v != null, orElse: () => 0.25);

    return WeatherData(
      latitude: lat,
      longitude: lon,
      locationName: locationName,
      current: current,
      daily: forecasts,
      soilTemperature: (soilTemp as num).toDouble(),
      soilMoisture: (soilMois as num).toDouble(),
    );
  }
}
