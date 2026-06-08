import 'apiclient.dart';

class BoardApi {
  static Future<dynamic> getBoardConfig(String boardId) async {
    return await ApiClient.request("Board/$boardId", method: "GET");
  }
}
