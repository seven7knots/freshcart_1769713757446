import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sizer/sizer.dart';

import '../../providers/marketplace_provider.dart';
import '../../services/marketplace_service.dart';
import '../../l10n/generated/app_localizations.dart';

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
          SnackBar(content: Text('Please select date and time', maxLines: 1, overflow: TextOverflow.ellipsis)));
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
            SnackBar(content: Text('Booking created successfully', maxLines: 1, overflow: TextOverflow.ellipsis)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}', maxLines: 1, overflow: TextOverflow.ellipsis)));
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
            Text(AppLocalizations.of(context)!.bookService, style: Theme.of(context).textTheme.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: serviceAsync.when(
        data: (service) {
          if (service == null) {
            return Center(child: Text(AppLocalizations.of(context)!.serviceNotFound, maxLines: 1, overflow: TextOverflow.ellipsis));
          }
          return ListView(
            padding: EdgeInsets.all(4.w),
            children: [
              Text('Service: ${service.name}',
                  style:
                      TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 2.h),
              ListTile(
                title: Text(AppLocalizations.of(context)!.selectDateTime, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text(_selectedDate != null
                    ? _selectedDate.toString().substring(0, 16)
                    : AppLocalizations.of(context)!.notSelected, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDate,
                tileColor:
                    Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
              SizedBox(height: 2.h),
              Text(AppLocalizations.of(context)!.paymentMethod,
                  style:
                      TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 1.h),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.cash, maxLines: 1, overflow: TextOverflow.ellipsis),
                value: 'cash',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              RadioListTile<String>(
                title: Text(AppLocalizations.of(context)!.wallet, maxLines: 1, overflow: TextOverflow.ellipsis),
                value: 'wallet',
                groupValue: _paymentMethod,
                onChanged: (v) => setState(() => _paymentMethod = v!),
              ),
              SizedBox(height: 2.h),
              TextField(
                controller: _notesController,
                decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.specialRequestsOptional,
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
                        Flexible(child: Text(AppLocalizations.of(context)!.baseFare, style: TextStyle(fontSize: 13.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Flexible(child: Text('\$${service.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 13.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    Divider(height: 2.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(child: Text(AppLocalizations.of(context)!.total,
                            style: TextStyle(
                                fontSize: 15.sp, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Flexible(child: Text('\$${service.basePrice.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary), maxLines: 1, overflow: TextOverflow.ellipsis)),
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
                    : Text(AppLocalizations.of(context)!.confirmBooking, maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
            child: Text('Error: ${error.toString()}',
                style: TextStyle(color: Colors.red, fontSize: 12.sp), maxLines: 1, overflow: TextOverflow.ellipsis)),
      ),
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }
}
