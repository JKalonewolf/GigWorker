import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/earning_model.dart';

class EarningService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID safely
  // NEW (Temporary for testing)
  String get _uid => _auth.currentUser?.uid ?? 'test_user_123';

  // 1. Add Earning (Updated for Debugging)
  Future<void> addEarning(EarningModel earning) async {
    // DEBUG CHECK: Print the User ID to the console
    print("Attempting to add earning for User ID: $_uid");

    if (_uid.isEmpty) {
      throw Exception("User is not logged in! Go back to Login Page.");
    }

    try {
      await _db
          .collection('users')
          .doc(_uid)
          .collection('earnings')
          .doc(earning.id)
          .set(earning.toMap());
      print("Earning successfully added to Firestore!");
    } catch (e) {
      print("Firestore Error: $e");
      rethrow;
    }
  }

  // 2. Get Earnings Stream
  Stream<List<EarningModel>> getEarningsStream() {
    if (_uid.isEmpty) return const Stream.empty();
    return _db
        .collection('users')
        .doc(_uid)
        .collection('earnings')
        .orderBy('date', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => EarningModel.fromMap(doc.data()))
              .toList(),
        );
  }
}
