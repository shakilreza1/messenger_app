import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:messenger_app/Models/user.dart';
import 'package:messenger_app/Pages/ChattingPage.dart';
import 'package:messenger_app/main.dart';
import 'package:messenger_app/Pages/AccountSettingsPage.dart';
import 'package:messenger_app/Widgets/ProgressWidget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreen extends StatefulWidget {

  final String currentUserId;

  HomeScreen({Key key, @required this.currentUserId}) : super(key : key);

  @override
  State createState() => HomeScreenState(currentUserId: currentUserId);
}

class HomeScreenState extends State<HomeScreen> {

  HomeScreenState({Key key, @required this.currentUserId});

  TextEditingController searchTextEditingController = TextEditingController();
  Future<QuerySnapshot> futureSearchResults;
  final String currentUserId;



  SharedPreferences preferences;
  String id ="";
  String nickname="";
  String photoUrl ="";

  void initState() {
    // TODO: implement initState
    super.initState();
    readDataFromLocal();
  }


  void readDataFromLocal()async{
    preferences = await SharedPreferences.getInstance();

    id = preferences.getString("id");
    nickname = preferences.getString("nickname");
    photoUrl = preferences.getString("photoUrl");
    setState(() {

    });
  }


  homePageHeader(){
    return AppBar(
      automaticallyImplyLeading: false,//remove the back button
      leading:IconButton(
      splashColor: Colors.red,
      icon: Icon(Icons.edit,size: 30.0,color: Colors.white,),
      onPressed: (){
        Navigator.push(context, MaterialPageRoute(builder: (context)=> Settings()));
      },
    ),
      actions: [
        //Icon(Icons.favorite),
        /*Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Icon(Icons.search),
        ),*/
        Container(
          height: 10,
          width: 70,
          color: Colors.transparent,
          child: Center(
              child: Text(
                nickname,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 20.0,color: Colors.white,fontWeight: FontWeight.w500,letterSpacing: 0.6),
              ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(right: 10),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Material(
              //Display already exiting - old image file
              child: CachedNetworkImage(
                placeholder: (context, url) => Container(
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    valueColor: AlwaysStoppedAnimation(
                        Colors.lightBlueAccent),
                  ),
                  width: 50.0,
                  height: 50.0,
                  padding: EdgeInsets.all(20.0),
                ),
                imageUrl: photoUrl,
                width: 50.0,
                height: 50.0,
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.all(Radius.circular(50.0)),
              clipBehavior: Clip.hardEdge,
            ),
          ),
        ),

      ],
      title: Container(
        margin: EdgeInsets.only(right: 0.0),
        //width: double.infinity,
        width:200,
        height: 40,
        decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.7), borderRadius: BorderRadius.circular(30)),
        child: TextFormField(
          style: TextStyle(color: Colors.white,fontSize: 20,fontWeight: FontWeight.w600),
          cursorColor: Colors.white,
          controller: searchTextEditingController,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.search,color: Colors.white54.withOpacity(0.5),),
            hintText: "Search",
            hintStyle: TextStyle(fontSize: 22.0,color: Colors.white54.withOpacity(0.5),),
            border: InputBorder.none,
            filled: false,
            suffixIcon: IconButton(
              icon: Icon(Icons.clear,color: Colors.white,),
              onPressed: emptyTextField,
            ),
          ),
          onFieldSubmitted: controlSearching,
        ),
      ),
      backgroundColor: Colors.lightBlueAccent,
    );
  }

  emptyTextField(){
    searchTextEditingController.clear();
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: homePageHeader(),
      body:futureSearchResults == null ? displayNoSearchResultScreen() : displayUserFoundScreen(),
    );
  }

  controlSearching(String userName){
    Future<QuerySnapshot> allFoundUsers = Firestore.instance.collection("users").where("nickname",isGreaterThanOrEqualTo: userName).getDocuments();

    setState(() {
      futureSearchResults =allFoundUsers;
    });
  }

  displayUserFoundScreen(){
    return FutureBuilder(
      future: futureSearchResults,
      builder: (context, dataSnapshot){
        if(!dataSnapshot.hasData)
        {
          return circularProgress();
        }
        List<UserResult> searchUserResult = [];
        dataSnapshot.data.documents.forEach((document)
        {
          User eachUser = User.fromDocument(document);
          UserResult userResult = UserResult(eachUser);

          if(currentUserId != document["id"]){
            searchUserResult.add(userResult);
          }
        });

        return ListView(children: searchUserResult);
      },
    );
  }

  //No User Search Default Show Screen
  displayNoSearchResultScreen(){
    final Orientation orientation = MediaQuery.of(context).orientation;
    return Container(
      child: Center(
        child: ListView(
          shrinkWrap: true,
          children: [
            Icon(Icons.group,color: Colors.lightBlueAccent,size: 200.0,),
            Text(
              "Search Users",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.lightBlueAccent,fontSize: 50.0,fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
//No User Search Default Show Screen

}


// Search Users show in here...
class UserResult extends StatelessWidget
{
  final User eachUser;
  UserResult(this.eachUser);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.0),
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            GestureDetector(
              onTap: ()=> sendUserToChatPage(context),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.black,
                  backgroundImage: CachedNetworkImageProvider(eachUser.photoUrl),
                ),
                title: Text(
                  eachUser.nickname,
                  style: TextStyle(color: Colors.black,fontSize: 16.0,fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                    "Joined" + DateFormat("dd MMMM, yyyy - hh:mm:aa")
                        .format(DateTime.fromMillisecondsSinceEpoch(int.parse(eachUser.createdAt))),
                  style: TextStyle(color: Colors.grey,fontSize: 14.0,fontStyle: FontStyle.italic),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  sendUserToChatPage(BuildContext context)
  {
    Navigator.push(context, MaterialPageRoute
      (
        builder: (context)=> Chat
          (
            receiverId: eachUser.id,
            receiverAvatar: eachUser.photoUrl,
            receiverName: eachUser.nickname,
        )));
  }
}
// Search Users show in here...
