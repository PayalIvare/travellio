import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddVehiclePage extends StatefulWidget {
  final List<Map<String, String>> initialVehicles;

  const AddVehiclePage({super.key, this.initialVehicles = const []});

  @override
  _AddVehiclePageState createState() => _AddVehiclePageState();
}

class _AddVehiclePageState extends State<AddVehiclePage> {
  final _formKey = GlobalKey<FormState>();
  String? vehicleType;
  String vehicleNumber = '';
  String numberOfSeats = '';

  late List<Map<String, String>> vehicleList;

  @override
  void initState() {
    super.initState();
    vehicleList = List<Map<String, String>>.from(widget.initialVehicles);
  }

  Future<void> addVehicle() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in')),
        );
        return;
      }

      Map<String, dynamic> newVehicle = {
        'type': vehicleType ?? '',
        'number': vehicleNumber,
        'seats': numberOfSeats,
        'timestamp': FieldValue.serverTimestamp(),
      };

      try {
        // Add to Firestore under vehicles/operatorUID/vehicle_list/
        await FirebaseFirestore.instance
            .collection('vehicles')
            .doc(currentUser.uid)
            .collection('vehicle_list')
            .add(newVehicle);

        setState(() {
          vehicleList.add({
            'type': newVehicle['type'],
            'number': newVehicle['number'],
            'seats': newVehicle['seats'],
          });

          vehicleType = null;
          vehicleNumber = '';
          numberOfSeats = '';
          _formKey.currentState?.reset();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehicle added and saved to Firestore')),
        );
      } catch (e) {
        print('Error saving vehicle: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save vehicle to Firestore')),
        );
      }
    }
  }

  void deleteVehicle(int index) {
    setState(() {
      vehicleList.removeAt(index);
    });
  }

  void showVehiclePopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Added Vehicles",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 10),
            vehicleList.isEmpty
                ? const Center(child: Text("No vehicles added yet."))
                : Column(
                    children: vehicleList.asMap().entries.map((entry) {
                      final index = entry.key;
                      final vehicle = entry.value;
                      return Card(
                        child: ListTile(
                          title: Text(
                              '${vehicle['type'] ?? ''} - ${vehicle['number'] ?? ''}',
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text('Seats: ${vehicle['seats'] ?? ''}'),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              Navigator.pop(context);
                              deleteVehicle(index);
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Vehicle"),
        backgroundColor: const Color(0xFF77DDE7),
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 233, 232, 232),
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Text('Enter Vehicle Details',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<String>(
                      value: vehicleType,
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Type',
                        border: UnderlineInputBorder(),
                      ),
                      items: ['Van', 'Bus', 'Auto', 'Car']
                          .map((type) => DropdownMenuItem(
                                value: type,
                                child: Text(type),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => vehicleType = val),
                      validator: (val) => val == null || val.isEmpty
                          ? 'Please select vehicle type'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Vehicle Number',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Enter vehicle number';
                        }
                        final pattern = RegExp(r'^[A-Z]{2}\d{2}[A-Z]{2}\d{4}$');
                        if (!pattern.hasMatch(val)) {
                          return 'Format: MH12AB1234';
                        }
                        return null;
                      },
                      onSaved: (val) => vehicleNumber = val ?? '',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Number of Seats',
                        border: UnderlineInputBorder(),
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
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: addVehicle,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BFA6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        textStyle: const TextStyle(fontSize: 16),
                      ),
                      child: const Text("Add Vehicle"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: showVehiclePopup,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16),
              ),
              child: const Text("Show Added Vehicles",
                  textAlign: TextAlign.center),
            ),
          ],
        ),
      ),
    );
  }
}
