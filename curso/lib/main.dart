import 'package:curso/navigation/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curso/routes.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/providers/auth_provider.dart'; // Tu AuthProvider

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      navigatorKey: NavigationService.navigatorKey,
      title: AppConstants.appName,
      theme: ThemeData.dark(),
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
      routes: appRoutes,
    );
  }
}

class AuthWrapper extends ConsumerStatefulWidget {
  const AuthWrapper({super.key});

  @override
  ConsumerState<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends ConsumerState<AuthWrapper> {
  bool _hasInitialized = false;
  bool _hasNavigated = false; // AGREGADO: Para evitar navegación múltiple

  @override
  void initState() {
    super.initState();
    // Inicializar el AuthProvider cuando se crea el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeAuth();
    });
  }

  Future<void> _initializeAuth() async {
    if (_hasInitialized) return;
    _hasInitialized = true;
    
    print('🔄 Inicializando AuthProvider...');
    // Usar tu método initialize del AuthProvider
    await ref.read(authNotifierProvider.notifier).initialize();
  }

  @override
  Widget build(BuildContext context) {
    // Observar el estado del AuthProvider
    final authState = ref.watch(authNotifierProvider);
    
    print('🔍 AuthState: isLoading=${authState.isLoading}, isLoggedIn=${authState.isLoggedIn}, isInitialized=${authState.isInitialized}');
    
    // Si no está inicializado o está cargando, mostrar splash
    if (!authState.isInitialized || authState.isLoading) {
      return const SplashScreen();
    }

    // MODIFICADO: Solo navegar si no se ha navegado antes
    if (!_hasNavigated) {
      _hasNavigated = true; // Marcar que ya se navegó
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (authState.isLoggedIn) {
          print('Usuario logueado: ${authState.user?.nombreCompleto}');
          print('Navegando a HOME');
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        } else {
          print('Usuario no logueado');
          print('Navegando a WELCOME');
          Navigator.of(context).pushReplacementNamed(AppConstants.welcomeRoute);
        }
      });
    }

    // Mientras navega, seguir mostrando splash
    return const SplashScreen();
  }
}

// Splash Screen (sin cambios)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: AppConstants.mediumAnimation,
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
    
    // Timeout de seguridad más largo para dar tiempo a la verificación
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) {
        print('⏱️ Timeout de seguridad - navegando a welcome');
        Navigator.of(context).pushReplacementNamed(AppConstants.welcomeRoute);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppConstants.darkBackground,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppConstants.primaryBlue,
                  borderRadius: BorderRadius.circular(AppConstants.borderRadius * 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: AppConstants.primaryBlue.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.security,
                  color: AppConstants.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryBlue,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                AppConstants.appDescription,
                style: TextStyle(
                  fontSize: 16,
                  color: AppConstants.textLight.withOpacity(0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CircularProgressIndicator(
                color: AppConstants.primaryBlue,
              ),
              const SizedBox(height: 20),
              Text(
                'Verificando sesión...',
                style: TextStyle(
                  fontSize: 14,
                  color: AppConstants.textLight.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}