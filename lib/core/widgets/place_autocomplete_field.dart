import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/core/providers/places_provider.dart';
import 'package:safarsure/core/services/places_service.dart';
import 'package:safarsure/core/theme/app_colors.dart';

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
  final _focusNode = FocusNode();
  List<PlaceSuggestion> _suggestions = const [];
  bool _loading = false;
  bool _focused = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _focusNode.removeListener(_onFocusChanged);
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() => _focused = _focusNode.hasFocus);
    if (_focusNode.hasFocus) {
      _loadSuggestions(widget.controller.text);
    }
  }

  void _onTextChanged() {
    if (!_focused) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      _loadSuggestions(widget.controller.text);
    });
  }

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

  void _selectSuggestion(PlaceSuggestion suggestion) {
    widget.controller.text = suggestion.description;
    setState(() {
      _focused = false;
      _suggestions = const [];
    });
    _focusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final showList = _focused;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: widget.controller,
          focusNode: _focusNode,
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
                : (_focused
                    ? IconButton(
                        icon: const Icon(Icons.keyboard_hide),
                        onPressed: () => _focusNode.unfocus(),
                      )
                    : null),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter a place';
            }
            return null;
          },
          onTap: () {
            if (!_focused) {
              _loadSuggestions(widget.controller.text);
            }
          },
        ),
        if (showList) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: _suggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Type to filter cities…',
                        style: TextStyle(color: AppColors.charcoalMuted),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _suggestions.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final suggestion = _suggestions[index];
                        return ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.location_on_outlined,
                            size: 20,
                            color: AppColors.primary,
                          ),
                          title: Text(suggestion.description),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      },
                    ),
            ),
          ),
        ],
      ],
    );
  }
}
