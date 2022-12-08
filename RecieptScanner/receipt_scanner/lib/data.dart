import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

Future<http.Response> fetchTrends() async {
  return http.get(Uri.parse(
      'https://receiptappbackend.azurewebsites.net/view-user-trends?user_id=Bob'));
}

Future<http.Response> fetchReceiptItems() {
  print('Fetching Receipt Items');
  return http.get(Uri.parse(
      'https://receiptappbackend.azurewebsites.net/view-user-receipt-items?user_id=Bob'));
}

Future<http.StreamedResponse> postReceipt(Uri imageFile) async {
  var postUri =
      Uri.parse("https://receiptappbackend.azurewebsites.net/upload-receipts");
  var request = http.MultipartRequest("POST", postUri);

  //create multipart using filepath, string or bytes
  var pic = await http.MultipartFile.fromPath("receipts", imageFile.path);
  //add multipart to request
  request.files.add(pic);

  return await request.send();
}
