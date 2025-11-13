import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/api/apis.dart';
import 'package:frontend/models/chat_user_card.dart';
import 'package:frontend/screens/profile_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gif/gif.dart';
import '../auth/login_screen.dart';
import '../widgets/chat_user_cart.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  List<ChatUser> _list = [];
  final List<ChatUser> _searchList = [];
  bool _isSearching = false;

  late GifController _gifController;
  bool _isLoading = true; // New flag to show loading until APIs.me is ready

  @override
  void initState() {
    super.initState();

    _gifController = GifController(vsync: this);

    _initialize();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startGifLoop();
    });
  }

  Future<void> _initialize() async {
    await APIs.getSelfInfo();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _startGifLoop() async {
    const int totalFrames = 30; // total frames of your gif
    while (mounted) {
      await _gifController.animateTo(
        totalFrames.toDouble(),
        duration: const Duration(seconds: 2),
        curve: Curves.linear,
      );
      await _gifController.animateBack(
        0,
        duration: const Duration(seconds: 2),
        curve: Curves.linear,
      );
      await _gifController.animateTo(
        totalFrames.toDouble(),
        duration: const Duration(seconds: 2),
        curve: Curves.linear,
      );
    }
  }

  @override
  void dispose() {
    _gifController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show loading indicator until APIs.me is ready
    if (_isLoading || APIs.me == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
            leadingWidth: 130,
            leading: GestureDetector(
              onTap: () {},
              child: Gif(
                controller: _gifController,
                image: const AssetImage('assets/ai.gif'),
                width: 200,
                height: 200,
              ),
            ),
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
                  _list.where((user) =>
                  user.name.toLowerCase().contains(val.toLowerCase()) ||
                      user.email.toLowerCase().contains(val.toLowerCase())),
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
                  final users = data
                      ?.map((e) => ChatUser.fromJson(e.data()))
                      .where((user) => user.id != APIs.me.id)
                      .toList() ??
                      [];
                  _list = users;

                  if (_list.isNotEmpty) {
                    return ListView.builder(
                      itemCount: _isSearching ? _searchList.length : _list.length,
                      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.01),
                      physics: const BouncingScrollPhysics(),
                      itemBuilder: (context, index) {
                        final user =
                        _isSearching ? _searchList[index] : _list[index];
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
