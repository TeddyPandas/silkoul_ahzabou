
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../models/wazifa_gathering.dart';
import '../../providers/wazifa_provider.dart';
import 'package:latlong2/latlong.dart';
import 'location_picker_screen.dart';

class AddWazifaScreen extends StatefulWidget {
  const AddWazifaScreen({Key? key}) : super(key: key);

  @override
  State<AddWazifaScreen> createState() => _AddWazifaScreenState();
}

class _AddWazifaScreenState extends State<AddWazifaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();

  WazifaRhythm _selectedRhythm = WazifaRhythm.MEDIUM;
  TimeOfDay _morningTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _eveningTime = const TimeOfDay(hour: 19, minute: 0);
  Position? _pickedPosition;

  bool _isLocating = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLocating = true);
    try {
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _pickedPosition = position;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur localisation: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLocating = false);
    }
  }

  Future<void> _pickOnMap() async {
    // Utiliser la position actuelle ou Dakar par défaut
    final initialLat = _pickedPosition?.latitude ?? 14.6928;
    final initialLng = _pickedPosition?.longitude ?? -17.4467;

    print("Navigating to LocationPickerScreen with lat: $initialLat, lng: $initialLng"); // Debug log

    final result = await Navigator.push<LatLng>(
      context,
      MaterialPageRoute(
        builder: (context) => LocationPickerScreen(
          initialLat: initialLat,
          initialLng: initialLng,
        ),
      ),
    );

    if (result != null && mounted) {
      print("LocationPicker returned: ${result.latitude}, ${result.longitude}"); // Debug log
      setState(() {
        // On crée un objet Position "artificiel" pour le stocker
        _pickedPosition = Position(
          longitude: result.longitude,
          latitude: result.latitude,
          timestamp: DateTime.now(),
          accuracy: 10.0,
          altitude: 0.0,
          heading: 0.0,
          speed: 0.0,
          speedAccuracy: 0.0,
          altitudeAccuracy: 0.0, 
          headingAccuracy: 0.0
        );
      });
    }
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      if (_pickedPosition == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez obtenir votre position GPS')),
        );
        return;
      }

      try {
        await Provider.of<WazifaProvider>(context, listen: false).addGathering(
          name: _nameController.text,
          description: _descController.text,
          lat: _pickedPosition!.latitude,
          lng: _pickedPosition!.longitude,
          rhythm: _selectedRhythm,
          scheduleMorning: _formatTime(_morningTime),
          scheduleEvening: _formatTime(_eveningTime),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Lieu ajouté avec succès ! 🕌')),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur: $e')),
          );
        }
      }
    }
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute'; // HH:mm
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Si on a une position depuis le provider (quand on vient de la carte), on peut l'utiliser
    // mais ici on veut forcement la position *actuelle* précise pour l'ajout.

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajouter un lieu Wazifa'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- NOM ---
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nom du lieu (Ex: Zawiya...)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.mosque),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nom requis' : null,
              ),
              const SizedBox(height: 16),

              // --- DESCRIPTION ---
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optionnel)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                  hintText: 'Ex: Tapis disponibles, entrée latérale...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // --- RYTHME (Choice Chips) ---
              const Text('Rythme de la Wazifa',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildRhythmChip(WazifaRhythm.SLOW, "Lent 🐢", Colors.green),
                  _buildRhythmChip(
                      WazifaRhythm.MEDIUM, "Moyen 🚶", Colors.orange),
                  _buildRhythmChip(WazifaRhythm.FAST, "Rapide 🏃", Colors.red),
                ],
              ),
              const SizedBox(height: 20),

              // --- HORAIRES ---
              const Text('Horaires Habituels',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTimePicker(
                      context,
                      label: "Matin (Subh)",
                      time: _morningTime,
                      onChanged: (t) => setState(() => _morningTime = t),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimePicker(
                      context,
                      label: "Soir (Timis)",
                      time: _eveningTime,
                      onChanged: (t) => setState(() => _eveningTime = t),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // --- LOCATION CARD ---
              Card(
                color: theme.colorScheme.surfaceVariant,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_on),
                          SizedBox(width: 8),
                          Text("Localisation GPS",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (_isLocating)
                        const LinearProgressIndicator()
                      else if (_pickedPosition != null)
                        Text(
                          "${_pickedPosition!.latitude.toStringAsFixed(5)}, ${_pickedPosition!.longitude.toStringAsFixed(5)}",
                          style: const TextStyle(fontSize: 18),
                        )
                      else
                        const Text("Aucune position détectée"),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton.icon(
                            onPressed: _getCurrentLocation,
                            icon: const Icon(Icons.my_location),
                            label: const Text('Ma Position'),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickOnMap,
                            icon: const Icon(Icons.map),
                            label: const Text('Choisir sur carte'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // --- SUBMIT ---
              Consumer<WazifaProvider>(
                builder: (context, provider, child) {
                  return ElevatedButton(
                    onPressed: provider.isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    child: provider.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('ENREGISTRER LE LIEU',
                            style: TextStyle(fontSize: 18)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRhythmChip(WazifaRhythm value, String label, Color color) {
    final isSelected = _selectedRhythm == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _selectedRhythm = value),
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      avatar: isSelected ? null : CircleAvatar(backgroundColor: color, radius: 4),
    );
  }

  Widget _buildTimePicker(BuildContext context,
      {required String label,
      required TimeOfDay time,
      required ValueChanged<TimeOfDay> onChanged}) {
    return InkWell(
      onTap: () async {
        final picked =
            await showTimePicker(context: context, initialTime: time);
        if (picked != null) onChanged(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.access_time),
        ),
        child: Text(
          _formatTime(time),
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
