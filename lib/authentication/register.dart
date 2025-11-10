// ignore_for_file: deprecated_member_use

import 'dart:typed_data';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:projectz/global/global.dart';
import 'package:projectz/widgets/customTextField.dart';
import 'package:http/http.dart' as http;
import 'package:projectz/widgets/loadingDialog.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:projectz/mainScreens/homeScreen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController nameFieldController = TextEditingController();
  TextEditingController emailFieldController = TextEditingController();
  TextEditingController passwordFieldController = TextEditingController();
  TextEditingController confirmPasswordFieldController = TextEditingController();
  TextEditingController phoneFieldController = TextEditingController();
  TextEditingController addressFieldController = TextEditingController();
  

  Position? sellerCurrentPosition;
  List<Placemark>? sellerPlacemarks;

  Future<String?> _getAddressFromCoordinatesWeb(double lat, double lng) async {
    try {
      // Using Nominatim API (OpenStreetMap) for reverse geocoding
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1'
      );
      
      final response = await http.get(
        url,
        headers: {'User-Agent': 'FlutterSellerApp/1.0'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Extract address components
        final address = data['address'];
        String formattedAddress = '';
        
        if (address != null) {
          List<String> addressParts = [];
          
          if (address['road'] != null) addressParts.add(address['road']);
          if (address['suburb'] != null) addressParts.add(address['suburb']);
          if (address['city'] != null) addressParts.add(address['city']);
          if (address['state'] != null) addressParts.add(address['state']);
          if (address['postcode'] != null) addressParts.add(address['postcode']);
          if (address['country'] != null) addressParts.add(address['country']);
          
          formattedAddress = addressParts.join(', ');
        }
        
        return formattedAddress.isNotEmpty ? formattedAddress : data['display_name'];
      }
    } catch (e) {
      print('Error getting address from API: $e');
    }
    return null;
  }

  Future<void> formValidation() async
  {
    if(imageXFile == null)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please select an image."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(nameFieldController.text.trim().isEmpty)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please enter your name."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(emailFieldController.text.trim().isEmpty)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please enter your email."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(!emailFieldController.text.contains("@"))
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please enter a valid email."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(passwordFieldController.text.trim().isEmpty)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please enter a password."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(passwordFieldController.text.length < 6)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Password must be at least 6 characters."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(confirmPasswordFieldController.text.trim().isEmpty)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please confirm your password."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(passwordFieldController.text != confirmPasswordFieldController.text)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Passwords do not match."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(phoneFieldController.text.trim().isEmpty)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please enter your phone number."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else if(addressFieldController.text.trim().isEmpty)
    {
      showDialog(
        context: context, 
        builder: 
        (c)
        {
          return AlertDialog(
            content: Text("Please provide your shop address."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        }
      );
    }
    else
    {
      // proceed with registration
      showDialog(
        context: context, 
        builder: (c) {
          return LoadingDialog(
            message: "Registering Account",
          );
        }
      );

      // Upload image to Supabase and register user
      await uploadImageAndRegister();
    }
  }

  Future<void> uploadImageAndRegister() async {
    try {
      if (imageXFile == null || imageBytes == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please select an image')),
        );
        return;
      }

      // Generate unique filename
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      String fileExtension = imageXFile!.name.split('.').last;
      String fullFileName = '$fileName.$fileExtension';

      // Upload to Supabase Storage
      final supabaseClient = supabase.Supabase.instance.client;
      
      await supabaseClient.storage
        .from('user-images')
        .uploadBinary(
          fullFileName,
          imageBytes!,
          fileOptions: supabase.FileOptions(
            contentType: 'image/$fileExtension',
            upsert: true,
          ),
        );

      // Get public URL of uploaded image
      final String imageUrl = supabaseClient.storage
        .from('user-images')
        .getPublicUrl(fullFileName);

      print('Image uploaded successfully: $imageUrl');

      // Authenticate and register user with Firebase
      await authenticateSellerAndSignUp(imageUrl);

      // Note: Loading dialog is closed in authenticateSellerAndSignUp()

    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error uploading image: $e');
      
      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            content: Text('Error uploading image: ${e.toString()}'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  void clearForm() {
    setState(() {
      imageXFile = null;
      imageBytes = null;
      nameFieldController.clear();
      emailFieldController.clear();
      passwordFieldController.clear();
      confirmPasswordFieldController.clear();
      phoneFieldController.clear();
      addressFieldController.clear();
    });
  }

  Future<void> authenticateSellerAndSignUp(String imageUrl) async {
    User? currentUser;
    
    try {
      final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
      
      // Create user with email and password
      await firebaseAuth.createUserWithEmailAndPassword(
        email: emailFieldController.text.trim(),
        password: passwordFieldController.text.trim(),
      ).then((auth) {
        currentUser = auth.user;
      });

      if (currentUser != null) {
        // Save user data to Firestore
        await saveDataToFirestore(currentUser!, imageUrl).then((value) {
          Navigator.pop(context); // Close loading dialog
          
          // Navigate to home screen
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (c) => const HomeScreen()),
          );
        });
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      
      showDialog(
        context: context,
        builder: (c) {
          return AlertDialog(
            content: Text('Error: ${e.toString()}'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(c);
                },
                child: Text("OK"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> saveDataToFirestore(User currentUser, String imageUrl) async {
    await FirebaseFirestore.instance.collection("sellers").doc(currentUser.uid).set({
      "sellerUID": currentUser.uid,
      "sellerEmail": currentUser.email,
      "sellerName": nameFieldController.text.trim(),
      "sellerAvatarUrl": imageUrl,
      "phone": phoneFieldController.text.trim(),
      "address": addressFieldController.text.trim(),
      "status": "approved",
      "earnings": 0.0,
      "lat": sellerCurrentPosition?.latitude ?? 0.0,
      "lng": sellerCurrentPosition?.longitude ?? 0.0,
    });

    // save data locally using SharedPreferences 

    sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences!.setString("sellerUID", currentUser.uid);
    await sharedPreferences!.setString("sellerEmail", currentUser.email!.toString());
    await sharedPreferences!.setString("sellerName", nameFieldController.text.trim());
    await sharedPreferences!.setString("sellerAvatarUrl", imageUrl);
    await sharedPreferences!.setString("phone", phoneFieldController.text.trim());
    await sharedPreferences!.setString("address", addressFieldController.text.trim());

    // Debug logging
    print("=== REGISTER: SharedPreferences Saved ===");
    print("sellerUID: ${currentUser.uid}");
    print("sellerEmail: ${currentUser.email}");
    print("sellerName: ${nameFieldController.text.trim()}");
    print("=========================================");
  }

  getCurrentLocation() async
  {    
    try {
      Position newPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      sellerCurrentPosition = newPosition;

      if (kIsWeb) {
        // On web, use Nominatim API for reverse geocoding
        addressFieldController.text = 'Loading address...';
        
        String? address = await _getAddressFromCoordinatesWeb(
          newPosition.latitude,
          newPosition.longitude,
        );
        
        if (address != null && address.isNotEmpty) {
          addressFieldController.text = address;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Location captured successfully!')),
          );
        } else {
          // Fallback to coordinates if API fails
          String webAddress = 'Lat: ${newPosition.latitude.toStringAsFixed(6)}, Lng: ${newPosition.longitude.toStringAsFixed(6)}';
          addressFieldController.text = webAddress;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Got coordinates (address lookup failed)')),
          );
        }
      } else {
        // On mobile, use geocoding
        sellerPlacemarks = await placemarkFromCoordinates(
          sellerCurrentPosition!.latitude,
          sellerCurrentPosition!.longitude,
        );

        if (sellerPlacemarks != null && sellerPlacemarks!.isNotEmpty) {
          Placemark pMark = sellerPlacemarks![0];

          String completeAddressInfo =
              '${pMark.subThoroughfare} ${pMark.thoroughfare}, ${pMark.subLocality} ${pMark.locality}, ${pMark.subAdministrativeArea}, ${pMark.administrativeArea} ${pMark.postalCode}, ${pMark.country}';

          print('Complete Address Info: ' + completeAddressInfo);

          String specificAddress = '${pMark.subLocality} ${pMark.locality}, ${pMark.administrativeArea} ${pMark.postalCode}, ${pMark.country}';

          addressFieldController.text = specificAddress;
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: ${e.toString()}')),
      );
    }
  }

  XFile? imageXFile;
  final ImagePicker _picker = ImagePicker();
  Uint8List? imageBytes;

  Future<void> _getImage() async
  {
    imageXFile = await _picker.pickImage(source: ImageSource.gallery);
    if (imageXFile != null) {
      imageBytes = await imageXFile!.readAsBytes();
    }
    setState(() {});
  }

  ImageProvider? _getImageProvider() {
    if (imageXFile == null) return null;
    
    if (kIsWeb) {
      // For web platform, use MemoryImage with bytes
      return imageBytes != null ? MemoryImage(imageBytes!) : null;
    } else {
      // For mobile platforms (iOS/Android), use FileImage
      try {
        return FileImage(File(imageXFile!.path));
      } catch (e) {
        // Fallback to MemoryImage if File is not available
        return imageBytes != null ? MemoryImage(imageBytes!) : null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Container(
        child: Column(
          mainAxisSize:  MainAxisSize.max,
          children: [
            const SizedBox (height: 10,),
            InkWell(
              onTap: () {
                _getImage();
              },
              child: CircleAvatar(
                radius: MediaQuery.of(context).size.width * 0.20,
                backgroundColor: Colors.white,
                backgroundImage: _getImageProvider(),
                child: imageXFile == null
                    ? 
                    Icon(
                      Icons.add_photo_alternate,
                      size: MediaQuery.of(context).size.width * 0.20,
                      color: Colors.grey,
                    )
                    : null,

              ),
            ),
            const SizedBox (height: 10,),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  CustomTextField(
                    controller: nameFieldController,
                    data: Icons.person,
                    hintText: 'Name',
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: emailFieldController,
                    data: Icons.email,
                    hintText: 'Email',
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: passwordFieldController,
                    data: Icons.lock,
                    hintText: 'Password',
                  ),
                  CustomTextField(
                    controller: confirmPasswordFieldController,
                    data: Icons.lock,
                    hintText: 'Confirm Password',
                  ),
                  CustomTextField(
                    controller: phoneFieldController,
                    data: Icons.phone,
                    hintText: 'Phone',
                    isObsecure: false,
                  ),
                  CustomTextField(
                    controller: addressFieldController,
                    data: Icons.location_city,
                    hintText: 'Shop Address',
                    isObsecure: false,
                    enabled: true,
                  ),
                  Container(
                    width: 400,
                    height: 40,
                    alignment: Alignment.center,
                    child: ElevatedButton.icon(
                      label: Text(
                        "Get my location",
                        style: TextStyle(color: Colors.white ),
                      ),
                        
                        
                      icon: Icon(
                        Icons.location_on,
                        color: Colors.white,
                      ),
                      onPressed: () {
                        getCurrentLocation();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyan,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                    ),

                  )
                ],
              ),
               
            ),
            const SizedBox( height: 30, ),
            ElevatedButton(
              child: const Text(
                "Sign Up",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 20),
              ),
              onPressed: () 
              {
                formValidation();
              },
              ),
            const SizedBox( height: 30, ),
          ],
          
        ),
      ),
    );
  }
}