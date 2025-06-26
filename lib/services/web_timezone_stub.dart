/// Web platform stub for timezone functionality
/// This provides mock implementations for web platform compatibility

class TZDateTime extends DateTime {
  TZDateTime(
    int year, [
    int month = 1,
    int day = 1,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
  ]) : super(year, month, day, hour, minute, second, millisecond, microsecond);

  static TZDateTime now(Location location) {
    return TZDateTime.from(DateTime.now(), location);
  }
  
  static TZDateTime from(DateTime dateTime, Location location) {
    return TZDateTime(
      dateTime.year,
      dateTime.month,
      dateTime.day,
      dateTime.hour,
      dateTime.minute,
      dateTime.second,
      dateTime.millisecond,
      dateTime.microsecond,
    );
  }
}

Location get local => Location._('local');

Location getLocation(String locationName) {
  return Location._(locationName);
}

class Location {
  final String name;
  
  Location._(this.name);
}

// Mock timezone initialization
void initializeTimeZones() {
  // No-op for web
}