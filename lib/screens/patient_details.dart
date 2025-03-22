import 'package:flutter/material.dart';
import 'add_clinical_data.dart';
import '../services/health_calculator.dart';
import '../models/patient.dart';
import '../models/clinical_data.dart';
import '../services/api_service.dart';

class PatientDetails extends StatefulWidget {
  final Patient patient;
  final Function(Patient)? onUpdatePatient;

  const PatientDetails(
      {super.key, required this.patient, this.onUpdatePatient});

  @override
  _PatientDetailsState createState() => _PatientDetailsState();
}

class _PatientDetailsState extends State<PatientDetails>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<ClinicalData> clinicalData = [];
  late Patient currentPatient;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    currentPatient = widget.patient;
    _fetchClinicalData();
  }

  Future<void> _fetchClinicalData() async {
    if (currentPatient.id == null) {
      setState(() {
        _isLoading = false;
        clinicalData = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final data = await ApiService.getPatientClinicalData(currentPatient.id!);
      setState(() {
        clinicalData = data.map((json) => ClinicalData.fromJson(json)).toList();
        _isLoading = false;
      });

      // Update patient condition based on clinical data
      _updatePatientCondition();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = 'Failed to load clinical data: ${e.toString()}';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color _getConditionColor(String condition) {
    return condition == 'Critical' ? Colors.red : Color(0xFF26A69A);
  }

  // Update patient's condition based on clinical data
  Future<void> _updatePatientCondition() async {
    if (clinicalData.isEmpty) return;

    // Convert ClinicalData objects to Map<String, String> for health calculator
    List<Map<String, String>> clinicalDataMaps =
        clinicalData.map((data) => data.toMap()).toList();

    // Calculate overall condition based on all clinical data
    String newCondition =
        HealthCalculator.determineOverallCondition(clinicalDataMaps);

    // Update the patient's condition if it has changed
    if (newCondition != currentPatient.condition) {
      setState(() {
        currentPatient.condition = newCondition;
      });

      // Update the patient in the database
      if (currentPatient.id != null) {
        try {
          await ApiService.updatePatient(
              currentPatient.id!, currentPatient.toJson());

          // Notify parent about the updated patient
          if (widget.onUpdatePatient != null) {
            widget.onUpdatePatient!(currentPatient);
          }

          // Show a notification to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Patient condition updated to $newCondition'),
              backgroundColor: _getConditionColor(newCondition),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed to update patient condition: ${e.toString()}'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final conditionColor = _getConditionColor(currentPatient.condition);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Patient Details',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          unselectedLabelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          tabs: [
            Tab(text: 'Basic Info'),
            Tab(text: 'Clinical Data'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Basic Info Tab
          _buildBasicInfoTab(conditionColor),

          // Clinical Data Tab
          _buildClinicalDataTab(conditionColor),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab(Color conditionColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with patient name and condition
          Row(
            children: [
              Text(
                'Patient Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: conditionColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentPatient.condition == 'Critical'
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 16,
                      color: conditionColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      currentPatient.condition,
                      style: TextStyle(
                        color: conditionColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Patient Image and Info Card
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Top part with avatar and name
                Container(
                  padding: EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: conditionColor.withOpacity(0.1),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Patient actual image instead of avatar with letter
                      ClipRRect(
                        borderRadius: BorderRadius.circular(45),
                        child: Image.asset(
                          'assets/patient1.png',
                          width: 90,
                          height: 90,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return CircleAvatar(
                              radius: 45,
                              backgroundColor: conditionColor.withOpacity(0.3),
                              child: Text(
                                currentPatient.name.substring(0, 1),
                                style: TextStyle(
                                  color: conditionColor,
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(width: 16),

                      // Name and ID
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentPatient.name,
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Patient ID: ${currentPatient.id ?? 'N/A'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Divider
                Divider(height: 1, thickness: 1, color: Colors.grey[200]),

                // Patient details in a clean layout
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildDetailItem('Age', currentPatient.age,
                          Icons.calendar_today_outlined),
                      SizedBox(height: 16),
                      _buildDetailItem('Contact', currentPatient.contact,
                          Icons.phone_outlined),
                      SizedBox(height: 16),
                      _buildDetailItem(
                          'Condition',
                          currentPatient.condition,
                          currentPatient.condition == 'Critical'
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline,
                          valueColor: conditionColor),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClinicalDataTab(Color conditionColor) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[300],
            ),
            SizedBox(height: 16),
            Text(
              'Error Loading Data',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchClinicalData,
              icon: Icon(Icons.refresh),
              label: Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Add Clinical Data Button with improved design
        Container(
          padding: EdgeInsets.all(16),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: conditionColor.withOpacity(0.3),
                  spreadRadius: 1,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                if (currentPatient.id == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Cannot add clinical data: Patient ID is missing'),
                      backgroundColor: Colors.red,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddClinicalData(
                      patientName: currentPatient.name,
                      onAddClinicalData: (Map<String, String> data) async {
                        try {
                          // Create a ClinicalData object from the form data
                          final newClinicalData = ClinicalData(
                            patientId: currentPatient.id!,
                            date: data['date'] ?? '',
                            testType: data['testType'] ?? '',
                            reading: data['reading'] ?? '',
                            condition: data['condition'] ?? 'Normal',
                          );

                          // Save to API
                          final result = await ApiService.addClinicalData(
                            currentPatient.id!,
                            newClinicalData.toJson(),
                          );

                          // Add to local list with the received ID
                          setState(() {
                            clinicalData.add(ClinicalData.fromJson(result));
                          });

                          // Update patient's condition based on all clinical data
                          _updatePatientCondition();

                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Clinical data added successfully'),
                              backgroundColor: Colors.green,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Failed to add clinical data: ${e.toString()}'),
                              backgroundColor: Colors.red,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                );
              },
              icon: Icon(Icons.add_circle_outline, color: Colors.white),
              label: Text('Add Clinical Data'),
              style: ElevatedButton.styleFrom(
                backgroundColor: conditionColor,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ),

        SizedBox(height: 16),

        // Clinical Data Table with improved design
        Expanded(
          child: clinicalData.isEmpty
              ? _buildEmptyDataState()
              : Container(
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor:
                              MaterialStateProperty.all(Colors.grey[100]),
                          headingTextStyle: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          dataRowColor: MaterialStateProperty.all(Colors.white),
                          horizontalMargin: 24,
                          columnSpacing: 40,
                          columns: [
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text('Date'),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 100,
                                child: Text('Test Type'),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 80,
                                child: Text('Reading'),
                              ),
                            ),
                            DataColumn(
                              label: Container(
                                width: 100,
                                child: Text('Condition'),
                              ),
                            ),
                          ],
                          rows: clinicalData.map((data) {
                            return DataRow(
                              cells: [
                                DataCell(Text(data.date)),
                                DataCell(Text(data.testType)),
                                DataCell(Text(data.reading)),
                                DataCell(
                                  Container(
                                    width: 90,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: data.condition == 'Critical'
                                          ? Colors.red[100]
                                          : Colors.green[100],
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      data.condition,
                                      style: TextStyle(
                                        color: data.condition == 'Critical'
                                            ? Colors.red[900]
                                            : Colors.green[900],
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.grey[700], size: 22),
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: valueColor ?? Colors.grey[800],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyDataState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.medical_information_outlined,
              size: 70,
              color: Colors.blue,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Clinical Data Available',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Add clinical data to track patient health',
            style: TextStyle(
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
