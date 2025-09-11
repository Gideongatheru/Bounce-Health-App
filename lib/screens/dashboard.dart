import 'package:flutter/material.dart';
import 'package:bounce_health/screens/login.dart';
import 'profile.dart';

enum AppointmentStatus { upcoming, completed, cancelled }

class Doctor {
  final String name;
  final String specialization;
  final String bio;
  final String contact;
  final String imageUrl;
  const Doctor({
    required this.name,
    required this.specialization,
    this.bio = '',
    this.contact = '',
    this.imageUrl = '',
  });
}

class Appointment {
  final Doctor doctor;
  final DateTime date;
  final TimeOfDay time;
  AppointmentStatus status;
  final String note;
  Appointment({required this.doctor, required this.date, required this.time, this.status = AppointmentStatus.upcoming, this.note = ''});
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Appointment> _appointments = [];

  @override
  Widget build(BuildContext context) {
    _updateAppointmentStatuses();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Dashboard', 
               style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.blue.shade700,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Profile',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // Header Card with Icon
            Card(
              color: Colors.blue.shade100,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.medical_services, 
                               size: 40, color: Colors.blue),
                    ),
                    const SizedBox(height: 15),
                    Text('Welcome Back!',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                      )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 25),

            // Action Grid
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                mainAxisSpacing: 15,
                crossAxisSpacing: 15,
                children: [
                  _buildActionCard(
                    icon: Icons.calendar_today,
                    label: 'View Appointments',
                    onTap: () => _viewAppointments(context),
                  ),
                  _buildActionCard(
                    icon: Icons.add_circle,
                    label: 'New Appointment',
                    onTap: () => _makeAppointment(context),
                  ),
                  _buildActionCard(
                    icon: Icons.edit_calendar,
                    label: 'Reschedule',
                    onTap: () => _rescheduleAppointment(context),
                  ),
                  _buildActionCard(
                    icon: Icons.cancel,
                    label: 'Cancel',
                    onTap: () => _cancelAppointment(context),
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.logout),
                  label: const Text('LOG OUT'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onPressed: () => _logout(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable Action Card Widget
  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 30, color: Colors.blue.shade700),
              ),
              const SizedBox(height: 10),
              Text(label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.black87,
                )),
            ],
          ),
        ),
      ),
    );
  }

  void _makeAppointment(BuildContext context) async {
    final result = await showDialog<Appointment>(
      context: context,
      builder: (context) => _AppointmentDialog(
        appointments: _appointments,
      ),
    );
    if (result != null) {
      setState(() => _appointments.add(result));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Appointment booked with ${result.doctor.name} on ${result.date.toLocal().toString().split(' ')[0]} at ${result.time.format(context)}'),
        ),
      );
    }
  }

  void _viewAppointments(BuildContext context) {
    _updateAppointmentStatuses();
    showDialog(
      context: context,
      builder: (context) => _AppointmentsViewDialog(appointments: _appointments),
    );
  }

  void _showAppointmentDetails(BuildContext context, Appointment appt) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Appointment Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Doctor: ${appt.doctor.name}'),
            Text('Specialization: ${appt.doctor.specialization}'),
            Text('Date: ${appt.date.toLocal().toString().split(' ')[0]}'),
            Text('Time: ${appt.time.format(context)}'),
            Text('Status: ${_statusToString(appt.status)}', style: TextStyle(color: _statusColor(appt.status))),
            if (appt.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Note: ${appt.note}'),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _rescheduleAppointment(BuildContext context) async {
    if (_appointments.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('No Appointments'),
          content: Text('You have no appointments to reschedule.'),
        ),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => _SelectAppointmentDialog(
        appointments: _appointments,
        action: 'Reschedule',
      ),
    );
    if (selected != null) {
      final appt = _appointments[selected];
      final newDate = await showDatePicker(
        context: context,
        initialDate: appt.date,
        firstDate: DateTime.now(),
        lastDate: DateTime(DateTime.now().year + 1),
      );
      if (newDate != null) {
        final newTime = await showTimePicker(
          context: context,
          initialTime: appt.time,
        );
        if (newTime != null) {
          // Prevent double booking
          final isBooked = _appointments.any((a) =>
              a != appt &&
              a.doctor.name == appt.doctor.name &&
              a.date == newDate &&
              a.time.hour == newTime.hour &&
              a.time.minute == newTime.minute &&
              a.status == AppointmentStatus.upcoming);
          if (isBooked) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('This slot is already booked for this doctor.')),
            );
            return;
          }
          setState(() {
            _appointments[selected] = Appointment(
              doctor: appt.doctor,
              date: newDate,
              time: newTime,
              status: AppointmentStatus.upcoming,
              note: appt.note,
            );
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Appointment rescheduled.')),
          );
        }
      }
    }
  }

  void _cancelAppointment(BuildContext context) async {
    if (_appointments.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => const AlertDialog(
          title: Text('No Appointments'),
          content: Text('You have no appointments to cancel.'),
        ),
      );
      return;
    }
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => _SelectAppointmentDialog(
        appointments: _appointments,
        action: 'Cancel',
      ),
    );
    if (selected != null) {
      setState(() => _appointments[selected].status = AppointmentStatus.cancelled);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled.')),
      );
    }
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/login');
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }

  void _updateAppointmentStatuses() {
    final now = DateTime.now();
    setState(() {
      for (final appt in _appointments) {
        if (appt.status == AppointmentStatus.upcoming) {
          final apptDateTime = DateTime(
            appt.date.year,
            appt.date.month,
            appt.date.day,
            appt.time.hour,
            appt.time.minute,
          );
          if (apptDateTime.isBefore(now)) {
            appt.status = AppointmentStatus.completed;
          }
        }
      }
    });
  }
}

class _AppointmentDialog extends StatefulWidget {
  final List<Appointment> appointments;
  const _AppointmentDialog({super.key, required this.appointments});
  @override
  State<_AppointmentDialog> createState() => _AppointmentDialogState();
}

class _AppointmentDialogState extends State<_AppointmentDialog> {
  final List<Doctor> _doctors = [
    Doctor(
      name: 'Dr. John Smith',
      specialization: 'Cardiologist',
      bio: 'Expert in heart health with 15 years of experience.',
      contact: 'john.smith@hospital.com',
      imageUrl: '',
    ),
    Doctor(
      name: 'Dr. Jane Doe',
      specialization: 'Dermatologist',
      bio: 'Specialist in skin care and dermatological surgery.',
      contact: 'jane.doe@hospital.com',
      imageUrl: '',
    ),
    Doctor(
      name: 'Dr. Emily Johnson',
      specialization: 'Pediatrician',
      bio: 'Caring for children and infants for over a decade.',
      contact: 'emily.johnson@hospital.com',
      imageUrl: '',
    ),
    Doctor(
      name: 'Dr. Michael Brown',
      specialization: 'Orthopedic',
      bio: 'Bone and joint specialist, sports injury expert.',
      contact: 'michael.brown@hospital.com',
      imageUrl: '',
    ),
  ];
  Doctor? _selectedDoctor;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _submitting = false;
  final _noteController = TextEditingController();

  List<TimeOfDay> _availableTimesForDoctor(Doctor doctor, DateTime date) {
    // Example: allow booking every 30 minutes from 9:00 to 17:00
    final times = <TimeOfDay>[];
    for (int h = 9; h < 17; h++) {
      times.add(TimeOfDay(hour: h, minute: 0));
      times.add(TimeOfDay(hour: h, minute: 30));
    }
    // Remove times already booked for this doctor on this date
    final booked = widget.appointments.where((a) =>
        a.doctor.name == doctor.name &&
        a.date == date &&
        a.status == AppointmentStatus.upcoming);
    return times.where((t) => !booked.any((a) => a.time.hour == t.hour && a.time.minute == t.minute)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Appointment'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<Doctor>(
              decoration: const InputDecoration(
                labelText: 'Choose Doctor',
                border: OutlineInputBorder(),
              ),
              value: _selectedDoctor,
              items: _doctors
                  .map((doc) => DropdownMenuItem(
                        value: doc,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(doc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(doc.specialization, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() {
                _selectedDoctor = val;
                _selectedDate = null;
                _selectedTime = null;
              }),
            ),
            if (_selectedDoctor != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.info_outline),
                  label: const Text('View Profile'),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => _DoctorProfileDialog(doctor: _selectedDoctor!),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            ListTile(
              title: Text(_selectedDate == null
                  ? 'Select Date'
                  : 'Date: ${_selectedDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectedDoctor == null
                  ? null
                  : () async {
                      final now = DateTime.now();
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: now,
                        firstDate: now,
                        lastDate: DateTime(now.year + 1),
                      );
                      if (picked != null) {
                        if (picked.isBefore(DateTime(now.year, now.month, now.day))) {
                          showDialog(
                            context: context,
                            builder: (context) => const AlertDialog(
                              title: Text('Invalid Date'),
                              content: Text('You cannot select a date that has already passed.'),
                            ),
                          );
                          return;
                        }
                        setState(() {
                          _selectedDate = picked;
                          _selectedTime = null;
                        });
                      }
                    },
            ),
            ListTile(
              title: Text(_selectedTime == null
                  ? 'Select Time'
                  : 'Time: ${_selectedTime!.format(context)}'),
              trailing: const Icon(Icons.access_time),
              onTap: (_selectedDoctor == null || _selectedDate == null)
                  ? null
                  : () async {
                      final available = _availableTimesForDoctor(_selectedDoctor!, _selectedDate!);
                      if (available.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No available slots for this doctor on this date.')),
                        );
                        return;
                      }
                      final picked = await showDialog<TimeOfDay>(
                        context: context,
                        builder: (context) => SimpleDialog(
                          title: const Text('Select Time'),
                          children: available
                              .map((t) => SimpleDialogOption(
                                    child: Text(t.format(context)),
                                    onPressed: () => Navigator.pop(context, t),
                                  ))
                              .toList(),
                        ),
                      );
                      if (picked != null) {
                        setState(() => _selectedTime = picked);
                      }
                    },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Note/Reason (optional)',
                border: OutlineInputBorder(),
              ),
              minLines: 1,
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submitting || _selectedDoctor == null || _selectedDate == null || _selectedTime == null
              ? null
              : () async {
                  setState(() => _submitting = true);
                  await Future.delayed(const Duration(seconds: 1));
                  Navigator.pop(context, Appointment(
                    doctor: _selectedDoctor!,
                    date: _selectedDate!,
                    time: _selectedTime!,
                    note: _noteController.text.trim(),
                  ));
                },
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Book Appointment'),
        ),
      ],
    );
  }
}

class _SelectAppointmentDialog extends StatelessWidget {
  final List<Appointment> appointments;
  final String action;
  const _SelectAppointmentDialog({required this.appointments, required this.action});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('$action Appointment'),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: appointments.length,
          itemBuilder: (context, i) {
            final appt = appointments[i];
            return ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(appt.doctor.name),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(appt.doctor.specialization, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 2),
                  Text('${appt.date.toLocal().toString().split(' ')[0]} at ${appt.time.format(context)}'),
                  const SizedBox(height: 2),
                  Text('Status: ${_statusToString(appt.status)}', style: TextStyle(fontSize: 13, color: _statusColor(appt.status))),
                ],
              ),
              onTap: () => Navigator.pop(context, i),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }
}

class _AppointmentsViewDialog extends StatefulWidget {
  final List<Appointment> appointments;
  const _AppointmentsViewDialog({super.key, required this.appointments});
  @override
  State<_AppointmentsViewDialog> createState() => _AppointmentsViewDialogState();
}

class _AppointmentsViewDialogState extends State<_AppointmentsViewDialog> {
  String _search = '';
  AppointmentStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    // Sort: Upcoming first, then Completed, then Cancelled, each by date/time
    final sorted = [...widget.appointments];
    sorted.sort((a, b) {
      int statusOrder(AppointmentStatus s) {
        switch (s) {
          case AppointmentStatus.upcoming:
            return 0;
          case AppointmentStatus.completed:
            return 1;
          case AppointmentStatus.cancelled:
            return 2;
        }
      }
      final cmp = statusOrder(a.status).compareTo(statusOrder(b.status));
      if (cmp != 0) return cmp;
      final aDateTime = DateTime(a.date.year, a.date.month, a.date.day, a.time.hour, a.time.minute);
      final bDateTime = DateTime(b.date.year, b.date.month, b.date.day, b.time.hour, b.time.minute);
      return aDateTime.compareTo(bDateTime);
    });
    final filtered = sorted.where((appt) {
      final matchesSearch = _search.isEmpty ||
        appt.doctor.name.toLowerCase().contains(_search.toLowerCase()) ||
        appt.doctor.specialization.toLowerCase().contains(_search.toLowerCase()) ||
        appt.note.toLowerCase().contains(_search.toLowerCase());
      final matchesStatus = _filterStatus == null || appt.status == _filterStatus;
      return matchesSearch && matchesStatus;
    }).toList();
    return AlertDialog(
      title: const Text('Your Appointments'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search by doctor, specialization, or note',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Filter:'),
                const SizedBox(width: 8),
                DropdownButton<AppointmentStatus?>(
                  value: _filterStatus,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('All'),
                    ),
                    ...AppointmentStatus.values.map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_statusToString(s)),
                        )),
                  ],
                  onChanged: (val) => setState(() => _filterStatus = val),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(child: Text('No appointments found.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: filtered.length,
                      itemBuilder: (context, i) {
                        final appt = filtered[i];
                        return ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: Text(appt.doctor.name),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(appt.doctor.specialization, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                              const SizedBox(height: 2),
                              Text('${appt.date.toLocal().toString().split(' ')[0]} at ${appt.time.format(context)}'),
                              const SizedBox(height: 2),
                              Text('Status: ${_statusToString(appt.status)}', style: TextStyle(fontSize: 13, color: _statusColor(appt.status))),
                              if (appt.note.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text('Note: ${appt.note}'),
                              ],
                            ],
                          ),
                          onTap: () => Navigator.of(context).pop(),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _statusToString(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return 'Upcoming';
      case AppointmentStatus.completed:
        return 'Completed';
      case AppointmentStatus.cancelled:
        return 'Cancelled';
    }
  }

  Color _statusColor(AppointmentStatus status) {
    switch (status) {
      case AppointmentStatus.upcoming:
        return Colors.blue;
      case AppointmentStatus.completed:
        return Colors.green;
      case AppointmentStatus.cancelled:
        return Colors.red;
    }
  }
}

class _DoctorProfileDialog extends StatelessWidget {
  final Doctor doctor;
  const _DoctorProfileDialog({super.key, required this.doctor});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(doctor.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Specialization: ${doctor.specialization}'),
          const SizedBox(height: 8),
          if (doctor.bio.isNotEmpty) ...[
            Text('Bio:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(doctor.bio),
            const SizedBox(height: 8),
          ],
          if (doctor.contact.isNotEmpty) ...[
            Text('Contact:', style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(doctor.contact),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }
}