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
  List<dynamic> filteredRiwayat = [];
  bool isLoading = true;
  bool isFilterVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Filter variables
  DateTime? selectedDate;
  int? selectedMonth;
  int? selectedYear;
  List<int> availableYears = [];
  
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

  void _extractAvailableYears() {
    Set<int> years = {};
    for (var item in riwayat) {
      try {
        DateTime date = DateTime.parse(item['tanggal']);
        years.add(date.year);
      } catch (e) {
        // Skip invalid dates
      }
    }
    availableYears = years.toList()..sort((a, b) => b.compareTo(a));
  }

  void _applyFilters() {
    List<dynamic> filtered = List.from(riwayat);
    
    if (selectedYear != null || selectedMonth != null || selectedDate != null) {
      filtered = filtered.where((item) {
        try {
          DateTime date = DateTime.parse(item['tanggal']);
          
          if (selectedYear != null && date.year != selectedYear) {
            return false;
          }
          
          if (selectedMonth != null && date.month != selectedMonth) {
            return false;
          }
          
          if (selectedDate != null) {
            DateTime filterDate = DateTime(selectedDate!.year, selectedDate!.month, selectedDate!.day);
            DateTime itemDate = DateTime(date.year, date.month, date.day);
            if (!itemDate.isAtSameMomentAs(filterDate)) {
              return false;
            }
          }
          
          return true;
        } catch (e) {
          return false;
        }
      }).toList();
    }
    
    setState(() {
      filteredRiwayat = filtered;
    });
  }

  void _clearFilters() {
    setState(() {
      selectedDate = null;
      selectedMonth = null;
      selectedYear = null;
      filteredRiwayat = List.from(riwayat);
    });
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
        "http://192.168.43.116:3000/api/riwayat/$idArmada/$statusArmada";

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
          filteredRiwayat = List.from(rawData);
          isLoading = false;
        });
        
        _extractAvailableYears();
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

  Widget _buildFilterSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isFilterVisible ? null : 0,
      child: isFilterVisible
          ? Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: const Color(0xFF006D3C),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        "Filter Riwayat",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _clearFilters,
                        child: const Text(
                          "Reset",
                          style: TextStyle(
                            color: Color(0xFF006D3C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Year Filter
                  Text(
                    "Tahun",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedYear,
                        hint: const Text("Pilih Tahun"),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text("Semua Tahun"),
                          ),
                          ...availableYears.map((year) {
                            return DropdownMenuItem<int>(
                              value: year,
                              child: Text(year.toString()),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedYear = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Month Filter
                  Text(
                    "Bulan",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: selectedMonth,
                        hint: const Text("Pilih Bulan"),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                        items: [
                          const DropdownMenuItem<int>(
                            value: null,
                            child: Text("Semua Bulan"),
                          ),
                          ...List.generate(12, (index) {
                            List<String> monthNames = [
                              'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
                              'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
                            ];
                            return DropdownMenuItem<int>(
                              value: index + 1,
                              child: Text(monthNames[index]),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedMonth = value;
                          });
                          _applyFilters();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Date Filter
                  Text(
                    "Tanggal",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: Color(0xFF006D3C),
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: Colors.black,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (picked != null) {
                        setState(() {
                          selectedDate = picked;
                        });
                        _applyFilters();
                      }
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null 
                                ? _formatDate(selectedDate!.toIso8601String().split('T')[0])
                                : "Pilih Tanggal",
                            style: TextStyle(
                              color: selectedDate != null 
                                  ? Colors.black87 
                                  : Colors.grey.shade600,
                            ),
                          ),
                          Icon(
                            Icons.calendar_today_rounded,
                            color: Colors.grey.shade600,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFilterChips() {
    List<Widget> chips = [];
    
    if (selectedYear != null) {
      chips.add(_buildFilterChip("Tahun: $selectedYear", () {
        setState(() {
          selectedYear = null;
        });
        _applyFilters();
      }));
    }
    
    if (selectedMonth != null) {
      List<String> monthNames = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      chips.add(_buildFilterChip("Bulan: ${monthNames[selectedMonth! - 1]}", () {
        setState(() {
          selectedMonth = null;
        });
        _applyFilters();
      }));
    }
    
    if (selectedDate != null) {
      chips.add(_buildFilterChip("Tanggal: ${_formatDate(selectedDate!.toIso8601String().split('T')[0])}", () {
        setState(() {
          selectedDate = null;
        });
        _applyFilters();
      }));
    }
    
    if (chips.isEmpty) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: chips,
      ),
    );
  }

  Widget _buildFilterChip(String label, VoidCallback onRemove) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF006D3C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF006D3C).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF006D3C),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFF006D3C),
            ),
          ),
        ],
      ),
    );
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
                top: index == 0 ? 8 : 8,
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
  bool hasActiveFilters = selectedDate != null || selectedMonth != null || selectedYear != null;
  
  return SingleChildScrollView(
    padding: const EdgeInsets.all(20),
    physics: const AlwaysScrollableScrollPhysics(),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min, // Penting untuk hindari overflow
        children: [
          // Illustration
          Container(
            width: MediaQuery.of(context).size.width * 0.4, // Responsive width
            height: MediaQuery.of(context).size.width * 0.4,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(60),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              hasActiveFilters ? Icons.search_off_rounded : Icons.history_rounded,
              size: 40, // Ukuran lebih reasonable
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 20),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              hasActiveFilters ? "Data Tidak Ditemukan" : "Belum Ada Riwayat",
              style: TextStyle(
                fontSize: 18, // Ukuran font disesuaikan
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              hasActiveFilters
                  ? "Tidak ada riwayat yang sesuai dengan filter yang dipilih"
                  : "Riwayat komersil Anda akan muncul di sini",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          
          // Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: SizedBox(
              width: double.infinity, // Button full width
              child: ElevatedButton.icon(
                onPressed: hasActiveFilters ? _clearFilters : _refreshData,
                icon: Icon(hasActiveFilters ? Icons.clear_all_rounded : Icons.refresh_rounded),
                label: Text(hasActiveFilters ? "Hapus Filter" : "Muat Ulang"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D3C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
        automaticallyImplyLeading: false,
        title: const Text(
          "Riwayat Komersil",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                isFilterVisible = !isFilterVisible;
              });
            },
            icon: Icon(
              isFilterVisible ? Icons.filter_list_off_rounded : Icons.filter_list_rounded,
            ),
            tooltip: "Filter",
          ),
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
        child: Column(
          children: [
            _buildFilterSection(),
            _buildFilterChips(),
            Expanded(
              child: isLoading
                  ? _buildLoadingState()
                  : filteredRiwayat.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          itemCount: filteredRiwayat.length,
                          padding: const EdgeInsets.only(bottom: 16),
                          itemBuilder: (context, index) =>
                              buildRiwayatCard(filteredRiwayat[index], index),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}