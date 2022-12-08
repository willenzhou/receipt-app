import 'package:flutter/material.dart';
import 'package:receipt_scanner/scannerview.dart';

import 'historyview.dart';
import 'trendview.dart';

class Tabs extends StatelessWidget {
  const Tabs({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.scanner)),
              Tab(icon: Icon(Icons.history)),
              Tab(icon: Icon(Icons.trending_up)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [ScannerView(), HistoryView(), TrendView()],
        ),
      ),
    );
  }
}
