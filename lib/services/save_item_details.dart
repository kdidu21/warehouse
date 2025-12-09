import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/salesordermodel.dart';

class ItemPreparationService {
  static const String baseUrl =
      'http://shopapi.vaxilifecorp.com/api/appsales/0';

  static Future<bool> submitForPreparation(
    salesorder order,
    [String selectedWarehouseman = '']
  ) async {
    try {
      final List<Map<String, dynamic>> itemsList = [];
      
      for (var item in order.items) {
        final Map<String, dynamic> itemData = {
          'id': item.id,
          'ItemCode': item.ItemCode,
          'Quantity': item.PreparedQuantity,
          'DateExpire': item.DateExpire,
          'BatchNo': item.BatchNo ?? '',
          'SecondExpire': item.DateExpire2 ?? '',
          'Status': "For Preparation",
        };
        
        if (selectedWarehouseman.isNotEmpty) {
          itemData['WarehouseMan'] = selectedWarehouseman;
        }
        
        itemsList.add(itemData);
      }

      final response = await http.put(
        Uri.parse(baseUrl),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode(itemsList),
      );

      print("Status: ${response.statusCode}");
      print("Body: ${response.body}");

      if (response.statusCode != 200) {
        print("Failed to submit order for preparation");
        return false;
      }

      print("All items submitted for preparation successfully");
      return true;
    } catch (e) {
      print("Exception: $e");
      return false;
    }
  }
}