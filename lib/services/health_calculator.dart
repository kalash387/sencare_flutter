class HealthCalculator {
  // Define weights for different test types
  static const Map<String, double> testWeights = {
    'Blood Pressure': 0.8,
    'Heart Rate': 0.7,
    'Temperature': 0.6,
    'Respiratory Rate': 0.7,
    'Oxygen Saturation': 0.9,
    'Glucose Level': 0.5,
    'BMI': 0.4,
    'Cholesterol': 0.5,
    'Blood Cell Count': 0.6,
  };

  // Normalize test values to determine if they are in a critical range (1) or normal range (0)
  static double normalizeTestValue(String testType, String value) {
    // Extract numeric value from readings like "120/80 mmHg" -> 120
    String numericPart = value.split(' ')[0];
    if (testType == 'Blood Pressure') {
      // Handle special case for blood pressure with format "120/80 mmHg"
      final parts = numericPart.split('/');
      if (parts.length == 2) {
        final systolic = double.tryParse(parts[0]) ?? 0;
        final diastolic = double.tryParse(parts[1]) ?? 0;
        return (systolic > 140 ||
                systolic < 90 ||
                diastolic > 90 ||
                diastolic < 60)
            ? 1.0
            : 0.0;
      }
    }

    // For other test types, extract numeric value
    double numericValue = 0.0;
    try {
      numericValue =
          double.parse(numericPart.replaceAll(RegExp(r'[^\d.]'), ''));
    } catch (e) {
      return 0.0; // Default to 0 if parsing fails
    }

    switch (testType) {
      case 'Glucose Level':
        return numericValue < 70 || numericValue > 180 ? 1.0 : 0.0;
      case 'Heart Rate':
        return numericValue < 60 || numericValue > 100 ? 1.0 : 0.0;
      case 'Temperature':
        return numericValue < 36.1 || numericValue > 37.5 ? 1.0 : 0.0;
      case 'Respiratory Rate':
        return numericValue < 12 || numericValue > 20 ? 1.0 : 0.0;
      case 'Oxygen Saturation':
        return numericValue < 90 ? 1.0 : 0.0;
      case 'BMI':
        return numericValue < 18.5 || numericValue > 30 ? 1.0 : 0.0;
      case 'Cholesterol':
        return numericValue > 200 ? 1.0 : 0.0;
      case 'Blood Cell Count':
        // Simplified check for demo purposes
        return numericValue < 4000 || numericValue > 11000 ? 1.0 : 0.0;
      default:
        return 0.0;
    }
  }

  // Calculate the weighted health score based on all tests
  static double calculateWeightedScore(List<Map<String, String>> tests) {
    double totalWeight = 0.0;
    double weightedSum = 0.0;

    if (tests.isEmpty) {
      return 0.0;
    }

    for (var test in tests) {
      final testType = test['testType'] ?? '';
      final value = test['reading'] ?? '';
      final weight =
          testWeights[testType] ?? 0.5; // Default weight if not found
      final normalizedScore = normalizeTestValue(testType, value);

      weightedSum += normalizedScore * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.0;
  }

  // Determine the overall condition based on the weighted score or by checking individual conditions
  static String determineOverallCondition(List<Map<String, String>> tests) {
    // First check if any reading has a 'Critical' condition already set
    for (final data in tests) {
      final condition = data['condition'] ?? '';
      if (condition == 'Critical') {
        return 'Critical';
      }
    }

    // If no explicit critical conditions, calculate based on weighted score
    final weightedScore = calculateWeightedScore(tests);
    return weightedScore >= 0.5 ? 'Critical' : 'Normal';
  }

  // Determine condition based on a single test type and reading
  static String determineCondition(String testType, String reading) {
    try {
      switch (testType) {
        case 'Blood Pressure':
          return _analyzeBloodPressure(reading);
        case 'Heart Rate':
          return _analyzeHeartRate(reading);
        case 'Blood Glucose':
          return _analyzeBloodGlucose(reading);
        case 'Cholesterol':
          return _analyzeCholesterol(reading);
        case 'BMI':
          return _analyzeBMI(reading);
        case 'Temperature':
          return _analyzeTemperature(reading);
        case 'Oxygen Saturation':
          return _analyzeOxygenSaturation(reading);
        case 'Respiratory Rate':
          return _analyzeRespiratoryRate(reading);
        default:
          return 'Normal';
      }
    } catch (e) {
      // In case of invalid format or parsing errors, return Normal
      print('Error analyzing $testType reading: $e');
      return 'Normal';
    }
  }

  // Helper methods to analyze specific readings
  static String _analyzeBloodPressure(String reading) {
    // Expected format: "120/80 mmHg"
    final parts = reading.replaceAll(' mmHg', '').split('/');
    if (parts.length != 2) return 'Normal';

    final systolic = int.tryParse(parts[0]) ?? 0;
    final diastolic = int.tryParse(parts[1]) ?? 0;

    if (systolic >= 180 || diastolic >= 120) {
      return 'Critical'; // Hypertensive crisis
    } else if (systolic >= 140 || diastolic >= 90) {
      return 'Critical'; // Stage 2 hypertension
    }

    return 'Normal';
  }

  static String _analyzeHeartRate(String reading) {
    // Expected format: "72 bpm"
    final rate = int.tryParse(reading.replaceAll(' bpm', '')) ?? 0;

    if (rate > 120 || rate < 50) {
      return 'Critical';
    }

    return 'Normal';
  }

  static String _analyzeBloodGlucose(String reading) {
    // Expected format: "100 mg/dL"
    final glucose = int.tryParse(reading.replaceAll(' mg/dL', '')) ?? 0;

    if (glucose > 200 || glucose < 70) {
      return 'Critical';
    }

    return 'Normal';
  }

  static String _analyzeCholesterol(String reading) {
    // Expected format: "200 mg/dL"
    final cholesterol = int.tryParse(reading.replaceAll(' mg/dL', '')) ?? 0;

    if (cholesterol >= 240) {
      return 'Critical';
    }

    return 'Normal';
  }

  static String _analyzeBMI(String reading) {
    // Expected format: "24.5"
    final bmi = double.tryParse(reading) ?? 0;

    if (bmi >= 40 || bmi < 16) {
      return 'Critical';
    }

    return 'Normal';
  }

  static String _analyzeTemperature(String reading) {
    // Expected format: "98.6 °F"
    final temp = double.tryParse(reading.replaceAll(' °F', '')) ?? 0;

    if (temp >= 103 || temp <= 95) {
      return 'Critical';
    }

    return 'Normal';
  }

  static String _analyzeOxygenSaturation(String reading) {
    // Expected format: "98%"
    final saturation = int.tryParse(reading.replaceAll('%', '')) ?? 0;

    if (saturation < 90) {
      return 'Critical';
    }

    return 'Normal';
  }

  static String _analyzeRespiratoryRate(String reading) {
    // Expected format: "16 breaths/min"
    final rate = int.tryParse(reading.replaceAll(' breaths/min', '')) ?? 0;

    if (rate > 30 || rate < 8) {
      return 'Critical';
    }

    return 'Normal';
  }
}
