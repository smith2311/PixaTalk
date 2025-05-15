import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/api/apis.dart';
import 'package:frontend/models/chat_user_card.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth/login_screen.dart';
import '../main.dart';
import '../widgets/chat_user_cart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    // Fetch self info on screen initialization
    APIs.getSelfInfo();

    // Monitor app lifecycle (app goes to background/foreground)
    if (APIs.auth.currentUser != null) {
      SystemChannels.lifecycle.setMessageHandler((message) async {
        if (message.toString().contains('resume')) {
          APIs.updateActiveStatus(true);
        }
        if (message.toString().contains('pause')) {
          APIs.updateActiveStatus(false);
        }
        return Future.value(message);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: WillPopScope(
        onWillPop: () async {
          if (_isSearching) {
            setState(() => _isSearching = false);
            return false;
          }
          return true;
        },
        child: Scaffold(
          appBar: AppBar(
            title: _isSearching
                ? TextField(
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Name, Email...',
              ),
              autofocus: true,
              style: const TextStyle(fontSize: 17, letterSpacing: 0.5),
              onChanged: (val) {
                _searchList.clear();
                _searchList.addAll(
                  _list.where(
                        (user) =>
                    user.name.toLowerCase().contains(val.toLowerCase()) ||
                        user.email.toLowerCase().contains(val.toLowerCase()),
                  ),
                );
                setState(() {});
              },
            )
                : const Text('PixaTalk'),
            actions: [
              IconButton(
                icon: Icon(_isSearching
                    ? CupertinoIcons.clear_circled_solid
                    : Icons.search),
                onPressed: () {
                  setState(() => _isSearching = !_isSearching);
                },
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProfileScreen(user: APIs.me),
                    ),
                  );
                },
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(bottom: 90, right: 20),
            child: FloatingActionButton(
              onPressed: () async {
                await APIs.auth.signOut();
                await GoogleSignIn().signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Icon(Icons.add_comment_rounded),
            ),
          ),
          body: StreamBuilder(
            stream: APIs.getAllUsersStream(),
            builder: (context, snapshot) {
              switch (snapshot.connectionState) {
                case ConnectionState.waiting:
                case ConnectionState.none:
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.purple),
                  );

                case ConnectionState.active:
                case ConnectionState.done:
                  final data = snapshot.data?.docs;
                  // Map users and exclude current user by filtering
                  final users = data
                      ?.map((e) => ChatUser.fromJson(e.data()))
                      .where((user) => user.id != APIs.me.id)
                      .toList() ??
                      [];
                  _list = users;

                  if (_list.isNotEmpty) {
                    return ListView.builder(
                      itemCount: _isSearching ? _searchList.length : _list.length,
                      padding: EdgeInsets.only(top: mq.height * 0.01),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final user = _isSearching ? _searchList[index] : _list[index];
                        return ChatUserCard(user: user);
                      },
                    );
                  } else {
                    return const Center(
                      child: Text(
                        'No Connection found',
                        style: TextStyle(fontSize: 20),
                      ),
                    );
                  }
              }
            },
          ),
        ),
      ),
    );
  }
}
