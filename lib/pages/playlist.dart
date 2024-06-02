import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:songapp_public/auth.dart';
import 'package:share/share.dart';
import 'package:songapp_public/pages/playlist_manager.dart';
import 'package:songapp_public/pages/song_play.dart';

class PlaylistPage extends StatefulWidget {
  final String playlistName;

  const PlaylistPage({Key? key, required this.playlistName}) : super(key: key);

  @override
  State<PlaylistPage> createState() => _PlaylistPageState();
}

class _PlaylistPageState extends State<PlaylistPage> {
  late List<dynamic> playlistSong = [];
  CollectionReference playlistRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(Auth().currentUser?.uid)
      .collection('Playlist');
  late Map<String, dynamic> _playlistData = {};
  CollectionReference songsRef = FirebaseFirestore.instance.collection('Songs');
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  Future<void> getUserData() async {
    try {
      DocumentSnapshot playlistSnapshot =
          await playlistRef.doc(widget.playlistName).get();
      Map<String, dynamic> playlistData =
          playlistSnapshot.data() as Map<String, dynamic>;
      setState(() {
        _playlistData = playlistData;
        playlistSong = _playlistData['songlist'] ?? [];
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> removeFromThisPlaylist(String songName) async {
    try {
      setState(() {
        playlistSong.remove(songName);
      });
      await playlistRef
          .doc(widget.playlistName)
          .update({'songlist': playlistSong});
    } catch (e) {
      print(e);
    }
  }

  void showSongManager(Map<String, dynamic> songData) {
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
              height: MediaQuery.of(context).size.height * 0.8,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 10,
                    ),
                    ListTile(
                      leading: Image.network(songData['songPic']),
                      title: Text(songData['songName']),
                      subtitle: Text(songData['songArtist']),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    ListTile(
                      leading: const Icon(Icons.add_circle_outline),
                      title: const Text('Add to other playlist'),
                      onTap: () => {
                        Navigator.of(context).pop(),
                        Navigator.of(context)
                            .push(MaterialPageRoute(builder: (context) {
                          return PlaylistManager(
                              songName: songData['songName']);
                        }))
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.do_not_disturb_on_outlined),
                      title: const Text('Remove from this playlist'),
                      onTap: () => {
                        Navigator.of(context).pop(),
                        removeFromThisPlaylist(songData['songName']),
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.queue_music),
                      title: const Text('Add to queue'),
                      onTap: () => {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.album_outlined),
                      title: const Text('View album'),
                      onTap: () => {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('View artists'),
                      onTap: () => {},
                    ),
                    ListTile(
                    leading: const Icon(Icons.share_outlined),
                    title: const Text('Share'),
                    onTap: () {
                      final RenderBox box =
                          context.findRenderObject() as RenderBox;
                      Share.share(
                        '${songData['songName']}\n${songData['shareLink']}',
                        subject: 'Share Song',
                        sharePositionOrigin:
                            box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                  ),
                    ListTile(
                      leading: const Icon(Icons.radar),
                      title: const Text('Go to song radio'),
                      onTap: () => {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Show credits'),
                      onTap: () => {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.waves_outlined),
                      title: const Text('Show Spotify Code'),
                      onTap: () => {},
                    ),
                  ],
                ),
              ));
        });
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlistName),
      ),
      body: Column(
        children: [
          SearchBar(
            controller: _searchController,
            leading: const Icon(Icons.search),
            onSubmitted: (value) {
              setState(() {
                searchText = _searchController.text;
              });
            },
            hintText: 'Search something?',
          ),
          const SizedBox(
            height: 5,
          ),
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
                return const Text('No Songs found.');
              }
              return Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: playlistSong.length,
                        itemBuilder: (context, index) {
                          var songId = playlistSong[index];
                          var songSnapshot = snapshot.data!.docs.firstWhere(
                            (doc) => doc.id == songId,
                          );
                          var songData =
                              songSnapshot.data() as Map<String, dynamic>;
                          String songName = songData['songName'];
                          if (songName
                              .toLowerCase()
                              .contains(searchText.toLowerCase())) {
                            return ListTile(
                              leading: Image.network(
                                songData['songPic'],
                                width: MediaQuery.of(context).size.width * 0.1,
                                height: MediaQuery.of(context).size.width * 0.1,
                                fit: BoxFit.cover,
                              ),
                              title: Text(songData['songName']),
                              subtitle: Text(songData['songArtist']),
                              trailing: IconButton(
                                  onPressed: () => {showSongManager(songData)},
                                  icon: const Icon(Icons.more_vert)),
                              onTap: () => {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return SongPlaying(
                                    songName: songData['songName'],
                                    playlistName: widget.playlistName,
                                  );
                                }))
                              },
                              onLongPress: () => {showSongManager(songData)},
                            );
                          } else {
                            return const SizedBox.shrink();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
