import 'dart:async';
import 'package:flutter/material.dart';
import '../../features/auth/services/auth_service.dart';
import '../../core/database/database_service.dart';
import '../home/home_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;

  const VerifyEmailScreen({
    Key? key,
    required this.email,
    required this.firstName,
    required this.lastName,
  }) : super(key: key);

  @override
  _VerifyEmailScreenState createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _authService = AuthService();
  final _dbService = DatabaseService();
  bool _isLoading = false;
  int _start = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    setState(() => _start = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (_start == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void _resend() async {
    _startTimer();
    await _authService.resendOtp(widget.email);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código reenviado. Revisa tu correo.')),
      );
    }
  }

  void _verify() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userId = await _authService.verifyEmail(
      widget.email,
      _codeController.text.trim(),
    );

    if (userId != null) {
      // Create user profile in 'usuarios' table
      await _dbService.insertRecord('usuarios', {
        'auth_user_id': userId,
        'email': widget.email,
        'first_name': widget.firstName,
        'last_name': widget.lastName,
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Código inválido o expirado. Inténtalo de nuevo.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verificar Email')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Hemos enviado un código de verificación a ${widget.email}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'Código de 6 dígitos'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.length != 6) {
                    return 'Ingresa el código de 6 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton(
                  onPressed: _verify,
                  child: const Text('Verificar'),
                ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: _start == 0 ? _resend : null,
                child: Text(_start == 0 ? 'Reenviar código' : 'Reenviar código en $_start s'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Goes back to RegisterScreen
                },
                child: const Text('¿Te equivocaste de correo? Volver'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
