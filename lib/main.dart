import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  //image par default si pas de poster ou image indisponible
  static const String defaultIMG = 'https://lh3.googleusercontent.com/drive-viewer/AK7aPaC9hrzeILF5_7Jyf-EUDKM63cgz9KD4PgCnYHeFKiCtwsnabrwhfINsWnTYw22hdRjTN7QXlvBVRaVkfUEIfsO8R7rO=w1920-h893';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = TextEditingController();
  List<Film> _films = [];
  bool _loading = false;

  Future<void> _fetchData(String query) async {
    setState(() {
      _loading = true;
      _films.clear();
    });

    final response = await http.get(Uri.parse('https://www.omdbapi.com/?s=$query&apikey=8a95ed30'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      if (data.containsKey('Search')) {
        setState(() {
          _films = List<Film>.from(data['Search'].map((film) => Film.fromJson(film)));
        });
      }
    }

    setState(() {
      _loading = false;
    });
  }
//Matérialistion de la page principale :
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Filmographia'),
      ),
      backgroundColor: const Color(0xFF263238),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Rechercher',
                labelStyle: TextStyle(color: Colors.white),
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  color: Colors.white,
                  onPressed: () {
                    _fetchData(_controller.text);
                  },
                ),
              ),
              onSubmitted: (value) {
                _fetchData(value);
              },
            ),
          ),
          _loading
              ? CircularProgressIndicator()
              : _films.isEmpty
              ? (_controller.text.isNotEmpty
              ? Center(
            child: Text(
              'Aucun film trouvé',
              style: TextStyle(color: Colors.white),
            ),
          )
              : Container())
              : Expanded(
            child: ListView.builder(
              itemCount: _films.length,
              itemBuilder: (context, index) {
                return FilmItem(
                  film: _films[index],
                  onTap: () {
                    _navigateToDetailsPage(_films[index].imdbID);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToDetailsPage(String imdbID) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PageDuFilm(imdbID: imdbID),
      ),
    );
  }
}

class Film {
  final String title;
  final String poster;
  final String imdbID;

  Film({required this.title, required this.poster, required this.imdbID});

  factory Film.fromJson(Map<String, dynamic> json) {
    return Film(
      title: json['Title'],
      poster: json['Poster'],
      imdbID: json['imdbID'],
    );
  }
}

class FilmItem extends StatelessWidget {
  final Film film;
  final VoidCallback onTap;

  FilmItem({required this.film, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border.all(color: Colors.black),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAfficheDuFilm(),
            SizedBox(height: 8),
            Text(
              film.title,
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAfficheDuFilm() {
    return Image.network(
      film.poster,
      height: 150,
      width: 100,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        //si il y a une erreur on affiche l'image par défaut
        return Image.network(
          MyApp.defaultIMG,
          height: 150,
          width: 100,
          fit: BoxFit.cover,
        );
      },
    );
  }
}


class PageDuFilm extends StatefulWidget {
  final String imdbID;

  PageDuFilm({required this.imdbID});

  @override
  _PageDuFilmState createState() => _PageDuFilmState();
}

class _PageDuFilmState extends State<PageDuFilm> {
  late DetailsFilm _detailsFilm;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final response =
    await http.get(Uri.parse('https://www.omdbapi.com/?i=${widget.imdbID}&apikey=8a95ed30'));
    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      setState(() {
        _detailsFilm = DetailsFilm.fromJson(data);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text('Filmographia'),
      ),
      backgroundColor: const Color(0xFF263238),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 16),
          Text(
            _detailsFilm.title,
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.yellow),
          ),
          SizedBox(height: 8),
          Text(
            _detailsFilm.year,
            style: TextStyle(fontSize: 24, color: Colors.white),
          ),
          _buildAfficheDuFilm(),
          SizedBox(height: 8),
          Text(
            _detailsFilm.plot,
            style: TextStyle(fontSize: 15, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(
            _detailsFilm.actors,
            style: TextStyle(fontSize: 15, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildAfficheDuFilm() {
    return Image.network(
      _detailsFilm.poster,
      height: 300,
      width: 200,
      fit: BoxFit.cover,
      errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
        // Gestionnaire d'erreur : afficher l'image par défaut en cas d'erreur
        return Image.network(
          MyApp.defaultIMG,
          height: 300,
          width: 200,
          fit: BoxFit.cover,
        );
      },
    );
  }
}


class DetailsFilm {
  final String title;
  final String poster;
  final String year;
  final String actors;
  final String plot;

  DetailsFilm({
    required this.title,
    required this.poster,
    required this.year,
    required this.actors,
    required this.plot,
  });

  factory DetailsFilm.fromJson(Map<String, dynamic> json) {
    return DetailsFilm(
      title: json['Title'],
      poster: json['Poster'],
      year: json['Year'],
      actors: json['Actors'],
      plot: json['Plot'],
    );
  }
}