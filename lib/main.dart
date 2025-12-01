import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(PokemonApp());
}

class PokemonApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pokémon y APIs públicas',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Pokémon y API pública'),
          bottom: TabBar(
            tabs: [Tab(text: 'Pokémon'), Tab(text: 'API pública')],
          ),
        ),
        body: TabBarView(
          children: [PokemonTab(), PublicApiTab()],
        ),
      ),
    );
  }
}

class PokemonTab extends StatefulWidget {
  @override
  _PokemonTabState createState() => _PokemonTabState();
}

class _PokemonTabState extends State<PokemonTab> {
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _error;
  Map<String, dynamic>? _pokemon;

  Future<void> _searchPokemon(String name) async {
    setState(() {
      _loading = true;
      _error = null;
      _pokemon = null;
    });

    final url = Uri.parse('https://pokeapi.co/api/v2/pokemon/\$name'.replaceAll('\$name', name.toLowerCase().trim()));
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        setState(() {
          _pokemon = data;
          _loading = false;
        });
      } else if (resp.statusCode == 404) {
        setState(() {
          _error = 'Pokémon no encontrado: '
              '${name.toLowerCase().trim()}';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error al obtener datos (HTTP \\${resp.statusCode})';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de red: \\$e';
        _loading = false;
      });
    }
  }

  Widget _buildPokemonView() {
    if (_loading) return Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!, style: TextStyle(color: Colors.red)));
    if (_pokemon == null) return Center(child: Text('Usa el campo de búsqueda para ver un Pokémon'));

    final sprites = _pokemon?['sprites'] as Map<String, dynamic>?;
    final imageUrl = sprites?['other']?['official-artwork']?['front_default'] ?? sprites?['front_default'];

    final types = (_pokemon?['types'] as List<dynamic>?) ?? [];
    final abilities = (_pokemon?['abilities'] as List<dynamic>?) ?? [];
    final stats = (_pokemon?['stats'] as List<dynamic>?) ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Center(child: Image.network(imageUrl, height: 200, fit: BoxFit.contain)),
          SizedBox(height: 12),
          Text('Nombre: ' + (_pokemon?['name'] ?? ''), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          Text('ID: ' + (_pokemon?['id']?.toString() ?? '')),
          SizedBox(height: 6),
          Text('Altura: ' + (_pokemon?['height']?.toString() ?? '') + '  •  Peso: ' + (_pokemon?['weight']?.toString() ?? '')),
          SizedBox(height: 12),
          Text('Tipos:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(
            spacing: 8,
            children: types.map<Widget>((t) {
              final name = t['type']?['name'] ?? '';
              return Chip(label: Text(name));
            }).toList(),
          ),
          SizedBox(height: 12),
          Text('Habilidades:', style: TextStyle(fontWeight: FontWeight.bold)),
          Wrap(spacing: 8, children: abilities.map<Widget>((a) {
            final name = a['ability']?['name'] ?? '';
            return Chip(label: Text(name));
          }).toList()),
          SizedBox(height: 12),
          Text('Stats:', style: TextStyle(fontWeight: FontWeight.bold)),
          Column(
            children: stats.map<Widget>((s) {
              final statName = s['stat']?['name'] ?? '';
              final base = s['base_stat']?.toString() ?? '';
              return ListTile(
                dense: true,
                title: Text(statName),
                trailing: Text(base),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(labelText: 'Nombre del Pokémon (ej: ditto)', border: OutlineInputBorder()),
                  onSubmitted: _searchPokemon,
                ),
              ),
              SizedBox(width: 8),
              ElevatedButton(onPressed: () => _searchPokemon(_controller.text), child: Text('Buscar')),
            ],
          ),
        ),
        Expanded(child: _buildPokemonView()),
      ],
    );
  }
}

class PublicApiTab extends StatefulWidget {
  @override
  _PublicApiTabState createState() => _PublicApiTabState();
}

class _PublicApiTabState extends State<PublicApiTab> {
  String? _dogImage;
  bool _loading = false;
  String? _error;

  Future<void> _fetchRandomDog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final url = Uri.parse('https://dog.ceo/api/breeds/image/random');
    try {
      final resp = await http.get(url);
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body);
        setState(() {
          _dogImage = data['message'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error HTTP \\${resp.statusCode}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de red: \\$e';
        _loading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchRandomDog();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(child: Text('Dog API — imagen aleatoria de perro')),
              ElevatedButton(onPressed: _fetchRandomDog, child: Text('Nueva')),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: _loading
                ? CircularProgressIndicator()
                : _error != null
                    ? Text(_error!, style: TextStyle(color: Colors.red))
                    : (_dogImage != null
                        ? Image.network(_dogImage!, fit: BoxFit.contain)
                        : Text('Pulsa "Nueva" para cargar una imagen')),
          ),
        ),
      ],
    );
  }
}