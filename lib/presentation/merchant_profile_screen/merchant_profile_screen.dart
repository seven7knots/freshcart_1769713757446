import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../providers/auth_provider.dart';
import '../../providers/merchant_provider.dart';
import './widgets/merchant_form_widget.dart';
import '../../l10n/generated/app_localizations.dart';

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.merchantProfile,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    AppLocalizations.of(context)!.loadingMerchantProfile,
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            );
          }

          if (merchantProvider.error != null &&
              merchantProvider.merchant == null) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 48.sp,
                      color: theme.colorScheme.error,
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      AppLocalizations.of(context)!.errorLoadingMerchant,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 1.h),
                    Text(
                      merchantProvider.error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: theme.colorScheme.onSurfaceVariant,
                      ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    SizedBox(height: 3.h),
                    ElevatedButton.icon(
                      onPressed: _loadMerchant,
                      icon: const Icon(Icons.refresh),
                      label: Text(AppLocalizations.of(context)!.retry, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ),
            );
          }

          final merchant = merchantProvider.merchant;
          final userId = authProvider.userId;

          if (userId == null) {
            return Center(
              child: Text(AppLocalizations.of(context)!.pleaseLogInToContinue, maxLines: 1, overflow: TextOverflow.ellipsis),
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