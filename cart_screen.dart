import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../services/wallet_service.dart';

class CartScreen extends StatefulWidget {
  final String userEmail;
  const CartScreen({required this.userEmail, super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  final WalletService _walletService = WalletService();
  List<Map<String, dynamic>> _orders = [];
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _fetchWalletBalance();
  }

  Future<void> _fetchOrders() async {
    List<Map<String, dynamic>> orders = await _orderService.getGroupedOrders(widget.userEmail);
    if (mounted) {
      setState(() {
        _orders = orders;
      });
    }
  }

  Future<void> _fetchWalletBalance() async {
    double balance = await _walletService.getBalance(widget.userEmail);
    if (mounted) {
      setState(() {
        _walletBalance = balance;
      });
    }
  }

  Future<void> _payWithWallet() async {
    double totalUnpaid = _orders.fold(0.0, (sum, order) => sum + (order['unpaidTotal']));

    if (totalUnpaid > 0 && _walletBalance >= totalUnpaid) {
      bool success = await _walletService.deductMoney(widget.userEmail, totalUnpaid);
      if (success) {
        await _orderService.markOrdersPaid(widget.userEmail, totalUnpaid);
        _fetchOrders();
        _fetchWalletBalance();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Failed! Please try again.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Insufficient balance.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cart")),
      body: _orders.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _orders.length,
              itemBuilder: (context, index) {
                var order = _orders[index];
                return ListTile(
                  title: Text("Order ID: ${order['orderId']}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Total Price: ₹${order['totalPrice']}"),
                      Text("Total Items: ${order['totalQuantity']}"),
                    ],
                  ),
                  trailing: Text(
                    order['unpaidTotal'] > 0 ? "Unpaid" : "Paid",
                    style: TextStyle(
                      color: order['unpaidTotal'] > 0 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: _payWithWallet,
              child: const Text("Pay with Wallet"),
            ),
          ),
        ],
      ),
    );
  }
}
