import '../../l10n/generated/app_localizations.dart';

/// One department/office in the bundled label table.
///
/// The registration pickers are filled from the public `/api/academic/units`
/// endpoint and submit row ids; this table only maps a *stored* value (the
/// Bengali name, byte-identical to what earlier app versions sent) to a
/// localized label — for already-saved profiles, and for the completion
/// form's locked field while the fetched list is still in flight. An
/// English-locale user sees "Mathematics" while the database keeps 'গণিত', so
/// existing rows and admin tooling never see a difference.
class AcademicOption {
  const AcademicOption(this.value, this.label);

  final String value;
  final String Function(AppLocalizations l10n) label;
}

final List<AcademicOption> departmentOptions = [
  AcademicOption('কম্পিউটার সায়েন্স অ্যান্ড ইঞ্জিনিয়ারিং (CSE)',
      (l10n) => l10n.deptCse),
  AcademicOption('গণিত', (l10n) => l10n.deptMathematics),
  AcademicOption('পদার্থবিজ্ঞান', (l10n) => l10n.deptPhysics),
  AcademicOption('পরিসংখ্যান', (l10n) => l10n.deptStatistics),
  AcademicOption('রসায়ন', (l10n) => l10n.deptChemistry),
  AcademicOption('ফার্মেসি', (l10n) => l10n.deptPharmacy),
  AcademicOption('ইংরেজি', (l10n) => l10n.deptEnglish),
  AcademicOption('বাংলা', (l10n) => l10n.deptBangla),
  AcademicOption('অর্থনীতি', (l10n) => l10n.deptEconomics),
  AcademicOption('লোক প্রশাসন', (l10n) => l10n.deptPublicAdministration),
  AcademicOption('নৃবিজ্ঞান', (l10n) => l10n.deptAnthropology),
  AcademicOption('গণযোগাযোগ ও সাংবাদিকতা', (l10n) => l10n.deptMassCommunication),
  AcademicOption('প্রত্নতত্ত্ব', (l10n) => l10n.deptArchaeology),
  AcademicOption('ব্যবস্থাপনা শিক্ষা', (l10n) => l10n.deptManagement),
  AcademicOption('অ্যাকাউন্টিং অ্যান্ড ইনফরমেশন সিস্টেমস',
      (l10n) => l10n.deptAccounting),
  AcademicOption('মার্কেটিং', (l10n) => l10n.deptMarketing),
  AcademicOption('ফাইন্যান্স অ্যান্ড ব্যাংকিং', (l10n) => l10n.deptFinance),
  AcademicOption('ইনফরমেশন অ্যান্ড কমিউনিকেশন টেকনোলজি (ICT)',
      (l10n) => l10n.deptIct),
  AcademicOption('আইন', (l10n) => l10n.deptLaw),
];

final List<AcademicOption> officeOptions = [
  AcademicOption('উপাচার্যের কার্যালয়', (l10n) => l10n.officeVc),
  AcademicOption('উপ-উপাচার্যের কার্যালয়', (l10n) => l10n.officeProVc),
  AcademicOption('কোষাধ্যক্ষের কার্যালয়', (l10n) => l10n.officeTreasurer),
  AcademicOption('রেজিস্ট্রারের কার্যালয়', (l10n) => l10n.officeRegistrar),
  AcademicOption('প্রক্টরের কার্যালয়', (l10n) => l10n.officeProctor),
  AcademicOption('গবেষণা ও সম্প্রসারণ পরিচালকের কার্যালয়',
      (l10n) => l10n.officeResearchExtension),
  AcademicOption('এস্টেট শাখা', (l10n) => l10n.officeEstate),
  AcademicOption('নিরাপত্তা শাখা', (l10n) => l10n.officeSecurity),
  AcademicOption('কেন্দ্রীয় স্টোর', (l10n) => l10n.officeCentralStore),
  AcademicOption('অর্থ ও হিসাব পরিচালকের কার্যালয়',
      (l10n) => l10n.officeFinanceAccounts),
  AcademicOption('পরীক্ষা নিয়ন্ত্রকের কার্যালয়', (l10n) => l10n.officeExaminations),
  AcademicOption('পরিকল্পনা ও উন্নয়ন পরিচালকের কার্যালয়',
      (l10n) => l10n.officePlanningDevelopment),
  AcademicOption('কেন্দ্রীয় গ্রন্থাগার', (l10n) => l10n.officeLibrary),
  AcademicOption('প্রকৌশল কার্যালয়', (l10n) => l10n.officeEngineering),
  AcademicOption('মেডিকেল সেন্টার', (l10n) => l10n.officeMedical),
  AcademicOption('আইসিটি সেল', (l10n) => l10n.officeIctCell),
  AcademicOption('শারীরিক শিক্ষা কার্যালয়', (l10n) => l10n.officePhysicalEducation),
  AcademicOption('জনসংযোগ কার্যালয়', (l10n) => l10n.officePublicRelations),
  AcademicOption('কেন্দ্রীয় মসজিদ', (l10n) => l10n.officeCentralMosque),
  AcademicOption('পরিবহন পুল', (l10n) => l10n.officeTransportPool),
  AcademicOption('শিক্ষার্থী কাউন্সেলিং ও গাইডেন্স', (l10n) => l10n.officeCounseling),
  AcademicOption('আন্তর্জাতিক সম্পর্ক', (l10n) => l10n.officeInternationalRelations),
  AcademicOption('ক্যারিয়ার ডেভেলপমেন্ট সেন্টার',
      (l10n) => l10n.officeCareerDevelopment),
];

final List<AcademicOption> teacherDepartmentOptions = [
  ...departmentOptions,
  ...officeOptions,
];

/// The localized label for a stored department/office value. A value that
/// isn't a known option (e.g. set directly by an admin) is shown as-is.
String departmentLabelFor(String value, AppLocalizations l10n) {
  for (final option in teacherDepartmentOptions) {
    if (option.value == value) return option.label(l10n);
  }
  return value;
}
