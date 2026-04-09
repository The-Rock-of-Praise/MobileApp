import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final baseUrl = 'https://therockofpraise.org/api';
  
  print('Fetching worship artists...');
  var res = await http.get(Uri.parse('$baseUrl/worship-artists'));
  print('Agents /worship-artists: ${res.statusCode}');
  
  if (res.statusCode == 200) {
    final data = json.decode(res.body);
    final artists = data['data'] ?? [];
    if (artists.isNotEmpty) {
      final firstArtist = artists[0];
      final artistId = firstArtist['id'];
      print('First artist ID: $artistId (${firstArtist['name']})');
      
      print('Fetching songs for artist $artistId ...');
      var songsRes = await http.get(Uri.parse('$baseUrl/worship-artists/$artistId/songs'));
      print('Songs status: ${songsRes.statusCode}');
      print('Songs body: ${songsRes.body}');
    }
  }
}
