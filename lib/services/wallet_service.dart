import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';
import '../models/transaction_model.dart';

class WalletService {
  final SupabaseClient _client = Supabase.instance.client;

  // Get user wallet
  Future<WalletModel?> getUserWallet() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await _client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return WalletModel.fromJson(response);
    } catch (e) {
      throw Exception('Failed to get wallet: $e');
    }
  }

  // Get wallet balance
  Future<double> getWalletBalance() async {
    try {
      final wallet = await getUserWallet();
      return wallet?.balance ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get transaction history
  Future<List<TransactionModel>> getTransactionHistory({
    String? type,
    int limit = 50,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final wallet = await getUserWallet();
      if (wallet == null) return [];

      var query =
          _client.from('transactions').select().eq('wallet_id', wallet.id);

      if (type != null) {
        query = query.eq('type', type);
      }

      final response =
          await query.order('created_at', ascending: false).limit(limit);

      return (response as List)
          .map((json) => TransactionModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to load transactions: $e');
    }
  }

  // Top up wallet (placeholder - requires payment gateway)
  Future<void> topUpWallet(double amount) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // This would integrate with payment gateway
      // For now, just log the intent
      throw UnimplementedError('Payment gateway integration required');
    } catch (e) {
      throw Exception('Failed to top up wallet: $e');
    }
  }
}
