import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:io';
import '../app_theme.dart';

class SocialAccountsPage extends StatefulWidget {
  const SocialAccountsPage({super.key});

  @override
  State<SocialAccountsPage> createState() => _SocialAccountsPageState();
}

class _SocialAccountsPageState extends State<SocialAccountsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final String _currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';

  bool _googleLinked = false;
  bool _facebookLinked = false;
  bool _twitterLinked = false;
  bool _appleLinked = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLinkedAccounts();
  }

  Future<void> _loadLinkedAccounts() async {
    try {
      final doc = await _db.collection('users').doc(_currentUserId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final providerData = _auth.currentUser?.providerData ?? [];

        setState(() {
          _googleLinked = providerData.any((p) => p.providerId == 'google.com');
          _facebookLinked =
              providerData.any((p) => p.providerId == 'facebook.com');
          _twitterLinked =
              providerData.any((p) => p.providerId == 'twitter.com');
          _appleLinked = providerData.any((p) => p.providerId == 'apple.com');
        });
      }
    } catch (e) {
      debugPrint('Error loading linked accounts: $e');
    }
  }

  Future<void> _linkGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.currentUser?.linkWithCredential(credential);

      setState(() {
        _googleLinked = true;
        _isLoading = false;
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط حساب Google بنجاح'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل ربط حساب Google: $e')),
        );
      }
    }
  }

  Future<void> _unlinkGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.unlink('google.com');
      await _googleSignIn.signOut();

      setState(() {
        _googleLinked = false;
        _isLoading = false;
      });

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فك ربط حساب Google'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل فك ربط حساب Google: $e')),
        );
      }
    }
  }

  Future<void> _linkFacebook() async {
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();
      if (result.status == LoginStatus.success) {
        final AccessToken? accessToken = result.accessToken;
        if (accessToken != null) {
          final credential = FacebookAuthProvider.credential(accessToken.token);
          await _auth.currentUser?.linkWithCredential(credential);
        }

        setState(() {
          _facebookLinked = true;
          _isLoading = false;
        });

        if (mounted) {
          HapticFeedback.mediumImpact();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم ربط حساب Facebook بنجاح'),
              backgroundColor: AppTheme.royalGold,
            ),
          );
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل ربط حساب Facebook: $e')),
        );
      }
    }
  }

  Future<void> _unlinkFacebook() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.unlink('facebook.com');
      await FacebookAuth.instance.logOut();

      setState(() {
        _facebookLinked = false;
        _isLoading = false;
      });

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فك ربط حساب Facebook'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل فك ربط حساب Facebook: $e')),
        );
      }
    }
  }

  Future<void> _linkTwitter() async {
    setState(() => _isLoading = true);
    try {
      final twitterLogin = TwitterLogin(
        apiKey: dotenv.env['TWITTER_API_KEY'] ??
            "2058550979801288704-TtRVNWoQtvZ8yEZUKRZNQrldxbJjpQ",
        apiSecretKey: dotenv.env['TWITTER_API_SECRET_KEY'] ??
            "qAf6BLUNMCfKvNpOljVyVn6oTfSvncNlOWxNNw1ZlPUsz",
        redirectURI: dotenv.env['TWITTER_REDIRECT_URI'] ?? "royaldoor://",
      );

      final authResult = await twitterLogin.login();
      switch (authResult.status) {
        case TwitterLoginStatus.loggedIn:
          if (authResult.authToken != null &&
              authResult.authTokenSecret != null) {
            final credential = TwitterAuthProvider.credential(
              accessToken: authResult.authToken!,
              secret: authResult.authTokenSecret!,
            );
            await _auth.currentUser?.linkWithCredential(credential);
          }

          setState(() {
            _twitterLinked = true;
            _isLoading = false;
          });

          if (mounted) {
            HapticFeedback.mediumImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('تم ربط حساب Twitter بنجاح'),
                backgroundColor: AppTheme.royalGold,
              ),
            );
          }
          break;
        case TwitterLoginStatus.cancelledByUser:
          setState(() => _isLoading = false);
          break;
        case TwitterLoginStatus.error:
          setState(() => _isLoading = false);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content:
                      Text('فشل ربط حساب Twitter: ${authResult.errorMessage}')),
            );
          }
          break;
        default:
          setState(() => _isLoading = false);
          break;
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل ربط حساب Twitter: $e')),
        );
      }
    }
  }

  Future<void> _unlinkTwitter() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.unlink('twitter.com');

      setState(() {
        _twitterLinked = false;
        _isLoading = false;
      });

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فك ربط حساب Twitter'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل فك ربط حساب Twitter: $e')),
        );
      }
    }
  }

  Future<void> _linkApple() async {
    setState(() => _isLoading = true);
    try {
      if (!Platform.isIOS && !Platform.isMacOS) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Apple Sign-In متاح فقط على أجهزة Apple')),
          );
        }
        return;
      }

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      await _auth.currentUser?.linkWithCredential(oauthCredential);

      setState(() {
        _appleLinked = true;
        _isLoading = false;
      });

      if (mounted) {
        HapticFeedback.mediumImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم ربط حساب Apple بنجاح'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل ربط حساب Apple: $e')),
        );
      }
    }
  }

  Future<void> _unlinkApple() async {
    setState(() => _isLoading = true);
    try {
      await _auth.currentUser?.unlink('apple.com');

      setState(() {
        _appleLinked = false;
        _isLoading = false;
      });

      if (mounted) {
        HapticFeedback.lightImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم فك ربط حساب Apple'),
            backgroundColor: AppTheme.royalGold,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل فك ربط حساب Apple: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A12),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E293B),
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'ربط الحسابات الاجتماعية',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20)
              .copyWith(bottom: MediaQuery.of(context).padding.bottom + 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // معلومات
              _buildInfoCard(
                icon: Icons.info_outline,
                title: 'معلومات مهمة',
                content:
                    'ربط حساباتك الاجتماعية يسهل تسجيل الدخول ويزيد أمان حسابك.',
              ),
              const SizedBox(height: 30),

              // Google
              _buildSocialCard(
                icon: Icons.g_mobiledata,
                title: 'Google',
                subtitle: 'ربط حساب Google',
                color: Colors.red,
                isLinked: _googleLinked,
                onLink: _linkGoogle,
                onUnlink: _unlinkGoogle,
              ),
              const SizedBox(height: 15),

              // Facebook
              _buildSocialCard(
                icon: Icons.facebook,
                title: 'Facebook',
                subtitle: 'ربط حساب Facebook',
                color: Colors.blue,
                isLinked: _facebookLinked,
                onLink: _linkFacebook,
                onUnlink: _unlinkFacebook,
              ),
              const SizedBox(height: 15),

              // Twitter
              _buildSocialCard(
                icon: Icons.flutter_dash,
                title: 'Twitter / X',
                subtitle: 'ربط حساب Twitter',
                color: Colors.lightBlue,
                isLinked: _twitterLinked,
                onLink: _linkTwitter,
                onUnlink: _unlinkTwitter,
              ),
              const SizedBox(height: 15),

              // Apple
              _buildSocialCard(
                icon: Icons.apple,
                title: 'Apple',
                subtitle: 'ربط حساب Apple',
                color: Colors.grey,
                isLinked: _appleLinked,
                onLink: _linkApple,
                onUnlink: _unlinkApple,
              ),
              const SizedBox(height: 30),

              // معلومات إضافية
              _buildInfoCard(
                icon: Icons.security,
                title: 'الأمان',
                content:
                    'يمكنك استخدام الحسابات المرتبطة لتسجيل الدخول بدلاً من كلمة المرور.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isLinked,
    required VoidCallback onLink,
    required VoidCallback onUnlink,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                if (isLinked) const SizedBox(height: 4),
                if (isLinked)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.green.withValues(alpha: 0.5)),
                    ),
                    child: const Text(
                      'مرتبط',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_isLoading)
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppTheme.royalGold,
              ),
            )
          else
            ElevatedButton(
              onPressed: isLinked ? onUnlink : onLink,
              style: ElevatedButton.styleFrom(
                backgroundColor: isLinked ? Colors.red : color,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: Text(
                isLinked ? 'فك الربط' : 'ربط',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.blue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.blue,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
