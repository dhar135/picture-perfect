import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/poll_view_model.dart';
import 'package:picture_perfect/src/presentation/widgets/common/dynamic_scaffold.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/image_picker_util.dart';
import '../../../data/models/poll_model.dart';

class CreatePollPage extends StatefulWidget {
  const CreatePollPage({super.key});

  @override
  State<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends State<CreatePollPage> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  final _formData = PollFormData();

  // Controllers for Text Fields
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _captionOneController = TextEditingController();
  final _captionTwoController = TextEditingController();

  File? _imageOne;
  File? _imageTwo;
  bool _isLoading = false;
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _captionOneController.dispose();
    _captionTwoController.dispose();
    super.dispose();
  }

  // Handle Step changes
  void _onStepContinue() {
    final isLastStep = _currentStep == 3;

    if (isLastStep) {
      _submitPoll();
    } else {
      setState(() {
        _currentStep += 1;
      });
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    } else {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DynamicScaffold(
        child: Form(
            key: _formKey,
            child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                steps: [
                  _buildBasicInfoStep(),
                  _buildImagesStep(),
                  _buildSettingsStep(),
                  _buildPreviewStep()
                ])));
  }

  // Create Poll Steps
  Step _buildBasicInfoStep() {
    return Step(
        title: const Text('Basic Info'),
        content: Padding(
          padding: EdgeInsets.only(top: 5),
          child: Column(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                    labelText: 'Title', hintText: 'Enter your poll title'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a title';
                  }
                  return null;
                },
                onSaved: (value) => _formData.title = value,
              ),
              const SizedBox(
                height: 16,
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                    labelText: 'Description (Optional)',
                    hintText: 'Enter poll description'),
                maxLines: 3,
                onSaved: (value) => _formData.description = value,
              )
            ],
          ),
        ),
        isActive: _currentStep >= 0,
        state: _validateBasicInfo() ? StepState.complete : StepState.indexed);
  }

  Step _buildImagesStep() {
    return Step(
      title: const Text('Images'),
      content: Container(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Image One Selection
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: _buildImageSelector(
                        "Image One",
                        _imageOne,
                        () => _selectImage(true),
                        _captionOneController,
                      ),
                    ),
                  ),
                ),
                // Image Two Selection
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Card(
                      child: _buildImageSelector(
                        "Image Two",
                        _imageTwo,
                        () => _selectImage(false),
                        _captionTwoController,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_imageOne != null && _imageTwo != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Hold images to preview',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
      isActive: _currentStep >= 1,
      state: _validateImagesStep() ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildSettingsStep() {
    final theme = Theme.of(context);

    return Step(
      title: const Text('Settings'),
      content: Container(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category Dropdown
            DropdownButtonFormField<PollCategory>(
              value: _formData.category,
              decoration: InputDecoration(
                labelText: 'Category',
                hintText: 'Select poll category',
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: theme.colorScheme.primary),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary.withOpacity(0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
              ),
              dropdownColor: theme.colorScheme.surface,
              items: PollCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(
                    category.toString().split('.').last,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _formData.category = value ?? PollCategory.other;
                });
              },
            ),
            const SizedBox(height: 24),

            // Voting Type Selection
            Text(
              'Voting Type',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<PollVotingType>(
                    title: const Text('Public'),
                    value: PollVotingType.nonAnonymous,
                    groupValue: _formData.votingType,
                    onChanged: (value) {
                      setState(() {
                        _formData.votingType =
                            value ?? PollVotingType.nonAnonymous;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<PollVotingType>(
                    title: const Text('Anonymous'),
                    value: PollVotingType.anonymous,
                    groupValue: _formData.votingType,
                    onChanged: (value) {
                      setState(() {
                        _formData.votingType =
                            value ?? PollVotingType.anonymous;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Deadline Picker
            Text(
              'Poll Deadline (Optional)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    readOnly: true,
                    controller: TextEditingController(
                      text: _deadline != null
                          ? DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(_deadline!)
                          : 'No deadline set',
                    ),
                    decoration: InputDecoration(
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_deadline != null)
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                setState(() {
                                  _deadline = null;
                                  _formData.deadline = null;
                                });
                              },
                            ),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _showDeadlinePicker,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isActive: _currentStep >= 2,
      state: _validateSettingsStep() ? StepState.complete : StepState.indexed,
    );
  }

  Step _buildPreviewStep() {
    final theme = Theme.of(context);
    return Step(
        title: const Text('Preview'),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Title and Description
                    Text(
                      _titleController.text.isEmpty
                          ? 'No Title'
                          : _titleController.text,
                      style: theme.textTheme.titleLarge,
                    ),
                    if (_descriptionController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _descriptionController.text,
                        style: theme.textTheme.bodyMedium,
                      )
                    ],
                    const SizedBox(height: 16),

                    // Images
                    Row(
                      children: [
                        Expanded(
                            child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _imageOne != null
                                  ? Image.file(
                                      _imageOne!,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            if (_captionOneController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_captionOneController.text),
                              )
                          ],
                        )),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: _imageTwo != null
                                  ? Image.file(
                                      _imageTwo!,
                                      height: 150,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.image),
                                    ),
                            ),
                            if (_captionTwoController.text.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(_captionTwoController.text),
                              )
                          ],
                        ))
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Poll Details
                    _buildDetailRow('Category',
                        _formData.category.toString().split('.').last),

                    _buildDetailRow(
                        'Voting Type',
                        _formData.votingType == PollVotingType.anonymous
                            ? 'Anonymous'
                            : 'Public'),
                    if (_deadline != null)
                      _buildDetailRow(
                          'Deadline',
                          DateFormat('MMM dd, yyyy - hh:mm a')
                              .format(_deadline!))
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
                onPressed: _isLoading ? null : _submitPoll,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Poll'))
          ],
        ),
        isActive: _currentStep >= 3);
  }

  /// Widgets Below
  Widget _buildImageSelector(
    String label,
    File? image,
    VoidCallback onTap,
    TextEditingController captionController,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: _isLoading ? null : onTap,
          onLongPress: image != null ? () => _previewImage(image) : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator()
                else if (image != null)
                  Stack(
                    alignment: Alignment.topRight,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          image,
                          height: 100,
                          width: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeImage(label == "Image One"),
                      ),
                    ],
                  )
                else
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_photo_alternate, size: 50),
                  ),
                const SizedBox(height: 8),
                Text(label),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: TextFormField(
            controller: captionController,
            decoration: InputDecoration(
              labelText: 'Caption (Optional)',
              hintText: 'Add a caption',
              isDense: true,
            ),
            maxLength: 50,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  /// Utility Functions Below

  // Enhanced image selection method
  Future<void> _selectImage(bool isFirstImage) async {
    setState(() => _isLoading = true);
    try {
      final image = await ImagePickerUtil.showImagePickerOptions(context);
      if (image != null) {
        setState(() {
          if (isFirstImage) {
            _imageOne = image;
          } else {
            _imageTwo = image;
          }
        });
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Remove image
  void _removeImage(bool isFirstImage) {
    setState(() {
      if (isFirstImage) {
        _imageOne = null;
        _captionOneController.clear();
      } else {
        _imageTwo = null;
        _captionTwoController.clear();
      }
    });
  }

  // Preview image
  void _previewImage(File image) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Stack(
          children: [
            Image.file(image),
            Positioned(
              right: 8,
              top: 8,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeadlinePicker() async {
    final DateTime now = DateTime.now();
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)), // Max 30 days
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          _deadline = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          _formData.deadline = _deadline;
        });
      }
    }
  }

  // Submit poll method
  Future<void> _submitPoll() async {
    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please complete all required fields'),
          backgroundColor: Colors.red));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authViewModel = context.read<AuthViewModel>();
      final pollViewModel = context.read<PollViewModel>();

      final success = await pollViewModel.createPoll(
          creatorId: authViewModel.currentUser!.id,
          title: _titleController.text,
          description: _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          imageOne: _imageOne!,
          imageTwo: _imageTwo!,
          captionOne: _captionOneController.text.isEmpty
              ? null
              : _captionOneController.text,
          captionTwo: _captionTwoController.text.isEmpty
              ? null
              : _captionTwoController.text,
          category: _formData.category!,
          votingType: _formData.votingType,
          deadline: _deadline,
          status: PollStatus.active);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Poll created successfully'),
            backgroundColor: Colors.green,
          ));
          context.go('/home');
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Failed to create poll: ${pollViewModel.errorMessage ?? 'Unknown error'}'),
            backgroundColor: Colors.red,
          ));
        }
      }
    } catch (e) {
      AppLogger.error('Error creating poll: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error creating poll: ${e.toString()}'),
          backgroundColor: Colors.red,
        ));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Validation
  bool _validateImagesStep() {
    return _imageOne != null && _imageTwo != null;
  }

  bool _validateSettingsStep() {
    return _formData.category != null;
  }

  bool _validateBasicInfo() {
    return _formData.title != null;
  }

  bool _validateAll() {
    return _titleController.text.isNotEmpty &&
        _imageOne != null &&
        _imageTwo != null &&
        _formData.category != null;
  }
}

class PollFormData {
  String? title;
  String? description;
  File? imageOne;
  File? imageTwo;
  String? captionOne;
  String? captionTwo;
  PollCategory? category;
  PollVotingType votingType = PollVotingType.nonAnonymous;
  DateTime? deadline;
  PollStatus status = PollStatus.active;
}
