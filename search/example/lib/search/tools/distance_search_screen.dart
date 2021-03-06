import 'package:amap_base_core/amap_base_core.dart';
import 'package:amap_base_search/amap_base_search.dart';
import 'package:decorated_flutter/decorated_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

const beijing = LatLng(39.90960, 116.397228);
const shanghai = LatLng(31.22, 121.48);
const guangzhou = LatLng(23.16, 113.23);

class DistanceSearchScreen extends StatefulWidget {
  @override
  _DistanceSearchScreenState createState() => _DistanceSearchScreenState();
}

class _DistanceSearchScreenState extends State<DistanceSearchScreen> {
  LatLng src1 = beijing;
  LatLng src2 = shanghai;
  LatLng target = guangzhou;

  String text = "";

  @override
  void initState() {
    super.initState();
    AMapSearch().distanceSearch(
      [src1, src2],
      target,
      DistanceSearchType.driver,
    ).then((distanceList) {
      text = "北京到广州的距离${distanceList[0]}\n"
          "上海到广州的距离${distanceList[1]}";
      setState(() {});
    }, onError: (e) {
      if (e is PlatformException) {
        // L.p("发生错误,错误原因${e.code}");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('距离测量'),
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Text(text),
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      ),
    );
  }
}
