import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:silkoul_ahzabou/services/campaign_service.dart';
import 'package:silkoul_ahzabou/models/campaign.dart';

// Generate mocks
@GenerateMocks([http.Client, SupabaseClient, GoTrueClient, Session, User])
import 'campaign_service_test.mocks.dart';

void main() {
  late CampaignService campaignService;
  late MockClient mockHttpClient;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;
  late MockSession mockSession;
  late MockUser mockUser;

  setUp(() {
    mockHttpClient = MockClient();
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockSession = MockSession();
    mockUser = MockUser();

    // Setup Supabase Auth mock
    when(mockSupabaseClient.auth).thenReturn(mockAuth);
    when(mockAuth.currentSession).thenReturn(mockSession);
    when(mockSession.accessToken).thenReturn('fake_token');
    when(mockAuth.currentUser).thenReturn(mockUser);
    when(mockUser.id).thenReturn('user_123');

    campaignService = CampaignService(
      client: mockHttpClient,
      supabase: mockSupabaseClient,
      baseUrl: 'http://test-api.com',
    );
  });

  group('CampaignService', () {
    test('getPublicCampaigns returns list of campaigns on 200', () async {
      // Arrange
      const responseBody = '''
        {
          "data": [
            {
              "id": "1",
              "name": "Campaign 1",
              "start_date": "2023-01-01T00:00:00.000Z",
              "end_date": "2023-01-31T00:00:00.000Z",
              "created_by": "user_1",
              "is_public": true,
              "created_at": "2023-01-01T00:00:00.000Z",
              "updated_at": "2023-01-01T00:00:00.000Z",
              "tasks": []
            }
          ]
        }
      ''';

      when(mockHttpClient.get(
        any,
        headers: anyNamed('headers'),
      )).thenAnswer((_) async => http.Response(responseBody, 200));

      // Act
      final campaigns = await campaignService.getPublicCampaigns();

      // Assert
      expect(campaigns, isA<List<Campaign>>());
      expect(campaigns.length, 1);
      expect(campaigns.first.name, 'Campaign 1');
    });

    test('subscribeToCampaign calls correct endpoint', () async {
      // Arrange
      when(mockHttpClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response('{"message": "Success"}', 201));

      // Act
      await campaignService.subscribeToCampaign(
        campaignId: 'camp_123',
        selectedTasks: [{'task_id': 't1', 'quantity': 100}],
        userId: 'user_123',
      );

      // Assert
      verify(mockHttpClient.post(
        Uri.parse('http://test-api.com/tasks/subscribe'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer fake_token',
        },
        body: anyNamed('body'),
      )).called(1);
    });
  });
}
