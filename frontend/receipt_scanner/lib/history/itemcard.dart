import 'package:charts_flutter/flutter.dart' as charts;
import 'package:darq/darq.dart';
import 'package:flutter/material.dart';
import 'package:receipt_scanner/history/receiptview.dart';
import 'package:intl/intl.dart';

class ItemCard extends StatefulWidget {
  final ItemAnalyzedData data;

  const ItemCard({super.key, required this.data});
  @override
  State<StatefulWidget> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    Widget body = expanded ? expandedWiget(context) : collapsedWidget(context);

    return GestureDetector(
      onTap: () => setState(() {
        expanded = !expanded;
      }),
      child: body,
    );
  }

  Widget collapsedWidget(BuildContext context) {
    return Card(
        margin: const EdgeInsets.all(5),
        child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RichText(
                    text: TextSpan(
                        text: widget.data.item,
                        style: const TextStyle(
                            fontWeight: FontWeight.normal,
                            color: Colors.black)),
                  ),
                  const Icon(Icons.arrow_drop_down_outlined)
                ])));
  }

  Widget expandedWiget(BuildContext context) {
    List<charts.Series<TimeSeriesSales, DateTime>> seriesList =
        _createSampleData(widget.data);
    return Card(
        margin: const EdgeInsets.all(5),
        child: Padding(
            padding: const EdgeInsets.all(3),
            child: Column(
              children: [
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                            text: widget.data.item,
                            style: const TextStyle(
                                fontWeight: FontWeight.normal,
                                color: Colors.black)),
                      ),
                      const Icon(Icons.arrow_drop_up_outlined)
                    ]),
                const Divider(
                  height: 3,
                  thickness: 1,
                  indent: 5,
                  endIndent: 5,
                ),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                            text: "Purchase Count",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w800)),
                      ),
                      RichText(
                          text: TextSpan(
                              text: "${widget.data.totalPurchases}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800))),
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                            text: "Min. Cost",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w800)),
                      ),
                      RichText(
                          text: TextSpan(
                              text:
                                  "${widget.data.purchasePoints.min(((e1, e2) => e1.b.compareTo(e2.b))).b.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800))),
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                            text: "Max. Cost",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w800)),
                      ),
                      RichText(
                          text: TextSpan(
                              text:
                                  "${widget.data.purchasePoints.max(((e1, e2) => e1.b.compareTo(e2.b))).b.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800))),
                    ]),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RichText(
                        text: TextSpan(
                            text: "Avg. Cost",
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w800)),
                      ),
                      RichText(
                          text: TextSpan(
                              text:
                                  "${widget.data.purchasePoints.map((e) => e.b).average().toStringAsFixed(2)}",
                              style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black,
                                  fontWeight: FontWeight.w800))),
                    ]),
                widget.data.purchasePoints
                            .distinct((i) => i.a.purchaseDate)
                            .length <=
                        1
                    ? Container()
                    : Container(
                        height: 160,
                        child: charts.TimeSeriesChart(
                          seriesList,
                          animate: false,
                        ))
              ],
            )));
  }

  /// Create one series with sample hard coded data.
  static List<charts.Series<TimeSeriesSales, DateTime>> _createSampleData(
      ItemAnalyzedData itemData) {
    final data = [
      for (var item in itemData.purchasePoints.map((e) {
        var parts = e.a.purchaseDate.split('-');
        print(DateTime(
            int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])));
        return Pair(
            DateTime(
                int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2])),
            e.b);
      }))
        TimeSeriesSales(item.a, item.b)
    ];

    return [
      charts.Series<TimeSeriesSales, DateTime>(
        id: 'Purchases',
        colorFn: (_, __) => charts.MaterialPalette.blue.shadeDefault,
        domainFn: (TimeSeriesSales sales, _) => sales.time,
        measureFn: (TimeSeriesSales sales, _) => sales.sales,
        data: data,
      )
    ];
  }
}

class TimeSeriesSales {
  final DateTime time;
  final double sales;

  TimeSeriesSales(this.time, this.sales);
}

class Pair<T1, T2> {
  final T1 a;
  final T2 b;

  Pair(this.a, this.b);
}

class ItemAnalyzedData {
  final String item;
  final int totalPurchases;
  final List<Pair<ReceiptData, double>> purchasePoints;

  ItemAnalyzedData(this.item, this.totalPurchases, this.purchasePoints);
}
