import 'dart:convert';

import 'package:darq/darq.dart';
import 'package:flutter/material.dart';
import 'package:receipt_scanner/data.dart';
import 'package:receipt_scanner/history/itemcard.dart';
import 'package:receipt_scanner/history/itemview.dart';
import 'package:receipt_scanner/history/receiptview.dart';
import 'package:receipt_scanner/loadingicon.dart';
import 'package:receipt_scanner/scannerview.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<StatefulWidget> createState() => HistoryViewState();
}

class HistoryViewState extends State<HistoryView>
    with AutomaticKeepAliveClientMixin<HistoryView> {
  @override
  bool get wantKeepAlive => true;

  static HistoryViewState? state;

  void forceRefresh() {
    if (ScannerView.refreshHistory) {
      ScannerView.refreshHistory = false;
      print("Refresh History");
      setState(() {
        receipts = null;
        items = null;
        loadSuccess = false;
      });
    }
  }

  List<ItemAnalyzedData>? items;
  bool loadSuccess = true;
  List<ReceiptData>? receipts;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    state = this;
    if (ScannerView.refreshHistory) {
      ScannerView.refreshHistory = false;
      print("Refresh History");
      setState(() {
        receipts = null;
        items = null;
        loadSuccess = false;
      });
    }

    if (receipts == null) {
      fetchReceiptItems().then((response) {
        if (response.statusCode == 200) {
          List<dynamic> receiptArray = jsonDecode(response.body);

          var tempReceipts = receiptArray
              .map((e) => ReceiptData.fromJson(e))
              .orderByDescending((element) => element.purchaseDate)
              .toList();

          Map<String, List<Pair<ReceiptData, double>>> itemMap = {};
          Map<String, int> itemCountMap = {};

          var test = tempReceipts.map((receipt) {
            var output = receipt.items.map((i) {
              itemMap.putIfAbsent(i.itemName, () => []);
              itemCountMap.putIfAbsent(i.itemName, () => 0);
              itemMap[i.itemName]?.add(Pair(receipt, i.price));
              itemCountMap[i.itemName] = itemCountMap[i.itemName]! + 1;
            }).toList();
          }).toList();

          var tempItems = itemMap.entries
              .map(
                  (e) => ItemAnalyzedData(e.key, itemCountMap[e.key]!, e.value))
              .toList();

          setState(() {
            receipts = tempReceipts;
            items = tempItems;
          });
        } else {
          setState(() {
            loadSuccess = false;
          });
        }
      });
    }

    return receipts == null
        ? const LoadingIcon(key: null, durationInSeconds: 2.0)
        : DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                flexibleSpace: const TabBar(
                  tabs: [
                    Tab(icon: Icon(Icons.receipt)),
                    Tab(icon: Icon(Icons.shopping_cart)),
                  ],
                ),
              ),
              body: TabBarView(
                children: [
                  ReceiptView(null, receipts!),
                  ItemView(null, items!)
                ],
              ),
            ),
          );
  }
}
