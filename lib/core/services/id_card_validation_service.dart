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
          errorMessage: 'ছবি থেকে কোনো তথ্য পড়া যায়নি। আইডি কার্ডের ছবি দিন।',
          rawText: '',
        );
      }

      final lowerText = text.toLowerCase();

      // STRICT: Must find "Comilla University" in English
      final hasUniversity = lowerText.contains('comilla university') ||
          lowerText.contains('cumilla university') ||
          lowerText.contains('comilla uni');

      if (!hasUniversity) {
        return IdCardValidationResult(
          isValid: false,
          errorMessage: 'এটি কুমিল্লা বিশ্ববিদ্যালয়ের আইডি কার্ড মনে হচ্ছে না।',
          rawText: text,
        );
      }

      // TEACHER validation
      if (role == 'teacher') {
        // Teacher ID card must have employee id AND (designation OR lecturer/professor)
        final hasEmployeeId = lowerText.contains('employee id') ||
            lowerText.contains('employee no') ||
            lowerText.contains('employee id :') ||
            lowerText.contains('employee id:') ||
            RegExp(r'employee\s*id\s*:\s*\d+').hasMatch(lowerText);

        final hasDesignation = lowerText.contains('designation') ||
            lowerText.contains('lecturer') ||
            lowerText.contains('professor') ||
            lowerText.contains('associate professor') ||
            lowerText.contains('assistant professor');

        // Reject if it's a student ID card (has roll no)
        final isStudentCard = lowerText.contains('roll no') ||
            lowerText.contains('roll no.');

        if (isStudentCard && !hasEmployeeId) {
          return const IdCardValidationResult(
            isValid: false,
            errorMessage: 'এটি শিক্ষার্থীর আইডি কার্ড। শিক্ষক আইডি কার্ড দিন।',
            rawText: '',
          );
        }

        if (hasEmployeeId && hasDesignation) {
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
          errorMessage: 'শিক্ষক আইডি কার্ড সনাক্ত হয়নি। শিক্ষক পরিচয়পত্রের ছবি দিন।',
          rawText: '',
        );
      }

      // STUDENT validation - ONLY accept ID card
      // Student ID card markers: roll no, blood group, id no, session with (Hon's)
      final hasRollNo = lowerText.contains('roll no') ||
          lowerText.contains('roll no.');
      final hasBloodGroup = lowerText.contains('blood gr') ||
          lowerText.contains('blood group');
      final hasIdNo = lowerText.contains('id no') ||
          lowerText.contains('id no.');
      final hasHonors = lowerText.contains("hon's") ||
          lowerText.contains('hons');

      // Count how many ID card markers are found
      int idCardMarkers = 0;
      if (hasRollNo) idCardMarkers++;
      if (hasBloodGroup) idCardMarkers++;
      if (hasIdNo) idCardMarkers++;
      if (hasHonors) idCardMarkers++;

      // Need at least 2 markers to confirm it's a student ID card
      if (idCardMarkers >= 2) {
        return IdCardValidationResult(
          isValid: true,
          extractedRollNumber: _extractRollNumber(text),
          extractedSession: _extractSession(text),
          extractedDepartment: _extractDepartment(text),
          documentType: 'id_card',
          rawText: text,
        );
      }

      // Reject - not a student ID card
      return const IdCardValidationResult(
        isValid: false,
        errorMessage: 'শুধুমাত্র আইডি কার্ড গ্রহণযোগ্য। ভর্তির ফর্ম বা অন্যান্য ছবি দেওয়া যাবে না।',
        rawText: '',
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
