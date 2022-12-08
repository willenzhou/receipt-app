import 'dart:convert';

import 'package:darq/darq.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:receipt_scanner/loadingicon.dart';
import 'package:receipt_scanner/scannerview.dart';
import 'package:url_launcher/url_launcher.dart';

import 'data.dart';
import 'history/itemview.dart';

class TrendView extends StatefulWidget {
  const TrendView({super.key});

  @override
  State<StatefulWidget> createState() => TrendViewState();
}

class TrendViewState extends State<TrendView>
    with AutomaticKeepAliveClientMixin<TrendView> {
  @override
  bool get wantKeepAlive => true;

  TrendData? trendData;
  static TrendViewState? state;
  void processTrendData(Response data) {
    var json = jsonDecode(data.body)[0];
    print(json);
    var items = json["sorted_items"];
    print(items);

    var tempData = TrendData.fromJSON(json);
    setState(() {
      trendData = tempData;
    });
    print("Process");

    print(trendData!.recommendedItems);
  }

  void refresh() {
    print("Refresh");

    fetchTrends().then((data) => processTrendData(data));
  }

  void forceRefresh() {
    if (ScannerView.refreshTrend) {
      ScannerView.refreshTrend = false;
      print("Refresh Trend");
      setState(() {
        trendData = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    state = this;
    if (ScannerView.refreshTrend) {
      setState(() {
        trendData = null;
        ScannerView.refreshTrend = false;
      });
    }

    if (trendData == null) {
      refresh();
      return const Center(child: LoadingIcon(durationInSeconds: 2));
    } else {
      return Column(children: [
        Container(
          padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
          child: Column(children: [
            RichText(
              text: TextSpan(
                  text: 'Stats for ${monthFromMonthNumber(trendData!.month)}',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.black87)),
              textAlign: TextAlign.center,
              textScaleFactor: 1.4,
            ),
            Container(
              height: MediaQuery.of(context).size.height * 0.25,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  color: Colors.grey[400]),
              padding: EdgeInsets.fromLTRB(5, 5, 5, 0),
              child: Column(children: [
                Expanded(
                    child: Padding(
                        padding: EdgeInsets.only(top: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _makeLabelForStat("Receipts Scanned",
                                "${trendData!.receiptsScanned}"),
                            _makeLabelForStat("Money Spent",
                                "\$${trendData!.moneySpent.toStringAsFixed(2)}"),
                          ],
                        ))),
                Expanded(
                    child: Row(children: [
                  _makeLabelForStat("Monthly Scan Growth %",
                      "${trendData!.scanGrowth.toStringAsFixed(2)}\%"),
                  _makeLabelForStat("Monthly Money Growth %",
                      "${trendData!.moneyGrowth.toStringAsFixed(2)}\%"),
                ])),
              ]),
            ),
          ]),
        ),
        Divider(
          height: 20,
          thickness: 1,
          indent: 20,
          endIndent: 20,
          color: Colors.grey,
        ),
        Container(
          alignment: Alignment.bottomCenter,
          padding: EdgeInsets.fromLTRB(0, 20, 0, 20),
          child: Column(children: [
            Container(
              padding: EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: RichText(
                text: const TextSpan(
                    text: 'Recommendations',
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.black87)),
                textAlign: TextAlign.center,
                textScaleFactor: 1.2,
              ),
            ),
            Container(
                padding: EdgeInsets.all(10),
                child: Wrap(
                  runSpacing: 10,
                  spacing: 10,
                  children: [
                    for (var i in trendData!.recommendedItems)
                      Container(
                          height: 40,
                          padding: const EdgeInsetsDirectional.all(10),
                          decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.grey[700]!,
                              ),
                              borderRadius: BorderRadius.circular(60)),
                          child: Container(
                              child: Row(children: [
                            const Icon(Icons.shopping_bag),
                            Expanded(
                              child: InkWell(
                                  child: Text(
                                    i.relatedItem,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                  ),
                                  onTap: () => launchUrl(i.relatedItemLink)),
                            )
                          ])))
                  ],
                )),
          ]),
        ),
      ]);
    }
  }

  String monthFromMonthNumber(int number) {
    var months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[number - 1];
  }

  Widget _makeLabelForStat(String statLabel, String statValue) {
    return Expanded(
        child: Stack(children: [
      Align(
        alignment: Alignment.topCenter,
        child: RichText(
            text: TextSpan(
                text: statLabel,
                style: TextStyle(
                    color: Colors.black54,
                    fontStyle: FontStyle.italic,
                    fontSize: 11))),
      ),
      Align(
          alignment: Alignment.center,
          child: RichText(
              text: TextSpan(
                  text: statValue,
                  style: TextStyle(
                      color: Colors.black,
                      fontStyle: FontStyle.normal,
                      fontSize: 20)))),
    ]));
  }
}

class TrendData {
  final String userId;
  final double moneySpent;
  final int receiptsScanned;
  final double scanGrowth;
  final double moneyGrowth;
  final List<ItemData> recommendedItems;
  final int month;

  TrendData.fromJSON(Map<String, dynamic> json)
      : userId = json["user"],
        moneySpent = json["money_spent"] + .0,
        receiptsScanned = json["receipts_scanned"],
        scanGrowth = json["money_growth"] + .0,
        moneyGrowth = json["scan_growth"] + .0,
        month = json["current_month"],
        recommendedItems = (json["sorted_items"] as List<dynamic>)
            .map((e) => ItemData.fromJson(e))
            .distinct((item) => item.itemName)
            .take(3)
            .toList();
}
