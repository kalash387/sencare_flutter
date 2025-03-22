class Patient {
  String? id;
  String name;
  String age;
  String contact;
  String condition;
  String? photo;
  List<Map<String, dynamic>>? clinicalData;

  Patient({
    this.id,
    required this.name,
    required this.age,
    required this.contact,
    required this.condition,
    this.photo,
    this.clinicalData,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    // Debug output
    print('Creating Patient from JSON: ${json.keys.toList()}');

    // Handle different ID field names (_id is common in MongoDB/Mongoose)
    final patientId = json['id'] ?? json['_id'];
    print('Patient ID: $patientId');

    // Make sure age is a string
    String age = 'N/A';
    if (json['age'] != null) {
      if (json['age'] is int) {
        age = json['age'].toString();
      } else if (json['age'] is String) {
        age = json['age'];
      } else {
        age = json['age'].toString();
      }
    }

    // Get name and other fields with fallbacks
    final name = json['name'] as String? ?? 'Unknown';
    final contact = json['contact'] as String? ?? 'N/A';
    final condition = json['condition'] as String? ?? 'Normal';
    final photo = json['photo'] as String?;

    final List<Map<String, dynamic>> clinicalDataList = [];

    // Handle clinical data if it exists in the response
    if (json['clinicalData'] != null) {
      if (json['clinicalData'] is List) {
        try {
          clinicalDataList.addAll((json['clinicalData'] as List)
              .map((data) => data is Map<String, dynamic>
                  ? Map<String, dynamic>.from(data)
                  : {'data': data.toString()})
              .toList());
        } catch (e) {
          print('Error processing clinical data: $e');
        }
      } else {
        print(
            'Warning: clinicalData is not a List: ${json['clinicalData'].runtimeType}');
      }
    }

    print(
        'Created Patient: $name, ID: $patientId, Age: $age, Contact: $contact, Condition: $condition');

    return Patient(
      id: patientId,
      name: name,
      age: age,
      contact: contact,
      condition: condition,
      photo: photo,
      clinicalData: clinicalDataList.isEmpty ? null : clinicalDataList,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'name': name,
      'age': age,
      'contact': contact,
      'condition': condition,
    };

    // Only include these fields if they're not null
    if (id != null) data['_id'] = id; // Use _id for MongoDB compatibility
    if (photo != null) data['photo'] = photo;
    if (clinicalData != null) data['clinicalData'] = clinicalData;

    return data;
  }

  // Convert to a simple map that was used in the original code
  Map<String, String> toMap() {
    return {
      if (id != null) 'id': id!,
      'name': name,
      'age': age,
      'contact': contact,
      'condition': condition,
      if (photo != null) 'photo': photo!,
    };
  }

  // Create from a simple map that was used in the original code
  factory Patient.fromMap(Map<String, String> map) {
    return Patient(
      id: map['id'],
      name: map['name'] ?? 'Unknown',
      age: map['age'] ?? 'N/A',
      contact: map['contact'] ?? 'N/A',
      condition: map['condition'] ?? 'Normal',
      photo: map['photo'],
    );
  }
}
