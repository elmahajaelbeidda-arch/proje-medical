/// Tolerant text search for typed or spoken (speech-to-text) queries in
/// Arabic and French.
///
/// "أريد طبيب قلب في نواذيبو" matches a cardiologist in Nouadhibou:
/// diacritics, letter variants, the article "ال" and filler words are ignored,
/// and every remaining word must appear in one of the searched fields.
class Search {
  Search._();

  static final _diacritics = RegExp('[ً-ٰٟـ]');
  static final _latinAccents = {
    'à': 'a',
    'â': 'a',
    'ä': 'a',
    'ç': 'c',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'î': 'i',
    'ï': 'i',
    'ô': 'o',
    'ö': 'o',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'œ': 'oe',
    '’': "'",
  };

  /// Words that carry no meaning for the search ("I want a doctor in...").
  static final _stopWords = {
    // Arabic
    'اريد', 'ابحث', 'ابغي', 'بغيت', 'عن', 'في', 'من', 'الى', 'على', 'مع',
    'طبيب', 'طبيبه', 'الطبيب', 'دكتور', 'دكتوره', 'د', 'اخصائي', 'اخصائيه',
    'تخصص', 'مدينه', 'لو', 'سمحت', 'عندي', 'يا',
    // French
    'je', 'veux', 'cherche', 'un', 'une', 'le', 'la', 'les', 'de', 'des',
    'du', 'en', 'a', 'au', 'aux', 'pour', 'medecin', 'docteur', 'dr',
    'specialiste', 'ville', 'svp', "d'un", "d'une",
  };

  static String normalize(String input) {
    var s = input.toLowerCase().replaceAll(_diacritics, '');
    s = s
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي');
    _latinAccents.forEach((k, v) => s = s.replaceAll(k, v));
    return s.replaceAll(RegExp(r'[^\p{L}\p{N}\s]', unicode: true), ' ');
  }

  /// Meaningful words of a query.
  static List<String> terms(String query) {
    final out = <String>[];
    for (var w in normalize(query).split(RegExp(r'\s+'))) {
      if (w.isEmpty || _stopWords.contains(w)) continue;
      // Drop the Arabic article: "القلب" -> "قلب", "بالقلب" -> "قلب".
      for (final prefix in ['بال', 'وال', 'لل', 'ال']) {
        if (w.startsWith(prefix) && w.length - prefix.length >= 2) {
          w = w.substring(prefix.length);
          break;
        }
      }
      if (_stopWords.contains(w) || w.length < 2) continue;
      out.add(w);
    }
    return out;
  }

  /// True when every term of [query] is found in at least one of [fields].
  /// An empty query matches everything.
  static bool matches(String query, Iterable<String> fields) {
    final t = terms(query);
    if (t.isEmpty) return true;
    final haystack = normalize(fields.join(' '));
    // Tolerate different word endings ("cardiologue" ~ "cardiologie",
    // "قلبية" ~ "قلب") by also trying the word without its last letters.
    bool found(String term) =>
        haystack.contains(term) ||
        (term.length >= 5 &&
            haystack.contains(term.substring(0, term.length - 2)));
    return t.every(found);
  }
}
