import 'package:demo_pusher/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PusherService {
  static Future<void> savePreferences({
    required String apiKey,
    required String cluster,
    required String channelName,
    required String eventName,
    required String data,
  }) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString("apiKey", apiKey);
    prefs.setString("cluster", cluster);
    prefs.setString("channelName", channelName);
    prefs.setString("eventName", eventName);
    prefs.setString("data", data);
  }

  static Future<Map<String, String>> getPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return {
      "apiKey": prefs.getString("apiKey") ?? '',
      "cluster": prefs.getString("cluster") ?? AppConstants.defaultCluster,
      "channelName": prefs.getString("channelName") ?? AppConstants.defaultChannelName,
      "eventName": prefs.getString("eventName") ?? AppConstants.defaultEventName,
      "data": prefs.getString("data") ?? AppConstants.defaultData,
    };
  }
}
