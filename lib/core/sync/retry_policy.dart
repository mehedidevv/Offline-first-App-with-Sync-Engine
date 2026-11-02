import 'dart:math';

class RetryPolicy {
  static const int maxRetries = 5;
  static const Duration baseDelay = Duration(seconds: 2);
  static const Duration maxDelay = Duration(minutes: 5);

  static DateTime calculateNextRetryTime(int retryCount) {
    if (retryCount >= maxRetries) {
      // Dead letter or maximum backoff reached
      return DateTime.now().add(maxDelay);
    }

    // Exponential backoff: baseDelay * 2^retryCount
    final exponentialSeconds = baseDelay.inSeconds * pow(2, retryCount).toDouble();
    
    // Add random jitter (±20%)
    final random = Random();
    final jitterFactor = 0.8 + (random.nextDouble() * 0.4); // between 0.8 and 1.2
    final delaySeconds = (exponentialSeconds * jitterFactor).clamp(1.0, maxDelay.inSeconds.toDouble());

    return DateTime.now().add(Duration(seconds: delaySeconds.toInt()));
  }

  static bool shouldRetry(int retryCount, dynamic error) {
    if (retryCount >= maxRetries) return false;

    // Do not retry permanent client errors (HTTP 400, 401, 403, 404, etc.) except 429
    if (error.toString().contains('HTTP_400') ||
        error.toString().contains('AUTH_ERROR') ||
        error.toString().contains('HTTP_403') ||
        error.toString().contains('HTTP_404')) {
      return false;
    }

    return true;
  }
}
