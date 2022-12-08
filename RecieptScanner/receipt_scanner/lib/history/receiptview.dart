import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:receipt_scanner/history/receiptcard.dart';

import 'itemview.dart';

import 'package:flutter/material.dart';

class ReceiptView extends StatelessWidget {
  final List<ReceiptData> data;

  const ReceiptView(Key? key, this.data) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [for (var item in data) ReceiptCard(data: item)],
    );
  }
}

class ReceiptData {
  final String id;
  final Uri imageURI;
  final String userId;
  late List<ItemData> items;
  final double total;
  final double subtotal;
  final double tax;
  final String purchaseDate;

  ReceiptData(this.id, this.imageURI, this.userId, this.items, this.total,
      this.subtotal, this.tax, this.purchaseDate);

  ReceiptData.fromJson(Map<String, dynamic> json)
      : id = json["id"],
        imageURI = Uri.parse(json["image_url"]),
        userId = json["user"],
        total = json["total_price"],
        subtotal = json["subtotal"],
        tax = json["tax"],
        purchaseDate = json["purchase_date"],
        items = (json["items"] as List<dynamic>)
            .map((e) => ItemData.fromJson(e))
            .toList();
}
