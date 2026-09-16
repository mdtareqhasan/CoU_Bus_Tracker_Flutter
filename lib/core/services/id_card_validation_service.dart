import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of ID card validation
class IdCardValidationResult {
  final bool isValid;
  final String? extractedRollNumber;
  final String? extractedSession;
  final String? extractedDepartment;
  final String? documentType; // 'id_card' or 'registration_form'
  final String? errorMessage;
  final String rawText;

  const IdCardValidationResult({
    required this.isValid,
    this.extractedRollNumber,
    this.extractedSession,
    this.extractedDepartment,
    this.documentType,
    this.errorMessage,
    required this.rawText,
  });
}

/// Service for validating student ID cards and registration forms
/// using Google ML Kit Text Recognition.
class IdCardValidationService {
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Validates an uploaded image and extracts key fields.
  /// Returns an [IdCardValidationResult] with extracted data.
  static Future<IdCardValidationResult> validateIdCard(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      if (text.isEmpty) {
        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'ছবি থেকে কোনো তথ্য পড়া যায়নি। আবার চেষ্টা করুন।',
          rawText: '',
        );
      }

      // Detect document type
      final docType = _detectDocumentType(text);

      if (docType == null) {
        return IdCardValidationResult(
          isValid: false,
          errorMessage: 'এটি কমিলা বিশ্ববিদ্যালয়ের আইডি কার্ড বা ভর্তির ফর্ম মনে হচ্ছে না।',
          rawText: text,
        );
      }

      // Extract fields based on document type
      final rollNumber = _extractRollNumber(text);
      final session = _extractSession(text);
      final department = _extractDepartment(text);

      return IdCardValidationResult(
        isValid: true,
        extractedRollNumber: rollNumber,
        extractedSession: session,
        extractedDepartment: department,
        documentType: docType,
        rawText: text,
      );
    } catch (e) {
      return IdCardValidationResult(
        isValid: false,
        errorMessage: 'ছবি প্রক্রিয়াকরণে সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        rawText: '',
      );
    } finally {
      // Don't close the recognizer as it may be reused
    }
  }

  /// Detects the document type based on extracted text.
  /// Returns 'id_card', 'registration_form', or null.
  static String? _detectDocumentType(String text) {
    final lowerText = text.toLowerCase();

    // Check for Comilla University markers
    final hasUniversity = lowerText.contains('comilla university') ||
        lowerText.contains('কমিলা বিশ্ববিদ্যালয়') ||
        lowerText.contains('comilla uni') ||
        lowerText.contains('cou');

    if (!hasUniversity) return null;

    // Check for ID card markers
    final isIdCard = lowerText.contains('id card') ||
        lowerText.contains('identity card') ||
        lowerText.contains('non resident') ||
        lowerText.contains('resident') ||
        lowerText.contains('roll no') ||
        lowerText.contains('roll no.') ||
        lowerText.contains('blood gr') ||
        lowerText.contains('provost');

    // Check for registration form markers
    final isRegistrationForm = lowerText.contains('registration form') ||
        lowerText.contains('রেজিস্ট্রেশন ফর্ম') ||
        lowerText.contains('ভর্তির ফর্ম') ||
        lowerText.contains('admission') ||
        lowerText.contains('শিক্ষার্থীর নাম') ||
        lowerText.contains('student name') ||
        lowerText.contains('মাতার নাম') ||
        lowerText.contains('পিতার নাম') ||
        lowerText.contains('অনুদান');

    if (isIdCard) return 'id_card';
    if (isRegistrationForm) return 'registration_form';

    // If university name found but no specific markers, still accept
    return 'unknown';
  }

  /// Extracts roll number from the text.
  static String? _extractRollNumber(String text) {
    final lines = text.split('\n');

    for (final line in lines) {
      final lowerLine = line.toLowerCase().trim();

      // Pattern: "Roll No: 12208055" or "Roll No. 12208055"
      if (lowerLine.contains('roll no')) {
        final match = RegExp(r'roll\s*no\.?\s*:?\s*(\d+)').firstMatch(lowerLine);
        if (match != null) return match.group(1);
      }

      // Pattern: "রোল নম্বর: 12208055"
      if (lowerLine.contains('রোল') || lowerLine.contains('roll')) {
        final match = RegExp(r'(\d{7,8})').firstMatch(line);
        if (match != null) return match.group(1);
      }

      // Pattern: Registration/ID number in registration form
      // "রেজিস্ট্রেশন/আইডি নম্বর: 12608015"
      if (lowerLine.contains('রেজিস্ট্রেশন') || lowerLine.contains('registration')) {
        final match = RegExp(r'(\d{7,8})').firstMatch(line);
        if (match != null) return match.group(1);
      }
    }

    // Fallback: look for 7-8 digit numbers (typical roll numbers)
    final allNumbers = RegExp(r'\b(\d{7,8})\b').allMatches(text);
    if (allNumbers.isNotEmpty) {
      return allNumbers.first.group(1);
    }

    return null;
  }

  /// Extracts session from the text.
  static String? _extractSession(String text) {
    // Pattern: "Session: 2021-22" or "Session: 2021-22(Hon's)"
    final sessionMatch = RegExp(
      r'session\s*:?\s*(\d{4}[-–]\d{2,4}(?:\s*\([^)]*\))?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (sessionMatch != null) {
      // Clean up the session string
      var session = sessionMatch.group(1)!;
      // Extract just the year range part
      final yearMatch = RegExp(r'(\d{4}[-–]\d{2,4})').firstMatch(session);
      return yearMatch != null ? yearMatch.group(1) : session;
    }

    // Pattern: "শিক্ষাবর্ষ 2025-2026" or "শিক্ষাবর্ষ ২০২৫-২০২৬"
    final banglaSessionMatch = RegExp(
      r'শিক্ষাবর্ষ\s*(\d{4}[-–]\d{4})',
    ).firstMatch(text);
    if (banglaSessionMatch != null) {
      return banglaSessionMatch.group(1);
    }

    // Pattern: "2021-22(Hon's)" without "Session:" prefix
    final looseMatch = RegExp(
      r'(\d{4}[-–]\d{2}(?:\s*\(hon\'?s?\))?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (looseMatch != null) {
      var session = looseMatch.group(1)!;
      final yearMatch = RegExp(r'(\d{4}[-–]\d{2})').firstMatch(session);
      return yearMatch != null ? yearMatch.group(1) : session;
    }

    return null;
  }

  /// Extracts department from the text.
  static String? _extractDepartment(String text) {
    final knownDepartments = [
      'CSE', 'EEE', 'ECE', 'BBA', 'MBA', 'LLB', 'LLM',
      'Economics', 'English', 'Bangla', 'Mathematics', 'Physics',
      'Chemistry', 'Botany', 'Zoology', 'Sociology', 'Political Science',
      'Public Administration', 'Social Work', 'Education',
      'Information Technology', 'IT',
    ];

    // Pattern: "Dept: CSE" or "Department: Computer Science"
    final deptMatch = RegExp(
      r'(?:dept|department|বিভাগ)\s*:?\s*([A-Za-z\s]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (deptMatch != null) {
      final dept = deptMatch.group(1)!.trim();
      // Check against known departments
      for (final known in knownDepartments) {
        if (dept.toUpperCase().contains(known.toUpperCase())) {
          return known;
        }
      }
      return dept;
    }

    // Check for department codes directly
    for (final dept in knownDepartments) {
      if (text.toUpperCase().contains(dept.toUpperCase())) {
        return dept;
      }
    }

    return null;
  }

  /// Disposes the text recognizer when done.
  static void dispose() {
    _textRecognizer.close();
  }
}
