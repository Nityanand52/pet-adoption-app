import '../main.dart';

class AdoptionApplication {
  final String id;
  final Pet pet;
  final String applicantName;
  final String email;
  final String phone;
  final String address;
  final String reason;
  final String experience;
  String status;

  AdoptionApplication({
    required this.id,
    required this.pet,
    required this.applicantName,
    required this.email,
    required this.phone,
    required this.address,
    required this.reason,
    required this.experience,
    this.status = 'Pending',
  });
}