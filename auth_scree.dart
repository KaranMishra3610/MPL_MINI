import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/menu_screen.dart'; // ✅ Import MenuScreen

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _captchaController = TextEditingController();
  final AuthService _authService = AuthService();

  final List<String> captchaWords = ["apple", "secure", "verify", "random", "trust"];
  late String captchaWord;

  @override
  void initState() {
    super.initState();
    _generateNewCaptcha();
  }

  void _generateNewCaptcha() {
    setState(() {
      captchaWord = captchaWords[Random().nextInt(captchaWords.length)];
    });
  }

  void _authenticate(bool isLogin) async {
    if (_captchaController.text.trim().toLowerCase() != captchaWord.toLowerCase()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Incorrect CAPTCHA. Try again!")),
      );
      _generateNewCaptcha();
      return;
    }

    String? userId = isLogin
        ? await _authService.login(_emailController.text.trim(), _passwordController.text.trim())
        : await _authService.register(_emailController.text.trim(), _passwordController.text.trim());

    if (userId != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isLogin ? "Login Successful!" : "Registration Successful!")),
      );

      // ✅ Navigate to MenuScreen with userEmail after successful login
      Future.delayed(const Duration(milliseconds: 500), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(userEmail: _emailController.text.trim()),
          ),
        );
      });

    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Authentication Failed!")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Login / Register")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: "Password"),
              obscureText: true,
            ),
            const SizedBox(height: 10),
            Text('Enter the word: "$captchaWord"',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextField(
              controller: _captchaController,
              decoration: const InputDecoration(labelText: "Enter CAPTCHA"),
            ),
            const SizedBox(height: 10),
            ElevatedButton(onPressed: () => _authenticate(true), child: const Text("Login")),
            ElevatedButton(onPressed: () => _authenticate(false), child: const Text("Register")),
          ],
        ),
      ),
    );
  }
}
