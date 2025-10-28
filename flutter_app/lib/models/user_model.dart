class User {
  final String? id;
  final String username;
  final String email;
  final String? password; // Chỉ dùng khi tạo/update
  final String? image;

  User({
    this.id,
    required this.username,
    required this.email,
    this.password,
    this.image,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'],
      username: json['username'],
      email: json['email'],
      image: json['image'],
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'username': username,
      'email': email,
    };
    if (password != null && password!.isNotEmpty) {
      data['password'] = password;
    }
    if (image != null) {
      data['image'] = image;
    }
    return data;
  }
}