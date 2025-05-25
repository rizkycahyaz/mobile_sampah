import 'package:armada_app/pages/Profile_Page.dart';
import 'package:armada_app/pages/riwayat/Riwayat_komersil_page.dart';
import 'package:armada_app/pages/riwayat/Riwayat_lokal_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class NavbarPage extends StatefulWidget {
  final String? idArmada;

  const NavbarPage({Key? key, this.idArmada}) : super(key: key);

  @override
  _NavbarPageState createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  int _selectedIndex = 0;
  String? idArmada;
  String? statusArmada;
  Timer? _trackingTimer;

  @override
  void initState() {
    super.initState();
    _loadDataFromPrefs();
  }

  Future<void> _loadDataFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? storedId = prefs.getString('id_armada');
    String? storedStatus = prefs.getString('status_armada');

    if (storedId != null && storedStatus != null) {
      setState(() {
        idArmada = storedId;
        statusArmada = storedStatus;
      });

      startTrackingPeriodic(storedId); // ⬅️ Mulai tracking otomatis
    }
  }

  void startTrackingPeriodic(String idArmada) {
    _trackingTimer?.cancel(); // hentikan timer lama jika ada

    _trackingTimer = Timer.periodic(Duration(minutes: 5), (Timer timer) async {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever || !serviceEnabled) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      final url = Uri.parse('http://192.168.100.153:3000/api/tracking');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_armada': idArmada,
          'latitude': position.latitude,
          'longitude': position.longitude,
        }),
      );

      if (response.statusCode == 200) {
        print("Lokasi dikirim: ${position.latitude}, ${position.longitude}");
      } else {
        print("Gagal mengirim lokasi");
      }
    });
  }

  @override
  void dispose() {
    _trackingTimer?.cancel(); // stop timer saat widget dihancurkan
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (idArmada == null || statusArmada == null || idArmada == '' || statusArmada == '') {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final List<Widget> _pages = [
      statusArmada == '1'
          ? RiwayatLokalPage()
          : RiwayatKomersilPage(),
      ProfilePage(idArmada: idArmada!),
    ];

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
