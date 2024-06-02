import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:share/share.dart';
import 'package:songapp/auth.dart';
import 'package:songapp/pages/playlist_manager.dart';
import 'package:songapp/pages/create_playlist.dart';
import 'package:songapp/pages/playlist.dart';
import 'package:songapp/pages/song_play.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  late String profilePic =
      'https://i.pinimg.com/736x/e5/9e/51/e59e51dcbba47985a013544769015f25.jpg';
  CollectionReference playlistRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(Auth().currentUser?.uid)
      .collection('Playlist');
  late Stream<dynamic> playlist;
  CollectionReference songsRef = FirebaseFirestore.instance.collection('Songs');
  late Map<String, dynamic> userData = {};
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';

  Future<void> logOut() async {
    Auth().signOut();
  }

  Future<void> getUserData() async {
    CollectionReference userRef =
        FirebaseFirestore.instance.collection('Users');
    try {
      DocumentSnapshot userSnapshot =
          await userRef.doc(Auth().currentUser!.uid).get();
      Map<String, dynamic> userData =
          userSnapshot.data() as Map<String, dynamic>;
      setState(() {
        userData = userData;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> createPlaylist() async {
    try {
      Navigator.of(context).push(MaterialPageRoute(builder: (context) {
        return const CreatePlaylist();
      }));
    } catch (e) {
      print(e);
    }
  }

  Future<void> deletePlaylist(String playlistName) async {
    try {
      await playlistRef.doc(playlistName).delete();
    } catch (e) {
      print(e);
    }
  }

  Future<void> likeThisSong(String songName) async {
    try {
      DocumentSnapshot likeSongSnapshot =
          await playlistRef.doc('Likesong').get();
      Map<String, dynamic>? likesongData =
          likeSongSnapshot.data() as Map<String, dynamic>;
      List<dynamic> likesongDynamic = likesongData['songlist'] ?? [];
      List<String> likesongList = List<String>.from(likesongDynamic);
      likesongList.add(songName);
      await playlistRef.doc('Likesong').update({'songlist': likesongList});
    } catch (e) {
      print(e);
    }
  }

  void showPlaylistManager(Map<String, dynamic> playlistData) {
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
                    leading: Image.network(playlistData['playlistPic']),
                    title: Text(playlistData['playlistName']),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  ListTile(
                    leading: const Icon(Icons.download),
                    title: const Text('Download'),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.pin_drop),
                    title: const Text('Pin playlist'),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.close),
                    title: const Text('Delete playlist'),
                    onTap: () => {
                      Navigator.of(context).pop(),
                      deletePlaylist(playlistData['playlistName'])
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.share),
                    title: const Text('Share'),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.people),
                    title: const Text('Start a Jam'),
                    onTap: () => {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.waves),
                    title: const Text('Show Spotify Code'),
                    onTap: () => {},
                  ),
                ],
              ),
            ),
          );
        });
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
                  StreamBuilder(
                      stream: playlistRef.snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }
                        if (snapshot.hasError) {
                          return Text('Error: ${snapshot.error}');
                        }
                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return const Text('No playlists found.');
                        }
                        Map<String, dynamic> likesongData = (snapshot.data!.docs
                                    .firstWhere((doc) => doc.id == 'Likesong')
                                as QueryDocumentSnapshot<Map<String, dynamic>>)
                            .data();

                        if (likesongData['songlist']
                            .contains(songData['songName'])) {
                          return Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.add_circle_outline),
                                title: const Text('Add to other playlist'),
                                onTap: () => {
                                  Navigator.of(context).pop(),
                                  Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) {
                                    return PlaylistManager(
                                      songName: songData['songName'],
                                    );
                                  }))
                                },
                              )
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              ListTile(
                                leading: Image.network(
                                    "https://i1.sndcdn.com/artworks-y6qitUuZoS6y8LQo-5s2pPA-t500x500.jpg"),
                                title: const Text('Add to Likesong'),
                                onTap: () => {
                                  Navigator.of(context).pop(),
                                  likeThisSong(songData['songName'])
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.add_circle_outline),
                                title: const Text('Add to playlist'),
                                onTap: () => {
                                  Navigator.of(context).pop(),
                                  Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) {
                                    return PlaylistManager(
                                      songName: songData['songName'],
                                    );
                                  }))
                                },
                              ),
                            ],
                          );
                        }
                      }),
                  ListTile(
                    leading: const Icon(Icons.queue),
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
            ),
          );
        });
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
                child: Text(
              'Hello ${userData['username']}',
              style: const TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            )),
            ElevatedButton(onPressed: logOut, child: const Text('LogOut')),
          ],
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          Container(
            padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.05,
                top: MediaQuery.of(context).size.height * 0.1,
                right: MediaQuery.of(context).size.width * 0.05),
            child: Column(
              children: [
                Row(
                  children: [
                    Builder(builder: (context) {
                      return ElevatedButton(
                        onPressed: () => {Scaffold.of(context).openDrawer()},
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                        child: Image.network(
                          profilePic,
                          width: MediaQuery.of(context).size.width * 0.075,
                          height: MediaQuery.of(context).size.width * 0.075,
                        ),
                      );
                    }),
                    const Text(
                      'Your Library',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const Expanded(
                      child: SizedBox(
                        height: 0,
                      ),
                    ),
                    IconButton(
                        onPressed: () => {createPlaylist()},
                        icon: const Icon(Icons.add)),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                StreamBuilder<QuerySnapshot>(
                  stream: playlistRef.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text('No playlists found.');
                    }
                    return Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),
                          Expanded(
                            child: ListView.builder(
                              itemCount: snapshot.data!.docs.length,
                              itemBuilder: (context, index) {
                                var playlistData = snapshot.data!.docs[index]
                                    .data() as Map<String, dynamic>;
                                return Column(
                                  children: [
                                    ListTile(
                                      title: Text(
                                          playlistData['playlistName'] ??
                                              'No Name'),
                                      leading: Image.network(
                                        playlistData['playlistPic'] ??
                                            'https://t4.ftcdn.net/jpg/02/51/95/53/360_F_251955356_FAQH0U1y1TZw3ZcdPGybwUkH90a3VAhb.jpg',
                                      ),
                                      onTap: () => {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return PlaylistPage(
                                            playlistName:
                                                playlistData['playlistName'],
                                          );
                                        }))
                                      },
                                      onLongPress: () =>
                                          {showPlaylistManager(playlistData)},
                                    ),
                                    SizedBox(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.02,
                                    ),
                                  ],
                                );
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
          ),
          Container(
            padding: EdgeInsets.only(
                top: MediaQuery.of(context).size.height * 0.05,
                left: MediaQuery.of(context).size.width * 0.025,
                right: MediaQuery.of(context).size.width * 0.025),
            child: Column(
              children: [
                Row(
                  children: [
                    Builder(builder: (context) {
                      return ElevatedButton(
                        onPressed: () => {Scaffold.of(context).openDrawer()},
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(8),
                        ),
                        child: Image.network(
                          profilePic,
                          width: MediaQuery.of(context).size.width * 0.075,
                          height: MediaQuery.of(context).size.width * 0.075,
                        ),
                      );
                    }),
                    const Text(
                      'Search',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 5,
                ),
                SearchBar(
                  controller: _searchController,
                  leading: const Icon(Icons.search),
                  onSubmitted: (value) {
                    setState(() {
                      searchText = _searchController.text;
                    });
                  },
                  hintText: 'Something on your mind?',
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
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var songData = snapshot.data!.docs[index]
                                      .data() as Map<String, dynamic>;
                                  String songName = songData['songName'];
                                  if (songName
                                      .toLowerCase()
                                      .contains(searchText.toLowerCase())) {
                                    return ListTile(
                                      leading: Image.network(
                                        songData['songPic'],
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        height:
                                            MediaQuery.of(context).size.width *
                                                0.1,
                                        fit: BoxFit.cover,
                                      ),
                                      title: Text(songData['songName']),
                                      subtitle: Text(songData['songArtist']),
                                      onTap: () => {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return SongPlaying(
                                              songName: songData['songName']);
                                        }))
                                      },
                                      trailing: IconButton(
                                        icon: const Icon(Icons.more_vert),
                                        onPressed: () =>
                                            {showSongManager(songData)},
                                      ),
                                      onLongPress: () => {
                                        showSongManager(songData),
                                      },
                                    );
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                }),
                          )
                        ],
                      ));
                    }),
              ],
            ),
          )
        ],
      ),
      bottomNavigationBar: NavigationBar(
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedIndex: _currentIndex,
        destinations: const <Widget>[
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
            selectedIcon: Icon(Icons.home),
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            label: 'Search',
            selectedIcon: Icon(Icons.search),
          ),
        ],
      ),
    );
  }
}
