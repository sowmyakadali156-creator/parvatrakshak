import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/incident.dart';
import '../../services/app_store.dart';
import '../../services/location_service.dart';
import '../../theme/app_theme.dart';
import 'incident_details.dart';

class ReportEmergency extends StatefulWidget {
  const ReportEmergency({super.key});

  @override
  State<ReportEmergency> createState() => _ReportEmergencyState();
}

class _ReportEmergencyState extends State<ReportEmergency> {
  IncidentCategory category = IncidentCategory.medical;
  int people = 1;
  final descriptionController = TextEditingController();
  XFile? photo;
  Position? position;
  bool locationLoading = false;
  bool submitting = false;

  @override
  void dispose() {
    descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report emergency')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = constraints.maxWidth > 850 ? 760.0 : 680.0;
          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StepHeader(
                      step: '01',
                      title: 'What happened?',
                      subtitle: 'Choose the closest emergency category.',
                    ),
                    const SizedBox(height: 12),
                    _categoryGrid(),
                    const SizedBox(height: 22),
                    _StepHeader(
                      step: '02',
                      title: 'People affected',
                      subtitle: 'This helps RescueGrid calculate severity.',
                    ),
                    const SizedBox(height: 12),
                    _peopleSelector(),
                    const SizedBox(height: 22),
                    _StepHeader(
                      step: '03',
                      title: 'Where is it?',
                      subtitle: 'GPS is used to help responders reach you.',
                    ),
                    const SizedBox(height: 12),
                    _locationCard(),
                    const SizedBox(height: 22),
                    _StepHeader(
                      step: '04',
                      title: 'Evidence & details',
                      subtitle: 'Add a photo and any useful context.',
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descriptionController,
                      maxLines: 4,
                      maxLength: 240,
                      decoration: const InputDecoration(
                        hintText: 'Example: Smoke coming from the second floor...',
                        labelText: 'Description (optional)',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _photoPicker(),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: submitting ? null : _submit,
                        icon: submitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.sos_rounded),
                        label: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            submitting
                                ? 'ANALYSING & DISPATCHING...'
                                : 'REPORT EMERGENCY',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              letterSpacing: .5,
                            ),
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Center(
                      child: Text(
                        'RescueGrid will automatically assess severity and find the best available responder.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _categoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: IncidentCategory.values.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 3 : 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.55,
      ),
      itemBuilder: (context, index) {
        final item = IncidentCategory.values[index];
        final selected = category == item;
        return InkWell(
          onTap: () => setState(() => category = item),
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: selected ? AppTheme.blue : Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppTheme.blue : const Color(0xFFE0E6EE),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  item.icon,
                  color: selected ? Colors.white : AppTheme.blue,
                  size: 27,
                ),
                const SizedBox(height: 7),
                Text(
                  item.label,
                  style: TextStyle(
                    color: selected ? Colors.white : AppTheme.navy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _peopleSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFEAF2FF),
              child: Icon(Icons.groups_rounded, color: AppTheme.blue),
            ),
            const SizedBox(width: 13),
            const Expanded(
              child: Text(
                'Estimated people affected',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              onPressed: people > 1 ? () => setState(() => people--) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Text(
              '$people',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            IconButton(
              onPressed: people < 50 ? () => setState(() => people++) : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      ),
    );
  }

  Widget _locationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFE8F7F0),
              child: Icon(Icons.location_on_rounded, color: AppTheme.green),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    position == null
                        ? 'Location not captured'
                        : 'GPS location captured',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    position == null
                        ? 'Tap the button to use your current position.'
                        : '${position!.latitude.toStringAsFixed(5)}, ${position!.longitude.toStringAsFixed(5)}',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: locationLoading ? null : _captureLocation,
              child: Text(locationLoading ? '...' : 'CAPTURE'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPicker() {
    return InkWell(
      onTap: _pickPhoto,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(17),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE0E6EE)),
        ),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFFFF2E7),
              child: Icon(Icons.camera_alt_rounded, color: AppTheme.orange),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    photo == null ? 'Attach emergency photo' : 'Photo attached ✓',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    photo == null
                        ? 'Camera or gallery • optional'
                        : 'Evidence is ready to be submitted.',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.add_a_photo_rounded),
          ],
        ),
      ),
    );
  }

  Future<void> _captureLocation() async {
    setState(() => locationLoading = true);
    final result = await CampusLocation.getCurrentPosition();
    if (!mounted) return;
    setState(() {
      position = result;
      locationLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result == null
              ? 'GPS unavailable. Demo campus location will be used.'
              : 'Current GPS location captured.',
        ),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final result = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1400,
      );
      if (result != null) {
        setState(() => photo = result);
      }
    } catch (_) {
      final result = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (result != null) {
        setState(() => photo = result);
      }
    }
  }

  Future<void> _submit() async {
    setState(() => submitting = true);

    var lat = position?.latitude ?? CampusLocation.fallbackLatitude;
    var lon = position?.longitude ?? CampusLocation.fallbackLongitude;

    if (position == null) {
      final current = await CampusLocation.getCurrentPosition();
      if (current != null) {
        lat = current.latitude;
        lon = current.longitude;
      }
    }

    await Future<void>.delayed(const Duration(milliseconds: 650));

    final incident = AppStore.instance.createIncident(
      category: category,
      description: descriptionController.text.trim().isEmpty
          ? 'Emergency reported from campus.'
          : descriptionController.text.trim(),
      peopleAffected: people,
      latitude: lat,
      longitude: lon,
      locationLabel: position == null
          ? CampusLocation.fallbackLabel
          : 'Current GPS position',
      photoPath: photo?.path,
    );

    if (!mounted) return;

    setState(() => submitting = false);

    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => IncidentDetails(incident: incident, showSuccess: true),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _StepHeader({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 35,
          height: 35,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppTheme.blue,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Text(
            step,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 3),
              Text(subtitle, style: TextStyle(color: Colors.grey.shade600)),
            ],
          ),
        ),
      ],
    );
  }
}
