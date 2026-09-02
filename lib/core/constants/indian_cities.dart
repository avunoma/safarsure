const List<String> indianCities = [
  'Bengaluru',
  'Chennai',
  'Hyderabad',
  'Mumbai',
  'Pune',
  'Delhi',
  'Jaipur',
  'Kolkata',
  'Ahmedabad',
  'Goa',
  'Kochi',
  'Lucknow',
  'Chandigarh',
  'Indore',
  'Nagpur',
];

List<String> filterCities(String query) {
  if (query.trim().isEmpty) {
    return indianCities;
  }
  final lower = query.toLowerCase();
  return indianCities
      .where((city) => city.toLowerCase().contains(lower))
      .toList();
}
