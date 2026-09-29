abstract class TranslationService {
  /// Liefert eine Uebersetzungs-Vermutung oder null, wenn keine gefunden wurde.
  Future<String?> translate(
    String text, {
    required String sourceLang,
    required String targetLang,
  });
}
