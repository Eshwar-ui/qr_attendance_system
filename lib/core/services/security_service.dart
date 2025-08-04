import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

enum QRValidationResult {
  valid,
  tooEarly,
  tooLate,
  invalid,
}

class SecurityService {
  static final SecurityService _instance = SecurityService._internal();
  factory SecurityService() => _instance;
  SecurityService._internal();

  // Generate secure QR code with expiration and validation
  String generateSecureQRCode({
    required String classId,
    required DateTime expiry,
    required String facultyId,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final expiryTimestamp = expiry.millisecondsSinceEpoch;
    
    final data = {
      'classId': classId,
      'facultyId': facultyId,
      'timestamp': timestamp,
      'expiry': expiryTimestamp,
      'nonce': _generateNonce(),
    };
    
    final jsonData = json.encode(data);
    final signature = _generateSignature(jsonData);
    
    return base64Encode(utf8.encode('$jsonData|$signature'));
  }

  // Validate QR code security and time-based validity
  Map<String, dynamic>? validateQRCode(String qrData) {
    try {
      final decoded = utf8.decode(base64Decode(qrData));
      final parts = decoded.split('|');
      
      if (parts.length != 2) return null;
      
      final jsonData = parts[0];
      final signature = parts[1];
      
      // Verify signature
      if (!_verifySignature(jsonData, signature)) return null;
      
      final data = json.decode(jsonData) as Map<String, dynamic>;
      
      // Check expiry
      final expiry = DateTime.fromMillisecondsSinceEpoch(data['expiry']);
      if (DateTime.now().isAfter(expiry)) return null;
      
      return data;
    } catch (e) {
      return null;
    }
  }

  // Check if QR code is within valid attendance marking window (10 minutes from class start)
  QRValidationResult validateAttendanceWindow(String classId, DateTime classStartTime) {
    final now = DateTime.now();
    final validWindow = classStartTime.add(const Duration(minutes: 10));
    
    if (now.isBefore(classStartTime)) {
      // Class hasn't started yet
      return QRValidationResult.tooEarly;
    } else if (now.isAfter(validWindow)) {
      // More than 10 minutes after class started
      return QRValidationResult.tooLate;
    } else {
      // Within valid window
      return QRValidationResult.valid;
    }
  }

  String _generateNonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  String _generateSignature(String data) {
    // In production, use a proper secret key from environment
    const secretKey = 'your-secret-key-here';
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final digest = hmac.convert(utf8.encode(data));
    return digest.toString();
  }

  bool _verifySignature(String data, String signature) {
    return _generateSignature(data) == signature;
  }

  // Input validation
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  bool isValidRollNumber(String rollNumber) {
    return RegExp(r'^[A-Z0-9]{6,12}$').hasMatch(rollNumber.toUpperCase());
  }

  bool isValidPhone(String phone) {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(phone);
  }

  // Sanitize input to prevent injection attacks
  String sanitizeInput(String input) {
    return input
        .replaceAll(RegExp(r'[<>"\]'), '')
        .replaceAll(RegExp(r'[&]'), '&amp;')
        .trim();
  }
}
