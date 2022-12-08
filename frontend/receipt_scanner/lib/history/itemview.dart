import 'package:flutter/material.dart';

import 'itemcard.dart';

class ItemView extends StatelessWidget {
  final List<ItemAnalyzedData> data;

  const ItemView(Key? key, this.data) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [for (var item in data) ItemCard(data: item)],
    );
  }
}

class ItemData {
  final String itemName;
  final double price;
  final String relatedItem;
  final Uri relatedItemLink;

  ItemData(this.itemName, this.price, this.relatedItem, this.relatedItemLink);

  ItemData.fromJson(Map<String, dynamic> json)
      : itemName = json["product_name"],
        price = json["product_price"],
        relatedItem = json["related_product"],
        relatedItemLink = Uri.parse(json["related_product_link"]);
}
