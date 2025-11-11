import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoadingCard extends StatelessWidget {
  const LottieLoadingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://lottie.host/8bd84439-c5ad-496a-94d9-997354e1e851/hLPHFdiRvA.json',
      width: 256,
    );
  }
}

class LottieSuccessCard extends StatelessWidget {
  final String message;
  const LottieSuccessCard({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Lottie.network(
      'https://lottie.host/332642b0-def2-4876-bcde-4d260813e934/BHfkPEd2N3.json',
      width: 154,
    );
  }
}
