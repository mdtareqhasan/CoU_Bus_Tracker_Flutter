import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class IdCardValidationResult {
  final bool isValid;
  final String? extractedRollNumber;
  final String? extractedSession;
  final String? extractedDepartment;
  final String? extractedDesignation;
  final String? extractedEmployeeId;
  final String? documentType;
  final String? errorMessage;
  final String rawText;

  const IdCardValidationResult({
    required this.isValid,
    this.extractedRollNumber,
    this.extractedSession,
    this.extractedDepartment,
    this.extractedDesignation,
    this.extractedEmployeeId,
    this.documentType,
    this.errorMessage,
    required this.rawText,
  });
}

class IdCardValidationService {
  static final _latinRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static Future<IdCardValidationResult> validateIdCard(File imageFile, {String role = 'student'}) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);

      // Use Latin script - it recognizes English text on Bangla documents
      final recognizedText = await _latinRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      if (text.trim().isEmpty) {
        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'ছবি থেকে কোনো তথ্য পড়া যায়নি। আবার চেষ্টা করুন।',
          rawText: '',
        );
      }

      final docType = _detectDocumentType(text, role);

      if (docType == null) {
        return IdCardValidationResult(
          isValid: false,
          errorMessage: role == 'teacher'
              ? 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের শিক্ষক আইডি কার্ড মনে হচ্ছে না।'
              : 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড বা ভর্তির ফর্ম মনে হচ্ছে না।',
          rawText: text,
        );
      }

      if (docType == 'teacher_id_card') {
        return IdCardValidationResult(
          isValid: true,
          extractedDepartment: _extractDepartment(text),
          extractedDesignation: _extractDesignation(text),
          extractedEmployeeId: _extractEmployeeId(text),
          documentType: docType,
          rawText: text,
        );
      }

      return IdCardValidationResult(
        isValid: true,
        extractedRollNumber: _extractRollNumber(text),
        extractedSession: _extractSession(text),
        extractedDepartment: _extractDepartment(text),
        documentType: docType,
        rawText: text,
      );
    } catch (e) {
      return IdCardValidationResult(
        isValid: false,
        errorMessage: 'ছবি প্রক্রিয়াকরণে সমস্যা হয়েছে। আবার চেষ্টা করুন।',
        rawText: '',
      );
    }
  }

  static bool _hasUniversityMarker(String lowerText) {
    return lowerText.contains('comilla university') ||
        lowerText.contains('কুমিল্লা বিশ্ববিদ্যালয়') ||
        lowerText.contains('কমিলা বিশ্ববিদ্যালয়') ||
        lowerText.contains('comilla uni') ||
        lowerText.contains('কুমিল্লা') ||
        lowerText.contains('কমিলা') ||
        lowerText.contains('cou') ||
        lowerText.contains('cumilla') ||
        lowerText.contains('কুমিল্লা বিশ্ব');
  }

  static String? _detectDocumentType(String text, String role) {
    final lowerText = text.toLowerCase();

    if (!_hasUniversityMarker(lowerText)) return null;

    if (role == 'teacher') {
      final isTeacherCard = lowerText.contains('identity card') ||
          lowerText.contains('employee id') ||
          lowerText.contains('employee no') ||
          lowerText.contains('designation') ||
          lowerText.contains('lecturer') ||
          lowerText.contains('professor') ||
          lowerText.contains('employee');
      if (isTeacherCard) return 'teacher_id_card';
      return null;
    }

    // Check for ID card markers
    final isIdCard = lowerText.contains('id card') ||
        lowerText.contains('identity card') ||
        lowerText.contains('non resident') ||
        lowerText.contains('resident') ||
        lowerText.contains('roll no') ||
        lowerText.contains('roll no.') ||
        lowerText.contains('blood gr') ||
        lowerText.contains('blood group') ||
        lowerText.contains('provost');

    if (isIdCard) return 'id_card';

    // Check for registration form markers (English + Bangla patterns)
    final isRegistrationForm = lowerText.contains('registration form') ||
        lowerText.contains('registration') ||
        lowerText.contains('রেজিস্ট্রেশন') ||
        lowerText.contains('ভর্তি') ||
        lowerText.contains('admission') ||
        lowerText.contains('student name') ||
        lowerText.contains('father') ||
        lowerText.contains('mother') ||
        lowerText.contains('guardian') ||
        lowerText.contains('date of birth') ||
        lowerText.contains('blood group') ||
        lowerText.contains('nationality') ||
        lowerText.contains('religion') ||
        lowerText.contains('marital') ||
        lowerText.contains('dept') ||
        lowerText.contains('session');

    if (isRegistrationForm) return 'registration_form';

    // If university marker found but no specific markers, still accept
    // Check if there's a 7-8 digit number (typical roll/registration number)
    final hasNumber = RegExp(r'\b\d{7,8}\b').hasMatch(text);
    if (hasNumber) return 'registration_form';

    return 'unknown';
  }

  static String? _extractRollNumber(String text) {
    final lines = text.split('\n');

    for (final line in lines) {
      final lowerLine = line.toLowerCase().trim();

      if (lowerLine.contains('roll no')) {
        final match = RegExp(r'roll\s*no\.?\s*:?\s*(\d+)').firstMatch(lowerLine);
        if (match != null) return match.group(1);
      }

      if (lowerLine.contains('রোল') || lowerLine.contains('roll')) {
        final match = RegExp(r'(\d{7,8})').firstMatch(line);
        if (match != null) return match.group(1);
      }

      if (lowerLine.contains('রেজিস্ট্রেশন') || lowerLine.contains('registration')) {
        final match = RegExp(r'(\d{7,8})').firstMatch(line);
        if (match != null) return match.group(1);
      }
    }

    final allNumbers = RegExp(r'\b(\d{7,8})\b').allMatches(text);
    if (allNumbers.isNotEmpty) {
      return allNumbers.first.group(1);
    }

    return null;
  }

  static String? _extractSession(String text) {
    final sessionMatch = RegExp(
      r'session\s*:?\s*(\d{4}[-–]\d{2,4}(?:\s*\([^)]*\))?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (sessionMatch != null) {
      var session = sessionMatch.group(1)!;
      final yearMatch = RegExp(r'(\d{4}[-–]\d{2,4})').firstMatch(session);
      return yearMatch != null ? yearMatch.group(1) : session;
    }

    final banglaSessionMatch = RegExp(
      r'শিক্ষাবর্ষ\s*(\d{4}[-–]\d{4})',
    ).firstMatch(text);
    if (banglaSessionMatch != null) {
      return banglaSessionMatch.group(1);
    }

    final looseMatch = RegExp(
      r"(\d{4}[-–]\d{2}(?:\s*\(hon'?s?\))?)",
      caseSensitive: false,
    ).firstMatch(text);
    if (looseMatch != null) {
      var session = looseMatch.group(1)!;
      final yearMatch = RegExp(r'(\d{4}[-–]\d{2})').firstMatch(session);
      return yearMatch != null ? yearMatch.group(1) : session;
    }

    return null;
  }

  static String? _extractDepartment(String text) {
    final knownDepartments = [
      'CSE', 'EEE', 'ECE', 'BBA', 'MBA', 'LLB', 'LLM',
      'Economics', 'English', 'Bangla', 'Mathematics', 'Physics',
      'Chemistry', 'Botany', 'Zoology', 'Sociology', 'Political Science',
      'Public Administration', 'Social Work', 'Education',
      'Information Technology', 'IT', 'Computer Science and Engineering',
    ];

    final deptMatch = RegExp(
      r'(?:dept|department|বিভাগ)\s*:?\s*([A-Za-z\s]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (deptMatch != null) {
      final dept = deptMatch.group(1)!.trim();
      for (final known in knownDepartments) {
        if (dept.toUpperCase().contains(known.toUpperCase())) {
          return known;
        }
      }
      return dept;
    }

    for (final dept in knownDepartments) {
      if (text.toUpperCase().contains(dept.toUpperCase())) {
        return dept;
      }
    }

    return null;
  }

  static String? _extractDesignation(String text) {
    final designations = [
      'Professor', 'Associate Professor', 'Assistant Professor',
      'Lecturer', 'Senior Lecturer', 'Adjunct Professor',
      'Visiting Professor', 'Professor Emeritus',
    ];

    final desigMatch = RegExp(
      r'designation\s*:?\s*([A-Za-z\s]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (desigMatch != null) {
      final desig = desigMatch.group(1)!.trim();
      for (final known in designations) {
        if (desig.toUpperCase().contains(known.toUpperCase())) {
          return known;
        }
      }
      return desig;
    }

    for (final desig in designations) {
      if (text.toLowerCase().contains(desig.toLowerCase())) {
        return desig;
      }
    }

    return null;
  }

  static String? _extractEmployeeId(String text) {
    final match = RegExp(
      r'employee\s*(?:id|no)\s*:?\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) return match.group(1);
    return null;
  }

  static void dispose() {
    _latinRecognizer.close();
  }
}
