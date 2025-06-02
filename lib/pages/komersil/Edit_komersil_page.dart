import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


class EditRiwayatPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const EditRiwayatPage({Key? key, required this.data}) : super(key: key);

  @override
  State<EditRiwayatPage> createState() => _EditRiwayatPageState();
}

class _EditRiwayatPageState extends State<EditRiwayatPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _volumeController;
  int? _selectedJenisSampah;

  @override
  void initState() {
    super.initState();

//Cetak data ke console
  print("DATA YANG DITERIMA: ${widget.data}");


    _volumeController = TextEditingController(
        text: (widget.data['volume_sampah'] ?? '').toString());
    _selectedJenisSampah = int.tryParse(widget.data['jenis_sampah'].toString());
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    final url = Uri.parse("http://192.168.43.116:3000/api/komersil/update/${widget.data['id']}");
    final response = await http.post(
      url,
      body: {
        'volume_sampah': _volumeController.text,
        'jenis_sampah': _selectedJenisSampah.toString(),
      },
    );

    if (response.statusCode == 200) {
      Navigator.pop(context, true); // Bisa gunakan untuk refresh parent page
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Data berhasil diperbarui")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal memperbarui data")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Riwayat"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<int>(
                value: _selectedJenisSampah,
                onChanged: (value) {
                  setState(() => _selectedJenisSampah = value);
                },
                decoration: InputDecoration(labelText: "Jenis Sampah"),
                items: const [
                  DropdownMenuItem(value: 1, child: Text("Industri")),
                  DropdownMenuItem(value: 2, child: Text("Perekonomian")),
                  DropdownMenuItem(value: 3, child: Text("Lingkungan")),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _volumeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Volume Sampah (ton)"),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Volume tidak boleh kosong";
                  }
                  if (!RegExp(r'^\d+([.,]\d+)?$').hasMatch(value)) {
                    return "Masukkan angka yang valid";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitUpdate,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text("Simpan"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
