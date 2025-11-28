import 'dart:async';
import 'dart:typed_data';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchData();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _fetchData());
  }

  @override
  void dispose() {
    _timer?.cancel();
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          "Sales Orders",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.teal,
        actions: [
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _sortOption,
              dropdownColor: Colors.white,
              items: const [
                DropdownMenuItem(
                  value: 'Clinic Name (A–Z)',
                  child: Text('Clinic Name (A–Z)'),
                ),
                DropdownMenuItem(
                  value: 'Clinic Name (Z–A)',
                  child: Text('Clinic Name (Z–A)'),
                ),
                DropdownMenuItem(
                  value: 'Date (Newest First)',
                  child: Text('Date (Newest First)'),
                ),
                DropdownMenuItem(
                  value: 'Date (Oldest First)',
                  child: Text('Date (Oldest First)'),
                ),
                DropdownMenuItem(
                  value: 'Area (A–Z)',
                  child: Text('Area (A–Z)'),
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
          const SizedBox(width: 10),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Colors.teal))
          : _bookings.isEmpty
          ? const Center(child: Text('No bookings found.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _bookings.length,
              itemBuilder: (context, index) {
                final booking = _bookings[index];
                return _BookingCard(booking: booking, dateFormat: _dateFormat);
              },
            ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final salesorder booking;
  final DateFormat dateFormat;

  const _BookingCard({required this.booking, required this.dateFormat});

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

String safeDecode(String? input) {
  if (input == null || input.isEmpty) return '';
  try {
    return Uri.decodeComponent(input);
  } catch (_) {
    return input;
  }
}

class _BookingCardState extends State<_BookingCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color.fromRGBO(221, 214, 155, 100),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          booking.ClinicName,
                          style: const TextStyle(
                            color: Color.fromRGBO(0, 63, 119, 85),
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          booking.AreaName,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          safeDecode(booking.Remarks),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          // Remove overflow: TextOverflow.ellipsis to allow wrapping
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.dateFormat.format(
                          booking.DateOrder ?? DateTime.now(),
                        ),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Icon(
                        expanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: booking.items.map((item) {
                  return InkWell(
                    onTap: () {
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

                          // In the dialog where you parse the dates:
                          if (item.DateExpire.isNotEmpty &&
                              item.DateExpire != 'N/A') {
                            try {
                              final parts = item.DateExpire.split('-');
                              // ✅ FIXED: parts[0] is YEAR, parts[1] is MONTH (input is YYYY-MM)
                              if (parts.length == 2) {
                                exp1 = DateTime(
                                  int.parse(parts[0]), // year (first part)
                                  int.parse(parts[1]), // month (second part)
                                  1,
                                );
                              }
                            } catch (_) {
                              print(
                                'Error parsing DateExpire: ${item.DateExpire}',
                              );
                            }
                          }

                          if (item.DateExpire2 != null &&
                              item.DateExpire2!.isNotEmpty &&
                              item.DateExpire2 != 'N/A') {
                            try {
                              final parts = item.DateExpire2!.split('-');
                              // ✅ FIXED: parts[0] is YEAR, parts[1] is MONTH (input is YYYY-MM)
                              if (parts.length == 2) {
                                exp2 = DateTime(
                                  int.parse(parts[0]), // year (first part)
                                  int.parse(parts[1]), // month (second part)
                                  1,
                                );
                              }
                            } catch (_) {
                              print(
                                'Error parsing DateExpire2: ${item.DateExpire2}',
                              );
                            }
                          }
                          // capture parent setState
                          final parentSetState = setState;

                          return StatefulBuilder(
                            builder: (context, localSetState) {
                              Future<void> pickYearMonth(bool first) async {
                                final now = DateTime.now();
                                DateTime tempDate = first
                                    ? (exp1 ?? now)
                                    : (exp2 ?? now);

                                await showDialog(
                                  context: context,
                                  builder: (context) {
                                    int selectedYear = tempDate.year;
                                    int selectedMonth = tempDate.month;

                                    // ✅ Generate year range that includes selectedYear
                                    final minYear = selectedYear < now.year - 5
                                        ? selectedYear
                                        : now.year - 5;
                                    final maxYear = selectedYear > now.year + 4
                                        ? selectedYear
                                        : now.year + 4;
                                    final yearRange = maxYear - minYear + 1;

                                    return StatefulBuilder(
                                      builder: (context, setDialogState) {
                                        return AlertDialog(
                                          title: const Text(
                                            'Select Year and Month',
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              DropdownButton<int>(
                                                value: selectedYear,
                                                items: List.generate(
                                                  yearRange,
                                                  (i) => DropdownMenuItem(
                                                    value: minYear + i,
                                                    child: Text(
                                                      '${minYear + i}',
                                                    ),
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
                                              DropdownButton<int>(
                                                value: selectedMonth,
                                                items: List.generate(
                                                  12,
                                                  (i) => DropdownMenuItem(
                                                    value: i + 1,
                                                    child: Text(
                                                      '${i + 1}'.padLeft(
                                                        2,
                                                        '0',
                                                      ),
                                                    ),
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
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            ElevatedButton(
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
                                              child: const Text('Select'),
                                            ),
                                          ],
                                        );
                                      },
                                    );
                                  },
                                );
                              }

                              return AlertDialog(
                                title: const Text('Enter Item Details'),
                                content: SingleChildScrollView(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      TextField(
                                        controller: batchController,
                                        decoration: const InputDecoration(
                                          labelText: 'Batch No',
                                          border: OutlineInputBorder(),
                                        ),
                                        onTap: () {
                                          batchController.selection =
                                              TextSelection(
                                                baseOffset: 0,
                                                extentOffset:
                                                    batchController.text.length,
                                              );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      TextField(
                                        controller: qtyController,
                                        decoration: const InputDecoration(
                                          labelText: 'Prepared Quantity',
                                          border: OutlineInputBorder(),
                                        ),
                                        keyboardType: TextInputType.number,
                                        onTap: () {
                                          qtyController.selection =
                                              TextSelection(
                                                baseOffset: 0,
                                                extentOffset:
                                                    qtyController.text.length,
                                              );
                                        },
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  pickYearMonth(true),
                                              child: Text(
                                                exp1 == null
                                                    ? 'Select Expiration 1'
                                                    : 'Exp1: ${exp1!.year}-${exp1!.month.toString().padLeft(2, '0')}',
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  pickYearMonth(false),
                                              child: Text(
                                                exp2 == null
                                                    ? 'Select Expiration 2'
                                                    : 'Exp2: ${exp2!.year}-${exp2!.month.toString().padLeft(2, '0')}',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      final batchNo = batchController.text
                                          .trim();
                                      final qtyText = qtyController.text.trim();

                                      if (qtyText.isEmpty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please enter Prepared Quantity',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      final qty = int.tryParse(qtyText) ?? 0;
                                      final maxQty =
                                          double.tryParse(
                                            item.Quantity.toString(),
                                          ) ??
                                          0;

                                      if (qty <= 0 || qty > maxQty) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Invalid quantity (max $maxQty)',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      if (exp1 == null) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Please select the first expiration date',
                                            ),
                                          ),
                                        );
                                        return;
                                      }

                                      // ✅ Update model
                                      item.BatchNo = batchNo;
                                      item.PreparedQuantity = qty;
                                      item.DateExpire =
                                          '${exp1!.year}-${exp1!.month.toString().padLeft(2, '0')}';
                                      item.DateExpire2 = exp2 == null
                                          ? ''
                                          : '${exp2!.year}-${exp2!.month.toString().padLeft(2, '0')}';

                                      Navigator.pop(context);
                                      // ✅ Refresh parent list
                                      parentSetState(() {});
                                    },
                                    child: const Text('Save'),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                      );
                    },

                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Text(
                            '${item.id}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.ItemCode.substring(
                                0,
                                item.ItemCode.length > 20
                                    ? 20
                                    : item.ItemCode.length,
                              ),
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),

                          Text(
                            (item.DateExpire.isEmpty ||
                                    item.DateExpire == 'N/A')
                                ? 'No Expiration'
                                : item.DateExpire ?? 'No Expiration',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 16),
                          Text(
                            (item.BatchNo == null || item.BatchNo!.isEmpty)
                                ? 'No Batch'
                                : item.BatchNo!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(width: 16),
                          Text(
                            '${item.PreparedQuantity}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            item.UnitOfMeasure,
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 25),
                          Text(
                            '${item.Quantity}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.normal,
                            ),
                          ),
                          const SizedBox(width: 15),
                          Text(
                            item.UnitOfMeasure,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await printSalesOrderTemplateESCUtils(booking);
                  },
                  icon: const Icon(Icons.print, size: 18),
                  label: const Text('Print'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) {
                        String? selectedPerson;

                        return StatefulBuilder(
                          builder: (context, setDialogState) {
                            return AlertDialog(
                              title: const Text('Prepared by'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  RadioListTile<String>(
                                    title: const Text('Fe'),
                                    value: 'Fe',
                                    groupValue: selectedPerson,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedPerson = value;
                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Edrin'),
                                    value: 'Edrin',
                                    groupValue: selectedPerson,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedPerson = value;
                                      });
                                    },
                                  ),
                                  RadioListTile<String>(
                                    title: const Text('Anne'),
                                    value: 'Anne',
                                    groupValue: selectedPerson,
                                    onChanged: (value) {
                                      setDialogState(() {
                                        selectedPerson = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: selectedPerson == null
                                      ? null
                                      : () async {
                                          // Store context before async operations
                                          final currentContext = context;

                                          // Close the person selection dialog
                                          Navigator.pop(currentContext);

                                          // Show loading indicator
                                          showDialog(
                                            context: currentContext,
                                            barrierDismissible: false,
                                            builder: (context) => const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );

                                          try {
                                            // Close loading indicator
                                            if (currentContext.mounted) {
                                              Navigator.pop(currentContext);
                                            }

                                            // Submit the order
                                            final success =
                                                await SalesOrderService.submitSalesOrder(
                                                  booking,
                                                  selectedPerson!,
                                                );

                                            // Show result
                                            if (success) {
                                              if (currentContext.mounted) {
                                                ScaffoldMessenger.of(
                                                  currentContext,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text(
                                                      'Order ${booking.Sono} submitted by $selectedPerson',
                                                    ),
                                                    backgroundColor:
                                                        Colors.green,
                                                  ),
                                                );
                                              }
                                            } else {
                                              if (currentContext.mounted) {
                                                ScaffoldMessenger.of(
                                                  currentContext,
                                                ).showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                      'Failed to submit order. Please try again.',
                                                    ),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          } catch (e) {
                                            // Close loading indicator on error
                                            if (currentContext.mounted) {
                                              Navigator.pop(currentContext);
                                              ScaffoldMessenger.of(
                                                currentContext,
                                              ).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                  child: const Text('Submit'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Submit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> printSalesOrderTemplate(salesorder booking) async {
    final DateFormat dateFormat = DateFormat('MMM dd, yyyy');

    // ESC/POS command for small font (Font B)
    const smallFont = '\x1B\x21\x01'; // ESC ! 1 => Small + bold
    const normalFont = '\x1B\x21\x00'; // ESC ! 0 => Normal font

    StringBuffer buffer = StringBuffer();

    // Header in small font
    buffer.write(normalFont);
    buffer.writeln('==============================');
    buffer.writeln('       VAXI WAREHOUSE         ');
    buffer.writeln('==============================');

    // Order info
    buffer.writeln('Order No : ${booking.Sono}');
    buffer.writeln('Clinic   : ${booking.ClinicName}');
    buffer.writeln('Area     : ${booking.AreaName}');
    buffer.writeln(
      'Date     : ${dateFormat.format(booking.DateOrder ?? DateTime.now())}',
    );
    if (booking.Remarks.isNotEmpty) {
      buffer.writeln('Remarks  : ${booking.Remarks}');
    }

    buffer.write(smallFont);
    buffer.writeln('-------------------------------------------');
    buffer.writeln('Item                      Qty      Exp');
    buffer.writeln('-------------------------------------------');

    // Items
    for (var item in booking.items) {
      String itemName = item.ItemCode.length > 25
          ? item.ItemCode.substring(0, 25)
          : item.ItemCode.padRight(25);
      String qty = item.Quantity.toString().padLeft(5);
      String exp = item.DateExpire.padRight(9);
      buffer.writeln('$itemName   $qty   $exp');
    }
    buffer.write(normalFont);
    buffer.writeln('------------------------------');
    buffer.writeln('        THANK YOU!            ');
    buffer.writeln('==============================');
    buffer.writeln('\n\n');

    // Reset to normal font at the end
    buffer.write(normalFont);

    // Send to printer
    bool success = await PrinterHelper.printText(buffer.toString());

    if (success) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Printed successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to print. Check printer.')),
      );
    }
  }

  // Future<void> printSalesOrderTemplatePDF(salesorder booking) async {
  //   final pdf = pw.Document();
  //   final dateFormat = DateFormat('MMM dd, yyyy');

  //   pdf.addPage(
  //     pw.Page(
  //       pageFormat: PdfPageFormat(58 * 2.8346, double.infinity), // 58mm width
  //       build: (context) {
  //         return pw.Column(
  //           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //           children: [
  //             pw.Text(
  //               'VAXI WAREHOUSE',
  //               style: pw.TextStyle(
  //                 fontSize: 8,
  //                 fontWeight: pw.FontWeight.bold,
  //               ),
  //             ),
  //             pw.SizedBox(height: 2),
  //             pw.Text(
  //               'Order No: ${booking.Sono}',
  //               style: pw.TextStyle(fontSize: 6),
  //             ),
  //             pw.Text(
  //               'Clinic: ${booking.ClinicName}',
  //               style: pw.TextStyle(fontSize: 6),
  //             ),
  //             pw.Text(
  //               'Area: ${booking.AreaName}',
  //               style: pw.TextStyle(fontSize: 6),
  //             ),
  //             pw.Text(
  //               'Date: ${dateFormat.format(booking.DateOrder ?? DateTime.now())}',
  //               style: pw.TextStyle(fontSize: 6),
  //             ),
  //             pw.Divider(),
  //             pw.Row(
  //               children: [
  //                 pw.Expanded(
  //                   child: pw.Text('Item', style: pw.TextStyle(fontSize: 6)),
  //                 ),
  //                 pw.Text('Qty', style: pw.TextStyle(fontSize: 6)),
  //                 pw.SizedBox(width: 10),
  //                 pw.Text('Exp', style: pw.TextStyle(fontSize: 6)),
  //               ],
  //             ),
  //             pw.Divider(),
  //             for (var item in booking.items)
  //               pw.Row(
  //                 children: [
  //                   pw.Expanded(
  //                     child: pw.Text(
  //                       item.ItemCode,
  //                       style: pw.TextStyle(fontSize: 6),
  //                     ),
  //                   ),
  //                   pw.Text(
  //                     '${item.Quantity}',
  //                     style: pw.TextStyle(fontSize: 6),
  //                   ),
  //                   pw.SizedBox(width: 10),
  //                   pw.Text(item.DateExpire, style: pw.TextStyle(fontSize: 6)),
  //                 ],
  //               ),
  //             pw.Divider(),
  //             pw.Center(
  //               child: pw.Text('THANK YOU!', style: pw.TextStyle(fontSize: 8)),
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );

  //   // Convert to image
  //   final Uint8List bytes = await pdf.save();
  //   await PrinterHelper.printBytes(
  //     bytes,
  //   ); // your printer must support image printing
  // }

  Future<void> printSalesOrderTemplateESCUtils(salesorder booking) async {
    final profile = await CapabilityProfile.load(); // auto-detect printer
    final generator = Generator(PaperSize.mm58, profile); // XP-58IIH is 58mm

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
    //bytes += generator.text('Clinic   : ${booking.ClinicName}');
    bytes += generator.text('Area     : ${booking.AreaName}');
    bytes += generator.text(
      'Date     : ${dateFormat.format(booking.DateOrder ?? DateTime.now())}',
    );
    if (booking.Remarks.isNotEmpty) {
      bytes += generator.text('Remarks  : ${booking.Remarks}');
    }

    bytes += generator.hr(); // horizontal line

    // --- Items (small font) ---
    bytes += generator.row([
      PosColumn(text: 'Item', width: 7),
      PosColumn(text: 'Qty', width: 2, styles: PosStyles(bold: false)),
      PosColumn(text: 'Exp', width: 3),
    ]);
    const int itemWidth = 17; // max characters for Item column

    for (var item in booking.items) {
      String itemName = '${item.ItemCode} (${item.UnitOfMeasure})';
      String qty = item.Quantity.toString();
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Printed successfully!')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to print. Check printer.')),
      );
    }
  }
}
