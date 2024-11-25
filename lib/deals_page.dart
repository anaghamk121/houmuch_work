import 'dart:async';
import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class DealsPage extends StatefulWidget {
  const DealsPage({Key? key}) : super(key: key);

  @override
  State<DealsPage> createState() => _DealsPageState();
}

class _DealsPageState extends State<DealsPage> with SingleTickerProviderStateMixin {
  late Timer _timer;
  int _remainingTime = 300;
  bool _hasPlayedEndingAlert = false;
  late AnimationController _controller;
  late Animation<double> _shimmerAnimation;
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _isAudioInitialized = false;

  late int _bestOffer;

  final List<Map<String, dynamic>> deals = [
    {
      "id": "1",
      "image": "assets/hotel_1.jpg",
      "hotelName": "Hotel Paradise",
      "details": "Luxury stay with free breakfast",
      "price": 1500,
      "previousPrice": 1500
    },
    {
      "id": "2",
      "image": "assets/hotel_2.jpg",
      "hotelName": "Sea View Resort",
      "details": "Beachfront rooms with spa services",
      "price": 2000,
      "previousPrice": 2000
    },
    {
      "id": "3",
      "image": "assets/hotel_3.webp",
      "hotelName": "Mountain Retreat",
      "details": "Serene views and hiking trails",
      "price": 1200,
      "previousPrice": 1200
    },
  ];

  @override
  void initState() {
    super.initState();
    _bestOffer = _calculateBestOffer();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(_controller);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initializeAudio();
      _startTimer();
      _startDealUpdateSimulation();
      _controller.repeat(reverse: false);
    });
  }

  int _calculateBestOffer() {
    return deals.map((deal) => deal['price'] as int).reduce(min);
  }

  Future<void> _initializeAudio() async {
    try {
      await _audioPlayer.setSource(AssetSource('sounds/price_change.mp3'));
      _isAudioInitialized = true;
    } catch (e) {
      debugPrint('Error initializing audio: $e');
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_remainingTime > 0) {
        setState(() {
          _remainingTime--;
          if (_remainingTime == 60 && !_hasPlayedEndingAlert) {
            _playEndingSoonAlert();
            _hasPlayedEndingAlert = true;
          }
        });
      } else {
        _timer.cancel();
        _playDealEndedAlert();
      }
    });
  }

  void _startDealUpdateSimulation() {
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _updateRandomDeal();
    });
  }

  void _updateRandomDeal() {
    if (!mounted || deals.isEmpty) return;

    final random = Random();
    final randomIndex = random.nextInt(deals.length);
    final deal = deals[randomIndex];

    setState(() {
      final oldPrice = deal['price'] as int;
      final priceChange = (oldPrice * 0.85).round();

      if (priceChange != oldPrice) {
        deal['previousPrice'] = oldPrice;
        deal['price'] = priceChange;
        _bestOffer = _calculateBestOffer();
        _playDealChangeAlert();
        _showDealChangeSnackbar(deal['hotelName'], oldPrice, priceChange);
      }
    });
  }

  Future<void> _playDealChangeAlert() async {
    if (!_isAudioInitialized) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/price_change.mp3'));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  Future<void> _playEndingSoonAlert() async {
    if (!_isAudioInitialized) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/one_minute.mp3'));
    } catch (e) {
      debugPrint('Error playing ending soon sound: $e');
    }
  }

  Future<void> _playDealEndedAlert() async {
    if (!_isAudioInitialized) return;

    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/deal_end.mp3'));
    } catch (e) {
      debugPrint('Error playing deal ended sound: $e');
    }
  }

  void _showDealChangeSnackbar(String hotelName, int oldPrice, int newPrice) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Price changed for $hotelName: INR $oldPrice → INR $newPrice',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: newPrice < oldPrice ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildShimmer(Widget child) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _shimmerAnimation,
        builder: (context, _) {
          return ShaderMask(
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.centerRight,
                colors: const [Colors.lightBlue, Colors.blueGrey, Colors.red],
                stops: [
                  _shimmerAnimation.value - 0.5,
                  _shimmerAnimation.value,
                  _shimmerAnimation.value + 0.5
                ],
              ).createShader(bounds);
            },
            child: child,
            blendMode: BlendMode.srcATop,
          );
        },
        child: child,
      ),
    );
  }

  Widget _buildTimerContainer() {
    return Container(
      width: double.infinity,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 70, top: 15),
            child: Row(
              children: [
                const Text(
                  "Best Offer:",
                  style: TextStyle(
                      color: Colors.black,
                      fontSize: 18,
                      fontWeight: FontWeight.bold
                  ),
                ),
                Text(
                  "INR:$_bestOffer",
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Row(
              children: [
                const Text(
                  "Offer Ends In:",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18,
                  ),
                ),
                Text(
                  _formatDuration(_remainingTime),
                  style: const TextStyle(
                    color: Colors.red,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealsList() {
    return ListView.builder(
      itemCount: deals.length,
      cacheExtent: 100,
      itemBuilder: (BuildContext context, int index) {
        final deal = deals[index];
        return RepaintBoundary(
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.asset(
                      deal["image"],
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      cacheWidth: 200,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          deal["hotelName"],
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          deal["details"],
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Price: INR ${deal["price"]}",
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
        showDialog(
        context: context,
        builder: (BuildContext context) {
        return AlertDialog(
        title: const Text("Confirmation"),
        content: const Text("Booked this hotel"),
        actions: [
        TextButton(
        onPressed: () {
        Navigator.of(context).pop(); // Close the dialog
        },
        child: const Text("OK"),
        )]);
                    },);},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text("Book Deal",style: TextStyle(color: Colors.white),
                  ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Deals In Progress..."),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            _buildShimmer(_buildTimerContainer()),
            const SizedBox(height: 20),
            Expanded(child: _buildDealsList()),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text("Cancellation"),
                      content: const Text("Cancelled Booking"),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                          },
                          child: const Text("OK"),
                        ),
                      ],
                    );
                  },
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text("Cancel",style:TextStyle(color:Colors.white)),
            )
          ],
        ),
      ),
    );
  }
}