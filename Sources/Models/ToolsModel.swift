import AppKit
import CoreAudio
import CoreLocation
import Foundation

@_silgen_name("SLSSetAppearanceThemeLegacy")
func SLSSetAppearanceThemeLegacy(_ theme: Bool)

@_silgen_name("SLSGetAppearanceThemeLegacy")
func SLSGetAppearanceThemeLegacy() -> Bool

@_silgen_name("CoreDisplay_Display_SetUserBrightness")
func CoreDisplay_Display_SetUserBrightness(_ display: Int32, _ brightness: Double) -> Int32

enum ToolsModel {
    static let locationManager = CLLocationManager()

    struct WeatherData: Codable {
        let latitude: Double
        let longitude: Double
        let generationtimeMs: Double
        let utcOffsetSeconds: Int
        let timezone: String
        let timezoneAbbreviation: String
        let elevation: Double
        let currentWeatherUnits: CurrentWeatherUnits
        let currentWeather: CurrentWeather
        let hourlyUnits: HourlyUnits
        let hourly: Hourly
        let dailyUnits: DailyUnits
        let daily: Daily

        enum CodingKeys: String, CodingKey {
            case latitude
            case longitude
            case generationtimeMs = "generationtime_ms"
            case utcOffsetSeconds = "utc_offset_seconds"
            case timezone
            case timezoneAbbreviation = "timezone_abbreviation"
            case elevation
            case currentWeatherUnits = "current_weather_units"
            case currentWeather = "current_weather"
            case hourlyUnits = "hourly_units"
            case hourly
            case dailyUnits = "daily_units"
            case daily
        }

        struct CurrentWeatherUnits: Codable {
            let time: String
            let interval: String
            let temperature: String
            let windspeed: String
            let winddirection: String
            let isDay: String
            let weathercode: String

            enum CodingKeys: String, CodingKey {
                case time
                case interval
                case temperature
                case windspeed
                case winddirection
                case isDay = "is_day"
                case weathercode
            }
        }

        struct CurrentWeather: Codable {
            let time: String
            let interval: Int
            let temperature: Double
            let windspeed: Double
            let winddirection: Double
            let isDay: Int
            let weathercode: Int

            enum CodingKeys: String, CodingKey {
                case time
                case interval
                case temperature
                case windspeed
                case winddirection
                case isDay = "is_day"
                case weathercode
            }
        }

        struct HourlyUnits: Codable {
            let time: String
            let temperature2m: String
            let relativeHumidity2m: String
            let weatherCode: String
            let rain: String
            let showers: String
            let snowfall: String
            let precipitation: String
            let precipitationProbability: String

            enum CodingKeys: String, CodingKey {
                case time
                case temperature2m = "temperature_2m"
                case relativeHumidity2m = "relative_humidity_2m"
                case weatherCode = "weather_code"
                case rain
                case showers
                case snowfall
                case precipitation
                case precipitationProbability = "precipitation_probability"
            }
        }

        struct Hourly: Codable {
            let time: [String]
            let temperature2m: [Double]
            let relativeHumidity2m: [Int]
            let weatherCode: [Int]
            let rain: [Double]
            let showers: [Double]
            let snowfall: [Double]
            let precipitation: [Double]
            let precipitationProbability: [Int]

            enum CodingKeys: String, CodingKey {
                case time
                case temperature2m = "temperature_2m"
                case relativeHumidity2m = "relative_humidity_2m"
                case weatherCode = "weather_code"
                case rain
                case showers
                case snowfall
                case precipitation
                case precipitationProbability = "precipitation_probability"
            }
        }

        struct DailyUnits: Codable {
            let time: String
            let weatherCode: String
            let sunrise: String
            let sunset: String
            let snowfallSum: String
            let showersSum: String
            let rainSum: String
            let temperature2mMax: String
            let uvIndexMax: String
            let uvIndexClearSkyMax: String
            let temperature2mMin: String

            enum CodingKeys: String, CodingKey {
                case time
                case weatherCode = "weather_code"
                case sunrise
                case sunset
                case snowfallSum = "snowfall_sum"
                case showersSum = "showers_sum"
                case rainSum = "rain_sum"
                case temperature2mMax = "temperature_2m_max"
                case uvIndexMax = "uv_index_max"
                case uvIndexClearSkyMax = "uv_index_clear_sky_max"
                case temperature2mMin = "temperature_2m_min"
            }
        }

        struct Daily: Codable {
            let time: [String]
            let weatherCode: [Int]
            let sunrise: [String]
            let sunset: [String]
            let snowfallSum: [Double]
            let showersSum: [Double]
            let rainSum: [Double]
            let temperature2mMax: [Double]
            let uvIndexMax: [Double]
            let uvIndexClearSkyMax: [Double]
            let temperature2mMin: [Double]

            enum CodingKeys: String, CodingKey {
                case time
                case weatherCode = "weather_code"
                case sunrise
                case sunset
                case snowfallSum = "snowfall_sum"
                case showersSum = "showers_sum"
                case rainSum = "rain_sum"
                case temperature2mMax = "temperature_2m_max"
                case uvIndexMax = "uv_index_max"
                case uvIndexClearSkyMax = "uv_index_clear_sky_max"
                case temperature2mMin = "temperature_2m_min"
            }
        }
    }

    public enum LocationPermissionError: String, LocalizedError {
        case denied
        case notDetermined
        case restricted
        case unknownLocation
    }

    public struct CurrentTime: Codable {
        let localTimezone: String
        let localTime: String
        let utcTime: String
    }

    static func setDarkMode(darkMode: Bool?) -> Bool {
        guard let darkMode = darkMode else {
            return toggleDarkMode()
        }

        let currentDarkMode = isDarkMode()
        SLSSetAppearanceThemeLegacy(darkMode)

        return currentDarkMode != darkMode
    }

    static func toggleDarkMode() -> Bool {
        let currentDarkMode = SLSGetAppearanceThemeLegacy()
        SLSSetAppearanceThemeLegacy(!currentDarkMode)

        return !currentDarkMode
    }

    static func isDarkMode() -> Bool {
        return SLSGetAppearanceThemeLegacy()
    }

    static func getCurrentTime() -> CurrentTime {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        let currentDate = Date()

        // Local time
        dateFormatter.timeZone = TimeZone.current
        let localTime = dateFormatter.string(from: currentDate)

        // UTC time
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        let utcTime = dateFormatter.string(from: currentDate)

        return CurrentTime(
            localTimezone: TimeZone.current.identifier,
            localTime: localTime,
            utcTime: utcTime
        )
    }

    static func getSystemVolume() -> Float {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &defaultOutputDeviceID
        )

        var volume = Float32(0)
        propertySize = UInt32(MemoryLayout<Float32>.size)
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )

        AudioObjectGetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            &propertySize,
            &volume
        )

        return volume
    }

    static func setSystemVolume(_ volume: Float) {
        var defaultOutputDeviceID = AudioDeviceID(0)
        var propertySize = UInt32(MemoryLayout<AudioDeviceID>.size)
        var address = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )

        AudioObjectGetPropertyData(
            AudioObjectID(kAudioObjectSystemObject),
            &address,
            0,
            nil,
            &propertySize,
            &defaultOutputDeviceID
        )

        var newVolume = volume
        address = AudioObjectPropertyAddress(
            mSelector: kAudioDevicePropertyVolumeScalar,
            mScope: kAudioDevicePropertyScopeOutput,
            mElement: 0
        )

        AudioObjectSetPropertyData(
            defaultOutputDeviceID,
            &address,
            0,
            nil,
            UInt32(MemoryLayout<Float32>.size),
            &newVolume
        )
    }

    static func requestLocationPermission() async -> CLAuthorizationStatus {
        await withCheckedContinuation { continuation in
            locationManager.requestWhenInUseAuthorization()
            continuation.resume(returning: locationManager.authorizationStatus)
        }
    }

    static func getCurrentLocation() async -> Result<
        (latitude: Double, longitude: Double), LocationPermissionError
    > {
        let status = await requestLocationPermission()

        switch status {
        case .denied:
            return .failure(.denied)
        case .notDetermined:
            return .failure(.notDetermined)
        case .restricted:
            return .failure(.restricted)
        default: ()
        }

        guard let location = locationManager.location else {
            return .failure(.unknownLocation)
        }
        return .success(
            (latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        )
    }

    static func geocodeString(_ string: String) async -> (latitude: Double, longitude: Double)? {
        let geocoder = CLGeocoder()
        let location = try? await geocoder.geocodeAddressString(string)
        guard let location, let location = location.first else {
            return nil
        }
        return (
            latitude: location.location?.coordinate.latitude ?? 0.0,
            longitude: location.location?.coordinate.longitude ?? 0.0
        )
    }

    static func getWeather(latitude: Double, longitude: Double) async -> WeatherData? {
        // Make a request to OpenMeteo API
        let latURLEncoded =
            "\(latitude)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let lonURLEncoded =
            "\(longitude)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""

        let url =
            URL(
                string:
                    "https://api.open-meteo.com/v1/forecast?latitude=\(latURLEncoded)&longitude=\(lonURLEncoded)&current_weather=true&daily=weather_code,sunrise,sunset,snowfall_sum,showers_sum,rain_sum,temperature_2m_max,uv_index_max,uv_index_clear_sky_max,temperature_2m_min&hourly=temperature_2m,relative_humidity_2m,weather_code,rain,showers,snowfall,precipitation,precipitation_probability&current=temperature_2m,relative_humidity_2m,is_day,rain,precipitation,showers,snowfall,weather_code&format=json"
            )!

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let weatherData = try JSONDecoder().decode(WeatherData.self, from: data)
            return weatherData
        } catch {
            print("Error fetching weather data: \(error)")
            return nil
        }
    }

}
