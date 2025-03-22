import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/health_calculator.dart';

class AddClinicalData extends StatefulWidget {
  final String patientName;
  final Function(Map<String, String>) onAddClinicalData;

  const AddClinicalData({
    Key? key,
    required this.patientName,
    required this.onAddClinicalData,
  }) : super(key: key);

  @override
  _AddClinicalDataState createState() => _AddClinicalDataState();
}

class _AddClinicalDataState extends State<AddClinicalData> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _readingController = TextEditingController();

  String _selectedTestType = 'Blood Pressure';
  String _condition = 'Normal';
  bool _isCalculating = false;

  // Updated test types to match the health calculator
  final List<String> _testTypes = [
    'Blood Pressure',
    'Heart Rate',
    'Blood Glucose',
    'Cholesterol',
    'BMI',
    'Temperature',
    'Oxygen Saturation',
    'Respiratory Rate'
  ];

  // Hint text for readings based on test type
  final Map<String, String> _readingHints = {
    'Blood Pressure': 'e.g., 120/80 mmHg',
    'Heart Rate': 'e.g., 75 bpm',
    'Blood Glucose': 'e.g., 100 mg/dL',
    'Cholesterol': 'e.g., 200 mg/dL',
    'BMI': 'e.g., 24.5',
    'Temperature': 'e.g., 98.6 °F',
    'Oxygen Saturation': 'e.g., 98%',
    'Respiratory Rate': 'e.g., 16 breaths/min'
  };

  @override
  void initState() {
    super.initState();
    // Set default date to today
    _dateController.text = DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  @override
  void dispose() {
    _dateController.dispose();
    _readingController.dispose();
    super.dispose();
  }

  // Calculate condition based on test type and reading
  void _calculateCondition() {
    setState(() {
      _isCalculating = true;
    });

    // Delay to show loading indicator
    Future.delayed(Duration(milliseconds: 300), () {
      final result = HealthCalculator.determineCondition(
        _selectedTestType,
        _readingController.text,
      );

      setState(() {
        _condition = result;
        _isCalculating = false;
      });
    });
  }

  // Select date using date picker
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Clinical Data',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Patient name card
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.person,
                      color: Theme.of(context).primaryColor,
                      size: 36,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Patient',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            widget.patientName,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.grey[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24),

              // Form
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Data Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),

                    SizedBox(height: 16),

                    // Date field
                    TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: 'Date',
                        hintText: 'Select date',
                        prefixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      onTap: () => _selectDate(context),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a date';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    // Test type dropdown
                    DropdownButtonFormField<String>(
                      value: _selectedTestType,
                      decoration: InputDecoration(
                        labelText: 'Test Type',
                        prefixIcon: Icon(Icons.medical_services),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                      ),
                      items: _testTypes.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _selectedTestType = newValue;
                            // Clear reading when test type changes
                            _readingController.clear();
                            _condition = 'Normal';
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a test type';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 16),

                    // Reading field
                    TextFormField(
                      controller: _readingController,
                      decoration: InputDecoration(
                        labelText: 'Reading',
                        hintText:
                            _readingHints[_selectedTestType] ?? 'Enter reading',
                        prefixIcon: Icon(Icons.monitor_heart),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 16,
                          horizontal: 16,
                        ),
                        suffixIcon: IconButton(
                          icon: _isCalculating
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Icon(Icons.calculate),
                          onPressed: _readingController.text.isEmpty
                              ? null
                              : _calculateCondition,
                          tooltip: 'Calculate condition',
                        ),
                      ),
                      onChanged: (value) {
                        if (value.isNotEmpty) {
                          _calculateCondition();
                        } else {
                          setState(() {
                            _condition = 'Normal';
                          });
                        }
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter reading';
                        }
                        return null;
                      },
                    ),

                    SizedBox(height: 24),

                    // Condition indicator
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _condition == 'Critical'
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _condition == 'Critical'
                              ? Colors.red.withOpacity(0.5)
                              : Colors.green.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _condition == 'Critical'
                                ? Icons.warning_amber_rounded
                                : Icons.check_circle_outline,
                            color: _condition == 'Critical'
                                ? Colors.red
                                : Colors.green,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Condition Assessment',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  _condition,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: _condition == 'Critical'
                                        ? Colors.red
                                        : Colors.green[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 32),

                    // Submit button
                    Container(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_formKey.currentState!.validate()) {
                            final data = {
                              'date': _dateController.text,
                              'testType': _selectedTestType,
                              'reading': _readingController.text,
                              'condition': _condition,
                            };

                            widget.onAddClinicalData(data);
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                          'Add Data',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
