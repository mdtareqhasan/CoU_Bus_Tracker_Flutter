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
  static final _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static Future<IdCardValidationResult> validateIdCard(File imageFile, {String role = 'student'}) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      final text = recognizedText.text;

      if (text.trim().isEmpty) {
        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'ছবি থেকে কোনো তথ্য পড়া যায়নি। আইডি কার্ড বা ভর্তির ফর্মের ছবি দিন।',
          rawText: '',
        );
      }

      final lowerText = text.toLowerCase();

      // STRICT: Must find "Comilla University" or "Cumilla University"
      final hasUniversity = lowerText.contains('comilla university') ||
          lowerText.contains('cumilla university') ||
          lowerText.contains('কুমিল্লা বিশ্ববিদ্যালয়') ||
          lowerText.contains('কমিলা বিশ্ববিদ্যালয়');

      if (!hasUniversity) {
        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড বা ভর্তির ফর্ম মনে হচ্ছে না।',
          rawText: text,
        );
      }

      // University found - now detect type
      if (role == 'teacher') {
        final isTeacherCard = lowerText.contains('employee id') ||
            lowerText.contains('employee no') ||
            lowerText.contains('designation') ||
            lowerText.contains('lecturer') ||
            lowerText.contains('professor');

        if (isTeacherCard) {
          return IdCardValidationResult(
            isValid: true,
            extractedDepartment: _extractDepartment(text),
            extractedDesignation: _extractDesignation(text),
            extractedEmployeeId: _extractEmployeeId(text),
            documentType: 'teacher_id_card',
            rawText: text,
          );
        }

        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'শিক্ষক আইডি কার্ড সনাক্ত হয়নি।',
          rawText: '',
        );
      }

      // Student
      final isIdCard = lowerText.contains('roll no') ||
          lowerText.contains('blood group');

      final isRegistrationForm = lowerText.contains('registration') ||
          lowerText.contains('father') ||
          lowerText.contains('mother');

      String docType = 'unknown';
      if (isIdCard) docType = 'id_card';
      else if (isRegistrationForm) docType = 'registration_form';

      return IdCardValidationResult(
        isValid: true,
        extractedRollNumber: _extractRollNumber(text),
        extractedSession: _extractSession(text),
        extractedDepartment: _extractDepartment(text),
        documentType: docType,
        rawText: text,
      );

    } catch (e) {
      return const IdCardValidationResult(
        isValid: false,
        errorMessage: 'ছবি প্রক্রিয়াকরণে সমস্যা হয়েছে।',
        rawText: '',
      );
    }
  }

  static String? _extractRollNumber(String text) {
    for (final line in text.split('\n')) {
      final lowerLine = line.toLowerCase().trim();
      if (lowerLine.contains('roll no')) {
        final match = RegExp(r'roll\s*no\.?\s*:?\s*(\d+)').firstMatch(lowerLine);
        if (match != null) return match.group(1);
      }
    }
    final allNumbers = RegExp(r'\b(\d{7,8})\b').allMatches(text);
    if (allNumbers.isNotEmpty) return allNumbers.first.group(1);
    return null;
  }

  static String? _extractSession(String text) {
    final match = RegExp(
      r'session\s*:?\s*(\d{4}[-–]\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1);
  }

  static String? _extractDepartment(String text) {
    final knownDepartments = [
      'CSE', 'EEE', 'ECE', 'BBA', 'MBA', 'LLB',
      'Economics', 'English', 'Bangla', 'Mathematics', 'Physics',
      'Chemistry', 'Sociology', 'Computer Science and Engineering',
    ];

    final match = RegExp(
      r'(?:dept|department)\s*:?\s*([A-Za-z\s]+)',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final dept = match.group(1)!.trim();
      for (final known in knownDepartments) {
        if (dept.toUpperCase().contains(known.toUpperCase())) return known;
      }
    }

    for (final dept in knownDepartments) {
      if (text.toUpperCase().contains(dept.toUpperCase())) return dept;
    }
    return null;
  }

  static String? _extractDesignation(String text) {
    final designations = [
      'Professor', 'Associate Professor', 'Assistant Professor',
      'Lecturer', 'Senior Lecturer',
    ];
    for (final desig in designations) {
      if (text.toLowerCase().contains(desig.toLowerCase())) return desig;
    }
    return null;
  }

  static String? _extractEmployeeId(String text) {
    final match = RegExp(
      r'employee\s*(?:id|no)\s*:?\s*(\d+)',
      caseSensitive: false,
    ).firstMatch(text);
    return match?.group(1);
  }

  static void dispose() {
    _textRecognizer.close();
  }
}
