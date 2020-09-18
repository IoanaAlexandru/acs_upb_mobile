import 'package:acs_upb_mobile/authentication/model/user.dart';
import 'package:acs_upb_mobile/authentication/service/auth_provider.dart';
import 'package:acs_upb_mobile/authentication/view/login_view.dart';
import 'package:acs_upb_mobile/authentication/view/sign_up_view.dart';
import 'package:acs_upb_mobile/main.dart';
import 'package:acs_upb_mobile/pages/filter/model/filter.dart';
import 'package:acs_upb_mobile/pages/filter/service/filter_provider.dart';
import 'package:acs_upb_mobile/pages/home/home_page.dart';
import 'package:acs_upb_mobile/pages/people/service/person_provider.dart';
import 'package:acs_upb_mobile/pages/portal/service/website_provider.dart';
import 'package:acs_upb_mobile/pages/profile/profile_page.dart';
import 'package:acs_upb_mobile/widgets/form/form_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:preferences/preferences.dart';
import 'package:provider/provider.dart';

class MockAuthProvider extends Mock implements AuthProvider {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockFilterProvider extends Mock implements FilterProvider {}

class MockWebsiteProvider extends Mock implements WebsiteProvider {}

class MockPersonProvider extends Mock implements PersonProvider {}

void main() {
  AuthProvider mockAuthProvider;
  WebsiteProvider mockWebsiteProvider;
  FilterProvider mockFilterProvider;
  PersonProvider mockPersonProvider;

  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    PrefService.enableCaching();
    PrefService.cache = {};
    PrefService.setString('language', 'en');

    // Mock the behaviour of the auth provider
    // TODO: Test AuthProvider separately
    mockAuthProvider = MockAuthProvider();
    // ignore: invalid_use_of_protected_member
    when(mockAuthProvider.hasListeners).thenReturn(false);
    when(mockAuthProvider.isAuthenticatedFromCache).thenReturn(false);
    when(mockAuthProvider.isAuthenticatedFromService)
        .thenAnswer((realInvocation) => Future.value(false));

    mockWebsiteProvider = MockWebsiteProvider();
    // ignore: invalid_use_of_protected_member
    when(mockWebsiteProvider.hasListeners).thenReturn(false);
    when(mockWebsiteProvider.deleteWebsite(any, context: anyNamed('context')))
        .thenAnswer((realInvocation) => Future.value(true));
    when(mockWebsiteProvider.fetchWebsites(any))
        .thenAnswer((_) => Future.value([]));

    mockFilterProvider = MockFilterProvider();
    // ignore: invalid_use_of_protected_member
    when(mockFilterProvider.hasListeners).thenReturn(false);
    when(mockFilterProvider.filterEnabled).thenReturn(true);
    when(mockFilterProvider.fetchFilter(any))
        .thenAnswer((_) => Future.value(Filter(localizedLevelNames: [
              {'en': 'Level', 'ro': 'Nivel'}
            ], root: FilterNode(name: 'root'))));

    mockPersonProvider = MockPersonProvider();
    // ignore: invalid_use_of_protected_member
    when(mockPersonProvider.hasListeners).thenReturn(false);
    when(mockPersonProvider.fetchPeople(context: anyNamed('context')))
        .thenAnswer((_) => Future.value([]));
  });

  group('Login', () {
    testWidgets('Anonymous login', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider, child: MyApp()));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        expect(find.byType(LoginView), findsOneWidget);

        when(mockAuthProvider.signInAnonymously(context: anyNamed('context')))
            .thenAnswer((_) => Future.value(true));

        // Log in anonymously
        await tester.tap(find.byKey(ValueKey('log_in_anonymously_button')));
        await tester.pumpAndSettle();

        verify(
            mockAuthProvider.signInAnonymously(context: anyNamed('context')));
        expect(find.byType(HomePage), findsOneWidget);

        // Easy way to check that the login page can't be navigated back to
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });
    });

    testWidgets('Credential login', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider, child: MyApp()));
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        expect(find.byType(LoginView), findsOneWidget);

        expect(find.text('@stud.acs.upb.ro'), findsOneWidget);

        when(mockAuthProvider.signIn(
                email: anyNamed('email'),
                password: anyNamed('password'),
                context: anyNamed('context')))
            .thenAnswer((_) => Future.value(true));

        // Enter credentials
        await tester.enterText(
            find.byKey(ValueKey('email_text_field')), 'test');
        await tester.enterText(
            find.byKey(ValueKey('password_text_field')), 'password');

        await tester.tap(find.byKey(ValueKey('log_in_button')));
        await tester.pumpAndSettle();

        verify(mockAuthProvider.signIn(
            email: argThat(equals('test@stud.acs.upb.ro'), named: 'email'),
            password: argThat(equals('password'), named: 'password'),
            context: anyNamed('context')));
        expect(find.byType(HomePage), findsOneWidget);

        // Easy way to check that the login page can't be navigated back to
        expect(find.byIcon(Icons.arrow_back), findsNothing);
      });
    });
  });

  group('Recover password', () {
    testWidgets('Send email', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider, child: MyApp()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);

      when(mockAuthProvider.sendPasswordResetEmail(
              email: anyNamed('email'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      expect(find.byType(AlertDialog), findsNothing);

      // Reset password
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Send email
      await tester.enterText(
          find.byKey(ValueKey('reset_password_email_text_field')), 'test');

      await tester.tap(find.byKey(ValueKey('send_email_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      verify(mockAuthProvider.sendPasswordResetEmail(
          email: argThat(equals('test@stud.acs.upb.ro'), named: 'email'),
          context: anyNamed('context')));
    });

    testWidgets('Cancel', (WidgetTester tester) async {
      await tester.pumpWidget(ChangeNotifierProvider<AuthProvider>(
          create: (_) => mockAuthProvider, child: MyApp()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginView), findsOneWidget);

      when(mockAuthProvider.sendPasswordResetEmail(
              email: anyNamed('email'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      expect(find.byType(AlertDialog), findsNothing);

      // Reset password
      await tester.tap(find.text('Reset password'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      // Close dialog
      await tester.tap(find.byKey(ValueKey('cancel_button')));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing);

      verifyNever(
          mockAuthProvider.sendPasswordResetEmail(email: anyNamed('email')));
    });
  });

  group('Sign up', () {
    MockNavigatorObserver mockObserver = MockNavigatorObserver();
    FilterProvider mockFilterProvider = MockFilterProvider();

    setUp(() {
      mockFilterProvider = MockFilterProvider();
      // ignore: invalid_use_of_protected_member
      when(mockFilterProvider.hasListeners).thenReturn(false);
      when(mockFilterProvider.filterEnabled).thenReturn(true);
      when(mockFilterProvider.fetchFilter(any))
          .thenAnswer((_) => Future.value(Filter(
                  localizedLevelNames: [
                    {'en': 'Degree', 'ro': 'Nivel de studiu'},
                    {'en': 'Major', 'ro': 'Specializare'},
                    {'en': 'Year', 'ro': 'An'},
                    {'en': 'Series', 'ro': 'Serie'},
                    {'en': 'Group', 'ro': 'Group'}
                  ],
                  root: FilterNode(name: 'All', value: true, children: [
                    FilterNode(name: 'BSc', value: true, children: [
                      FilterNode(name: 'CTI', value: true, children: [
                        FilterNode(name: 'CTI-1', value: true, children: [
                          FilterNode(name: '1-CA'),
                          FilterNode(
                            name: '1-CB',
                            value: true,
                            children: [
                              FilterNode(name: '311CB'),
                              FilterNode(name: '312CB'),
                              FilterNode(name: '313CB'),
                              FilterNode(
                                name: '314CB',
                                value: true,
                              ),
                            ],
                          ),
                          FilterNode(name: '1-CC'),
                          FilterNode(
                            name: '1-CD',
                            children: [
                              FilterNode(name: '311CD'),
                              FilterNode(name: '312CD'),
                              FilterNode(name: '313CD'),
                              FilterNode(name: '314CD'),
                            ],
                          ),
                        ]),
                        FilterNode(
                          name: 'CTI-2',
                        ),
                        FilterNode(
                          name: 'CTI-3',
                        ),
                        FilterNode(
                          name: 'CTI-4',
                        ),
                      ]),
                      FilterNode(name: 'IS')
                    ]),
                    FilterNode(name: 'MSc', children: [
                      FilterNode(
                        name: 'IA',
                      ),
                      FilterNode(name: 'SPRC'),
                    ])
                  ]))));
    });

    testWidgets('Sign up', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider)
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(LoginView), findsOneWidget);

      // Scroll sign up button into view and tap
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(SignUpView), findsOneWidget);

      when(mockAuthProvider.signUp(
              info: anyNamed('info'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));
      when(mockAuthProvider.canSignUpWithEmail(email: anyNamed('email')))
          .thenAnswer((realInvocation) => Future.value(true));

      // Test parser from email
      final FormTextField firstName = tester
          .widget<FormTextField>(find.byKey(ValueKey('first_name_text_field')));
      final FormTextField lastName = tester
          .widget<FormTextField>(find.byKey(ValueKey('last_name_text_field')));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_alexander.doe123');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john.doe');
      expect(firstName.controller.text, equals('John'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          '1234john.doe');
      expect(firstName.controller.text, equals('John'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john1234.doe');
      expect(firstName.controller.text, equals('John'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john.1234doe');
      expect(firstName.controller.text, equals('John'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john.doe1234');
      expect(firstName.controller.text, equals('John'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          '1234john_alexander.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john1234_alexander.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_1234alexander.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_alexander1234.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_alexander.1234doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          '!@#%^&*()=-+john_alexander.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john!@#%^&*()=-+_alexander.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_!@#%^&*()=-+alexander.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_alexander!@#%^&*()=-+.doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_alexander.!@#%^&*()=-+doe');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_alexander.doe!@#%^&*()=-+');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          '!@#%^&*()=-+john!@#%^&*()=-+_!@#%^&*()=-+alexander!@#%^&*()=-+.!@#%^&*()=-+1234!@#%^&*()=-+doe!@#%^&*()=-+');
      expect(firstName.controller.text, equals('John Alexander'));
      expect(lastName.controller.text, equals('Doe'));

      await tester.enterText(
          find.byKey(ValueKey('email_text_field'), skipOffstage: true),
          'john_alexander.doe1234');

      ///////////////////////

      await tester.enterText(
          find.byKey(ValueKey('password_text_field'), skipOffstage: true),
          'password');
      await tester.enterText(
          find.byKey(ValueKey('confirm_password_text_field')), 'password');
      await tester.enterText(
          find.byKey(ValueKey('first_name_text_field')), 'John Alexander');
      await tester.enterText(
          find.byKey(ValueKey('last_name_text_field')), 'Doe');
      // TODO: Test dropdown buttons

      // Scroll sign up button into view
      await tester.ensureVisible(find.byKey(ValueKey('sign_up_button')));

      // Check Privacy Policy
      await tester.tap(find.byType(Checkbox));

      // Press sign up
      await tester.tap(find.byKey(ValueKey('sign_up_button')));
      await tester.pumpAndSettle();

      verify(mockAuthProvider.signUp(
          info: argThat(
              equals({
                'Email': 'john_alexander.doe1234@stud.acs.upb.ro',
                'Password': 'password',
                'Confirm password': 'password',
                'First name': 'John Alexander',
                'Last name': 'Doe',
              }),
              named: 'info'),
          context: anyNamed('context')));
      expect(find.byType(HomePage), findsOneWidget);
      verify(mockObserver.didPush(any, any));
    });

    testWidgets('Cancel', (WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider)
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(LoginView), findsOneWidget);

      // Scroll sign up button into view and tap
      await tester.ensureVisible(find.text('Sign up'));
      await tester.tap(find.text('Sign up'));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(SignUpView), findsOneWidget);

      when(mockAuthProvider.signUp(
              info: anyNamed('info'), context: anyNamed('context')))
          .thenAnswer((_) => Future.value(true));

      // Scroll cancel button into view and tap
      await tester.ensureVisible(find.byKey(ValueKey('cancel_button')));
      await tester.tap(find.byKey(ValueKey('cancel_button')));
      await tester.pumpAndSettle();

      verifyNever(mockAuthProvider.signUp(
          info: anyNamed('info'), context: anyNamed('context')));
      expect(find.byType(LoginView), findsOneWidget);
      expect(find.byType(SignUpView), findsNothing);
      verify(mockObserver.didPop(any, any));
    });
  });

  group('Sign out', () {
    MockNavigatorObserver mockObserver = MockNavigatorObserver();

    setUp(() {
      // Mock an anonymous user already being logged in
      when(mockAuthProvider.isAuthenticatedFromCache).thenReturn(true);
      when(mockAuthProvider.isAuthenticatedFromService)
          .thenAnswer((realInvocation) => Future.value(true));
      when(mockAuthProvider.isVerifiedFromService)
          .thenAnswer((realInvocation) => Future.value(false));
    });

    testWidgets('Sign out anonymous', (WidgetTester tester) async {
      when(mockAuthProvider.currentUser)
          .thenAnswer((realInvocation) => Future.value(null));
      when(mockAuthProvider.isAnonymous).thenReturn(true);

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        ChangeNotifierProvider<PersonProvider>(
            create: (_) => mockPersonProvider),
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(HomePage), findsOneWidget);

      // Open profile page
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('Anonymous'), findsOneWidget);

      // Press log in button
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      verify(mockAuthProvider.signOut(any));
      expect(find.byType(LoginView), findsOneWidget);
    });

    testWidgets('Sign out authenticated', (WidgetTester tester) async {
      when(mockAuthProvider.currentUser).thenAnswer((realInvocation) =>
          Future.value(User(uid: '0', firstName: 'John', lastName: 'Doe')));
      when(mockAuthProvider.isAnonymous).thenReturn(false);

      await tester.pumpWidget(MultiProvider(providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => mockAuthProvider),
        ChangeNotifierProvider<FilterProvider>(
            create: (_) => mockFilterProvider),
        ChangeNotifierProvider<WebsiteProvider>(
            create: (_) => mockWebsiteProvider),
        ChangeNotifierProvider<PersonProvider>(
            create: (_) => mockPersonProvider),
      ], child: MyApp(navigationObservers: [mockObserver])));
      await tester.pumpAndSettle();

      verify(mockObserver.didPush(any, any));
      expect(find.byType(HomePage), findsOneWidget);

      // Open profile page
      await tester.tap(find.byIcon(Icons.person));
      await tester.pumpAndSettle();

      expect(find.byType(ProfilePage), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);

      // Press log out button
      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(mockAuthProvider.signOut(any));
      expect(find.byType(LoginView), findsOneWidget);
    });
  });
}
