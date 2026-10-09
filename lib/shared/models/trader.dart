enum TraderRole {
  exporter('مصدّر'),
  importer('مستورد'),
  both('مصدّر ومستورد');

  const TraderRole(this.label);
  final String label;

  bool get canExport => this != importer;
  bool get canImport => this != exporter;
}

enum BusinessType {
  individual('مؤسسة فردية'),
  company('شركة');

  const BusinessType(this.label);
  final String label;
}

enum VerificationStatus {
  pending('قيد التحقق'),
  verified('موثّق'),
  rejected('مرفوض');

  const VerificationStatus(this.label);
  final String label;
}

/// A document reference. Only the file name is kept in memory — never the file contents —
/// so no identity documents end up in logs or demo data.
class UploadedDocument {
  const UploadedDocument({required this.type, required this.fileName, required this.uploadedAt});
  final String type;
  final String fileName;
  final DateTime uploadedAt;
}

class Trader {
  Trader({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.companyName,
    required this.role,
    required this.businessType,
    required this.city,
    required this.commercialRegNo,
    this.establishmentNationalNo,
    this.chamberMembershipNo,
    this.status = VerificationStatus.pending,
    this.documents = const [],
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  final String id;
  String fullName;
  final String email;
  String phone;
  String companyName;
  TraderRole role;
  final BusinessType businessType;
  String city;
  final String commercialRegNo;
  final String? establishmentNationalNo;
  final String? chamberMembershipNo;
  VerificationStatus status;
  final List<UploadedDocument> documents;
  final DateTime joinedAt;

  String get initials => fullName.trim().isEmpty ? '؟' : fullName.trim().substring(0, 1);
}
