import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  MethodChannel _channel = MethodChannel('opengl_texture');

  bool hasLoadTexture = false;
  int mainTexture = -1;

  @override
  void initState() {
    super.initState();

    newTexture();
  }

  void newTexture() async {
    mainTexture = await _channel.invokeMethod('newTexture');
    setState(() {
      hasLoadTexture = true;
    });
  }

  Widget getTextureBody(BuildContext context) {
    return Container(
      // color: Colors.red,
      // width: 100,
      // height: 100,
      child: Texture(textureId: mainTexture,),
    );
  }

  @override
  Widget build(BuildContext context) {

    Widget body = hasLoadTexture ? getTextureBody(context) : Text('loading...');

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(child: body,),
    );
  }
}
