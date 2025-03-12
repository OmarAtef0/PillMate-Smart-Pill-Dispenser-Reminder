class TimeUtils {
  static DateTime parseDateTime(String dateTimeStr) {
    return DateTime.parse(dateTimeStr);
  }

  static String formatTime(DateTime dateTime) {
    return "${dateTime.hour}:${dateTime.minute}";
  }
}
