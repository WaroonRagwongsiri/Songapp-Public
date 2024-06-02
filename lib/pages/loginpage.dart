import 'package:flutter/material.dart';
import 'package:songapp_public/auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  int _currentIndex = 0;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  CollectionReference users = FirebaseFirestore.instance.collection('Users');

  Future<void> addUser({required String username}) async {
    late String? email;
    late String? uid;
    try {
      email = Auth().currentUser?.email;
      uid = Auth().currentUser?.uid;
      users.doc(uid).set({'username': username, 'email': email, 'uid': uid});
      users.doc(uid).collection('Playlist').doc('Likesong').set({
        'playlistName':'Likesong',
        'playlistPic':'https://i1.sndcdn.com/artworks-y6qitUuZoS6y8LQo-5s2pPA-t500x500.jpg',
        'songlist':[],
        'queue':[],
        'playing':'',
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> login({required String email, required String password}) async {
    try {
      await Auth().signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      print(e);
    }
  }

  Future<void> register({
    required String email,
    required String password,
    required String username,
  }) async {
    try {
      await Auth()
          .createUserWithEmailAndPassword(email: email, password: password);
      await addUser(username: username);
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login/Register'),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildLoginScreen(),
          _buildRegisterScreen(),
        ],
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Material(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.6,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('LOGIN'),
            TextFormField(
              decoration: const InputDecoration(hintText: 'email'),
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'password'),
              keyboardType: TextInputType.visiblePassword,
              controller: _passwordController,
            ),
            ElevatedButton(
              onPressed: () => login(
                email: _emailController.text,
                password: _passwordController.text,
              ),
              child: const Text('Login'),
            ),
            Row(
              children: [
                const Text('Don\'t have an account?'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                  child: const Text('Register'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterScreen() {
    return Material(
      child: Container(
        height: MediaQuery.of(context).size.height * 0.7,
        width: MediaQuery.of(context).size.width * 0.6,
        margin: EdgeInsets.only(
          top: MediaQuery.of(context).size.height * 0.1,
          left: MediaQuery.of(context).size.width * 0.2,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('REGISTER'),
            TextFormField(
              decoration: const InputDecoration(hintText: 'username'),
              keyboardType: TextInputType.text,
              controller: _usernameController,
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'email'),
              keyboardType: TextInputType.emailAddress,
              controller: _emailController,
            ),
            TextFormField(
              decoration: const InputDecoration(hintText: 'password'),
              keyboardType: TextInputType.visiblePassword,
              controller: _passwordController,
            ),
            ElevatedButton(
              onPressed: () => register(
                email: _emailController.text,
                password: _passwordController.text,
                username: _usernameController.text,
              ),
              child: const Text('Register'),
            ),
            Row(
              children: [
                const Text('Already have an account?'),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                  child: const Text('Login'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
