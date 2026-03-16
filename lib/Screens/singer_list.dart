import 'package:flutter/material.dart';
import 'package:lyrics/widgets/main_background.dart';

class Singer {
  final String name;
  final String imagePath;

  Singer({required this.name, required this.imagePath});
}

class SingerList extends StatelessWidget {
  SingerList({super.key});

  // Sample data - replace with your actual data
  final List<Singer> singers = [
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
    Singer(name: "Billie Eilish", imagePath: "assets/Rectangle 33.png"),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Singer List',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: const Color(0xFF1E3A5F), // Dark blue color
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: MainBAckgound(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85, // Adjust to match the card proportions
            ),
            itemCount: singers.length,
            itemBuilder: (context, index) {
              return SingerCard(singer: singers[index]);
            },
          ),
        ),
      ),
    );
  }
}

class SingerCard extends StatelessWidget {
  final Singer singer;

  const SingerCard({super.key, required this.singer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: DecorationImage(
                  image: AssetImage(singer.imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                singer.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Alternative implementation using NetworkImage if you're using network images
class SingerCardNetwork extends StatelessWidget {
  final Singer singer;

  const SingerCardNetwork({super.key, required this.singer});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  singer.imagePath,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey.withOpacity(0.3),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 40,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(
                singer.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
