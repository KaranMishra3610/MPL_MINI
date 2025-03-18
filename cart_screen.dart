import 'package:flutter/material.dart';
import '../services/order_service.dart';

class CartScreen extends StatefulWidget {
  final String userEmail;
  const CartScreen({required this.userEmail, super.key});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final OrderService _orderService = OrderService();
  List<Map<String, dynamic>> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  Future<void> _fetchCartItems() async {
    List<Map<String, dynamic>> items = await _orderService.getCartItems(widget.userEmail);
    if (mounted) {
      setState(() {
        _cartItems = items;
      });
    }
  }

  Future<void> _updateQuantity(String name, int change) async {
    await _orderService.updateQuantity(widget.userEmail, name, change);
    _fetchCartItems(); // Refresh UI
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Cart")),
      body: _cartItems.isEmpty
          ? Center(child: Text("Your cart is empty"))
          : ListView.builder(
        itemCount: _cartItems.length,
        itemBuilder: (context, index) {
          var item = _cartItems[index];
          return ListTile(
            title: Text(item['name']),
            subtitle: Text("Price: ${item['price']} x ${item['quantity']}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(icon: Icon(Icons.remove), onPressed: () => _updateQuantity(item['name'], -1)),
                IconButton(icon: Icon(Icons.add), onPressed: () => _updateQuantity(item['name'], 1)),
              ],
            ),
          );
        },
      ),
    );
  }
}
