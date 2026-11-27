import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show ImageFilter;
import 'package:audio_metadata_reader/audio_metadata_reader.dart' show readMetadata;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

const L = <String, Map<String, String>>{
  'en': {
    'songs': 'Songs', 'playlists': 'Playlists', 'favs': 'Favorites', 'recent': 'Recent',
    'settings': 'Settings', 'add': 'Add songs', 'search': 'Search songs', 'newpl': 'New playlist',
    'save': 'Save', 'cancel': 'Cancel', 'del': 'Delete', 'rename': 'Rename', 'cover': 'Set cover',
    'addpl': 'Add to playlist', 'rmpl': 'Remove from playlist', 'empty': 'No songs here yet.',
    'theme_mode': 'Theme mode', 'color': 'Accent color', 'style': 'UI style', 'lang': 'Language',
    'system': 'System', 'light': 'Light', 'dark': 'Dark', 'amoled': 'Black (AMOLED)',
    's0': 'Classic', 's1': 'Minimal', 's2': 'Vinyl', 's3': 'Glass', 'off': 'Off', 'min': 'min',
    'fav': 'Favorite', 'added': 'songs added', 'nothing': 'Nothing playing', 'sure': 'Delete this song for good?',
    'custom': 'Custom color', 'eq': 'Equalizer', 'eq_on': 'Enable equalizer', 'lyrics': 'Lyrics',
    'info': 'Edit info', 'title': 'Title', 'artist': 'Artist', 'album': 'Album',
    'no_lyrics': 'No lyrics yet. Use the buttons above to type or import them.',
    'lyr_file': 'Import .lrc / .txt', 'edit': 'Edit', 'online': 'Fetch info online',
    'auto_online': 'Auto-fill missing info online (needs internet)', 'found': 'Info updated',
    'notfound': 'Nothing found (check your internet)', 'flat': 'Flat', 'bass': 'Bass',
    'treble': 'Treble', 'vocal': 'Vocal', 'eq_err': 'Equalizer is not ready. Play a song first.',
  },
  'bn': {
    'songs': 'গান', 'playlists': 'প্লেলিস্ট', 'favs': 'প্রিয়', 'recent': 'সাম্প্রতিক',
    'settings': 'সেটিংস', 'add': 'গান যোগ করুন', 'search': 'গান খুঁজুন', 'newpl': 'নতুন প্লেলিস্ট',
    'save': 'সেভ', 'cancel': 'বাতিল', 'del': 'মুছে ফেলুন', 'rename': 'নাম বদলান', 'cover': 'কভার সেট করুন',
    'addpl': 'প্লেলিস্টে যোগ করুন', 'rmpl': 'প্লেলিস্ট থেকে সরান', 'empty': 'এখানে এখনো কোনো গান নেই।',
    'theme_mode': 'থিম মোড', 'color': 'অ্যাক্সেন্ট রঙ', 'style': 'UI স্টাইল', 'lang': 'ভাষা',
    'system': 'সিস্টেম', 'light': 'লাইট', 'dark': 'ডার্ক', 'amoled': 'কালো (AMOLED)',
    's0': 'ক্লাসিক', 's1': 'মিনিমাল', 's2': 'ভিনাইল', 's3': 'গ্লাস', 'off': 'বন্ধ', 'min': 'মিনিট',
    'fav': 'প্রিয়তে যোগ/সরান', 'added': 'টি গান যোগ হয়েছে', 'nothing': 'কিছু চলছে না', 'sure': 'গানটি চিরতরে মুছবেন?',
    'custom': 'নিজের পছন্দের রঙ', 'eq': 'ইকুয়ালাইজার', 'eq_on': 'ইকুয়ালাইজার চালু করুন', 'lyrics': 'লিরিক্স',
    'info': 'তথ্য এডিট করুন', 'title': 'গানের নাম', 'artist': 'শিল্পী', 'album': 'অ্যালবাম',
    'no_lyrics': 'এখনো লিরিক্স নেই। উপরের বাটন দিয়ে টাইপ করুন বা ফাইল থেকে নিন।',
    'lyr_file': '.lrc / .txt ফাইল থেকে নিন', 'edit': 'এডিট', 'online': 'অনলাইনে তথ্য খুঁজুন',
    'auto_online': 'ইন্টারনেট থাকলে নিজে নিজে বাকি তথ্য খুঁজে বসান', 'found': 'তথ্য আপডেট হয়েছে',
    'notfound': 'কিছু পাওয়া যায়নি (ইন্টারনেট দেখুন)', 'flat': 'ফ্ল্যাট', 'bass': 'বেস',
    'treble': 'ট্রেবল', 'vocal': 'ভোকাল', 'eq_err': 'ইকুয়ালাইজার এখনো তৈরি না। আগে একটা গান চালান।',
  },
};
String t(String k) => L[app.lang]?[k] ?? k;
String tg(dynamic Function() f) {
  try {
    return (f() ?? '').toString().trim();
  } catch (_) {
    return '';
  }
}

class Song {
  String id, title, file, artist, album, lyrics;
  String? cover;
  Song(this.id, this.title, this.file, {this.artist = '', this.album = '', this.lyrics = '', this.cover});
  Map<String, dynamic> toJ() => {'i': id, 't': title, 'f': file, 'c': cover, 'a': artist, 'al': album, 'ly': lyrics};
  static Song fromJ(dynamic m) => Song(m['i'], m['t'], m['f'], artist: m['a'] ?? '', album: m['al'] ?? '', lyrics: m['ly'] ?? '', cover: m['c']);
}

class PL {
  String id, name;
  List<String> ids;
  PL(this.id, this.name, this.ids);
  Map<String, dynamic> toJ() => {'i': id, 'n': name, 's': ids};
  static PL fromJ(dynamic m) => PL(m['i'], m['n'], List<String>.from(m['s']));
}

class S extends ChangeNotifier {
  late SharedPreferences sp;
  late Directory dir;
  final eq = AndroidEqualizer();
  late final AudioPlayer player = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [eq]));
  Map<String, Song> songs = {};
  List<String> lib = [], recent = [];
  List<PL> pls = [];
  Set<String> favs = {};
  int accent = 0xFF9B1D45, mode = 0, style = 0, sleepMin = 0;
  String lang = 'bn';
  bool autoOnline = true, eqOn = false;
  Timer? _t;

  String nid() => DateTime.now().microsecondsSinceEpoch.toString();
  String path(String f) => p.join(dir.path, f);
  String? coverPath(String id) {
    final c = songs[id]?.cover;
    return c == null ? null : path(c);
  }

  Future<void> load() async {
    sp = await SharedPreferences.getInstance();
    final base = await getApplicationDocumentsDirectory();
    dir = Directory(p.join(base.path, 'velvet'));
    await dir.create(recursive: true);
    accent = sp.getInt('acc') ?? accent;
    mode = sp.getInt('mode') ?? 0;
    style = sp.getInt('style') ?? 0;
    lang = sp.getString('lang') ?? 'bn';
    autoOnline = sp.getBool('auto') ?? true;
    final j = sp.getString('db');
    if (j != null) {
      final m = jsonDecode(j);
      for (final x in m['songs']) {
        final s = Song.fromJ(x);
        songs[s.id] = s;
      }
      lib = List<String>.from(m['lib']);
      recent = List<String>.from(m['recent']);
      pls = [for (final x in m['pls']) PL.fromJ(x)];
      favs = Set<String>.from(m['favs']);
    }
    player.sequenceStateStream.listen((s) {
      final id = (s?.currentSource?.tag as MediaItem?)?.id;
      if (id != null && (recent.isEmpty || recent.first != id)) {
        recent.remove(id);
        recent.insert(0, id);
        if (recent.length > 30) recent.removeLast();
        save();
      }
    });
  }

  void save() {
    sp.setString('db', jsonEncode({
      'songs': [for (final s in songs.values) s.toJ()],
      'lib': lib, 'recent': recent, 'favs': favs.toList(),
      'pls': [for (final x in pls) x.toJ()],
    }));
    notifyListeners();
  }

  void pref({int? acc, int? m, int? st, String? l, bool? auto}) {
    if (acc != null) { accent = acc; sp.setInt('acc', acc); }
    if (m != null) { mode = m; sp.setInt('mode', m); }
    if (st != null) { style = st; sp.setInt('style', st); }
    if (l != null) { lang = l; sp.setString('lang', l); }
    if (auto != null) { autoOnline = auto; sp.setBool('auto', auto); }
    notifyListeners();
  }

  Future<int> importSongs() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (r == null) return 0;
    var n = 0;
    final added = <String>[];
    for (final f in r.files) {
      if (f.path == null) continue;
      final id = '${nid()}$n';
      final name = '$id${p.extension(f.path!)}';
      await File(f.path!).copy(path(name));
      final song = Song(id, p.basenameWithoutExtension(f.name), name);
      try {
        final dynamic md = await readMetadata(File(path(name)), getImage: true);
        final tt = tg(() => md.title);
        if (tt.isNotEmpty) song.title = tt;
        song.artist = tg(() => md.artist);
        song.album = tg(() => md.album);
        song.lyrics = tg(() => md.lyrics);
        final pics = md.pictures;
        if (pics != null && pics.isNotEmpty) {
          final dynamic pic = pics.first;
          final mt = tg(() => pic.mimetype).toLowerCase();
          final ext = mt.contains('png') ? '.png' : '.jpg';
          final cn = 'c${DateTime.now().microsecondsSinceEpoch}$n$ext';
          await File(path(cn)).writeAsBytes(List<int>.from(pic.bytes));
          song.cover = cn;
        }
      } catch (_) {}
      songs[id] = song;
      lib.add(id);
      added.add(id);
      n++;
    }
    save();
    if (autoOnline) _autoFetch(added);
    return n;
  }

  Future<void> _autoFetch(List<String> ids) async {
    for (final id in ids) {
      final s = songs[id];
      if (s == null) continue;
      if (s.artist.isEmpty || s.cover == null) await fetchOnline(id);
    }
  }

  Future<bool> fetchOnline(String id, {bool manual = false}) async {
    final s = songs[id];
    if (s == null) return false;
    final cl = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final q = Uri.encodeQueryComponent('${s.title.replaceAll('_', ' ')} ${s.artist}'.trim());
      final rq = await cl.getUrl(Uri.parse('https://itunes.apple.com/search?term=$q&entity=song&limit=1'));
      final rs = await rq.close().timeout(const Duration(seconds: 10));
      final body = await rs.transform(utf8.decoder).join();
      final res = jsonDecode(body)['results'] as List;
      if (res.isEmpty) return false;
      final r = res.first;
      if (manual) {
        s.title = r['trackName'] ?? s.title;
        s.artist = r['artistName'] ?? s.artist;
        s.album = r['collectionName'] ?? s.album;
      } else {
        if (s.artist.isEmpty) s.artist = r['artistName'] ?? '';
        if (s.album.isEmpty) s.album = r['collectionName'] ?? '';
      }
      final art = r['artworkUrl100'];
      if (art != null && (manual || s.cover == null)) {
        final url = (art as String).replaceAll('100x100bb', '600x600bb');
        final rq2 = await cl.getUrl(Uri.parse(url));
        final rs2 = await rq2.close().timeout(const Duration(seconds: 15));
        final bytes = <int>[];
        await for (final ch in rs2) { bytes.addAll(ch); }
        final cn = 'c${DateTime.now().microsecondsSinceEpoch}.jpg';
        await File(path(cn)).writeAsBytes(bytes);
        final old = s.cover;
        if (old != null) {
          try { File(path(old)).deleteSync(); } catch (_) {}
        }
        s.cover = cn;
      }
      save();
      return true;
    } catch (_) {
      return false;
    } finally {
      cl.close();
    }
  }

  Future<void> setCover(String id) async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    final f = r?.files.single.path;
    if (f == null) return;
    final old = songs[id]!.cover;
    if (old != null) {
      try { File(path(old)).deleteSync(); } catch (_) {}
    }
    final n = 'c${DateTime.now().millisecondsSinceEpoch}${p.extension(f)}';
    await File(f).copy(path(n));
    songs[id]!.cover = n;
    save();
  }

  Future<void> importLyrics(String id) async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['lrc', 'txt']);
    final f = r?.files.single.path;
    if (f == null) return;
    try {
      var txt = await File(f).readAsString();
      txt = txt.replaceAll(RegExp(r'\[\d{1,2}:\d{2}(?:[.:]\d{1,3})?\]'), '').replaceAll(RegExp(r'\[[a-z]{2}:.*?\]\n?'), '').trim();
      songs[id]!.lyrics = txt;
      save();
    } catch (_) {}
  }

  Future<void> delSong(String id) async {
    final cur = (player.sequenceState?.currentSource?.tag as MediaItem?)?.id;
    if (cur == id) await player.stop();
    final s = songs.remove(id);
    if (s == null) return;
    for (final f in [s.file, s.cover]) {
      if (f != null) {
        try { File(path(f)).deleteSync(); } catch (_) {}
      }
    }
    lib.remove(id);
    recent.remove(id);
    favs.remove(id);
    for (final x in pls) { x.ids.remove(id); }
    save();
  }

  Future<void> playList(List<String> ids, int i) async {
    final src = ConcatenatingAudioSource(children: [
      for (final id in ids)
        AudioSource.file(path(songs[id]!.file),
            tag: MediaItem(
                id: id,
                title: songs[id]!.title,
                artist: songs[id]!.artist.isEmpty ? null : songs[id]!.artist,
                album: songs[id]!.album.isEmpty ? null : songs[id]!.album,
                artUri: coverPath(id) == null ? null : Uri.file(coverPath(id)!))),
    ]);
    await player.setAudioSource(src, initialIndex: i);
    player.play();
  }

  void setSleep(int m) {
    _t?.cancel();
    sleepMin = m;
    if (m > 0) {
      _t = Timer(Duration(minutes: m), () {
        player.pause();
        sleepMin = 0;
        notifyListeners();
      });
    }
    notifyListeners();
  }
}

final app = S();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.velvet.channel.audio',
    androidNotificationChannelName: 'Velvet',
    androidNotificationOngoing: true,
  );
  await app.load();
  runApp(const VelvetApp());
}

/* ---------- theme & background ---------- */

class VelvetApp extends StatelessWidget {
  const VelvetApp({super.key});
  ThemeData mk(Brightness b, bool black) {
    var cs = ColorScheme.fromSeed(seedColor: Color(app.accent), brightness: b);
    if (black) cs = cs.copyWith(surface: Colors.black);
    final dark = b == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: cs,
      scaffoldBackgroundColor: Colors.transparent,
      appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: (dark ? Colors.black : Colors.white).withOpacity(dark ? .35 : .45),
        indicatorColor: cs.primary.withOpacity(.35),
      ),
      bottomSheetTheme: BottomSheetThemeData(backgroundColor: cs.surfaceContainerHigh),
    );
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => MaterialApp(
          title: 'Velvet',
          debugShowCheckedModeBanner: false,
          theme: mk(Brightness.light, false),
          darkTheme: mk(Brightness.dark, app.mode == 3),
          themeMode: app.mode == 1 ? ThemeMode.light : (app.mode == 0 ? ThemeMode.system : ThemeMode.dark),
          builder: (c, child) => Bg(child: child ?? const SizedBox()),
          home: const Home(),
        ),
      );
}

class Bg extends StatelessWidget {
  final Widget child;
  const Bg({super.key, required this.child});
  @override
  Widget build(BuildContext c) {
    final dark = Theme.of(c).brightness == Brightness.dark;
    final h = HSLColor.fromColor(Color(app.accent));
    Color m(double dh, double s, double l) => HSLColor.fromAHSL(1, (h.hue + dh) % 360, s, l).toColor();
    final black = dark && app.mode == 3;
    final List<Color> cols = black
        ? [m(-30, .8, .16), m(0, .8, .08), Colors.black]
        : (dark
            ? [m(-30, .8, .27), m(0, .75, .16), m(35, .85, .21)]
            : [m(-30, .95, .90), m(0, .9, .84), m(35, .95, .90)]);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: cols)),
      child: child,
    );
  }
}

Widget glass(BuildContext c, Widget child, {double r = 18, EdgeInsets margin = EdgeInsets.zero, EdgeInsets padding = EdgeInsets.zero}) {
  final dark = Theme.of(c).brightness == Brightness.dark;
  return Container(
    margin: margin,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(dark ? .10 : .50),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: Colors.white.withOpacity(dark ? .22 : .7)),
          ),
          child: child,
        ),
      ),
    ),
  );
}

Widget cover(String id, double size, {bool circle = false}) {
  final cp = app.coverPath(id);
  return Builder(builder: (c) {
    final col = Theme.of(c).colorScheme;
    final w = SizedBox(
      width: size,
      height: size,
      child: cp == null
          ? ColoredBox(color: col.primaryContainer, child: Center(child: Icon(Icons.music_note, size: size * .5, color: col.onPrimaryContainer)))
          : Image.file(File(cp), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.music_note))),
    );
    return circle ? ClipOval(child: w) : ClipRRect(borderRadius: BorderRadius.circular(size > 100 ? 22 : 10), child: w);
  });
}

/* ---------- dialogs & menus ---------- */

Future<String?> askText(BuildContext c, String title, String init, {int lines = 1, bool empty = false}) {
  final ctl = TextEditingController(text: init);
  return showDialog<String>(
    context: c,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctl, autofocus: true, minLines: 1, maxLines: lines),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(t('cancel'))),
        FilledButton(
          onPressed: () => Navigator.pop(d, ctl.text.trim().isEmpty && !empty ? null : ctl.text.trim()),
          child: Text(t('save')),
        ),
      ],
    ),
  );
}

void editInfo(BuildContext c, String id) {
  final s = app.songs[id]!;
  final a = TextEditingController(text: s.title);
  final b = TextEditingController(text: s.artist);
  final d = TextEditingController(text: s.album);
  showDialog<void>(
    context: c,
    builder: (x) => AlertDialog(
      title: Text(t('info')),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: a, decoration: InputDecoration(labelText: t('title'))),
          TextField(controller: b, decoration: InputDecoration(labelText: t('artist'))),
          TextField(controller: d, decoration: InputDecoration(labelText: t('album'))),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(x), child: Text(t('cancel'))),
        FilledButton(
          onPressed: () {
            if (a.text.trim().isNotEmpty) s.title = a.text.trim();
            s.artist = b.text.trim();
            s.album = d.text.trim();
            app.save();
            Navigator.pop(x);
          },
          child: Text(t('save')),
        ),
      ],
    ),
  );
}

void confirmDel(BuildContext c, String id) {
  showDialog<void>(
    context: c,
    builder: (d) => AlertDialog(
      title: Text(t('sure')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(t('cancel'))),
        FilledButton(onPressed: () { Navigator.pop(d); app.delSong(id); }, child: Text(t('del'))),
      ],
    ),
  );
}

void addToPl(BuildContext c, String id) {
  showModalBottomSheet<void>(
    context: c,
    builder: (b) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        for (final x in app.pls)
          ListTile(
            leading: const Icon(Icons.queue_music),
            title: Text(x.name),
            onTap: () { Navigator.pop(b); if (!x.ids.contains(id)) x.ids.add(id); app.save(); },
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: Text(t('newpl')),
          onTap: () async {
            Navigator.pop(b);
            final v = await askText(c, t('newpl'), '');
            if (v != null) { app.pls.add(PL(app.nid(), v, [id])); app.save(); }
          },
        ),
      ]),
    ),
  );
}

void songMenu(BuildContext c, String id, PL? pl) {
  showModalBottomSheet<void>(
    context: c,
    builder: (b) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: Icon(app.favs.contains(id) ? Icons.favorite : Icons.favorite_border),
            title: Text(t('fav')),
            onTap: () {
              Navigator.pop(b);
              if (!app.favs.remove(id)) app.favs.add(id);
              app.save();
            },
          ),
          ListTile(leading: const Icon(Icons.edit_note), title: Text(t('info')), onTap: () { Navigator.pop(b); editInfo(c, id); }),
          ListTile(leading: const Icon(Icons.image), title: Text(t('cover')), onTap: () { Navigator.pop(b); app.setCover(id); }),
          ListTile(
            leading: const Icon(Icons.cloud_download_outlined),
            title: Text(t('online')),
            onTap: () async {
              Navigator.pop(b);
              final ok = await app.fetchOnline(id, manual: true);
              if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(t(ok ? 'found' : 'notfound'))));
            },
          ),
          ListTile(leading: const Icon(Icons.playlist_add), title: Text(t('addpl')), onTap: () { Navigator.pop(b); addToPl(c, id); }),
          if (pl != null)
            ListTile(leading: const Icon(Icons.playlist_remove), title: Text(t('rmpl')), onTap: () { Navigator.pop(b); pl.ids.remove(id); app.save(); })
          else
            ListTile(leading: const Icon(Icons.delete_outline), title: Text(t('del')), onTap: () { Navigator.pop(b); confirmDel(c, id); }),
        ]),
      ),
    ),
  );
}

void lyricsSheet(BuildContext c, String id) {
  showModalBottomSheet<void>(
    context: c,
    isScrollControlled: true,
    builder: (b) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: .75,
      minChildSize: .4,
      maxChildSize: .95,
      builder: (_, sc) => ListenableBuilder(
        listenable: app,
        builder: (_, __) {
          final s = app.songs[id];
          if (s == null) return const SizedBox.shrink();
          return Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(children: [
                Expanded(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: t('edit'),
                  onPressed: () async {
                    final v = await askText(c, t('lyrics'), s.lyrics, lines: 8, empty: true);
                    if (v != null) { s.lyrics = v; app.save(); }
                  },
                ),
                IconButton(icon: const Icon(Icons.file_open), tooltip: t('lyr_file'), onPressed: () => app.importLyrics(id)),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: sc,
                padding: const EdgeInsets.all(20),
                child: Text(s.lyrics.isEmpty ? t('no_lyrics') : s.lyrics, style: const TextStyle(fontSize: 18, height: 1.7)),
              ),
            ),
          ]);
        },
      ),
    ),
  );
}

void customColor(BuildContext c) {
  var h = HSVColor.fromColor(Color(app.accent));
  showModalBottomSheet<void>(
    context: c,
    builder: (b) => StatefulBuilder(
      builder: (b, set) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(t('custom'), style: const TextStyle(fontWeight: FontWeight.w700)),
            Slider(value: h.hue, max: 360, onChanged: (v) { set(() => h = h.withHue(v)); app.pref(acc: h.toColor().toARGB32()); }),
            Slider(value: h.saturation, onChanged: (v) { set(() => h = h.withSaturation(v)); app.pref(acc: h.toColor().toARGB32()); }),
            Slider(value: h.value.clamp(.3, 1.0).toDouble(), min: .3, onChanged: (v) { set(() => h = h.withValue(v)); app.pref(acc: h.toColor().toARGB32()); }),
          ]),
        ),
      ),
    ),
  );
}

/* ---------- lists ---------- */

class SongTile extends StatelessWidget {
  final String id;
  final int index;
  final VoidCallback onTap;
  final PL? pl;
  const SongTile({super.key, required this.id, required this.index, required this.onTap, this.pl});
  @override
  Widget build(BuildContext c) {
    final s = app.songs[id]!;
    final st = app.style;
    final fav = app.favs.contains(id);
    return StreamBuilder<SequenceState?>(
      stream: app.player.sequenceStateStream,
      builder: (c, snap) {
        final on = (snap.data?.currentSource?.tag as MediaItem?)?.id == id;
        final pr = Theme.of(c).colorScheme.primary;
        final tile = ListTile(
          dense: st == 1,
          tileColor: on && st != 3 ? pr.withOpacity(.16) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(st == 2 ? 40 : 12)),
          leading: st == 1
              ? SizedBox(width: 28, child: Center(child: Text('${index + 1}', style: TextStyle(color: on ? pr : null))))
              : cover(id, st == 0 ? 54 : 50, circle: st == 2),
          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: on ? pr : null, fontWeight: on ? FontWeight.w800 : (st == 0 ? FontWeight.w600 : null))),
          subtitle: s.artist.isEmpty ? null : Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (fav) Icon(Icons.favorite, size: 16, color: pr),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () => songMenu(c, id, pl)),
          ]),
          onTap: onTap,
        );
        if (st == 3) {
          return glass(c, Material(type: MaterialType.transparency, child: tile), r: 16, margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4));
        }
        return tile;
      },
    );
  }
}

class SongList extends StatelessWidget {
  final List<String> ids;
  final String k, q;
  final bool reorder;
  final PL? pl;
  const SongList({super.key, required this.ids, required this.k, this.q = '', this.reorder = false, this.pl});
  @override
  Widget build(BuildContext c) {
    final ql = q.toLowerCase();
    final shown = q.isEmpty
        ? ids
        : ids.where((i) => ('${app.songs[i]!.title} ${app.songs[i]!.artist}').toLowerCase().contains(ql)).toList();
    if (shown.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t('empty'), textAlign: TextAlign.center)));
    }
    Widget tile(int i) => SongTile(key: ValueKey(shown[i]), id: shown[i], index: i, pl: pl, onTap: () => app.playList(shown, i));
    const pad = EdgeInsets.only(bottom: 96);
    if (reorder && q.isEmpty) {
      return ReorderableListView.builder(
        padding: pad,
        itemCount: ids.length,
        onReorder: (a, b) {
          if (b > a) b--;
          ids.insert(b, ids.removeAt(a));
          app.save();
        },
        itemBuilder: (_, i) => tile(i),
      );
    }
    return ListView.builder(padding: pad, itemCount: shown.length, itemBuilder: (_, i) => tile(i));
  }
}

class PlaylistsView extends StatelessWidget {
  const PlaylistsView({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => ListView(children: [
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(t('newpl')),
            onTap: () async {
              final v = await askText(c, t('newpl'), '');
              if (v != null) { app.pls.add(PL(app.nid(), v, [])); app.save(); }
            },
          ),
          for (final x in app.pls)
            ListTile(
              leading: const Icon(Icons.queue_music),
              title: Text(x.name),
              subtitle: Text('${x.ids.length}'),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => showModalBottomSheet<void>(
                  context: c,
                  builder: (b) => SafeArea(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      ListTile(
                        leading: const Icon(Icons.edit),
                        title: Text(t('rename')),
                        onTap: () async {
                          Navigator.pop(b);
                          final v = await askText(c, t('rename'), x.name);
                          if (v != null) { x.name = v; app.save(); }
                        },
                      ),
                      ListTile(leading: const Icon(Icons.delete_outline), title: Text(t('del')), onTap: () { Navigator.pop(b); app.pls.remove(x); app.save(); }),
                    ]),
                  ),
                ),
              ),
              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => PlPage(x))),
            ),
        ]),
      );
}

class PlPage extends StatelessWidget {
  final PL pl;
  const PlPage(this.pl, {super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => Scaffold(
          appBar: AppBar(title: Text(pl.name), actions: [
            IconButton(icon: const Icon(Icons.play_arrow), onPressed: () { if (pl.ids.isNotEmpty) app.playList(pl.ids, 0); }),
          ]),
          body: SongList(ids: pl.ids, k: pl.id, reorder: true, pl: pl),
        ),
      );
}

/* ---------- player ---------- */

class PlayBtn extends StatelessWidget {
  final double size;
  const PlayBtn({super.key, this.size = 28});
  @override
  Widget build(BuildContext c) => StreamBuilder<PlayerState>(
        stream: app.player.playerStateStream,
        builder: (c, s) {
          final on = s.data?.playing ?? false;
          return IconButton(
            iconSize: size,
            icon: Icon(on ? Icons.pause : Icons.play_arrow),
            onPressed: () => on ? app.player.pause() : app.player.play(),
          );
        },
      );
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => StreamBuilder<SequenceState?>(
          stream: app.player.sequenceStateStream,
          builder: (c, snap) {
            final id = (snap.data?.currentSource?.tag as MediaItem?)?.id;
            final s = id == null ? null : app.songs[id];
            if (s == null) return const SizedBox.shrink();
            final st = app.style;
            final inner = Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const NowPlaying())),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                  child: Row(children: [
                    cover(id!, 44, circle: st == 2),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                        if (s.artist.isNotEmpty) Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                      ]),
                    ),
                    const PlayBtn(),
                  ]),
                ),
              ),
            );
            if (st == 3) return glass(c, inner, r: 20, margin: const EdgeInsets.fromLTRB(10, 0, 10, 6));
            return Container(color: Theme.of(c).colorScheme.surfaceContainerHighest.withOpacity(.7), child: inner);
          },
        ),
      );
}

class SeekBar extends StatelessWidget {
  const SeekBar({super.key});
  String f(Duration d) => '${d.inMinutes}:${(d.inSeconds % 60).toString().padLeft(2, '0')}';
  @override
  Widget build(BuildContext c) => StreamBuilder<Duration>(
        stream: app.player.positionStream,
        builder: (c, snap) {
          final pos = snap.data ?? Duration.zero;
          final dur = app.player.duration ?? Duration.zero;
          final mx = dur.inMilliseconds > 0 ? dur.inMilliseconds.toDouble() : 1.0;
          return Column(children: [
            Slider(
              value: pos.inMilliseconds.toDouble().clamp(0.0, mx).toDouble(),
              max: mx,
              onChanged: (v) => app.player.seek(Duration(milliseconds: v.toInt())),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(f(pos)), Text(f(dur))]),
            ),
          ]);
        },
      );
}

class Vinyl extends StatefulWidget {
  final String id;
  const Vinyl(this.id, {super.key});
  @override
  State<Vinyl> createState() => _VinylState();
}

class _VinylState extends State<Vinyl> with SingleTickerProviderStateMixin {
  late final AnimationController ac = AnimationController(vsync: this, duration: const Duration(seconds: 8));
  StreamSubscription<bool>? sub;
  @override
  void initState() {
    super.initState();
    if (app.player.playing) ac.repeat();
    sub = app.player.playingStream.listen((on) {
      if (on) {
        ac.repeat();
      } else {
        ac.stop();
      }
    });
  }

  @override
  void dispose() {
    sub?.cancel();
    ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext c) {
    final col = Theme.of(c).colorScheme;
    return RotationTransition(
      turns: ac,
      child: Container(
        width: 260,
        height: 260,
        decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF111111), boxShadow: [BoxShadow(color: col.primary.withOpacity(.5), blurRadius: 40)]),
        child: Stack(alignment: Alignment.center, children: [
          for (final d in [244.0, 222.0, 200.0])
            Container(width: d, height: d, decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white12))),
          cover(widget.id, 140, circle: true),
          Container(width: 16, height: 16, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black)),
        ]),
      ),
    );
  }
}

Widget controls(BuildContext c, String id) {
  final col = Theme.of(c).colorScheme;
  final fav = app.favs.contains(id);
  return Column(children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      StreamBuilder<bool>(
        stream: app.player.shuffleModeEnabledStream,
        builder: (c, sh) {
          final on = sh.data ?? false;
          return IconButton(icon: Icon(Icons.shuffle, color: on ? col.primary : null), onPressed: () => app.player.setShuffleModeEnabled(!on));
        },
      ),
      IconButton(iconSize: 36, icon: const Icon(Icons.skip_previous), onPressed: () => app.player.seekToPrevious()),
      const PlayBtn(size: 56),
      IconButton(iconSize: 36, icon: const Icon(Icons.skip_next), onPressed: () => app.player.seekToNext()),
      StreamBuilder<LoopMode>(
        stream: app.player.loopModeStream,
        builder: (c, lm) {
          final m = lm.data ?? LoopMode.off;
          return IconButton(
            icon: Icon(m == LoopMode.one ? Icons.repeat_one : Icons.repeat, color: m == LoopMode.off ? null : col.primary),
            onPressed: () => app.player.setLoopMode(LoopMode.values[(m.index + 1) % 3]),
          );
        },
      ),
    ]),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      IconButton(
        icon: Icon(fav ? Icons.favorite : Icons.favorite_border, color: fav ? col.primary : null),
        onPressed: () {
          if (!app.favs.remove(id)) app.favs.add(id);
          app.save();
        },
      ),
      IconButton(icon: const Icon(Icons.lyrics_outlined), tooltip: t('lyrics'), onPressed: () => lyricsSheet(c, id)),
      IconButton(icon: const Icon(Icons.equalizer), tooltip: t('eq'), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const EqPage()))),
      PopupMenuButton<int>(
        icon: Icon(Icons.bedtime_outlined, color: app.sleepMin > 0 ? col.primary : null),
        onSelected: app.setSleep,
        itemBuilder: (_) => [
          for (final m in [0, 15, 30, 60]) PopupMenuItem(value: m, child: Text(m == 0 ? t('off') : '$m ${t('min')}')),
        ],
      ),
      IconButton(icon: const Icon(Icons.edit_note), tooltip: t('info'), onPressed: () => editInfo(c, id)),
    ]),
  ]);
}

class NowPlaying extends StatelessWidget {
  const NowPlaying({super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => StreamBuilder<SequenceState?>(
          stream: app.player.sequenceStateStream,
          builder: (c, snap) {
            final id = (snap.data?.currentSource?.tag as MediaItem?)?.id;
            final s = id == null ? null : app.songs[id];
            final col = Theme.of(c).colorScheme;
            final back = IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(c));
            if (s == null) return Scaffold(appBar: AppBar(leading: back), body: Center(child: Text(t('nothing'))));
            final sid = id!;
            final st = app.style;
            final left = st == 0;
            final sub = s.artist.isEmpty ? '' : (s.album.isEmpty ? s.artist : '${s.artist} • ${s.album}');
            final titleBlock = SizedBox(
              width: double.infinity,
              child: Column(crossAxisAlignment: left ? CrossAxisAlignment.start : CrossAxisAlignment.center, children: [
                Text(
                  s.title,
                  textAlign: left ? TextAlign.left : TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: st == 1 ? FontWeight.w300 : FontWeight.w800, fontSize: st == 1 ? 32 : null),
                ),
                if (sub.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: col.onSurface.withOpacity(.7))),
                  ),
              ]),
            );
            Widget head;
            if (st == 2) {
              head = Vinyl(sid);
            } else if (st == 1) {
              head = const SizedBox.shrink();
            } else {
              head = Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [BoxShadow(color: col.primary.withOpacity(st == 3 ? .55 : .3), blurRadius: st == 3 ? 50 : 30, spreadRadius: 2)],
                ),
                child: cover(sid, 270),
              );
            }
            final panel = Column(children: [titleBlock, const SizedBox(height: 8), const SeekBar(), controls(c, sid)]);
            return Scaffold(
              appBar: AppBar(leading: back),
              body: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Column(children: [
                  const Spacer(),
                  head,
                  const Spacer(),
                  if (st == 3) glass(c, panel, r: 28, padding: const EdgeInsets.all(16)) else panel,
                ]),
              ),
            );
          },
        ),
      );
}

class EqPage extends StatefulWidget {
  const EqPage({super.key});
  @override
  State<EqPage> createState() => _EqState();
}

class _EqState extends State<EqPage> {
  AndroidEqualizerParameters? ps;
  bool err = false;
  List<double> gains = [];
  @override
  void initState() {
    super.initState();
    app.eq.parameters.then((v) {
      if (mounted) {
        setState(() {
          ps = v;
          gains = [for (final b in v.bands) b.gain];
        });
      }
    }).catchError((_) {
      if (mounted) setState(() => err = true);
    });
  }

  void preset(int k) {
    final pr = ps!;
    final n = pr.bands.length;
    final mx = pr.maxDecibels;
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? 0.0 : i / (n - 1);
      double v = 0;
      if (k == 1) v = (1 - 2 * x).clamp(0.0, 1.0).toDouble() * mx * .8;
      if (k == 2) v = (2 * x - 1).clamp(0.0, 1.0).toDouble() * mx * .8;
      if (k == 3) v = (1 - (x - .55).abs() * 2.2).clamp(0.0, 1.0).toDouble() * mx * .6;
      gains[i] = v;
      pr.bands[i].setGain(v);
    }
    setState(() {});
  }

  String fq(double f) => f >= 1000 ? '${(f / 1000).toStringAsFixed(f % 1000 == 0 ? 0 : 1)}k' : '${f.round()}';

  @override
  Widget build(BuildContext c) {
    final pr = ps;
    return Scaffold(
      appBar: AppBar(title: Text(t('eq'))),
      body: pr == null
          ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(err ? t('eq_err') : '...', textAlign: TextAlign.center)))
          : ListView(padding: const EdgeInsets.all(16), children: [
              SwitchListTile(
                title: Text(t('eq_on')),
                value: app.eqOn,
                onChanged: (v) async {
                  await app.eq.setEnabled(v);
                  app.eqOn = v;
                  setState(() {});
                },
              ),
              Wrap(spacing: 8, children: [
                for (final e in {0: 'flat', 1: 'bass', 2: 'treble', 3: 'vocal'}.entries)
                  ActionChip(label: Text(t(e.value)), onPressed: () => preset(e.key)),
              ]),
              const SizedBox(height: 12),
              for (var i = 0; i < pr.bands.length; i++)
                Row(children: [
                  SizedBox(width: 48, child: Text(fq(pr.bands[i].centerFrequency))),
                  Expanded(
                    child: Slider(
                      min: pr.minDecibels,
                      max: pr.maxDecibels,
                      value: gains[i].clamp(pr.minDecibels, pr.maxDecibels).toDouble(),
                      onChanged: (v) {
                        gains[i] = v;
                        pr.bands[i].setGain(v);
                        setState(() {});
                      },
                    ),
                  ),
                ]),
            ]),
    );
  }
}

/* ---------- settings & home ---------- */

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  static const cols = [0xFF9B1D45, 0xFFE91E63, 0xFFD32F2F, 0xFFFF6F00, 0xFFFBC02D, 0xFF2E7D32, 0xFF00897B, 0xFF0288D1, 0xFF3949AB, 0xFF7B1FA2, 0xFF8D6E63, 0xFF455A64];
  Widget sec(String s) => Padding(padding: const EdgeInsets.fromLTRB(16, 20, 16, 8), child: Text(s, style: const TextStyle(fontWeight: FontWeight.w700)));
  Widget chips<T>(Map<T, String> m, T cur, void Function(T) on) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Wrap(spacing: 8, children: [
          for (final e in m.entries) ChoiceChip(label: Text(e.value), selected: cur == e.key, onSelected: (_) => on(e.key)),
        ]),
      );
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => Scaffold(
          appBar: AppBar(title: Text(t('settings'))),
          body: ListView(children: [
            sec(t('theme_mode')),
            chips<int>({0: t('system'), 1: t('light'), 2: t('dark'), 3: t('amoled')}, app.mode, (v) => app.pref(m: v)),
            sec(t('color')),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(spacing: 12, runSpacing: 12, children: [
                for (final x in cols)
                  GestureDetector(
                    onTap: () => app.pref(acc: x),
                    child: CircleAvatar(radius: 20, backgroundColor: Color(x), child: app.accent == x ? const Icon(Icons.check, color: Colors.white) : null),
                  ),
                GestureDetector(
                  onTap: () => customColor(c),
                  child: CircleAvatar(radius: 20, backgroundColor: Theme.of(c).colorScheme.surfaceContainerHighest, child: const Icon(Icons.colorize, size: 18)),
                ),
              ]),
            ),
            sec(t('style')),
            chips<int>({0: t('s0'), 1: t('s1'), 2: t('s2'), 3: t('s3')}, app.style, (v) => app.pref(st: v)),
            sec(t('lang')),
            chips<String>({'bn': 'বাংলা', 'en': 'English'}, app.lang, (v) => app.pref(l: v)),
            const SizedBox(height: 12),
            SwitchListTile(title: Text(t('auto_online')), value: app.autoOnline, onChanged: (v) => app.pref(auto: v)),
            ListTile(
              leading: const Icon(Icons.equalizer),
              title: Text(t('eq')),
              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const EqPage())),
            ),
          ]),
        ),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int tab = 0;
  String q = '';
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) {
          final favIds = app.lib.where(app.favs.contains).toList();
          final pages = <Widget>[
            Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
                child: TextField(
                  decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: t('search'), isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(28))),
                  onChanged: (v) => setState(() => q = v),
                ),
              ),
              Expanded(child: SongList(ids: app.lib, k: 'lib', q: q, reorder: true)),
            ]),
            const PlaylistsView(),
            SongList(ids: favIds, k: 'fav'),
            SongList(ids: app.recent, k: 'recent'),
          ];
          return Scaffold(
            appBar: AppBar(
              title: const Text('Velvet', style: TextStyle(fontWeight: FontWeight.w800)),
              actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const SettingsPage())))],
            ),
            body: pages[tab],
            floatingActionButton: tab == 0
                ? FloatingActionButton.extended(
                    icon: const Icon(Icons.add),
                    label: Text(t('add')),
                    onPressed: () async {
                      final n = await app.importSongs();
                      if (n > 0 && c.mounted) {
                        ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text('$n ${t('added')}')));
                      }
                    },
                  )
                : null,
            bottomNavigationBar: Column(mainAxisSize: MainAxisSize.min, children: [
              const MiniPlayer(),
              NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (i) => setState(() => tab = i),
                destinations: [
                  NavigationDestination(icon: const Icon(Icons.music_note), label: t('songs')),
                  NavigationDestination(icon: const Icon(Icons.playlist_play), label: t('playlists')),
                  NavigationDestination(icon: const Icon(Icons.favorite), label: t('favs')),
                  NavigationDestination(icon: const Icon(Icons.history), label: t('recent')),
                ],
              ),
            ]),
          );
        },
      );
}
