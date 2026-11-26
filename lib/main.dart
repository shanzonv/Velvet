import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
    'theme_mode': 'Theme mode', 'color': 'Color', 'style': 'UI style', 'lang': 'Language',
    'system': 'System', 'light': 'Light', 'dark': 'Dark', 'amoled': 'Black (AMOLED)',
    's0': 'Classic', 's1': 'Minimal', 's2': 'Vinyl', 'off': 'Off', 'min': 'min',
    'fav': 'Favorite', 'added': 'songs added', 'nothing': 'Nothing playing', 'sure': 'Delete this song for good?',
  },
  'bn': {
    'songs': 'গান', 'playlists': 'প্লেলিস্ট', 'favs': 'প্রিয়', 'recent': 'সাম্প্রতিক',
    'settings': 'সেটিংস', 'add': 'গান যোগ করুন', 'search': 'গান খুঁজুন', 'newpl': 'নতুন প্লেলিস্ট',
    'save': 'সেভ', 'cancel': 'বাতিল', 'del': 'মুছে ফেলুন', 'rename': 'নাম বদলান', 'cover': 'কভার সেট করুন',
    'addpl': 'প্লেলিস্টে যোগ করুন', 'rmpl': 'প্লেলিস্ট থেকে সরান', 'empty': 'এখানে এখনো কোনো গান নেই।',
    'theme_mode': 'থিম মোড', 'color': 'রঙ', 'style': 'UI স্টাইল', 'lang': 'ভাষা',
    'system': 'সিস্টেম', 'light': 'লাইট', 'dark': 'ডার্ক', 'amoled': 'কালো (AMOLED)',
    's0': 'ক্লাসিক', 's1': 'মিনিমাল', 's2': 'ভিনাইল', 'off': 'বন্ধ', 'min': 'মিনিট',
    'fav': 'প্রিয়তে যোগ/সরান', 'added': 'টি গান যোগ হয়েছে', 'nothing': 'কিছু চলছে না', 'sure': 'গানটি চিরতরে মুছবেন?',
  },
};
String t(String k) => L[app.lang]?[k] ?? k;

class Song {
  String id, title, file;
  String? cover;
  Song(this.id, this.title, this.file, [this.cover]);
  Map<String, dynamic> toJ() => {'i': id, 't': title, 'f': file, 'c': cover};
  static Song fromJ(dynamic m) => Song(m['i'], m['t'], m['f'], m['c']);
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
  final player = AudioPlayer();
  Map<String, Song> songs = {};
  List<String> lib = [], recent = [];
  List<PL> pls = [];
  Set<String> favs = {};
  int accent = 0xFF9B1D45, mode = 0, style = 0, sleepMin = 0;
  String lang = 'bn';
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

  void pref({int? acc, int? m, int? st, String? l}) {
    if (acc != null) { accent = acc; sp.setInt('acc', acc); }
    if (m != null) { mode = m; sp.setInt('mode', m); }
    if (st != null) { style = st; sp.setInt('style', st); }
    if (l != null) { lang = l; sp.setString('lang', l); }
    notifyListeners();
  }

  Future<int> importSongs() async {
    final r = await FilePicker.platform.pickFiles(type: FileType.audio, allowMultiple: true);
    if (r == null) return 0;
    var n = 0;
    for (final f in r.files) {
      if (f.path == null) continue;
      final id = '${nid()}$n';
      final name = '$id${p.extension(f.path!)}';
      await File(f.path!).copy(path(name));
      songs[id] = Song(id, p.basenameWithoutExtension(f.name), name);
      lib.add(id);
      n++;
    }
    save();
    return n;
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

class VelvetApp extends StatelessWidget {
  const VelvetApp({super.key});
  ThemeData mk(Brightness b, bool black) {
    var cs = ColorScheme.fromSeed(seedColor: Color(app.accent), brightness: b);
    if (black) cs = cs.copyWith(surface: Colors.black);
    return ThemeData(useMaterial3: true, colorScheme: cs, scaffoldBackgroundColor: cs.surface);
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
          home: const Home(),
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
    return circle ? ClipOval(child: w) : ClipRRect(borderRadius: BorderRadius.circular(size > 100 ? 20 : 8), child: w);
  });
}

Future<String?> askText(BuildContext c, String title, String init) {
  final ctl = TextEditingController(text: init);
  return showDialog<String>(
    context: c,
    builder: (d) => AlertDialog(
      title: Text(title),
      content: TextField(controller: ctl, autofocus: true),
      actions: [
        TextButton(onPressed: () => Navigator.pop(d), child: Text(t('cancel'))),
        FilledButton(onPressed: () => Navigator.pop(d, ctl.text.trim().isEmpty ? null : ctl.text.trim()), child: Text(t('save'))),
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
  final s = app.songs[id]!;
  showModalBottomSheet<void>(
    context: c,
    builder: (b) => SafeArea(
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
        ListTile(
          leading: const Icon(Icons.edit),
          title: Text(t('rename')),
          onTap: () async {
            Navigator.pop(b);
            final v = await askText(c, t('rename'), s.title);
            if (v != null) { s.title = v; app.save(); }
          },
        ),
        ListTile(leading: const Icon(Icons.image), title: Text(t('cover')), onTap: () { Navigator.pop(b); app.setCover(id); }),
        ListTile(leading: const Icon(Icons.playlist_add), title: Text(t('addpl')), onTap: () { Navigator.pop(b); addToPl(c, id); }),
        if (pl != null)
          ListTile(leading: const Icon(Icons.playlist_remove), title: Text(t('rmpl')), onTap: () { Navigator.pop(b); pl.ids.remove(id); app.save(); })
        else
          ListTile(leading: const Icon(Icons.delete_outline), title: Text(t('del')), onTap: () { Navigator.pop(b); confirmDel(c, id); }),
      ]),
    ),
  );
}

class SongTile extends StatelessWidget {
  final String id;
  final VoidCallback onTap;
  final PL? pl;
  const SongTile({super.key, required this.id, required this.onTap, this.pl});
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
        return ListTile(
          dense: st == 1,
          leading: st == 1 ? null : cover(id, 48, circle: st == 2),
          title: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: on ? pr : null, fontWeight: on ? FontWeight.w700 : null)),
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            if (fav) Icon(Icons.favorite, size: 16, color: pr),
            IconButton(icon: const Icon(Icons.more_vert), onPressed: () => songMenu(c, id, pl)),
          ]),
          onTap: onTap,
        );
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
    final shown = q.isEmpty ? ids : ids.where((i) => app.songs[i]!.title.toLowerCase().contains(q.toLowerCase())).toList();
    if (shown.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32), child: Text(t('empty'), textAlign: TextAlign.center)));
    }
    Widget tile(int i) => SongTile(key: ValueKey(shown[i]), id: shown[i], pl: pl, onTap: () => app.playList(shown, i));
    if (reorder && q.isEmpty) {
      return ReorderableListView.builder(
        itemCount: ids.length,
        onReorder: (a, b) {
          if (b > a) b--;
          ids.insert(b, ids.removeAt(a));
          app.save();
        },
        itemBuilder: (_, i) => tile(i),
      );
    }
    return ListView.builder(itemCount: shown.length, itemBuilder: (_, i) => tile(i));
  }
}

class PlaylistsView extends StatelessWidget {
  const PlaylistsView({super.key});
  @override
  Widget build(BuildContext c) => ListView(children: [
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
      ]);
}

class PlPage extends StatelessWidget {
  final PL pl;
  const PlPage(this.pl, {super.key});
  @override
  Widget build(BuildContext c) => ListenableBuilder(
        listenable: app,
        builder: (c, _) => Scaffold(
          appBar: AppBar(title: Text(pl.name), actions: [
            IconButton(
              icon: const Icon(Icons.play_arrow),
              onPressed: () { if (pl.ids.isNotEmpty) app.playList(pl.ids, 0); },
            ),
          ]),
          body: SongList(ids: pl.ids, k: pl.id, reorder: true, pl: pl),
        ),
      );
}

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
  Widget build(BuildContext c) => StreamBuilder<SequenceState?>(
        stream: app.player.sequenceStateStream,
        builder: (c, snap) {
          final id = (snap.data?.currentSource?.tag as MediaItem?)?.id;
          final s = id == null ? null : app.songs[id];
          if (s == null) return const SizedBox.shrink();
          return Material(
            color: Theme.of(c).colorScheme.surfaceContainerHighest,
            child: InkWell(
              onTap: () => Navigator.push(c, MaterialPageRoute(builder: (_) => const NowPlaying())),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                child: Row(children: [
                  cover(id!, 44, circle: app.style == 2),
                  const SizedBox(width: 12),
                  Expanded(child: Text(s.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const PlayBtn(),
                ]),
              ),
            ),
          );
        },
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
            return Scaffold(
              appBar: AppBar(leading: IconButton(icon: const Icon(Icons.keyboard_arrow_down), onPressed: () => Navigator.pop(c))),
              body: s == null
                  ? Center(child: Text(t('nothing')))
                  : Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(children: [
                        const Spacer(),
                        if (app.style == 2)
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black87, border: Border.all(color: col.primary, width: 3)),
                            child: cover(id!, 240, circle: true),
                          )
                        else if (app.style == 0)
                          cover(id!, 300),
                        const Spacer(),
                        Text(s.title, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis, style: Theme.of(c).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 12),
                        const SeekBar(),
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
                            icon: Icon(app.favs.contains(id) ? Icons.favorite : Icons.favorite_border, color: app.favs.contains(id) ? col.primary : null),
                            onPressed: () {
                              if (!app.favs.remove(id)) app.favs.add(id!);
                              app.save();
                            },
                          ),
                          PopupMenuButton<int>(
                            icon: Icon(Icons.bedtime_outlined, color: app.sleepMin > 0 ? col.primary : null),
                            onSelected: app.setSleep,
                            itemBuilder: (_) => [
                              for (final m in [0, 15, 30, 60]) PopupMenuItem(value: m, child: Text(m == 0 ? t('off') : '$m ${t('min')}')),
                            ],
                          ),
                        ]),
                        const SizedBox(height: 12),
                      ]),
                    ),
            );
          },
        ),
      );
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
              ]),
            ),
            sec(t('style')),
            chips<int>({0: t('s0'), 1: t('s1'), 2: t('s2')}, app.style, (v) => app.pref(st: v)),
            sec(t('lang')),
            chips<String>({'bn': 'বাংলা', 'en': 'English'}, app.lang, (v) => app.pref(l: v)),
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
