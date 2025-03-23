import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';
import '../services/wallet_service.dart';
import '../screens/auth_screen.dart';

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

  Future<void> _payForOrder(String orderId, double orderTotal) async {
    if (_walletBalance >= orderTotal) {
      bool success = await _walletService.deductMoney(widget.userEmail, orderTotal);
      if (success) {
        await _orderService.markOrderPaid(widget.userEmail, orderId);
        await _fetchOrders();
        await _fetchWalletBalance();
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

  Future<void> _cancelOrder(String orderId, double refundAmount) async {
    try {
      bool refundSuccess = await _walletService.addMoney(widget.userEmail, refundAmount);

      if (refundSuccess) {
        await FirebaseFirestore.instance
            .collection("user_cart")
            .doc(widget.userEmail)
            .collection("orders")
            .doc(orderId)
            .delete();

        await _fetchOrders();
        await _fetchWalletBalance();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order canceled successfully! Amount refunded.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to process refund!")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to cancel order!")),
      );
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Cart"),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _orders.isEmpty
          ? const Center(child: Text("Your cart is empty"))
          : ListView.builder(
        itemCount: _orders.length,
        itemBuilder: (context, index) {
          var order = _orders[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ExpansionTile(
              title: Text("Order ID: ${order['orderId']}"),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Total Price: ₹${order['totalPrice']}"),
                  Text("Total Items: ${order['totalQuantity']}"),
                ],
              ),
              children: [
                Column(
                  children: (order['items'] as List<dynamic>).map<Widget>((item) {
                    return ListTile(
                      title: Text(item['name']),
                      subtitle: Text("Price: ₹${item['price']} x ${item['unpaidQuantity']}"),
                    );
                  }).toList(),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () => _payForOrder(order['orderId'], order['unpaidTotal']),
                      child: const Text("Pay with Wallet"),
                    ),
                    TextButton(
                      onPressed: () => _cancelOrder(order['orderId'], order['unpaidTotal']),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text("Cancel Order"),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        },
      ),
    );
  }
}
