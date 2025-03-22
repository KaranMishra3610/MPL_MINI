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
  List<Map<String, dynamic>> _cartItems = [];
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
    _fetchWalletBalance();
  }

  Future<void> _fetchCartItems() async {
    List<Map<String, dynamic>> items =
    await _orderService.getCartItems(widget.userEmail);
    if (mounted) {
      setState(() {
        _cartItems = items;
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
    double totalUnpaid = _cartItems.fold(
        0.0, (sum, item) => sum + (item['price'] * item['unpaidQuantity']));

    if (totalUnpaid > 0 && _walletBalance >= totalUnpaid) {
      bool success =
      await _walletService.deductMoney(widget.userEmail, totalUnpaid);
      if (success) {
        await _orderService.markOrdersPaid(widget.userEmail, totalUnpaid);
        _fetchCartItems();
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
      body: _cartItems.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _cartItems.length,
              itemBuilder: (context, index) {
                var item = _cartItems[index];
                return ListTile(
                  title: Text(item['name']),
                  subtitle: Text(
                      "Price: ₹${item['price']} x ${item['paidQuantity'] + item['unpaidQuantity']}"),
                  trailing: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (item['paidQuantity'] > 0)
                        Text(
                          "Paid: ${item['paidQuantity']}",
                          style: const TextStyle(color: Colors.green),
                        ),
                      if (item['unpaidQuantity'] > 0)
                        Text(
                          "Unpaid: ${item['unpaidQuantity']}",
                          style: const TextStyle(color: Colors.red),
                        ),
                    ],
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
