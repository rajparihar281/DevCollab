abstract final class RouteNames {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const settings = '/settings';
  static const terms = '/terms';
  static const privacy = '/privacy';

  static const organizations = '/organizations';
  static const createOrganization = '/organizations/create';

  // Organization detail with nested routes
  static const organizationDetail = '/organizations/:orgId';
  static String organizationDetailPath(String orgId) =>
      '/organizations/$orgId';

  // Teams
  static const teams = '/organizations/:orgId/teams';
  static String teamsPath(String orgId) => '/organizations/$orgId/teams';

  static const createTeam = '/organizations/:orgId/teams/create';
  static String createTeamPath(String orgId) =>
      '/organizations/$orgId/teams/create';

  static const teamDetail = '/organizations/:orgId/teams/:teamId';
  static String teamDetailPath(String orgId, String teamId) =>
      '/organizations/$orgId/teams/$teamId';

  // Projects
  static const createProject =
      '/organizations/:orgId/teams/:teamId/projects/create';
  static String createProjectPath(String orgId, String teamId) =>
      '/organizations/$orgId/teams/$teamId/projects/create';

  static const projectDetail =
      '/organizations/:orgId/teams/:teamId/projects/:projectId';
  static String projectDetailPath(
          String orgId, String teamId, String projectId) =>
      '/organizations/$orgId/teams/$teamId/projects/$projectId';

  // Tasks
  static const taskDetail =
      '/organizations/:orgId/teams/:teamId/projects/:projectId/tasks/:taskId';
  static String taskDetailPath(
          String orgId, String teamId, String projectId, String taskId) =>
      '/organizations/$orgId/teams/$teamId/projects/$projectId/tasks/$taskId';

  // Chat
  static const chat = '/organizations/:orgId/teams/:teamId/chat';
  static String chatPath(String orgId, String teamId) =>
      '/organizations/$orgId/teams/$teamId/chat';
}
