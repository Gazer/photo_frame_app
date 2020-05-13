import 'dart:convert';

import 'package:http/http.dart' as http;
import 'dart:async';

class Album {
  final String id;
  final String title;
  final String coverPhotoBaseUrl;

  Album(this.id, this.title, this.coverPhotoBaseUrl);

  factory Album.fromJson(Map<String, dynamic> json) {
    return Album(
      json["id"],
      json["title"],
      json["coverPhotoBaseUrl"],
    );
  }
}

class Photo {
  final String baseUrl;

  Photo(this.baseUrl);

  factory Photo.fromJson(Map<String, dynamic> json) {
    return Photo(json["baseUrl"]);
  }
}

class PhotoClient {
  final Future<Map<String, String>> authHeaders;

  PhotoClient(this.authHeaders);

  Future<List<Album>> getAlbums() async {
    var response = await http.get(
        "https://photoslibrary.googleapis.com/v1/albums?pageSize=50",
      headers: await authHeaders,
    );

    if (response.statusCode != 200) {
      print(response.body);
      return [];
    }

    var json = jsonDecode(response.body);
    var albums = json["albums"] as Iterable;

    return albums.map((data) => Album.fromJson(data)).toList();
  }

  Future<List<Photo>> getPhotos(String albumId) async {
    var response = await http.post(
      "https://photoslibrary.googleapis.com/v1/mediaItems:search",
      headers: await authHeaders,
      body: jsonEncode({
        "pageSize": "100",
        "albumId": albumId,
      })
    );
    if (response.statusCode != 200) {
      print(response.body);
      return [];
    }

    var json = jsonDecode(response.body);
    var mediaItems = (json["mediaItems"] as Iterable);

    return mediaItems.map((json) => Photo.fromJson(json)).toList();
  }
}