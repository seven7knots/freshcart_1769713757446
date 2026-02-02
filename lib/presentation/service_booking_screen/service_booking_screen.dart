import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../providers/marketplace_provider.dart';
import '../../services/marketplace_service.dart';

class ServiceBookingScreen extends ConsumerStatefulWidget {
  const ServiceBookingScreen({super.key});

  @override
  ConsumerState<ServiceBookingScreen> createState() =>
      _ServiceBookingScreenState();
}

class _ServiceBookingScreenState extends ConsumerState<ServiceBookingScreen> {
  final _notesController = TextEditingController();
  DateTime? _selectedDate;
  String _paymentMethod = 'cash';
  bool _isBooking = false;

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date != null) {
      final time =
          await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() => _selectedDate =
            DateTime(date.year, date.month, date.day, time.hour, time.minute));
      }
    }
  }

  Future<void> _createBooking(
      String serviceId, String providerId, double basePrice) async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select date and time')));
      return;
    }

    setState(() => _isBooking = true);

    try {
      final service = MarketplaceService();
      await service.createBooking(
        serviceId: serviceId,
        providerId: providerId,
        baseFare: basePrice,
        total: basePrice,
        scheduledTime: _selectedDate,
        paymentMethod: _paymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Booking created successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceId = ModalRoute.of(context)!.settings.arguments as String;
    final serviceAsync = ref.watch(serviceDetailProvider(serviceId));

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title:
            Text('Book Service', style: Theme.of(context).textTheme.titleLarge),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: serviceAsync.when(
        data: (service) {
          if (service == null) {
            return const Center(child: Text('Service not found'));
          }
          return ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              Text('Service: ${service.name}',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 2.h),
              ListTile(
                title: const Text('Select Date & Time'),
                subtitle: Text(_selectedDate != null
                    ? _selectedDate.toString().substring(0, 16)
                    : 'Not selected'),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                tileColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
              SizedBox(height: 2.h),
              Text('Payment Method',
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600)),
              SizedBox(height: 1.h),
              RadioListTile<String>(
                title: const Text('Cash'),
                value: 'cash',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              RadioListTile<String>(
                title: const Text('Wallet'),
                value: 'wallet',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                    labelText: 'Special Requests (Optional)',
                    border: OutlineInputBorder()),
                maxLines: 3,
              ),
              SizedBox(height: 2.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8.0)),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Base Fare', style: TextStyle(fontSize: 13.sp)),
                        Text('\$${service.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13.sp, fontWeight: FontWeight.w600)),
                      ],
                    ),
                    Divider(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: TextStyle(
                                fontSize: 15.sp, fontWeight: FontWeight.bold)),
                        Text('\$${service.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary)),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: 3.h),
              ElevatedButton(
                onPressed: _isBooking
                    ? null
                    : () => _createBooking(
                        service.id, service.providerId, service.basePrice),
                style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 6.h)),
                child: _isBooking
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Confirm Booking'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
            child: Text('Error: ${error.toString()}',
                style: TextStyle(color: Colors.red, fontSize: 12.sp))),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
