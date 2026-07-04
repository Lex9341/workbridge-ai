import 'package:flutter/material.dart';

import '../models.dart';

const pageMaxWidth = 1280.0;
const mutedText = Color(0xff8fa3b8);
const borderColor = Color(0xff223041);
const cardColor = Color(0xff111823);
const successColor = Color(0xff46d39a);
const warningColor = Color(0xffffc15a);
const dangerColor = Color(0xffff6b6b);
const accentColor = Color(0xff55c7ff);

class PageScaffold extends StatelessWidget {
  const PageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
    this.action,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.all(
          MediaQuery.sizeOf(context).width < 700 ? 16 : 28,
        ),
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: pageMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Header(title: title, subtitle: subtitle, action: action),
                  const SizedBox(height: 24),
                  ...children.map(
                    (child) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Header extends StatelessWidget {
  const Header({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 14,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: mutedText, height: 1.45),
              ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.minItemWidth = 240,
  });

  final List<Widget> children;
  final double minItemWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = (constraints.maxWidth / minItemWidth).floor().clamp(
          1,
          4,
        );
        return GridView.count(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: columns == 1 ? 3.5 : 1.45,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: children,
        );
      },
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            color: mutedText,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.detail,
    this.color = accentColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? detail;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: mutedText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
            ),
            if (detail != null) ...[
              const SizedBox(height: 6),
              Text(
                detail!,
                style: const TextStyle(color: mutedText, fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.tone = BadgeTone.neutral});
  const StatusBadge.success(this.label, {super.key}) : tone = BadgeTone.success;
  const StatusBadge.warning(this.label, {super.key}) : tone = BadgeTone.warning;
  const StatusBadge.danger(this.label, {super.key}) : tone = BadgeTone.danger;
  const StatusBadge.info(this.label, {super.key}) : tone = BadgeTone.info;

  final String label;
  final BadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      BadgeTone.success => (successColor, const Color(0xff0d3326)),
      BadgeTone.warning => (warningColor, const Color(0xff3a2a10)),
      BadgeTone.danger => (dangerColor, const Color(0xff3a161b)),
      BadgeTone.info => (accentColor, const Color(0xff10293b)),
      BadgeTone.neutral => (mutedText, const Color(0xff182231)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.$2,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: colors.$1.withValues(alpha: .55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.$1,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum BadgeTone { success, warning, danger, info, neutral }

class SkillChip extends StatelessWidget {
  const SkillChip(this.label, {super.key, this.warning = false});

  final String label;
  final bool warning;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: warning
          ? const Color(0xff2f2617)
          : const Color(0xff142536),
      side: BorderSide(
        color: warning ? const Color(0xff765a2a) : const Color(0xff2e526d),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    required this.icon,
    this.action,
  });

  final String title;
  final String message;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 540),
          child: Column(
            children: [
              Icon(icon, color: accentColor, size: 38),
              const SizedBox(height: 12),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: mutedText, height: 1.45),
              ),
              if (action != null) ...[const SizedBox(height: 18), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.message = 'Loading WorkBridge data'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: message,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LinearProgressIndicator(minHeight: 3),
          SizedBox(height: 14),
          SkeletonLine(width: 360),
          SizedBox(height: 8),
          SkeletonLine(width: 260),
        ],
      ),
    );
  }
}

class SkeletonLine extends StatelessWidget {
  const SkeletonLine({super.key, required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: 12,
      decoration: BoxDecoration(
        color: const Color(0xff1a2533),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Connection or provider issue',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_outlined, color: warningColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '$message\nCheck the backend, provider configuration, or API key. WorkBridge will keep existing local data visible.',
              style: const TextStyle(color: Color(0xffffd99a), height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }
}

class DetailRow extends StatelessWidget {
  const DetailRow(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(
                color: mutedText,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(value.isEmpty ? 'Not provided' : value),
          ),
        ],
      ),
    );
  }
}

StatusBadge decisionBadge(EligibilityDecision? decision) {
  return switch (decision) {
    EligibilityDecision.eligible => const StatusBadge.success('Eligible'),
    EligibilityDecision.almostEligible => const StatusBadge.warning(
      'Almost eligible',
    ),
    EligibilityDecision.notEligible => const StatusBadge.danger('Not eligible'),
    EligibilityDecision.unclear => const StatusBadge.info('Unclear'),
    null => const StatusBadge.info('Unclear'),
  };
}

StatusBadge supportBadge(String label, SupportValue value) {
  return switch (value) {
    SupportValue.provided => StatusBadge.success(label),
    SupportValue.mentioned => StatusBadge.info(label),
    SupportValue.notProvided => StatusBadge.danger(label),
    SupportValue.notMentioned => StatusBadge(label),
    SupportValue.unclear => StatusBadge.info(label),
  };
}

String titleCaseEnum(Enum value) {
  final text = value.name
      .replaceAllMapped(RegExp(r'[A-Z]'), (match) => ' ${match.group(0)}')
      .trim();
  return text.isEmpty ? '' : '${text[0].toUpperCase()}${text.substring(1)}';
}
