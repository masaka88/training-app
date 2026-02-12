/// 改行区切りのアクティビティテキストを「 / 」区切りの1行に変換する。
/// 空行は除外される。
String formatActivityDisplay(String activity) {
  return activity
      .split('\n')
      .where((l) => l.trim().isNotEmpty)
      .join(' / ');
}

/// コメントを最大[maxLength]文字にプレビュー用に切り詰める。
/// null・空白のみの場合はnullを返す。
String? formatCommentPreview(String? comment, {int maxLength = 20}) {
  if (comment == null || comment.trim().isEmpty) return null;
  final trimmed = comment.trim();
  return trimmed.length > maxLength
      ? '${trimmed.substring(0, maxLength)}...'
      : trimmed;
}

/// 空白のみの文字列をnullに変換する。
/// フォーム入力のオプショナルフィールドの正規化に使用。
String? emptyToNull(String? value) {
  if (value == null || value.trim().isEmpty) return null;
  return value;
}

/// 文字列を整数にパースする。パースできない場合はfallback値を返す。
int parseIntOrDefault(String? value, {int fallback = 0}) {
  if (value == null) return fallback;
  return int.tryParse(value) ?? fallback;
}
