import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';
import '../services/wallet_service.dart';

final walletServiceProvider = Provider((ref) => WalletService());

final userWalletProvider = FutureProvider<WalletModel?>((ref) async {
  final walletService = ref.watch(walletServiceProvider);
  return await walletService.getUserWallet();
});

final transactionHistoryProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final walletService = ref.watch(walletServiceProvider);
  return await walletService.getTransactionHistory();
});
