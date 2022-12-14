

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sellers_app/mainScreen/homeScreen.dart';
import 'package:sellers_app/widgets/customeTextField.dart';
import 'package:sellers_app/widgets/error_dialog.dart';
import 'package:sellers_app/widgets/loading_dialog.dart';
import 'package:firebase_storage/firebase_storage.dart'as fStorage;
import 'package:shared_preferences/shared_preferences.dart';

import '../globlal/global.dart';

class RegisterScreen extends StatefulWidget {

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

 TextEditingController nameController=TextEditingController();
 TextEditingController passwordController=TextEditingController();
 TextEditingController confirmPasswordController=TextEditingController();
 TextEditingController phoneController=TextEditingController();
 TextEditingController locationController=TextEditingController();

 TextEditingController emailController=TextEditingController();


 XFile? imageXfile;
 final GlobalKey<FormState> _formKey=GlobalKey<FormState>();
 final ImagePicker _picker=ImagePicker();

 Position? position;
 List<Placemark>? placeMarks;

 String sellerImageUrl="";
 String completeAddress="";

 Future<void> _getImage()async{
   imageXfile=await _picker.pickImage(source: ImageSource.gallery);

   setState(() {
     imageXfile;
   });
 }

 getCurrentLocation() async{
   Position newPosition = await Geolocator.getCurrentPosition(
   desiredAccuracy: LocationAccuracy.high,
   );


   position=newPosition;
   placeMarks=await placemarkFromCoordinates(
       position!.latitude,
       position!.longitude,
   );

   Placemark pMark=placeMarks![0];

    completeAddress='${pMark.subThoroughfare} ${pMark.thoroughfare}, ${pMark.subLocality} ${pMark.locality}, ${pMark.subAdministrativeArea}, ${pMark.administrativeArea} ${pMark.postalCode}, ${pMark.country}';
    locationController.text=completeAddress;

 }

 Future<void> forValidation()async {
   if (imageXfile == null) {
     showDialog(
         context: context,
         builder: (c) {
           return ErrorDialog(
             message: "???? ???????? ?????????? ???????? ????????????",
           );
         }
     );
   }
   else {
     if (passwordController.text == confirmPasswordController.text) {
       if (confirmPasswordController.text.isNotEmpty &&
           emailController.text.isNotEmpty &&
           emailController.text.contains("@")&&
           emailController.text.contains(".com")&&
           nameController.text.isNotEmpty &&
           phoneController.text.isNotEmpty &&
           locationController.text.isNotEmpty) {
         //start up date image
         showDialog(
             context: context,
             builder: (c){
               return LoadingDialog(
                 message: "?????????? ????????????",
               )
               ;
             });
         String fileName=DateTime.now().millisecondsSinceEpoch.toString();
         fStorage.Reference reference=fStorage.FirebaseStorage.instance.ref().child("sellers").child(fileName);
         fStorage.UploadTask uploadTask=reference.putFile(File(imageXfile!.path));
         fStorage.TaskSnapshot taskSnapshot=await uploadTask.whenComplete((){});
         await taskSnapshot.ref.getDownloadURL().then((url){
           sellerImageUrl=url;

           //save information to fir store database
//???? ??????????????
           authenticateSellerAndSignUp();
         });

       }
       else {
         showDialog(
             context: context,
             builder: (c) {
               return ErrorDialog(
                 message: "???? ???????? ???????? ???? ?????????? ???????? ????????????",
               );
             }
         );
       }
     }
     else {
       showDialog(
           context: context,
           builder: (c) {
             return ErrorDialog(
               message: "???????? ???????????? ?????? ??????????????",
             );
           }
       );
     }
   }
 }

 void authenticateSellerAndSignUp()async{
   User? currentUser;
    await firebaseAuth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text).then((auth){
          currentUser=auth.user;

    }).catchError((error){
      Navigator.pop(context);
      showDialog(
          context: context,
          builder: (c) {
            return ErrorDialog(
              message: "??????" + error.message.toString(),
            );
          });
    });

    if(currentUser!=null){
      saveDataToFirestore(currentUser!).then((value){
      Navigator.pop(context);
        //send the user for home page
        
        Route newRoute=MaterialPageRoute(builder: (c)=>HomeScreen());
        Navigator.pushReplacement(context, newRoute);

      });
    }
 }

 Future saveDataToFirestore(User currentUser)async{
   FirebaseFirestore.instance.collection("sellers").doc(currentUser.uid).set({
   "sellerUID":currentUser.uid,
     "sellerEmail":currentUser.email,
     "sellerName":nameController.text.trim(),
     "sellerAvatarUrl":sellerImageUrl,
     "phone":phoneController.text.trim(),
     "address":completeAddress,
     "status":"approved",
     "earnings":0.0,
     "lat":position!.latitude,
     "lng":position!.longitude
   });
   // save data locally
   sharedPreferences=await SharedPreferences.getInstance();
   await sharedPreferences!.setString("uid", currentUser.uid);
   await sharedPreferences!.setString("email", currentUser.email.toString());
   await sharedPreferences!.setString("name", nameController.text.trim());
   await sharedPreferences!.setString("photoUrl", sellerImageUrl);



 }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children:  [
          const SizedBox(height: 10,),
          InkWell(

            onTap: (){
              _getImage();
            },
            child: CircleAvatar(
              radius: MediaQuery.of(context).size.width*0.20,
              backgroundColor: Colors.white,
              backgroundImage: imageXfile==null?null : FileImage(File(imageXfile!.path)),
              child: imageXfile==null?Icon(
                Icons.add_photo_alternate,
                color: Colors.grey,
                size: MediaQuery.of(context).size.width*0.20,
              ):null,
            ),
          ),
          const SizedBox(height: 8,),
          Form(
              key: _formKey,
              child:Column(
                children: [
                 CustomTextFiled(
                   data: Icons.person,
                   controller: nameController,
                   hintText: "?????? ????????????????",
                   isObsece: false,
                 ),
                  CustomTextFiled(
                    data: Icons.email,
                    controller: emailController,
                    hintText: "???????????? ????????????????????",
                    isObsece: false,
                  ),

                  CustomTextFiled(
                    data: Icons.lock,
                    controller: passwordController,
                    hintText: "???????? ????????????",
                    isObsece: true,
                  ),

                  CustomTextFiled(
                    data: Icons.lock,
                    controller: confirmPasswordController,
                    hintText: "?????????? ???????? ????????????",
                    isObsece: true,
                  ),

                  CustomTextFiled(
                    data: Icons.phone,
                    controller: phoneController,
                    hintText: "?????? ???????????? ??????????????",
                    isObsece: false,
                  ),

                  CustomTextFiled(
                    data: Icons.my_location,
                    controller: locationController,
                    hintText: "?????????? ??????????????",
                    isObsece: false,
                    enabled: false,
                  ),

                  Container(
                    width: 400,
                    height: 40,
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(

                        label: const Text("???????? ?????? ???????????? ????????????",style:
                          TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      icon: const Icon(Icons.location_on,
                        color: Colors.white,

                      ),
                      onPressed: (){
                        getCurrentLocation();
                    },
                      style: ElevatedButton.styleFrom(
                        primary: Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),

                        ),
                      ),
                    ),
                  ),


                ],
              ),

          ),
          const SizedBox(height: 30,),
          ElevatedButton(
              onPressed: (){
                forValidation();
            },
              child: const Text("??????????",style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              ),
            style: ElevatedButton.styleFrom(
              primary: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 80,vertical: 5)
            ),
          ),
          const SizedBox(height: 30,),
        ],
      ),
    );
  }
}



