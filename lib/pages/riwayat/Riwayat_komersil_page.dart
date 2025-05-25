import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:armada_app/pages/komersil/Detail_kormesil_Page.dart';

class RiwayatKomersilPage extends StatefulWidget {
  const RiwayatKomersilPage({Key? key}) : super(key: key);

  @override
  _RiwayatKomersilPageState createState() => _RiwayatKomersilPageState();
}

class _RiwayatKomersilPageState extends State<RiwayatKomersilPage>
    with SingleTickerProviderStateMixin {
  List<dynamic> riwayat = [];
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    fetchRiwayatKomersil();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String getJenisSampah(int jenis) {
    switch (jenis) {
      case 1:
        return 'Industri';
      case 2:
        return 'Perekonomian';
      case 3:
        return 'Lingkungan';
      default:
        return 'Tidak Diketahui';
    }
  }



  Future<void> fetchRiwayatKomersil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? idArmada = prefs.getString('id_armada');
    String? statusArmada = prefs.getString('status_armada');

    if (idArmada == null || statusArmada != '2') {
      print("ID atau Status Armada tidak sesuai (harus 2).");
      setState(() => isLoading = false);
      return;
    }

    final String apiUrl =
        "http://192.168.100.153:3000/api/riwayat/$idArmada/$statusArmada";

    try {
      final response = await http.get(Uri.parse(apiUrl));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        List<dynamic> rawData = data["data"];

        // Sorting berdasarkan tanggal + waktu DESC
        rawData.sort((a, b) {
          DateTime dateA = DateTime.tryParse('${a['tanggal']} ${a['waktu'] ?? '00:00'}') ?? DateTime(1970);
          DateTime dateB = DateTime.tryParse('${b['tanggal']} ${b['waktu'] ?? '00:00'}') ?? DateTime(1970);
          return dateB.compareTo(dateA);
        });

        setState(() {
          riwayat = rawData;
          isLoading = false;
        });
        _animationController.forward();
      } else {
        setState(() => isLoading = false);
        print("Gagal ambil data: ${data['message']}");
      }
    } catch (e) {
      print("Error fetch: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    setState(() => isLoading = true);
    _animationController.reset();
    await fetchRiwayatKomersil();
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return "-";
    try {
      DateTime date = DateTime.parse(dateString);
      List<String> months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
      ];
      return "${date.day} ${months[date.month - 1]} ${date.year}";
    } catch (e) {
      return dateString;
    }
  }

  Widget buildRiwayatCard(Map<String, dynamic> item, int index) {

    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _fadeAnimation.value)),
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Container(
              margin: EdgeInsets.only(
                left: 16,
                right: 16,
                top: index == 0 ? 16 : 8,
                bottom: 8,
              ),
              child: Material(
                elevation: 4,
                borderRadius: BorderRadius.circular(16),
                shadowColor: Colors.black.withOpacity(0.1),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailRiwayatPage(data: item),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Icon Container with gradient
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  const Color(0xFF006D3C),
                                  const Color(0xFF00A855),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF006D3C).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.local_shipping_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Content
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Title
                                Text(
                                  item['nama_sumbersampah'] ?? "Sumber Sampah",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.black87,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                // Date with icon
                                Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today_rounded,
                                      size: 16,
                                      color: Colors.grey.shade600,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      _formatDate(item['tanggal']),
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // Arrow with background
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.history_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "Belum Ada Riwayat",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Riwayat komersil Anda akan muncul di sini",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text("Muat Ulang"),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF006D3C),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF006D3C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF006D3C)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "Memuat riwayat...",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFF006D3C),
        foregroundColor: Colors.white,
        title: const Text(
          "Riwayat Komersil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _refreshData,
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Muat Ulang",
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'images/logo armada.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF006D3C),
        child: isLoading
            ? _buildLoadingState()
            : riwayat.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: riwayat.length,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, index) =>
                        buildRiwayatCard(riwayat[index], index),
                  ),
      ),
    );
  }
}