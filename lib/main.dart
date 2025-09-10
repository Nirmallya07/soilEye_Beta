import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: SoilEyeApp(),
  ));
}

class SoilEyeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Soil Eye",
          style: TextStyle(
            fontFamily: "DMSerifText",
            fontSize: 30,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SoilFormPage(),
    );
  }
}

class SoilFormPage extends StatefulWidget {
  @override
  _SoilFormPageState createState() => _SoilFormPageState();
}

class _SoilFormPageState extends State<SoilFormPage> {
  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker();
  File? _image;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final locationController = TextEditingController();
  final khasraController = TextEditingController();
  final farmSizeController = TextEditingController();
  final cropNameController = TextEditingController();

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri.parse("http://10.12.127.213:5000/upload"); // Replace with your laptop IP
    var request = http.MultipartRequest("POST", uri);

    request.fields['name'] = nameController.text;
    request.fields['email'] = emailController.text;
    request.fields['address'] = addressController.text;
    request.fields['location'] = locationController.text;
    request.fields['khasra'] = khasraController.text;
    request.fields['farm_size'] = farmSizeController.text;
    request.fields['crop'] = cropNameController.text;

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('soil_image', _image!.path));
    }

    var response = await request.send();
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data uploaded successfully!")),
      );
      _formKey.currentState!.reset();
      setState(() => _image = null);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload failed.")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.all(20),
        children: [
          Column(
            children: [
              Text(
                "Empowering Farmers for a Sustainable Future",
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: "OpenSans_Condensed",
                ),
              ),
              SizedBox(height: 5),
              Container(height: 2, color: Colors.greenAccent),
            ],
          ),
          SizedBox(height: 20),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(labelText: "Name"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: emailController,
            decoration: InputDecoration(labelText: "Email"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: addressController,
            decoration: InputDecoration(labelText: "Address"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: locationController,
            decoration: InputDecoration(labelText: "Location"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: khasraController,
            decoration: InputDecoration(labelText: "Khasra Number"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: farmSizeController,
            decoration: InputDecoration(labelText: "Farm Size (sqft)"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          TextFormField(
            controller: cropNameController,
            decoration: InputDecoration(labelText: "Crop Name"),
            validator: (v) => v!.isEmpty ? "Required" : null,
          ),
          SizedBox(height: 20),
          if (_image != null)
            Image.file(_image!, height: 150),
          ElevatedButton(onPressed: pickImage, child: Text("Upload Soil Image")),
          SizedBox(height: 20),
          ElevatedButton(onPressed: submitData, child: Text("Generate Soil Health Card")),
        ],
      ),
    );
  }
}
