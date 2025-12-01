import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

class CrimeReportPage extends StatefulWidget {
  const CrimeReportPage({super.key});

  @override
  State<CrimeReportPage> createState() => _CrimeReportPageState();
}

class _CrimeReportPageState extends State<CrimeReportPage> {
  Map<String, dynamic>? data;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCrimeData();
  }

  Future<void> fetchCrimeData() async {
    try {
      final response = await http.get(
        Uri.parse("https://faiyaz6969.pythonanywhere.com/crime_data"),
      );
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        setState(() {
          data = jsonData;
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load crime data");
      }
    } catch (e) {
      print("Error fetching data: $e");
      setState(() {
        isLoading = false;
        data = {};
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  floating: true,
                  pinned: true,
                  expandedHeight: 160,
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: const Center(
                        child: Text(
                          "Crime Report",
                          style: TextStyle(
                            fontSize: 28,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black45,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SectionTitle("Crime Trends"),
                        SizedBox(
                          height: 220,
                          child: buildBarChart(
                            (data!['crime_counts'] as Map<String, dynamic>)
                                .entries
                                .map((e) => ChartData(e.key, e.value as int))
                                .toList(),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionTitle("Area with highest crime"),
                        SizedBox(
                          height: 220,
                          child: buildBarChart(
                            (data!['area_counts'] as Map<String, dynamic>)
                                .entries
                                .map((e) => ChartData(e.key, e.value as int))
                                .toList()
                              ..sort((a, b) => b.value.compareTo(a.value))
                              ..removeRange(5, (data!['area_counts'] as Map<String, dynamic>).length),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const SectionTitle("Reports Table"),
                        DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.white10),
                          columns: const [
                            DataColumn(
                              label: Text("Metric",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            DataColumn(
                              label: Text("Count",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                          rows: [
                            DataRow(cells: [
                              const DataCell(Text("Total Reports",
                                  style: TextStyle(color: Colors.white))),
                              DataCell(Text("${data!['total_reports']}",
                                  style: const TextStyle(color: Colors.white))),
                            ]),
                            DataRow(cells: [
                              const DataCell(Text("Last Hour Reports",
                                  style: TextStyle(color: Colors.white))),
                              DataCell(Text("${data!['hourly_counts'].values.first}",
                                  style: const TextStyle(color: Colors.white))),
                            ]),
                          ],
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

 BarChart buildBarChart(List<ChartData> chartData) {
  final colors = [
    Colors.cyanAccent,
    Colors.pinkAccent,
    Colors.orangeAccent,
    Colors.lightGreenAccent,
    Colors.purpleAccent,
    Colors.yellowAccent,
    Colors.tealAccent,
    Colors.redAccent,
    Colors.blueAccent,
    Colors.limeAccent,
  ];

  return BarChart(
    BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: chartData.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble() * 1.2,
      barGroups: chartData.asMap().entries.map((entry) {
        int index = entry.key;
        final data = entry.value;
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: data.value.toDouble(),
              color: colors[index % colors.length], // cycle through colors
              width: 14,
              borderRadius: BorderRadius.circular(6),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: 0,
                color: Colors.white12,
              ),
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= chartData.length) return Container();
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: RotatedBox(
                  quarterTurns: 0,
                  child: Text(
                    chartData[index].label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              );
            },
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.white12,
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: false),
    ),
  );
}

}

class ChartData {
  final String label;
  final int value;
  ChartData(this.label, this.value);
}

class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          shadows: [Shadow(color: Colors.black45, blurRadius: 2, offset: Offset(1, 1))],
        ),
      ),
    );
  }
}
