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
  bool _showSuggestions = false;
  bool _selecting = false;
  String? _mapsErrorHint;
  Timer? _debounce;

  static const _debounceDuration = Duration(milliseconds: 200);
  static const _selectingHoldDuration = Duration(milliseconds: 300);

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
    if (_selecting) return;

    if (_focusNode.hasFocus) {
      setState(() => _showSuggestions = true);
      _loadSuggestions(widget.controller.text);
      return;
    }

    // Web: focus may leave the TextField before tap completes.
    Future<void>.delayed(const Duration(milliseconds: 200), () {
      if (!mounted || _selecting || _focusNode.hasFocus) return;
      setState(() => _showSuggestions = false);
    });
  }

  void _onTextChanged() {
    if (_selecting) return;
    if (!_showSuggestions && !_focusNode.hasFocus) return;

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () {
      if (_selecting) return;
      _loadSuggestions(widget.controller.text);
    });
  }

  Future<void> _loadSuggestions(String query) async {
    if (!mounted || _selecting) return;
    if (!_showSuggestions && !_focusNode.hasFocus) return;

    setState(() => _loading = true);
    final service = ref.read(placesServiceProvider);
    final results = await service.autocomplete(query);
    if (!mounted || _selecting) return;

    setState(() {
      _suggestions = results.suggestions;
      _mapsErrorHint = results.mapsErrorHint;
      _loading = false;
      // Never force the list open here — callers open explicitly; selection closes it.
    });
  }

  void _selectSuggestion(PlaceSuggestion suggestion) {
    if (_selecting) return;

    _selecting = true;
    _debounce?.cancel();

    widget.controller.removeListener(_onTextChanged);
    widget.controller.text = suggestion.canonicalName;
    widget.controller.addListener(_onTextChanged);

    setState(() {
      _showSuggestions = false;
      _suggestions = const [];
      _loading = false;
    });
    _focusNode.unfocus();

    Future<void>.delayed(_selectingHoldDuration, () {
      if (mounted) _selecting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
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
                : (_showSuggestions
                    ? IconButton(
                        icon: const Icon(Icons.keyboard_hide),
                        onPressed: () {
                          setState(() => _showSuggestions = false);
                          _focusNode.unfocus();
                        },
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
            if (_selecting) return;
            setState(() => _showSuggestions = true);
            _loadSuggestions(widget.controller.text);
          },
        ),
        if (_mapsErrorHint != null) ...[
          const SizedBox(height: 4),
          Text(
            _mapsErrorHint!,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.charcoalMuted,
                ),
          ),
        ],
        if (_showSuggestions) ...[
          const SizedBox(height: 8),
          Material(
            elevation: 1,
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260),
              child: _loading && _suggestions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : _suggestions.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(16),
                          child: Text(
                            'No matching cities',
                            style: TextStyle(color: AppColors.charcoalMuted),
                          ),
                        )
                      : Scrollbar(
                          thumbVisibility: _suggestions.length > 6,
                          child: ListView.separated(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: _suggestions.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final suggestion = _suggestions[index];
                              return Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => _selectSuggestion(suggestion),
                                  child: Listener(
                                    behavior: HitTestBehavior.translucent,
                                    onPointerDown: (_) =>
                                        _selectSuggestion(suggestion),
                                    child: ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.location_on_outlined,
                                        size: 20,
                                        color: AppColors.primary,
                                      ),
                                      title: Text(suggestion.displayLabel),
                                      subtitle:
                                          suggestion.displayLabel !=
                                                  suggestion.canonicalName
                                              ? Text(
                                                  suggestion.canonicalName,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall,
                                                )
                                              : null,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
            ),
          ),
        ],
      ],
    );
  }
}
