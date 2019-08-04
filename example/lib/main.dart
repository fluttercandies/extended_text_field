import 'package:example/text_demo.dart';
import 'package:example/widget_span.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import 'common/tu_chong_repository.dart';
import 'custom_toolbar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return OKToast(
        child: MaterialApp(
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    ));
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Page> pages = new List<Page>();
  TuChongRepository _listSourceRepository = TuChongRepository();
  @override
  void initState() {
    pages.add(Page(
        PageType.text, "build special text and inline image in text field"));
    pages.add(Page(PageType.toolbar_hanldes,
        "custom selection toolbar and handles for text field"));
    pages.add(Page(PageType.widgetSpan, "mailbox demo with widgetSpan"));

    super.initState();
  }

  @override
  void dispose() {
    _listSourceRepository.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var content = ListView.builder(
      itemBuilder: (_, int index) {
        var page = pages[index];

        Widget pageWidget;
        return Container(
          margin: EdgeInsets.all(20.0),
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  (index + 1).toString() +
                      "." +
                      page.type.toString().replaceAll("PageType.", ""),
                  //style: TextStyle(inherit: false),
                ),
                Text(
                  page.description,
                  style: TextStyle(color: Colors.grey),
                )
              ],
            ),
            onTap: () {
              switch (page.type) {
                case PageType.text:
                  pageWidget = TextDemo(_listSourceRepository);
                  break;
                case PageType.toolbar_hanldes:
                  pageWidget = CustomToolBar();
                  break;
                case PageType.widgetSpan:
                  pageWidget = WidgetSpanDemo();
                  break;
                default:
                  break;
              }
              Navigator.push(context,
                  new MaterialPageRoute(builder: (BuildContext context) {
                return pageWidget;
              }));
            },
          ),
        );
      },
      itemCount: pages.length,
    );

    return Scaffold(
      body: content,
    );
  }
}

class Page {
  final PageType type;
  final String description;
  Page(this.type, this.description);
}

enum PageType { text, toolbar_hanldes, widgetSpan }
