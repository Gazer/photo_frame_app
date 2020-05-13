import 'package:flutter/cupertino.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'PhotosClient.dart';

class PhotosProvider extends ChangeNotifier {
  GoogleSignInAccount _currentUser;

  final GoogleSignIn _signIn = GoogleSignIn(scopes: [
    'profile',
    'https://www.googleapis.com/auth/photoslibrary.readonly'
  ]);

  GoogleSignInAccount get user => _currentUser;
  List<Album> get albums => _albums;

  PhotoClient _client;
  List<Album> _albums;

  Map<String, Future<List<Photo>>> _photosFuture = {};

  PhotosProvider() {
    _signIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      _currentUser = account;
      if (_currentUser != null) {
        _updateAlbums();
      }
    });
  }

  bool isLoggedIn() {
    return _currentUser != null;
  }

  void signIn() async {
    _currentUser = await _signIn.signIn();

    if (_currentUser != null) {
      _client = PhotoClient(_currentUser.authHeaders);
      await _updateAlbums();
    } else {
      notifyListeners();
    }
  }

  _updateAlbums() async {
    _albums = await _client.getAlbums();

    notifyListeners();
  }

  Future<List<Photo>> getPhotos(String albumId) {
    if (_photosFuture[albumId] == null) {
      _photosFuture[albumId] = _client.getPhotos(albumId);
    }

    return _photosFuture[albumId];
  }
}