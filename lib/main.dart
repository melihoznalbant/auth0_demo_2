import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart' as local_auth_package;
import 'package:auth0_flutter/auth0_flutter.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face ID Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FaceIdAuthScreen(),
    );
  }
}

class FaceIdAuthScreen extends StatefulWidget {
  @override
  _FaceIdAuthScreenState createState() => _FaceIdAuthScreenState();
}

class _FaceIdAuthScreenState extends State<FaceIdAuthScreen> with WidgetsBindingObserver {
  final local_auth_package.LocalAuthentication auth = local_auth_package.LocalAuthentication();
  bool _isAuthenticating = false;
  String _authToken = '';
  String _errorMessage = '';
  bool _isAppInForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    setState(() {
      _isAppInForeground = state == AppLifecycleState.resumed;
    });
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _errorMessage = '';
      });
      authenticated = await auth.authenticate(
        localizedReason: 'Please authenticate to get token',
        options: const local_auth_package.AuthenticationOptions(
          biometricOnly: true,
        ),
      );
      setState(() {
        _isAuthenticating = false;
      });
    } catch (e) {
      setState(() {
        _isAuthenticating = false;
        _errorMessage = 'Error during authentication: $e';
      });
    }

    if (authenticated) {
      _getAuthToken();
    }
  }

  Future<void> _getAuthToken() async {
    if (!_isAppInForeground) {
      setState(() {
        _errorMessage = 'App is not in foreground';
      });
      return;
    }

    final auth0 = Auth0(
      'dev-72zrfykv3lzqt1a6.eu.auth0.com',
      'vjhMTfICs0n1LM3JegaAF0HaYfHhqS9v',
    );

    try {
      final result = await auth0.webAuthentication().login(
        audience: 'https://dev-72zrfykv3lzqt1a6.eu.auth0.com/api/v2/',
        scopes: {'openid', 'profile', 'email', 'offline_access'},
      );

      setState(() {
        _authToken = result.accessToken!;
      });
    } catch (e) {
      setState(() {
        _authToken = '';
        _errorMessage = 'Failed to get token: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face ID Auth'),
      ),
      body: Center(
        child: _isAuthenticating
            ? CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: _authenticate,
                    child: Text('Authenticate with Face ID'),
                  ),
                  SizedBox(height: 20),
                  if (_authToken.isNotEmpty) Text('Token: $_authToken'),
                  if (_errorMessage.isNotEmpty) Text('Error: $_errorMessage'),
                ],
              ),
      ),
    );
  }
}
