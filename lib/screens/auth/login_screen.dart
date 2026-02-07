import 'package:flutter/material.dart';
import '../../models/usuario.dart';
import '../admin/admin_home.dart';
import '../worker/worker_home.dart';
import '../supervisor/supervisor_home.dart';
import '../../models/rol.dart';
import '../../services/remote_data_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  bool _rememberSession = false;

  final data = RemoteDataService.instance;

  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final Usuario? user = await data.login(
        usernameCtrl.text.trim(),
        passwordCtrl.text.trim(),
      );

      if (user == null) {
        setState(() {
          _error = "Usuario o contraseña incorrectos";
          _loading = false;
        });
        return;
      }

      if (_rememberSession) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user.id);
      }

      Widget destino;
      switch (user.rol) {
        case Rol.admin:
          destino = AdminHome(user: user);
          break;
        case Rol.supervisor:
          destino = SupervisorHome(user: user);
          break;
        case Rol.trabajador:
          destino = WorkerHome(user: user);
          break;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 🔵 HEADER
              const Icon(
                Icons.task_alt,
                size: 72,
                color: Colors.blue,
              ),
              const SizedBox(height: 12),
              const Text(
                "Control de Tareas",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Gestión simple y clara",
                style: TextStyle(color: Colors.grey),
              ),

              const SizedBox(height: 32),

              // 🟦 CARD LOGIN
              Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      TextField(
                        controller: usernameCtrl,
                        decoration: const InputDecoration(
                          labelText: "Usuario",
                          prefixIcon: Icon(Icons.person),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextField(
                        controller: passwordCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Contraseña",
                          prefixIcon: Icon(Icons.lock),
                        ),
                      ),

                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],

                      Row(
                        children: [
                          Checkbox(
                            value: _rememberSession,
                            onChanged: (v) {
                              setState(() {
                                _rememberSession = v ?? false;
                              });
                            },
                          ),
                          const Text("Mantener sesión iniciada"),
                        ],
                      ),

                      const SizedBox(height: 24),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : const Text(
                            "Iniciar sesión",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}