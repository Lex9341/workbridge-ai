import { Injectable } from '@nestjs/common';

import type {
  AnalyzerConfidence,
  AnalyzerSource,
  ApplicationPackage,
  CompanySupport,
  Credential,
  EligibilityAnalysis,
  EligibilityDecision,
  JobPosting,
  ParsedJobRequirements,
  PortfolioProject,
  SupportValue,
  UserProfile,
  WorkMode
} from './domain';

const nowIso = () => new Date().toISOString();

const skillKeywords = [
  'Flutter',
  'Dart',
  'React',
  'TypeScript',
  'JavaScript',
  'Node.js',
  'NestJS',
  'Python',
  'Django',
  'Java',
  'Spring',
  'Kotlin',
  'Swift',
  'PostgreSQL',
  'MySQL',
  'MongoDB',
  'Docker',
  'Kubernetes',
  'AWS',
  'GCP',
  'Azure',
  'Firebase',
  'CI/CD',
  'GitHub Actions',
  'REST API',
  'GraphQL',
  'Testing',
  'QA Automation',
  'Selenium',
  'Playwright'
];

@Injectable()
export class LocalAnalyzerService {
  private metadata = {
    source: 'rule_based' as AnalyzerSource,
    fallbackUsed: false,
    confidence: 'medium' as AnalyzerConfidence
  };

  async parse(job: JobPosting): Promise<ParsedJobRequirements> {
    const aiParsed = await this.parseWithAi(job);
    if (aiParsed) {
      this.metadata = { source: 'real_ai', fallbackUsed: false, confidence: confidenceFor(aiParsed) };
      return aiParsed;
    }
    this.metadata = {
      source: 'rule_based',
      fallbackUsed: process.env.USE_REAL_AI === 'true' && Boolean(process.env.OPENAI_API_KEY || process.env.AI_API_KEY),
      confidence: 'medium'
    };
    return this.parseLocally(job);
  }

  getMetadata() {
    return this.metadata;
  }

  parseLocally(job: JobPosting): ParsedJobRequirements {
    const lower = job.rawDescription.toLowerCase();
    const requiredSkills = skillKeywords.filter((skill) => lower.includes(skill.toLowerCase()));
    const preferredSkills = requiredSkills.filter((skill) =>
      lower.includes(`${skill.toLowerCase()} helpful`) || lower.includes(`${skill.toLowerCase()} preferred`)
    );
    const visaProvided = containsAny(lower, [
      'visa sponsorship',
      'work visa',
      'work permit',
      'certificate of eligibility',
      'immigration support'
    ]);
    const visaDenied = containsAny(lower, ['no visa sponsorship', 'must already have work authorization']);
    const relocation = containsAny(lower, ['relocation support', 'relocation package']);
    const housing = containsAny(lower, [
      'housing provided',
      'temporary accommodation',
      'accommodation provided',
      'housing allowance',
      'apartment support',
      'company dormitory'
    ]);
    const companySupport: CompanySupport = {
      visaSponsorship: support(visaProvided, visaDenied),
      workPermitSupport: support(visaProvided, visaDenied),
      relocationPackage: relocation ? 'provided' : 'notMentioned',
      flightTicket: lower.includes('flight') ? 'mentioned' : 'notMentioned',
      temporaryHousing: housing ? 'provided' : 'notMentioned',
      housingAllowance: housing ? 'provided' : 'notMentioned',
      apartmentSearchSupport: lower.includes('apartment') ? 'mentioned' : 'notMentioned',
      healthInsurance: lower.includes('health insurance') ? 'provided' : 'notMentioned',
      socialInsurance: lower.includes('social insurance') ? 'provided' : 'notMentioned',
      equipmentProvided: lower.includes('equipment') ? 'provided' : 'notMentioned',
      remoteWorkSupport: job.workMode === 'remote' ? 'mentioned' : 'notMentioned',
      languageClasses: lower.includes('language classes') ? 'provided' : 'notMentioned',
      familyRelocation: lower.includes('family relocation') ? 'mentioned' : 'notMentioned',
      salaryRange: job.salaryRange,
      bonus: lower.includes('bonus') ? 'mentioned' : 'notMentioned',
      stockOptions: lower.includes('stock') ? 'mentioned' : 'notMentioned',
      taxSupport: lower.includes('tax support') ? 'mentioned' : 'notMentioned'
    };

    return {
      requiredSkills,
      preferredSkills,
      experienceLevel: lower.includes('senior') || lower.includes('5+ years') ? 'senior' : 'junior-mid',
      languageRequirements: extractLanguages(lower),
      educationRequirements: lower.includes('degree') ? ['degree mentioned'] : [],
      certificateRequirements: lower.includes('certificate') ? ['certificate mentioned'] : [],
      visaSponsorship: companySupport.visaSponsorship,
      workPermitSupport: companySupport.workPermitSupport,
      relocationSupport: companySupport.relocationPackage,
      housingSupport: housing ? 'provided' : 'notMentioned',
      flightTicket: companySupport.flightTicket,
      healthInsurance: companySupport.healthInsurance,
      salaryRange: job.salaryRange,
      workMode: inferWorkMode(lower, job.workMode),
      locationRestrictions: lower.includes('work authorization') ? ['local work authorization mentioned'] : [],
      companySupport
    };
  }

  private async parseWithAi(job: JobPosting): Promise<ParsedJobRequirements | undefined> {
    const apiKey = process.env.OPENAI_API_KEY || process.env.AI_API_KEY;
    if (process.env.USE_REAL_AI !== 'true' || !apiKey) return undefined;
    try {
      const response = await fetch('https://api.openai.com/v1/chat/completions', {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${apiKey}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          model: process.env.OPENAI_MODEL ?? 'gpt-4o-mini',
          response_format: { type: 'json_object' },
          messages: [
            {
              role: 'system',
              content:
                'Extract IT job requirements as strict JSON. Do not infer company support unless explicitly stated. Use provided, notProvided, mentioned, notMentioned, or unclear for support values.'
            },
            {
              role: 'user',
              content: JSON.stringify({
                title: job.jobTitle,
                company: job.companyName,
                country: job.country,
                workMode: job.workMode,
                salaryRange: job.salaryRange,
                description: job.rawDescription,
                schemaKeys: [
                  'requiredSkills',
                  'preferredSkills',
                  'experienceLevel',
                  'languageRequirements',
                  'educationRequirements',
                  'certificateRequirements',
                  'visaSponsorship',
                  'workPermitSupport',
                  'relocationSupport',
                  'housingSupport',
                  'flightTicket',
                  'healthInsurance',
                  'salaryRange',
                  'workMode',
                  'locationRestrictions',
                  'companySupport'
                ]
              })
            }
          ]
        })
      });
      if (!response.ok) return undefined;
      const data = (await response.json()) as { choices?: Array<{ message?: { content?: string } }> };
      const parsed = JSON.parse(data.choices?.[0]?.message?.content ?? '{}') as Partial<ParsedJobRequirements>;
      return normalizeParsedRequirements(parsed, job);
    } catch {
      return undefined;
    }
  }
}

@Injectable()
export class EligibilityService {
  constructor(private readonly analyzer: LocalAnalyzerService) {}

  async analyze(
    profile: UserProfile,
    credentials: Credential[],
    projects: PortfolioProject[],
    job: JobPosting
  ): Promise<EligibilityAnalysis> {
    const parsed = await this.analyzer.parse(job);
    const matchedSkills = parsed.requiredSkills.filter((skill) => profile.skills.includes(skill));
    const missingSkills = parsed.requiredSkills.filter((skill) => !profile.skills.includes(skill));
    const proofSkills = new Set(projects.flatMap((project) => project.proofSkills));
    const credentialText = credentials.map((credential) => `${credential.title} ${credential.notes}`).join(' ');
    const missingProof = matchedSkills.filter(
      (skill) => !proofSkills.has(skill) && !credentialText.toLowerCase().includes(skill.toLowerCase())
    );

    const skillsScore = parsed.requiredSkills.length
      ? Math.round((matchedSkills.length / parsed.requiredSkills.length) * 100)
      : 60;
    const experienceScore = parsed.experienceLevel === 'senior' && profile.yearsOfExperience < 4 ? 35 : 80;
    const languageScore = languageScoreFor(profile, parsed.languageRequirements);
    const visaScore = visaScoreFor(profile, parsed);
    const locationScore = locationScoreFor(profile, job, parsed.workMode);
    const companySupportScore = supportScore(profile, parsed.companySupport);
    const overallMatchScore = Math.round(
      skillsScore * 0.32 +
        experienceScore * 0.18 +
        languageScore * 0.15 +
        visaScore * 0.18 +
        locationScore * 0.12 +
        companySupportScore * 0.05
    );

    const visaBlocker = profile.needsVisaSponsorship && parsed.visaSponsorship === 'notProvided';
    const localAuthorizationBlocker =
      parsed.locationRestrictions.length > 0 && profile.currentCountry !== job.country && job.workMode !== 'remote';
    const seniorBlocker = parsed.experienceLevel === 'senior' && profile.yearsOfExperience < 2;
    const locationBlocker = locationScore < 55;
    const unclear = profile.needsVisaSponsorship && parsed.visaSponsorship === 'unclear';
    const criticalBlocker = visaBlocker || localAuthorizationBlocker || seniorBlocker || locationBlocker;
    const decision: EligibilityDecision = unclear
      ? 'unclear'
      : criticalBlocker || overallMatchScore < 55
        ? 'notEligible'
        : overallMatchScore >= 80
          ? 'eligible'
          : 'almostEligible';
    const risks = [
      ...(visaBlocker ? ['User needs visa sponsorship, but the job appears to reject sponsorship.'] : []),
      ...(localAuthorizationBlocker ? ['Local work authorization may be required.'] : []),
      ...(seniorBlocker ? ['The role appears senior compared with the user profile.'] : []),
      ...(missingSkills.length ? [`Missing skills: ${missingSkills.join(', ')}.`] : []),
      ...(missingProof.length ? [`Missing proof: ${missingProof.join(', ')}.`] : [])
    ];
    const now = nowIso();
    const metadata = this.analyzer.getMetadata();

    return {
      id: `analysis-${job.id}`,
      jobId: job.id,
      overallMatchScore,
      skillsScore,
      experienceScore,
      languageScore,
      visaScore,
      locationScore,
      companySupportScore,
      decision,
      matchedSkills,
      missingSkills,
      missingProof,
      languageRequirements: parsed.languageRequirements,
      visaStatus: supportSentence('Visa sponsorship', parsed.visaSponsorship),
      relocationStatus: supportSentence('Relocation', parsed.relocationSupport),
      locationRestrictions: parsed.locationRestrictions,
      degreeRequirements: parsed.educationRequirements,
      companySupport: parsed.companySupport,
      risks,
      actionPlan: [
        ...(missingSkills.length ? [`Build targeted evidence for ${missingSkills.slice(0, 3).join(', ')}.`] : []),
        ...(missingProof.length ? [`Add portfolio or credential proof for ${missingProof.slice(0, 3).join(', ')}.`] : []),
        'Confirm visa, work authorization and relocation terms before manually applying.'
      ],
      explanation:
        metadata.source === 'real_ai'
          ? 'Real AI parsing produced structured requirements, then eligibility scoring compared them against profile, credentials, portfolio proof and relocation needs.'
          : 'Local rule-based analysis compared job requirements against the profile, credentials, portfolio proof and relocation needs.',
      summary: `Matched ${matchedSkills.length}/${parsed.requiredSkills.length} detected skills with overall score ${overallMatchScore}.`,
      parsedRequirements: parsed,
      source: metadata.source,
      fallbackUsed: metadata.fallbackUsed,
      confidence: metadata.confidence,
      missingInformationQuestions: missingInformationQuestions(parsed),
      createdAt: now,
      updatedAt: now
    };
  }
}

@Injectable()
export class ApplicationBuilderService {
  generate(
    profile: UserProfile,
    projects: PortfolioProject[],
    job: JobPosting,
    analysis: EligibilityAnalysis
  ): ApplicationPackage {
    const now = nowIso();
    const projectEvidence = projects
      .map(
        (project) =>
          `${project.title}: ${project.description} Proof skills: ${project.proofSkills.join(', ')}. GitHub: ${project.githubUrl}`
      )
      .join('\n');
    return {
      id: `application-${job.id}`,
      jobId: job.id,
      cvSummary: `${profile.fullName} is a ${profile.targetRole} with ${profile.yearsOfExperience} years of experience and portfolio evidence in ${profile.skills.slice(0, 8).join(', ')}. Target markets: ${profile.preferredCountries.join(', ')}.`,
      coverLetter: `Dear ${job.companyName} team,\n\nI am interested in the ${job.jobTitle} role. My strongest matches are ${analysis.matchedSkills.join(', ') || 'the role domain and project background'}. ${analysis.missingSkills.length ? `I am currently strengthening ${analysis.missingSkills.join(', ')} and will describe my level honestly.` : 'I can provide portfolio evidence for the detected core requirements.'}\n\nPlease confirm visa and relocation details for candidates based in ${profile.currentCountry}.\n\nKind regards,\n${profile.fullName}`,
      recruiterMessage: `Hello, I am interested in ${job.companyName}'s ${job.jobTitle} role. Relevant skills: ${analysis.matchedSkills.join(', ')}. Could you confirm visa sponsorship and relocation support before I send the full application?`,
      skillMatchExplanation: `Matched skills: ${analysis.matchedSkills.join(', ') || 'none detected'}. Missing skills: ${analysis.missingSkills.join(', ') || 'none detected'}. Missing proof: ${analysis.missingProof.join(', ') || 'none detected'}.`,
      projectEvidence,
      riskNotes: analysis.risks.length ? analysis.risks.join('\n') : 'No major risks detected by the local analyzer.',
      finalChecklist: [
        'Review every statement for truthfulness.',
        'Confirm visa and relocation details.',
        'Attach portfolio and credential evidence.',
        'Manually send the application outside WorkBridge AI.'
      ],
      createdAt: now,
      updatedAt: now
    };
  }
}

function containsAny(text: string, terms: string[]): boolean {
  return terms.some((term) => text.includes(term));
}

function support(provided: boolean, denied: boolean): SupportValue {
  if (provided) return 'provided';
  if (denied) return 'notProvided';
  return 'unclear';
}

function extractLanguages(lower: string): string[] {
  return ['English', 'Japanese', 'Korean', 'German', 'N5', 'N4', 'N3', 'N2', 'N1', 'TOPIK', 'IELTS', 'TOEFL', 'CEFR', 'B1', 'B2', 'C1'].filter(
    (language) => lower.includes(language.toLowerCase())
  );
}

function inferWorkMode(lower: string, fallback: WorkMode): WorkMode {
  if (lower.includes('remote')) return 'remote';
  if (lower.includes('hybrid')) return 'hybrid';
  if (lower.includes('onsite') || lower.includes('on-site')) return 'onsite';
  return fallback;
}

function languageScoreFor(profile: UserProfile, requirements: string[]): number {
  const required = requirements.map((item) => item.toLowerCase());
  if (required.includes('japanese') && !['N3', 'N2', 'N1'].includes(profile.japaneseLevel)) return 45;
  if (required.includes('german') && !['B1', 'B2', 'C1'].includes(profile.germanLevel)) return 55;
  if (required.includes('english') && ['B2', 'C1', 'C2'].includes(profile.englishLevel)) return 90;
  return requirements.length ? 75 : 80;
}

function visaScoreFor(profile: UserProfile, parsed: ParsedJobRequirements): number {
  if (!profile.needsVisaSponsorship) return 90;
  if (parsed.visaSponsorship === 'provided') return 90;
  if (parsed.visaSponsorship === 'notProvided') return 0;
  return 45;
}

function locationScoreFor(profile: UserProfile, job: JobPosting, workMode: WorkMode): number {
  if (profile.preferredCountries.includes(job.country)) return 90;
  if (job.country === 'Unclear' && workMode === 'remote') return 60;
  return 25;
}

function supportScore(profile: UserProfile, supportValues: CompanySupport): number {
  let score = 40;
  if (profile.needsVisaSponsorship && supportValues.visaSponsorship === 'provided') score += 30;
  if (profile.wantsRelocationSupport && supportValues.relocationPackage === 'provided') score += 20;
  if (profile.wantsHousingSupport && supportValues.temporaryHousing === 'provided') score += 10;
  return Math.min(score, 100);
}

function supportSentence(label: string, value: SupportValue): string {
  if (value === 'provided') return `${label} is provided or clearly mentioned.`;
  if (value === 'notProvided') return `${label} appears not to be provided.`;
  if (value === 'mentioned') return `${label} is mentioned but not fully confirmed.`;
  if (value === 'notMentioned') return `${label} is not mentioned.`;
  return `${label} is unclear.`;
}

function normalizeParsedRequirements(input: Partial<ParsedJobRequirements>, job: JobPosting): ParsedJobRequirements {
  const base = new LocalAnalyzerService().parseLocally(job);
  const companySupport = {
    ...base.companySupport,
    ...(input.companySupport ?? {})
  };
  return {
    ...base,
    ...input,
    requiredSkills: list(input.requiredSkills, base.requiredSkills),
    preferredSkills: list(input.preferredSkills, base.preferredSkills),
    languageRequirements: list(input.languageRequirements, base.languageRequirements),
    educationRequirements: list(input.educationRequirements, base.educationRequirements),
    certificateRequirements: list(input.certificateRequirements, base.certificateRequirements),
    locationRestrictions: list(input.locationRestrictions, base.locationRestrictions),
    visaSponsorship: supportValue(input.visaSponsorship, base.visaSponsorship),
    workPermitSupport: supportValue(input.workPermitSupport, base.workPermitSupport),
    relocationSupport: supportValue(input.relocationSupport, base.relocationSupport),
    housingSupport: supportValue(input.housingSupport, base.housingSupport),
    flightTicket: supportValue(input.flightTicket, base.flightTicket),
    healthInsurance: supportValue(input.healthInsurance, base.healthInsurance),
    workMode: input.workMode ?? base.workMode,
    salaryRange: input.salaryRange ?? base.salaryRange,
    companySupport: {
      visaSponsorship: supportValue(companySupport.visaSponsorship, base.companySupport.visaSponsorship),
      workPermitSupport: supportValue(companySupport.workPermitSupport, base.companySupport.workPermitSupport),
      relocationPackage: supportValue(companySupport.relocationPackage, base.companySupport.relocationPackage),
      flightTicket: supportValue(companySupport.flightTicket, base.companySupport.flightTicket),
      temporaryHousing: supportValue(companySupport.temporaryHousing, base.companySupport.temporaryHousing),
      housingAllowance: supportValue(companySupport.housingAllowance, base.companySupport.housingAllowance),
      apartmentSearchSupport: supportValue(companySupport.apartmentSearchSupport, base.companySupport.apartmentSearchSupport),
      healthInsurance: supportValue(companySupport.healthInsurance, base.companySupport.healthInsurance),
      socialInsurance: supportValue(companySupport.socialInsurance, base.companySupport.socialInsurance),
      equipmentProvided: supportValue(companySupport.equipmentProvided, base.companySupport.equipmentProvided),
      remoteWorkSupport: supportValue(companySupport.remoteWorkSupport, base.companySupport.remoteWorkSupport),
      languageClasses: supportValue(companySupport.languageClasses, base.companySupport.languageClasses),
      familyRelocation: supportValue(companySupport.familyRelocation, base.companySupport.familyRelocation),
      salaryRange: companySupport.salaryRange || base.companySupport.salaryRange,
      bonus: supportValue(companySupport.bonus, base.companySupport.bonus),
      stockOptions: supportValue(companySupport.stockOptions, base.companySupport.stockOptions),
      taxSupport: supportValue(companySupport.taxSupport, base.companySupport.taxSupport)
    }
  };
}

function confidenceFor(parsed: ParsedJobRequirements): 'low' | 'medium' | 'high' {
  const unclearCount = [
    parsed.visaSponsorship,
    parsed.workPermitSupport,
    parsed.relocationSupport,
    parsed.housingSupport,
    parsed.flightTicket,
    parsed.healthInsurance
  ].filter((item) => item === 'unclear' || item === 'notMentioned').length;
  if (parsed.requiredSkills.length === 0 || unclearCount >= 5) return 'low';
  if (unclearCount >= 3) return 'medium';
  return 'high';
}

function missingInformationQuestions(parsed: ParsedJobRequirements): string[] {
  return [
    ...(parsed.visaSponsorship === 'unclear' || parsed.visaSponsorship === 'notMentioned'
      ? ['Does the employer provide visa sponsorship for this country and role?']
      : []),
    ...(parsed.relocationSupport === 'unclear' || parsed.relocationSupport === 'notMentioned'
      ? ['Is relocation support available, and what costs are covered?']
      : []),
    ...(parsed.housingSupport === 'unclear' || parsed.housingSupport === 'notMentioned'
      ? ['Is temporary housing, housing allowance, or apartment search support available?']
      : []),
    ...(!parsed.salaryRange ? ['What is the salary range and compensation structure?'] : []),
    ...(parsed.workMode === 'unknown' ? ['Is the role remote, hybrid, or onsite, and are international remote candidates eligible?'] : []),
    ...(parsed.locationRestrictions.length > 0 ? ['Does the role require existing local work authorization?'] : []),
    ...(parsed.languageRequirements.length === 0 ? ['What language level is required for daily work and interviews?'] : [])
  ];
}

function list(value: unknown, fallback: string[]): string[] {
  return Array.isArray(value) ? value.map(String).filter(Boolean) : fallback;
}

function supportValue(value: unknown, fallback: SupportValue): SupportValue {
  return ['provided', 'notProvided', 'mentioned', 'notMentioned', 'unclear'].includes(String(value))
    ? (value as SupportValue)
    : fallback;
}
