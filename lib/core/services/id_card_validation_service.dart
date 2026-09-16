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
  static bool _tessdataReady = false;

  static Future<void> _ensureTessdata() async {
    if (_tessdataReady) return;
    try {
      final data = await rootBundle.load('assets/tessdata/ben.traineddata');
      final bytes = data.buffer.asUint8List();
      final tessdataPath = await getTessdataPath();
      final file = File('$tessdataPath/ben.traineddata');
      if (!await file.exists()) {
        await file.writeAsBytes(bytes);
      }
      _tessdataReady = true;
    } catch (e) {
      _tessdataReady = false;
    }
  }

  static Future<IdCardValidationResult> validateIdCard(File imageFile, {String role = 'student'}) async {
    await _ensureTessdata();

    String latinText = '';
    String banglaText = '';

    // Run ML Kit for English text
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final result = await _latinRecognizer.processImage(inputImage);
      latinText = result.text;
    } catch (_) {}

    // Run Tesseract for Bangla text
    if (_tessdataReady) {
      try {
        banglaText = await FlutterTesseractOcr.extractText(
          imageFile.path,
          language: 'ben',
        );
      } catch (_) {}
    }

    final combinedText = '$latinText\n$banglaText';

    // Check for university markers in both texts
    final hasUniversity = _hasUniversityMarker(combinedText.toLowerCase());

    // If no university marker found → REJECT
    if (!hasUniversity) {
      return const IdCardValidationResult(
        isValid: false,
        errorMessage: 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড বা ভর্তির ফর্ম মনে হচ্ছে না।',
        rawText: '',
      );
    }

    // University marker found → detect document type
    final docType = _detectDocumentType(combinedText, role);

    if (role == 'teacher' && docType != 'teacher_id_card') {
      return const IdCardValidationResult(
        isValid: false,
        errorMessage: 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের শিক্ষক আইডি কার্ড মনে হচ্ছে না।',
        rawText: combinedText,
      );
    }

    // Accept student ID card, registration form, or unknown with university marker
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
      documentType: docType ?? 'unknown',
      rawText: combinedText,
    );
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

    if (role == 'teacher') {
      if (lowerText.contains('identity card') ||
          lowerText.contains('employee id') ||
          lowerText.contains('employee no') ||
          lowerText.contains('designation') ||
          lowerText.contains('lecturer') ||
          lowerText.contains('professor') ||
          lowerText.contains('employee')) {
        return 'teacher_id_card';
      }
      return null;
    }

    if (lowerText.contains('id card') ||
        lowerText.contains('identity card') ||
        lowerText.contains('roll no') ||
        lowerText.contains('roll no.') ||
        lowerText.contains('blood group') ||
        lowerText.contains('provost')) {
      return 'id_card';
    }

    if (lowerText.contains('registration form') ||
        lowerText.contains('রেজিস্ট্রেশন ফর্ম') ||
        lowerText.contains('registration') ||
        lowerText.contains('রেজিস্ট্রেশন') ||
        lowerText.contains('ভর্তি') ||
        lowerText.contains('father') ||
        lowerText.contains('mother') ||
        lowerText.contains('পিতা') ||
        lowerText.contains('মাতা') ||
        lowerText.contains('dept') ||
        lowerText.contains('বিভাগ') ||
        lowerText.contains('session') ||
        lowerText.contains('শিক্ষাবর্ষ')) {
      return 'registration_form';
    }

    return 'unknown';
  }

  static String? _extractRollNumber(String text) {
    final banglaMatch = RegExp(r'রেজিস্ট্রেশন/আইডি\s*নম্বর[:\s]*(\d{7,8})').firstMatch(text);
    if (banglaMatch != null) return banglaMatch.group(1);

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
    final banglaMatch = RegExp(r'শিক্ষাবর্ষ\s*(\d{4}[-–]\d{4})').firstMatch(text);
    if (banglaMatch != null) return banglaMatch.group(1);

    final match = RegExp(
      r'session\s*:?\s*(\d{4}[-–]\d{2,4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) return match.group(1);

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

    final banglaMatch = RegExp(r'বিভাগ[:\s]*([A-Za-z\s]+)').firstMatch(text);
    if (banglaMatch != null) {
      final dept = banglaMatch.group(1)!.trim();
      for (final known in knownDepartments) {
        if (dept.toUpperCase().contains(known.toUpperCase())) return known;
      }
      return dept;
    }

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
    _latinRecognizer.close();
  }
}
