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
  List<int> textures = [];

  @override
  void initState() {
    super.initState();
  }

  void newTexture() async {
    int newTexture = await _channel.invokeMethod('newTexture');
    textures.add(newTexture);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              itemCount: textures.length,
              separatorBuilder: (BuildContext context, int index) {
                return Divider(height: 1, color: Colors.grey,);
              },
              itemBuilder: (BuildContext context, int index) {
                int textureId = textures[index];
                return Container(
                  height: 100,
                  child: Row(
                    children: <Widget>[
                      Text(index.toString()),
                      Container(
                        width: 80,
                        height: 80,
                        // color: Colors.red,
                        child: Texture(textureId: textureId,),
                      ),                      
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            height: 100,
            child: FlatButton(
              child: Text('add texture'),
              onPressed: newTexture,
            ),
          )
        ],
      ),
    );
  }
}
