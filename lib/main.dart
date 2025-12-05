import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'screens/notes_screen.dart';
import 'screens/tasks_screen.dart';
import 'screens/lock_screen.dart';
import 'services/notification_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.initialize();
  runApp(const NovaApp());
}

class NovaApp extends StatelessWidget {
  const NovaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Nova',
            debugShowCheckedModeBanner: false,
            theme: ThemeProvider.lightTheme(),
            darkTheme: ThemeProvider.darkTheme(),
            themeMode: themeProvider.themeMode,
            home: const MainScreen(),
          );
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLocked = false;
  bool _isCheckingAuth = true;

  final List<Widget> _screens = [const NotesScreen(), const TasksScreen()];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkAuthenticationStatus();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAuthenticationStatus();
    }
  }

  Future<void> _checkAuthenticationStatus() async {
    final authService = AuthService.instance;
    final isPinSet = await authService.isPinSet();
    final shouldLock = await authService.shouldLock();
    
    setState(() {
      _isLocked = isPinSet && shouldLock;
      _isCheckingAuth = false;
    });
  }

  Future<void> _onUnlocked() async {
    final authService = AuthService.instance;
    authService.updateLastActiveTime();
    setState(() {
      _isLocked = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Show loading while checking auth
    if (_isCheckingAuth) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    // Show lock screen if locked
    if (_isLocked) {
      return WillPopScope(
        onWillPop: () async => false, // Prevent back button
        child: LockScreen(onUnlocked: _onUnlocked),
      );
    }
    
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
          },
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : Colors.white,
          indicatorColor: const Color(0xFF2DBD6C).withValues(alpha: 0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.note_outlined),
              selectedIcon: Icon(Icons.note, color: Color(0xFF2DBD6C)),
              label: 'Notes',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_today_outlined),
              selectedIcon: Icon(Icons.calendar_today, color: Color(0xFF2DBD6C)),
              label: 'Tasks',
            ),
          ],
        ),
      ),
    );
  }
}
