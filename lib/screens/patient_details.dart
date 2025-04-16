import 'package:flutter/material.dart';
import 'add_clinical_data.dart';
import 'edit_clinical_data.dart';
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
      if (mounted) {
        setState(() {
          _isLoading = false;
          clinicalData = [];
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }

    try {
      final data = await ApiService.getPatientClinicalData(currentPatient.id!);
      
      // Check if widget is still mounted before updating state
      if (mounted) {
        setState(() {
          clinicalData = data.map((json) => ClinicalData.fromJson(json)).toList();
          _isLoading = false;
        });

        // Update patient condition based on clinical data
        await _updatePatientCondition();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasError = true;
          _errorMessage = 'Failed to load clinical data: ${e.toString()}';
        });
      }
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
    // If there's no clinical data, set condition to Normal
    if (clinicalData.isEmpty) {
      if (currentPatient.condition != 'Normal') {
        if (mounted) {
          setState(() {
            currentPatient.condition = 'Normal';
          });
        } else {
          // Update the condition without setState
          currentPatient.condition = 'Normal';
        }
        
        // Update the patient in the database
        await _savePatientCondition('Normal');
      }
      return;
    }

    // Convert ClinicalData objects to Map<String, String> for health calculator
    List<Map<String, String>> clinicalDataMaps =
        clinicalData.map((data) => data.toMap()).toList();

    // Calculate overall condition based on all clinical data
    String newCondition =
        HealthCalculator.determineOverallCondition(clinicalDataMaps);

    // Update the patient's condition if it has changed
    if (newCondition != currentPatient.condition) {
      if (mounted) {
        setState(() {
          currentPatient.condition = newCondition;
        });
      } else {
        // Update the condition without setState
        currentPatient.condition = newCondition;
      }

      // Update the patient in the database
      await _savePatientCondition(newCondition);
    }
  }
  
  // Helper method to save patient condition to the database
  Future<void> _savePatientCondition(String newCondition) async {
    if (currentPatient.id != null) {
      try {
        await ApiService.updatePatient(
            currentPatient.id!, currentPatient.toJson());

        // Notify parent about the updated patient
        if (widget.onUpdatePatient != null) {
          widget.onUpdatePatient!(currentPatient);
        }

        // Check if widget is still mounted before showing SnackBar
        if (mounted) {
          // Show a notification to the user
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Patient condition updated to $newCondition',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              backgroundColor: _getConditionColor(newCondition),
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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
                  boxShadow: [
                    BoxShadow(
                      color: conditionColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                  border: Border.all(
                    color: conditionColor.withOpacity(0.5),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentPatient.condition == 'Critical'
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline,
                      size: 18,
                      color: conditionColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      currentPatient.condition,
                      style: TextStyle(
                        color: conditionColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
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
                          valueColor: conditionColor,
                          highlight: true),
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
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Cannot add clinical data: Patient ID is missing'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                  return;
                }

                final dataAdded = await Navigator.push<Map<String, dynamic>>(
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
                          final responseData = await ApiService.addClinicalData(
                            currentPatient.id!,
                            newClinicalData.toJson(),
                          );
                          
                          // Return success status and data
                          if (responseData != null) {
                            // Extract ID from response - handle both formats
                            String? id;
                            if (responseData['_id'] != null) {
                              id = responseData['_id'].toString();
                            } else if (responseData['id'] != null) {
                              id = responseData['id'].toString();
                            } else if (responseData['data'] != null && responseData['data'] is Map) {
                              // If there's a nested data object
                              var nestedData = responseData['data'] as Map;
                              if (nestedData['_id'] != null) {
                                id = nestedData['_id'].toString();
                              } else if (nestedData['id'] != null) {
                                id = nestedData['id'].toString();
                              }
                            }
                            
                            // Create a new clinical data with the ID from the response
                            if (id != null) {
                              final clinicalDataWithId = ClinicalData(
                                id: id,
                                patientId: currentPatient.id!,
                                date: data['date'] ?? '',
                                testType: data['testType'] ?? '',
                                reading: data['reading'] ?? '',
                                condition: data['condition'] ?? 'Normal',
                              );
                              
                              return {
                                'success': true,
                                'data': clinicalDataWithId
                              };
                            }
                          }
                          
                          // Fallback - perform a fetch to get the latest data
                          return {'success': true, 'needsRefresh': true};
                        } catch (e) {
                          print('Failed to add clinical data: ${e.toString()}');
                          
                          // Check if the error message contains success indicators
                          String errorMsg = e.toString().toLowerCase();
                          if (errorMsg.contains('"status":"success"') || 
                              errorMsg.contains('200')) {
                            // This is actually a success case
                            return {'success': true, 'needsRefresh': true};
                          }
                          
                          return {'success': false};
                        }
                      },
                    ),
                  ),
                );
                
                // If data was added successfully
                if (dataAdded != null && dataAdded['success'] == true) {
                  if (dataAdded['data'] != null) {
                    // Get the new clinical data and add it to the list
                    final ClinicalData newData = dataAdded['data'];
                    
                    // Check if widget is still mounted before updating the state
                    if (mounted) {
                      setState(() {
                        clinicalData.add(newData);
                      });
                    }
                  } else if (dataAdded['needsRefresh'] == true) {
                    // If we need to refresh the data from the server
                    await _fetchClinicalData();
                  }
                  
                  // Update patient condition based on the new clinical data
                  await _updatePatientCondition();
                  
                  // Show success message if still mounted
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Clinical data added successfully'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
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
                    child: DataTable(
                      dividerThickness: 1,
                      border: TableBorder(
                        horizontalInside: BorderSide(
                          width: 1, 
                          color: Colors.grey.shade200
                        ),
                      ),
                      headingRowColor:
                          MaterialStateProperty.all(Colors.grey[100]),
                      headingTextStyle: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                      dataRowColor: MaterialStateProperty.all(Colors.white),
                      horizontalMargin: 12,
                      columnSpacing: 16,
                      columns: [
                        DataColumn(
                          label: Container(
                            width: 70,
                            child: Text('Date'),
                          ),
                        ),
                        DataColumn(
                          label: Container(
                            width: 90,
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
                            child: Text('Actions', overflow: TextOverflow.visible),
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
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    width: 40,
                                    child: IconButton(
                                      icon: Icon(Icons.edit, size: 20, color: Colors.blue),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () async {
                                        // First get the current data for reference
                                        ClinicalData currentData = data;
                                        
                                        final result = await Navigator.push<Map<String, dynamic>>(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => EditClinicalData(
                                              patientName: currentPatient.name,
                                              clinicalData: currentData,
                                              onSaveClinicalData: (updatedData) async {
                                                if (updatedData.id == null) {
                                                  return false;
                                                }
                                                
                                                try {
                                                  // Update via API
                                                  await ApiService.updateClinicalData(
                                                    updatedData.patientId,
                                                    updatedData.id!,
                                                    updatedData.toJson(),
                                                  );
                                                  
                                                  // Return the updated data and success status
                                                  return {
                                                    'success': true,
                                                    'data': updatedData
                                                  };
                                                } catch (e) {
                                                  print('Failed to update clinical data: ${e.toString()}');
                                                  return {
                                                    'success': false
                                                  };
                                                }
                                              },
                                            ),
                                          ),
                                        );
                                        
                                        // Check if we got a successful result back
                                        if (result != null && result['success'] == true) {
                                          // Get the updated data
                                          ClinicalData updatedData = result['data'];
                                          
                                          // Update the UI immediately - this setState is directly in this function's scope
                                          if (mounted) {
                                            setState(() {
                                              // Find the index of the item and replace it
                                              final index = clinicalData.indexWhere((item) => item.id == updatedData.id);
                                              if (index != -1) {
                                                clinicalData[index] = updatedData;
                                              }
                                            });
                                          }
                                          
                                          // Update patient condition based on the updated clinical data
                                          await _updatePatientCondition();
                                          
                                          // Show success message if still mounted
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Clinical data updated successfully'),
                                                backgroundColor: Colors.green,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                  Container(
                                    width: 40,
                                    child: IconButton(
                                      icon: Icon(Icons.delete_outline, size: 20, color: Colors.red),
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: Text('Delete Clinical Data'),
                                            content: Text(
                                                'Are you sure you want to delete this clinical data?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, false),
                                                child: Text('Cancel'),
                                              ),
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context, true),
                                                child: Text('Delete'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            if (data.id == null) return;
                                            
                                            // Store ID for reference after deletion
                                            final String dataId = data.id!;
                                            
                                            // Delete via API
                                            bool success = await ApiService.deleteClinicalData(
                                              data.patientId,
                                              dataId,
                                            );
                                            
                                            if (success) {
                                              // Update UI by removing the item from the list if still mounted
                                              if (mounted) {
                                                setState(() {
                                                  clinicalData.removeWhere((item) => item.id == dataId);
                                                });
                                              }
                                              
                                              // Update patient condition after deletion of clinical data
                                              await _updatePatientCondition();
                                              
                                              // Show success message if still mounted
                                              if (mounted) {
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(
                                                    content: Text('Clinical data deleted successfully'),
                                                    backgroundColor: Colors.green,
                                                    behavior: SnackBarBehavior.floating,
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Failed to delete clinical data: ${e.toString()}'),
                                                  backgroundColor: Colors.red,
                                                  behavior: SnackBarBehavior.floating,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon,
      {Color? valueColor, bool highlight = false}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: highlight && valueColor != null 
                ? valueColor.withOpacity(0.1) 
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: highlight && valueColor != null 
                ? Border.all(color: valueColor.withOpacity(0.4), width: 1.5) 
                : null,
          ),
          child: Icon(icon, 
                 color: highlight && valueColor != null 
                     ? valueColor 
                     : Colors.grey[700], 
                 size: 22),
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
                fontSize: highlight ? 18 : 16,
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
