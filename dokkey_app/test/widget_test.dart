import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dokkey_app/providers/dokkey_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('DokkeyApp Kkaebi Topics & Lore Integrity', () async {
    SharedPreferences.setMockInitialValues({});
    final provider = DokkeyProvider();
    await provider.initialize();

    final topics = provider.getKkaebiTopics();
    expect(topics.isNotEmpty, isTrue);

    // Verify 6 topics exist
    final topicIds = topics.map((t) => t['id'] as String).toList();
    expect(topicIds, contains('passcode'));
    expect(topicIds, contains('lotto'));
    expect(topicIds, contains('interview'));
    expect(topicIds, contains('relationship'));
    expect(topicIds, contains('healing'));
    expect(topicIds, contains('joke'));

    // Verify step responses
    final answer = provider.getKkaebiAnswer('healing', 1);
    expect(answer.isNotEmpty, isTrue);
  });
}