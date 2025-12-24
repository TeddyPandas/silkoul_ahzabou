import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silkoul_ahzabou/screens/campaigns/subscribe_dialog.dart';
import 'package:silkoul_ahzabou/models/campaign.dart';
import 'package:silkoul_ahzabou/models/task.dart';
import 'package:silkoul_ahzabou/providers/campaign_provider.dart';
import 'package:silkoul_ahzabou/providers/auth_provider.dart';
import 'package:silkoul_ahzabou/services/supabase_service.dart';

// Generate mocks
@GenerateMocks(
    [CampaignProvider, SupabaseClient, GoTrueClient, User, AuthProvider])
import 'subscribe_dialog_test.mocks.dart';

void main() {
  late MockCampaignProvider mockCampaignProvider;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockAuthProvider mockAuthProvider;

  setUp(() {
    mockCampaignProvider = MockCampaignProvider();
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    // Setup Supabase mock
    when(mockSupabaseClient.auth).thenReturn(mockAuth);
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.id).thenReturn('user_123');

    mockAuthProvider = MockAuthProvider();
    when(mockAuthProvider.user).thenReturn(mockUser);

    // Inject mock client into SupabaseService
    SupabaseService.client = mockSupabaseClient;
  });

  testWidgets('SubscribeDialog renders correctly with tasks',
      (WidgetTester tester) async {
    // Arrange
    final campaign = Campaign(
      id: 'c1',
      name: 'Test Campaign',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      createdBy: 'user_1',
      isPublic: true,
      tasks: [
        Task(
            id: 't1',
            campaignId: 'c1',
            name: 'Task 1',
            totalNumber: 1000,
            remainingNumber: 500,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()),
        Task(
            id: 't2',
            campaignId: 'c1',
            name: 'Task 2',
            totalNumber: 2000,
            remainingNumber: 2000,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<CampaignProvider>.value(
              value: mockCampaignProvider,
            ),
            ChangeNotifierProvider<AuthProvider>.value(
              value: mockAuthProvider,
            ),
          ],
          child: SubscribeDialog(
            campaign: campaign,
            onSubscriptionSuccess: () {},
          ),
        ),
      ),
    );

    // Assert
    expect(find.text("Rejoindre Test Campaign"), findsOneWidget);
    expect(find.text('Task 1'), findsOneWidget);
    expect(find.text('Task 2'), findsOneWidget);
    expect(find.text('Disponible : 500 / 1000'), findsOneWidget);
  });

  testWidgets('Subscribe button triggers provider call',
      (WidgetTester tester) async {
    // Arrange
    final campaign = Campaign(
      id: 'c1',
      name: 'Test Campaign',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      createdBy: 'user_1',
      isPublic: true,
      tasks: [
        Task(
            id: 't1',
            campaignId: 'c1',
            name: 'Task 1',
            totalNumber: 1000,
            remainingNumber: 500,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now()),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(mockCampaignProvider.subscribeToCampaign(
      userId: anyNamed('userId'),
      campaignId: anyNamed('campaignId'),
      accessCode: anyNamed('accessCode'),
      selectedTasks: anyNamed('selectedTasks'),
    )).thenAnswer((_) async => true);

    await tester.pumpWidget(
      MaterialApp(
        home: MultiProvider(
          providers: [
            ChangeNotifierProvider<CampaignProvider>.value(
              value: mockCampaignProvider,
            ),
            ChangeNotifierProvider<AuthProvider>.value(
              value: mockAuthProvider,
            ),
          ],
          child: SubscribeDialog(
            campaign: campaign,
            onSubscriptionSuccess: () {},
          ),
        ),
      ),
    );

    // Act
    // Enter quantity for Task 1
    // We need to find the specific text field for Task 1 because there are multiple tasks
    final task1CardFinder =
        find.widgetWithText(Card, 'Task 1'); // Find card containing Task 1
    final textFieldFinder = find.descendant(
      of: task1CardFinder,
      matching: find.byType(TextFormField),
    );

    await tester.enterText(textFieldFinder, '100');
    await tester.pump();

    // Tap subscribe
    await tester.tap(find.text('Valider'));
    await tester.pump(); // Start loading
    await tester.pump(); // Finish future

    // Assert
    verify(mockCampaignProvider.subscribeToCampaign(
      userId: 'user_123',
      campaignId: 'c1',
      accessCode: null,
      selectedTasks: argThat(
          contains(predicate(
              (Map m) => m['task_id'] == 't1' && m['quantity'] == 100)),
          named: 'selectedTasks'),
    )).called(1);
  });
}
