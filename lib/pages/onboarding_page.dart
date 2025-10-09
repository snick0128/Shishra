import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shishra/pages/main_navigation.dart';
import 'package:shishra/main.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  Future<void> _completeOnboarding(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await sharedPrefs.setBool('onboarded_${user.uid}', true);
    }
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            children: const [
              OnboardingStep(
                image: 'assets/images/onboarding1.svg',
                title: 'Welcome to Shishra',
                description:
                    'Discover a world of exquisite jewelry, handcrafted with love and passion.',
              ),
              OnboardingStep(
                image: 'assets/images/onboarding2.svg',
                title: 'Create Your Wishlist',
                description:
                    'Save your favorite pieces and create a wishlist for any occasion.',
              ),
              OnboardingStep(
                image: 'assets/images/onboarding3.svg',
                title: 'Seamless Shopping',
                description:
                    'Enjoy a fast, secure, and delightful shopping experience from start to finish.',
              ),
            ],
          ),
          Positioned(
            bottom: 20.0,
            left: 20.0,
            right: 20.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => _completeOnboarding(context),
                  child: const Text('Skip'),
                ),
                Row(
                  children: List.generate(
                    3,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 10,
                      width: _currentPage == index ? 30 : 10,
                      margin: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.black
                            : Colors.grey,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    if (_currentPage < 2) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.ease,
                      );
                    } else {
                      _completeOnboarding(context);
                    }
                  },
                  child: Text(_currentPage == 2 ? 'Get Started' : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingStep extends StatelessWidget {
  final String image;
  final String title;
  final String description;

  const OnboardingStep({
    super.key,
    required this.image,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(image, height: 300),
          const SizedBox(height: 40),
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            description,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}