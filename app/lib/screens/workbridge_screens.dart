import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';

import '../app_state.dart';
import '../models.dart';
import '../shared/workbridge_ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final analyses = state.analyses.values.toList();
    final eligible = analyses
        .where((item) => item.decision == EligibilityDecision.eligible)
        .length;
    final almost = analyses
        .where((item) => item.decision == EligibilityDecision.almostEligible)
        .length;
    final notEligible = analyses
        .where((item) => item.decision == EligibilityDecision.notEligible)
        .length;
    final readiness = analyses.isEmpty
        ? 'Not scored'
        : '${(analyses.map((item) => item.overallMatchScore).reduce((a, b) => a + b) / analyses.length).round()}%';
    final missingSkills = analyses
        .expand((item) => item.missingSkills)
        .toSet()
        .take(8)
        .toList();
    final applied = state.jobs
        .where((item) => item.status == JobStatus.applied)
        .length;
    final interviews = state.jobs
        .where((item) => item.status == JobStatus.interview)
        .length;
    final offers = state.jobs
        .where((item) => item.status == JobStatus.offer)
        .length;

    return PageScaffold(
      title: 'International IT readiness',
      subtitle:
          'A focused command center for job discovery, eligibility analysis, and review-ready application materials.',
      children: [
        if (state.isLoading)
          const LoadingState(message: 'Refreshing dashboard'),
        if (state.error != null) ErrorState(message: state.error!),
        ResponsiveGrid(
          children: [
            MetricCard(
              label: 'Readiness score',
              value: readiness,
              icon: Icons.speed_outlined,
              detail: analyses.isEmpty
                  ? 'Analyze jobs to calculate score'
                  : 'Average analyzed match',
            ),
            MetricCard(
              label: 'Selected countries',
              value: '${state.profile.preferredCountries.length}',
              icon: Icons.public_outlined,
              detail: state.profile.preferredCountries.join(', '),
            ),
            MetricCard(
              label: 'Total jobs found',
              value: '${state.jobs.length}',
              icon: Icons.work_outline,
            ),
            MetricCard(
              label: 'Eligible jobs',
              value: '$eligible',
              icon: Icons.verified_outlined,
              color: successColor,
            ),
            MetricCard(
              label: 'Almost eligible',
              value: '$almost',
              icon: Icons.pending_actions_outlined,
              color: warningColor,
            ),
            MetricCard(
              label: 'Not eligible',
              value: '$notEligible',
              icon: Icons.report_gmailerrorred_outlined,
              color: dangerColor,
            ),
            MetricCard(
              label: 'Applied jobs',
              value: '$applied',
              icon: Icons.send_outlined,
            ),
            MetricCard(
              label: 'Interviews',
              value: '$interviews',
              icon: Icons.record_voice_over_outlined,
            ),
            MetricCard(
              label: 'Offers',
              value: '$offers',
              icon: Icons.emoji_events_outlined,
              color: successColor,
            ),
          ],
        ),
        SectionCard(
          title: 'Top missing skills',
          subtitle: 'Signals pulled from analyzed roles.',
          child: missingSkills.isEmpty
              ? const Text(
                  'No missing-skill pattern yet. Analyze a few jobs to see concrete gaps.',
                  style: TextStyle(color: mutedText),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: missingSkills
                      .map((item) => SkillChip(item, warning: true))
                      .toList(),
                ),
        ),
        SectionCard(
          title: 'Next recommended actions',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              SecondaryButton(
                icon: Icons.search,
                label: 'Discover jobs',
                onPressed: () => context.go('/jobs'),
              ),
              SecondaryButton(
                icon: Icons.person_outline,
                label: 'Complete profile',
                onPressed: () => context.go('/profile'),
              ),
              SecondaryButton(
                icon: Icons.workspace_premium_outlined,
                label: 'Add proof',
                onPressed: () => context.go('/credentials'),
              ),
              SecondaryButton(
                icon: Icons.description_outlined,
                label: 'Build resume',
                onPressed: () => context.go('/resume'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class JobDiscoveryScreen extends ConsumerStatefulWidget {
  const JobDiscoveryScreen({super.key});

  @override
  ConsumerState<JobDiscoveryScreen> createState() => _JobDiscoveryScreenState();
}

class _JobDiscoveryScreenState extends ConsumerState<JobDiscoveryScreen> {
  final queryController = TextEditingController();
  final countryController = TextEditingController();
  final roleController = TextEditingController();
  final modes = <WorkMode>{WorkMode.remote, WorkMode.hybrid, WorkMode.onsite};
  bool visaRequired = true;
  bool relocationPreferred = true;
  bool housingPreferred = true;

  @override
  void dispose() {
    queryController.dispose();
    countryController.dispose();
    roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final providers =
        state.settings?.configuredProviders ??
        const ['MockJobProvider', 'RemotiveProvider', 'TheMuseProvider'];
    return PageScaffold(
      title: 'Discover Jobs',
      subtitle:
          'Search international IT roles by country, source, support signals, and work mode.',
      children: [
        if (state.settings?.useMockJobs == true || state.useMockSources)
          const Align(
            alignment: Alignment.centerLeft,
            child: StatusBadge.warning('Demo jobs enabled'),
          ),
        if (state.error != null) ErrorState(message: state.error!),
        SectionCard(
          title: 'Search filters',
          subtitle:
              'Filters stack on mobile and expand into a dense search console on desktop.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _field(
                    queryController,
                    'Search input',
                    hint: 'Flutter, backend, QA automation',
                  ),
                  _field(
                    countryController,
                    'Country selector',
                    hint: state.profile.preferredCountries.join(', '),
                  ),
                  _field(
                    roleController,
                    'Role selector',
                    hint: state.profile.targetRole,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final mode in WorkMode.values.where(
                    (item) => item != WorkMode.unknown,
                  ))
                    FilterChip(
                      label: Text('${titleCaseEnum(mode)} mode'),
                      selected: modes.contains(mode),
                      onSelected: (value) => setState(
                        () => value ? modes.add(mode) : modes.remove(mode),
                      ),
                    ),
                  FilterChip(
                    label: const Text('Visa sponsorship required'),
                    selected: visaRequired,
                    onSelected: (value) => setState(() => visaRequired = value),
                  ),
                  FilterChip(
                    label: const Text('Relocation support preferred'),
                    selected: relocationPreferred,
                    onSelected: (value) =>
                        setState(() => relocationPreferred = value),
                  ),
                  FilterChip(
                    label: const Text('Housing support preferred'),
                    selected: housingPreferred,
                    onSelected: (value) =>
                        setState(() => housingPreferred = value),
                  ),
                ],
              ),
              const Divider(height: 28),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final provider in providers)
                    FilterChip(
                      label: Text(provider),
                      selected: state.selectedProviders.contains(provider),
                      onSelected: (value) => ref
                          .read(appStateProvider.notifier)
                          .toggleProvider(provider, value),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PrimaryButton(
                    icon: Icons.search,
                    label: 'Search jobs',
                    onPressed: state.isLoading ? null : () => _search(state),
                  ),
                  SecondaryButton(
                    icon: Icons.clear,
                    label: 'Clear filters',
                    onPressed: _clearFilters,
                  ),
                ],
              ),
              if (state.isLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
            ],
          ),
        ),
        if (state.jobs.isEmpty)
          EmptyState(
            title: 'No jobs found',
            message:
                'Broaden the role, add another country, or enable a configured source provider.',
            icon: Icons.work_off_outlined,
            action: PrimaryButton(
              icon: Icons.search,
              label: 'Run search',
              onPressed: () => _search(state),
            ),
          )
        else
          ...state.jobs.map(
            (job) => JobCard(job: job, analysis: state.analyses[job.id]),
          ),
      ],
    );
  }

  void _search(WorkBridgeState state) {
    ref
        .read(appStateProvider.notifier)
        .searchJobs(
          query: queryController.text,
          countries: _csv(countryController.text).isEmpty
              ? state.profile.preferredCountries
              : _csv(countryController.text),
          roles: _csv(roleController.text).isEmpty
              ? [state.profile.targetRole]
              : _csv(roleController.text),
          workModes: modes.toList(),
          visaRequired: visaRequired,
          relocationPreferred: relocationPreferred,
          housingPreferred: housingPreferred,
        );
  }

  void _clearFilters() {
    setState(() {
      queryController.clear();
      countryController.clear();
      roleController.clear();
      modes
        ..clear()
        ..addAll([WorkMode.remote, WorkMode.hybrid, WorkMode.onsite]);
      visaRequired = true;
      relocationPreferred = true;
      housingPreferred = true;
    });
  }
}

class JobCard extends ConsumerWidget {
  const JobCard({super.key, required this.job, this.analysis});

  final JobPosting job;
  final EligibilityAnalysis? analysis;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go('/jobs/${job.id}'),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CompanyLogo(name: job.companyName),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.jobTitle,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '${job.companyName} • ${job.city}, ${job.country}',
                          style: const TextStyle(color: mutedText),
                        ),
                      ],
                    ),
                  ),
                  decisionBadge(analysis?.decision),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge.info(titleCaseEnum(job.workMode)),
                  StatusBadge(job.source),
                  StatusBadge(
                    job.salaryRange.isEmpty
                        ? 'Salary not listed'
                        : job.salaryRange,
                  ),
                  StatusBadge.info(
                    analysis == null
                        ? 'Match not analyzed'
                        : '${analysis!.overallMatchScore}% match',
                  ),
                  StatusBadge.info(
                    analysis?.visaStatus.isEmpty ?? true
                        ? 'Visa unclear'
                        : analysis!.visaStatus,
                  ),
                  StatusBadge.info(
                    analysis?.relocationStatus.isEmpty ?? true
                        ? 'Relocation unclear'
                        : analysis!.relocationStatus,
                  ),
                  const StatusBadge.info('Housing unclear'),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PrimaryButton(
                    icon: Icons.psychology_outlined,
                    label: 'Analyze',
                    onPressed: () =>
                        ref.read(appStateProvider.notifier).analyzeJob(job.id),
                  ),
                  SecondaryButton(
                    icon: Icons.bookmark_outline,
                    label: 'Save',
                    onPressed: () => ref
                        .read(appStateProvider.notifier)
                        .updateJobStatus(job.id, JobStatus.saved),
                  ),
                  SecondaryButton(
                    icon: Icons.open_in_new,
                    label: 'Open link',
                    onPressed: () =>
                        _copy(context, job.jobUrl, 'Job link copied'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class JobDetailsScreen extends ConsumerWidget {
  const JobDetailsScreen({super.key, required this.jobId});

  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final job = state.jobs.where((item) => item.id == jobId).firstOrNull;
    if (job == null) {
      return const PageScaffold(
        title: 'Job not found',
        subtitle: 'The job may have been removed from the current result set.',
        children: [
          EmptyState(
            title: 'No matching job',
            message: 'Return to job discovery and open an available role.',
            icon: Icons.search_off_outlined,
          ),
        ],
      );
    }
    final analysis = state.analyses[jobId];
    final history = state.statusHistory[jobId] ?? const <JobStatusHistory>[];
    return PageScaffold(
      title: job.jobTitle,
      subtitle: '${job.companyName} • ${job.city}, ${job.country}',
      action: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          PrimaryButton(
            icon: Icons.outbox_outlined,
            label: 'Prepare Application',
            onPressed: () => _prepare(context, ref, job.id),
          ),
          SecondaryButton(
            icon: Icons.bookmark_outline,
            label: 'Save Job',
            onPressed: () => ref
                .read(appStateProvider.notifier)
                .updateJobStatus(job.id, JobStatus.saved),
          ),
          SecondaryButton(
            icon: Icons.check_circle_outline,
            label: 'Mark as Applied',
            onPressed: () =>
                ref.read(appStateProvider.notifier).markApplied(job.id),
          ),
          SecondaryButton(
            icon: Icons.open_in_new,
            label: 'Open Job Link',
            onPressed: () => _copy(context, job.jobUrl, 'Job link copied'),
          ),
        ],
      ),
      children: [
        SectionCard(
          title: 'Job overview',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailRow('Company', job.companyName),
              DetailRow('Location', '${job.city}, ${job.country}'),
              DetailRow('Work mode', titleCaseEnum(job.workMode)),
              DetailRow('Provider/source', job.source),
              DetailRow('Salary', job.salaryRange),
              DetailRow('Status', titleCaseEnum(job.status)),
              const SizedBox(height: 8),
              SelectableText(
                job.rawDescription,
                style: const TextStyle(height: 1.45),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Status timeline and notes',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (history.isEmpty)
                const Text(
                  'No status changes recorded yet.',
                  style: TextStyle(color: mutedText),
                )
              else
                for (final item in history.reversed.take(6))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DetailRow(
                      _dateLabel(item.changedAt),
                      '${titleCaseEnum(item.previousStatus)} → ${titleCaseEnum(item.newStatus)}${item.note.isEmpty ? '' : ' • ${item.note}'}',
                    ),
                  ),
              if (job.notes != null) ...[
                const SizedBox(height: 8),
                DetailRow('Next action', job.notes!.nextAction),
                DetailRow('General notes', job.notes!.generalNotes),
                DetailRow('Interview notes', job.notes!.interviewNotes),
                DetailRow('Recruiter notes', job.notes!.recruiterNotes),
              ],
            ],
          ),
        ),
        if (analysis == null)
          EmptyState(
            title: 'Analysis not run yet',
            message:
                'Run the AI analyzer to see match scoring, missing proof, support signals, risks, and an action plan.',
            icon: Icons.psychology_outlined,
            action: PrimaryButton(
              icon: Icons.psychology_outlined,
              label: 'Analyze job',
              onPressed: () =>
                  ref.read(appStateProvider.notifier).analyzeJob(job.id),
            ),
          )
        else
          AnalysisView(analysis: analysis),
      ],
    );
  }

  void _prepare(BuildContext context, WidgetRef ref, String jobId) {
    ref.read(appStateProvider.notifier).generateApplication(jobId);
    context.go('/applications');
  }
}

class AnalysisView extends StatelessWidget {
  const AnalysisView({super.key, required this.analysis});

  final EligibilityAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final support = analysis.companySupport;
    return Column(
      children: [
        SectionCard(
          title: 'AI explanation',
          trailing: decisionBadge(analysis.decision),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${analysis.overallMatchScore}% match',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(
                analysis.explanation.isEmpty
                    ? analysis.summary
                    : analysis.explanation,
                style: const TextStyle(height: 1.45),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusBadge.info('Source: ${analysis.source}'),
                  StatusBadge.info('Confidence: ${analysis.confidence}'),
                  if (analysis.fallbackUsed)
                    const StatusBadge.warning('AI fallback used'),
                ],
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Score breakdown',
          child: ResponsiveGrid(
            minItemWidth: 180,
            children: [
              MetricCard(
                label: 'Skills',
                value: '${analysis.skillsScore}%',
                icon: Icons.code,
              ),
              MetricCard(
                label: 'Experience',
                value: '${analysis.experienceScore}%',
                icon: Icons.timeline,
              ),
              MetricCard(
                label: 'Language',
                value: '${analysis.languageScore}%',
                icon: Icons.translate,
              ),
              MetricCard(
                label: 'Visa',
                value: '${analysis.visaScore}%',
                icon: Icons.badge_outlined,
              ),
              MetricCard(
                label: 'Location',
                value: '${analysis.locationScore}%',
                icon: Icons.place_outlined,
              ),
              MetricCard(
                label: 'Company support',
                value: '${analysis.companySupportScore}%',
                icon: Icons.business_center_outlined,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Skills and proof',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chipSection(
                'Required skills',
                <String>{
                  ...analysis.matchedSkills,
                  ...analysis.missingSkills,
                }.toList(),
              ),
              _chipSection('Matched skills', analysis.matchedSkills),
              _chipSection(
                'Missing skills',
                analysis.missingSkills,
                warning: true,
              ),
              _chipSection(
                'Missing proof',
                analysis.missingProof,
                warning: true,
              ),
              _chipSection(
                'Language requirements',
                analysis.languageRequirements,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Visa, relocation, housing, and support',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              supportBadge(
                'Visa sponsorship: ${titleCaseEnum(support.visaSponsorship)}',
                support.visaSponsorship,
              ),
              supportBadge(
                'Work permit: ${titleCaseEnum(support.workPermitSupport)}',
                support.workPermitSupport,
              ),
              supportBadge(
                'Relocation package: ${titleCaseEnum(support.relocationPackage)}',
                support.relocationPackage,
              ),
              supportBadge(
                'Flight ticket: ${titleCaseEnum(support.flightTicket)}',
                support.flightTicket,
              ),
              supportBadge(
                'Temporary housing: ${titleCaseEnum(support.temporaryHousing)}',
                support.temporaryHousing,
              ),
              supportBadge(
                'Housing allowance: ${titleCaseEnum(support.housingAllowance)}',
                support.housingAllowance,
              ),
              supportBadge(
                'Apartment search: ${titleCaseEnum(support.apartmentSearchSupport)}',
                support.apartmentSearchSupport,
              ),
              supportBadge(
                'Health insurance: ${titleCaseEnum(support.healthInsurance)}',
                support.healthInsurance,
              ),
              supportBadge(
                'Social insurance: ${titleCaseEnum(support.socialInsurance)}',
                support.socialInsurance,
              ),
              supportBadge(
                'Equipment/laptop: ${titleCaseEnum(support.equipmentProvided)}',
                support.equipmentProvided,
              ),
              supportBadge(
                'Remote support: ${titleCaseEnum(support.remoteWorkSupport)}',
                support.remoteWorkSupport,
              ),
              supportBadge(
                'Language classes: ${titleCaseEnum(support.languageClasses)}',
                support.languageClasses,
              ),
              supportBadge(
                'Family relocation: ${titleCaseEnum(support.familyRelocation)}',
                support.familyRelocation,
              ),
              StatusBadge.info(
                'Salary range: ${support.salaryRange.isEmpty ? 'Not mentioned' : support.salaryRange}',
              ),
              supportBadge(
                'Bonus: ${titleCaseEnum(support.bonus)}',
                support.bonus,
              ),
              supportBadge(
                'Stock options: ${titleCaseEnum(support.stockOptions)}',
                support.stockOptions,
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Risks and action plan',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chipSection('Risks', analysis.risks, warning: true),
              _chipSection('Action plan', analysis.actionPlan),
              _chipSection(
                'Questions to confirm',
                analysis.missingInformationQuestions,
                warning: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appStateProvider).profile;
    return PageScaffold(
      title: 'Profile',
      subtitle:
          'A professional candidate profile used for matching, readiness scoring, and application generation.',
      action: PrimaryButton(
        icon: Icons.edit_outlined,
        label: 'Edit profile',
        onPressed: () => showProfileDialog(context, ref, profile),
      ),
      children: [
        SectionCard(
          title: profile.fullName.isEmpty
              ? 'Candidate profile'
              : profile.fullName,
          subtitle: profile.targetRole,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailRow('Current country', profile.currentCountry),
              DetailRow('Citizenship', profile.citizenship),
              DetailRow(
                'Experience',
                '${profile.experienceLevel}, ${profile.yearsOfExperience} years',
              ),
              DetailRow('Education', profile.educationLevel),
              DetailRow(
                'Languages',
                'English ${profile.englishLevel}, Japanese ${profile.japaneseLevel}, Korean ${profile.koreanLevel}, German ${profile.germanLevel}, ${profile.otherLanguages.join(', ')}',
              ),
              DetailRow(
                'Links',
                [
                  profile.githubUrl,
                  profile.linkedInUrl,
                  profile.portfolioUrl,
                ].where((item) => item.isNotEmpty).join(' • '),
              ),
              const SizedBox(height: 10),
              _chipSection('Skills', profile.skills),
              _chipSection('Target countries', profile.preferredCountries),
              _chipSection('Relocation preferences', [
                profile.needsVisaSponsorship
                    ? 'Visa sponsorship needed'
                    : 'Visa not needed',
                profile.wantsRelocationSupport
                    ? 'Relocation support preferred'
                    : 'No relocation preference',
                profile.wantsHousingSupport
                    ? 'Housing support preferred'
                    : 'No housing preference',
              ]),
            ],
          ),
        ),
      ],
    );
  }
}

class CredentialsScreen extends ConsumerWidget {
  const CredentialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentials = ref.watch(appStateProvider).credentials;
    return PageScaffold(
      title: 'Credentials',
      subtitle:
          'Certificates, education, language proof, and verification signals.',
      action: PrimaryButton(
        icon: Icons.add,
        label: 'Add credential',
        onPressed: () => showCredentialDialog(context, ref),
      ),
      children: credentials.isEmpty
          ? [
              EmptyState(
                title: 'No credentials yet',
                message:
                    'Add certificates, degrees, language scores, or cloud credentials so applications can cite stronger proof.',
                icon: Icons.workspace_premium_outlined,
                action: PrimaryButton(
                  icon: Icons.add,
                  label: 'Add credential',
                  onPressed: () => showCredentialDialog(context, ref),
                ),
              ),
            ]
          : [
              ResponsiveGrid(
                minItemWidth: 330,
                children: [
                  for (final credential in credentials)
                    _CredentialCard(credential: credential),
                ],
              ),
            ],
    );
  }
}

class _CredentialCard extends ConsumerWidget {
  const _CredentialCard({required this.credential});

  final Credential credential;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    credential.title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _trustBadge(credential.trustLevel),
              ],
            ),
            const SizedBox(height: 12),
            DetailRow('Provider', credential.provider),
            DetailRow('Type', titleCaseEnum(credential.type)),
            DetailRow('Issue date', _dateLabel(credential.issueDate)),
            DetailRow('Expiry date', _dateLabel(credential.expiryDate)),
            DetailRow('Verification URL', credential.verificationUrl),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SecondaryButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onPressed: () =>
                      showCredentialDialog(context, ref, credential),
                ),
                SecondaryButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: () => ref
                      .read(appStateProvider.notifier)
                      .deleteCredential(credential.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(appStateProvider).projects;
    return PageScaffold(
      title: 'Portfolio',
      subtitle:
          'Project evidence that turns claimed skills into inspectable proof.',
      action: PrimaryButton(
        icon: Icons.add,
        label: 'Add project',
        onPressed: () => showProjectDialog(context, ref),
      ),
      children: projects.isEmpty
          ? [
              EmptyState(
                title: 'No portfolio projects',
                message:
                    'Add projects with tech stack, proof skills, links, tests, and CI/CD evidence.',
                icon: Icons.folder_open_outlined,
                action: PrimaryButton(
                  icon: Icons.add,
                  label: 'Add project',
                  onPressed: () => showProjectDialog(context, ref),
                ),
              ),
            ]
          : [
              ResponsiveGrid(
                minItemWidth: 360,
                children: [
                  for (final project in projects)
                    _ProjectCard(project: project),
                ],
              ),
            ],
    );
  }
}

class _ProjectCard extends ConsumerWidget {
  const _ProjectCard({required this.project});

  final PortfolioProject project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              project.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              project.description,
              style: const TextStyle(color: mutedText, height: 1.4),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.techStack.map(SkillChip.new).toList(),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: project.proofSkills
                  .map((item) => SkillChip(item, warning: true))
                  .toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusBadge.info(
                  project.githubUrl.isEmpty
                      ? 'No GitHub link'
                      : 'GitHub linked',
                ),
                StatusBadge.info(
                  project.demoUrl.isEmpty ? 'No demo link' : 'Demo linked',
                ),
                project.hasTests
                    ? const StatusBadge.success('Has tests')
                    : const StatusBadge.warning('Tests missing'),
                project.hasCiCd
                    ? const StatusBadge.success('Has CI/CD')
                    : const StatusBadge.warning('CI/CD missing'),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                SecondaryButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  onPressed: () => showProjectDialog(context, ref, project),
                ),
                SecondaryButton(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  onPressed: () => ref
                      .read(appStateProvider.notifier)
                      .deleteProject(project.id),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ResumeBuilderScreen extends ConsumerWidget {
  const ResumeBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final summary =
        '${state.profile.fullName} is a ${state.profile.targetRole} based in ${state.profile.currentCountry}, targeting ${state.profile.preferredCountries.join(', ')}. Core skills include ${state.profile.skills.join(', ')}. Portfolio proof includes ${state.projects.map((project) => project.title).join(', ')}.';
    final resumeText = _resumeMarkdown(state, summary);
    final desktop = MediaQuery.sizeOf(context).width >= 980;
    final editor = SectionCard(
      title: 'Profile and resume sections',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DetailRow('Candidate', state.profile.fullName),
          DetailRow('Target role', state.profile.targetRole),
          DetailRow(
            'Links',
            [
              state.profile.githubUrl,
              state.profile.linkedInUrl,
              state.profile.portfolioUrl,
            ].where((item) => item.isNotEmpty).join(' • '),
          ),
          DetailRow(
            'Languages',
            'English ${state.profile.englishLevel}, Japanese ${state.profile.japaneseLevel}, German ${state.profile.germanLevel}',
          ),
          _chipSection(
            'Credentials',
            state.credentials.map((item) => item.title).toList(),
          ),
          _chipSection(
            'Projects',
            state.projects.map((item) => item.title).toList(),
          ),
        ],
      ),
    );
    final preview = SectionCard(
      title: 'Generated preview',
      child: SelectableText(resumeText, style: const TextStyle(height: 1.45)),
    );
    return PageScaffold(
      title: 'Resume Builder',
      subtitle:
          'A clean editor and preview for a truthful, review-ready resume summary.',
      action: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          PrimaryButton(
            icon: Icons.auto_awesome,
            label: 'Generate summary',
            onPressed: () =>
                _copy(context, summary, 'Generated summary copied'),
          ),
          SecondaryButton(
            icon: Icons.copy,
            label: 'Copy summary',
            onPressed: () => _copy(context, summary, 'Summary copied'),
          ),
          SecondaryButton(
            icon: Icons.download_outlined,
            label: 'Download Markdown/TXT',
            onPressed: () => _writeTextFile(
              context,
              _exportFileName(
                state.profile.fullName,
                'resume',
                'profile',
                'md',
              ),
              resumeText,
            ),
          ),
        ],
      ),
      children: [
        if (desktop)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: editor),
              const SizedBox(width: 14),
              Expanded(child: preview),
            ],
          )
        else ...[
          editor,
          preview,
        ],
      ],
    );
  }
}

class ApplicationBuilderScreen extends ConsumerWidget {
  const ApplicationBuilderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final packages = state.applications.values.toList();
    return PageScaffold(
      title: 'Application Builder',
      subtitle:
          'Review-first application packages. WorkBridge prepares drafts; you decide what is sent.',
      children: packages.isEmpty
          ? [
              EmptyState(
                title: 'No applications yet',
                message:
                    'Open an analyzed job and prepare an application package to review CV summary, cover letter, recruiter message, evidence, and risks.',
                icon: Icons.outbox_outlined,
                action: PrimaryButton(
                  icon: Icons.search,
                  label: 'Find a job',
                  onPressed: () => context.go('/jobs'),
                ),
              ),
            ]
          : packages.map((package) {
              final job = state.jobs
                  .where((item) => item.id == package.jobId)
                  .firstOrNull;
              return SectionCard(
                title: job == null
                    ? 'Application package'
                    : '${job.companyName} • ${job.jobTitle}',
                subtitle:
                    'Review before sending. WorkBridge AI can make mistakes. You are responsible for checking your application before sending it.',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const StatusBadge.warning('Review required before sending'),
                    const SizedBox(height: 16),
                    _copyBlock(context, 'CV summary', package.cvSummary),
                    _copyBlock(context, 'Cover letter', package.coverLetter),
                    _copyBlock(
                      context,
                      'Recruiter message',
                      package.recruiterMessage,
                    ),
                    _copyBlock(
                      context,
                      'Skill match explanation',
                      package.skillMatchExplanation,
                    ),
                    _copyBlock(
                      context,
                      'Project evidence',
                      package.projectEvidence,
                    ),
                    _copyBlock(context, 'Risk notes', package.riskNotes),
                    _chipSection(
                      'Final checklist',
                      package.finalChecklist,
                      warning: true,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        SecondaryButton(
                          icon: Icons.copy,
                          label: 'Copy CV Summary',
                          onPressed: () => _copy(
                            context,
                            package.cvSummary,
                            'CV summary copied',
                          ),
                        ),
                        SecondaryButton(
                          icon: Icons.copy,
                          label: 'Copy Cover Letter',
                          onPressed: () => _copy(
                            context,
                            package.coverLetter,
                            'Cover letter copied',
                          ),
                        ),
                        SecondaryButton(
                          icon: Icons.copy,
                          label: 'Copy Recruiter Message',
                          onPressed: () => _copy(
                            context,
                            package.recruiterMessage,
                            'Recruiter message copied',
                          ),
                        ),
                        SecondaryButton(
                          icon: Icons.download_outlined,
                          label: 'Download Application Package',
                          onPressed: job == null
                              ? null
                              : () => _writeTextFile(
                                  context,
                                  _exportFileName(
                                    job.companyName,
                                    job.jobTitle,
                                    state.profile.fullName,
                                    'md',
                                  ),
                                  _applicationMarkdown(package, job),
                                ),
                        ),
                        SecondaryButton(
                          icon: Icons.open_in_new,
                          label: 'Open Job Link',
                          onPressed: job == null
                              ? null
                              : () => _copy(
                                  context,
                                  job.jobUrl,
                                  'Job link copied',
                                ),
                        ),
                        PrimaryButton(
                          icon: Icons.check_circle_outline,
                          label: 'Mark as Applied',
                          onPressed: job == null
                              ? null
                              : () => ref
                                    .read(appStateProvider.notifier)
                                    .markApplied(job.id),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
    );
  }
}

class JobTrackerScreen extends ConsumerWidget {
  const JobTrackerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(appStateProvider).jobs;
    return PageScaffold(
      title: 'Job Tracker',
      subtitle:
          'Manual pipeline tracking for saved, analyzed, applied, interview, offer, and rejected jobs.',
      children: jobs.isEmpty
          ? [
              EmptyState(
                title: 'No saved jobs',
                message:
                    'Discover and save roles to start building a visible application pipeline.',
                icon: Icons.fact_check_outlined,
                action: PrimaryButton(
                  icon: Icons.search,
                  label: 'Discover jobs',
                  onPressed: () => context.go('/jobs'),
                ),
              ),
            ]
          : [
              SectionCard(
                title: 'Pipeline',
                child: Column(
                  children: [
                    for (final job in jobs)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            _CompanyLogo(name: job.companyName),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    job.jobTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${job.companyName} • ${job.country}',
                                    style: const TextStyle(color: mutedText),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 190,
                              child: DropdownButtonFormField<JobStatus>(
                                initialValue: job.status,
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                ),
                                items: JobStatus.values
                                    .map(
                                      (status) => DropdownMenuItem(
                                        value: status,
                                        child: Text(titleCaseEnum(status)),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (status) {
                                  if (status != null) {
                                    ref
                                        .read(appStateProvider.notifier)
                                        .updateJobStatus(job.id, status);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
    );
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final providers = state.settings?.providers ?? const <ProviderSetting>[];
    final providerNames = providers.isEmpty
        ? state.selectedProviders
        : providers.map((item) => item.name).toList();
    return PageScaffold(
      title: 'Settings',
      subtitle:
          'Runtime mode, provider visibility, AI status, theme defaults, and product safety notes.',
      children: [
        SectionCard(
          title: 'App mode and providers',
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: state.useMockSources,
                onChanged: ref
                    .read(appStateProvider.notifier)
                    .toggleMockSources,
                title: const Text('App mode: mock / real'),
                subtitle: Text(
                  state.useMockSources
                      ? 'Mock job data is active.'
                      : 'Real provider mode is selected.',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final provider in providerNames)
                      FilterChip(
                        label: Text(provider),
                        selected: state.selectedProviders.contains(provider),
                        onSelected: (value) => ref
                            .read(appStateProvider.notifier)
                            .toggleProvider(provider, value),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SectionCard(
          title: 'Runtime',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailRow(
                'Environment',
                state.settings?.environment ?? 'development',
              ),
              DetailRow(
                'API base URL',
                state.settings?.apiBaseUrl ?? apiBaseUrl,
              ),
              DetailRow(
                'Real AI',
                state.settings?.useRealAi == true
                    ? 'Enabled'
                    : 'Disabled or API key missing',
              ),
              DetailRow('Theme mode', 'Dark'),
              DetailRow(
                'Storage',
                state.settings?.storage ?? 'Backend unavailable or not loaded',
              ),
              DetailRow(
                'Auth mode',
                state.settings?.requireAuth == true
                    ? 'JWT required'
                    : 'Demo fallback allowed',
              ),
              DetailRow('App version', '1.0.0+1'),
            ],
          ),
        ),
        if (state.settings != null)
          SectionCard(
            title: 'Production readiness',
            subtitle: state.settings!.publicationReadiness.ready
                ? 'Ready'
                : 'Not ready',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                state.settings!.publicationReadiness.ready
                    ? const StatusBadge.success('Ready')
                    : const StatusBadge.warning('Not ready'),
                const SizedBox(height: 12),
                _chipSection(
                  'Blockers',
                  state.settings!.publicationReadiness.blockers,
                  warning: true,
                ),
                _chipSection(
                  'Warnings',
                  state.settings!.publicationReadiness.warnings,
                  warning: true,
                ),
                _chipSection(
                  'Next actions',
                  state.settings!.publicationReadiness.nextActions,
                ),
              ],
            ),
          ),
        if (providers.isNotEmpty)
          SectionCard(
            title: 'Provider status',
            child: Column(
              children: [
                for (final provider in providers)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          provider.status == 'configured' ||
                                  provider.status == 'active'
                              ? Icons.check_circle_outline
                              : provider.status == 'disabled'
                              ? Icons.pause_circle_outline
                              : Icons.warning_amber_outlined,
                          color: provider.status == 'configured' ||
                                  provider.status == 'active'
                              ? const Color(0xff77d17a)
                              : provider.status == 'disabled'
                              ? mutedText
                              : const Color(0xffffd99a),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                provider.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                [
                                  provider.status,
                                  if (provider.requiresApiKey)
                                    'API key required',
                                  if (provider.requiresCompanySlug)
                                    'company slug/token required',
                                  if (provider.companySlugs.isNotEmpty)
                                    'slugs: ${provider.companySlugs.join(', ')}',
                                ].join(' • '),
                                style: const TextStyle(color: mutedText),
                              ),
                              if (provider.warning != null)
                                Text(
                                  provider.warning!,
                                  style: const TextStyle(
                                    color: Color(0xffffd99a),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        const SectionCard(
          title: 'Safety warning',
          child: Text(
            'WorkBridge AI does not automatically apply to jobs, send recruiter messages, or submit employer forms. Review every generated application before sending.',
            style: TextStyle(color: Color(0xffffd99a), height: 1.45),
          ),
        ),
      ],
    );
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final email = TextEditingController(text: 'demo@workbridge.local');
  final password = TextEditingController();
  final fullName = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    fullName.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    return PageScaffold(
      title: 'Auth',
      subtitle: 'JWT session for user-specific profile, jobs, analyses, and applications.',
      children: [
        SectionCard(
          title: state.authUser == null
              ? 'Login or register'
              : 'Signed in as ${state.authUser!.email}',
          child: Column(
            children: [
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fullName,
                decoration: const InputDecoration(labelText: 'Full name'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  PrimaryButton(
                    icon: Icons.login,
                    label: 'Login',
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(appStateProvider.notifier)
                              .login(email.text, password.text),
                  ),
                  SecondaryButton(
                    icon: Icons.person_add_alt,
                    label: 'Register',
                    onPressed: state.isLoading
                        ? null
                        : () => ref
                              .read(appStateProvider.notifier)
                              .register(
                                email.text,
                                password.text,
                                fullName.text,
                              ),
                  ),
                ],
              ),
              if (state.error != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.error!,
                  style: const TextStyle(color: Color(0xffff9f9f)),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

Future<void> showProfileDialog(
  BuildContext context,
  WidgetRef ref,
  UserProfile profile,
) async {
  final fullName = TextEditingController(text: profile.fullName);
  final currentCountry = TextEditingController(text: profile.currentCountry);
  final citizenship = TextEditingController(text: profile.citizenship);
  final targetRole = TextEditingController(text: profile.targetRole);
  final experienceLevel = TextEditingController(text: profile.experienceLevel);
  final years = TextEditingController(text: '${profile.yearsOfExperience}');
  final education = TextEditingController(text: profile.educationLevel);
  final english = TextEditingController(text: profile.englishLevel);
  final japanese = TextEditingController(text: profile.japaneseLevel);
  final korean = TextEditingController(text: profile.koreanLevel);
  final german = TextEditingController(text: profile.germanLevel);
  final otherLanguages = TextEditingController(
    text: profile.otherLanguages.join(', '),
  );
  final skills = TextEditingController(text: profile.skills.join(', '));
  final countries = TextEditingController(
    text: profile.preferredCountries.join(', '),
  );
  final github = TextEditingController(text: profile.githubUrl);
  final linkedIn = TextEditingController(text: profile.linkedInUrl);
  final portfolio = TextEditingController(text: profile.portfolioUrl);
  var needsVisa = profile.needsVisaSponsorship;
  var wantsRelocation = profile.wantsRelocationSupport;
  var wantsHousing = profile.wantsHousingSupport;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Edit profile'),
        content: SizedBox(
          width: 760,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field(fullName, 'Personal info'),
                _field(targetRole, 'Target role'),
                _field(currentCountry, 'Current country'),
                _field(citizenship, 'Citizenship'),
                _field(experienceLevel, 'Experience'),
                _field(years, 'Years of experience'),
                _field(education, 'Education'),
                _field(english, 'English'),
                _field(japanese, 'Japanese'),
                _field(korean, 'Korean'),
                _field(german, 'German'),
                _field(otherLanguages, 'Other languages'),
                _field(skills, 'Skills', width: 532),
                _field(countries, 'Target countries', width: 532),
                _field(github, 'GitHub URL'),
                _field(linkedIn, 'LinkedIn URL'),
                _field(portfolio, 'Portfolio URL'),
                SizedBox(
                  width: 720,
                  child: CheckboxListTile(
                    value: needsVisa,
                    onChanged: (value) =>
                        setState(() => needsVisa = value ?? false),
                    title: const Text('Needs visa sponsorship'),
                  ),
                ),
                SizedBox(
                  width: 720,
                  child: CheckboxListTile(
                    value: wantsRelocation,
                    onChanged: (value) =>
                        setState(() => wantsRelocation = value ?? false),
                    title: const Text('Wants relocation support'),
                  ),
                ),
                SizedBox(
                  width: 720,
                  child: CheckboxListTile(
                    value: wantsHousing,
                    onChanged: (value) =>
                        setState(() => wantsHousing = value ?? false),
                    title: const Text('Wants housing support'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(appStateProvider.notifier)
                  .saveProfile(
                    UserProfile(
                      id: profile.id,
                      fullName: fullName.text,
                      currentCountry: currentCountry.text,
                      citizenship: citizenship.text,
                      targetRole: targetRole.text,
                      experienceLevel: experienceLevel.text,
                      yearsOfExperience: int.tryParse(years.text) ?? 0,
                      educationLevel: education.text,
                      englishLevel: english.text,
                      japaneseLevel: japanese.text,
                      koreanLevel: korean.text,
                      germanLevel: german.text,
                      otherLanguages: _csv(otherLanguages.text),
                      skills: _csv(skills.text),
                      preferredCountries: _csv(countries.text),
                      preferredWorkModes: profile.preferredWorkModes,
                      needsVisaSponsorship: needsVisa,
                      wantsRelocationSupport: wantsRelocation,
                      wantsHousingSupport: wantsHousing,
                      githubUrl: github.text,
                      linkedInUrl: linkedIn.text,
                      portfolioUrl: portfolio.text,
                      createdAt: profile.createdAt,
                      updatedAt: DateTime.now(),
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showCredentialDialog(
  BuildContext context,
  WidgetRef ref, [
  Credential? credential,
]) async {
  final item = credential;
  final title = TextEditingController(text: item?.title ?? '');
  final provider = TextEditingController(text: item?.provider ?? '');
  final verification = TextEditingController(text: item?.verificationUrl ?? '');
  final fileName = TextEditingController(text: item?.fileName ?? '');
  final notes = TextEditingController(text: item?.notes ?? '');
  var type = item?.type ?? CredentialType.programming;
  var trust = item?.trustLevel ?? TrustLevel.unverified;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(item == null ? 'Add credential' : 'Edit credential'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field(title, 'Certificate title'),
                _field(provider, 'Provider'),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField(
                    initialValue: type,
                    items: CredentialType.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(titleCaseEnum(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) => setState(() => type = value ?? type),
                    decoration: const InputDecoration(labelText: 'Type'),
                  ),
                ),
                SizedBox(
                  width: 260,
                  child: DropdownButtonFormField(
                    initialValue: trust,
                    items: TrustLevel.values
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(titleCaseEnum(value)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => trust = value ?? trust),
                    decoration: const InputDecoration(labelText: 'Trust level'),
                  ),
                ),
                _field(verification, 'Verification URL'),
                _field(fileName, 'File name'),
                _field(notes, 'Notes', width: 532),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = Credential(
                id: item?.id ?? '',
                title: title.text,
                provider: provider.text,
                type: type,
                trustLevel: trust,
                verificationUrl: verification.text,
                fileName: fileName.text,
                notes: notes.text,
              );
              item == null
                  ? ref.read(appStateProvider.notifier).createCredential(value)
                  : ref.read(appStateProvider.notifier).updateCredential(value);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Future<void> showProjectDialog(
  BuildContext context,
  WidgetRef ref, [
  PortfolioProject? project,
]) async {
  final item = project;
  final title = TextEditingController(text: item?.title ?? '');
  final description = TextEditingController(text: item?.description ?? '');
  final techStack = TextEditingController(
    text: item?.techStack.join(', ') ?? '',
  );
  final proofSkills = TextEditingController(
    text: item?.proofSkills.join(', ') ?? '',
  );
  final github = TextEditingController(text: item?.githubUrl ?? '');
  final demo = TextEditingController(text: item?.demoUrl ?? '');
  final appStore = TextEditingController(text: item?.appStoreUrl ?? '');
  final screenshots = TextEditingController(
    text: item?.screenshots.join(', ') ?? '',
  );
  final notes = TextEditingController(text: item?.notes ?? '');
  var hasTests = item?.hasTests ?? false;
  var hasCiCd = item?.hasCiCd ?? false;
  await showDialog<void>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(item == null ? 'Add project' : 'Edit project'),
        content: SizedBox(
          width: 680,
          child: SingleChildScrollView(
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _field(title, 'Title'),
                _field(description, 'Description', width: 592),
                _field(techStack, 'Tech stack chips'),
                _field(proofSkills, 'Proof skills'),
                _field(github, 'GitHub link'),
                _field(demo, 'Demo link'),
                _field(appStore, 'App store URL'),
                _field(screenshots, 'Screenshots'),
                _field(notes, 'Notes', width: 592),
                SizedBox(
                  width: 280,
                  child: CheckboxListTile(
                    value: hasTests,
                    onChanged: (value) =>
                        setState(() => hasTests = value ?? false),
                    title: const Text('Has tests'),
                  ),
                ),
                SizedBox(
                  width: 280,
                  child: CheckboxListTile(
                    value: hasCiCd,
                    onChanged: (value) =>
                        setState(() => hasCiCd = value ?? false),
                    title: const Text('Has CI/CD'),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final value = PortfolioProject(
                id: item?.id ?? '',
                title: title.text,
                description: description.text,
                techStack: _csv(techStack.text),
                proofSkills: _csv(proofSkills.text),
                githubUrl: github.text,
                demoUrl: demo.text,
                appStoreUrl: appStore.text,
                screenshots: _csv(screenshots.text),
                hasTests: hasTests,
                hasCiCd: hasCiCd,
                notes: notes.text,
              );
              item == null
                  ? ref.read(appStateProvider.notifier).createProject(value)
                  : ref.read(appStateProvider.notifier).updateProject(value);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
}

Widget _field(
  TextEditingController controller,
  String label, {
  String? hint,
  double width = 260,
}) {
  return SizedBox(
    width: width,
    child: TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, hintText: hint),
    ),
  );
}

Widget _chipSection(String label, List<String> values, {bool warning = false}) {
  if (values.isEmpty) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        '$label: Not provided',
        style: const TextStyle(color: mutedText),
      ),
    );
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: values
              .map((item) => SkillChip(item, warning: warning))
              .toList(),
        ),
      ],
    ),
  );
}

Widget _copyBlock(BuildContext context, String label, String text) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            IconButton(
              tooltip: 'Copy $label',
              onPressed: () => _copy(context, text, '$label copied'),
              icon: const Icon(Icons.copy),
            ),
          ],
        ),
        SelectableText(
          text.isEmpty ? 'Not generated' : text,
          style: const TextStyle(color: Color(0xffd7e3ef), height: 1.45),
        ),
      ],
    ),
  );
}

class _CompanyLogo extends StatelessWidget {
  const _CompanyLogo({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();
    return Container(
      width: 46,
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xff10293b),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xff2e526d)),
      ),
      child: Text(
        initials.isEmpty ? 'WB' : initials,
        style: const TextStyle(fontWeight: FontWeight.w900, color: accentColor),
      ),
    );
  }
}

StatusBadge _trustBadge(TrustLevel level) {
  return switch (level) {
    TrustLevel.high => const StatusBadge.success('High trust'),
    TrustLevel.medium => const StatusBadge.warning('Medium trust'),
    TrustLevel.low => const StatusBadge.danger('Low trust'),
    TrustLevel.unverified => const StatusBadge('Unverified'),
  };
}

List<String> _csv(String value) => value
    .split(',')
    .map((item) => item.trim())
    .where((item) => item.isNotEmpty)
    .toList();

String _dateLabel(DateTime? date) =>
    date == null ? 'Not provided' : date.toIso8601String().split('T').first;

void _copy(BuildContext context, String text, String message) {
  Clipboard.setData(ClipboardData(text: text));
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Future<void> _writeTextFile(
  BuildContext context,
  String fileName,
  String content,
) async {
  final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9_.-]'), '_');
  try {
    final baseDir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${baseDir.path}/WorkBridgeAI');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    final file = File('${exportDir.path}/$safeName');
    await file.writeAsString(content);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved ${file.path}')));
    }
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    }
  }
}

String _exportFileName(
  String primary,
  String secondary,
  String owner,
  String extension,
) {
  final date = DateTime.now().toIso8601String().split('T').first;
  final raw = ['workbridge', owner, primary, secondary, date]
      .where((item) => item.trim().isNotEmpty)
      .join('_')
      .toLowerCase();
  return '$raw.$extension';
}

String _resumeMarkdown(WorkBridgeState state, String summary) {
  return [
    '# ${state.profile.fullName}',
    summary,
    '',
    '## Skills',
    state.profile.skills.join(', '),
    '',
    '## Languages',
    'English ${state.profile.englishLevel}, Japanese ${state.profile.japaneseLevel}, Korean ${state.profile.koreanLevel}, German ${state.profile.germanLevel}, ${state.profile.otherLanguages.join(', ')}',
    '',
    '## Credentials',
    ...state.credentials.map(
      (item) =>
          '- ${item.title} (${item.provider}, ${titleCaseEnum(item.trustLevel)}) ${item.verificationUrl.isEmpty ? 'No verification URL provided.' : item.verificationUrl}',
    ),
    '',
    '## Portfolio',
    ...state.projects.map(
      (item) =>
          '- ${item.title}: ${item.description} Proof: ${item.proofSkills.join(', ')} GitHub: ${item.githubUrl}',
    ),
  ].join('\n');
}

String _applicationMarkdown(ApplicationPackage package, JobPosting job) {
  return [
    '# ${job.companyName} - ${job.jobTitle}',
    'Job link: ${job.jobUrl}',
    '',
    '## CV Summary',
    package.cvSummary,
    '',
    '## Cover Letter',
    package.coverLetter,
    '',
    '## Recruiter Message',
    package.recruiterMessage,
    '',
    '## Skill Match',
    package.skillMatchExplanation,
    '',
    '## Project Evidence',
    package.projectEvidence,
    '',
    '## Risk Notes',
    package.riskNotes,
    '',
    '## Final Checklist',
    ...package.finalChecklist.map((item) => '- $item'),
    '',
    'Review before sending. WorkBridge AI can make mistakes. You are responsible for checking your application before sending it.',
  ].join('\n');
}
