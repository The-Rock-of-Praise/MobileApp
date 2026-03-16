// class UserModel {
//   final String fullname;
//   final String email;
//   final String phonenumber;
//   final String password;
//   final int? id; // Added to store user ID from backend

//   UserModel({
//     required this.fullname,
//     required this.email,
//     required this.phonenumber,
//     required this.password,
//     this.id,
//   });

//   // Factory constructor to create a UserModel from JSON
//   factory UserModel.fromJson(Map<String, dynamic> json) {
//     return UserModel(
//       id: json['id'] as int?,
//       fullname: json['fullname'] as String,
//       email: json['email'] as String,
//       phonenumber: json['phonenumber'] as String,
//       password: '', // Password won't be returned from the API
//     );
//   }

//   // Method to convert UserModel to JSON
//   Map<String, dynamic> toJson() {
//     return {
//       if (id != null) 'id': id,
//       'fullname': fullname,
//       'email': email,
//       'phonenumber': phonenumber,
//       'password': password,
//     };
//   }

//   // Copy with method for immutability
//   UserModel copyWith({
//     String? fullname,
//     String? email,
//     String? phonenumber,
//     String? password,
//     int? id,
//   }) {
//     return UserModel(
//       fullname: fullname ?? this.fullname,
//       email: email ?? this.email,
//       phonenumber: phonenumber ?? this.phonenumber,
//       password: password ?? this.password,
//       id: id ?? this.id,
//     );
//   }
// }

class UserModel {
  final int? id;
  final String fullname;
  final String? phonenumber;
  final String email;
  final String password;
  final bool isPremium;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int synced; // 0 = not synced, 1 = synced

  UserModel({
    this.id,
    required this.fullname,
    required this.phonenumber,
    required this.email,
    this.password = '',
    this.isPremium = false,
    this.createdAt,
    this.updatedAt,
    this.synced = 0,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      fullname: json['fullname'] ?? '',
      phonenumber: json['phonenumber'] ?? '',
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      isPremium: json['isPremium'] == 1 || json['isPremium'] == true,
      createdAt:
          json['created_at'] != null
              ? DateTime.parse(json['created_at'])
              : null,
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
      synced: json['synced'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'phonenumber': phonenumber,
      'email': email,
      'password': password,
      'isPremium': isPremium ? 1 : 0,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'synced': synced,
    };
  }

  UserModel copyWith({
    int? id,
    String? fullname,
    String? phonenumber,
    String? email,
    String? password,
    bool? isPremium,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? synced,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullname: fullname ?? this.fullname,
      phonenumber: phonenumber ?? this.phonenumber,
      email: email ?? this.email,
      password: password ?? this.password,
      isPremium: isPremium ?? this.isPremium,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      synced: synced ?? this.synced,
    );
  }
}
