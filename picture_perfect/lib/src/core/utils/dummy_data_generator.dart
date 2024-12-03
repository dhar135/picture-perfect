import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:picture_perfect/src/data/models/user_model.dart';
import 'package:picture_perfect/src/data/models/poll_model.dart';
import 'dart:math';
import 'package:picture_perfect/src/core/utils/logger.dart';

class DummyDataGenerator {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Random _random = Random();

  // Sample data for generating realistic-looking content
  final List<String> _firstNames = [
    'Alex',
    'Jordan',
    'Taylor',
    'Morgan',
    'Casey',
    'Sam',
    'Jamie',
    'Riley',
    'Quinn',
    'Avery',
    'Blake',
    'Charlie',
    'Drew',
    'Eden',
    'Frankie',
    'Gray',
    'Harper',
    'Indie',
    'Jules',
    'Kennedy'
  ];

  final List<String> _lastNames = [
    'Smith',
    'Johnson',
    'Williams',
    'Brown',
    'Jones',
    'Garcia',
    'Miller',
    'Davis',
    'Rodriguez',
    'Martinez',
    'Hernandez',
    'Lopez',
    'Gonzalez',
    'Wilson',
    'Anderson',
    'Thomas',
    'Taylor',
    'Moore',
    'Jackson',
    'Martin'
  ];

  // Replace the simple _pollTitles with structured poll content
  final Map<PollCategory, List<Map<String, dynamic>>> _pollContent = {
    PollCategory.fashion: [
      {
        'title': 'Which outfit for a first date?',
        'description': 'Help me choose the perfect first date look!',
        'captionOne': 'Casual chic',
        'captionTwo': 'Dressy elegant',
      },
      {
        'title': 'Which shoes should I get?',
        'description': 'Looking for a new pair for everyday wear',
        'captionOne': 'Classic sneakers',
        'captionTwo': 'Trendy boots',
      },
      {
        'title': 'Best accessory for this look?',
        'description': 'Need to complete my outfit',
        'captionOne': 'Statement necklace',
        'captionTwo': 'Minimalist jewelry',
      },
      {
        'title': 'Which bag matches better?',
        'description': 'Going to a wedding',
        'captionOne': 'Clutch',
        'captionTwo': 'Small crossbody',
      },
    ],
    PollCategory.food: [
      {
        'title': 'Dinner plans tonight?',
        'description': 'Can\'t decide what to cook!',
        'captionOne': 'Homemade pasta',
        'captionTwo': 'Grilled salmon',
      },
      {
        'title': 'Best breakfast option?',
        'description': 'Starting my day right',
        'captionOne': 'Avocado toast',
        'captionTwo': 'Acai bowl',
      },
      {
        'title': 'Which dessert looks better?',
        'description': 'Sweet tooth cravings',
        'captionOne': 'Chocolate cake',
        'captionTwo': 'Fruit tart',
      },
      {
        'title': 'Restaurant choice for anniversary',
        'description': 'Special occasion dining',
        'captionOne': 'Italian fine dining',
        'captionTwo': 'Modern fusion',
      },
    ],
    PollCategory.lifestyle: [
      {
        'title': 'Which workout routine?',
        'description': 'Planning my fitness journey',
        'captionOne': 'HIIT training',
        'captionTwo': 'Yoga flow',
      },
      {
        'title': 'Weekend getaway location',
        'description': 'Need a break from the city',
        'captionOne': 'Beach resort',
        'captionTwo': 'Mountain cabin',
      },
      {
        'title': 'Home office setup',
        'description': 'Upgrading my workspace',
        'captionOne': 'Minimalist desk',
        'captionTwo': 'Creative corner',
      },
      {
        'title': 'Evening routine activity',
        'description': 'Better way to wind down?',
        'captionOne': 'Reading book',
        'captionTwo': 'Meditation',
      },
    ],
    PollCategory.beauty: [
      {
        'title': 'Which hairstyle suits me?',
        'description': 'Time for a change, need your opinion!',
        'captionOne': 'Long layers',
        'captionTwo': 'Trendy bob',
      },
      {
        'title': 'Makeup look for wedding',
        'description': 'Going to a friend\'s wedding',
        'captionOne': 'Natural glow',
        'captionTwo': 'Glamorous smokey',
      },
      {
        'title': 'Best skincare routine?',
        'description': 'Building my morning routine',
        'captionOne': 'Korean 10-step',
        'captionTwo': 'Minimal 3-step',
      },
    ],
    PollCategory.travel: [
      {
        'title': 'Next vacation destination',
        'description': 'Planning my summer trip!',
        'captionOne': 'Tropical paradise',
        'captionTwo': 'European adventure',
      },
      {
        'title': 'Travel accommodation',
        'description': 'Where should I stay?',
        'captionOne': 'Luxury resort',
        'captionTwo': 'Local boutique hotel',
      },
      {
        'title': 'Adventure activity pick',
        'description': 'Trying something new on vacation',
        'captionOne': 'Scuba diving',
        'captionTwo': 'Mountain hiking',
      },
    ],
    PollCategory.technology: [
      {
        'title': 'Which laptop to buy?',
        'description': 'Need a new work computer',
        'captionOne': 'MacBook Pro',
        'captionTwo': 'Dell XPS',
      },
      {
        'title': 'Smart home device',
        'description': 'Adding to my smart home setup',
        'captionOne': 'Smart lights',
        'captionTwo': 'Smart thermostat',
      },
      {
        'title': 'Gaming console choice',
        'description': 'Time for an upgrade',
        'captionOne': 'PS5',
        'captionTwo': 'Xbox Series X',
      },
    ],
    PollCategory.pets: [
      {
        'title': 'Which pet bed design?',
        'description': 'Getting something comfy for my furry friend',
        'captionOne': 'Plush donut bed',
        'captionTwo': 'Memory foam mat',
      },
      {
        'title': 'Pet costume for Halloween',
        'description': 'Making my pet the star of the party',
        'captionOne': 'Superhero outfit',
        'captionTwo': 'Dinosaur costume',
      },
      {
        'title': 'Pet toy selection',
        'description': 'Birthday gift for my pet',
        'captionOne': 'Interactive puzzle',
        'captionTwo': 'Plush squeaky toy',
      },
    ],
    PollCategory.fitness: [
      {
        'title': 'Gym equipment purchase',
        'description': 'Building my home gym',
        'captionOne': 'Adjustable dumbbells',
        'captionTwo': 'Resistance bands set',
      },
      {
        'title': 'Post-workout meal',
        'description': 'Need to refuel after training',
        'captionOne': 'Protein smoothie',
        'captionTwo': 'Chicken and rice',
      },
      {
        'title': 'Workout shoes',
        'description': 'Need new training footwear',
        'captionOne': 'Running shoes',
        'captionTwo': 'Cross-trainers',
      },
    ],
    PollCategory.home: [
      {
        'title': 'Living room color scheme',
        'description': 'Redecorating my space',
        'captionOne': 'Warm neutrals',
        'captionTwo': 'Bold and bright',
      },
      {
        'title': 'Kitchen appliance choice',
        'description': 'Adding to my kitchen',
        'captionOne': 'Stand mixer',
        'captionTwo': 'Air fryer',
      },
      {
        'title': 'Garden layout design',
        'description': 'Planning my backyard makeover',
        'captionOne': 'Zen garden',
        'captionTwo': 'Cottage garden',
      },
    ],
    PollCategory.entertainment: [
      {
        'title': 'Weekend movie genre',
        'description': 'Movie night with friends',
        'captionOne': 'Horror thriller',
        'captionTwo': 'Comedy drama',
      },
      {
        'title': 'Concert tickets',
        'description': 'Which show should I attend?',
        'captionOne': 'Rock festival',
        'captionTwo': 'Pop concert',
      },
      {
        'title': 'Board game night',
        'description': 'Planning game night with friends',
        'captionOne': 'Strategy game',
        'captionTwo': 'Party game',
      },
    ],
    PollCategory.art: [
      {
        'title': 'Wall art style',
        'description': 'Decorating my new apartment',
        'captionOne': 'Abstract canvas',
        'captionTwo': 'Vintage prints',
      },
      {
        'title': 'Photography theme',
        'description': 'For my next photo series',
        'captionOne': 'Urban street',
        'captionTwo': 'Natural landscape',
      },
      {
        'title': 'Craft project idea',
        'description': 'Weekend DIY plans',
        'captionOne': 'Pottery making',
        'captionTwo': 'Paint pouring',
      },
    ],
    PollCategory.sports: [
      {
        'title': 'Sports equipment',
        'description': 'Starting a new hobby',
        'captionOne': 'Tennis racket',
        'captionTwo': 'Golf clubs',
      },
      {
        'title': 'Team jersey design',
        'description': 'For our local team',
        'captionOne': 'Classic stripes',
        'captionTwo': 'Modern gradient',
      },
      {
        'title': 'Game day snacks',
        'description': 'Hosting a sports viewing party',
        'captionOne': 'Wings and dips',
        'captionTwo': 'Pizza and nachos',
      },
    ],
    PollCategory.other: [
      {
        'title': 'Next phone choice',
        'description': 'Time for an upgrade',
        'captionOne': 'Latest iPhone',
        'captionTwo': 'New Android',
      },
      {
        'title': 'Movie night pick',
        'description': 'Friday night entertainment',
        'captionOne': 'Action thriller',
        'captionTwo': 'Rom-com',
      },
      {
        'title': 'Pet adoption choice',
        'description': 'Adding to the family',
        'captionOne': 'Rescue dog',
        'captionTwo': 'Shelter cat',
      },
      {
        'title': 'Gift for best friend',
        'description': 'Birthday coming up',
        'captionOne': 'Experience gift',
        'captionTwo': 'Physical present',
      },
    ],
  };

  final List<String> _sampleImages = [
    'https://picsum.photos/400/600', // Replace with your actual image URLs
    'https://picsum.photos/400/601',
    'https://picsum.photos/400/602',
    'https://picsum.photos/400/603',
    'https://picsum.photos/400/604',
  ];

  String _generateEmail(String firstName, String lastName) {
    return '${firstName.toLowerCase()}.${lastName.toLowerCase()}@example.com';
  }

  Future<void> generateDummyData() async {
    try {
      // Generate 20 users
      for (int i = 0; i < 20; i++) {
        String firstName = _firstNames[i];
        String lastName = _lastNames[i];
        String email = _generateEmail(firstName, lastName);
        String password =
            'Password123!'; // Simple password for all dummy accounts

        // Create Firebase Auth account
        UserCredential userCred = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Create user profile
        UserModel user = UserModel.fromFirebaseUser(userCred.user!)
            .copyWith(name: '$firstName $lastName');

        // Save user to Firestore
        await _firestore.collection('users').doc(user.id).set(user.toJson());

        // Generate 2-5 polls for this user
        int numPolls = _random.nextInt(4) + 2; // Random number between 2 and 5
        for (int j = 0; j < numPolls; j++) {
          await _createDummyPoll(user.id);
        }
      }
    } catch (e) {
      AppLogger.error('Error generating dummy data', e);
    }
  }

  Future<void> _createDummyPoll(String userId) async {
    try {
      final pollRef = _firestore.collection('polls').doc();

      // Select random category
      final category =
          PollCategory.values[_random.nextInt(PollCategory.values.length)];

      // Select random poll content from that category
      final categoryPolls = _pollContent[category]!;
      final pollContent = categoryPolls[_random.nextInt(categoryPolls.length)];

      final poll = PollModel(
        id: pollRef.id,
        creatorId: userId,
        title: pollContent['title'],
        description: pollContent['description'],
        imageOne: _sampleImages[_random.nextInt(_sampleImages.length)],
        imageTwo: _sampleImages[_random.nextInt(_sampleImages.length)],
        captionOne: pollContent['captionOne'],
        captionTwo: pollContent['captionTwo'],
        category: category,
        votingType: _random.nextBool()
            ? PollVotingType.anonymous
            : PollVotingType.nonAnonymous,
        createdAt: DateTime.now(),
        deadline: DateTime.now().add(Duration(days: _random.nextInt(7) + 1)),
        status: PollStatus.active,
      );

      await pollRef.set(poll.toJson());

      // Update user's createdPolls
      await _firestore.collection('users').doc(userId).update({
        'createdPolls': FieldValue.arrayUnion([pollRef.id]),
        'posts': FieldValue.increment(1),
      });
    } catch (e) {
      AppLogger.error('Error creating dummy poll', e);
    }
  }

  // Helper method to clean up all dummy data (use carefully!)
  Future<void> cleanupDummyData() async {
    try {
      // Get all users with @example.com email
      final querySnapshot = await _firestore.collection('users').get();

      for (var doc in querySnapshot.docs) {
        final userData = doc.data();
        if (userData['email'].toString().contains('@example.com')) {
          // Delete their polls
          final polls = List<String>.from(userData['createdPolls'] ?? []);
          for (var pollId in polls) {
            await _firestore.collection('polls').doc(pollId).delete();
          }

          // Delete the user document
          await doc.reference.delete();

          // Delete the Firebase Auth account
          try {
            // Sign in as the user first
            await _auth.signInWithEmailAndPassword(
              email: userData['email'].toString(),
              password: 'Password123!',
            );
            await _auth.currentUser?.delete();
          } catch (e) {
            AppLogger.error('Error deleting auth user', e);
          }
        }
      }
    } catch (e) {
      AppLogger.error('Error cleaning up dummy data', e);
    }
  }
}
