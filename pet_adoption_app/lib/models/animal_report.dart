class AnimalReport {
  final String id;
  final String animalType;
  final String location;
  final String condition;
  final String description;
  final String? imagePath;
  final DateTime date;
  String status;
  final double? latitude;
  final double? longitude;

  AnimalReport({
    required this.id,
    required this.animalType,
    required this.location,
    required this.condition,
    required this.description,
    this.imagePath,
    required this.date,
    this.status = 'Pending',
    this.latitude,
    this.longitude,
  });
}