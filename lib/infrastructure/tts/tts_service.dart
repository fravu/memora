abstract class TtsService {
  Future<void> speak(String text, {required String languageCode});
}
