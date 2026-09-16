import 'dart:io';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';

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
  static bool _tessdataInitialized = false;

  /// Ensures the Bangla trained data is available for Tesseract.
  static Future<void> _initTessdata() async {
    if (_tessdataInitialized) return;

    try {
      final data = await rootBundle.load('assets/tessdata/ben.traineddata');
      final bytes = data.buffer.asUint8List();
      final dir = await getTessdataPath();
      final file = File('$dir/ben.traineddata');
      if (!await file.exists()) {
        await file.writeAsBytes(bytes);
      }
      _tessdataInitialized = true;
    } catch (e) {
      // Tesseract Bangla not available, will use Latin only
      _tessdataInitialized = false;
    }
  }

  static Future<IdCardValidationResult> validateIdCard(File imageFile, {String role = 'student'}) async {
    try {
      // Ensure Tesseract Bangla data is ready
      await _initTessdata();

      final inputImage = InputImage.fromFile(imageFile);

      // Run ML Kit for English text
      final latinResult = await _latinRecognizer.processImage(inputImage);
      final latinText = latinResult.text;

      // Run Tesseract for Bangla text
      String banglaText = '';
      if (_tessdataInitialized) {
        try {
          banglaText = await FlutterTesseractOcr.extractText(
            imageFile.path,
            language: 'ben',
          );
        } catch (_) {
          // Tesseract failed, continue with Latin only
        }
      }

      // Combine both texts
      final combinedText = '$latinText\n$banglaText';

      if (combinedText.trim().isEmpty) {
        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'ছবি থেকে কোনো তথ্য পড়া যায়নি। আবার চেষ্টা করুন।',
          rawText: '',
        );
      }

      final docType = _detectDocumentType(combinedText, role);

      if (docType == null) {
        return IdCardValidationResult(
          isValid: false,
          errorMessage: role == 'teacher'
              ? 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের শিক্ষক আইডি কার্ড মনে হচ্ছে না।'
              : 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড বা ভর্তির ফর্ম মনে হচ্ছে না।',
          rawText: combinedText,
        );
      }

      if (docType == 'teacher_id_card') {
        return IdCardValidationResult(
          isValid: true,
          extractedDepartment: _extractDepartment(combinedText),
          extractedDesignation: _extractDesignation(combinedText),
          extractedEmployeeId: _extractEmployeeId(combinedText),
          documentType: docType,
          rawText: combinedText,
        );
      }

      return IdCardValidationResult(
        isValid: true,
        extractedRollNumber: _extractRollNumber(combinedText),
        extractedSession: _extractSession(combinedText),
        extractedDepartment: _extractDepartment(combinedText),
        documentType: docType,
        rawText: combinedText,
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
        lowerText.contains('cumilla');
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

    // Check for registration form markers (English + Bangla)
    final isRegistrationForm = lowerText.contains('registration form') ||
        lowerText.contains('রেজিস্ট্রেশন ফর্ম') ||
        lowerText.contains('registration') ||
        lowerText.contains('রেজিস্ট্রেশন') ||
        lowerText.contains('ভর্তির ফর্ম') ||
        lowerText.contains('ভর্তি ফর্ম') ||
        lowerText.contains('admission') ||
        lowerText.contains('father') ||
        lowerText.contains('mother') ||
        lowerText.contains('guardian') ||
        lowerText.contains('পিতা') ||
        lowerText.contains('মাতা') ||
        lowerText.contains('date of birth') ||
        lowerText.contains('nationality') ||
        lowerText.contains('religion') ||
        lowerText.contains('dept') ||
        lowerText.contains('বিভাগ') ||
        lowerText.contains('session') ||
        lowerText.contains('শিক্ষাবর্ষ');

    if (isRegistrationForm) return 'registration_form';

    // Fallback: if university marker found and has 7-8 digit number
    final hasNumber = RegExp(r'\b\d{7,8}\b').hasMatch(text);
    if (hasNumber) return 'registration_form';

    return 'unknown';
  }

  static String? _extractRollNumber(String text) {
    // Try Bangla pattern first: "রেজিস্ট্রেশন/আইডি নম্বর: 12608015"
    final banglaMatch = RegExp(r'রেজিস্ট্রেশন/আইডি\s*নম্বর[:\s]*(\d{7,8})').firstMatch(text);
    if (banglaMatch != null) return banglaMatch.group(1);

    // Try English pattern: "Roll No: 12208055"
    final lines = text.split('\n');
    for (final line in lines) {
      final lowerLine = line.toLowerCase().trim();

      if (lowerLine.contains('roll no')) {
        final match = RegExp(r'roll\s*no\.?\s*:?\s*(\d+)').firstMatch(lowerLine);
        if (match != null) return match.group(1);
      }
    }

    // Fallback: look for 7-8 digit numbers
    final allNumbers = RegExp(r'\b(\d{7,8})\b').allMatches(text);
    if (allNumbers.isNotEmpty) {
      return allNumbers.first.group(1);
    }

    return null;
  }

  static String? _extractSession(String text) {
    // Try Bangla pattern: "শিক্ষাবর্ষ 2025-2026"
    final banglaMatch = RegExp(r'শিক্ষাবর্ষ\s*(\d{4}[-–]\d{4})').firstMatch(text);
    if (banglaMatch != null) return banglaMatch.group(1);

    // Try English pattern: "Session: 2021-22"
    final sessionMatch = RegExp(
      r'session\s*:?\s*(\d{4}[-–]\d{2,4}(?:\s*\([^)]*\))?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (sessionMatch != null) {
      var session = sessionMatch.group(1)!;
      final yearMatch = RegExp(r'(\d{4}[-–]\d{2,4})').firstMatch(session);
      return yearMatch != null ? yearMatch.group(1) : session;
    }

    // Try "Session 2025-2026" without colon
    final looseMatch = RegExp(
      r'session\s+(\d{4}[-–]\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (looseMatch != null) return looseMatch.group(1);

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

    // Try Bangla pattern: "বিভাগ: CSE"
    final banglaMatch = RegExp(r'বিভাগ[:\s]*([A-Za-z\s]+)').firstMatch(text);
    if (banglaMatch != null) {
      final dept = banglaMatch.group(1)!.trim();
      for (final known in knownDepartments) {
        if (dept.toUpperCase().contains(known.toUpperCase())) {
          return known;
        }
      }
      return dept;
    }

    // Try English pattern: "Dept: CSE" or "Department: Computer Science"
    final deptMatch = RegExp(
      r'(?:dept|department)\s*:?\s*([A-Za-z\s]+)',
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

    // Check for department codes directly
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

    // Try Bangla pattern: "পদবি: Lecturer"
    final banglaMatch = RegExp(r'পদবি[:\s]*([A-Za-z\s]+)').firstMatch(text);
    if (banglaMatch != null) {
      final desig = banglaMatch.group(1)!.trim();
      for (final known in designations) {
        if (desig.toUpperCase().contains(known.toUpperCase())) {
          return known;
        }
      }
      return desig;
    }

    // Try English pattern
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
