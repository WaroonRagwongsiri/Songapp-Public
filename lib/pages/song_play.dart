import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:songapp_public/auth.dart';

class SongPlaying extends StatefulWidget {
  final String songName;
  late String? playlistName;

  SongPlaying({Key? key, required this.songName, this.playlistName})
      : super(key: key);

  @override
  State<SongPlaying> createState() => _SongPlayingState();
}

class _SongPlayingState extends State<SongPlaying> {
  late String songUrl = '';
  late String songPic =
      'https://t4.ftcdn.net/jpg/02/51/95/53/360_F_251955356_FAQH0U1y1TZw3ZcdPGybwUkH90a3VAhb.jpg';
  late String songArtist = '';
  AudioPlayer player = AudioPlayer();
  bool loaded = false;
  bool playing = false;
  bool loved = false;
  IconData lovedIcon = Icons.favorite_outline;
  IconData playIcon = Icons.pause;
  List<String> likesong = [];
  List<String> playlist = [];
  List<String> queue = [];

  CollectionReference likesongRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(Auth().currentUser!.uid)
      .collection('Playlist');

  CollectionReference userRef = FirebaseFirestore.instance.collection('Users');

  Future<void> getSongData() async {
    CollectionReference songs = FirebaseFirestore.instance.collection('Songs');
    try {
      var songData = await songs.doc(widget.songName).get();
      Map<String, dynamic> data = songData.data() as Map<String, dynamic>;

      setState(() {
        songUrl = data['songUrl'];
        songArtist = data['songArtist'];
        songPic = data['songPic'];
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> getUserData() async {
    try {
      DocumentSnapshot userDataSnapshot =
          await userRef.doc(Auth().currentUser!.uid).get();
      Map<String, dynamic> userData =
          userDataSnapshot.data() as Map<String, dynamic>;

      await userRef
          .doc(Auth().currentUser!.uid)
          .update({'playing': widget.songName});

      setState(() {
        queue = List<String>.from(userData['queue']);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> getPlaylistData() async {
    CollectionReference playlistRef = FirebaseFirestore.instance
        .collection('Users')
        .doc(Auth().currentUser!.uid)
        .collection('Playlist');
    try {
      DocumentSnapshot playlistSnapshot =
      
          await playlistRef.doc(widget.playlistName).get();
      Map<String, dynamic> playlistData =
          playlistSnapshot.data() as Map<String, dynamic>;
      List<dynamic> playlistDynamic = playlistData['songlist'] ?? [];
      List<String> playlistList = List<String>.from(playlistDynamic);
      setState(() {
        playlist = List.from(playlistList);
        queue = List.from(playlist);
      });
      await userRef.doc(Auth().currentUser!.uid).update({'queue': queue});
    } catch (e) {
      print(e);
    }
  }

  Future<void> getLikesongPlaylist() async {
    try {
      DocumentSnapshot likesongSnapshot =
          await likesongRef.doc('Likesong').get();
      Map<String, dynamic> likesongData =
          likesongSnapshot.data() as Map<String, dynamic>;
      List<dynamic> songListDynamic = likesongData['songlist'] ?? [];
      List<String> likesongList = List<String>.from(songListDynamic);
      setState(() {
        likesong = likesongList;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> clearQueue() async {
    try {
      setState(() {
        queue.clear();
      });
      await userRef.doc(Auth().currentUser!.uid).update({'queue': queue});
    } catch (e) {
      print(e);
    }
  }

  Future<void> loadMusic() async {
    await player.setUrl(songUrl);
    setState(() {
      loaded = true;
    });
  }

  Future<void> playMusic() async {
    setState(() {
      playing = true;
    });
    await player.play();
  }

  Future<void> pauseMusic() async {
    setState(() {
      playing = false;
    });
    await player.pause();
  }

  void nextSong(int index) {
    index++;
    try {
      if (index > queue.length - 1 || queue.isEmpty) {
        return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return SongPlaying(
          songName: queue[index],
          playlistName: widget.playlistName,
        );
      }));
    } catch (e) {
      print(e);
    }
  }

  void previousSong(int index) {
    index--;
    try {
      if (index < 0 || queue.isEmpty) {
        return;
      }
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return SongPlaying(
          songName: queue[index],
          playlistName: widget.playlistName,
        );
      }));
    } catch (e) {
      print(e);
    }
  }

  void like() {
    try {
      if (loved) {
        setState(() {
          likesong.remove(widget.songName);
          likesongRef.doc('Likesong').update({'songlist': likesong});
          lovedIcon = Icons.favorite_border;
        });
      } else {
        setState(() {
          likesong.add(widget.songName);
          likesongRef.doc('Likesong').update({'songlist': likesong});
          lovedIcon = Icons.favorite;
        });
      }
      setState(() {
        loved = !loved;
      });
    } catch (e) {
      print(e);
    }
  }

  void openQueue() {
    CollectionReference songsRef =
        FirebaseFirestore.instance.collection('Songs');
    print(queue);
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.8,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 5),
                const Text(
                  'Now Playing',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ListTile(
                  leading: Image.network(
                    songPic,
                    width: MediaQuery.of(context).size.width * 0.1,
                    height: MediaQuery.of(context).size.width * 0.1,
                    fit: BoxFit.cover,
                  ),
                  title: Text(widget.songName),
                  subtitle: Text(songArtist),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Next Song',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.left,
                    ),
                    const Expanded(child: SizedBox()),
                    ElevatedButton(
                        onPressed: clearQueue, child: Text('Clear Queue')),
                  ],
                ),
                const SizedBox(height: 5),
                StreamBuilder(
                  stream: songsRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No songs found.');
                    }
                    if (queue.isEmpty) {
                      return const SizedBox.shrink();
                    } else {
                      return ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount:
                            queue.length - queue.indexOf(widget.songName),
                        itemBuilder: (context, index) {
                          var songId =
                              queue[index + queue.indexOf(widget.songName)];
                          var songSnapshot = snapshot.data!.docs.firstWhere(
                            (doc) => doc.id == songId,
                          );
                          var songData =
                              songSnapshot.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: Image.network(
                              songData['songPic'],
                              width: MediaQuery.of(context).size.width * 0.1,
                              height: MediaQuery.of(context).size.width * 0.1,
                              fit: BoxFit.cover,
                            ),
                            title: Text(songData['songName']),
                            subtitle: Text(songData['songArtist']),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.pushReplacement(context,
                                  MaterialPageRoute(builder: (context) {
                                return SongPlaying(
                                  songName: queue[
                                      index + queue.indexOf(widget.songName)],
                                  playlistName: widget.playlistName,
                                );
                              }));
                            },
                          );
                        },
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    getSongData().then((value) => {loadMusic(), playMusic()});
    getLikesongPlaylist().then((value) => {
          setState(() {
            if (likesong.contains(widget.songName)) {
              print("Song is liked.");
              loved = true;
              lovedIcon = Icons.favorite;
            } else {
              print("Song is not liked.");
              loved = false;
              lovedIcon = Icons.favorite_border;
            }
          })
        });

    if (widget.playlistName != null) {
      getPlaylistData().then((value) => getUserData());
    } else {
      getUserData();
    }

    player.positionStream.listen((position) {
      final Duration duration = player.duration ?? Duration.zero;
      if (position >= duration) {
        if (queue.isEmpty ||
            queue.indexOf(widget.songName) >= queue.length - 1) {
          return;
        } else {
          nextSong(queue.indexOf(widget.songName));
        }
      }
    });

    print('Likesong: $likesong');
    print('Widget song name: ${widget.songName}');
    print('Playlist $playlist');
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName ?? ''),
      ),
      body: Column(children: [
        const SizedBox(
          height: 30,
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            songPic,
            height: MediaQuery.of(context).size.width * 0.8,
            width: MediaQuery.of(context).size.width * 0.8,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(
          height: 50,
        ),
        ListTile(
            title: Text(widget.songName),
            subtitle: Text(songArtist),
            trailing: IconButton(
              onPressed: () => {like()},
              icon: Icon(lovedIcon),
            )),
        const SizedBox(
          height: 20,
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: StreamBuilder(
            stream: player.positionStream,
            builder: (context, snapshot1) {
              final Duration duration = loaded
                  ? snapshot1.data as Duration
                  : const Duration(seconds: 0);
              return StreamBuilder(
                  stream: player.bufferedPositionStream,
                  builder: (context, snapshot2) {
                    final Duration bufferedDuration = loaded
                        ? snapshot2.data as Duration
                        : const Duration(seconds: 0);
                    return SizedBox(
                      height: 30,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: ProgressBar(
                          progress: duration,
                          total: player.duration ?? const Duration(seconds: 0),
                          buffered: bufferedDuration,
                          timeLabelPadding: -1,
                          timeLabelTextStyle: const TextStyle(
                            fontSize: 14,
                          ),
                          onSeek: loaded
                              ? (duration) async {
                                  await player.seek(duration);
                                }
                              : null,
                        ),
                      ),
                    );
                  });
            },
          ),
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
                onPressed: () => {previousSong(queue.indexOf(widget.songName))},
                icon: const Icon(Icons.skip_previous)),
            IconButton(
                onPressed: () {
                  if (playing) {
                    pauseMusic();
                    setState(() {
                      playIcon = Icons.play_arrow;
                    });
                  } else {
                    playMusic();
                    setState(() {
                      playIcon = Icons.pause;
                    });
                  }
                },
                icon: Icon(playIcon)),
            IconButton(
                onPressed: () => {nextSong(queue.indexOf(widget.songName))},
                icon: const Icon(Icons.skip_next)),
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            IconButton(
                onPressed: () => {openQueue()},
                icon: const Icon(Icons.queue_music))
          ],
        )
      ]),
    );
  }
}
