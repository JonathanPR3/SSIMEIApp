import 'package:curso/navigation/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:curso/routes.dart';
import 'package:curso/constants/app_constants.dart';
import 'package:curso/providers/auth_provider.dart'; // Tu AuthProvider
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:curso/screens/organization/accept_invitation_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Manejar link inicial (cuando la app se abre con un deep link)
    try {
      final initialLink = await _appLinks.getInitialLink();
      if (initialLink != null) {
        _handleDeepLink(initialLink);
      }
    } catch (e) {
      print('❌ Error obteniendo link inicial: $e');
    }

    // Escuchar deep links mientras la app está abierta
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        print('🔗 Deep link recibido: $uri');
        _handleDeepLink(uri);
      },
      onError: (err) {
        print('❌ Error en deep link stream: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    print('📱 Procesando deep link: ${uri.toString()}');
    print('   Scheme: ${uri.scheme}');
    print('   Host: ${uri.host}');
    print('   Path: ${uri.path}');
    print('   Query: ${uri.queryParameters}');

    // Verificar si es un link de invitación
    // Soporta: ssimei://accept-invite?token=XXX
    // Soporta: https://ssimei.app/accept-invite?token=XXX
    if ((uri.scheme == 'ssimei' && uri.host == 'accept-invite') ||
        (uri.scheme == 'https' && uri.host == 'ssimei.app' && uri.path == '/accept-invite')) {

      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        print('✅ Token encontrado: ${token.substring(0, 20)}...');

        // Navegar a la pantalla de aceptar invitación
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final context = NavigationService.navigatorKey.currentContext;
          if (context != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => AcceptInvitationScreen(token: token),
              ),
            );
          }
        });
      } else {
        print('❌ Token no encontrado en el deep link');
      }
    } else {
      print('⚠️ Deep link no reconocido');
    }
  }

  @override
  Widget build(BuildContext context) {
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

  String? _getSpecialRoute() {
    // En web, verificar si hay una ruta específica en el fragment
    try {
      final uri = Uri.base;
      print('🌐 URI inicial en AuthWrapper: ${uri.toString()}');
      print('   Fragment: ${uri.fragment}');

      if (uri.fragment.isNotEmpty) {
        final fragment = uri.fragment;
        // Detectar rutas específicas
        if (fragment.startsWith('/accept-invite')) {
          print('✅ Ruta especial detectada: /accept-invite');
          return '/accept-invite';
        } else if (fragment.startsWith('/reset-password')) {
          return '/reset-password';
        } else if (fragment.startsWith('/confirm-email')) {
          return '/confirm-email';
        }
      }
    } catch (e) {
      print('❌ Error verificando ruta: $e');
    }
    return null;
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

    // MODIFICADO: Verificar si hay ruta especial primero
    final specialRoute = _getSpecialRoute();

    if (!_hasNavigated) {
      _hasNavigated = true; // Marcar que ya se navegó

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (specialRoute != null) {
          // Si hay ruta especial, navegar a ella
          print('📍 Navegando a ruta especial: $specialRoute');
          Navigator.of(context).pushReplacementNamed(specialRoute);
        } else if (authState.isLoggedIn) {
          // Usuario logueado → Home
          print('Usuario logueado: ${authState.user?.nombreCompleto}');
          print('Navegando a HOME');
          Navigator.of(context).pushReplacementNamed(AppConstants.homeRoute);
        } else {
          // Usuario no logueado → Welcome
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

    // DESACTIVADO: El AuthWrapper ya maneja la navegación correctamente
    // No queremos que este timeout sobrescriba la navegación a rutas especiales
    // como /accept-invite

    // Future.delayed(const Duration(seconds: 8), () {
    //   if (mounted) {
    //     print('⏱️ Timeout de seguridad - navegando a welcome');
    //     Navigator.of(context).pushReplacementNamed(AppConstants.welcomeRoute);
    //   }
    // });
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