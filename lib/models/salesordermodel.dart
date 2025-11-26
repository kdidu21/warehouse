class  salesorder {
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
      Sono: json['Sono'],
      ClinicName: json['ClinicName'],
      DateOrder: json['DateOrder'] != null
          ? DateTime.parse(json['DateOrder'])
          : null,
      AreaName: json['AreaName'],
      Remarks: json['Remarks'] ?? '',
      items: (json['Items'] as List)
          .map((i) => salesorderdetails.fromJson(i))
          .toList(),
    );
  }
}

class salesorderdetails {
  int id;
  String ItemCode;
  int Quantity;
  String UnitOfMeasure;
  int PreparedQuantity;
  String DateExpire;
  String? BatchNo;
  String? DateExpire2;

  salesorderdetails({
    required this.id,
    required this.ItemCode,
    required this.Quantity,
    required this.UnitOfMeasure,
    required this.PreparedQuantity,
    required this.DateExpire,
    this.BatchNo,
    this.DateExpire2,
  });

  factory salesorderdetails.fromJson(Map<String, dynamic> json) {
    return salesorderdetails(
      id: json['id'],
      ItemCode: json['ItemCode'],
      Quantity: json['Quantity'],
      UnitOfMeasure: json['UnitOfMeasure'],
      PreparedQuantity: json['PreparedQuantity'] ?? 0,
      DateExpire: json['DateExpire'] != null
          ? () {
              final dt = DateTime.parse(json['DateExpire']);
              return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
            }()
          : 'N/A',
      BatchNo: json['BatchNo'],
      DateExpire2: json['SecondExpire'],
    );
  }
  salesorderdetails copyWith({
    int? PreparedQuantity,
    String? DateExpire,
    String? BatchNo,
    String? DateExpire2,
  }) {
    return salesorderdetails(
      id: id,
      ItemCode: ItemCode,
      Quantity: Quantity,
      UnitOfMeasure: UnitOfMeasure,
      PreparedQuantity: PreparedQuantity ?? this.PreparedQuantity,
      DateExpire: DateExpire ?? this.DateExpire,
      BatchNo: BatchNo ?? this.BatchNo,
      DateExpire2: DateExpire2 ?? this.DateExpire2,
    );
  }
}
