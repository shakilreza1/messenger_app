import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:messenger_app/Models/user.dart';
import 'package:messenger_app/Widgets/ProgressWidget.dart';
import 'package:messenger_app/main.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';



class Settings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        iconTheme: IconThemeData(
          color: Colors.white,
        ),
        backgroundColor: Colors.lightBlue,
        title: Text(
          "Account Settings",
          style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SettingsScreen(),
    );
  }
}


class SettingsScreen extends StatefulWidget {

  @override
  State createState() => SettingsScreenState();
}



class SettingsScreenState extends State<SettingsScreen> {

  TextEditingController nicknameTextEditingController;
  TextEditingController aboutMeTextEditingController;

  SharedPreferences preferences;
  String id ="";
  String nickname ="";
  String aboutMe ="";
  String photoUrl ="";
  File imageFileAvatar;
  bool isLoading = false;
  final FocusNode nicknameFocusNode = FocusNode();
  final FocusNode aboutMeFocusNode = FocusNode();


  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    readDataFromLocal();
  }

  void readDataFromLocal()async{
    preferences = await SharedPreferences.getInstance();

    id = preferences.getString("id");
    nickname = preferences.getString("nickname");
    aboutMe = preferences.getString("aboutMe");
    photoUrl = preferences.getString("photoUrl");


    nicknameTextEditingController = TextEditingController(text: nickname);
    aboutMeTextEditingController = TextEditingController(text: aboutMe);

    setState(() {

    });
  }


  Future getImage()async{
    File newImageFile = await ImagePicker.pickImage(source: ImageSource.gallery);

    if(newImageFile != null)
    {
      setState(() {
        this.imageFileAvatar = newImageFile;
        isLoading = true;
      });
    }
    uplaodImageToFirestoreAndStorage();
  }

  Future uplaodImageToFirestoreAndStorage()async{
    String mFileName = id;
    StorageReference storageReference = FirebaseStorage.instance.ref().child(mFileName);
    StorageUploadTask storageUploadTask = storageReference.putFile(imageFileAvatar);
    StorageTaskSnapshot storageTaskSnapshot;
    storageUploadTask.onComplete.then((value)
    {
      if(value.error == null)
      {
        storageTaskSnapshot = value;

        storageTaskSnapshot.ref.getDownloadURL().then((newImageDownloadUrl)
        {
          photoUrl = newImageDownloadUrl;

          Firestore.instance.collection("users").document(id).updateData({
            "photoUrl":photoUrl,
            "aboutMe":aboutMe,
            "nickname":nickname,
            // "aboutMe":aboutMe,
            // "nickname":nickname,
          }).then((data)async
          {
            await preferences.setString("photoUrl",photoUrl);
            await preferences.setString("aboutMe",aboutMe);
             await preferences.setString("nickname",nickname);

            setState(() {
              isLoading = false;
            });
            Fluttertoast.showToast(msg: "Updated Successfully");
          });
        },onError: (errorMsg)
        {
          setState(() {
            isLoading = false;
          });
          Fluttertoast.showToast(msg:"Eroor occured in getting Downloading url.");
        });
      }
    },onError: (errorMsg){
      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg:errorMsg.toString());
    });
  }

  void updateData()
  {
    nicknameFocusNode.unfocus();
    aboutMeFocusNode.unfocus();

    setState(() {
      isLoading = false;
    });

    Firestore.instance.collection("users").document(id).updateData({
      "photoUrl":photoUrl,
      "aboutMe":aboutMe,
      "nickname":nickname,
    }).then((data)async
    {
      await preferences.setString("photoUrl",photoUrl);
      await preferences.setString("aboutMe",aboutMe);
      await preferences.setString("nickname",nickname);

      setState(() {
        isLoading = false;
      });
      Fluttertoast.showToast(msg: "Updated Successfully");
    });
  }


  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            children: [
              //profile Image - Avatar
              Container(
                child: Center(
                  child: Stack(
                    children: [
                      (imageFileAvatar == null) ?(photoUrl != "") ?
                      Material(
                        //Display already exiting - old image file
                        child: CachedNetworkImage(
                          placeholder: (context, url) => Container(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation(
                                  Colors.lightBlueAccent),
                            ),
                            width: 200.0,
                            height: 200.0,
                            padding: EdgeInsets.all(20.0),
                          ),
                          imageUrl: photoUrl,
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(125.0)),
                        clipBehavior: Clip.hardEdge,
                      )
                          : Icon(
                        Icons.account_circle, size: 90.0, color: Colors.grey,)
                          : Material(
                        //Display the new updated image here
                        child: Image.file(
                          imageFileAvatar,
                          width: 200.0,
                          height: 200.0,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(125.0)),
                        clipBehavior: Clip.hardEdge,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.camera_alt, size: 100.0,
                          color: Colors.white54.withOpacity(0.3),
                        ),
                        onPressed: getImage,
                        padding: EdgeInsets.all(0.0),
                        splashColor: Colors.transparent,
                        highlightColor: Colors.grey,
                        iconSize: 200.0,
                      ),
                    ],
                  ),
                ),
                width: double.infinity,
                margin: EdgeInsets.all(20.0),
              ),
              //profile Image - Avatar

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(padding: EdgeInsets.all(1.0),
                    child: isLoading ? circularProgress() : Container(),
                  ),

                  //Username
                  Container(
                    child: Text(
                      "Profile Name:",
                      style: TextStyle(fontStyle: FontStyle.italic,fontWeight: FontWeight.bold,color: Colors.lightBlueAccent),
                    ),
                    margin: EdgeInsets.only(left: 10.0,bottom: 5.0,top: 10.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: Colors.lightBlueAccent),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "e.g.",
                          contentPadding: EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        controller: nicknameTextEditingController,
                        onChanged:(value){
                          nickname = value;
                        } ,
                        focusNode: nicknameFocusNode,
                      ),
                    ),
                    margin: EdgeInsets.only(left:30.0,right: 30.0),
                  ),

                  //AbouyMe
                  Container(
                    child: Text(
                      "About:",
                      style: TextStyle(fontStyle: FontStyle.italic,fontWeight: FontWeight.bold,color: Colors.lightBlueAccent),
                    ),
                    margin: EdgeInsets.only(left: 10.0,bottom: 5.0,top: 10.0),
                  ),
                  Container(
                    child: Theme(
                      data: Theme.of(context).copyWith(primaryColor: Colors.lightBlueAccent),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Bio...",
                          contentPadding: EdgeInsets.all(5.0),
                          hintStyle: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                        controller: aboutMeTextEditingController,
                        onChanged:(value){
                          aboutMe = value;
                        } ,
                        focusNode: aboutMeFocusNode,
                      ),
                    ),
                    margin: EdgeInsets.only(left:30.0,right: 30.0),
                  ),
                ],
              ),

              //Buttons
              Container(
                child: FlatButton(
                  onPressed: updateData,
                  child: Text(
                    "Update",
                    style: TextStyle(
                      fontSize: 16.0,
                    ),
                  ),
                  color: Colors.lightBlueAccent,
                  highlightColor: Colors.transparent,
                  splashColor: Colors.transparent,
                  textColor: Colors.white,
                  padding: EdgeInsets.fromLTRB(30.0, 10.0, 30.0, 10.0),
                ),
                margin: EdgeInsets.only(top: 50.0, bottom: 1.0),
              ),

              //Logout
              Padding(
                padding: EdgeInsets.only(left:50.0,right: 50.0),
                child: RaisedButton(
                  color: Colors.red,
                  onPressed: logoutUser,
                  child: Text(
                    "Logout",
                    style: TextStyle(color: Colors.white,fontSize: 14.0),
                  ),
                ),
              ),

            ],
          ),
          padding: EdgeInsets.only(left: 15.0, right: 15.0),
        ),
      ],
    );
  }


  final GoogleSignIn googleSignIn = GoogleSignIn();


  Future<Null> logoutUser()async
  {
    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();


    this.setState(() {
      isLoading = false;

    });

    Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) => MyApp()), (Route<dynamic> route) => false);
  }
}
