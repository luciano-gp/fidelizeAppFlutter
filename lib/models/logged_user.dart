import 'user_model.dart';

class LoggedUser {
  static UserModel? _user;

  static void setUser(UserModel user) {
    _user = user;
  }

  static UserModel? get user => _user;

  static bool get isAdmin => _user?.isAdmin ?? false;
  static String get name => _user?.name ?? '';
  static int get points => _user?.points ?? 0;
}
