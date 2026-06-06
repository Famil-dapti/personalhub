import '../data/models/media_models.dart';

/// Pure filter + sort over the review queue. Kept side-effect free so it is
/// trivially testable and runs the same on every platform.
///
/// `seed` makes the `random` order deterministic within a deck load (so the
/// list doesn't reshuffle on every rebuild) while still varying between loads.
List<MediaAsset> applyMediaFilterSort(
  List<MediaAsset> assets, {
  MediaTypeFilter type = MediaTypeFilter.all,
  String? album,
  bool screenshotsOnly = false,
  MediaSortOrder sort = MediaSortOrder.newest,
  int seed = 0,
}) {
  final filtered = assets.where((a) {
    if (type == MediaTypeFilter.photos && a.isVideo) return false;
    if (type == MediaTypeFilter.videos && !a.isVideo) return false;
    if (album != null && a.albumName != album) return false;
    if (screenshotsOnly && !a.isScreenshot) return false;
    return true;
  }).toList();

  switch (sort) {
    case MediaSortOrder.newest:
      filtered.sort((a, b) => _date(b).compareTo(_date(a)));
    case MediaSortOrder.oldest:
      filtered.sort((a, b) => _date(a).compareTo(_date(b)));
    case MediaSortOrder.largest:
      filtered.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
    case MediaSortOrder.random:
      _shuffleDeterministic(filtered, seed);
  }
  return filtered;
}

DateTime _date(MediaAsset a) =>
    a.createdDate ?? DateTime.fromMillisecondsSinceEpoch(0);

// Fisher-Yates with a MINSTD (Park-Miller) PRNG so the order is stable for a
// given seed. All intermediate products stay under 2^53, so it is exact on web
// (JS doubles) as well as native — no 64-bit literals.
void _shuffleDeterministic(List<MediaAsset> list, int seed) {
  const modulus = 2147483647; // 2^31 - 1
  var state = (seed.abs() % (modulus - 1)) + 1; // keep in 1..modulus-1
  int next(int bound) {
    state = (state * 48271) % modulus;
    return state % bound;
  }

  for (var i = list.length - 1; i > 0; i--) {
    final j = next(i + 1);
    final tmp = list[i];
    list[i] = list[j];
    list[j] = tmp;
  }
}
