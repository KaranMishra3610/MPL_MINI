import 'package:flutter/material.dart';
import '../services/wallet_service.dart';

class WalletScreen extends StatefulWidget {
  final String userEmail;
  const WalletScreen({required this.userEmail, super.key});

  @override
  _WalletScreenState createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final WalletService _walletService = WalletService();
  double balance = 0.0;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchBalance();
  }

  Future<void> _fetchBalance() async {
    double newBalance = await _walletService.getBalance(widget.userEmail);
    if (mounted) {
      setState(() {
        balance = newBalance;
      });
    }
  }

  Future<void> _addMoney() async {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0) {
      await _walletService.addMoney(widget.userEmail, amount);
      _fetchBalance();
      _amountController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Money added successfully!")),
      );
    }
  }

  Future<void> _payWithWallet() async {
    double amount = double.tryParse(_amountController.text) ?? 0;
    if (amount > 0) {
      bool success = await _walletService.deductMoney(widget.userEmail, amount);
      if (success) {
        _fetchBalance();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Insufficient Balance!")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Wallet")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Wallet Balance: ₹${balance.toStringAsFixed(2)}",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter Amount",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _addMoney,
                  child: const Text("Add Money"),
                ),
                ElevatedButton(
                  onPressed: _payWithWallet,
                  child: const Text("Pay with Wallet"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
