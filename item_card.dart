import 'package:flutter/material.dart';

class ItemCard extends StatelessWidget {
  final String name;
  final double price;
  final VoidCallback onAdd;

  const ItemCard({super.key, 
    required this.name,
    required this.price,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("\$${price.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, color: Colors.grey[700])),
            SizedBox(height: 8),
            ElevatedButton(onPressed: onAdd, child: Text("Add to Cart"))
          ],
        ),
      ),
    );
  }
}
