import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/core/providers/places_provider.dart';
import 'package:safarsure/core/services/places_service.dart';

class PlaceAutocompleteField extends ConsumerStatefulWidget {
  const PlaceAutocompleteField({
    super.key,
    required this.label,
    required this.controller,
    this.icon = Icons.location_city,
  });

  final String label;
  final TextEditingController controller;
  final IconData icon;

  @override
  ConsumerState<PlaceAutocompleteField> createState() =>
      _PlaceAutocompleteFieldState();
}

class _PlaceAutocompleteFieldState
    extends ConsumerState<PlaceAutocompleteField> {
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;

  Future<void> _loadSuggestions(String query) async {
    setState(() => _loading = true);
    final service = ref.read(placesServiceProvider);
    final results = await service.autocomplete(query);
    if (mounted) {
      setState(() {
        _suggestions = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<PlaceSuggestion>(
      initialValue: TextEditingValue(text: widget.controller.text),
      optionsBuilder: (textEditingValue) async {
        await _loadSuggestions(textEditingValue.text);
        return _suggestions;
      },
      displayStringForOption: (option) => option.description,
      onSelected: (selection) {
        widget.controller.text = selection.description;
      },
      fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {
        if (widget.controller.text.isNotEmpty && textController.text.isEmpty) {
          textController.text = widget.controller.text;
        }
        textController.addListener(() {
          widget.controller.text = textController.text;
        });
        return TextFormField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            prefixIcon: Icon(widget.icon),
            suffixIcon: _loading
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : null,
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a place';
            }
            return null;
          },
        );
      },
    );
  }
}
