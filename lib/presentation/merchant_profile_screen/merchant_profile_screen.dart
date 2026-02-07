import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import './widgets/merchant_form_widget.dart';

class MerchantProfileScreen extends StatefulWidget {
  const MerchantProfileScreen({super.key});

  @override
  State<MerchantProfileScreen> createState() => _MerchantProfileScreenState();
}

class _MerchantProfileScreenState extends State<MerchantProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMerchant();
    });
  }

  void _loadMerchant() {
    final authProvider = context.read<AuthProvider>();
    final merchantProvider = context.read<MerchantProvider>();
    final userId = authProvider.userId;

    if (userId != null) {
      merchantProvider.loadMyMerchant(userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Merchant Profile',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer2<MerchantProvider, AuthProvider>(
        builder: (context, merchantProvider, authProvider, child) {
          if (merchantProvider.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading merchant profile...',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          if (merchantProvider.error != null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.sp,
                      color: Colors.red,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      'Error loading merchant',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      merchantProvider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 3.h),
                    ElevatedButton(
                      onPressed: _loadMerchant,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final merchant = merchantProvider.merchant;
          final userId = authProvider.userId;

          if (userId == null) {
            return const Center(
              child: Text('Please log in to continue'),
            );
          }

          return SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: MerchantFormWidget(
                merchant: merchant,
                userId: userId,
                onSuccess: () {
                  _loadMerchant();
                },
              ),
            ),
          );
        },
      ),
    );
  }
}