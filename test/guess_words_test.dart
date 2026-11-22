import 'package:flutter_test/flutter_test.dart';
import 'package:word_rumble/data/guess_words.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'the shipped dictionary accepts real guesses and rejects gibberish',
    () async {
      final dictionary = await GuessWords.load();
      for (final word in ['TOWER', 'WELLS', ...GuessWords.targets]) {
        expect(dictionary.accepts(word), isTrue, reason: word);
        final remaining = GuessWords.rack.split('');
        for (final letter in word.split('')) {
          expect(
            remaining.remove(letter),
            isTrue,
            reason: 'Rack cannot spell $word',
          );
        }
      }
      expect(dictionary.accepts('OWTLR'), isFalse);
      expect(dictionary.accepts(''), isFalse);
    },
  );
}
