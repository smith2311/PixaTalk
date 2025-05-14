import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:frontend/api/apis.dart';
import 'package:frontend/helper/dialogs.dart';
import 'package:frontend/models/chat_user_card.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import '../auth/login_screen.dart';
import '../main.dart';

class ProfileScreen extends StatefulWidget {
  final ChatUser user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _image;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context).size; // To get screen size for resizing

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 90, right: 20),
          child: FloatingActionButton.extended(
            onPressed: () async {
              Dialogs.showProgressBar(context);
              
              await APIs.updateActiveStatus(false);
              
              await APIs.auth.signOut().then((value) async {
                await GoogleSignIn().signOut().then((value) {
                  Navigator.pop(context);
                  Navigator.pop(context);

                  APIs.auth= FirebaseAuth.instance;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                });
              });
            },
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white)),
            backgroundColor: Colors.red,
          ),
        ),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: mq.width * .05),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(width: mq.width, height: mq.height * .04),

                  Stack(
                    children: [
                      _image != null ?  ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .1),
                        child: Image.file(
                          File(_image!),
                          width: mq.height * .20,
                          height: mq.height * .20,
                          fit: BoxFit.cover,
                        ),
                      ):

                      ClipRRect(
                        borderRadius: BorderRadius.circular(mq.height * .1),
                        child: CachedNetworkImage(
                          width: mq.height * .20,
                          height: mq.height * .20,
                          fit: BoxFit.cover,
                          imageUrl: widget.user.image,
                          errorWidget: (context, url, error) =>
                          const CircleAvatar(child: Icon(CupertinoIcons.person)),
                        ),
                      ),
                      // Edit image button
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: MaterialButton(
                          onPressed: () {
                            _showBottomSheet();
                          },
                          elevation: 1,
                          shape: const CircleBorder(),
                          color: Colors.white,
                          child: const Icon(Icons.edit, color: Colors.blue),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: mq.height * .04),
                  Text(widget.user.email,
                      style: const TextStyle(color: Colors.black54, fontSize: 16)),
                  SizedBox(width: mq.width, height: mq.height * .05),
                  TextFormField(
                    initialValue: widget.user.name,
                    onSaved: (val) => APIs.me.name = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.person, color: Colors.blue.shade400),
                      hintText: 'Eg: Shivam Kansara',
                      label: const Text('Name'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  SizedBox(width: mq.width, height: mq.height * .02),
                  TextFormField(
                    initialValue: widget.user.about,
                    onSaved: (val) => APIs.me.about = val ?? '',
                    validator: (val) =>
                    val != null && val.isNotEmpty ? null : 'Required Field',
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.info_outline, color: Colors.blue.shade400),
                      hintText: 'Eg: Feeling Happy!!',
                      label: const Text('About You'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                  SizedBox(width: mq.width, height: mq.height * .05),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: const StadiumBorder(),
                      minimumSize: Size(mq.width * .4, mq.width * .1),
                    ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        APIs.updateUserInfo().then((value) {
                          Dialogs.showSnackBar(context, 'Profile Updated Successfully');
                        });
                        log('inside validator');
                      }
                    },
                    icon: const Icon(Icons.edit, size: 28, color: Colors.white),
                    label: const Text('UPDATE', style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20))),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          padding: EdgeInsets.only(top: mq.height * .03, bottom: mq.height * .05),
          children: [
            const Text('Time for a fresh look!!', textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
            SizedBox(height: mq.height * .02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Gallery button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * 0.2, mq.width * 0.2), // Resize button based on screen width
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

                    if(image != null){
                      log('Image Path: ${image.path} --Mime Type: ${image.mimeType}');
                      setState(() {
                        _image= image.path;
                      });
                      APIs.updateProfilePicture(File(_image!));
                      //for hiding bottom sheet
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset(
                    'assets/picture.png',
                    fit: BoxFit.cover,
                    width: mq.width * 0.1, // Resize the image based on screen width
                    height: mq.width * 0.1, // Resize the image based on screen width
                  ),
                ),
                // Camera button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: const CircleBorder(),
                    fixedSize: Size(mq.width * 0.3, mq.width * 0.2), // Resize button based on screen width
                  ),
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();
                    final XFile? image = await picker.pickImage(source: ImageSource.camera);

                    if(image != null){
                      log('Image Path: ${image.path}');
                      setState(() {
                        _image= image.path;
                      });
                      APIs.updateProfilePicture(File(_image!));
                      //for hiding bottom sheet
                      Navigator.pop(context);
                    }
                  },
                  child: Image.asset(
                    'assets/camera.png',
                    fit: BoxFit.cover,
                    width: mq.width * 0.1, // Resize the image based on screen width
                    height: mq.width * 0.1, // Resize the image based on screen width
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
