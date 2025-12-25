import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Load environment variables
    await dotenv.load(fileName: ".env");
    
    // Debug: Print loaded env variables (remove in production)
    print('✅ Environment loaded successfully');
    print('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
    print('PUSHER_APP_KEY: ${dotenv.env['PUSHER_APP_KEY']}');
    print('PUSHER_CLUSTER: ${dotenv.env['PUSHER_CLUSTER']}');
    
  } catch (e) {
    print('❌ Error loading .env file: $e');
  }
  
  runApp(const MyApp());
}