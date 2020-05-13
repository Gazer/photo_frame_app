import 'dart:async';

import 'package:flutter/material.dart';
import 'package:photo_frame_app/PhotosProvider.dart';
import 'package:provider/provider.dart';

import 'PhotosClient.dart';

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
      home: ChangeNotifierProvider(
        create: (_) => PhotosProvider(),
        child: LoginPage(),
      ),
    );
  }
}

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<PhotosProvider>(
        builder: (context, state, child) {
          if (!state.isLoggedIn()) {
            return Center(
              child: RaisedButton(
                child: Text("Sign In with Google"),
                onPressed: () {
                  state.signIn();
                },
              ),
            );
          } else {
            return _albumList(state);
          }
        },
      ),
    );
  }

  Widget _albumList(PhotosProvider state) {
    return SafeArea(
      child: ListView.builder(
        itemCount: state.albums.length,
        itemBuilder: (context, idx) {
          return ListTile(
            title: Text(state.albums[idx].title),
            leading: Image.network(
              "${state.albums[idx].coverPhotoBaseUrl}=w50-h50-c",
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => ChangeNotifierProvider.value(
                  value: state,
                  child: PhotosPage(id: state.albums[idx].id),
                ),
              ));
            },
          );
        },
      ),
    );
  }
}

class PhotosPage extends StatefulWidget {
  final String id;

  const PhotosPage({Key key, this.id}) : super(key: key);

  @override
  _PhotosPageState createState() => _PhotosPageState();
}

class _PhotosPageState extends State<PhotosPage> {
  PageController _pageController;
  Timer _timer;
  int totalPages = 0;
  double currentPage = 0;

  @override
  void initState() {
    super.initState();

    _pageController = PageController(
      viewportFraction: 0.6,
    );
    _pageController.addListener(() {
      setState(() {
        currentPage = _pageController.page;
      });
    });

    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.page.round() < totalPages - 1) {
        _pageController.nextPage(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInSine,
        );
      } else {
        _pageController.animateToPage(
          0,
          duration: Duration(milliseconds: 1500),
          curve: Curves.easeInSine,
        );
      }
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
    if (_timer != null) {
      _timer.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
    var state = Provider.of<PhotosProvider>(context);

    return FutureBuilder(
      future: state.getPhotos(widget.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return SafeArea(
            child: _buildPhotoFrame(snapshot.data),
          );
        }

        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }

  Widget _buildPhotoFrame(List<Photo> data) {
    totalPages = data.length;
    return PageView.builder(
      controller: _pageController,
      itemCount: data.length,
      itemBuilder: (context, idx) {
        return PhotoWidget(
          url: data[idx].baseUrl,
//          idx: idx,
//          currentPage: currentPage,
//          color: Colors.accents[0],
        );
      },
    );
  }
}

class PhotoWidget extends StatelessWidget {
  final String url;

  const PhotoWidget({Key key, this.url}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      margin: EdgeInsets.all(8),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25.0),
        image: DecorationImage(
          image: NetworkImage(url),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class AlbumCard extends StatelessWidget {
  final Color color;
  final int idx;
  final double currentPage;
  final String url;

  AlbumCard({this.url, this.color, this.idx, this.currentPage});

  @override
  Widget build(BuildContext context) {
    double relativePosition = idx - currentPage;

    return Container(
      width: 250,
      child: Transform(
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.003) // add perspective
          ..scale((1 - relativePosition.abs()).clamp(0.2, 0.6) + 0.4)
          ..rotateY(relativePosition),
        // ..rotateZ(relativePosition),
        alignment: relativePosition >= 0
            ? Alignment.centerLeft
            : Alignment.centerRight,
        child: Container(
          margin: EdgeInsets.only(top: 20, bottom: 20, left: 5, right: 5),
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color,
            image: DecorationImage(
              fit: BoxFit.cover,
              image: NetworkImage(url),
            ),
          ),
        ),
      ),
    );
  }
}
