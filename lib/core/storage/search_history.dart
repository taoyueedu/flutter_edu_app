import 'sp_util.dart';

/// 搜索历史管理（最多存 10 条，用 `|` 分隔存字符串）
class SearchHistory {
  SearchHistory._();

  static const String _key = 'search_history';
  static const int _maxCount = 10;

  static List<String> get() {
    final raw = SpUtil.getString(_key);
    if (raw.isEmpty) return const [];
    return raw.split('|').where((e) => e.isNotEmpty).toList();
  }

  static Future<void> add(String keyword) {
    final list = get().where((e) => e != keyword).toList();
    list.insert(0, keyword);
    if (list.length > _maxCount) {
      list.removeRange(_maxCount, list.length);
    }
    return SpUtil.setString(_key, list.join('|'));
  }

  static Future<void> clear() => SpUtil.remove(_key);
}
