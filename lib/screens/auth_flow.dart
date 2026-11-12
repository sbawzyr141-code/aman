import 'package:flutter/material.dart' hide Text;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_language.dart';
import 'main_layout_screen.dart'; // تأكد من مطابقة مسار الشاشة الرئيسية لديك

// -------------------------------------------------------------
// 1. TOPOGRAPHIC CONTOUR CUSTOM PAINTER
// -------------------------------------------------------------
class TopographicContourPainter extends CustomPainter {
  final Color lineColor;
  final Color accentColor;

  TopographicContourPainter({
    this.lineColor = const Color(0x33527F90),
    this.accentColor = const Color(0x28315F73),
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final paintLine = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final paintAccent = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final center1 = Offset(w * 0.62, h * 0.32);
    final radii = [
      const Offset(0.07, 0.05),
      const Offset(0.14, 0.10),
      const Offset(0.22, 0.16),
      const Offset(0.31, 0.23),
      const Offset(0.42, 0.32),
      const Offset(0.55, 0.43),
      const Offset(0.70, 0.56),
    ];

    for (int i = 0; i < radii.length; i++) {
      final rx = w * radii[i].dx;
      final ry = h * radii[i].dy;
      final rect = Rect.fromCenter(
        center: center1,
        width: rx * 2,
        height: ry * 2,
      );
      canvas.drawOval(rect, (i % 2 == 0) ? paintLine : paintAccent);
    }

    final center2 = Offset(w * 0.22, h * 0.58);
    final secondaryRadii = [
      const Offset(0.08, 0.06),
      const Offset(0.18, 0.13),
      const Offset(0.28, 0.21),
      const Offset(0.39, 0.30),
    ];
    for (var r in secondaryRadii) {
      final rect = Rect.fromCenter(
        center: center2,
        width: w * r.dx * 2,
        height: h * r.dy * 2,
      );
      canvas.drawOval(rect, paintLine);
    }

    final wave1 = Path()
      ..moveTo(-w * 0.1, h * 0.15)
      ..cubicTo(w * 0.25, h * 0.05, w * 0.55, h * 0.25, w * 1.1, h * 0.10);
    canvas.drawPath(wave1, paintAccent);

    final wave2 = Path()
      ..moveTo(-w * 0.1, h * 0.48)
      ..cubicTo(w * 0.35, h * 0.68, w * 0.70, h * 0.28, w * 1.1, h * 0.50);
    canvas.drawPath(wave2, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// -------------------------------------------------------------
// 2. CUSTOM WAVE CLIPPER
// -------------------------------------------------------------
enum WaveClipType { welcome, signIn }

class TopographicWaveClipper extends CustomClipper<Path> {
  final WaveClipType type;
  TopographicWaveClipper({this.type = WaveClipType.welcome});

  @override
  Path getClip(Size size) {
    final path = Path();
    final w = size.width;
    final h = size.height;

    path.moveTo(0, 0);
    path.lineTo(w, 0);

    if (type == WaveClipType.welcome) {
      path.lineTo(w, h * 0.88);
      path.cubicTo(w * 0.72, h * 1.05, w * 0.40, h * 0.84, 0, h * 0.86);
    } else {
      path.lineTo(w, h * 0.90);
      path.cubicTo(w * 0.70, h * 1.04, w * 0.35, h * 0.78, 0, h * 0.82);
    }

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// -------------------------------------------------------------
// 3. REUSABLE WAVE HEADER WIDGET
// -------------------------------------------------------------
class TopographicWaveHeaderWidget extends StatelessWidget {
  final double height;
  final WaveClipType clipType;
  final Widget? overlayChild;

  const TopographicWaveHeaderWidget({
    super.key,
    required this.height,
    this.clipType = WaveClipType.welcome,
    this.overlayChild,
  });

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: TopographicWaveClipper(type: clipType),
      child: Container(
        height: height,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF315F73), Color(0xFF3D7183), Color(0xFF315F73)],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: TopographicContourPainter()),
            ),
            ?overlayChild,
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 4. ONBOARDING / WELCOME SCREEN
// -------------------------------------------------------------
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.58;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FA),
      body: Column(
        children: [
          TopographicWaveHeaderWidget(
            height: headerHeight,
            clipType: WaveClipType.welcome,
            overlayChild: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0x33FFFFFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shield,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'AMAN SYSTEM',
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    const LanguageSwitchButton(foregroundColor: Colors.white),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF315F73),
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 14),
                      Text(
                        'منظومة أمان لتأمين الهواتف وتوثيق عقود البيع الرسمية للمحلات التجارية ومنع سرقة الأجهزة.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: Color(0xFF87969D),
                        ),
                      ),
                    ],
                  ),
                  SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignInScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF87969D),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignInScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(27),
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: const BoxDecoration(
                              color: Color(0xFF315F73),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0x40315F73),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 5. SIGN IN / LOGIN SCREEN
// -------------------------------------------------------------
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        if (!mounted) return;
        setState(() => _isLoading = false);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainLayoutScreen()),
          (route) => false,
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        String message = 'حدث خطأ أثناء تسجيل الدخول';
        if (e.code == 'invalid-credential' ||
            e.code == 'wrong-password' ||
            e.code == 'user-not-found') {
          message = 'البريد الإلكتروني أو كلمة المرور غير صحيحة.';
        } else if (e.code == 'invalid-email') {
          message = 'صيغة البريد الإلكتروني غير صحيحة.';
        } else if (e.message != null) {
          message = e.message!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.36;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FA),
      body: Column(
        children: [
          TopographicWaveHeaderWidget(
            height: headerHeight,
            clipType: WaveClipType.signIn,
            overlayChild: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const LanguageSwitchButton(foregroundColor: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign in',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF315F73),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 36,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF315F73),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 28),
                    const Text(
                      'Email',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF87969D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        color: Color(0xFF315F73),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.email_outlined,
                          size: 20,
                          color: Color(0xFF315F73),
                        ),
                        hintText: 'demo@email.com',
                        hintStyle: const TextStyle(color: Color(0xFF9AAAB1)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8EEF0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF315F73),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return translateAppText(
                            'الرجاء إدخال البريد الإلكتروني',
                          );
                        }
                        if (!value.contains('@')) {
                          return translateAppText('بريد إلكتروني غير صالح');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Password',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF87969D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(
                        color: Color(0xFF315F73),
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: Color(0xFF315F73),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9AAAB1),
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                        hintText: translateAppText('enter your password'),
                        hintStyle: const TextStyle(color: Color(0xFF9AAAB1)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8EEF0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF315F73),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return translateAppText('الرجاء إدخال كلمة المرور');
                        }
                        if (value.length < 4) {
                          return translateAppText('كلمة المرور قصيرة جداً');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 24,
                                height: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: const Color(0xFF315F73),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  onChanged: (val) => setState(
                                    () => _rememberMe = val ?? false,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Flexible(
                                child: Text(
                                  'Remember Me',
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFF87969D),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: TextButton(
                            onPressed: () {
                              if (_emailController.text.trim().isNotEmpty) {
                                FirebaseAuth.instance.sendPasswordResetEmail(
                                  email: _emailController.text.trim(),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'تم إرسال رابط استعادة كلمة المرور إلى بريدك',
                                    ),
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'الرجاء كتابة البريد الإلكتروني أولاً',
                                    ),
                                  ),
                                );
                              }
                            },
                            child: const FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Forgot Password?',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF315F73),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF315F73),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an Account ? ",
                          style: TextStyle(
                            color: Color(0xFF87969D),
                            fontSize: 14,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Sign up',
                            style: TextStyle(
                              color: Color(0xFF315F73),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 6. SIGN UP / REGISTER SCREEN
// -------------------------------------------------------------
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String _selectedRole = 'shop_owner';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);

      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );
        final createdUser = userCredential.user;
        if (createdUser == null) {
          throw StateError('Firebase did not return the created user.');
        }

        await FirebaseFirestore.instance
            .collection('users')
            .doc(createdUser.uid)
            .set({
              'fullName': _nameController.text.trim(),
              'phone': _phoneController.text.trim(),
              'email': _emailController.text.trim(),
              'role': _selectedRole,
              'createdAt': FieldValue.serverTimestamp(),
            });

        await createdUser.sendEmailVerification();
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'تم إنشاء الحساب. تحقق من بريدك الإلكتروني، ثم سجّل الدخول.',
            ),
          ),
        );
      } on FirebaseAuthException catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        String message = 'حدث خطأ أثناء إنشاء الحساب';
        if (e.code == 'email-already-in-use') {
          message = 'البريد الإلكتروني مستخدم مسبقاً لحساب آخر.';
        } else if (e.code == 'weak-password') {
          message = 'كلمة المرور ضعيفة جداً.';
        } else if (e.message != null) {
          message = e.message!;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الاتصال: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final headerHeight = size.height * 0.30;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FA),
      body: Column(
        children: [
          TopographicWaveHeaderWidget(
            height: headerHeight,
            clipType: WaveClipType.signIn,
            overlayChild: SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      const LanguageSwitchButton(foregroundColor: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF315F73),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 36,
                      height: 3.5,
                      decoration: BoxDecoration(
                        color: const Color(0xFF315F73),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'الاسم الكامل أو اسم المحل',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF87969D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      decoration: _inputDecoration(
                        'أدخل اسمك أو اسم محلك التجاري',
                        Icons.person_outline,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? translateAppText('الرجاء إدخال الاسم')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'رقم الهاتف',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF87969D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: _inputDecoration(
                        'أدخل رقم هاتفك',
                        Icons.phone_outlined,
                      ),
                      validator: (val) => val == null || val.trim().isEmpty
                          ? translateAppText('الرجاء إدخال رقم الهاتف')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'البريد الإلكتروني',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF87969D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: _inputDecoration(
                        'demo@email.com',
                        Icons.email_outlined,
                      ),
                      validator: (val) => val == null || !val.contains('@')
                          ? translateAppText('بريد إلكتروني غير صالح')
                          : null,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'كلمة المرور',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF87969D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          size: 20,
                          color: Color(0xFF315F73),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: const Color(0xFF9AAAB1),
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _isPasswordVisible = !_isPasswordVisible,
                          ),
                        ),
                        hintText: translateAppText('أدخل كلمة مرور قوية'),
                        hintStyle: const TextStyle(
                          color: Color(0xFF9AAAB1),
                          fontSize: 14,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8EEF0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF315F73),
                            width: 1.5,
                          ),
                        ),
                      ),
                      validator: (val) => val == null || val.length < 6
                          ? translateAppText(
                              'كلمة المرور يجب أن تكون 6 أحرف على الأقل',
                            )
                          : null,
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'نوع الحساب',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF87969D),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedRole,
                      decoration: _inputDecoration('', Icons.badge_outlined),
                      items: const [
                        DropdownMenuItem(
                          value: 'shop_owner',
                          child: Text('صاحب محل هواتف / موثق عقود'),
                        ),
                        DropdownMenuItem(
                          value: 'user',
                          child: Text('مستخدم عادي / فرد'),
                        ),
                      ],
                      onChanged: (val) =>
                          setState(() => _selectedRole = val ?? 'shop_owner'),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF315F73),
                          foregroundColor: Colors.white,
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Sign Up',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFF315F73)),
      hintText: translateAppText(hint),
      hintStyle: const TextStyle(color: Color(0xFF9AAAB1), fontSize: 14),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE8EEF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF315F73), width: 1.5),
      ),
    );
  }
}
