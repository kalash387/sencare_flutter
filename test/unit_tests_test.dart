import 'package:flutter_test/flutter_test.dart';
import 'package:sencare_flutter/models/patient.dart';
import 'package:sencare_flutter/models/clinical_data.dart';
import 'package:sencare_flutter/services/health_calculator.dart';

void main() {
  group('Patient Model Tests', () {
    test('Patient.fromJson should correctly parse patient data', () {
      // Arrange
      final Map<String, dynamic> patientJson = {
        '_id': '123',
        'name': 'John Doe',
        'age': 45,
        'contact': '555-1234',
        'condition': 'Normal'
      };

      // Act
      final patient = Patient.fromJson(patientJson);

      // Assert
      expect(patient.id, '123');
      expect(patient.name, 'John Doe');
      expect(patient.age, '45');
      expect(patient.contact, '555-1234');
      expect(patient.condition, 'Normal');
    });
  });

  group('ClinicalData Model Tests', () {
    test('ClinicalData.fromJson should correctly parse clinical data', () {
      // Arrange
      final Map<String, dynamic> clinicalDataJson = {
        '_id': '456',
        'patientId': '123',
        'date': '2023-04-15T00:00:00.000Z',
        'type': 'Blood Pressure',
        'value': '120/80 mmHg',
        'condition': 'Normal'
      };

      // Act
      final clinicalData = ClinicalData.fromJson(clinicalDataJson);

      // Assert
      expect(clinicalData.id, '456');
      expect(clinicalData.patientId, '123');
      expect(clinicalData.date, '2023-04-15');
      expect(clinicalData.testType, 'Blood Pressure');
      expect(clinicalData.reading, '120/80 mmHg');
      expect(clinicalData.condition, 'Normal');
    });
  });

  group('Health Calculator Tests', () {
    test(
        'HealthCalculator should correctly determine condition based on Blood Pressure',
        () {
      // Arrange & Act
      final normalCondition =
          HealthCalculator.determineCondition('Blood Pressure', '120/80 mmHg');
      final criticalCondition =
          HealthCalculator.determineCondition('Blood Pressure', '180/120 mmHg');

      // Assert
      expect(normalCondition, 'Normal');
      expect(criticalCondition, 'Critical');
    });

    test(
        'HealthCalculator should correctly determine overall condition from multiple readings',
        () {
      // Arrange
      final List<Map<String, String>> normalReadings = [
        {
          'testType': 'Blood Pressure',
          'reading': '120/80 mmHg',
          'condition': 'Normal'
        },
        {'testType': 'Heart Rate', 'reading': '70 bpm', 'condition': 'Normal'}
      ];

      final List<Map<String, String>> criticalReadings = [
        {
          'testType': 'Blood Pressure',
          'reading': '120/80 mmHg',
          'condition': 'Normal'
        },
        {
          'testType': 'Heart Rate',
          'reading': '130 bpm',
          'condition': 'Critical'
        }
      ];

      // Act
      final normalResult =
          HealthCalculator.determineOverallCondition(normalReadings);
      final criticalResult =
          HealthCalculator.determineOverallCondition(criticalReadings);

      // Assert
      expect(normalResult, 'Normal');
      expect(criticalResult, 'Critical');
    });
  });
}
