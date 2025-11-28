class salesorder {
  final String Sono;
  final String ClinicName;
  final DateTime? DateOrder;
  final String AreaName;
  final String Remarks;
  final List<salesorderdetails> items;

  salesorder({
    required this.Sono,
    required this.ClinicName,
    required this.DateOrder,
    required this.AreaName,
    required this.Remarks,
    required this.items,
  });

  factory salesorder.fromJson(Map<String, dynamic> json) {
    return salesorder(
      Sono: json['Sono'] ?? '',
      ClinicName: json['ClinicName'] ?? '',
      DateOrder: json['DateOrder'] != null
          ? DateTime.tryParse(json['DateOrder'])
          : null,
      AreaName: json['AreaName'] ?? '',
      Remarks: json['Remarks'] ?? '',
      items: (json['Items'] as List<dynamic>?)
              ?.map((i) => salesorderdetails.fromJson(i))
              .toList() ??
          [],
    );
  }
}

class salesorderdetails {
  int id;
  String ItemCode;
  int Quantity;
  String UnitOfMeasure; // non-nullable
  int PreparedQuantity;
  String DateExpire;
  String? BatchNo;
  String? DateExpire2;
  String? WarehouseMan;

  salesorderdetails({
    required this.id,
    required this.ItemCode,
    required this.Quantity,
    this.UnitOfMeasure = '',
    required this.PreparedQuantity,
    required this.DateExpire,
    this.BatchNo,
    this.DateExpire2,
    this.WarehouseMan,
  });

  factory salesorderdetails.fromJson(Map<String, dynamic> json) {
    String formatDate(String? date) {
      if (date == null) return 'N/A';
      try {
        final dt = DateTime.parse(date);
        return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
      } catch (_) {
        return 'N/A';
      }
    }

    return salesorderdetails(
      id: json['id'] ?? 0,
      ItemCode: json['ItemCode'] ?? '',
      Quantity: json['Quantity'] ?? 0,
      UnitOfMeasure: json['UnitOfMeasure']?.toString() ?? '',
      PreparedQuantity: json['PreparedQuantity'] ?? 0,
      DateExpire: formatDate(json['DateExpire']),
      BatchNo: json['BatchNo'],
      DateExpire2: json['SecondExpire'],
      WarehouseMan: json['WarehouseMan'],
    );
  }

  salesorderdetails copyWith({
    int? PreparedQuantity,
    String? DateExpire,
    String? BatchNo,
    String? DateExpire2,
    String? UnitOfMeasure,
    String? WarehouseMan,
  }) {
    return salesorderdetails(
      id: id,
      ItemCode: ItemCode,
      Quantity: Quantity,
      UnitOfMeasure: UnitOfMeasure ?? this.UnitOfMeasure,
      PreparedQuantity: PreparedQuantity ?? this.PreparedQuantity,
      DateExpire: DateExpire ?? this.DateExpire,
      BatchNo: BatchNo ?? this.BatchNo,
      DateExpire2: DateExpire2 ?? this.DateExpire2,
      WarehouseMan: WarehouseMan ?? this.WarehouseMan,
    );
  }
}
