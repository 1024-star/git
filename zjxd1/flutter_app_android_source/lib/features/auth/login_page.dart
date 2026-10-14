import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_api_client.dart';
import '../home/cartoon_fitness_home_page.dart';
import '../../utils/app_logger.dart';
import '../../utils/user_scope.dart';

// Clear AI assistant data constants
const String _aiAssistantWelcomeKey = 'ai_assistant_has_seen_welcome';
const String _aiAssistantChatKey = 'ai_assistant_chat_history';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _captchaEnabled = false;
  bool _registerEnabled = true;
  bool _showRegisterForm = false;

  bool _passwordObscured = true;
  bool _registerPasswordObscured = true;
  bool _registerConfirmPasswordObscured = true;

  bool _submitting = false;

  // Registration form controllers
  final _registerUsernameController = TextEditingController();
  final _registerPasswordController = TextEditingController();
  final _registerConfirmPasswordController = TextEditingController();
  final _registerFormKey = GlobalKey<FormState>();

  late final AuthApiClient _authApi;

  late final AnimationController _floatController;
  late final Animation<double> _floatA;
  late final Animation<double> _floatB;
  late final Animation<double> _floatC;

  int _logoClickCount = 0;
  Timer? _logoClickTimer;

  @override
  void initState() {
    super.initState();
    _authApi = AuthApiClient();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    _floatA = Tween<double>(begin: 0, end: -20).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatB = Tween<double>(begin: 0, end: 16).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    _floatC = Tween<double>(begin: 0, end: -12).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoClickTimer?.cancel();
    _floatController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _captchaController.dispose();
    _registerUsernameController.dispose();
    _registerPasswordController.dispose();
    _registerConfirmPasswordController.dispose();
    super.dispose();
  }

  void _handleLogoClick() {
    setState(() {
      _logoClickCount++;
    });

    _logoClickTimer?.cancel();
    _logoClickTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) return;
      setState(() {
        _logoClickCount = 0;
      });
    });

    if (_logoClickCount >= 5) {
      _logoClickTimer?.cancel();
      setState(() {
        _logoClickCount = 0;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已触发配置入口')),
      );
    }
  }

  void _gotoConfigConsole() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('跳转配置控制台')),
    );
  }

  void _handleUserRegister() {
    setState(() {
      _showRegisterForm = true;
    });
  }

  void _handlePrivacy() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('隐私协议')),
    );
  }

  void _handleUserAgreement() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('用户协议')),
    );
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (_submitting) return;
    setState(() => _submitting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('登录中...')),
    );

    try {
      final username = _usernameController.text.trim();
      final password = _passwordController.text;

      if (username == 'lzf' && password == '123456') {
        UserScope.setUser(username: username, isDemo: true);
        if (!mounted) return;

        // Clear AI assistant and hip bridge training data on login so each login starts fresh
        SharedPreferences.getInstance().then((prefs) {
          prefs.remove(_aiAssistantWelcomeKey);
          prefs.remove(_aiAssistantChatKey);
          prefs.remove('hip_bridge_has_result');
          prefs.remove('hip_bridge_result_data');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已进入离线账号：lzf')),
        );

        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!mounted) return;

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const CartoonFitnessHomePage()),
        );
        return;
      }

      final resp = await _authApi.login(
        username: username,
        password: password,
      );
      if (!mounted) return;

      UserScope.setUser(
        username: resp.user.username,
        nickname: resp.user.nickname,
        avatar: resp.user.avatar,
        token: resp.token,
        expiresAtMs: resp.expiresAtMs,
      );

      // Clear AI assistant and hip bridge training data on login so each login starts fresh
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(_aiAssistantWelcomeKey);
        prefs.remove(_aiAssistantChatKey);
        prefs.remove('hip_bridge_has_result');
        prefs.remove('hip_bridge_result_data');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录成功：$username')),
      );

      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CartoonFitnessHomePage()),
      );
    } on AuthApiException catch (e, st) {
      AppLogger.e('登录', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, st) {
      AppLogger.e('登录', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络异常，请稍后再试')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _handleRegister() async {
    if (!(_registerFormKey.currentState?.validate() ?? false)) return;

    if (_submitting) return;
    setState(() => _submitting = true);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('注册中...')),
    );

    try {
      final username = _registerUsernameController.text.trim();
      final password = _registerPasswordController.text;

      // 后端 /register 直接返回登录态，无需再调一次 /login
      final resp = await _authApi.register(
        username: username,
        password: password,
      );
      if (!mounted) return;

      UserScope.setUser(
        username: resp.user.username,
        nickname: resp.user.nickname,
        avatar: resp.user.avatar,
        token: resp.token,
        expiresAtMs: resp.expiresAtMs,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('注册成功，正在登录...')),
      );

      await Future<void>.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;

      // Clear AI assistant and hip bridge training data on login so each login starts fresh
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove(_aiAssistantWelcomeKey);
        prefs.remove(_aiAssistantChatKey);
        prefs.remove('hip_bridge_has_result');
        prefs.remove('hip_bridge_result_data');
      });

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const CartoonFitnessHomePage()),
      );
    } on AuthApiException catch (e, st) {
      AppLogger.e('登录', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e, st) {
      AppLogger.e('登录', e, st);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('网络异常，请稍后再试')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _backToLogin() {
    setState(() {
      _showRegisterForm = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _floatController,
              builder: (context, _) {
                return Stack(
                  children: [
                    Positioned(
                      top: -size.width * 0.35,
                      right: -size.width * 0.35,
                      child: Transform.translate(
                        offset: Offset(0, _floatA.value),
                        child: _BgCircle(
                          diameter: size.width * 1.05,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x33ABDCFF),
                              Color(0x330396FF),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -size.width * 0.22,
                      left: -size.width * 0.22,
                      child: Transform.translate(
                        offset: Offset(0, _floatB.value),
                        child: _BgCircle(
                          diameter: size.width * 0.70,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x3300E4A7),
                              Color(0x3302D9A5),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: size.height * 0.40,
                      left: size.width * 0.60,
                      child: Transform.translate(
                        offset: Offset(0, _floatC.value),
                        child: _BgCircle(
                          diameter: size.width * 0.52,
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0x33FF6B6B),
                              Color(0x33FF6B6B),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: size.height - MediaQuery.paddingOf(context).vertical),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.06),
                    _BrandHeader(
                      onTitleTap: _handleLogoClick,
                      onSloganTap: _gotoConfigConsole,
                    ),
                    const SizedBox(height: 36),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final formWidth = (constraints.maxWidth * 0.95).clamp(335.0, 425.0);
                        return Center(
                          child: SizedBox(
                            width: formWidth,
                            child: _showRegisterForm
                                ? Form(
                                    key: _registerFormKey,
                                    child: Column(
                                      children: [
                                        _InputItem(
                                          icon: Icons.person_outline,
                                          controller: _registerUsernameController,
                                          hintText: '用户名',
                                          obscureText: false,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return '请输入用户名';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 18),
                                        _InputItem(
                                          icon: Icons.lock_outline,
                                          controller: _registerPasswordController,
                                          hintText: '密码',
                                          obscureText: _registerPasswordObscured,
                                          trailing: IconButton(
                                            onPressed: () => setState(() => _registerPasswordObscured = !_registerPasswordObscured),
                                            icon: Icon(
                                              _registerPasswordObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                              size: 22,
                                              color: const Color(0xFF9CA3AF),
                                            ),
                                            splashRadius: 20,
                                            tooltip: _registerPasswordObscured ? '显示密码' : '隐藏密码',
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return '请输入密码';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 18),
                                        _InputItem(
                                          icon: Icons.lock_outline,
                                          controller: _registerConfirmPasswordController,
                                          hintText: '确认密码',
                                          obscureText: _registerConfirmPasswordObscured,
                                          trailing: IconButton(
                                            onPressed: () => setState(() => _registerConfirmPasswordObscured = !_registerConfirmPasswordObscured),
                                            icon: Icon(
                                              _registerConfirmPasswordObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                              size: 22,
                                              color: const Color(0xFF9CA3AF),
                                            ),
                                            splashRadius: 20,
                                            tooltip: _registerConfirmPasswordObscured ? '显示密码' : '隐藏密码',
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return '请确认密码';
                                            if (v != _registerPasswordController.text) return '两次密码输入不一致';
                                            return null;
                                          },
                                        ),
                                        if (_captchaEnabled) ...[
                                          const SizedBox(height: 20),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: SizedBox(
                                              width: formWidth * 0.78,
                                              child: _InputItem(
                                                icon: Icons.qr_code_2,
                                                controller: _captchaController,
                                                hintText: '验证码',
                                                obscureText: false,
                                                validator: (v) => null,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 38),
                                        _GradientButton(
                                          text: _submitting ? '请稍候...' : '注册',
                                          onTap: _handleRegister,
                                        ),
                                        const SizedBox(height: 16),
                                        GestureDetector(
                                          onTap: _backToLogin,
                                          child: Text(
                                            '返回登录',
                                            style: const TextStyle(
                                              color: Color(0xFF3B82F6),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 18),
                                        _AgreementRow(
                                          onUserAgreementTap: _handleUserAgreement,
                                          onPrivacyTap: _handlePrivacy,
                                        ),
                                      ],
                                    ),
                                  )
                                : Form(
                                    key: _formKey,
                                    child: Column(
                                      children: [
                                        _InputItem(
                                          icon: Icons.person_outline,
                                          controller: _usernameController,
                                          hintText: '用户名',
                                          obscureText: false,
                                          validator: (v) {
                                            if (v == null || v.trim().isEmpty) return '请输入用户名';
                                            return null;
                                          },
                                        ),
                                        const SizedBox(height: 18),
                                        _InputItem(
                                          icon: Icons.lock_outline,
                                          controller: _passwordController,
                                          hintText: '密码',
                                          obscureText: _passwordObscured,
                                          trailing: IconButton(
                                            onPressed: () => setState(() => _passwordObscured = !_passwordObscured),
                                            icon: Icon(
                                              _passwordObscured ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                              size: 22,
                                              color: const Color(0xFF9CA3AF),
                                            ),
                                            splashRadius: 20,
                                            tooltip: _passwordObscured ? '显示密码' : '隐藏密码',
                                          ),
                                          validator: (v) {
                                            if (v == null || v.isEmpty) return '请输入密码';
                                            return null;
                                          },
                                        ),
                                        if (_captchaEnabled) ...[
                                          const SizedBox(height: 20),
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: SizedBox(
                                              width: formWidth * 0.78,
                                              child: _InputItem(
                                                icon: Icons.qr_code_2,
                                                controller: _captchaController,
                                                hintText: '验证码',
                                                obscureText: false,
                                                validator: (v) => null,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 38),
                                        _GradientButton(
                                          text: _submitting ? '请稍候...' : '登录',
                                          onTap: _handleLogin,
                                        ),
                                        if (_registerEnabled) ...[
                                          const SizedBox(height: 16),
                                          _RegisterRow(onRegisterTap: _handleUserRegister),
                                        ],
                                        const SizedBox(height: 18),
                                        _AgreementRow(
                                          onUserAgreementTap: _handleUserAgreement,
                                          onPrivacyTap: _handlePrivacy,
                                        ),
                                      ],
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _captchaEnabled = !_captchaEnabled),
                          child: Text(_captchaEnabled ? '关闭验证码' : '启用验证码'),
                        ),
                        TextButton(
                          onPressed: () => setState(() => _registerEnabled = !_registerEnabled),
                          child: Text(_registerEnabled ? '账号注册' : '返回登录'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
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

class _BgCircle extends StatelessWidget {
  const _BgCircle({required this.diameter, required this.gradient});

  final double diameter;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: gradient,
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onTitleTap, required this.onSloganTap});

  final VoidCallback onTitleTap;
  final VoidCallback onSloganTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.cover,
            errorBuilder: (context, _, __) {
              return Container(
                color: const Color(0xFFF5F6F7),
                alignment: Alignment.center,
                child: const Icon(Icons.image_not_supported_outlined, color: Colors.grey),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: onTitleTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
            child: Text(
              '正脊行动',
              key: const Key('login_title'),
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
                color: const Color(0xFF111827),
                fontSize: (theme.textTheme.headlineSmall?.fontSize ?? 28) ,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: onSloganTap,
          child: Text(
            '正脊行动,健康未来',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF6B7280),
              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) + 2,
            ),
          ),
        ),
      ],
    );
  }
}

class _InputItem extends StatelessWidget {
  const _InputItem({
    required this.icon,
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.validator,
    this.trailing,
  });

  final IconData icon;
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final FormFieldValidator<String> validator;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18),
      alignment: Alignment.center,
      child: Row(
        children: [
          Icon(icon, size: 25, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              maxLength: 20,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF111827)),
              decoration: InputDecoration(
                counterText: '',
                hintText: hintText,
                hintStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500, color: Color(0xFF9CA3AF)),
                border: InputBorder.none,
              ),
              validator: validator,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.text, required this.onTap});

  final String text;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 69,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF00E4A7),
              Color(0xFF0396FF),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E4A7).withValues(alpha: 0.22),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => onTap(),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            text,
            key: const Key('login_button'),
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterRow extends StatelessWidget {
  const _RegisterRow({required this.onRegisterTap});

  final VoidCallback onRegisterTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '没有账号？',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: const Color(0xFF9CA3AF),
            fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) + 3,
          ),
        ),
        const SizedBox(width: 6),
        GestureDetector(
          onTap: onRegisterTap,
          child: Text(
            '立即注册',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF3B82F6),
              fontWeight: FontWeight.w600,
              fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) + 3,
            ),
          ),
        ),
      ],
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({required this.onUserAgreementTap, required this.onPrivacyTap});

  final VoidCallback onUserAgreementTap;
  final VoidCallback onPrivacyTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: const Color(0xFF374151),
      fontSize: (Theme.of(context).textTheme.bodySmall?.fontSize ?? 12) + 3,
    );
    final linkStyle = baseStyle?.copyWith(
      color: const Color(0xFF3B82F6),
      fontWeight: FontWeight.w600,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle,
        children: [
          const TextSpan(text: '登录即代表同意 '),
          TextSpan(
            text: '《用户协议》',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onUserAgreementTap,
          ),
          const TextSpan(text: ' '),
          TextSpan(
            text: '《隐私协议》',
            style: linkStyle,
            recognizer: TapGestureRecognizer()..onTap = onPrivacyTap,
          ),
        ],
      ),
    );
  }
}
