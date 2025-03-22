import 'dart:math';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../screens/menu_screen.dart';

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
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/images/background.png", fit: BoxFit.cover),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("Welcome!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildTextField(_emailController, "Email"),
                    _buildTextField(_passwordController, "Password", isPassword: true),
                    const SizedBox(height: 10),
                    Text('Enter the word: "$captchaWord"',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    _buildTextField(_captchaController, "Enter CAPTCHA"),
                    const SizedBox(height: 10),
                    _buildButton("Login", () => _authenticate(true), Colors.blue),
                    _buildButton("Register", () => _authenticate(false), Colors.green),
                    const SizedBox(height: 10),
                    _buildButton("Login as Admin", () => Navigator.pushNamed(context, '/admin'), Colors.orange),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {bool isPassword = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        decoration: InputDecoration(
          labelText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          fillColor: Colors.white,
          filled: true,
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: color, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        onPressed: onPressed,
        child: Text(text, style: const TextStyle(fontSize: 18, color: Colors.white)),
      ),
    );
  }
}
