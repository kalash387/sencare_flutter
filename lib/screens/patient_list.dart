import 'package:flutter/material.dart';
import 'add_patient.dart'; // Import AddPatient screen

class PatientList extends StatefulWidget {
  @override
  _PatientListState createState() => _PatientListState();
}

class _PatientListState extends State<PatientList> {
  List<Map<String, String>> patients = [
    {'name': 'John Doe', 'condition': 'Normal'},
    {'name': 'Jane Smith', 'condition': 'Critical'},
    {'name': 'Samuel Green', 'condition': 'Normal'},
    {'name': 'Rachel Adams', 'condition': 'Critical'},
  ];

  List<Map<String, String>> filteredPatients = [];

  @override
  void initState() {
    super.initState();
    filteredPatients = patients;
  }

  void _filterPatients(String query) {
    setState(() {
      filteredPatients = patients
          .where((patient) =>
              patient['name']!.toLowerCase().contains(query.toLowerCase()) ||
              patient['condition']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  void _addPatient(Map<String, String> newPatient) {
    setState(() {
      patients.add(newPatient);
      filteredPatients = patients; // Update the filtered list
    });
  }

  Color _getBorderColor(String condition) {
    if (condition == 'Critical') {
      return Colors.red; // Red for critical condition
    } else {
      return Colors.green; // Green for normal condition (or you can use blue)
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Patient List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              onChanged: _filterPatients,
              decoration: InputDecoration(
                labelText: 'Search Patients',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 15, horizontal: 10),
              ),
            ),
            SizedBox(height: 20),

            // Sort buttons row
            Row(
              children: [
                // All button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filteredPatients = patients; // Show all patients
                      });
                    },
                    child: Text('All'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Button background color
                      side: BorderSide(color: Colors.blue), // Border color
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Space between buttons

                // Normal button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filteredPatients = patients
                            .where(
                                (patient) => patient['condition'] == 'Normal')
                            .toList();
                      });
                    },
                    child: Text('Normal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Button background color
                      side: BorderSide(color: Colors.blue), // Border color
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                SizedBox(width: 10), // Space between buttons

                // Critical button
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        filteredPatients = patients
                            .where(
                                (patient) => patient['condition'] == 'Critical')
                            .toList();
                      });
                    },
                    child: Text('Critical'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white, // Button background color
                      side: BorderSide(color: Colors.blue), // Border color
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),

            // Add Patient button (full width)
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddPatient(onAddPatient: _addPatient),
                  ),
                );
              },
              child: Text('Add Patient'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // Button color
                padding: EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                minimumSize: Size(double.infinity, 50), // Full width
              ),
            ),
            SizedBox(height: 20),

            // Patient List
            Expanded(
              child: ListView.builder(
                itemCount: filteredPatients.length,
                itemBuilder: (context, index) {
                  final patient = filteredPatients[index];
                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                          color: _getBorderColor(patient['condition']!),
                          width: 2), // Dynamic border color
                    ),
                    child: ListTile(
                      title: Text(patient['name']!),
                      subtitle: Text('Condition: ${patient['condition']}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
