import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/user_service.dart';

final userServiceProvider = Provider((ref) => UserService());

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getCurrentUserProfile();
});

final walletBalanceProvider = FutureProvider<double>((ref) async {
  final userService = ref.watch(userServiceProvider);
  return await userService.getWalletBalance();
});
