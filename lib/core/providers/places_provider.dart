import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:safarsure/core/services/places_service.dart';

final placesServiceProvider = Provider<PlacesService>((ref) => PlacesService());
