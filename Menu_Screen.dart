import 'package:flutter/material.dart';
import 'cart_screen.dart';
import '../widgets/item_card.dart';
import '../services/order_service.dart';

class MenuScreen extends StatefulWidget {
  final String userEmail;
  const MenuScreen({required this.userEmail, super.key});

  @override
  _MenuScreenState createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final OrderService _orderService = OrderService();

  final List<Map<String, dynamic>> menuItems = [
    {"name": "Pizza", "price": 8.99},
    {"name": "Burger", "price": 5.99},
    {"name": "Pasta", "price": 7.49},
  ];

  Future<void> addToCart(String name, double price) async {
    await _orderService.addToCart(widget.userEmail, name, price);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$name added to cart")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Canteen Menu"), actions: [
        IconButton(icon: Icon(Icons.shopping_cart), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => CartScreen(userEmail: widget.userEmail)))),
      ]),
      body: ListView(
        children: menuItems.map((item) => ItemCard(name: item["name"], price: item["price"], onAdd: () => addToCart(item["name"], item["price"]))).toList(),
      ),
    );
  }
}
