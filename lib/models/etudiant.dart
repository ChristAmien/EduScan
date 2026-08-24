class Student {
  final String id;
  final String studentId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? level;
  final String? qrCode;
  final String? status;
  final String? filiereName;

  Student({
    required this.id,
    required this.studentId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.level,
    this.qrCode,
    this.status,
    this.filiereName,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'],
      studentId: json['student_id'] ?? '',
      firstName: json['first_name'] ?? '',
      lastName: json['last_name'] ?? '',
      email: json['email'],
      phone: json['phone'],
      level: json['level'],
      qrCode: json['qr_code'],
      status: json['status'],
      filiereName: json['filieres']?['name'],
    );
  }

  String get fullName => '$firstName $lastName';

  String get initials {
    return '${firstName.isNotEmpty ? firstName[0] : ''}'
        '${lastName.isNotEmpty ? lastName[0] : ''}'
        .toUpperCase();
  }
}