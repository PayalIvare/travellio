import 'package:flutter/material.dart';
import 'SelectSchool.dart';
import 'HolidayCalendarPage.dart';
import 'LiveLocationPage.dart';

class TravellerDashboard extends StatefulWidget {
  const TravellerDashboard({Key? key}) : super(key: key);

  @override
  State<TravellerDashboard> createState() => _TravellerDashboardState();
}

class _TravellerDashboardState extends State<TravellerDashboard> {
  static const Color turquoise = Color(0xFF77DDE7);
  static const Color black = Colors.black;
  static const Color white = Colors.white;

  String travellerName = "Traveller";
  List<dynamic> schoolData = [];

  @override
  void initState() {
    super.initState();
    _loadTravellerData();
  }

  /// ✅ Load name and schools locally (or later from DB)
  void _loadTravellerData() {
    travellerName = "Traveller"; // Replace with logged-in user if needed

    schoolData = [
      {
        "name": "ABC School",
        "routes": [
          {
            "start": "Point A",
            "end": "Point B",
            "stops": ["Stop 1", "Stop 2", "Stop 3"]
          }
        ],
      },
      {
        "name": "XYZ School",
        "routes": [
          {
            "start": "X",
            "end": "Y",
            "stops": ["X1", "X2", "X3"]
          }
        ],
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      body: Column(
        children: [
          // ✅ Top bar
          Container(
            color: turquoise,
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: white),
                  onPressed: () => Navigator.pop(context),
                ),
                IconButton(
                  icon: const Icon(Icons.menu, color: white),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Menu tapped')),
                    );
                  },
                ),
              ],
            ),
          ),

          // ✅ Hello block
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              color: turquoise,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hello,', style: TextStyle(color: white, fontSize: 24)),
                Text(
                  travellerName.isNotEmpty ? travellerName : "Traveller",
                  style: const TextStyle(
                    color: white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  'Your Transport Solution',
                  style: TextStyle(color: white, fontSize: 20),
                ),
              ],
            ),
          ),

          // ✅ Dashboard buttons grid
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  buildDashboardButton(
                    icon: Icons.school,
                    label: 'Select School',
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectSchool(
                            initialSchoolData: schoolData,
                          ),
                        ),
                      );
                      if (result != null) {
                        debugPrint('Selected school: $result');
                      }
                    },
                  ),
                  buildDashboardButton(
                    icon: Icons.business,
                    label: 'Select Operator',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Select Operator tapped')),
                      );
                    },
                  ),
                  buildDashboardButton(
                    icon: Icons.location_on,
                    label: 'Live Location',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LiveLocationPage(),
                        ),
                      );
                    },
                  ),
                  buildDashboardButton(
                    icon: Icons.calendar_today,
                    label: 'Calendar',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HolidayCalendarPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildDashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: black,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 2,
              offset: Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: turquoise),
              const SizedBox(height: 10),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  color: turquoise,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
