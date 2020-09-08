import 'package:flutter/material.dart';
import 'package:flutter_svg_clickable/svg_parser/parser.dart';
import 'package:touchable/touchable.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

//! Make sure fill the current svg's viewBox(width and height)
// TODO: fix svg parser to automatic get the viewBox
const double SvgWidth = 1369; //1369; //612.54211;
const double SvgHeight = 1141; //1141; //723.61865;

class _MyHomePageState extends State<MyHomePage> {
  Path _selectPath;
  final svgPath = "assets/map_china.svg";
  List<Path> paths = [];

  @override
  void initState() {
    parseSvgToPath();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("svg clickable china map ")),
      body: Center(
        child: Container(
          color: Colors.grey,  // just make a difference
          width: double.infinity, // full screen here, you can change size to see different effect
          height: double.infinity,
          child: CanvasTouchDetector( // see: https://pub.dev/packages/touchable
            builder: (context) => CustomPaint(
              painter: PathPainter(
                context: context,
                paths: paths,
                curPath: _selectPath,
                onPressed: (curPath) {
                  setState(() {
                    _selectPath = curPath;
                  });
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void parseSvgToPath() {
    SvgParser parser = SvgParser();
    parser.loadFromFile(svgPath).then((value) {
      setState(() {
        paths = parser.getPaths();
      });
    });
  }
}

class PathPainter extends CustomPainter {
  final BuildContext context;
  final List<Path> paths;
  final Path curPath;
  final Function(Path curPath) onPressed;
  PathPainter({this.context, this.paths, this.curPath, this.onPressed});

  @override
  void paint(Canvas canvas, Size size) {

    // calculate the scale factor, use the min value
    final double xScale = size.width / SvgWidth;
    final double yScale = size.height / SvgHeight;
    final double scale = xScale < yScale ? xScale : yScale;

    // scale each path to match canvas size
    final Matrix4 matrix4 = Matrix4.identity();
    matrix4.scale(scale, scale);

    // calculate the scaled svg image width and height in order to get right offset
    double scaledSvgWidth = SvgWidth * scale;
    double scaledSvgHeight = SvgHeight * scale;
    // calculate offset to center the svg image
    double offsetX = (size.width - scaledSvgWidth) / 2;
    double offsetY = (size.height - scaledSvgHeight) / 2;

    // make canvas clickable, see: https://pub.dev/packages/touchable
    final TouchyCanvas touchCanvas = TouchyCanvas(context, canvas);
    // your paint
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.red
      ..strokeWidth = 1.0;

    paths.forEach(
      (path) {
        // Here: archive our target, select one province, just change the paint's style to fill
        paint.style = path == curPath ? PaintingStyle.fill : PaintingStyle.stroke;

        touchCanvas.drawPath(
          // scale and offset each path to match the canvas
          path.transform(matrix4.storage).shift(Offset(offsetX, offsetY)),
          paint,
          onTapDown: (details) {
            // notify select change and redraw
            onPressed(path); 
          },
        );
      },
    );
  }

  @override
  bool shouldRepaint(PathPainter oldDelegate) => true;
}
