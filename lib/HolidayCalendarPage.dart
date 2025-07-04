import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HolidayCalendarPage extends StatefulWidget {
  const HolidayCalendarPage({Key? key}) : super(key: key);

  @override
  State<HolidayCalendarPage> createState() => _HolidayCalendarPageState();
}

class _HolidayCalendarPageState extends State<HolidayCalendarPage> {
  final Color turquoise = const Color(0xFF77DDE7);
  final Color black = Colors.black;
  final Color white = Colors.white;
  final Color holidayColor = Colors.redAccent;

  DateTime _focusedDay = DateTime.now();
  List<DateTime> _selectedHolidays = [];
  bool _selecting = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _userId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    if (_userId == null) return;
    final doc = await _firestore.collection('holiday_calendars').doc(_userId).get();
    if (doc.exists) {
      final data = doc.data()!;
      final List<dynamic> dates = data['holidays'] ?? [];
      setState(() {
        _selectedHolidays = dates.map((ts) => (ts as Timestamp).toDate()).toList();
      });
    }
  }

  Future<void> _saveHolidays() async {
    if (_userId == null) return;
    await _firestore.collection('holiday_calendars').doc(_userId).set({
      'travellerId': _userId,
      'holidays': _selectedHolidays.map((d) => Timestamp.fromDate(d)).toList(),
    });
  }

  void _toggleHolidaySelection(DateTime day) {
    setState(() {
      if (_selectedHolidays.any((d) => isSameDay(d, day))) {
        _selectedHolidays.removeWhere((d) => isSameDay(d, day));
      } else {
        _selectedHolidays.add(day);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Holiday Calendar'),
        backgroundColor: turquoise,
      ),
      backgroundColor: black,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  _selectedHolidays.any((holiday) => isSameDay(holiday, day)),
              onDaySelected: (selectedDay, focusedDay) {
                if (_selecting) {
                  _toggleHolidaySelection(selectedDay);
                }
                setState(() {
                  _focusedDay = focusedDay;
                });
              },
              calendarStyle: CalendarStyle(
                holidayDecoration: BoxDecoration(
                  color: holidayColor,
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: turquoise,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: turquoise.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                weekendTextStyle: TextStyle(color: white),
                defaultTextStyle: TextStyle(color: white),
                outsideTextStyle: TextStyle(color: white.withOpacity(0.5)),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekendStyle: TextStyle(color: turquoise),
                weekdayStyle: TextStyle(color: turquoise),
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(color: white),
                leftChevronIcon: Icon(Icons.chevron_left, color: white),
                rightChevronIcon: Icon(Icons.chevron_right, color: white),
              ),
              holidayPredicate: (day) =>
                  _selectedHolidays.any((holiday) => isSameDay(holiday, day)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  setState(() {
                    _selecting = !_selecting;
                  });
                  if (!_selecting) {
                    await _saveHolidays();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Saved ${_selectedHolidays.length} holidays!',
                        ),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: turquoise,
                  foregroundColor: black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  _selecting ? 'Finish Selecting Holidays' : 'Edit Holidays',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
