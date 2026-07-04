import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.route);

  final String label;
  final IconData icon;
  final String route;
}

const navItems = [
  NavItem('Dashboard', Icons.space_dashboard_outlined, '/'),
  NavItem('Discover Jobs', Icons.travel_explore_outlined, '/jobs'),
  NavItem('Tracker', Icons.fact_check_outlined, '/tracker'),
  NavItem('Profile', Icons.person_outline, '/profile'),
  NavItem('Credentials', Icons.workspace_premium_outlined, '/credentials'),
  NavItem('Portfolio', Icons.folder_open_outlined, '/portfolio'),
  NavItem('Resume', Icons.description_outlined, '/resume'),
  NavItem('Applications', Icons.outbox_outlined, '/applications'),
  NavItem('Settings', Icons.settings_outlined, '/settings'),
  NavItem('Auth', Icons.lock_outline, '/auth'),
];

class WorkBridgeShell extends StatelessWidget {
  const WorkBridgeShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final path = GoRouterState.of(context).uri.path;
    final title = navItems[_selectedIndex(path)].label;

    if (width < 780) {
      final visible = navItems.take(5).toList();
      final selected = _selectedIndex(path).clamp(0, visible.length - 1);
      return Scaffold(
        appBar: AppBar(title: Text(title)),
        body: child,
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          destinations: [
            for (final item in visible)
              NavigationDestination(icon: Icon(item.icon), label: item.label),
          ],
          onDestinationSelected: (index) => context.go(visible[index].route),
        ),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SidebarNavigation(
            extended: width >= 1180,
            selectedIndex: _selectedIndex(path),
            onSelected: (index) => context.go(navItems[index].route),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class SidebarNavigation extends StatelessWidget {
  const SidebarNavigation({
    super.key,
    required this.extended,
    required this.selectedIndex,
    required this.onSelected,
  });

  final bool extended;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: extended ? 248 : 86,
      decoration: const BoxDecoration(
        color: Color(0xff0b1018),
        border: Border(right: BorderSide(color: Color(0xff1d2a39))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 18, 20),
              child: Row(
                mainAxisAlignment: extended
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.center,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xff10293b),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xff265b7b)),
                    ),
                    child: const Icon(
                      Icons.hub_outlined,
                      color: Color(0xff55c7ff),
                    ),
                  ),
                  if (extended) ...[
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WorkBridge AI',
                            style: TextStyle(fontWeight: FontWeight.w800),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Career readiness',
                            style: TextStyle(
                              color: Color(0xff8fa3b8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                itemCount: navItems.length,
                itemBuilder: (context, index) {
                  final item = navItems[index];
                  final selected = selectedIndex == index;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Tooltip(
                      message: item.label,
                      child: Material(
                        color: selected
                            ? const Color(0xff13283a)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () => onSelected(index),
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: extended ? 12 : 0,
                              vertical: 12,
                            ),
                            child: Row(
                              mainAxisAlignment: extended
                                  ? MainAxisAlignment.start
                                  : MainAxisAlignment.center,
                              children: [
                                Icon(
                                  item.icon,
                                  color: selected
                                      ? const Color(0xff55c7ff)
                                      : const Color(0xff8fa3b8),
                                ),
                                if (extended) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      item.label,
                                      style: TextStyle(
                                        color: selected
                                            ? const Color(0xfff7fbff)
                                            : const Color(0xffb8c6d4),
                                        fontWeight: selected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (extended)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  'No automatic applications. Review every package before sending.',
                  style: TextStyle(
                    color: Color(0xff8fa3b8),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

int _selectedIndex(String path) {
  final index = navItems.indexWhere(
    (item) =>
        item.route == path ||
        (item.route != '/' && path.startsWith(item.route)),
  );
  return index < 0 ? 0 : index;
}
