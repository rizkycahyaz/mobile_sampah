import 'package:armada_app/pages/Profile_Page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armada_app/pages/riwayat/Riwayat_komersil_page.dart';
import 'package:armada_app/pages/riwayat/Riwayat_lokal_page.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDataFromPrefs();
  }

  Future<void> _loadDataFromPrefs() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      idArmada = prefs.getString('id_armada') ?? '';
      statusArmada = prefs.getString('status_armada') ?? '';
    });
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
