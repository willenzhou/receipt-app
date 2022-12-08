import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:receipt_scanner/history/receiptcard.dart';
import 'package:receipt_scanner/history/receiptview.dart';
import 'package:receipt_scanner/historyview.dart';
import 'package:receipt_scanner/loadingicon.dart';
import 'package:receipt_scanner/trendview.dart';

import 'data.dart';

class ScannerView extends StatefulWidget {
  const ScannerView({Key? key}) : super(key: key);
  static bool refreshHistory = false;
  static bool refreshTrend = false;

  @override
  State<ScannerView> createState() => _ScannerViewState();
}

class _ScannerViewState extends State<ScannerView>
    with AutomaticKeepAliveClientMixin<ScannerView> {
  @override
  bool get wantKeepAlive => true;
  ScanStatus scanStatus = ScanStatus.Picking;
  ReceiptData? data;
  File? image;

  Future pickImage() async {
    try {
      final image = await ImagePicker().pickImage(source: ImageSource.gallery);

      if (image == null) return;
      setState(() {
        scanStatus = ScanStatus.Uploading;
      });
      print("Uploading");

      final imageTemp = File(image.path);
      setState(() => {this.image = imageTemp});
      postReceipt(imageTemp.uri).then((result) async {
        http.Response.fromStream(result).then((response) async {
          if (response.statusCode == 200) {
            print("Uploaded! ");
            print('response.body ${response.body}');

            var tempData = ReceiptData.fromJson(jsonDecode(response.body)[0]);

            setState(() {
              data = tempData;
              print("Complete");
              scanStatus = ScanStatus.Displaying;
              ScannerView.refreshHistory = true;
              ScannerView.refreshTrend = true;

              HistoryViewState.state?.forceRefresh();
              TrendViewState.state?.forceRefresh();
            });
          } else {
            print("Failed : ${response.statusCode}");
            print('response.body ${response.body}');
          }

          return response.body;
        });
      });
    } on PlatformException catch (e) {
      print('Failed to pick image');
      setState(() {
        scanStatus = ScanStatus.Picking;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget? body = null;

    switch (scanStatus) {
      case ScanStatus.Picking:
        body = MaterialButton(
            color: Colors.blue,
            child: const Text("Upload Receipt",
                style: TextStyle(
                    color: Colors.white70, fontWeight: FontWeight.bold)),
            onPressed: () {
              pickImage();
            });
        break;
      case ScanStatus.Uploading:
        body = LoadingIcon(durationInSeconds: 2);
        break;
      case ScanStatus.Displaying:
        // TODO: Handle this case.
        body = WillPopScope(
            onWillPop: () {
              print(
                  'Backbutton pressed (device or appbar button), do whatever you want.');

              //trigger leaving and use own data
              setState(() {
                scanStatus = ScanStatus.Picking;
                data = null;
                image = null;
              });
              //we need to return a future
              return Future.value(false);
            },
            child: Center(
                child: ReceiptCard(
              data: data!,
              defaultExpanded: true,
            )));

        break;
    }
    return Scaffold(
      body: Center(
        child: body,
      ),
    );
  }
}

enum ScanStatus { Picking, Uploading, Displaying }
