class User {
  final String name;
  final String email;
  final String mobile;
  final String password;
  final String userType;

  User({
    required this.name,
    required this.email,
    required this.mobile,
    required this.password,
    required this.userType,
  });
  
  get role => null;
}

class UserDatabase {
  static final List<User> users = [];

  static User? authenticate(String email, String password, String role) {
    try {
      return users.firstWhere((user) =>
          user.email == email && user.password == password && user.role == role);
    } catch (e) {
      return null;
    }
  }

  static bool emailExists(String email) {
    return users.any((user) => user.email == email);
  }
}
