import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AddVehiclePage extends StatefulWidget {
  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  String? vehicleType;
  String vehicleNumber = '';
  String numberOfSeats = '';
  List<Map<String, String>> vehicleList = [];

  @override
  void initState() {
    super.initState();
    loadVehicles();
  }

  Future<void> loadVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? data = prefs.getString('vehicles');
    if (data != null) {
      setState(() {
        vehicleList = List<Map<String, String>>.from(json.decode(data));
      });
    }
  }

  Future<void> saveVehicles() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vehicles', json.encode(vehicleList));
  }

  void addVehicle() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      setState(() {
        vehicleList.add({
          'type': vehicleType ?? '',
          'number': vehicleNumber,
          'seats': numberOfSeats
        });

        // Clear all fields
        vehicleNumber = '';
        numberOfSeats = '';
        vehicleType = null;

        _formKey.currentState?.reset();
      });

      saveVehicles();
    }
  }

  void deleteVehicle(int index) async {
    setState(() {
      vehicleList.removeAt(index);
    });
    await saveVehicles();
  }

  void showVehiclePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Added Vehicles"),
        content: Container(
          width: double.maxFinite,
          child: vehicleList.isEmpty
              ? Text("No vehicles added yet.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: vehicleList.length,
                  itemBuilder: (_, index) {
                    final vehicle = vehicleList[index];
                    return ListTile(
                      title: Text('${vehicle['type'] ?? ''} - ${vehicle['number'] ?? ''}',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Seats: ${vehicle['seats'] ?? ''}'),
                      trailing: IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          Navigator.pop(context);
                          deleteVehicle(index);
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            child: Text("Close"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Vehicle"),
        backgroundColor: Color(0xFF77DDE7),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Text(
                        'Enter Vehicle Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: vehicleType,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type',
                          border: OutlineInputBorder(),
                        ),
                        items: ['Van', 'Bus', 'Auto', 'Car']
                            .map((type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(type),
                                ))
                            .toList(),
                        onChanged: (val) => setState(() => vehicleType = val),
                        validator: (val) =>
                            val == null || val.isEmpty ? 'Please select vehicle type' : null,
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Vehicle Number',
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter vehicle number';
                          }
                          final pattern =
                              RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}\d{4}$');
                          if (!pattern.hasMatch(val)) {
                            return 'Format: MH12AB1234';
                          }
                          return null;
                        },
                        onSaved: (val) => vehicleNumber = val ?? '',
                      ),
                      SizedBox(height: 12),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Number of Seats',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Enter number of seats';
                          }
                          if (int.tryParse(val) == null) {
                            return 'Enter a valid number';
                          }
                          return null;
                        },
                        onSaved: (val) => numberOfSeats = val ?? '',
                      ),
                      SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: addVehicle,
                          child: Text("Add Vehicle"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF00BFA6),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                horizontal: 30, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            GestureDetector(
              onTap: showVehiclePopup,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: Text(
                  "Show Added Vehicles",
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
