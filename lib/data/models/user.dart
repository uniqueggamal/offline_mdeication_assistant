class AppUser {
  final String id;
  final String? email;
  final String? linkedPatientId; // caretaker: which patient they view

  const AppUser({
    required this.id,
    this.email,
    this.linkedPatientId,
  });
}

