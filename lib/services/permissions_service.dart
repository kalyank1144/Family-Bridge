import 'package:permission_handler/permission_handler.dart';

class PermissionsService {
  static Future<void> ensureBasic() async {
    await [
      Permission.notification,
    ].request();
  }
}
