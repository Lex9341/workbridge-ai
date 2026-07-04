import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'models.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

final appStateProvider = StateNotifierProvider<AppController, WorkBridgeState>(
  (_) => AppController(WorkBridgeApi(apiBaseUrl)),
);

class WorkBridgeState {
  const WorkBridgeState({
    required this.profile,
    required this.credentials,
    required this.projects,
    required this.jobs,
    required this.analyses,
    required this.applications,
    required this.statusHistory,
    required this.useMockSources,
    required this.selectedProviders,
    required this.settings,
    required this.authUser,
    required this.isLoading,
    required this.error,
  });

  final UserProfile profile;
  final List<Credential> credentials;
  final List<PortfolioProject> projects;
  final List<JobPosting> jobs;
  final Map<String, EligibilityAnalysis> analyses;
  final Map<String, ApplicationPackage> applications;
  final Map<String, List<JobStatusHistory>> statusHistory;
  final bool useMockSources;
  final List<String> selectedProviders;
  final AppSettings? settings;
  final SafeUser? authUser;
  final bool isLoading;
  final String? error;

  WorkBridgeState copyWith({
    UserProfile? profile,
    List<Credential>? credentials,
    List<PortfolioProject>? projects,
    List<JobPosting>? jobs,
    Map<String, EligibilityAnalysis>? analyses,
    Map<String, ApplicationPackage>? applications,
    Map<String, List<JobStatusHistory>>? statusHistory,
    bool? useMockSources,
    List<String>? selectedProviders,
    AppSettings? settings,
    SafeUser? authUser,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return WorkBridgeState(
      profile: profile ?? this.profile,
      credentials: credentials ?? this.credentials,
      projects: projects ?? this.projects,
      jobs: jobs ?? this.jobs,
      analyses: analyses ?? this.analyses,
      applications: applications ?? this.applications,
      statusHistory: statusHistory ?? this.statusHistory,
      useMockSources: useMockSources ?? this.useMockSources,
      selectedProviders: selectedProviders ?? this.selectedProviders,
      settings: settings ?? this.settings,
      authUser: authUser ?? this.authUser,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class AppController extends StateNotifier<WorkBridgeState> {
  AppController(this.api) : super(_seedState()) {
    unawaited(load());
  }

  final WorkBridgeApi api;

  Future<void> load() async {
    await _run(() async {
      final settings = await api.settings();
      state = state.copyWith(
        settings: settings,
        useMockSources: settings.useMockJobs,
        selectedProviders: settings.configuredProviders.isEmpty
            ? state.selectedProviders
            : settings.configuredProviders,
      );
      final profile = await api.profile();
      final credentials = await api.credentials();
      final projects = await api.projects();
      final jobs = await api.jobs();
      final applications = await api.applications();
      final histories = <String, List<JobStatusHistory>>{};
      for (final job in jobs) {
        histories[job.id] = await api.statusHistory(job.id);
      }
      state = state.copyWith(
        settings: settings,
        useMockSources: settings.useMockJobs,
        selectedProviders: settings.configuredProviders.isEmpty
            ? state.selectedProviders
            : settings.configuredProviders,
        profile: profile,
        credentials: credentials,
        projects: projects,
        jobs: jobs.isEmpty ? state.jobs : jobs,
        applications: {for (final item in applications) item.jobId: item},
        statusHistory: histories,
      );
    });
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _run(() async {
      state = state.copyWith(profile: await api.updateProfile(profile));
    });
  }

  Future<void> register(String email, String password, String fullName) async {
    await _run(() async {
      final session = await api.register(email, password, fullName);
      api.accessToken = session.accessToken;
      state = state.copyWith(authUser: session.user);
      await load();
    });
  }

  Future<void> login(String email, String password) async {
    await _run(() async {
      final session = await api.login(email, password);
      api.accessToken = session.accessToken;
      state = state.copyWith(authUser: session.user);
      await load();
    });
  }

  Future<void> createCredential(Credential credential) async {
    await _run(() async {
      final created = await api.createCredential(credential);
      state = state.copyWith(credentials: [...state.credentials, created]);
    });
  }

  Future<void> updateCredential(Credential credential) async {
    await _run(() async {
      final updated = await api.updateCredential(credential);
      state = state.copyWith(
        credentials: [
          for (final item in state.credentials)
            if (item.id == updated.id) updated else item,
        ],
      );
    });
  }

  Future<void> deleteCredential(String id) async {
    await _run(() async {
      await api.deleteCredential(id);
      state = state.copyWith(
        credentials: state.credentials.where((item) => item.id != id).toList(),
      );
    });
  }

  Future<void> createProject(PortfolioProject project) async {
    await _run(() async {
      final created = await api.createProject(project);
      state = state.copyWith(projects: [...state.projects, created]);
    });
  }

  Future<void> updateProject(PortfolioProject project) async {
    await _run(() async {
      final updated = await api.updateProject(project);
      state = state.copyWith(
        projects: [
          for (final item in state.projects)
            if (item.id == updated.id) updated else item,
        ],
      );
    });
  }

  Future<void> deleteProject(String id) async {
    await _run(() async {
      await api.deleteProject(id);
      state = state.copyWith(
        projects: state.projects.where((item) => item.id != id).toList(),
      );
    });
  }

  Future<void> searchJobs({
    String query = '',
    List<String>? countries,
    List<String>? roles,
    List<WorkMode>? workModes,
    bool? visaRequired,
    bool? relocationPreferred,
    bool? housingPreferred,
  }) async {
    await _run(() async {
      final jobs = await api.searchJobs({
        'query': query,
        'countries': countries ?? state.profile.preferredCountries,
        'roles': roles ?? [state.profile.targetRole],
        'workModes': (workModes ?? state.profile.preferredWorkModes)
            .map((item) => item.name)
            .toList(),
        'providers': state.selectedProviders,
        'visaRequired': visaRequired ?? state.profile.needsVisaSponsorship,
        'relocationPreferred':
            relocationPreferred ?? state.profile.wantsRelocationSupport,
        'housingPreferred':
            housingPreferred ?? state.profile.wantsHousingSupport,
        'experienceLevel': state.profile.experienceLevel,
      });
      state = state.copyWith(jobs: jobs);
    });
  }

  Future<void> analyzeJob(String jobId) async {
    await _run(() async {
      final analysis = await api.analyzeJob(jobId);
      final job = await api.job(jobId);
      final history = await api.statusHistory(jobId);
      state = state.copyWith(
        jobs: [
          for (final item in state.jobs)
            if (item.id == jobId) job else item,
        ],
        analyses: {...state.analyses, jobId: analysis},
        statusHistory: {...state.statusHistory, jobId: history},
      );
    });
  }

  Future<void> generateApplication(String jobId) async {
    await _run(() async {
      final package = await api.generateApplication(jobId);
      state = state.copyWith(
        applications: {...state.applications, jobId: package},
      );
    });
  }

  Future<void> markApplied(String jobId) async {
    await updateJobStatus(jobId, JobStatus.applied);
  }

  Future<void> updateJobStatus(String jobId, JobStatus status) async {
    await _run(() async {
      final job = await api.updateJobStatus(jobId, status);
      final history = await api.statusHistory(jobId);
      state = state.copyWith(
        jobs: [
          for (final item in state.jobs)
            if (item.id == jobId) job else item,
        ],
        statusHistory: {...state.statusHistory, jobId: history},
      );
    });
  }

  void toggleMockSources(bool value) {
    final provider = value ? 'MockJobProvider' : 'RemotiveProvider';
    state = state.copyWith(
      useMockSources: value,
      selectedProviders: [provider],
    );
  }

  void toggleProvider(String provider, bool value) {
    final providers = {...state.selectedProviders};
    value ? providers.add(provider) : providers.remove(provider);
    state = state.copyWith(selectedProviders: providers.toList());
  }

  Future<void> _run(Future<void> Function() action) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await action();
      state = state.copyWith(isLoading: false, clearError: true);
    } catch (error) {
      state = state.copyWith(isLoading: false, error: error.toString());
    }
  }
}

class WorkBridgeApi {
  WorkBridgeApi(this.baseUrl);

  final String baseUrl;
  String? accessToken;

  Future<AuthSession> register(
    String email,
    String password,
    String fullName,
  ) async => AuthSession.fromJson(
    await _postMap('/auth/register', {
      'email': email,
      'password': password,
      'fullName': fullName,
    }),
  );
  Future<AuthSession> login(String email, String password) async =>
      AuthSession.fromJson(
        await _postMap('/auth/login', {'email': email, 'password': password}),
      );
  Future<AppSettings> settings() async =>
      AppSettings.fromJson(await _getMap('/settings'));
  Future<UserProfile> profile() async =>
      UserProfile.fromJson(await _getMap('/profile'));
  Future<UserProfile> updateProfile(UserProfile profile) async =>
      UserProfile.fromJson(await _putMap('/profile', profile.toJson()));
  Future<List<Credential>> credentials() async =>
      _list('/credentials', Credential.fromJson);
  Future<Credential> createCredential(Credential input) async =>
      Credential.fromJson(await _postMap('/credentials', input.toJson()));
  Future<Credential> updateCredential(Credential input) async =>
      Credential.fromJson(
        await _putMap('/credentials/${input.id}', input.toJson()),
      );
  Future<void> deleteCredential(String id) async => _delete('/credentials/$id');
  Future<List<PortfolioProject>> projects() async =>
      _list('/portfolio-projects', PortfolioProject.fromJson);
  Future<PortfolioProject> createProject(PortfolioProject input) async =>
      PortfolioProject.fromJson(
        await _postMap('/portfolio-projects', input.toJson()),
      );
  Future<PortfolioProject> updateProject(PortfolioProject input) async =>
      PortfolioProject.fromJson(
        await _putMap('/portfolio-projects/${input.id}', input.toJson()),
      );
  Future<void> deleteProject(String id) async =>
      _delete('/portfolio-projects/$id');
  Future<List<JobPosting>> jobs() async => _list('/jobs', JobPosting.fromJson);
  Future<JobPosting> job(String id) async =>
      JobPosting.fromJson(await _getMap('/jobs/$id'));
  Future<List<JobPosting>> searchJobs(Map<String, dynamic> filters) async =>
      _decodeList(await _post('/jobs/search', filters), JobPosting.fromJson);
  Future<EligibilityAnalysis> analyzeJob(String id) async =>
      EligibilityAnalysis.fromJson(
        await _postMap('/jobs/$id/analyze', const {}),
      );
  Future<JobPosting> updateJobStatus(String id, JobStatus status) async =>
      JobPosting.fromJson(
        await _patchMap('/jobs/$id/status', {'status': status.name}),
      );
  Future<List<JobStatusHistory>> statusHistory(String id) async =>
      _list('/jobs/$id/status-history', JobStatusHistory.fromJson);
  Future<List<ApplicationPackage>> applications() async =>
      _list('/applications', ApplicationPackage.fromJson);
  Future<ApplicationPackage> generateApplication(String jobId) async =>
      ApplicationPackage.fromJson(
        await _postMap('/applications/generate', {'jobId': jobId}),
      );

  Future<List<T>> _list<T>(
    String path,
    T Function(Map<String, dynamic>) parse,
  ) async => _decodeList(await _get(path), parse);

  Future<Map<String, dynamic>> _getMap(String path) async =>
      _decodeMap(await _get(path));
  Future<Map<String, dynamic>> _postMap(
    String path,
    Map<String, dynamic> body,
  ) async => _decodeMap(await _post(path, body));
  Future<Map<String, dynamic>> _putMap(
    String path,
    Map<String, dynamic> body,
  ) async => _decodeMap(await _put(path, body));
  Future<Map<String, dynamic>> _patchMap(
    String path,
    Map<String, dynamic> body,
  ) async => _decodeMap(await _patch(path, body));

  Future<http.Response> _get(String path) => http.get(_uri(path));
  Future<http.Response> _post(String path, Map<String, dynamic> body) =>
      http.post(_uri(path), headers: _headers, body: jsonEncode(body));
  Future<http.Response> _put(String path, Map<String, dynamic> body) =>
      http.put(_uri(path), headers: _headers, body: jsonEncode(body));
  Future<http.Response> _patch(String path, Map<String, dynamic> body) =>
      http.patch(_uri(path), headers: _headers, body: jsonEncode(body));
  Future<void> _delete(String path) async =>
      _ensureOk(await http.delete(_uri(path)));

  Uri _uri(String path) => Uri.parse('$baseUrl$path');
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (accessToken != null) 'Authorization': 'Bearer $accessToken',
  };

  Map<String, dynamic> _decodeMap(http.Response response) {
    _ensureOk(response);
    return (jsonDecode(response.body) as Map).cast<String, dynamic>();
  }

  List<T> _decodeList<T>(
    http.Response response,
    T Function(Map<String, dynamic>) parse,
  ) {
    _ensureOk(response);
    return (jsonDecode(response.body) as List)
        .map((item) => parse((item as Map).cast<String, dynamic>()))
        .toList();
  }

  void _ensureOk(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('API ${response.statusCode}: ${response.body}');
    }
  }
}

WorkBridgeState _seedState() {
  final now = DateTime.now();
  final profile = UserProfile(
    id: 'primary-user',
    fullName: 'Akai Candidate',
    currentCountry: 'Uzbekistan',
    citizenship: 'Uzbekistan',
    targetRole: 'Flutter Developer',
    experienceLevel: 'Junior+',
    yearsOfExperience: 2,
    educationLevel: 'Bachelor equivalent',
    englishLevel: 'B2',
    japaneseLevel: 'N4',
    koreanLevel: 'Not provided',
    germanLevel: 'A2',
    otherLanguages: const ['Uzbek', 'Russian'],
    skills: const [
      'Flutter',
      'Dart',
      'Firebase',
      'REST API',
      'GitHub Actions',
      'Testing',
      'TypeScript',
    ],
    preferredCountries: const ['Japan', 'Germany', 'Netherlands'],
    preferredWorkModes: const [
      WorkMode.remote,
      WorkMode.hybrid,
      WorkMode.onsite,
    ],
    needsVisaSponsorship: true,
    wantsRelocationSupport: true,
    wantsHousingSupport: true,
    githubUrl: 'https://github.com/example',
    linkedInUrl: 'https://linkedin.com/in/example',
    portfolioUrl: 'https://example.dev',
    createdAt: now,
    updatedAt: now,
  );
  return WorkBridgeState(
    profile: profile,
    credentials: [
      Credential(
        id: 'cred-ielts',
        title: 'IELTS Academic',
        provider: 'British Council',
        type: CredentialType.language,
        trustLevel: TrustLevel.high,
        issueDate: DateTime(now.year - 1, 5, 1),
        expiryDate: DateTime(now.year + 1, 5, 1),
        verificationUrl: 'https://ielts.org',
        fileName: 'ielts-score.pdf',
        notes: 'B2/C1 range evidence for English communication.',
      ),
    ],
    projects: const [
      PortfolioProject(
        id: 'project-1',
        title: 'Cross-platform Task Planner',
        description:
            'Flutter productivity app with Firebase auth, Firestore sync, tests and CI.',
        techStack: ['Flutter', 'Dart', 'Firebase', 'GitHub Actions'],
        proofSkills: [
          'Flutter',
          'Dart',
          'Firebase',
          'Testing',
          'GitHub Actions',
        ],
        githubUrl: 'https://github.com/example/task-planner',
        demoUrl: 'https://example.dev/task-planner',
        appStoreUrl: '',
        screenshots: [],
        hasTests: true,
        hasCiCd: true,
        notes: 'Good evidence for mobile architecture and release readiness.',
      ),
    ],
    jobs: _mockJobs,
    analyses: const {},
    applications: const {},
    statusHistory: const {},
    useMockSources: true,
    selectedProviders: const ['MockJobProvider'],
    settings: null,
    authUser: null,
    isLoading: false,
    error: null,
  );
}

final _mockJobs = [
  JobPosting(
    id: 'mock-jp-flutter-1',
    source: 'MockJobProvider',
    externalId: 'jp-flutter-1',
    companyName: 'Tokyo Mobility Labs',
    jobTitle: 'Flutter Developer',
    country: 'Japan',
    city: 'Tokyo',
    workMode: WorkMode.hybrid,
    jobUrl: 'https://example.com/jobs/tokyo-flutter',
    rawDescription:
        'Flutter, Dart, Firebase, REST API and Testing. English required, Japanese N4 helpful. Visa sponsorship, certificate of eligibility, relocation support, temporary accommodation, equipment and health insurance provided.',
    salaryRange: 'JPY 5M-7M',
    publishedAt: DateTime.now().subtract(const Duration(days: 2)),
    status: JobStatus.saved,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  JobPosting(
    id: 'mock-de-fullstack-1',
    source: 'MockJobProvider',
    externalId: 'de-fullstack-1',
    companyName: 'Berlin Cloud Works',
    jobTitle: 'Junior Full-stack Developer',
    country: 'Germany',
    city: 'Berlin',
    workMode: WorkMode.remote,
    jobUrl: 'https://example.com/jobs/berlin-fullstack',
    rawDescription:
        'React, TypeScript, Node.js, PostgreSQL, Docker, CI/CD and AWS. English B2 required. Visa sponsorship unclear. Remote work support and equipment provided.',
    salaryRange: 'EUR 48K-62K',
    publishedAt: DateTime.now().subtract(const Duration(days: 4)),
    status: JobStatus.saved,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
  JobPosting(
    id: 'mock-nl-qa-1',
    source: 'MockJobProvider',
    externalId: 'nl-qa-1',
    companyName: 'Amsterdam Quality Systems',
    jobTitle: 'QA Automation Engineer',
    country: 'Netherlands',
    city: 'Amsterdam',
    workMode: WorkMode.hybrid,
    jobUrl: 'https://example.com/jobs/amsterdam-qa',
    rawDescription:
        'QA Automation, Playwright, Selenium, JavaScript, REST API and GitHub Actions. Must already have work authorization. Relocation support not provided.',
    salaryRange: 'EUR 42K-55K',
    publishedAt: DateTime.now().subtract(const Duration(days: 6)),
    status: JobStatus.saved,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
];
