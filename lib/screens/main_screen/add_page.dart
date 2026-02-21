import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  State<AddPage> createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _quantity = 1;
  File? _imageFile;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  /// A method to determine the current position of the device.
  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled. Please enable them in your settings.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // Get current position
    return await Geolocator.getCurrentPosition();
  }


  Future<void> _postProduct() async {
    if (!_formKey.currentState!.validate() || _imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and add an image.')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // --- Automatically get location before posting ---
      final Position position = await _determinePosition();
      // ---

      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw const AuthException('User not authenticated.');
      }

      final imageFile = _imageFile!;
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.${imageFile.path.split('.').last}';

      await supabase.storage
          .from('product_images')
          .upload(fileName, imageFile);

      final imageUrl = supabase.storage
          .from('product_images')
          .getPublicUrl(fileName);

      // Format the location data for PostGIS using the fetched position
      final locationString = 'POINT(${position.longitude} ${position.latitude})';

      await supabase.from('products').insert({
        'productName': _nameController.text,
        'price': double.tryParse(_priceController.text) ?? 0.0,
        'quantity': _quantity,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'sellerName': user.userMetadata?['full_name'] ?? 'Anonymous Seller',
        'sellerID': user.id,
        'location': locationString, // Save the auto-fetched location
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product posted successfully!')),
      );
      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to post product: $e')),
      );
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _priceController.clear();
    _descriptionController.clear();
    setState(() {
      _quantity = 1;
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Product Detail'),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextField(_nameController, 'Product Name'),
              const SizedBox(height: 16),
              _buildQuantityAndPrice(),
              const SizedBox(height: 16),
              _buildTextField(_descriptionController, 'Product Detail'),
              const SizedBox(height: 32),
              _isUploading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                onPressed: _postProduct,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[200],
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Post Product',
                  style: TextStyle(color: Colors.black54, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: _imageFile != null
            ? ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(_imageFile!, fit: BoxFit.cover),
        )
            : Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.camera_alt_outlined, color: Colors.grey[600], size: 40),
            const SizedBox(height: 8),
            const Text('Change photo', style: TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) => value!.isEmpty ? '$label can\'t be empty' : null,
    );
  }

  Widget _buildQuantityAndPrice() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text('1kg, Price', style: TextStyle(fontSize: 16)),
        const Spacer(),
        IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() => _quantity > 1 ? _quantity-- : null)),
        Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() => _quantity++)),
        const SizedBox(width: 20),
        Expanded(
          child: TextFormField(
            controller: _priceController,
            decoration: const InputDecoration(labelText: 'Rs.'),
            keyboardType: TextInputType.number,
            validator: (value) => value!.isEmpty ? 'Price is required' : null,
          ),
        ),
      ],
    );
  }
}