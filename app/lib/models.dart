enum WorkMode { remote, hybrid, onsite, unknown }

enum JobStatus {
  saved,
  analyzed,
  eligible,
  almostEligible,
  notEligible,
  applied,
  interview,
  offer,
  rejected,
  archived,
}

enum SupportValue { provided, notProvided, mentioned, notMentioned, unclear }

enum EligibilityDecision { eligible, almostEligible, notEligible, unclear }

enum CredentialType {
  language,
  programming,
  cloud,
  university,
  bootcamp,
  other,
}

enum TrustLevel { high, medium, low, unverified }

T _enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  return values.where((item) => item.name == name).firstOrNull ?? fallback;
}

DateTime _date(Object? value) =>
    DateTime.tryParse(value?.toString() ?? '') ?? DateTime.now();
DateTime? _nullableDate(Object? value) =>
    value == null || value == '' ? null : DateTime.tryParse(value.toString());
List<String> _stringList(Object? value) =>
    value is List ? value.map((item) => item.toString()).toList() : const [];

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.currentCountry,
    required this.citizenship,
    required this.targetRole,
    required this.experienceLevel,
    required this.yearsOfExperience,
    required this.educationLevel,
    required this.englishLevel,
    required this.japaneseLevel,
    required this.koreanLevel,
    required this.germanLevel,
    required this.otherLanguages,
    required this.skills,
    required this.preferredCountries,
    required this.preferredWorkModes,
    required this.needsVisaSponsorship,
    required this.wantsRelocationSupport,
    required this.wantsHousingSupport,
    required this.githubUrl,
    required this.linkedInUrl,
    required this.portfolioUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String fullName;
  final String currentCountry;
  final String citizenship;
  final String targetRole;
  final String experienceLevel;
  final int yearsOfExperience;
  final String educationLevel;
  final String englishLevel;
  final String japaneseLevel;
  final String koreanLevel;
  final String germanLevel;
  final List<String> otherLanguages;
  final List<String> skills;
  final List<String> preferredCountries;
  final List<WorkMode> preferredWorkModes;
  final bool needsVisaSponsorship;
  final bool wantsRelocationSupport;
  final bool wantsHousingSupport;
  final String githubUrl;
  final String linkedInUrl;
  final String portfolioUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
    id: json['id']?.toString() ?? 'primary-user',
    fullName: json['fullName']?.toString() ?? '',
    currentCountry: json['currentCountry']?.toString() ?? '',
    citizenship: json['citizenship']?.toString() ?? '',
    targetRole: json['targetRole']?.toString() ?? '',
    experienceLevel: json['experienceLevel']?.toString() ?? '',
    yearsOfExperience: (json['yearsOfExperience'] as num?)?.toInt() ?? 0,
    educationLevel: json['educationLevel']?.toString() ?? '',
    englishLevel: json['englishLevel']?.toString() ?? '',
    japaneseLevel: json['japaneseLevel']?.toString() ?? '',
    koreanLevel: json['koreanLevel']?.toString() ?? '',
    germanLevel: json['germanLevel']?.toString() ?? '',
    otherLanguages: _stringList(json['otherLanguages']),
    skills: _stringList(json['skills']),
    preferredCountries: _stringList(json['preferredCountries']),
    preferredWorkModes: _stringList(json['preferredWorkModes'])
        .map((item) => _enumByName(WorkMode.values, item, WorkMode.unknown))
        .toList(),
    needsVisaSponsorship: json['needsVisaSponsorship'] == true,
    wantsRelocationSupport: json['wantsRelocationSupport'] == true,
    wantsHousingSupport: json['wantsHousingSupport'] == true,
    githubUrl: json['githubUrl']?.toString() ?? '',
    linkedInUrl: json['linkedInUrl']?.toString() ?? '',
    portfolioUrl: json['portfolioUrl']?.toString() ?? '',
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'fullName': fullName,
    'currentCountry': currentCountry,
    'citizenship': citizenship,
    'targetRole': targetRole,
    'experienceLevel': experienceLevel,
    'yearsOfExperience': yearsOfExperience,
    'educationLevel': educationLevel,
    'englishLevel': englishLevel,
    'japaneseLevel': japaneseLevel,
    'koreanLevel': koreanLevel,
    'germanLevel': germanLevel,
    'otherLanguages': otherLanguages,
    'skills': skills,
    'preferredCountries': preferredCountries,
    'preferredWorkModes': preferredWorkModes.map((item) => item.name).toList(),
    'needsVisaSponsorship': needsVisaSponsorship,
    'wantsRelocationSupport': wantsRelocationSupport,
    'wantsHousingSupport': wantsHousingSupport,
    'githubUrl': githubUrl,
    'linkedInUrl': linkedInUrl,
    'portfolioUrl': portfolioUrl,
  };
}

class Credential {
  const Credential({
    required this.id,
    required this.title,
    required this.provider,
    required this.type,
    required this.trustLevel,
    this.issueDate,
    this.expiryDate,
    required this.verificationUrl,
    required this.fileName,
    required this.notes,
  });

  final String id;
  final String title;
  final String provider;
  final CredentialType type;
  final TrustLevel trustLevel;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String verificationUrl;
  final String fileName;
  final String notes;

  factory Credential.fromJson(Map<String, dynamic> json) => Credential(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    provider: json['provider']?.toString() ?? '',
    type: _enumByName(
      CredentialType.values,
      json['type'],
      CredentialType.other,
    ),
    trustLevel: _enumByName(
      TrustLevel.values,
      json['trustLevel'],
      TrustLevel.unverified,
    ),
    issueDate: _nullableDate(json['issueDate']),
    expiryDate: _nullableDate(json['expiryDate']),
    verificationUrl: json['verificationUrl']?.toString() ?? '',
    fileName: json['fileName']?.toString() ?? '',
    notes: json['notes']?.toString() ?? '',
  );

  Map<String, dynamic> toJson() => {
    'title': title,
    'provider': provider,
    'type': type.name,
    'trustLevel': trustLevel.name,
    'issueDate': issueDate?.toIso8601String().split('T').first,
    'expiryDate': expiryDate?.toIso8601String().split('T').first,
    'verificationUrl': verificationUrl,
    'fileName': fileName,
    'notes': notes,
  };
}

class PortfolioProject {
  const PortfolioProject({
    required this.id,
    required this.title,
    required this.description,
    required this.techStack,
    required this.proofSkills,
    required this.githubUrl,
    required this.demoUrl,
    required this.appStoreUrl,
    required this.screenshots,
    required this.hasTests,
    required this.hasCiCd,
    required this.notes,
  });

  final String id;
  final String title;
  final String description;
  final List<String> techStack;
  final List<String> proofSkills;
  final String githubUrl;
  final String demoUrl;
  final String appStoreUrl;
  final List<String> screenshots;
  final bool hasTests;
  final bool hasCiCd;
  final String notes;

  factory PortfolioProject.fromJson(Map<String, dynamic> json) =>
      PortfolioProject(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        techStack: _stringList(json['techStack']),
        proofSkills: _stringList(json['proofSkills']),
        githubUrl: json['githubUrl']?.toString() ?? '',
        demoUrl: json['demoUrl']?.toString() ?? '',
        appStoreUrl: json['appStoreUrl']?.toString() ?? '',
        screenshots: _stringList(json['screenshots']),
        hasTests: json['hasTests'] == true,
        hasCiCd: json['hasCiCd'] == true,
        notes: json['notes']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'techStack': techStack,
    'proofSkills': proofSkills,
    'githubUrl': githubUrl,
    'demoUrl': demoUrl,
    'appStoreUrl': appStoreUrl,
    'screenshots': screenshots,
    'hasTests': hasTests,
    'hasCiCd': hasCiCd,
    'notes': notes,
  };
}

class JobPosting {
  const JobPosting({
    required this.id,
    required this.source,
    required this.externalId,
    required this.companyName,
    required this.jobTitle,
    required this.country,
    required this.city,
    required this.workMode,
    required this.jobUrl,
    required this.rawDescription,
    required this.salaryRange,
    required this.publishedAt,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String source;
  final String externalId;
  final String companyName;
  final String jobTitle;
  final String country;
  final String city;
  final WorkMode workMode;
  final String jobUrl;
  final String rawDescription;
  final String salaryRange;
  final DateTime publishedAt;
  final JobStatus status;
  final JobNotes? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory JobPosting.fromJson(Map<String, dynamic> json) => JobPosting(
    id: json['id']?.toString() ?? '',
    source: json['source']?.toString() ?? '',
    externalId: json['externalId']?.toString() ?? '',
    companyName: json['companyName']?.toString() ?? '',
    jobTitle: json['jobTitle']?.toString() ?? '',
    country: json['country']?.toString() ?? '',
    city: json['city']?.toString() ?? '',
    workMode: _enumByName(WorkMode.values, json['workMode'], WorkMode.unknown),
    jobUrl: json['jobUrl']?.toString() ?? '',
    rawDescription: json['rawDescription']?.toString() ?? '',
    salaryRange: json['salaryRange']?.toString() ?? '',
    publishedAt: _date(json['publishedAt']),
    status: _enumByName(JobStatus.values, json['status'], JobStatus.saved),
    notes: json['notes'] is Map
        ? JobNotes.fromJson((json['notes'] as Map).cast<String, dynamic>())
        : null,
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  JobPosting copyWith({JobStatus? status}) => JobPosting(
    id: id,
    source: source,
    externalId: externalId,
    companyName: companyName,
    jobTitle: jobTitle,
    country: country,
    city: city,
    workMode: workMode,
    jobUrl: jobUrl,
    rawDescription: rawDescription,
    salaryRange: salaryRange,
    publishedAt: publishedAt,
    status: status ?? this.status,
    notes: notes,
    createdAt: createdAt,
    updatedAt: DateTime.now(),
  );
}

class JobNotes {
  const JobNotes({
    required this.generalNotes,
    required this.interviewNotes,
    required this.recruiterNotes,
    required this.nextAction,
    this.followUpDate,
    required this.updatedAt,
  });

  final String generalNotes;
  final String interviewNotes;
  final String recruiterNotes;
  final String nextAction;
  final DateTime? followUpDate;
  final DateTime updatedAt;

  factory JobNotes.fromJson(Map<String, dynamic> json) => JobNotes(
    generalNotes: json['generalNotes']?.toString() ?? '',
    interviewNotes: json['interviewNotes']?.toString() ?? '',
    recruiterNotes: json['recruiterNotes']?.toString() ?? '',
    nextAction: json['nextAction']?.toString() ?? '',
    followUpDate: _nullableDate(json['followUpDate']),
    updatedAt: _date(json['updatedAt']),
  );
}

class JobStatusHistory {
  const JobStatusHistory({
    required this.id,
    required this.jobId,
    required this.previousStatus,
    required this.newStatus,
    required this.note,
    required this.changedAt,
  });

  final String id;
  final String jobId;
  final JobStatus previousStatus;
  final JobStatus newStatus;
  final String note;
  final DateTime changedAt;

  factory JobStatusHistory.fromJson(Map<String, dynamic> json) =>
      JobStatusHistory(
        id: json['id']?.toString() ?? '',
        jobId: json['jobId']?.toString() ?? '',
        previousStatus: _enumByName(
          JobStatus.values,
          json['previousStatus'],
          JobStatus.saved,
        ),
        newStatus: _enumByName(
          JobStatus.values,
          json['newStatus'],
          JobStatus.saved,
        ),
        note: json['note']?.toString() ?? '',
        changedAt: _date(json['changedAt']),
      );
}

class CompanySupport {
  const CompanySupport({
    required this.visaSponsorship,
    required this.workPermitSupport,
    required this.relocationPackage,
    required this.flightTicket,
    required this.temporaryHousing,
    required this.housingAllowance,
    required this.apartmentSearchSupport,
    required this.healthInsurance,
    required this.socialInsurance,
    required this.equipmentProvided,
    required this.remoteWorkSupport,
    required this.languageClasses,
    required this.familyRelocation,
    required this.salaryRange,
    required this.bonus,
    required this.stockOptions,
    required this.taxSupport,
  });

  final SupportValue visaSponsorship;
  final SupportValue workPermitSupport;
  final SupportValue relocationPackage;
  final SupportValue flightTicket;
  final SupportValue temporaryHousing;
  final SupportValue housingAllowance;
  final SupportValue apartmentSearchSupport;
  final SupportValue healthInsurance;
  final SupportValue socialInsurance;
  final SupportValue equipmentProvided;
  final SupportValue remoteWorkSupport;
  final SupportValue languageClasses;
  final SupportValue familyRelocation;
  final String salaryRange;
  final SupportValue bonus;
  final SupportValue stockOptions;
  final SupportValue taxSupport;

  factory CompanySupport.fromJson(Map<String, dynamic> json) => CompanySupport(
    visaSponsorship: _enumByName(
      SupportValue.values,
      json['visaSponsorship'],
      SupportValue.unclear,
    ),
    workPermitSupport: _enumByName(
      SupportValue.values,
      json['workPermitSupport'],
      SupportValue.unclear,
    ),
    relocationPackage: _enumByName(
      SupportValue.values,
      json['relocationPackage'],
      SupportValue.unclear,
    ),
    flightTicket: _enumByName(
      SupportValue.values,
      json['flightTicket'],
      SupportValue.notMentioned,
    ),
    temporaryHousing: _enumByName(
      SupportValue.values,
      json['temporaryHousing'],
      SupportValue.notMentioned,
    ),
    housingAllowance: _enumByName(
      SupportValue.values,
      json['housingAllowance'],
      SupportValue.notMentioned,
    ),
    apartmentSearchSupport: _enumByName(
      SupportValue.values,
      json['apartmentSearchSupport'],
      SupportValue.notMentioned,
    ),
    healthInsurance: _enumByName(
      SupportValue.values,
      json['healthInsurance'],
      SupportValue.notMentioned,
    ),
    socialInsurance: _enumByName(
      SupportValue.values,
      json['socialInsurance'],
      SupportValue.notMentioned,
    ),
    equipmentProvided: _enumByName(
      SupportValue.values,
      json['equipmentProvided'],
      SupportValue.notMentioned,
    ),
    remoteWorkSupport: _enumByName(
      SupportValue.values,
      json['remoteWorkSupport'],
      SupportValue.notMentioned,
    ),
    languageClasses: _enumByName(
      SupportValue.values,
      json['languageClasses'],
      SupportValue.notMentioned,
    ),
    familyRelocation: _enumByName(
      SupportValue.values,
      json['familyRelocation'],
      SupportValue.notMentioned,
    ),
    salaryRange: json['salaryRange']?.toString() ?? '',
    bonus: _enumByName(
      SupportValue.values,
      json['bonus'],
      SupportValue.notMentioned,
    ),
    stockOptions: _enumByName(
      SupportValue.values,
      json['stockOptions'],
      SupportValue.notMentioned,
    ),
    taxSupport: _enumByName(
      SupportValue.values,
      json['taxSupport'],
      SupportValue.notMentioned,
    ),
  );
}

class EligibilityAnalysis {
  const EligibilityAnalysis({
    required this.id,
    required this.jobId,
    required this.overallMatchScore,
    required this.skillsScore,
    required this.experienceScore,
    required this.languageScore,
    required this.visaScore,
    required this.locationScore,
    required this.companySupportScore,
    required this.decision,
    required this.matchedSkills,
    required this.missingSkills,
    required this.missingProof,
    required this.languageRequirements,
    required this.visaStatus,
    required this.relocationStatus,
    required this.locationRestrictions,
    required this.degreeRequirements,
    required this.companySupport,
    required this.risks,
    required this.actionPlan,
    required this.explanation,
    required this.summary,
    required this.source,
    required this.fallbackUsed,
    required this.confidence,
    required this.missingInformationQuestions,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobId;
  final int overallMatchScore;
  final int skillsScore;
  final int experienceScore;
  final int languageScore;
  final int visaScore;
  final int locationScore;
  final int companySupportScore;
  final EligibilityDecision decision;
  final List<String> matchedSkills;
  final List<String> missingSkills;
  final List<String> missingProof;
  final List<String> languageRequirements;
  final String visaStatus;
  final String relocationStatus;
  final String locationRestrictions;
  final String degreeRequirements;
  final CompanySupport companySupport;
  final List<String> risks;
  final List<String> actionPlan;
  final String explanation;
  final String summary;
  final String source;
  final bool fallbackUsed;
  final String confidence;
  final List<String> missingInformationQuestions;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory EligibilityAnalysis.fromJson(
    Map<String, dynamic> json,
  ) => EligibilityAnalysis(
    id: json['id']?.toString() ?? '',
    jobId: json['jobId']?.toString() ?? '',
    overallMatchScore: (json['overallMatchScore'] as num?)?.toInt() ?? 0,
    skillsScore: (json['skillsScore'] as num?)?.toInt() ?? 0,
    experienceScore: (json['experienceScore'] as num?)?.toInt() ?? 0,
    languageScore: (json['languageScore'] as num?)?.toInt() ?? 0,
    visaScore: (json['visaScore'] as num?)?.toInt() ?? 0,
    locationScore: (json['locationScore'] as num?)?.toInt() ?? 0,
    companySupportScore: (json['companySupportScore'] as num?)?.toInt() ?? 0,
    decision: _enumByName(
      EligibilityDecision.values,
      json['decision'],
      EligibilityDecision.unclear,
    ),
    matchedSkills: _stringList(json['matchedSkills']),
    missingSkills: _stringList(json['missingSkills']),
    missingProof: _stringList(json['missingProof']),
    languageRequirements: _stringList(json['languageRequirements']),
    visaStatus: json['visaStatus']?.toString() ?? '',
    relocationStatus: json['relocationStatus']?.toString() ?? '',
    locationRestrictions: _stringList(json['locationRestrictions']).join(', '),
    degreeRequirements: _stringList(json['degreeRequirements']).join(', '),
    companySupport: CompanySupport.fromJson(
      (json['companySupport'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    risks: _stringList(json['risks']),
    actionPlan: _stringList(json['actionPlan']),
    explanation: json['explanation']?.toString() ?? '',
    summary: json['summary']?.toString() ?? '',
    source: json['source']?.toString() ?? 'rule_based',
    fallbackUsed: json['fallbackUsed'] == true,
    confidence: json['confidence']?.toString() ?? 'medium',
    missingInformationQuestions: _stringList(
      json['missingInformationQuestions'],
    ),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );
}

class ApplicationPackage {
  const ApplicationPackage({
    required this.id,
    required this.jobId,
    required this.cvSummary,
    required this.coverLetter,
    required this.recruiterMessage,
    required this.skillMatchExplanation,
    required this.projectEvidence,
    required this.riskNotes,
    required this.finalChecklist,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String jobId;
  final String cvSummary;
  final String coverLetter;
  final String recruiterMessage;
  final String skillMatchExplanation;
  final String projectEvidence;
  final String riskNotes;
  final List<String> finalChecklist;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ApplicationPackage.fromJson(Map<String, dynamic> json) =>
      ApplicationPackage(
        id: json['id']?.toString() ?? '',
        jobId: json['jobId']?.toString() ?? '',
        cvSummary: json['cvSummary']?.toString() ?? '',
        coverLetter: json['coverLetter']?.toString() ?? '',
        recruiterMessage: json['recruiterMessage']?.toString() ?? '',
        skillMatchExplanation: json['skillMatchExplanation']?.toString() ?? '',
        projectEvidence: json['projectEvidence']?.toString() ?? '',
        riskNotes: json['riskNotes']?.toString() ?? '',
        finalChecklist: _stringList(json['finalChecklist']),
        createdAt: _date(json['createdAt']),
        updatedAt: _date(json['updatedAt']),
      );
}

class AppSettings {
  const AppSettings({
    required this.environment,
    required this.useMockJobs,
    required this.useRealAi,
    required this.apiBaseUrl,
    required this.configuredProviders,
    required this.storage,
    required this.requireAuth,
    required this.providers,
    required this.publicationReadiness,
  });

  final String environment;
  final bool useMockJobs;
  final bool useRealAi;
  final String apiBaseUrl;
  final List<String> configuredProviders;
  final String storage;
  final bool requireAuth;
  final List<ProviderSetting> providers;
  final PublicationReadiness publicationReadiness;

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    environment: json['environment']?.toString() ?? 'development',
    useMockJobs: json['useMockJobs'] != false,
    useRealAi: json['useRealAi'] == true,
    apiBaseUrl: json['apiBaseUrl']?.toString() ?? '',
    configuredProviders: _stringList(json['configuredProviders']),
    storage: json['storage']?.toString() ?? '',
    requireAuth: json['requireAuth'] == true,
    providers: json['providers'] is List
        ? (json['providers'] as List)
              .map(
                (item) => ProviderSetting.fromJson(
                  (item as Map).cast<String, dynamic>(),
                ),
              )
              .toList()
        : const [],
    publicationReadiness: PublicationReadiness.fromJson(
      (json['publicationReadiness'] as Map?)?.cast<String, dynamic>() ??
          const {},
    ),
  );
}

class PublicationReadiness {
  const PublicationReadiness({
    required this.ready,
    required this.blockers,
    required this.warnings,
    required this.nextActions,
  });

  final bool ready;
  final List<String> blockers;
  final List<String> warnings;
  final List<String> nextActions;

  factory PublicationReadiness.fromJson(Map<String, dynamic> json) =>
      PublicationReadiness(
        ready: json['ready'] == true,
        blockers: _stringList(json['blockers']),
        warnings: _stringList(json['warnings']),
        nextActions: _stringList(json['nextActions']),
      );
}

class ProviderSetting {
  const ProviderSetting({
    required this.name,
    required this.enabled,
    required this.status,
    required this.requiresApiKey,
    required this.requiresCompanySlug,
    required this.companySlugs,
    this.warning,
  });

  final String name;
  final bool enabled;
  final String status;
  final bool requiresApiKey;
  final bool requiresCompanySlug;
  final List<String> companySlugs;
  final String? warning;

  factory ProviderSetting.fromJson(Map<String, dynamic> json) =>
      ProviderSetting(
        name: json['name']?.toString() ?? '',
        enabled: json['enabled'] != false,
        status: json['status']?.toString() ?? 'needs-configuration',
        requiresApiKey: json['requiresApiKey'] == true,
        requiresCompanySlug: json['requiresCompanySlug'] == true,
        companySlugs: _stringList(json['companySlugs']),
        warning: json['warning']?.toString(),
      );
}

class SafeUser {
  const SafeUser({
    required this.id,
    required this.email,
    required this.fullName,
  });

  final String id;
  final String email;
  final String fullName;

  factory SafeUser.fromJson(Map<String, dynamic> json) => SafeUser(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
  );
}

class AuthSession {
  const AuthSession({required this.accessToken, required this.user});

  final String accessToken;
  final SafeUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken']?.toString() ?? '',
    user: SafeUser.fromJson(
      (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );
}
