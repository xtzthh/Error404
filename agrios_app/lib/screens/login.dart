import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../widgets/cyber_card.dart';
import '../providers/theme_provider.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  late final AnimationController _introController;
  late final Animation<double> _fadeIn;
  late final Animation<Offset> _slideIn;
  bool _isLoggingIn = false;

  @override
  void initState() {
    super.initState();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    );
    _slideIn = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _introController,
      curve: Curves.easeOutCubic,
    ));
    _introController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _introController.dispose();
    super.dispose();
  }

  Future<void> _doLogin() async {
    if (_isLoggingIn) return;
    setState(() => _isLoggingIn = true);
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;

    if (_usernameController.text == 'judge' && _passwordController.text == 'agri123') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainDashboard()),
      );
    } else {
      setState(() => _isLoggingIn = false);
      final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.errorRed,
          content: Text(
            'AUTH_ERROR: INVALID_CREDENTIALS',
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontFamily: 'monospace',
              color: isDark ? Colors.white : Colors.white,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBg(isDark),
      body: Stack(
        children: [
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.05 : 0.02,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/carbon-fibre.png',
                repeat: ImageRepeat.repeat,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ),
          
          // Theme Toggle
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                color: isDark ? AppColors.neonGreen : AppColors.lightText,
              ),
              onPressed: () => themeProvider.toggleTheme(),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: FadeTransition(
                opacity: _fadeIn,
                child: SlideTransition(
                  position: _slideIn,
                  child: CyberCard(
                    width: 350,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 20),
                        _buildBrand(isDark),
                        const SizedBox(height: 30),
                        Text(
                          'AUTHENTICATE_SESSION',
                          style: TextStyle(
                            color: isDark ? AppColors.neonGreen : AppColors.lightText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            fontStyle: FontStyle.italic,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 25),
                        _buildTextField('Username', _usernameController, false, isDark),
                        const SizedBox(height: 15),
                        _buildTextField('Password', _passwordController, true, isDark),
                        const SizedBox(height: 25),
                        _buildLoginButton(isDark),
                        const SizedBox(height: 20),
                        MilitaryTag(text: 'Credentials: judge / agri123', isDark: isDark),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          color: isDark ? AppColors.neonGreen : AppColors.lightText,
          alignment: Alignment.center,
          child: Text(
            'AS',
            style: TextStyle(
              color: isDark ? AppColors.cyberBlack : Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 15),
        Text(
          'AGRI-OS',
          style: TextStyle(
            color: isDark ? AppColors.neonGreen : AppColors.lightText,
            fontWeight: FontWeight.w900,
            fontStyle: FontStyle.italic,
            fontSize: 24,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String hint, TextEditingController controller, bool isPassword, bool isDark) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: TextStyle(
        color: isDark ? AppColors.neonGreen : AppColors.lightText, 
        fontFamily: 'monospace'
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.getMutedText(isDark), 
          fontSize: 14, 
          fontFamily: 'monospace'
        ),
        filled: true,
        fillColor: isDark ? AppColors.cyberBlack : Colors.white.withOpacity(0.5),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.getBorder(isDark)),
          borderRadius: BorderRadius.zero,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: isDark ? AppColors.neonGreen : AppColors.lightText),
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }

  Widget _buildLoginButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoggingIn ? null : _doLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? AppColors.neonGreen : AppColors.lightText,
          foregroundColor: isDark ? AppColors.cyberBlack : Colors.white,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: _isLoggingIn
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.cyberBlack),
                  ),
                )
              : const Text(
                  'LOGIN',
                  style: TextStyle(fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                ),
        ),
      ),
    );
  }
}

class MilitaryTag extends StatelessWidget {
  final String text;
  final bool isDark;
  const MilitaryTag({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final color = isDark ? AppColors.neonGreen : AppColors.lightText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        ),
      ),
    );
  }
}
