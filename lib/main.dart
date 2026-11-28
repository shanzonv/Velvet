import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:audio_metadata_reader/audio_metadata_reader.dart' show readMetadata;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/* ================= strings ================= */

const L = <String, Map<String, String>>{
  'en': {
    'songs': 'Songs', 'playlists': 'Playlists', 'favs': 'Favorites', 'recent': 'Recent', 'dev': 'Developer',
    'settings': 'Settings', 'add': 'Add songs', 'search': 'Search songs', 'newpl': 'New playlist',
    'save': 'Save', 'cancel': 'Cancel', 'del': 'Delete', 'rename': 'Rename', 'cover': 'Set cover',
    'addpl': 'Add to playlist', 'rmpl': 'Remove from playlist', 'empty': 'No songs here yet.',
    'theme_mode': 'Theme mode', 'color': 'Accent color', 'style': 'UI style', 'lang': 'Language',
    'system': 'System', 'light': 'Light', 'dark': 'Dark', 'amoled': 'Black (AMOLED)',
    's0': 'Classic', 's1': 'Minimal', 's2': 'Vinyl', 's3': 'Glass', 'off': 'Off', 'min': 'min',
    'fav': 'Favorite', 'added': 'songs added', 'nothing': 'Nothing playing', 'sure': 'Delete this song for good?',
    'custom': 'Custom color', 'eq': 'Equalizer', 'eq_on': 'Enable equalizer', 'lyrics': 'Lyrics',
    'info': 'Edit info', 'title': 'Title', 'artist': 'Artist', 'album': 'Album', 'edit': 'Edit',
    'fetch': 'Fetch info & lyrics', 'save_fetch': 'Save & Fetch', 'reset': 'Reset to original',
    'found': 'Info updated', 'notfound': 'Nothing found (check your internet)',
    'flat': 'Flat', 'bass': 'Bass', 'treble': 'Treble', 'vocal': 'Vocal',
    'eq_err': 'Equalizer is not ready. Play a song first.',
    'sug': 'Possible match', 'sleep_q': 'How many minutes?', 'custom_t': 'Custom', 'copied': 'Copied',
    'dev_name': 'Name', 'font': 'Font', 'font_def': 'Default', 'font_add': 'Add your own font',
    'font_prev': 'Show font previews (needs internet)', 'font_en': 'English', 'font_bn': 'Bengali supported',
    'font_mine': 'My fonts (long-press to delete)', 'font_del': 'Delete this font?',
    'vol': 'Volume', 'vol_main': 'Velvet volume', 'vol_song': 'This song', 'vol_boost': 'Boost',
    'vol_warn': 'High boost can distort the sound. Lower it if you hear crackling.',
    'set_tags': 'Read info from inside song files', 'set_alyr': 'Find lyrics online automatically',
    'set_look': 'Suggest matches from file name (asks before applying)',
    'lyr_tag': 'From file', 'lyr_online': 'Online', 'lyr_mine': 'Mine', 'lyr_off': 'Off',
    'lyr_none': 'Lyrics are turned off for this song.', 'lyr_del': 'Delete this version',
    'lyr_file': 'Import .lrc / .txt', 'no_lyrics': 'No lyrics yet. Type them, import a file, or fetch online.',
    'fx': 'Sound FX', 'fx_all': 'All songs', 'fx_song': 'Only this song', 'speed': 'Speed', 'pitch': 'Pitch',
    'link': 'Pitch follows speed', 'fx_reset': 'Reset all', 'fx_global': 'Use the all-songs setting',
    'fx_note': 'Speed/pitch support can vary by phone.', 'notif': 'Allow notifications to see song controls.',
  },
  'bn': {
    'songs': 'গান', 'playlists': 'প্লেলিস্ট', 'favs': 'প্রিয়', 'recent': 'সাম্প্রতিক', 'dev': 'ডেভেলপার',
    'settings': 'সেটিংস', 'add': 'গান যোগ করুন', 'search': 'গান খুঁজুন', 'newpl': 'নতুন প্লেলিস্ট',
    'save': 'সেভ', 'cancel': 'বাতিল', 'del': 'মুছে ফেলুন', 'rename': 'নাম বদলান', 'cover': 'কভার সেট করুন',
    'addpl': 'প্লেলিস্টে যোগ করুন', 'rmpl': 'প্লেলিস্ট থেকে সরান', 'empty': 'এখানে এখনো কোনো গান নেই।',
    'theme_mode': 'থিম মোড', 'color': 'অ্যাক্সেন্ট রঙ', 'style': 'UI স্টাইল', 'lang': 'ভাষা',
    'system': 'সিস্টেম', 'light': 'লাইট', 'dark': 'ডার্ক', 'amoled': 'কালো (AMOLED)',
    's0': 'ক্লাসিক', 's1': 'মিনিমাল', 's2': 'ভিনাইল', 's3': 'গ্লাস', 'off': 'বন্ধ', 'min': 'মিনিট',
    'fav': 'প্রিয়তে যোগ/সরান', 'added': 'টি গান যোগ হয়েছে', 'nothing': 'কিছু চলছে না', 'sure': 'গানটি চিরতরে মুছবেন?',
    'custom': 'নিজের পছন্দের রঙ', 'eq': 'ইকুয়ালাইজার', 'eq_on': 'ইকুয়ালাইজার চালু করুন', 'lyrics': 'লিরিক্স',
    'info': 'তথ্য এডিট করুন', 'title': 'গানের নাম', 'artist': 'শিল্পী', 'album': 'অ্যালবাম', 'edit': 'এডিট',
    'fetch': 'তথ্য ও লিরিক্স খুঁজুন (Fetch)', 'save_fetch': 'সেভ ও Fetch', 'reset': 'আগের অবস্থায় ফেরান',
    'found': 'তথ্য আপডেট হয়েছে', 'notfound': 'কিছু পাওয়া যায়নি (ইন্টারনেট দেখুন)',
    'flat': 'ফ্ল্যাট', 'bass': 'বেস', 'treble': 'ট্রেবল', 'vocal': 'ভোকাল',
    'eq_err': 'ইকুয়ালাইজার এখনো তৈরি না। আগে একটা গান চালান।',
    'sug': 'সম্ভাব্য মিল', 'sleep_q': 'কত মিনিট?', 'custom_t': 'কাস্টম', 'copied': 'কপি হয়েছে',
    'dev_name': 'নাম', 'font': 'ফন্ট', 'font_def': 'ডিফল্ট', 'font_add': 'নিজের ফন্ট যোগ করুন',
    'font_prev': 'ফন্টের চেহারা দেখান (ইন্টারনেট লাগবে)', 'font_en': 'ইংরেজি', 'font_bn': 'বাংলা সমর্থন করে',
    'font_mine': 'আমার ফন্ট (লং-প্রেস করলে মুছবে)', 'font_del': 'ফন্টটি মুছবেন?',
    'vol': 'ভলিউম', 'vol_main': 'Velvet-এর ভলিউম', 'vol_song': 'এই গান', 'vol_boost': 'বুস্ট',
    'vol_warn': 'বেশি বুস্টে আওয়াজ ফেটে যেতে পারে। খচখচ শুনলে কমিয়ে দিন।',
    'set_tags': 'গানের ফাইলের ভেতরের তথ্য পড়ো', 'set_alyr': 'ইন্টারনেটে লিরিক্স নিজে খোঁজো',
    'set_look': 'ফাইলের নাম থেকে সম্ভাব্য মিল খোঁজো (বসানোর আগে জিজ্ঞেস করবে)',
    'lyr_tag': 'ফাইল থেকে', 'lyr_online': 'অনলাইন', 'lyr_mine': 'আমার', 'lyr_off': 'বন্ধ',
    'lyr_none': 'এই গানের লিরিক্স বন্ধ করা আছে।', 'lyr_del': 'এই সংস্করণ মুছুন',
    'lyr_file': '.lrc / .txt ফাইল থেকে নিন', 'no_lyrics': 'এখনো লিরিক্স নেই। লিখুন, ফাইল থেকে নিন বা অনলাইনে খুঁজুন।',
    'fx': 'সাউন্ড FX', 'fx_all': 'সব গানের জন্য', 'fx_song': 'শুধু এই গানের জন্য', 'speed': 'স্পিড', 'pitch': 'পিচ',
    'link': 'স্পিডের সাথে পিচও বদলাক', 'fx_reset': 'সব রিসেট', 'fx_global': 'সব গানের সেটিং ব্যবহার করো',
    'fx_note': 'স্পিড/পিচের সমর্থন ফোন অনুযায়ী আলাদা হতে পারে।', 'notif': 'গানের কন্ট্রোল দেখতে নোটিফিকেশনের অনুমতি দিন।',
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

/* ================= models ================= */

class Lyr {
  String src, text;
  Lyr(this.src, this.text);
}

class Sug {
  String t, a, al;
  String? u;
  Sug(this.t, this.a, this.al, this.u);
}

class Hit {
  String title, artist, album;
  String? art;
  int dur;
  double score;
  Hit(this.title, this.artist, this.album, this.art, this.dur, this.score);
}

class Fx {
  bool eqOn, link;
  double speed, pitch;
  List<double> gains;
  Fx({this.eqOn = false, this.link = false, this.speed = 1.0, this.pitch = 1.0, List<double>? gains}) : gains = gains ?? [];
  Fx copy() => Fx(eqOn: eqOn, link: link, speed: speed, pitch: pitch, gains: List<double>.from(gains));
  Map<String, dynamic> toJ() => {'e': eqOn, 'l': link, 's': speed, 'p': pitch, 'g': gains};
  static Fx fromJ(dynamic m) => Fx(
        eqOn: m['e'] ?? false,
        link: m['l'] ?? false,
        speed: (m['s'] ?? 1.0).toDouble(),
        pitch: (m['p'] ?? 1.0).toDouble(),
        gains: [for (final x in (m['g'] ?? [])) (x as num).toDouble()],
      );
}

class Song {
  String id, title, file, artist, album, fname, ot, oa, oal;
  String? cover, oc;
  bool locked = false, lyTried = false, sugTried = false;
  int li = -1, dur;
  double vol = 1.0;
  List<Lyr> lyr = [];
  Sug? sug;
  Fx? fx;
  Song(this.id, this.title, this.file, {this.artist = '', this.album = '', this.cover, this.fname = '', this.dur = 0})
      : ot = title,
        oa = artist,
        oal = album,
        oc = cover;

  Map<String, dynamic> toJ() => {
        'i': id, 't': title, 'f': file, 'c': cover, 'a': artist, 'al': album, 'fn': fname, 'd': dur,
        'ot': ot, 'oa': oa, 'oal': oal, 'oc': oc, 'lk': locked, 'lt': lyTried, 'st': sugTried,
        'li': li, 'v': vol,
        'ly': [for (final x in lyr) {'s': x.src, 't': x.text}],
        'sg': sug == null ? null : {'t': sug!.t, 'a': sug!.a, 'al': sug!.al, 'u': sug!.u},
        'fx': fx?.toJ(),
      };

  static Song fromJ(dynamic m) {
    final s = Song(m['i'], m['t'], m['f'], artist: m['a'] ?? '', album: m['al'] ?? '', cover: m['c'], fname: m['fn'] ?? '', dur: m['d'] ?? 0);
    s.ot = m['ot'] ?? s.title;
    s.oa = m['oa'] ?? s.artist;
    s.oal = m['oal'] ?? s.album;
    s.oc = (m as Map).containsKey('oc') ? m['oc'] : s.cover;
    s.locked = m['lk'] ?? false;
    s.lyTried = m['lt'] ?? false;
    s.sugTried = m['st'] ?? false;
    s.li = m['li'] ?? -1;
    s.vol = (m['v'] ?? 1.0).toDouble();
    final ly = m['ly'];
    if (ly is List) {
      s.lyr = [for (final x in ly) Lyr(x['s'], x['t'])];
    } else if (ly is String && ly.isNotEmpty) {
      s.lyr = [Lyr('file', ly)];
      s.li = 0;
    }
    final sg = m['sg'];
    if (sg is Map) s.sug = Sug(sg['t'], sg['a'], sg['al'], sg['u']);
    final f = m['fx'];
    if (f is Map) s.fx = Fx.fromJ(f);
    return s;
  }
}

class PL {
  String id, name;
  List<String> ids;
  PL(this.id, this.name, this.ids);
  Map<String, dynamic> toJ() => {'i': id, 'n': name, 's': ids};
  static PL fromJ(dynamic m) => PL(m['i'], m['n'], List<String>.from(m['s']));
}

/* ================= app state ================= */

class S extends ChangeNotifier {
  late SharedPreferences sp;
  late Directory dir, fdir;
  final eq = AndroidEqualizer();
  final loud = AndroidLoudnessEnhancer();
  late final AudioPlayer player = AudioPlayer(audioPipeline: AudioPipeline(androidAudioEffects: [eq, loud]));
  Map<String, Song> songs = {};
  List<String> lib = [], recent = [];
  List<PL> pls = [];
  Set<String> favs = {};
  List<Map<String, String>> ufonts = [];
  Fx gfx = Fx();
  int accent = 0xFF9B1D45, mode = 0, style = 0, sleepMin = 0, bareN = 0;
  String lang = 'bn', font = 'sys', defArt = '';
  bool readTags = true, autoLyr = true, lookup = false, netOk = true, bgRun = false;
  double vol = 1.0, boost = 0;
  Timer? sleepT;

  String nid() => DateTime.now().microsecondsSinceEpoch.toString();
  String path(String f) => p.join(dir.path, f);
  String? coverPath(String id) {
    final c = songs[id]?.cover;
    return c == null ? null : path(c);
  }

  String? get curId => (player.sequenceState?.currentSource?.tag as MediaItem?)?.id;

  Future<void> loadPrefs() async {
    sp = await SharedPreferences.getInstance();
    accent = sp.getInt('acc') ?? accent;
    mode = sp.getInt('mode') ?? 0;
    style = sp.getInt('style') ?? 0;
    lang = sp.getString('lang') ?? 'bn';
    font = sp.getString('font') ?? 'sys';
    readTags = sp.getBool('tags') ?? true;
    autoLyr = sp.getBool('alyr') ?? true;
    lookup = sp.getBool('look') ?? false;
    vol = sp.getDouble('vol') ?? 1.0;
    boost = sp.getDouble('boost') ?? 0;
    bareN = sp.getInt('bare') ?? 0;
    final g = sp.getString('gfx');
    if (g != null) {
      try { gfx = Fx.fromJ(jsonDecode(g)); } catch (_) {}
    }
  }

  Future<void> load() async {
    final base = await getApplicationDocumentsDirectory();
    dir = Directory(p.join(base.path, 'velvet'));
    await dir.create(recursive: true);
    fdir = Directory(p.join(base.path, 'velvet_fonts'));
    await fdir.create(recursive: true);
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
    final uf = sp.getString('uf');
    if (uf != null) {
      ufonts = [for (final x in jsonDecode(uf)) Map<String, String>.from(x)];
      for (final f in ufonts) {
        await regFont(f['n']!, File(p.join(fdir.path, f['f']!)));
      }
    }
    await mkDef();
    String? last;
    player.sequenceStateStream.listen((s) {
      final id = (s?.currentSource?.tag as MediaItem?)?.id;
      if (id == null || id == last) return;
      last = id;
      recent.remove(id);
      recent.insert(0, id);
      if (recent.length > 30) recent.removeLast();
      save();
      applyVol();
      applyFx(id);
    });
    applyVol();
    background();
  }

  void save() {
    sp.setString('db', jsonEncode({
      'songs': [for (final s in songs.values) s.toJ()],
      'lib': lib, 'recent': recent, 'favs': favs.toList(),
      'pls': [for (final x in pls) x.toJ()],
    }));
    notifyListeners();
  }

  void saveFx() {
    sp.setString('gfx', jsonEncode(gfx.toJ()));
    save();
  }

  void pref({int? acc, int? m, int? st, String? l, String? fnt, bool? tags, bool? alyr, bool? look}) {
    if (acc != null) { accent = acc; sp.setInt('acc', acc); mkDef(); }
    if (m != null) { mode = m; sp.setInt('mode', m); }
    if (st != null) { style = st; sp.setInt('style', st); }
    if (l != null) { lang = l; sp.setString('lang', l); }
    if (fnt != null) { font = fnt; sp.setString('font', fnt); }
    if (tags != null) { readTags = tags; sp.setBool('tags', tags); }
    if (alyr != null) { autoLyr = alyr; sp.setBool('alyr', alyr); if (alyr) background(); }
    if (look != null) { lookup = look; sp.setBool('look', look); if (look) background(); }
    notifyListeners();
  }

  /* ---- default cover ---- */
  Future<void> mkDef() async {
    try {
      final f = File(path('def_${accent.toRadixString(16)}.png'));
      if (!await f.exists()) {
        const sz = 512.0;
        final rec = ui.PictureRecorder();
        final cv = ui.Canvas(rec);
        final h = HSLColor.fromColor(Color(accent));
        final a = h.withLightness(.45).withSaturation(.8).toColor();
        final b = HSLColor.fromAHSL(1, (h.hue + 40) % 360, .8, .3).toColor();
        cv.drawRect(Rect.fromLTWH(0, 0, sz, sz), ui.Paint()..shader = ui.Gradient.linear(Offset.zero, Offset(sz, sz), [a, b]));
        final tp = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(Icons.music_note.codePoint),
            style: TextStyle(fontSize: 280, fontFamily: Icons.music_note.fontFamily, package: Icons.music_note.fontPackage, color: Colors.white.withOpacity(.9)),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(cv, Offset((sz - tp.width) / 2, (sz - tp.height) / 2));
        final img = await rec.endRecording().toImage(512, 512);
        final bd = await img.toByteData(format: ui.ImageByteFormat.png);
        await f.writeAsBytes(bd!.buffer.asUint8List());
      }
      defArt = f.path;
    } catch (_) {}
  }

  /* ---- importing ---- */
  Future<int> importSongs() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (r == null) return 0;
    var n = 0;
    for (final f in r.files) {
      if (f.path == null) continue;
      final id = '${nid()}$n';
      final name = '$id${p.extension(f.path!)}';
      await File(f.path!).copy(path(name));
      var title = '', artist = '', album = '', lyr = '';
      var dur = 0;
      String? cov;
      if (readTags) {
        try {
          final dynamic md = await readMetadata(File(path(name)), getImage: true);
          title = tg(() => md.title);
          artist = tg(() => md.artist);
          album = tg(() => md.album);
          lyr = tg(() => md.lyrics);
          final d = md.duration;
          if (d is Duration) dur = d.inMilliseconds;
          final pics = md.pictures;
          if (pics != null && pics.isNotEmpty) {
            final dynamic pic = pics.first;
            final mt = tg(() => pic.mimetype).toLowerCase();
            final ext = mt.contains('png') ? '.png' : '.jpg';
            final cn = 'c${DateTime.now().microsecondsSinceEpoch}$n$ext';
            await File(path(cn)).writeAsBytes(List<int>.from(pic.bytes));
            cov = cn;
          }
        } catch (_) {}
      }
      if (title.isEmpty) {
        bareN++;
        sp.setInt('bare', bareN);
        title = 'Song #$bareN';
      }
      final s = Song(id, title, name, artist: artist, album: album, cover: cov, fname: p.basenameWithoutExtension(f.name), dur: dur);
      if (lyr.isNotEmpty) {
        s.lyr.add(Lyr('file', lyr));
        s.li = 0;
      }
      songs[id] = s;
      lib.add(id);
      n++;
    }
    save();
    background();
    return n;
  }

  /* ---- online helpers ---- */
  Future<dynamic> getJson(String url) async {
    final cl = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final rq = await cl.getUrl(Uri.parse(url));
      rq.headers.set('User-Agent', 'Velvet/1.1');
      final rs = await rq.close().timeout(const Duration(seconds: 12));
      netOk = true;
      if (rs.statusCode != 200) {
        await rs.drain<void>();
        return null;
      }
      return jsonDecode(await rs.transform(utf8.decoder).join());
    } catch (_) {
      netOk = false;
      return null;
    } finally {
      cl.close();
    }
  }

  Set<String> tok(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'\(.*?\)|\[.*?\]'), ' ')
      .replaceAll(RegExp(r'[^a-z0-9\u0980-\u09ff ]'), ' ')
      .split(' ')
      .where((e) => e.isNotEmpty)
      .toSet();

  double sim(String a, String b) {
    final x = tok(a), y = tok(b);
    if (x.isEmpty || y.isEmpty) return 0;
    return x.intersection(y).length / (x.length > y.length ? x.length : y.length);
  }

  String clean(String f) => f.replaceAll(RegExp(r'[_\-.]+'), ' ').replaceAll(RegExp(r'^\d+\s+'), '').replaceAll(RegExp(r'\s+'), ' ').trim();

  Future<Hit?> find(String title, String artist, int durMs, {required double minSim, required int tol}) async {
    final q = Uri.encodeQueryComponent('$title $artist'.trim());
    final j = await getJson('https://itunes.apple.com/search?term=$q&entity=song&limit=10');
    if (j is! Map || j['results'] is! List) return null;
    Hit? best;
    for (final r in j['results']) {
      final tn = (r['trackName'] ?? '').toString();
      final an = (r['artistName'] ?? '').toString();
      final ts = sim(title, tn);
      final asim = artist.isEmpty ? .5 : sim(artist, an);
      if (ts < minSim) continue;
      if (artist.isNotEmpty && asim < .3) continue;
      final d = (r['trackTimeMillis'] is num) ? (r['trackTimeMillis'] as num).toInt() : 0;
      final diff = (durMs > 0 && d > 0) ? (d - durMs).abs() : -1;
      if (diff > tol) continue;
      final sc = ts * .6 + asim * .25 + (diff >= 0 ? (1 - diff / tol) * .15 : 0.0);
      if (best == null || sc > best.score) {
        best = Hit(tn, an, (r['collectionName'] ?? '').toString(), r['artworkUrl100']?.toString(), d, sc);
      }
    }
    return best;
  }

  Future<String?> lyricsFor(Song s) async {
    final dur = s.dur > 0 ? (s.dur / 1000).round() : 0;
    final base = 'track_name=${Uri.encodeQueryComponent(s.title)}&artist_name=${Uri.encodeQueryComponent(s.artist)}';
    final alb = s.album.isEmpty ? '' : '&album_name=${Uri.encodeQueryComponent(s.album)}';
    final du = dur > 0 ? '&duration=$dur' : '';
    final j = await getJson('https://lrclib.net/api/get?$base$alb$du');
    String? txt = (j is Map && j['plainLyrics'] is String) ? j['plainLyrics'] as String : null;
    if (txt == null || txt.trim().isEmpty) {
      final l = await getJson('https://lrclib.net/api/search?$base');
      if (l is List) {
        for (final r in l) {
          final d = (r['duration'] is num) ? (r['duration'] as num).toDouble() : 0.0;
          if (dur > 0 && d > 0 && (d - dur).abs() > 4) continue;
          final pl = r['plainLyrics'];
          if (pl is String && pl.trim().isNotEmpty && sim(s.title, (r['trackName'] ?? '').toString()) >= .5) {
            txt = pl;
            break;
          }
        }
      }
    }
    return (txt == null || txt.trim().isEmpty) ? null : txt.trim();
  }

  Future<bool> saveArt(Song s, String url) async {
    final cl = HttpClient()..connectionTimeout = const Duration(seconds: 6);
    try {
      final u = url.replaceAll('100x100bb', '600x600bb');
      final rq = await cl.getUrl(Uri.parse(u));
      final rs = await rq.close().timeout(const Duration(seconds: 15));
      if (rs.statusCode != 200) return false;
      final bytes = <int>[];
      await for (final ch in rs) {
        bytes.addAll(ch);
      }
      final cn = 'c${DateTime.now().microsecondsSinceEpoch}.jpg';
      await File(path(cn)).writeAsBytes(bytes);
      rmCover(s);
      s.cover = cn;
      return true;
    } catch (_) {
      return false;
    } finally {
      cl.close();
    }
  }

  void rmCover(Song s) {
    final c = s.cover;
    if (c != null && c != s.oc) {
      try { File(path(c)).deleteSync(); } catch (_) {}
    }
  }

  /* ---- manual fetch / suggestions / background ---- */
  Future<bool> fetch(String id) async {
    final s = songs[id];
    if (s == null) return false;
    var got = false;
    final h = await find(s.title, s.artist, s.dur, minSim: .5, tol: 8000);
    if (h != null) {
      if (s.album.isEmpty && h.album.isNotEmpty) s.album = h.album;
      if (s.cover == null && h.art != null) await saveArt(s, h.art!);
      got = true;
    }
    final ly = await lyricsFor(s);
    if (ly != null) {
      addLyr(s, 'online', ly, activate: true);
      got = true;
    }
    s.lyTried = true;
    if (got) save();
    return got;
  }

  Future<void> applySug(String id) async {
    final s = songs[id];
    final g = s?.sug;
    if (s == null || g == null) return;
    s.title = g.t;
    s.artist = g.a;
    s.album = g.al;
    s.sug = null;
    s.lyTried = false;
    if (s.cover == null && g.u != null) await saveArt(s, g.u!);
    save();
    background();
  }

  Future<void> background() async {
    if (bgRun) return;
    bgRun = true;
    try {
      for (final s in songs.values.toList()) {
        if (!songs.containsKey(s.id)) continue;
        if (autoLyr && s.artist.isNotEmpty && s.lyr.isEmpty && !s.lyTried) {
          final ly = await lyricsFor(s);
          if (!netOk) break;
          s.lyTried = true;
          if (ly != null) addLyr(s, 'online', ly, activate: true);
          save();
        }
        if (lookup && s.sug == null && s.artist.isEmpty && s.fname.isNotEmpty && s.dur > 0 && !s.sugTried) {
          final h = await find(clean(s.fname), '', s.dur, minSim: .6, tol: 3000);
          if (!netOk) break;
          s.sugTried = true;
          if (h != null) s.sug = Sug(h.title, h.artist, h.album, h.art);
          save();
        }
      }
    } finally {
      bgRun = false;
    }
  }

  /* ---- lyrics versions ---- */
  String? activeLyr(Song s) => (s.li >= 0 && s.li < s.lyr.length) ? s.lyr[s.li].text : null;

  void addLyr(Song s, String src, String text, {bool activate = false}) {
    final act = (s.li >= 0 && s.li < s.lyr.length) ? s.lyr[s.li] : null;
    if (src == 'online') s.lyr.removeWhere((x) => x.src == 'online');
    s.lyr.add(Lyr(src, text));
    if (activate) {
      s.li = s.lyr.length - 1;
    } else if (act != null && s.lyr.contains(act)) {
      s.li = s.lyr.indexOf(act);
    } else {
      s.li = -1;
    }
  }

  void delLyr(Song s, int i) {
    if (i < 0 || i >= s.lyr.length) return;
    s.lyr.removeAt(i);
    if (s.li == i) {
      s.li = s.lyr.isEmpty ? -1 : 0;
    } else if (s.li > i) {
      s.li--;
    }
    save();
  }

  Future<void> importLyrics(String id) async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['lrc', 'txt']);
    final f = r?.files.single.path;
    final s = songs[id];
    if (f == null || s == null) return;
    try {
      var txt = await File(f).readAsString();
      txt = txt.replaceAll(RegExp(r'\[\d{1,2}:\d{2}(?:[.:]\d{1,3})?\]'), '').replaceAll(RegExp(r'\[[a-z]{2}:.*?\]\n?'), '').trim();
      addLyr(s, 'mine', txt, activate: true);
      save();
    } catch (_) {}
  }

  /* ---- editing ---- */
  void resetInfo(String id) {
    final s = songs[id];
    if (s == null) return;
    if (s.cover != s.oc) rmCover(s);
    s.title = s.ot;
    s.artist = s.oa;
    s.album = s.oal;
    s.cover = s.oc;
    s.locked = false;
    save();
  }

  Future<void> setCover(String id) async {
    final r = await FilePicker.platform.pickFiles(type: FileType.image);
    final f = r?.files.single.path;
    final s = songs[id];
    if (f == null || s == null) return;
    final n = 'c${DateTime.now().millisecondsSinceEpoch}${p.extension(f)}';
    await File(f).copy(path(n));
    rmCover(s);
    s.cover = n;
    s.locked = true;
    save();
  }

  Future<void> delSong(String id) async {
    if (curId == id) await player.stop();
    final s = songs.remove(id);
    if (s == null) return;
    for (final f in {s.file, s.cover, s.oc}) {
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

  /* ---- playback, volume, fx ---- */
  Uri? artOf(String id) {
    final a = coverPath(id) ?? (defArt.isEmpty ? null : defArt);
    return a == null ? null : Uri.file(a);
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
                artUri: artOf(id))),
    ]);
    await player.setAudioSource(src, initialIndex: i);
    applyVol();
    applyBoost();
    applyFx(ids[i]);
    player.play();
  }

  void applyVol() {
    final id = curId;
    final sv = id == null ? 1.0 : (songs[id]?.vol ?? 1.0);
    player.setVolume((vol * sv).clamp(0.0, 1.0).toDouble());
  }

  Future<void> applyBoost() async {
    try {
      await loud.setEnabled(boost > 0);
      await loud.setTargetGain(boost);
    } catch (_) {}
  }

  void setVol(double v) {
    vol = v;
    sp.setDouble('vol', v);
    applyVol();
    notifyListeners();
  }

  Future<void> setBoost(double b) async {
    boost = b;
    sp.setDouble('boost', b);
    notifyListeners();
    await applyBoost();
  }

  Fx fxFor(String? id) => (id == null ? null : songs[id]?.fx) ?? gfx;

  Future<void> applyFx([String? id]) async {
    final f = fxFor(id ?? curId);
    try {
      await player.setSpeed(f.speed);
      await player.setPitch(f.link ? f.speed : f.pitch);
    } catch (_) {}
    try {
      await eq.setEnabled(f.eqOn);
      final ps = await eq.parameters;
      for (var i = 0; i < ps.bands.length; i++) {
        await ps.bands[i].setGain(i < f.gains.length ? f.gains[i] : 0.0);
      }
    } catch (_) {}
  }

  void setSleep(int m) {
    sleepT?.cancel();
    sleepMin = m;
    if (m > 0) {
      sleepT = Timer(Duration(minutes: m), () {
        player.pause();
        sleepMin = 0;
        notifyListeners();
      });
    }
    notifyListeners();
  }

  /* ---- fonts ---- */
  Future<void> regFont(String family, File f) async {
    try {
      final b = await f.readAsBytes();
      final l = FontLoader(family)..addFont(Future.value(ByteData.sublistView(b)));
      await l.load();
    } catch (_) {}
  }

  Future<bool> addUserFont() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['ttf', 'otf']);
    final f = r?.files.single.path;
    if (f == null) return false;
    final fam = p.basenameWithoutExtension(f).replaceAll(RegExp(r'[_\-]+'), ' ').trim();
    final fn = 'f${nid()}${p.extension(f)}';
    await File(f).copy(p.join(fdir.path, fn));
    await regFont(fam, File(p.join(fdir.path, fn)));
    ufonts.removeWhere((e) => e['n'] == fam);
    ufonts.add({'n': fam, 'f': fn});
    sp.setString('uf', jsonEncode(ufonts));
    pref(fnt: 'u:$fam');
    return true;
  }

  void delUserFont(String fam) {
    for (final x in ufonts.where((x) => x['n'] == fam)) {
      try { File(p.join(fdir.path, x['f']!)).deleteSync(); } catch (_) {}
    }
    ufonts.removeWhere((x) => x['n'] == fam);
    sp.setString('uf', jsonEncode(ufonts));
    if (font == 'u:$fam') {
      pref(fnt: 'sys');
    } else {
      notifyListeners();
    }
  }
}

final app = S();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await app.loadPrefs();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.velvet.channel.audio',
    androidNotificationChannelName: 'Velvet',
    androidNotificationOngoing: true,
    notificationColor: Color(app.accent),
  );
  await app.load();
  runApp(const VelvetApp());
}

/* ================= style helpers ================= */

double rad() => const [14.0, 4.0, 30.0, 20.0][app.style];

ThemeData mk(Brightness b, bool black) {
  var cs = ColorScheme.fromSeed(seedColor: Color(app.accent), brightness: b);
  if (black) cs = cs.copyWith(surface: Colors.black);
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(rad()));
  var th = ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(backgroundColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0),
    filledButtonTheme: FilledButtonThemeData(style: FilledButton.styleFrom(shape: shape)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(shape: shape)),
    chipTheme: ChipThemeData(shape: shape),
    snackBarTheme: SnackBarThemeData(shape: shape, behavior: SnackBarBehavior.floating),
    popupMenuTheme: PopupMenuThemeData(shape: shape),
  );
  final f = app.font;
  try {
    if (f.startsWith('g:')) {
      th = th.copyWith(textTheme: GoogleFonts.getTextTheme(f.substring(2), th.textTheme));
    } else if (f.startsWith('u:')) {
      th = th.copyWith(textTheme: th.textTheme.apply(fontFamily: f.substring(2)));
    }
  } catch (_) {}
  return th;
}

class VelvetApp extends StatelessWidget {
  const VelvetApp({super.key});
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

Widget glass(BuildContext c, Widget child, {double r = 18, EdgeInsets margin = EdgeInsets.zero, EdgeInsets padding = EdgeInsets.zero, Color? tint}) {
  final dark = Theme.of(c).brightness == Brightness.dark;
  return Container(
    margin: margin,
    child: ClipRRect(
      borderRadius: BorderRadius.circular(r),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: tint ?? Colors.white.withOpacity(dark ? .10 : .50),
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: Colors.white.withOpacity(dark ? .22 : .7)),
          ),
          child: child,
        ),
      ),
    ),
  );
}

PreferredSizeWidget appBar(BuildContext c, Widget title, {List<Widget>? actions, Widget? leading}) {
  final st = app.style;
  return AppBar(
    leading: leading,
    title: DefaultTextStyle.merge(
      style: TextStyle(fontWeight: st == 1 ? FontWeight.w300 : FontWeight.w800, letterSpacing: st == 1 ? 2 : 0, fontSize: 20),
      child: title,
    ),
    centerTitle: st == 2,
    actions: actions,
    flexibleSpace: st == 3
        ? ClipRect(child: BackdropFilter(filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14), child: Container(color: Colors.white.withOpacity(.06))))
        : null,
    shape: st == 1 ? Border(bottom: BorderSide(color: Theme.of(c).colorScheme.outline.withOpacity(.4))) : null,
  );
}

Widget addFab(BuildContext c, VoidCallback onTap) {
  switch (app.style) {
    case 1:
      return FloatingActionButton.small(
        onPressed: onTap,
        elevation: 0,
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4), side: BorderSide(color: Theme.of(c).colorScheme.primary)),
        child: const Icon(Icons.add),
      );
    case 2:
      return FloatingActionButton(onPressed: onTap, shape: const CircleBorder(), child: const Icon(Icons.add));
    case 3:
      return GestureDetector(
        onTap: onTap,
        child: glass(
          c,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.add), const SizedBox(width: 8), Text(t('add'))]),
          ),
          r: 30,
        ),
      );
    default:
      return FloatingActionButton.extended(onPressed: onTap, icon: const Icon(Icons.add), label: Text(t('add')));
  }
}

Widget searchBox(BuildContext c, ValueChanged<String> on) {
  final st = app.style;
  final cs = Theme.of(c).colorScheme;
  final InputBorder border = st == 1
      ? const UnderlineInputBorder()
      : (st == 3
          ? InputBorder.none
          : OutlineInputBorder(borderRadius: BorderRadius.circular(st == 2 ? 30 : 14), borderSide: st == 2 ? BorderSide.none : const BorderSide()));
  final field = TextField(
    onChanged: on,
    decoration: InputDecoration(
      prefixIcon: const Icon(Icons.search),
      hintText: t('search'),
      isDense: true,
      border: border,
      enabledBorder: border,
      focusedBorder: border,
      filled: st == 2,
      fillColor: cs.surfaceContainerHighest.withOpacity(.6),
    ),
  );
  return Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 4), child: st == 3 ? glass(c, field, r: 24) : field);
}

Future<T?> showDlg<T>(BuildContext c, String title, Widget content, List<Widget> Function(BuildContext) actions) {
  return showDialog<T>(
    context: c,
    builder: (d) {
      final st = app.style;
      final inner = Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Theme.of(d).textTheme.titleLarge),
        const SizedBox(height: 12),
        Flexible(child: SingleChildScrollView(child: content)),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: Wrap(spacing: 8, runSpacing: 4, alignment: WrapAlignment.end, children: actions(d))),
      ]);
      return Dialog(
        backgroundColor: st == 3 ? Colors.transparent : null,
        elevation: st == 3 ? 0 : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(rad()),
          side: st == 1 ? BorderSide(color: Theme.of(d).colorScheme.outline) : BorderSide.none,
        ),
        child: st == 3
            ? glass(d, inner, r: rad(), padding: const EdgeInsets.all(20), tint: Colors.black.withOpacity(.35))
            : Padding(padding: const EdgeInsets.all(20), child: inner),
      );
    },
  );
}

Future<T?> showSheet<T>(BuildContext c, Widget Function(BuildContext) builder, {bool full = false}) {
  return showModalBottomSheet<T>(
    context: c,
    isScrollControlled: full,
    backgroundColor: Colors.transparent,
    builder: (x) {
      final st = app.style;
      final cs = Theme.of(x).colorScheme;
      final body = builder(x);
      if (st == 3) return glass(x, body, r: 24, margin: const EdgeInsets.all(8), tint: Colors.black.withOpacity(.35));
      return Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.vertical(top: Radius.circular(rad() + 6)),
          border: st == 1 ? Border(top: BorderSide(color: cs.outline.withOpacity(.5))) : null,
        ),
        child: body,
      );
    },
  );
}

Future<String?> askText(BuildContext c, String title, String init, {int lines = 1, bool empty = false, bool digits = false}) {
  final ctl = TextEditingController(text: init);
  return showDlg<String>(
    c,
    title,
    TextField(
      controller: ctl,
      autofocus: true,
      minLines: 1,
      maxLines: lines,
      keyboardType: digits ? TextInputType.number : (lines > 1 ? TextInputType.multiline : TextInputType.text),
    ),
    (d) => [
      TextButton(onPressed: () => Navigator.pop(d), child: Text(t('cancel'))),
      FilledButton(
        onPressed: () => Navigator.pop(d, ctl.text.trim().isEmpty && !empty ? null : ctl.text.trim()),
        child: Text(t('save')),
      ),
    ],
  );
}

Widget cover(String id, double size, {bool circle = false}) {
  final cp = app.coverPath(id);
  return Builder(builder: (c) {
    Widget inner;
    if (cp == null) {
      final h = HSLColor.fromColor(Color(app.accent));
      inner = DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [h.withLightness(.5).withSaturation(.8).toColor(), HSLColor.fromAHSL(1, (h.hue + 40) % 360, .8, .32).toColor()],
          ),
        ),
        child: Center(child: Icon(Icons.music_note, size: size * .5, color: Colors.white.withOpacity(.9))),
      );
    } else {
      inner = Image.file(File(cp), fit: BoxFit.cover, cacheWidth: size.round() * 2, errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.music_note)));
    }
    final w = SizedBox(width: size, height: size, child: inner);
    return circle ? ClipOval(child: w) : ClipRRect(borderRadius: BorderRadius.circular(size > 100 ? 22 : 10), child: w);
  });
}

void snack(BuildContext c, String m) {
  if (c.mounted) ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));
}

/* ================= dialogs & sheets ================= */

void editInfo(BuildContext c, String id) {
  final s = app.songs[id]!;
  final a = TextEditingController(text: s.title);
  final b = TextEditingController(text: s.artist);
  final d = TextEditingController(text: s.album);
  void commit() {
    final nt = a.text.trim(), na = b.text.trim(), nl = d.text.trim();
    if (nt != s.title || na != s.artist || nl != s.album) {
      s.locked = true;
      s.lyTried = false;
    }
    if (nt.isNotEmpty) s.title = nt;
    s.artist = na;
    s.album = nl;
    app.save();
  }

  showDlg<void>(
    c,
    t('info'),
    Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: a, decoration: InputDecoration(labelText: t('title'))),
      TextField(controller: b, decoration: InputDecoration(labelText: t('artist'))),
      TextField(controller: d, decoration: InputDecoration(labelText: t('album'))),
    ]),
    (x) => [
      TextButton(onPressed: () { Navigator.pop(x); app.resetInfo(id); }, child: Text(t('reset'))),
      TextButton(onPressed: () => Navigator.pop(x), child: Text(t('cancel'))),
      FilledButton(onPressed: () { commit(); Navigator.pop(x); app.background(); }, child: Text(t('save'))),
      FilledButton.tonal(
        onPressed: () async {
          commit();
          Navigator.pop(x);
          final ok = await app.fetch(id);
          snack(c, t(ok ? 'found' : 'notfound'));
        },
        child: Text(t('save_fetch')),
      ),
    ],
  );
}

void confirmDel(BuildContext c, String id) {
  showDlg<void>(c, t('sure'), const SizedBox.shrink(), (d) => [
    TextButton(onPressed: () => Navigator.pop(d), child: Text(t('cancel'))),
    FilledButton(onPressed: () { Navigator.pop(d); app.delSong(id); }, child: Text(t('del'))),
  ]);
}

void addToPl(BuildContext c, String id) {
  showSheet<void>(
    c,
    (b) => SafeArea(
      child: SingleChildScrollView(
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
    ),
  );
}

void songMenu(BuildContext c, String id, PL? pl) {
  final s = app.songs[id]!;
  showSheet<void>(
    c,
    (b) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (s.sug != null)
            ListTile(
              leading: const Icon(Icons.lightbulb_outline),
              title: Text('${t('sug')}: ${s.sug!.t} — ${s.sug!.a}', maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: IconButton(icon: const Icon(Icons.close), onPressed: () { Navigator.pop(b); s.sug = null; app.save(); }),
              onTap: () { Navigator.pop(b); app.applySug(id); },
            ),
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
            title: Text(t('fetch')),
            onTap: () async {
              Navigator.pop(b);
              final ok = await app.fetch(id);
              snack(c, t(ok ? 'found' : 'notfound'));
            },
          ),
          ListTile(leading: const Icon(Icons.graphic_eq), title: Text(t('fx')), onTap: () { Navigator.pop(b); Navigator.push(c, MaterialPageRoute(builder: (_) => FxPage(id: id))); }),
          ListTile(leading: const Icon(Icons.volume_up_outlined), title: Text(t('vol')), onTap: () { Navigator.pop(b); volSheet(c, id: id); }),
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
  showSheet<void>(
    c,
    (b) => ListenableBuilder(
      listenable: app,
      builder: (_, __) {
        final s = app.songs[id];
        if (s == null) return const SizedBox.shrink();
        final txt = app.activeLyr(s);
        String nm(Lyr l) => l.src == 'file' ? t('lyr_tag') : (l.src == 'online' ? t('lyr_online') : t('lyr_mine'));
        return SizedBox(
          height: MediaQuery.of(b).size.height * .75,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(children: [
                Expanded(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: t('edit'),
                  onPressed: () async {
                    final v = await askText(b, t('lyrics'), app.activeLyr(s) ?? '', lines: 10);
                    if (v != null) {
                      if (s.li >= 0 && s.li < s.lyr.length && s.lyr[s.li].src == 'mine') {
                        s.lyr[s.li].text = v;
                      } else {
                        app.addLyr(s, 'mine', v, activate: true);
                      }
                      app.save();
                    }
                  },
                ),
                IconButton(icon: const Icon(Icons.file_open), tooltip: t('lyr_file'), onPressed: () => app.importLyrics(id)),
                IconButton(
                  icon: const Icon(Icons.cloud_download_outlined),
                  tooltip: t('fetch'),
                  onPressed: () async {
                    final ok = await app.fetch(id);
                    snack(b, t(ok ? 'found' : 'notfound'));
                  },
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Wrap(spacing: 8, children: [
                for (var i = 0; i < s.lyr.length; i++)
                  ChoiceChip(label: Text('${nm(s.lyr[i])} ${i + 1}'), selected: s.li == i, onSelected: (_) { s.li = i; app.save(); }),
                ChoiceChip(label: Text(t('lyr_off')), selected: s.li < 0, onSelected: (_) { s.li = -1; app.save(); }),
              ]),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Text(s.lyr.isEmpty ? t('no_lyrics') : (txt ?? t('lyr_none')), style: const TextStyle(fontSize: 18, height: 1.7)),
              ),
            ),
            if (txt != null)
              TextButton.icon(onPressed: () => app.delLyr(s, s.li), icon: const Icon(Icons.delete_outline), label: Text(t('lyr_del'))),
            const SizedBox(height: 12),
          ]),
        );
      },
    ),
    full: true,
  );
}

void volSheet(BuildContext c, {String? id}) {
  showSheet<void>(
    c,
    (b) => ListenableBuilder(
      listenable: app,
      builder: (_, __) {
        final s = id == null ? null : app.songs[id];
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t('vol'), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 8),
              Text('${t('vol_main')}: ${(app.vol * 100).round()}%'),
              Slider(min: .02, max: 1, value: app.vol.clamp(.02, 1.0).toDouble(), onChanged: app.setVol),
              if (s != null) ...[
                Text('${t('vol_song')}: ${(s.vol * 100).round()}%'),
                Slider(
                  min: .1,
                  max: 1,
                  value: s.vol.clamp(.1, 1.0).toDouble(),
                  onChanged: (v) { s.vol = v; app.applyVol(); app.save(); },
                ),
              ],
              Text('${t('vol_boost')}: +${app.boost.round()} dB'),
              Slider(max: 12, divisions: 12, value: app.boost.clamp(0.0, 12.0).toDouble(), onChanged: app.setBoost),
              Text(t('vol_warn'), style: const TextStyle(fontSize: 12)),
            ]),
          ),
        );
      },
    ),
  );
}

void customColor(BuildContext c) {
  var h = HSVColor.fromColor(Color(app.accent));
  showSheet<void>(
    c,
    (b) => StatefulBuilder(
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

/* ================= lists ================= */

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(st == 2 ? 40 : (st == 1 ? 4 : 12))),
          leading: st == 1
              ? SizedBox(width: 28, child: Center(child: Text('${index + 1}', style: TextStyle(color: on ? pr : null))))
              : cover(id, st == 0 ? 54 : 50, circle: st == 2),
          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: on ? pr : null, fontWeight: on ? FontWeight.w800 : (st == 0 ? FontWeight.w600 : null))),
          subtitle: s.artist.isEmpty ? null : Text(s.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (s.sug != null) Icon(Icons.lightbulb_outline, size: 16, color: pr),
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
        : ids.where((i) => '${app.songs[i]!.title} ${app.songs[i]!.artist}'.toLowerCase().contains(ql)).toList();
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
        builder: (c, _) => ListView(padding: const EdgeInsets.only(bottom: 96), children: [
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
                onPressed: () => showSheet<void>(
                  c,
                  (b) => SafeArea(
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
          appBar: appBar(c, Text(pl.name), actions: [
            IconButton(icon: const Icon(Icons.play_arrow), onPressed: () { if (pl.ids.isNotEmpty) app.playList(pl.ids, 0); }),
          ]),
          body: SongList(ids: pl.ids, k: pl.id, reorder: true, pl: pl),
        ),
      );
}

/* ================= player ================= */

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
            final cs = Theme.of(c).colorScheme;
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
            if (st == 2) {
              return Container(
                margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                decoration: BoxDecoration(color: cs.surfaceContainerHigh.withOpacity(.9), borderRadius: BorderRadius.circular(40)),
                child: inner,
              );
            }
            if (st == 1) {
              return Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outline.withOpacity(.4)))), child: inner);
            }
            return Container(color: cs.surfaceContainerHighest.withOpacity(.7), child: inner);
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
      IconButton(icon: const Icon(Icons.graphic_eq), tooltip: t('fx'), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => FxPage(id: id)))),
      IconButton(icon: const Icon(Icons.volume_up_outlined), tooltip: t('vol'), onPressed: () => volSheet(c, id: id)),
      PopupMenuButton<int>(
        icon: Icon(Icons.bedtime_outlined, color: app.sleepMin > 0 ? col.primary : null),
        onSelected: (m) async {
          if (m == -1) {
            final v = await askText(c, t('sleep_q'), '', digits: true);
            final n = int.tryParse(v ?? '');
            if (n != null && n > 0) app.setSleep(n);
          } else {
            app.setSleep(m);
          }
        },
        itemBuilder: (_) => [
          for (final m in [0, 15, 30, 60]) PopupMenuItem(value: m, child: Text(m == 0 ? t('off') : '$m ${t('min')}')),
          PopupMenuItem(value: -1, child: Text(t('custom_t'))),
        ],
      ),
      IconButton(icon: const Icon(Icons.edit_note), tooltip: t('info'), onPressed: () => editInfo(c, id)),
    ]),
    if (app.sleepMin > 0) Text('${app.sleepMin} ${t('min')}', style: TextStyle(fontSize: 12, color: col.primary)),
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
            if (s == null) return Scaffold(appBar: appBar(c, const Text(''), leading: back), body: Center(child: Text(t('nothing'))));
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
                child: cover(sid, 260),
              );
            }
            final panel = Column(children: [titleBlock, const SizedBox(height: 8), const SeekBar(), controls(c, sid)]);
            return Scaffold(
              appBar: appBar(c, const Text(''), leading: back),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (c, bc) => SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: bc.maxHeight - 48),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        head,
                        const SizedBox(height: 24),
                        if (st == 3) glass(c, panel, r: 28, padding: const EdgeInsets.all(16)) else panel,
                      ]),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
}

/* ================= sound FX page ================= */

class FxPage extends StatefulWidget {
  final String? id;
  const FxPage({super.key, this.id});
  @override
  State<FxPage> createState() => _FxState();
}

class _FxState extends State<FxPage> {
  AndroidEqualizerParameters? ps;
  bool err = false;
  late String scope;

  @override
  void initState() {
    super.initState();
    scope = (widget.id != null && app.songs[widget.id]?.fx != null) ? 's' : 'g';
    app.eq.parameters.then((v) {
      if (mounted) setState(() => ps = v);
    }).catchError((_) {
      if (mounted) setState(() => err = true);
    });
  }

  Fx get cur => scope == 's' ? (app.songs[widget.id]?.fx ?? app.gfx) : app.gfx;

  Fx edit() {
    if (scope == 's') {
      final s = app.songs[widget.id]!;
      s.fx ??= app.gfx.copy();
      return s.fx!;
    }
    return app.gfx;
  }

  void commit() {
    app.saveFx();
    app.applyFx(app.curId);
    if (mounted) setState(() {});
  }

  void preset(int k) {
    final pr = ps!;
    final n = pr.bands.length;
    final mx = pr.maxDecibels;
    final f = edit();
    f.gains = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      final x = n == 1 ? 0.0 : i / (n - 1);
      double v = 0;
      if (k == 1) v = (1 - 2 * x).clamp(0.0, 1.0).toDouble() * mx * .8;
      if (k == 2) v = (2 * x - 1).clamp(0.0, 1.0).toDouble() * mx * .8;
      if (k == 3) v = (1 - (x - .55).abs() * 2.2).clamp(0.0, 1.0).toDouble() * mx * .6;
      f.gains[i] = v;
    }
    f.eqOn = true;
    commit();
  }

  void resetAll() {
    if (scope == 's') {
      app.songs[widget.id]!.fx = Fx();
    } else {
      app.gfx = Fx();
    }
    commit();
  }

  String fq(double f) => f >= 1000 ? '${(f / 1000).toStringAsFixed(f % 1000 == 0 ? 0 : 1)}k' : '${f.round()}';

  @override
  Widget build(BuildContext c) {
    final f = cur;
    final pr = ps;
    final song = widget.id == null ? null : app.songs[widget.id];
    if (pr != null) {
      while (f.gains.length < pr.bands.length) {
        f.gains.add(0.0);
      }
    }
    return Scaffold(
      appBar: appBar(c, Text(t('fx'))),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 40), children: [
        if (song != null) ...[
          Wrap(spacing: 8, children: [
            ChoiceChip(label: Text(t('fx_all')), selected: scope == 'g', onSelected: (_) => setState(() => scope = 'g')),
            ChoiceChip(label: Text(t('fx_song')), selected: scope == 's', onSelected: (_) => setState(() => scope = 's')),
          ]),
          if (scope == 's')
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
            ),
        ],
        const SizedBox(height: 12),
        Text('${t('speed')}: ${f.speed.toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          min: .5,
          max: 2,
          divisions: 30,
          value: f.speed.clamp(.5, 2.0).toDouble(),
          onChanged: (v) => setState(() => edit().speed = v),
          onChangeEnd: (_) => commit(),
        ),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t('link')), value: f.link, onChanged: (v) { edit().link = v; commit(); }),
        Text('${t('pitch')}: ${(f.link ? f.speed : f.pitch).toStringAsFixed(2)}x', style: const TextStyle(fontWeight: FontWeight.w600)),
        Slider(
          min: .5,
          max: 2,
          divisions: 30,
          value: (f.link ? f.speed : f.pitch).clamp(.5, 2.0).toDouble(),
          onChanged: f.link ? null : (v) => setState(() => edit().pitch = v),
          onChangeEnd: f.link ? null : (_) => commit(),
        ),
        Text(t('fx_note'), style: const TextStyle(fontSize: 12)),
        const Divider(height: 32),
        SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(t('eq_on')), value: f.eqOn, onChanged: (v) { edit().eqOn = v; commit(); }),
        if (pr == null)
          Padding(padding: const EdgeInsets.all(12), child: Text(err ? t('eq_err') : '...'))
        else ...[
          Wrap(spacing: 8, children: [
            for (final e in {0: 'flat', 1: 'bass', 2: 'treble', 3: 'vocal'}.entries)
              ActionChip(label: Text(t(e.value)), onPressed: () => preset(e.key)),
          ]),
          const SizedBox(height: 8),
          for (var i = 0; i < pr.bands.length; i++)
            Row(children: [
              SizedBox(width: 48, child: Text(fq(pr.bands[i].centerFrequency))),
              Expanded(
                child: Slider(
                  min: pr.minDecibels,
                  max: pr.maxDecibels,
                  value: f.gains[i].clamp(pr.minDecibels, pr.maxDecibels).toDouble(),
                  onChanged: (v) => setState(() {
                    final e = edit();
                    while (e.gains.length < pr.bands.length) {
                      e.gains.add(0.0);
                    }
                    e.gains[i] = v;
                    e.eqOn = true;
                  }),
                  onChangeEnd: (_) => commit(),
                ),
              ),
            ]),
        ],
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(onPressed: resetAll, icon: const Icon(Icons.restart_alt), label: Text(t('fx_reset'))),
          if (song != null && song.fx != null)
            OutlinedButton(onPressed: () { song.fx = null; scope = 'g'; commit(); }, child: Text(t('fx_global'))),
        ]),
      ]),
    );
  }
}

/* ================= developer tab ================= */

class DevRow {
  final Widget icon;
  final String label, value, copy;
  final String? url;
  const DevRow(this.icon, this.label, this.value, this.copy, this.url);
}

Widget devCard(BuildContext c, DevRow r) {
  final cs = Theme.of(c).colorScheme;
  final st = app.style;
  final tile = Material(
    type: MaterialType.transparency,
    child: InkWell(
      borderRadius: BorderRadius.circular(rad()),
      onTap: r.url == null ? null : () => launchUrl(Uri.parse(r.url!), mode: LaunchMode.externalApplication),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        child: Row(children: [
          IconTheme(data: IconThemeData(color: cs.onSurface, size: 28), child: SizedBox(width: 32, child: Center(child: r.icon))),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.label, style: TextStyle(fontSize: 12, color: cs.onSurface.withOpacity(.6))),
              const SizedBox(height: 2),
              Text(r.value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: r.url != null ? cs.primary : null)),
            ]),
          ),
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: r.copy));
              snack(c, t('copied'));
            },
          ),
        ]),
      ),
    ),
  );
  if (st == 3) return glass(c, tile, r: rad(), margin: const EdgeInsets.symmetric(vertical: 6));
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 6),
    decoration: BoxDecoration(
      color: st == 1 ? Colors.transparent : cs.surfaceContainerHighest.withOpacity(.55),
      borderRadius: BorderRadius.circular(rad()),
      border: st == 1 ? Border.all(color: cs.outline.withOpacity(.5)) : null,
    ),
    child: tile,
  );
}

class DevPage extends StatelessWidget {
  const DevPage({super.key});
  @override
  Widget build(BuildContext c) {
    const insta = 'https://www.instagram.com/prabhat.viz?knvt=MXg0Y2wwaDEydW04aw==';
    const disc = 'https://discord.gg/HBHutYhg';
    final rows = [
      DevRow(const Icon(Icons.person_outline), t('dev_name'), 'Prabhat (ShanZo)', 'Prabhat (ShanZo)', null),
      const DevRow(FaIcon(FontAwesomeIcons.discord), 'Discord', 'discord.gg/HBHutYhg', disc, disc),
      const DevRow(FaIcon(FontAwesomeIcons.instagram), 'Instagram', '@prabhat.viz', insta, insta),
    ];
    return ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), children: [for (final r in rows) devCard(c, r)]);
  }
}

/* ================= settings ================= */

class FontSection extends StatefulWidget {
  const FontSection({super.key});
  @override
  State<FontSection> createState() => _FontState();
}

class _FontState extends State<FontSection> {
  bool prev = false;
  static const en = ['Quicksand', 'Comfortaa', 'Fredoka', 'Poppins', 'Josefin Sans', 'Pacifico', 'Dancing Script', 'Caveat', 'Playfair Display', 'Cinzel'];
  static const bn = ['Hind Siliguri', 'Baloo Da 2', 'Galada', 'Tiro Bangla', 'Atma', 'Anek Bangla'];

  TextStyle? gf(String n) {
    if (!prev) return null;
    try {
      return GoogleFonts.getFont(n);
    } catch (_) {
      return null;
    }
  }

  Widget chip(String key, String label, TextStyle? st, {VoidCallback? onLong}) => GestureDetector(
        onLongPress: onLong,
        child: ChoiceChip(label: Text(label, style: st), selected: app.font == key, onSelected: (_) => app.pref(fnt: key)),
      );

  Widget sub(String s) => Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 6), child: Text(s, style: const TextStyle(fontSize: 12)));

  Widget wrap(List<Widget> l) => Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Wrap(spacing: 8, runSpacing: 4, children: l));

  @override
  Widget build(BuildContext c) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SwitchListTile(title: Text(t('font_prev')), value: prev, onChanged: (v) => setState(() => prev = v)),
        wrap([chip('sys', t('font_def'), null)]),
        sub(t('font_en')),
        wrap([for (final n in en) chip('g:$n', n, gf(n))]),
        sub(t('font_bn')),
        wrap([for (final n in bn) chip('g:$n', '$n · আমার গান', gf(n))]),
        if (app.ufonts.isNotEmpty) sub(t('font_mine')),
        if (app.ufonts.isNotEmpty)
          wrap([
            for (final u in app.ufonts)
              chip('u:${u['n']}', u['n']!, TextStyle(fontFamily: u['n']), onLong: () {
                showDlg<void>(c, t('font_del'), Text(u['n']!), (d) => [
                  TextButton(onPressed: () => Navigator.pop(d), child: Text(t('cancel'))),
                  FilledButton(onPressed: () { Navigator.pop(d); app.delUserFont(u['n']!); }, child: Text(t('del'))),
                ]);
              }),
          ]),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: OutlinedButton.icon(onPressed: () => app.addUserFont(), icon: const Icon(Icons.add), label: Text(t('font_add'))),
        ),
      ]);
}

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
          appBar: appBar(c, Text(t('settings'))),
          body: ListView(padding: const EdgeInsets.only(bottom: 40), children: [
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
            sec(t('font')),
            const FontSection(),
            sec(t('lang')),
            chips<String>({'bn': 'বাংলা', 'en': 'English'}, app.lang, (v) => app.pref(l: v)),
            const SizedBox(height: 12),
            SwitchListTile(title: Text(t('set_tags')), value: app.readTags, onChanged: (v) => app.pref(tags: v)),
            SwitchListTile(title: Text(t('set_alyr')), value: app.autoLyr, onChanged: (v) => app.pref(alyr: v)),
            SwitchListTile(title: Text(t('set_look')), value: app.lookup, onChanged: (v) => app.pref(look: v)),
            ListTile(leading: const Icon(Icons.volume_up_outlined), title: Text(t('vol')), onTap: () => volSheet(c)),
            ListTile(
              leading: const Icon(Icons.graphic_eq),
              title: Text(t('fx')),
              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const FxPage())),
            ),
          ]),
        ),
      );
}

/* ================= home ================= */

class BottomBar extends StatelessWidget {
  final int tab;
  final ValueChanged<int> onTap;
  const BottomBar({super.key, required this.tab, required this.onTap});
  static const icons = [Icons.music_note, Icons.playlist_play, Icons.favorite, Icons.history, Icons.person];
  static const keys = ['songs', 'playlists', 'favs', 'recent', 'dev'];
  @override
  Widget build(BuildContext c) {
    final st = app.style;
    final cs = Theme.of(c).colorScheme;
    final dark = Theme.of(c).brightness == Brightness.dark;
    Widget item(int i) {
      final on = i == tab;
      final label = t(keys[i]);
      Widget body;
      if (st == 2) {
        body = Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: EdgeInsets.all(on ? 10 : 6),
            decoration: BoxDecoration(shape: BoxShape.circle, color: on ? cs.primary : Colors.transparent),
            child: Icon(icons[i], size: 22, color: on ? cs.onPrimary : null),
          ),
          if (on) Text(label, style: const TextStyle(fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
        ]);
      } else if (st == 1) {
        body = Column(mainAxisSize: MainAxisSize.min, children: [
          Text(label.toUpperCase(), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10, letterSpacing: 1, color: on ? cs.primary : null, fontWeight: on ? FontWeight.w700 : FontWeight.w300)),
          const SizedBox(height: 4),
          AnimatedContainer(duration: const Duration(milliseconds: 200), height: 2, width: on ? 18 : 0, color: cs.primary),
        ]);
      } else {
        body = Column(mainAxisSize: MainAxisSize.min, children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(color: on ? cs.primary.withOpacity(.3) : Colors.transparent, borderRadius: BorderRadius.circular(16)),
            child: Icon(icons[i], color: on ? cs.primary : null),
          ),
          const SizedBox(height: 2),
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: on ? cs.primary : null)),
        ]);
      }
      return Expanded(child: InkResponse(onTap: () => onTap(i), child: Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: body)));
    }

    final row = Row(children: [for (var i = 0; i < 5; i++) item(i)]);
    if (st == 3) return glass(c, row, r: 28, margin: const EdgeInsets.fromLTRB(10, 0, 10, 8));
    if (st == 2) {
      return Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        decoration: BoxDecoration(color: cs.surfaceContainerHigh.withOpacity(.9), borderRadius: BorderRadius.circular(40)),
        child: row,
      );
    }
    if (st == 1) {
      return Container(decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outline.withOpacity(.4)))), child: row);
    }
    return Container(color: (dark ? Colors.black : Colors.white).withOpacity(dark ? .35 : .45), child: row);
  }
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await Permission.notification.request();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) {
          final favIds = app.lib.where(app.favs.contains).toList();
          final pages = <Widget>[
            Column(children: [
              searchBox(c, (v) => setState(() => q = v)),
              Expanded(child: SongList(ids: app.lib, k: 'lib', q: q, reorder: true)),
            ]),
            const PlaylistsView(),
            SongList(ids: favIds, k: 'fav'),
            SongList(ids: app.recent, k: 'recent'),
            const DevPage(),
          ];
          return Scaffold(
            appBar: appBar(
              c,
              const Text('Velvet'),
              actions: [IconButton(icon: const Icon(Icons.settings_outlined), onPressed: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const SettingsPage())))],
            ),
            body: pages[tab],
            floatingActionButton: tab == 0
                ? addFab(c, () async {
                    final n = await app.importSongs();
                    if (n > 0) snack(c, '$n ${t('added')}');
                  })
                : null,
            bottomNavigationBar: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const MiniPlayer(),
                BottomBar(tab: tab, onTap: (i) => setState(() => tab = i)),
              ]),
            ),
          );
        },
      );
}
