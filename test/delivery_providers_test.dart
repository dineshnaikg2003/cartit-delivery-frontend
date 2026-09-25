import 'package:flutter_test/flutter_test.dart';
import 'package:cartit_delivery/models/delivery_order_model.dart';
import 'package:cartit_delivery/providers/delivery_order_provider.dart';
import 'package:cartit_delivery/providers/earnings_provider.dart';
import 'package:cartit_delivery/providers/duty_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('DeliveryOrderProvider Tests', () {
    test('Initial active orders load properly', () {
      final provider = DeliveryOrderProvider();
      expect(provider.orders.isNotEmpty, true);
      expect(provider.activeOrders.isNotEmpty, true);
    });

    test('Order status advancement progresses sequentially', () async {
      final provider = DeliveryOrderProvider();
      final order = provider.orders.first;
      expect(order.status, DeliveryOrderStatus.assigned);

      await provider.advanceOrderStatus(order.id);
      final updatedOrder = provider.orders.firstWhere((o) => o.id == order.id);
      expect(updatedOrder.status, DeliveryOrderStatus.arrivedAtStore);
    });

    test('OTP Verification completes order', () {
      final provider = DeliveryOrderProvider();
      final order = provider.orders.first;

      bool invalid = provider.verifyOtpAndCompleteOrder(order.id, '0000');
      expect(invalid, false);

      bool valid = provider.verifyOtpAndCompleteOrder(order.id, order.customerOtp);
      expect(valid, true);

      final completed = provider.orders.firstWhere((o) => o.id == order.id);
      expect(completed.status, DeliveryOrderStatus.delivered);
    });
  });

  group('EarningsProvider Tests', () {
    test('Calculates total payout accurately', () {
      final provider = EarningsProvider();
      expect(provider.todayTotalPayout,
          provider.todayBasePay + provider.todayDistanceBonus + provider.todaySurge + provider.todayTips);
    });

    test('Withdrawal deducts from wallet balance', () {
      final provider = EarningsProvider();
      final initialBalance = provider.walletBalance;
      bool success = provider.withdrawFunds(500.0);
      expect(success, true);
      expect(provider.walletBalance, initialBalance - 500.0);
    });

    test('Cash in hand deposit resets to zero', () {
      final provider = EarningsProvider();
      provider.addCodCollection(200.0);
      expect(provider.cashInHand > 0, true);
      provider.depositCashInHand();
      expect(provider.cashInHand, 0.0);
    });
  });

  group('DutyProvider Tests', () {
    test('Toggling duty changes isOnDuty flag', () {
      final provider = DutyProvider();
      expect(provider.isOnDuty, true);
      provider.toggleDuty();
      expect(provider.isOnDuty, false);
      provider.toggleDuty();
      expect(provider.isOnDuty, true);
      provider.dispose();
    });
  });
}
