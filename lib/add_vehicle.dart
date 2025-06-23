import 'package:flutter/material.dart';

class AddVehiclePage extends StatefulWidget {
  final List<Map<String, String>> initialVehicles;

  const AddVehiclePage({Key? key, this.initialVehicles = const []}) : super(key: key);

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

  void addVehicle() {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      setState(() {
        vehicleList.add({
          'type': vehicleType ?? '',
          'number': vehicleNumber,
          'seats': numberOfSeats,
        });

        // Reset fields
        vehicleType = null;
        vehicleNumber = '';
        numberOfSeats = '';
        _formKey.currentState?.reset();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vehicle added successfully!')),
      );
    }
  }

  void deleteVehicle(int index) {
    setState(() {
      vehicleList.removeAt(index);
    });
  }

  void showVehiclePopup() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Added Vehicles"),
        content: SizedBox(
          width: double.maxFinite,
          child: vehicleList.isEmpty
              ? const Text("No vehicles added yet.")
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: vehicleList.length,
                  itemBuilder: (_, index) {
                    final vehicle = vehicleList[index];
                    return ListTile(
                      title: Text(
                        '${vehicle['type'] ?? ''} - ${vehicle['number'] ?? ''}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Seats: ${vehicle['seats'] ?? ''}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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
            child: const Text("Close"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
                      const Text(
                        'Enter Vehicle Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: vehicleType,
                        decoration: const InputDecoration(
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
                        validator: (val) => val == null || val.isEmpty
                            ? 'Please select vehicle type'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Number',
                          border: OutlineInputBorder(),
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
                      const SizedBox(height: 12),
                      TextFormField(
                        decoration: const InputDecoration(
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
                      const SizedBox(height: 24),
                      Center(
                        child: ElevatedButton(
                          onPressed: addVehicle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00BFA6),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 30,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(fontSize: 16),
                          ),
                          child: const Text("Add Vehicle"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: showVehiclePopup,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.center,
                child: const Text(
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
