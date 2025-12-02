import 'dart:async';
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'package:vaxiwarehouse/models/salesordermodel.dart';
import 'package:vaxiwarehouse/utils/getData.dart';
import 'package:vaxiwarehouse/utils/printhelper.dart';
import 'package:vaxiwarehouse/services/sales_order_service.dart';

class ClinicBookingsPage extends StatefulWidget {
  const ClinicBookingsPage({super.key});

  @override
  State<ClinicBookingsPage> createState() => _ClinicBookingsPageState();
}

class _ClinicBookingsPageState extends State<ClinicBookingsPage> {
  List<salesorder> _bookings = [];
  final Map<String, String> _bookingStates = {};
  Timer? _timer;
  String _sortOption = 'Clinic Name (A–Z)';
  final DateFormat _dateFormat = DateFormat('MMM dd, yyyy');
  bool _loading = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final newData = await fetchClinicBookings();
      bool hasChange = false;

      for (var booking in newData) {
        final currentJson = _bookingToJson(booking);
        if (!_bookingStates.containsKey(booking.Sono) ||
            _bookingStates[booking.Sono] != currentJson) {
          hasChange = true;
          _bookingStates[booking.Sono] = currentJson;
        }
      }

      if (hasChange || _loading) {
        setState(() {
          _bookings = newData;
          _sortBookings(_bookings);
          _loading = false;
        });
      } else if (_loading) {
        setState(() => _loading = false);
      }
    } catch (e) {
      debugPrint('Error fetching bookings: $e');
      if (_loading) setState(() => _loading = false);
    }
  }

  String _bookingToJson(salesorder booking) {
    return booking.Sono +
        booking.ClinicName +
        booking.AreaName +
        (booking.DateOrder?.toIso8601String() ?? '') +
        booking.items
            .map((i) => i.ItemCode + i.Quantity.toString() + i.UnitOfMeasure)
            .join();
  }

  void _sortBookings(List<salesorder> bookings) {
    switch (_sortOption) {
      case 'Clinic Name (A–Z)':
        bookings.sort((a, b) => a.ClinicName.compareTo(b.ClinicName));
        break;
      case 'Clinic Name (Z–A)':
        bookings.sort((a, b) => b.ClinicName.compareTo(a.ClinicName));
        break;
      case 'Date (Newest First)':
        bookings.sort((a, b) => b.DateOrder!.compareTo(a.DateOrder!));
        break;
      case 'Date (Oldest First)':
        bookings.sort((a, b) => a.DateOrder!.compareTo(b.DateOrder!));
        break;
      case 'Area (A–Z)':
        bookings.sort((a, b) => a.AreaName.compareTo(b.AreaName));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              bottom: 16,
              left: 20,
              right: 20,
            ),
            decoration: BoxDecoration(
              color: Color(0xFFDC2626),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(2),
                bottomRight: Radius.circular(2),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Sales Orders",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 28,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortOption,
                          dropdownColor: Colors.white,
                          icon: const Icon(
                            Icons.filter_list_rounded,
                            color: Colors.white,
                          ),
                          underline: const SizedBox(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Clinic Name (A–Z)',
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16.0,
                                ), // Add left padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sort_by_alpha,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Clinic Name (A–Z)',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Clinic Name (Z–A)',
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16.0,
                                ), // Add left padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.sort_by_alpha,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Clinic Name (Z–A)',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Date (Newest First)',
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16.0,
                                ), // Add left padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.date_range,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Date (Newest First)',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Date (Oldest First)',
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16.0,
                                ), // Add left padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.date_range,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Date (Oldest First)',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'Area (A–Z)',
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: 16.0,
                                ), // Add left padding
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.location_on,
                                      size: 18,
                                      color: Colors.black,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Area (A–Z)',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _sortOption = value;
                                _sortBookings(_bookings);
                              });
                            }
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  '${_bookings.length} orders found',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? _buildLoadingState()
                : _bookings.isEmpty
                ? _buildEmptyState()
                : _buildOrdersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFDC2626)),
              strokeWidth: 4,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Loading Orders',
            style: TextStyle(
              color: Colors.grey[700],
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Getting the latest sales orders...',
            style: TextStyle(color: Colors.grey[500], fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Color(0xFFFEF2F2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.inventory_2_outlined,
              size: 50,
              color: Color(0xFFDC2626),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Orders Found',
            style: TextStyle(
              fontSize: 22,
              color: Colors.grey[800],
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'New sales orders will appear here automatically',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchData,
            icon: Icon(Icons.refresh_rounded),
            label: Text('Refresh'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList() {
    return RefreshIndicator(
      onRefresh: _fetchData,
      color: Color(0xFFDC2626),
      backgroundColor: Colors.white,
      child: ListView.builder(
        controller: _scrollController,
        padding: EdgeInsets.all(16),
        itemCount: _bookings.length,
        itemBuilder: (context, index) {
          final booking = _bookings[index];
          return _OrderCard(
            booking: booking,
            dateFormat: _dateFormat,
            onRefresh: () {
              setState(() {
                _bookings.removeAt(index);
              });
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatefulWidget {
  final salesorder booking;
  final DateFormat dateFormat;
  final VoidCallback onRefresh;

  const _OrderCard({
    required this.booking,
    required this.dateFormat,
    required this.onRefresh,
  });

  @override
  State<_OrderCard> createState() => _OrderCardState();
}

class _OrderCardState extends State<_OrderCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final totalItems = booking.items.length;
    final totalQuantity = booking.items.fold(
      0,
      (sum, item) => sum + item.Quantity,
    );

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Header
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_hospital_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.ClinicName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.location_on_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    booking.AreaName,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.9),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        _buildOrderBadge(),
                      ],
                    ),
                    SizedBox(height: 12),
                    if (booking.Remarks.isNotEmpty)
                      Container(
                        padding: EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.comment_rounded,
                              size: 14,
                              color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.8),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                safeDecode(booking.Remarks),
                                style: TextStyle(
                                  color: const Color.fromARGB(255, 255, 255, 255).withOpacity(0.9),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Order Summary
              Container(
                padding: EdgeInsets.all(16),
                color: Colors.grey[50],
                child: Row(
                  children: [
                    _buildSummaryItem(
                      Icons.inventory_2_rounded,
                      '$totalItems',
                      'Items',
                    ),
                    _buildSummaryItem(
                      Icons.shopping_cart_rounded,
                      '$totalQuantity',
                      'Total Qty',
                    ),
                    _buildSummaryItem(
                      Icons.calendar_today_rounded,
                      widget.dateFormat.format(
                        booking.DateOrder ?? DateTime.now(),
                      ),
                      'Order Date',
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFDC2626),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _expanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 6),
                            Text(
                              _expanded ? 'HIDE' : 'VIEW',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Items List
              AnimatedSize(
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _expanded ? _buildItemsList() : SizedBox.shrink(),
              ),

              // Actions
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildStatusChip(
                            'On-Hold',
                            Icons.pause_circle_filled_rounded,
                            Color(0xFFF59E0B),
                          ),
                          _buildStatusChip(
                            'Double-Booking',
                            Icons.copy_all_rounded,
                            Color(0xFF8B5CF6),
                          ),
                          _buildStatusChip(
                            'Out of Stocks',
                            Icons.error_outline_rounded,
                            Color(0xFFEF4444),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 12),
                    Row(
                      spacing: 10,
                      children: [
                        _buildActionButton(
                          'Print',
                          Icons.print_rounded,
                          Color(0xFFDC2626),
                          () => _printOrder(booking),
                        ),
                        SizedBox(height: 8),
                        _buildActionButton(
                          'Submit',
                          Icons.send_rounded,
                          Color(0xFF059669),
                          () => _showSubmitDialog(context, booking),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderBadge() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            widget.booking.Sono,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Sales Order',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Container(
      margin: EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey[600]),
              SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[500],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    'PRODUCT',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    'BATCH',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'EXPIRY',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'PREPARED',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    'ORDERED',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[600],
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          ...widget.booking.items.map((item) => _buildItemRow(item)),
        ],
      ),
    );
  }

  Widget _buildItemRow(salesorderdetails item) {
    return InkWell(
      onTap: () => _showItemDetailsDialog(item),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        margin: EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            // PRODUCT column - flex: 3 (3x wider than others)
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.ItemCode,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 2),
                  Text(
                    item.UnitOfMeasure,
                    style: TextStyle(color: Colors.grey[600], fontSize: 11),
                  ),
                ],
              ),
            ),

            // BATCH column - flex: 1
            Expanded(
              child: Center(
                child: Text(
                  (item.BatchNo == null ||
                          item.BatchNo!.isEmpty ||
                          item.BatchNo == 'N/A')
                      ? 'N/A'
                      : item.BatchNo!,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        (item.BatchNo == null ||
                            item.BatchNo!.isEmpty ||
                            item.BatchNo == 'N/A')
                        ? Colors.grey[400]
                        : Colors.grey[800],
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),

            // EXPIRY column - flex: 1
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      (item.DateExpire.isEmpty || item.DateExpire == 'N/A')
                          ? 'N/A'
                          : item.DateExpire,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            (item.DateExpire.isEmpty ||
                                item.DateExpire == 'N/A')
                            ? Colors.grey[400]
                            : Colors.grey[800],
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (item.DateExpire2 != null &&
                        item.DateExpire2!.isNotEmpty &&
                        item.DateExpire2 != 'N/A')
                      Padding(
                        padding: const EdgeInsets.only(top: 2.0),
                        child: Text(
                          item.DateExpire2!,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w400,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // PREPARED column - flex: 1
            Expanded(
              child: Center(
                child: Container(
                  margin: EdgeInsets.symmetric(horizontal: 4),
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: BoxDecoration(
                    color: item.PreparedQuantity > 0
                        ? Color(0xFF10B981).withOpacity(0.15)
                        : Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.PreparedQuantity > 0
                          ? Color(0xFF059669).withOpacity(0.3)
                          : Colors.grey[300]!,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${item.PreparedQuantity}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: item.PreparedQuantity > 0
                          ? Color(0xFF059669)
                          : Colors.grey[500],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

            // ORDERED column - flex: 1
            Expanded(
              child: Center(
                child: Text(
                  '${item.Quantity}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, IconData icon, Color color) {
    return ActionChip(
      onPressed: () => _showPreparedByDialog(context, widget.booking, status),
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildActionButton(
    String text,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return SizedBox(
      width: 100,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(
          text,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 1,
        ),
      ),
    );
  }

  void _showItemDetailsDialog(salesorderdetails item) {
    showDialog(
      context: context,
      builder: (context) {
        final batchController = TextEditingController(
          text:
              (item.BatchNo == null ||
                  item.BatchNo!.isEmpty ||
                  item.BatchNo == 'N/A')
              ? ''
              : item.BatchNo!,
        );
        final qtyController = TextEditingController(
          text: item.PreparedQuantity > 0
              ? item.PreparedQuantity.toString()
              : '',
        );
        DateTime? exp1;
        DateTime? exp2;

        if (item.DateExpire.isNotEmpty && item.DateExpire != 'N/A') {
          try {
            final parts = item.DateExpire.split('-');
            if (parts.length == 2) {
              exp1 = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
            }
          } catch (_) {
            print('Error parsing DateExpire: ${item.DateExpire}');
          }
        }

        if (item.DateExpire2 != null &&
            item.DateExpire2!.isNotEmpty &&
            item.DateExpire2 != 'N/A') {
          try {
            final parts = item.DateExpire2!.split('-');
            if (parts.length == 2) {
              exp2 = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
            }
          } catch (_) {
            print('Error parsing DateExpire2: ${item.DateExpire2}');
          }
        }

        final parentSetState = setState;

        return StatefulBuilder(
          builder: (context, localSetState) {
            Future<void> pickYearMonth(bool first) async {
              final now = DateTime.now();
              DateTime tempDate = first ? (exp1 ?? now) : (exp2 ?? now);

              await showDialog(
                context: context,
                builder: (context) {
                  int selectedYear = tempDate.year;
                  int selectedMonth = tempDate.month;

                  final minYear = selectedYear < now.year - 5
                      ? selectedYear
                      : now.year - 5;
                  final maxYear = selectedYear > now.year + 4
                      ? selectedYear
                      : now.year + 4;
                  final yearRange = maxYear - minYear + 1;

                  return StatefulBuilder(
                    builder: (context, setDialogState) {
                      return Dialog(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Select Year and Month',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Year',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  DropdownButton<int>(
                                    value: selectedYear,
                                    isExpanded: true,
                                    items: List.generate(
                                      yearRange,
                                      (i) => DropdownMenuItem(
                                        value: minYear + i,
                                        child: Text('${minYear + i}'),
                                      ),
                                    ),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setDialogState(() {
                                          selectedYear = v;
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'Month',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  DropdownButton<int>(
                                    value: selectedMonth,
                                    isExpanded: true,
                                    items: List.generate(
                                      12,
                                      (i) => DropdownMenuItem(
                                        value: i + 1,
                                        child: Text('${i + 1}'.padLeft(2, '0')),
                                      ),
                                    ),
                                    onChanged: (v) {
                                      if (v != null) {
                                        setDialogState(() {
                                          selectedMonth = v;
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        side: BorderSide(color: Colors.grey),
                                      ),
                                      child: Text('Cancel'),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        final selectedDate = DateTime(
                                          selectedYear,
                                          selectedMonth,
                                          1,
                                        );
                                        localSetState(() {
                                          if (first) {
                                            exp1 = selectedDate;
                                          } else {
                                            exp2 = selectedDate;
                                          }
                                        });
                                        Navigator.pop(context);
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Color(0xFFDC2626),
                                        foregroundColor:
                                            Colors.white, // Add this line
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                      ),
                                      child: Text('Select'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            }

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.inventory_2_rounded,
                            color: Color(0xFFDC2626),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Item Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    Text(
                      item.ItemCode,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Unit: ${item.UnitOfMeasure}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    SizedBox(height: 24),
                    TextField(
                      controller: batchController,
                      decoration: InputDecoration(
                        labelText: 'Batch Number',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextField(
                      controller: qtyController,
                      decoration: InputDecoration(
                        labelText: 'Prepared Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        prefixIcon: Icon(Icons.scale_rounded),
                        suffixText: 'Max: ${item.Quantity}',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Expiration Dates',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickYearMonth(true),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            icon: Icon(Icons.calendar_today_rounded, size: 18),
                            label: Text(
                              exp1 == null
                                  ? 'Select Expiration 1'
                                  : '${exp1!.year}-${exp1!.month.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => pickYearMonth(false),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            icon: Icon(Icons.calendar_today_rounded, size: 18),
                            label: Text(
                              exp2 == null
                                  ? 'Select Expiration 2'
                                  : '${exp2!.year}-${exp2!.month.toString().padLeft(2, '0')}',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 12),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final batchNo = batchController.text.trim();
                              final qtyText = qtyController.text.trim();

                              if (qtyText.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please enter Prepared Quantity',
                                    ),
                                  ),
                                );
                                return;
                              }

                              final qty = int.tryParse(qtyText) ?? 0;
                              final maxQty =
                                  double.tryParse(item.Quantity.toString()) ??
                                  0;

                              if (qty <= 0 || qty > maxQty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Invalid quantity (max $maxQty)',
                                    ),
                                  ),
                                );
                                return;
                              }

                              if (exp1 == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Please select the first expiration date',
                                    ),
                                  ),
                                );
                                return;
                              }

                              item.BatchNo = batchNo;
                              item.PreparedQuantity = qty;
                              item.DateExpire =
                                  '${exp1!.year}-${exp1!.month.toString().padLeft(2, '0')}';
                              item.DateExpire2 = exp2 == null
                                  ? ''
                                  : '${exp2!.year}-${exp2!.month.toString().padLeft(2, '0')}';

                              Navigator.pop(context);
                              parentSetState(() {});
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFFDC2626),
                              foregroundColor:
                                  Colors.white, // Add this line for white text
                              padding: EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text('Save Changes'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSubmitDialog(BuildContext context, salesorder booking) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedPerson;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        Icons.person_rounded,
                        size: 30,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Submit Order',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Who prepared this order?',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Column(
                      children: [
                        _buildPersonOption('Fe', selectedPerson, (value) {
                          setDialogState(() {
                            selectedPerson = value;
                          });
                        }),
                        _buildPersonOption('Edrin', selectedPerson, (value) {
                          setDialogState(() {
                            selectedPerson = value;
                          });
                        }),
                        _buildPersonOption('Anne', selectedPerson, (value) {
                          setDialogState(() {
                            selectedPerson = value;
                          });
                        }),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey),
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedPerson == null
                                ? null
                                : () async {
                                    final nav = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final person = selectedPerson!;

                                    nav.pop();

                                    try {
                                      final success =
                                          await SalesOrderService.submitSalesOrder(
                                            booking,
                                            person,
                                          );

                                      if (success) {
                                        widget.onRefresh();
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Order ${booking.Sono} submitted by $person',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      } else {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to submit order. Please try again.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0xFF059669),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              'Submit Order',
                              style: TextStyle(
                                color: Colors.white,
                              ), // Force white text
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPersonOption(
    String name,
    String? selectedPerson,
    Function(String?) setDialogState,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: RadioListTile<String>(
        title: Text(name, style: TextStyle(fontWeight: FontWeight.w500)),
        value: name,
        groupValue: selectedPerson,
        onChanged: (value) {
          setDialogState(value); // ✅ Call the callback with the new value
        },
        activeColor: Color(0xFFDC2626),
      ),
    );
  }

  void _showPreparedByDialog(
    BuildContext context,
    salesorder booking,
    String status,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        String? selectedPerson;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Icon(
                        _getStatusIcon(status),
                        size: 30,
                        color: _getStatusColor(status),
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Mark as $status',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Who is handling this status?',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    Column(
                      children: [
                        _buildPersonOption('Fe', selectedPerson, (value) {
                          setDialogState(() {
                            selectedPerson = value;
                          });
                        }),
                        _buildPersonOption('Edrin', selectedPerson, (value) {
                          setDialogState(() {
                            selectedPerson = value;
                          });
                        }),
                        _buildPersonOption('Anne', selectedPerson, (value) {
                          setDialogState(() {
                            selectedPerson = value;
                          });
                        }),
                      ],
                    ),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey),
                            ),
                            child: Text('Cancel'),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedPerson == null
                                ? null
                                : () async {
                                    final nav = Navigator.of(context);
                                    final messenger = ScaffoldMessenger.of(
                                      context,
                                    );
                                    final person = selectedPerson!;

                                    nav.pop();

                                    try {
                                      String url =
                                          'http://shopapi.vaxilifecorp.com/api/appsales?sono=${booking.Sono}_${status}_$person';

                                      final response = await http.get(
                                        Uri.parse(url),
                                      );

                                      if (response.statusCode == 200) {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Order ${booking.Sono} marked as $status by $person',
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                        widget.onRefresh();
                                      } else {
                                        messenger.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Failed to update status. Please try again.',
                                            ),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      messenger.showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _getStatusColor(status),
                              padding: EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text('Confirm'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'On-Hold':
        return Color(0xFFF59E0B);
      case 'Double-Booking':
        return Color(0xFF8B5CF6);
      case 'Out of Stocks':
        return Color(0xFFEF4444);
      default:
        return Color(0xFFDC2626);
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'On-Hold':
        return Icons.pause_circle_filled_rounded;
      case 'Double-Booking':
        return Icons.copy_all_rounded;
      case 'Out of Stocks':
        return Icons.error_outline_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  Future<void> _printOrder(salesorder booking) async {
    final messenger = ScaffoldMessenger.of(context);

    try {
      await printSalesOrderTemplateESCUtils(booking);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Printing failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> printSalesOrderTemplateESCUtils(salesorder booking) async {
    final messenger = ScaffoldMessenger.of(context);
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');

    List<int> bytes = [];

    // --- Header ---
    bytes += generator.text(
      booking.ClinicName,
      styles: PosStyles(
        align: PosAlign.center,
        height: PosTextSize.size2,
        width: PosTextSize.size2,
        bold: true,
      ),
    );

    bytes += generator.text('Order No : ${booking.Sono}');
    bytes += generator.text('Area     : ${booking.AreaName}');
    bytes += generator.text(
      'Date     : ${dateFormat.format(booking.DateOrder ?? DateTime.now())}',
    );

    // URL decode the remarks to handle %20, %26, etc.
    if (booking.Remarks.isNotEmpty) {
      String decodedRemarks = Uri.decodeComponent(booking.Remarks);
      bytes += generator.text('Remarks  : $decodedRemarks');
    }

    bytes += generator.hr(); // horizontal line

    // --- Items (small font) ---
    bytes += generator.row([
      PosColumn(text: 'Item', width: 7),
      PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: false)),
      PosColumn(text: 'Exp', width: 3),
    ]);
    const int itemWidth = 15; // max characters for Item column

    for (var item in booking.items) {
      String itemName = '${item.ItemCode} (${item.UnitOfMeasure})';
      String qty = item.PreparedQuantity.toString();
      String exp = item.DateExpire;

      // Split item name into chunks of itemWidth
      List<String> lines = [];
      for (int i = 0; i < itemName.length; i += itemWidth) {
        int end = (i + itemWidth < itemName.length)
            ? i + itemWidth
            : itemName.length;
        lines.add(itemName.substring(i, end));
      }

      // Print first line with Qty and Exp
      bytes += generator.row([
        PosColumn(
          text: lines[0],
          width: 7,
          styles: PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          text: qty,
          width: 2,
          styles: PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        ),
        PosColumn(
          text: exp,
          width: 3,
          styles: PosStyles(
            height: PosTextSize.size1,
            width: PosTextSize.size1,
          ),
        ),
      ]);

      // Print remaining lines (if any) without Qty/Exp
      for (int j = 1; j < lines.length; j++) {
        bytes += generator.row([
          PosColumn(
            text: lines[j],
            width: 6,
            styles: PosStyles(
              height: PosTextSize.size1,
              width: PosTextSize.size1,
            ),
          ),
          PosColumn(text: '', width: 2),
          PosColumn(text: '', width: 4),
        ]);
      }
    }

    bytes += generator.hr();

    // --- Footer ---
    bytes += generator.text(
      'THANK YOU!',
      styles: PosStyles(align: PosAlign.center, bold: true),
    );

    bytes += generator.feed(2); // feed 2 lines
    bytes += generator.cut(); // cut paper

    // --- Send bytes to your Bluetooth printer ---
    bool success = await PrinterHelper.printBytes(Uint8List.fromList(bytes));

    if (success) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Printed successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          content: Text('Failed to print. Check printer.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

String safeDecode(String? input) {
  if (input == null || input.isEmpty) return '';
  try {
    return Uri.decodeComponent(input);
  } catch (_) {
    return input;
  }
}
