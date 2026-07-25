
import 'package:dev_collab/features/auth/presentation/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/auth/presentation/pages/login_page.dart';
import '../features/auth/presentation/pages/reset_password_page.dart';
import '../features/auth/presentation/pages/signup_page.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/chat/presentation/pages/chat_page.dart';
import '../features/legal/presentation/pages/privacy_policy_page.dart';
import '../features/legal/presentation/pages/terms_and_conditions_page.dart';
import '../features/notifications/presentation/pages/notification_preferences_page.dart';
import '../features/onboarding/presentation/pages/onboarding_page.dart';
import '../features/organizations/presentation/pages/create_organization_page.dart';
import '../features/organizations/presentation/pages/organization_detail_page.dart';
import '../features/organizations/presentation/pages/organizations_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/projects/presentation/pages/create_project_page.dart';
import '../features/projects/presentation/pages/project_detail_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../features/tasks/presentation/pages/create_task_page.dart';
import '../features/tasks/presentation/pages/task_detail_page.dart';
import '../features/teams/presentation/pages/create_team_page.dart';
import '../features/teams/presentation/pages/team_detail_page.dart';
import 'route_names.dart';

GoRouter createAppRouter(AuthNotifier authNotifier, bool hasSeenOnboarding) {
  return GoRouter(
    initialLocation: RouteNames.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final isInitialized = authNotifier.isInitialized;
      final hasSession = authNotifier.session != null;
      final currentPath = state.matchedLocation;



      if (!isInitialized) {
        return currentPath == RouteNames.splash ? null : RouteNames.splash;
      }

      final isPublicRoute = currentPath == RouteNames.terms ||
          currentPath == RouteNames.privacy ||
          currentPath == RouteNames.forgotPassword ||
          currentPath == RouteNames.resetPassword;

      final isAuthRoute = currentPath == RouteNames.splash ||
          currentPath == RouteNames.login ||
          currentPath == RouteNames.signup ||
          currentPath == RouteNames.onboarding;

      if (hasSession && isAuthRoute) return RouteNames.organizations;
      if (!hasSession && !isAuthRoute && !isPublicRoute) {
        return hasSeenOnboarding ? RouteNames.login : RouteNames.onboarding;
      }
      if (currentPath == RouteNames.splash && !hasSession) {
        return hasSeenOnboarding ? RouteNames.login : RouteNames.onboarding;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (_, _) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.onboarding,
        builder: (_, _) => const OnboardingPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (_, _) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.signup,
        builder: (_, _) => const SignupPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (_, _) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (_, _) => const ResetPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.settings,
        builder: (_, _) => const SettingsPage(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (_, _) => const ProfilePage(),
      ),
      GoRoute(
        path: RouteNames.notificationPreferences,
        builder: (_, _) => const NotificationPreferencesPage(),
      ),
      GoRoute(
        path: RouteNames.terms,
        builder: (_, _) => const TermsAndConditionsPage(),
      ),
      GoRoute(
        path: RouteNames.privacy,
        builder: (_, _) => const PrivacyPolicyPage(),
      ),

      // Organizations
      GoRoute(
        path: RouteNames.organizations,
        builder: (_, _) => const OrganizationsPage(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (_, _) => const CreateOrganizationPage(),
          ),
          GoRoute(
            path: ':orgId',
            builder: (_, state) => OrganizationDetailPage(
              orgId: state.pathParameters['orgId']!,
            ),
            routes: [
              GoRoute(
                path: 'teams/create',
                builder: (_, state) => CreateTeamPage(
                  orgId: state.pathParameters['orgId']!,
                ),
              ),
              GoRoute(
                path: 'teams/:teamId',
                builder: (_, state) => TeamDetailPage(
                  orgId: state.pathParameters['orgId']!,
                  teamId: state.pathParameters['teamId']!,
                ),
                routes: [
                  GoRoute(
                    path: 'chat',
                    builder: (_, state) => ChatPage(
                      orgId: state.pathParameters['orgId']!,
                      teamId: state.pathParameters['teamId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'projects/create',
                    builder: (_, state) => CreateProjectPage(
                      orgId: state.pathParameters['orgId']!,
                      teamId: state.pathParameters['teamId']!,
                    ),
                  ),
                  GoRoute(
                    path: 'projects/:projectId',
                    builder: (_, state) => ProjectDetailPage(
                      orgId: state.pathParameters['orgId']!,
                      teamId: state.pathParameters['teamId']!,
                      projectId: state.pathParameters['projectId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'tasks/create',
                        builder: (_, state) => CreateTaskPage(
                          orgId: state.pathParameters['orgId']!,
                          projectId: state.pathParameters['projectId']!,
                        ),
                      ),
                      GoRoute(
                        path: 'tasks/:taskId',
                        builder: (_, state) => TaskDetailPage(
                          orgId: state.pathParameters['orgId']!,
                          projectId: state.pathParameters['projectId']!,
                          taskId: state.pathParameters['taskId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
