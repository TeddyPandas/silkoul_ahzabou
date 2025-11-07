import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/campaign_provider.dart';
import '../../providers/auth_provider.dart';

class CreateCampaignScreen extends StatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  State<CreateCampaignScreen> createState() => _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends State<CreateCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _accessCodeController = TextEditingController();
  String? _selectedCategory;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 7));
  bool _isPublic = true;
  final bool _isWeekly =
      false; // Not used in backend yet, but kept for consistency

  final List<Map<String, dynamic>> _tasks = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _accessCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null && picked != (isStartDate ? _startDate : _endDate)) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_startDate.isAfter(_endDate)) {
            _endDate = _startDate.add(const Duration(days: 7));
          }
        } else {
          _endDate = picked;
          if (_endDate.isBefore(_startDate)) {
            _startDate = _endDate.subtract(const Duration(days: 7));
          }
        }
      });
    }
  }

  void _addTask() {
    setState(() {
      _tasks.add({
        'name': '',
        'number': 0,
        'daily_goal': 0,
      });
    });
  }

  void _removeTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  Future<void> _createCampaign() async {
    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final campaignProvider =
          Provider.of<CampaignProvider>(context, listen: false);
      final userId = authProvider.user?.id;

      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated.')),
        );
        return;
      }

      try {
        final campaignId = await campaignProvider.createCampaign(
          name: _nameController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          startDate: _startDate,
          endDate: _endDate,
          category: _selectedCategory,
          isPublic: _isPublic,
          accessCode: _isPublic ? null : _accessCodeController.text,
          isWeekly: _isWeekly,
          tasks: _tasks,
          createdBy: '',
        );

        if (campaignId != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Campaign created successfully!')),
          );
          Navigator.of(context).pop();
        } else if (campaignProvider.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${campaignProvider.errorMessage}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create campaign: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create New Campaign'),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Campaign Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a campaign name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration:
                    const InputDecoration(labelText: 'Description (Optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ListTile(
                      title: const Text('Start Date'),
                      subtitle: Text(_startDate
                          .toLocal()
                          .toIso8601String()
                          .split('T')
                          .first),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  Expanded(
                    child: ListTile(
                      title: const Text('End Date'),
                      subtitle: Text(_endDate
                          .toLocal()
                          .toIso8601String()
                          .split('T')
                          .first),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration:
                    const InputDecoration(labelText: 'Category (Optional)'),
                items: <String>['Zikr', 'Quran', 'Dua', 'Charity', 'Community']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Public Campaign'),
                value: _isPublic,
                onChanged: (bool value) {
                  setState(() {
                    _isPublic = value;
                  });
                },
              ),
              if (!_isPublic)
                TextFormField(
                  controller: _accessCodeController,
                  decoration: const InputDecoration(
                      labelText: 'Access Code (for private campaigns)'),
                  validator: (value) {
                    if (!_isPublic && (value == null || value.isEmpty)) {
                      return 'Please enter an access code for private campaigns';
                    }
                    return null;
                  },
                ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tasks',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _addTask,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Task'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                          TextFormField(
                            initialValue: _tasks[index]['name'],
                            decoration: InputDecoration(
                              labelText: 'Task Name',
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _removeTask(index),
                              ),
                            ),
                            onChanged: (value) => _tasks[index]['name'] = value,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter a task name';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            initialValue: _tasks[index]['number'].toString(),
                            decoration: const InputDecoration(
                                labelText: 'Total Number'),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _tasks[index]['number'] =
                                int.tryParse(value) ?? 0,
                            validator: (value) {
                              if (value == null ||
                                  int.tryParse(value) == null ||
                                  int.parse(value) <= 0) {
                                return 'Please enter a valid total number';
                              }
                              return null;
                            },
                          ),
                          TextFormField(
                            initialValue:
                                _tasks[index]['daily_goal'].toString(),
                            decoration: const InputDecoration(
                                labelText: 'Daily Goal (Optional)'),
                            keyboardType: TextInputType.number,
                            onChanged: (value) => _tasks[index]['daily_goal'] =
                                int.tryParse(value) ?? 0,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(
                  onPressed: _createCampaign,
                  child: const Text('Create Campaign'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
