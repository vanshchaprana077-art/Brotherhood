/// App-wide constants — single source of truth for challenge timing and
/// the admin panel password.
class AppConstants {
  AppConstants._();

  /// The challenge officially begins on this date. Day counters, streaks,
  /// and the calendar/history range all start here.
  static final DateTime challengeStart = DateTime(2026, 7, 13);

  /// Total length of the challenge in days. Used to compute "Days Remaining"
  /// on the home dashboard.
  static const int challengeDurationDays = 100;

  /// Password required to open the hidden Admin Panel. Anyone who knows it
  /// can view admin data — it is not tied to a specific member identity.
  static const String adminPassword = 'vanshwedsmarjan';

  /// Weekly progress photos (front/side/back/face) are due every 7 days
  /// starting from the challenge start date.
  static const int progressPhotoIntervalDays = 7;
}
