import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'receiptview.dart';

class ReceiptCard extends StatefulWidget {
  final ReceiptData data;
  final bool defaultExpanded;

  const ReceiptCard(
      {super.key, required this.data, this.defaultExpanded = false});

  @override
  State<StatefulWidget> createState() => _ReceiptCardState();
}

class _ReceiptCardState extends State<ReceiptCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        child: (expanded || widget.defaultExpanded)
            ? expandedWidget(context)
            : collapsedWidget(context),
        onTap: () => setState(() {
              expanded = !expanded;
            }));
  }

  Widget collapsedWidget(BuildContext context) {
    var imageSize = MediaQuery.of(context).size.width / 5;
    return Card(
        margin: const EdgeInsets.all(5),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Padding(
              padding: const EdgeInsets.all(3),
              child: Container(
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 1,
                  ),
                ),
                child: CachedNetworkImage(
                    width: imageSize,
                    height: imageSize,
                    fit: BoxFit.contain,
                    imageUrl: widget.data.imageURI.toString()),
              )),
          RichText(
            text: TextSpan(
                text: "${widget.data.purchaseDate}",
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Colors.black)),
          ),
          const Icon(Icons.arrow_drop_down_outlined)
        ]));
  }

  Widget expandedWidget(BuildContext context) {
    var imageSize = MediaQuery.of(context).size.width / 5;

    Widget header =
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Padding(
          padding: const EdgeInsets.all(3),
          child: Container(
            width: imageSize,
            height: imageSize,
            decoration: BoxDecoration(
              border: Border.all(
                width: 1,
              ),
            ),
            child: CachedNetworkImage(
                width: imageSize,
                height: imageSize,
                fit: BoxFit.contain,
                imageUrl: widget.data.imageURI.toString()),
          )),
      RichText(
        text: TextSpan(
            text: "${widget.data.purchaseDate}",
            style: const TextStyle(
                fontWeight: FontWeight.w600, color: Colors.black)),
      ),
      const Icon(Icons.arrow_drop_up_outlined)
    ]);
    return Card(
        margin: const EdgeInsets.all(5),
        child: Column(children: [
          Wrap(children: [
            header,
            const Divider(
              height: 1,
              thickness: 1,
              indent: 5,
              endIndent: 5,
              color: Colors.grey,
            )
          ]),
          Padding(
              padding: const EdgeInsets.all(5),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                          text: "Items",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600)),
                    ),
                    RichText(
                      text: TextSpan(
                          text: "Price",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 5,
                  endIndent: 5,
                  color: Colors.grey,
                ),
                for (var item in widget.data.items)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("${item.itemName}"),
                      Text("\$${item.price.toStringAsFixed(2)}")
                    ],
                  ),
                const Divider(
                  height: 1,
                  thickness: 1,
                  indent: 5,
                  endIndent: 5,
                  color: Colors.grey,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                          text: "Subtotal",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600)),
                    ),
                    RichText(
                      text: TextSpan(
                          text: "\$ ${widget.data.subtotal.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.normal)),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                          text: "Tax",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w600)),
                    ),
                    RichText(
                      text: TextSpan(
                          text: "\$ ${widget.data.tax.toStringAsFixed(2)}",
                          style: const TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.normal)),
                    )
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                          text: "Total",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w800)),
                    ),
                    RichText(
                      text: TextSpan(
                          text: "\$ ${widget.data.total.toStringAsFixed(2)}",
                          style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                              fontWeight: FontWeight.w800)),
                    )
                  ],
                )
              ]))
        ]));
  }
}
