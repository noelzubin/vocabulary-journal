class Sm {
  SmResponse calc(int quality, int repetitions, int previousInterval,
      double previousEaseFactor) {
    int interval;
    double easeFactor;
    if (quality >= 3) {
      switch (repetitions) {
        case 0:
          interval = 1;
          break;
        case 1:
          interval = 6;
          break;
        default:
          interval = (previousInterval * previousEaseFactor).round();
      }

      repetitions++;
      easeFactor = previousEaseFactor +
          (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02));
    } else {
      repetitions = 0;
      interval = 1;
      easeFactor = previousEaseFactor;
    }

    if (easeFactor < 1.3) {
      easeFactor = 1.3;
    }

    return SmResponse(interval, repetitions, easeFactor);
  }
}

class SmResponse {
  final int interval;
  final int repetitions;
  final double easeFactor;

  SmResponse(this.interval, this.repetitions, this.easeFactor);

  @override
  String toString() {
    return "{interval: $interval, repetitions: $repetitions, easeFactor: $easeFactor}";
  }
}
