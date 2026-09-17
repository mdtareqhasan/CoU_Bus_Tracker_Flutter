import 'dart:io';
import 'package:flutter/foundation.dart';
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

      debugPrint('=== ID CARD VALIDATION ===');
      debugPrint('Role: $role');
      debugPrint('OCR text: $text');

      if (text.trim().isEmpty) {
        debugPrint('FAIL: Empty text');
        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'ছবি থেকে কোনো তথ্য পড়া যায়নি। আইডি কার্ডের ছবি দিন।',
          rawText: '',
        );
      }

      final lowerText = text.toLowerCase();

      final hasUniversity = lowerText.contains('comilla university') ||
          lowerText.contains('cumilla university') ||
          lowerText.contains('comilla uni');

      debugPrint('Has university: $hasUniversity');

      if (!hasUniversity) {
        debugPrint('FAIL: No Comilla University found');
        return IdCardValidationResult(
          isValid: false,
          errorMessage: 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড মনে হচ্ছে না।',
          rawText: text,
        );
      }

      if (role == 'teacher') {
        final hasEmployeeId = lowerText.contains('employee id') ||
            lowerText.contains('employee no') ||
            RegExp(r'employee\s*id\s*:\s*\d+').hasMatch(lowerText) ||
            RegExp(r'employee\s*i\.d\.?\s*:?\s*\d+').hasMatch(lowerText);

        final hasDesignation = lowerText.contains('designation') ||
            lowerText.contains('lecturer') ||
            lowerText.contains('professor') ||
            lowerText.contains('associate professor') ||
            lowerText.contains('assistant professor');

        final hasStudentOnlyMarkers = lowerText.contains('roll no') ||
            lowerText.contains('roll no.');

        debugPrint('Teacher: hasEmployeeId=$hasEmployeeId, hasDesignation=$hasDesignation, hasStudentOnly=$hasStudentOnlyMarkers');

        if (hasStudentOnlyMarkers) {
          debugPrint('FAIL: Student card for teacher');
          return IdCardValidationResult(
            isValid: false,
            errorMessage: 'এটি শিক্ষার্থীর আইডি কার্ড। শিক্ষক আইডি কার্ড দিন।',
            rawText: text,
          );
        }

        if (hasEmployeeId && hasDesignation) {
          debugPrint('PASS: Teacher ID card');
          return IdCardValidationResult(
            isValid: true,
            extractedDepartment: _extractDepartment(text),
            extractedDesignation: _extractDesignation(text),
            extractedEmployeeId: _extractEmployeeId(text),
            documentType: 'teacher_id_card',
            rawText: text,
          );
        }

        debugPrint('FAIL: Not teacher ID card');
        return const IdCardValidationResult(
          isValid: false,
          errorMessage: 'শিক্ষক আইডি কার্ড সনাক্ত হয়নি। শিক্ষক পরিচয়পত্রের ছবি দিন।',
          rawText: '',
        );
      }

      // STUDENT - ONLY ID card accepted
      final hasRollNo = lowerText.contains('roll no') || lowerText.contains('roll no.');
      final hasBloodGroup = lowerText.contains('blood gr') || lowerText.contains('blood group');
      final hasIdNo = lowerText.contains('id no') || lowerText.contains('id no.');
      final hasHonors = lowerText.contains("hon's") || lowerText.contains('hons');

      debugPrint('Student: hasRollNo=$hasRollNo, hasBloodGroup=$hasBloodGroup, hasIdNo=$hasIdNo, hasHonors=$hasHonors');

      int markers = 0;
      if (hasRollNo) markers++;
      if (hasBloodGroup) markers++;
      if (hasIdNo) markers++;
      if (hasHonors) markers++;

      debugPrint('Student markers count: $markers');

      if (markers >= 2) {
        debugPrint('PASS: Student ID card');
        return IdCardValidationResult(
          isValid: true,
          extractedRollNumber: _extractRollNumber(text),
          extractedSession: _extractSession(text),
          extractedDepartment: _extractDepartment(text),
          documentType: 'id_card',
          rawText: text,
        );
      }

      debugPrint('FAIL: Not a student ID card');
      return const IdCardValidationResult(
        isValid: false,
        errorMessage: 'শুধুমাত্র আইডি কার্ড গ্রহণযোগ্য। ভর্তির ফর্ম বা অন্যান্য ছবি দেওয়া যাবে না।',
        rawText: '',
      );

    } catch (e) {
      debugPrint('VALIDATION ERROR: $e');
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
