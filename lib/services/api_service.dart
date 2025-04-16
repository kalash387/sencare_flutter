import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl =
      'https://sencare-cnebb2hzg0crhje9.canadacentral-01.azurewebsites.net';
  static bool debugMode = true; // Enable or disable debug output

  // Helper method to debug API responses
  static void _debugPrint(String method, String endpoint, dynamic data) {
    if (!debugMode) return;

    print('=== API DEBUG: $method $endpoint ===');
    print('Response Type: ${data.runtimeType}');

    if (data is Map) {
      print('Map Keys: ${data.keys.toList()}');
      if (data.isNotEmpty) {
        final firstKey = data.keys.first;
        print('First Value Type: ${data[firstKey]?.runtimeType}');
        print(
            'First Value Sample: ${data[firstKey].toString().substring(0, min(50, data[firstKey].toString().length))}...');
      }
    } else if (data is List) {
      print('List Length: ${data.length}');
      if (data.isNotEmpty) {
        print('First Item Type: ${data.first.runtimeType}');
        print(
            'First Item Sample: ${data.first.toString().substring(0, min(50, data.first.toString().length))}...');
      }
    }

    print('===============================');
  }

  // Helper to get min value since dart:math is not imported
  static int min(int a, int b) => a < b ? a : b;

  // Get all patients
  static Future<List<Map<String, dynamic>>> getAllPatients() async {
    final response = await http.get(Uri.parse('$baseUrl/patients'));

    if (response.statusCode == 200) {
      final dynamic responseBody = jsonDecode(response.body);
      _debugPrint('GET', '/patients', responseBody);

      // Check if response has the expected format: {"status": "success", "data": [...]}
      if (responseBody is Map && responseBody.containsKey('data')) {
        final dynamic data = responseBody['data'];

        // Handle null or empty data
        if (data == null) {
          print('Warning: API returned null data');
          return [];
        }

        if (data is List) {
          // If data is already a list, map it to a list of maps
          final result =
              data.map((json) => json as Map<String, dynamic>).toList();
          print('Processed ${result.length} patients from API');
          return result;
        } else if (data is Map) {
          // If data is a map with numeric keys (common pattern for REST APIs)
          // Convert it to a list of the map values
          List<Map<String, dynamic>> result = [];

          // Check if it's a map of maps (with keys like "1", "2", etc.)
          data.forEach((key, value) {
            if (value is Map) {
              // Add ID to the map if it's not there already
              final Map<String, dynamic> itemWithId =
                  Map<String, dynamic>.from(value);
              if (!itemWithId.containsKey('id') &&
                  !itemWithId.containsKey('_id') &&
                  key is String) {
                // Use the key as id if it's not already present
                itemWithId['id'] = key;
              }
              result.add(itemWithId);
            }
          });

          if (result.isNotEmpty) {
            print('Processed ${result.length} patients from API map');
            return result;
          }

          // If it's just a single item wrapped in a map
          final singleResult = [Map<String, dynamic>.from(data)];
          print('Processed 1 patient from API (single map)');
          return singleResult;
        }
      } else if (responseBody is List) {
        // Handle direct list response
        final result =
            responseBody.map((json) => json as Map<String, dynamic>).toList();
        print('Processed ${result.length} patients from direct list');
        return result;
      } else if (responseBody is Map) {
        // Handle direct map response (possibly a single patient)
        final result = [Map<String, dynamic>.from(responseBody)];
        print('Processed 1 patient from direct map');
        return result;
      }

      // Fallback - empty result instead of exception
      print('Warning: Unexpected data format, returning empty list');
      return [];
    } else {
      throw Exception('Failed to load patients: ${response.statusCode}');
    }
  }

  // Alias for getAllPatients
  static Future<List<Map<String, dynamic>>> getPatients() => getAllPatients();

  // Get a specific patient by ID
  static Future<Map<String, dynamic>> getPatientById(String patientId) async {
    final response = await http.get(Uri.parse('$baseUrl/patients/$patientId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _debugPrint('GET', '/patients/$patientId', data);
      return data;
    } else {
      throw Exception('Failed to load patient: ${response.statusCode}');
    }
  }

  // Add a new patient
  static Future<Map<String, dynamic>> addPatient(
      Map<String, dynamic> patient) async {
    print('Adding patient: ${jsonEncode(patient)}');
    final response = await http.post(
      Uri.parse('$baseUrl/patients'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patient),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      final dynamic responseBody = jsonDecode(response.body);
      _debugPrint('POST', '/patients', responseBody);

      // Normalize the response to ensure we return a consistent format
      if (responseBody is Map) {
        // Check if response has a "data" field containing the actual patient info
        if (responseBody.containsKey('data')) {
          final dynamic data = responseBody['data'];
          if (data is Map) {
            return Map<String, dynamic>.from(data);
          } else if (data is List && data.isNotEmpty && data.first is Map) {
            // If 'data' is a list but contains the patient info
            return Map<String, dynamic>.from(data.first);
          }
        } else if (responseBody.containsKey('_id') ||
            responseBody.containsKey('id')) {
          // The response itself is the patient object
          return Map<String, dynamic>.from(responseBody);
        }
      }

      // If we haven't returned yet, enhance the original patient data with any additional info
      // This is a fallback to ensure something is always returned
      final enhancedPatient = Map<String, dynamic>.from(patient);

      // Extract ID from response if available
      if (responseBody is Map) {
        if (responseBody.containsKey('_id')) {
          enhancedPatient['_id'] = responseBody['_id'];
        } else if (responseBody.containsKey('id')) {
          enhancedPatient['id'] = responseBody['id'];
        }
      }

      print('Enhanced patient data: $enhancedPatient');
      return enhancedPatient;
    } else {
      throw Exception(
          'Failed to add patient: ${response.statusCode} - ${response.body}');
    }
  }

  // Get all clinical data for a patient
  static Future<List<Map<String, dynamic>>> getPatientClinicalData(
      String patientId) async {
    final response =
        await http.get(Uri.parse('$baseUrl/patients/$patientId/clinical-data'));

    if (response.statusCode == 200) {
      final dynamic responseBody = jsonDecode(response.body);
      _debugPrint('GET', '/patients/$patientId/clinical-data', responseBody);

      // Check if response has the expected format: {"status": "success", "data": [...]}
      if (responseBody is Map && responseBody.containsKey('data')) {
        final dynamic data = responseBody['data'];

        if (data is List) {
          // If data is already a list, map it to a list of maps
          return data.map((json) {
            final Map<String, dynamic> item = json as Map<String, dynamic>;
            // Ensure patientId is set
            if (!item.containsKey('patientId')) {
              item['patientId'] = patientId;
            }
            return item;
          }).toList();
        } else if (data is Map) {
          // If data is a map with numeric keys (common pattern for REST APIs)
          // Convert it to a list of the map values
          List<Map<String, dynamic>> result = [];

          // Check if it's a map of maps (with keys like "1", "2", etc.)
          data.forEach((key, value) {
            if (value is Map) {
              // Add ID to the map if it's not there already
              final Map<String, dynamic> itemWithId =
                  Map<String, dynamic>.from(value);
              if (!itemWithId.containsKey('id') && key is String) {
                // Use the key as id if it's not already present
                itemWithId['id'] = key;
              }
              itemWithId['patientId'] = patientId; // Ensure patientId is set
              result.add(itemWithId);
            }
          });

          if (result.isNotEmpty) {
            return result;
          }

          // If it's just a single item wrapped in a map
          final Map<String, dynamic> singleItem =
              Map<String, dynamic>.from(data);
          if (!singleItem.containsKey('patientId')) {
            singleItem['patientId'] = patientId;
          }
          return [singleItem];
        }
      } else if (responseBody is List) {
        // Handle direct list response
        return responseBody.map((json) {
          final Map<String, dynamic> item = json as Map<String, dynamic>;
          if (!item.containsKey('patientId')) {
            item['patientId'] = patientId;
          }
          return item;
        }).toList();
      } else if (responseBody is Map) {
        // Handle direct map response (possibly a single clinical data entry)
        final Map<String, dynamic> item =
            Map<String, dynamic>.from(responseBody);
        if (!item.containsKey('patientId')) {
          item['patientId'] = patientId;
        }
        return [item];
      }

      // Fallback
      throw Exception(
          'Unexpected data format from API: ${responseBody.runtimeType}');
    } else {
      throw Exception('Failed to load clinical data: ${response.statusCode}');
    }
  }

  // Get specific clinical data by ID
  static Future<Map<String, dynamic>> getClinicalDataById(
      String patientId, String dataId) async {
    final response = await http
        .get(Uri.parse('$baseUrl/patients/$patientId/clinical-data/$dataId'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _debugPrint('GET', '/patients/$patientId/clinical-data/$dataId', data);
      return data;
    } else {
      throw Exception('Failed to load clinical data: ${response.statusCode}');
    }
  }

  // Add clinical data for a patient
  static Future<Map<String, dynamic>> addClinicalData(
      String patientId, Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/patients/$patientId/clinical-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      // Handle both 200 and 201 status codes
      if (response.statusCode == 200 || response.statusCode == 201) {
        // Try to parse the response body if possible
        try {
          final responseData = jsonDecode(response.body);
          _debugPrint('POST', '/patients/$patientId/clinical-data', responseData);
          return responseData;
        } catch (e) {
          // If parsing fails, return a simplified success response
          return {'status': 'success'};
        }
      } else {
        throw Exception(
            'Failed to add clinical data: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // For network errors and other exceptions
      print('Error in addClinicalData: ${e.toString()}');
      throw e;
    }
  }

  // Update a patient
  static Future<Map<String, dynamic>> updatePatient(
      String patientId, Map<String, dynamic> patient) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$patientId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(patient),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _debugPrint('PUT', '/patients/$patientId', data);
      return data;
    } else {
      throw Exception('Failed to update patient: ${response.statusCode}');
    }
  }

  // Update clinical data for a patient
  static Future<Map<String, dynamic>> updateClinicalData(
      String patientId, String dataId, Map<String, dynamic> data) async {
    final response = await http.put(
      Uri.parse('$baseUrl/patients/$patientId/clinical-data/$dataId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      _debugPrint('PUT', '/patients/$patientId/clinical-data/$dataId', responseData);
      return responseData;
    } else {
      throw Exception(
          'Failed to update clinical data: ${response.statusCode} - ${response.body}');
    }
  }

  // Delete clinical data for a patient
  static Future<bool> deleteClinicalData(
      String patientId, String dataId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/patients/$patientId/clinical-data/$dataId'),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _debugPrint('DELETE', '/patients/$patientId/clinical-data/$dataId', 'success');
      return true;
    } else {
      throw Exception(
          'Failed to delete clinical data: ${response.statusCode} - ${response.body}');
    }
  }

  // Delete a patient
  static Future<bool> deletePatient(String patientId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/patients/$patientId'),
    );

    if (response.statusCode == 200 || response.statusCode == 204) {
      _debugPrint('DELETE', '/patients/$patientId', 'success');
      return true;
    } else {
      throw Exception(
          'Failed to delete patient: ${response.statusCode} - ${response.body}');
    }
  }
}
