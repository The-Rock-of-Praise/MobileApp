import 'package:lyrics/Models/notification_model.dart';
import 'package:lyrics/Service/base_api.dart';

class NotificationService {
  final BaseApiService _apiService;

  NotificationService({BaseApiService? apiService})
      : _apiService = apiService ?? BaseApiService();

  Future<Map<String, dynamic>> getAllNotifications() async {
    try {
      final result = await _apiService.get('/notifications');
      if (result['success']) {
        // BaseApiService wraps the whole response in a 'data' field.
        // The backend response itself also has a 'data' field containing the list.
        final backendResponse = result['data'];
        final List<dynamic> dataList = backendResponse is Map && backendResponse.containsKey('data') 
            ? (backendResponse['data'] ?? [])
            : (backendResponse is List ? backendResponse : []);
            
        final List<NotificationModel> notifications = 
            dataList.map((e) => NotificationModel.fromJson(e)).toList();
        return {
          'success': true,
          'notifications': notifications,
        };
      }
      return result;
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  void dispose() {
    _apiService.dispose();
  }
}
