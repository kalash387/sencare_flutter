class ClinicalData {
  String? id;
  String patientId;
  String date;
  String testType;
  String reading;
  String condition;

  ClinicalData({
    this.id,
    required this.patientId,
    required this.date,
    required this.testType,
    required this.reading,
    required this.condition,
  });

  factory ClinicalData.fromJson(Map<String, dynamic> json) {
    // Handle different ID field names (_id is common in MongoDB/Mongoose)
    final dataId = json['id'] ?? json['_id'];

    // Handle different field names in the API response
    final testType = json['testType'] ?? json['type'] ?? '';
    final reading = json['reading'] ?? json['value'] ?? '';

    // Handle date format
    String formattedDate = json['date'] ?? '';
    if (formattedDate.isNotEmpty && formattedDate.contains('T')) {
      // If date is in ISO format (2024-12-11T00:00:00.000Z)
      // Convert to simple date format (2024-12-11)
      formattedDate = formattedDate.split('T')[0];
    }

    return ClinicalData(
      id: dataId,
      patientId: json['patientId'] ?? '',
      date: formattedDate,
      testType: testType,
      reading: reading,
      condition: json['condition'] ?? 'Normal',
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'patientId': patientId,
      'date': date,
      'type':
          testType, // Use 'type' as the field name since that's what the API expects
      'value':
          reading, // Use 'value' as the field name since that's what the API expects
      'condition': condition,
    };

    // Only include ID if it's not null
    if (id != null) data['_id'] = id; // Use _id for MongoDB compatibility

    return data;
  }

  // Convert to a simple map that was used in the original code
  Map<String, String> toMap() {
    return {
      if (id != null) 'id': id!,
      'patientId': patientId,
      'date': date,
      'testType': testType,
      'reading': reading,
      'condition': condition,
    };
  }

  // Create from a simple map that was used in the original code
  factory ClinicalData.fromMap(Map<String, String> map) {
    return ClinicalData(
      id: map['id'],
      patientId: map['patientId'] ?? '',
      date: map['date'] ?? '',
      testType: map['testType'] ?? '',
      reading: map['reading'] ?? '',
      condition: map['condition'] ?? 'Normal',
    );
  }
}
