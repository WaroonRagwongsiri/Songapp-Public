import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:songapp/auth.dart';
import 'package:songapp/pages/create_playlist.dart';

class PlaylistManager extends StatefulWidget {
  final String songName;
  const PlaylistManager({super.key, required this.songName});

  @override
  State<PlaylistManager> createState() => _AddToPlaylistState();
}

class _AddToPlaylistState extends State<PlaylistManager> {
  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  CollectionReference playlistRef = FirebaseFirestore.instance
      .collection('Users')
      .doc(Auth().currentUser!.uid)
      .collection('Playlist');
  List<String> alreadyInPlaylistList = [];
  List<String> notInPLaylistList = [];
  List<String> selectedPlaylist = [];
  List<String> allPlaylist = [];

  Future<void> getPlaylistData() async {
    List<String> alreadyInPlaylistList = [];
    List<String> notInPLaylistList = [];
    List<String> allPlaylist = [];
    try {
      QuerySnapshot myDoc = await playlistRef.get();
      for (int i = 0; i < myDoc.size; i++) {
        var playlistData = myDoc.docs[i].data() as Map<String, dynamic>;
        if (playlistData['songlist'].contains(widget.songName)) {
          alreadyInPlaylistList.add(playlistData['playlistName']);
        } else {
          notInPLaylistList.add(playlistData['playlistName']);
        }
        allPlaylist.add(playlistData['playlistName']);
      }
      setState(() {
        alreadyInPlaylistList = List.from(alreadyInPlaylistList);
        notInPLaylistList = List.from(notInPLaylistList);
        selectedPlaylist = List.from(alreadyInPlaylistList);
        allPlaylist = List.from(allPlaylist);
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> playlistManage() async {
    try {
      Set<String> allPlaylistSet = allPlaylist.toSet();
      Set<String> selectedPlaylistSet = selectedPlaylist.toSet();
      Set<String> notSelectedPlaylistSet =
          allPlaylistSet.difference(selectedPlaylistSet);

      List<String> selectedPlaylistList = selectedPlaylistSet.toList();
      List<String> notSelectedPlaylistList = notSelectedPlaylistSet.toList();

      for (int i = 0; i < selectedPlaylistList.length; i++) {
        DocumentSnapshot playlistSnapshot =
            await playlistRef.doc(selectedPlaylistList[i]).get();
        Map<String, dynamic>? playlistData =
            playlistSnapshot.data() as Map<String, dynamic>;
        List<dynamic> songListDynamic = playlistData['songlist'] ?? [];
        List<String> songlist = List<String>.from(songListDynamic);
        if (!songlist.contains(widget.songName)) {
          songlist.add(widget.songName);
          await playlistRef
              .doc(selectedPlaylistList[i])
              .update({'songlist': songlist});
        }
        print(songlist);
      }
      for (int i = 0; i < notSelectedPlaylistList.length; i++) {
        DocumentSnapshot playlistSnapshot =
            await playlistRef.doc(notSelectedPlaylistList[i]).get();
        Map<String, dynamic>? playlistData =
            playlistSnapshot.data() as Map<String, dynamic>;
        List<dynamic> songListDynamic = playlistData['songlist'] ?? [];
        List<String> songlist = List<String>.from(songListDynamic);
        songlist.remove(widget.songName);
        await playlistRef
            .doc(notSelectedPlaylistList[i])
            .update({'songlist': songlist});
        print(songlist);
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  void initState() {
    super.initState();
    getPlaylistData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add to Playlist'),
      ),
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          ElevatedButton(
              onPressed: () async {
                await Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return const CreatePlaylist();
                }));
                getPlaylistData();
              },
              child: const Text(
                'New Playlist',
              )),
          const SizedBox(
            height: 20,
          ),
          SearchBar(
            controller: _searchController,
            leading: const Icon(Icons.search),
            hintText: 'Find playlist',
            onSubmitted: (value) {
              setState(() {
                searchText = _searchController.text;
              });
            },
          ),
          const SizedBox(
            height: 20,
          ),
          Builder(builder: (context) {
            if (alreadyInPlaylistList.isEmpty) {
              return Expanded(
                child: Column(
                  children: [
                    const SizedBox(
                      height: 20,
                    ),
                    const Text('Most relevant'),
                    const SizedBox(
                      height: 20,
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
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Text('No playlists found.');
                          }
                          return Expanded(
                            child: ListView.builder(
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var playlistData = snapshot.data!.docs[index]
                                      .data() as Map<String, dynamic>;
                                  IconData selectedIcon =
                                      Icons.radio_button_unchecked;
                                  if (selectedPlaylist
                                      .contains(playlistData['playlistName'])) {
                                    selectedIcon = Icons.check_circle;
                                  }

                                  if (playlistData['playlistName']
                                      .contains(searchText)) {
                                    return ListTile(
                                        leading: Image.network(
                                            playlistData['playlistPic']),
                                        title: Text(
                                            playlistData['playlistName'] ??
                                                'Unknown Playlist'),
                                        trailing: Icon(selectedIcon),
                                        onTap: () {
                                          setState(() {
                                            if (selectedPlaylist.contains(
                                                playlistData['playlistName'])) {
                                              selectedPlaylist.remove(
                                                  playlistData['playlistName']);
                                            } else {
                                              selectedPlaylist.add(
                                                  playlistData['playlistName']);
                                            }
                                          });
                                        });
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                }),
                          );
                        }),
                  ],
                ),
              );
            } else {
              return Expanded(
                child: Column(
                  children: [
                    const Text('Saved in'),
                    const SizedBox(
                      height: 15,
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
                          if (!snapshot.hasData ||
                              snapshot.data!.docs.isEmpty) {
                            return const Text('No playlists found.');
                          }
                          return Expanded(
                            child: ListView.builder(
                                itemCount: alreadyInPlaylistList.length,
                                itemBuilder: (context, index) {
                                  var playlistData = snapshot.data!.docs
                                      .firstWhere((doc) =>
                                          doc.id ==
                                          alreadyInPlaylistList[index])
                                      .data() as Map<String, dynamic>;
                                  IconData selectedIcon =
                                      Icons.radio_button_unchecked;
                                  if (selectedPlaylist
                                      .contains(playlistData['playlistName'])) {
                                    selectedIcon = Icons.check_circle;
                                  }
                                  if (playlistData['playlistName']
                                      .contains(searchText)) {
                                    return ListTile(
                                        leading: Image.network(
                                            playlistData['playlistPic']),
                                        title: Text(
                                            playlistData['playlistName'] ??
                                                'Unknown Playlist'),
                                        trailing: Icon(selectedIcon),
                                        onTap: () {
                                          setState(() {
                                            if (selectedPlaylist.contains(
                                                playlistData['playlistName'])) {
                                              selectedPlaylist.remove(
                                                  playlistData['playlistName']);
                                            } else {
                                              selectedPlaylist.add(
                                                  playlistData['playlistName']);
                                            }
                                          });
                                        });
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                }),
                          );
                        }),
                    const Text('Most relevavnt'),
                    const SizedBox(
                      height: 15,
                    ),
                    StreamBuilder(
                        stream: playlistRef.snapshots(),
                        builder: (context, snapshot) {
                          return Expanded(
                            child: ListView.builder(
                                itemCount: notInPLaylistList.length,
                                itemBuilder: (context, index) {
                                  var playlistData = snapshot.data!.docs
                                      .firstWhere((doc) =>
                                          doc.id == notInPLaylistList[index])
                                      .data() as Map<String, dynamic>;
                                  IconData selectedIcon =
                                      Icons.radio_button_unchecked;
                                  if (selectedPlaylist
                                      .contains(playlistData['playlistName'])) {
                                    selectedIcon = Icons.check_circle;
                                  }

                                  if (playlistData['playlistName']
                                      .contains(searchText)) {
                                    return ListTile(
                                        leading: Image.network(
                                            playlistData['playlistPic']),
                                        title: Text(
                                            playlistData['playlistName'] ??
                                                'Unknown Playlist'),
                                        trailing: Icon(selectedIcon),
                                        onTap: () {
                                          setState(() {
                                            if (selectedPlaylist.contains(
                                                playlistData['playlistName'])) {
                                              selectedPlaylist.remove(
                                                  playlistData['playlistName']);
                                            } else {
                                              selectedPlaylist.add(
                                                  playlistData['playlistName']);
                                            }
                                          });
                                        });
                                  } else {
                                    return const SizedBox.shrink();
                                  }
                                }),
                          );
                        }),
                  ],
                ),
              );
            }
          }),
          const SizedBox(
            height: 10,
          ),
          ElevatedButton(
              onPressed: () => {
                    Navigator.of(context).pop(),
                    playlistManage(),
                  },
              child: const Text(
                'Done',
              )),
          const SizedBox(
            height: 10,
          ),
        ],
      ),
    );
  }
}
