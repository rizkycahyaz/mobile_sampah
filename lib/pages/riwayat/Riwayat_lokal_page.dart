import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatLokalPage extends StatefulWidget {
  const RiwayatLokalPage({Key? key}) : super(key: key);

  @override
  _RiwayatLokalPageState createState() => _RiwayatLokalPageState();
}

class _RiwayatLokalPageState extends State<RiwayatLokalPage> {
  List<dynamic> riwayat = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRiwayatLokal();
  }

  Future<void> fetchRiwayatLokal() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idArmada = prefs.getString('id_armada');
    String? statusArmada = prefs.getString('status_armada');

    if (idArmada == null || statusArmada != '1') {
      print("ID Armada tidak ditemukan atau status bukan lokal.");
      setState(() => isLoading = false);
      return;
    }

    final String apiUrl =
        "http://192.168.1.10:3000/api/riwayat/$idArmada/$statusArmada";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        setState(() {
          riwayat = data["data"];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        print("Gagal ambil data: ${data['message']}");
      }
    } catch (e) {
      print("Error fetch: $e");
      setState(() => isLoading = false);
    }
  }

  // Widget buildRiwayatCard(Map<String, dynamic> item) {
  //   return Card(
  //     margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  //     elevation: 3,
  //     child: ListTile(
  //       title: Text("Volume: ${item['volume_sampah']} m³"),
  //       subtitle: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Text("Tanggal: ${item['tanggal']}"),
  //           Text("Waktu: ${item['waktu']}"),
  //           Text("ID Sumber Sampah: ${item['nama_sumbersampah']}"),
  //           Text("Surat Jalan: ${item['suratjalan']}"),
  //         ],
  //       ),
  //     ),
  //   );
  // }

Widget buildRiwayatCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green.shade100,
          child: Text(item['id'].toString()),
        ),
        title: Text("Tanggal: ${item['tanggal']}"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Volume: ${item['volume_sampah']} kg"),
            Text("Sumber Sampah: ${item['nama_sumbersampah']}"),
          ],
        ),
        trailing: Image.network(
          'http://192.168.43.116:3000/images/${item['suratjalan']}',
          width: 50,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.image_not_supported),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Riwayat Lokal")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : riwayat.isEmpty
              ? const Center(child: Text("Tidak ada riwayat lokal."))
              : ListView.builder(
                  itemCount: riwayat.length,
                  itemBuilder: (context, index) =>
                      buildRiwayatCard(riwayat[index]),
                ),
    );
  }
}
