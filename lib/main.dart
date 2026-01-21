import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';

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

  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final locationController = TextEditingController();
  final khasraController = TextEditingController();
  final farmSizeController = TextEditingController();
  final cropNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fillLocationAutomatically();
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    addressController.dispose();
    locationController.dispose();
    khasraController.dispose();
    farmSizeController.dispose();
    cropNameController.dispose();
    super.dispose();
  }

  Future<void> _fillLocationAutomatically() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }

      if (permission == LocationPermission.deniedForever) return;

      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.best,
      );

      Position position =
          await Geolocator.getCurrentPosition(locationSettings: locationSettings);

      List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);
      Placemark place = placemarks.first;

      setState(() {
        locationController.text =
            "Lat: ${position.latitude}, Lon: ${position.longitude}";
        addressController.text =
            "${place.name}, ${place.street}, ${place.locality}, ${place.country}";
      });
    } catch (e) {
      print("Error fetching location: $e");
    }
  }

  Future<void> pickImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _image = File(pickedFile.path));
    }
  }

  Future<void> submitData() async {
    if (!_formKey.currentState!.validate()) return;

    final uri = Uri.parse("http://10.12.116.81:5000/upload");
    var request = http.MultipartRequest("POST", uri);

    request.fields['name'] = nameController.text;
    request.fields['email'] = emailController.text;
    request.fields['address'] = addressController.text;
    request.fields['location'] = locationController.text;
    request.fields['khasra'] = khasraController.text;
    request.fields['farm_size'] = farmSizeController.text;
    request.fields['crop'] = cropNameController.text;

    if (_image != null) {
      request.files
          .add(await http.MultipartFile.fromPath('soil_image', _image!.path));
    }

    try {
      var response = await request.send().timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Data uploaded successfully!")),
        );
        _formKey.currentState!.reset();
        setState(() => _image = null);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed. Status: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error uploading data: $e")),
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
          // Form fields
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
            readOnly: true, // Auto-filled
          ),
          TextFormField(
            controller: khasraController,
            decoration: InputDecoration(labelText: "Khasra Number / Plot ID"),
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
          // Image picker
          if (_image != null) Image.file(_image!, height: 150),
          ElevatedButton(onPressed: pickImage, child: Text("Upload Soil Image")),
          SizedBox(height: 10),
          ElevatedButton(onPressed: submitData, child: Text("Upload Data")),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please enter your name first")),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      UserReportsPage(username: nameController.text),
                ),
              );
            },
            child: Text("View My Reports"),
          ),
        ],
      ),
    );
  }
}

class UserReportsPage extends StatefulWidget {
  final String username;
  UserReportsPage({required this.username});

  @override
  _UserReportsPageState createState() => _UserReportsPageState();
}

class _UserReportsPageState extends State<UserReportsPage> {
  List<dynamic> reports = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    final uri = Uri.parse(
      "http://10.12.116.81:5000/get_reports?username=${widget.username}"
    );
    try {
      final response = await http.get(uri).timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success') {
          setState(() {
            reports = data['reports'];
            isLoading = false;
          });
        } else {
          setState(() => isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed: ${data['message']}")));
        }
      } else {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Server error ${response.statusCode}")));
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error fetching reports: $e")));
    }
  }

  Future<void> downloadAndOpenFile(String url, String fileName) async {
    try {
      final response = await http.get(Uri.parse(url)).timeout(Duration(seconds: 30));
      if (response.statusCode == 200) {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory("${dir.path}/soil_reports");
        if (!folder.existsSync()) folder.createSync();

        final file = File("${folder.path}/$fileName");
        await file.writeAsBytes(response.bodyBytes);

        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Downloaded $fileName")));
        await OpenFile.open(file.path);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Failed to download $fileName")));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error downloading file: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.username}'s Reports")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : reports.isEmpty
              ? Center(child: Text("No reports found."))
              : ListView.builder(
                  itemCount: reports.length,
                  itemBuilder: (context, index) {
                    final report = reports[index];
                    return Card(
                      child: ListTile(
                        title: Text(report['file_name']),
                        subtitle: Text(
                            "Survey: ${report['survey_no']} | Time: ${report['timestamp']}"),
                        trailing: IconButton(
                          icon: Icon(Icons.download),
                          onPressed: () => downloadAndOpenFile(
                              report['url'], report['file_name']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
