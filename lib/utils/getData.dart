import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:vaxiwarehouse/config/api_config.dart';
import 'package:vaxiwarehouse/models/salesordermodel.dart';

Future<List<salesorder>> fetchClinicBookings() async {
  final response = await http.get(Uri.parse('${ApiConfig.baseUrl}/warehouse'));

  if (response.statusCode == 200) {
    final List<dynamic> data = json.decode(response.body);
    return data.map((json) => salesorder.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load bookings');
  }
}