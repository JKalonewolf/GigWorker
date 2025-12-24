import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // --- 1. SIGN UP (Updated with Verification) ---
  Future<String?> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required String city,
  }) async {
    try {
      // 1. Create Authentication User
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;

      if (user != null) {
        // 2. Save User Data (Using Phone as Document ID)
        await _firestore.collection('users').doc(phone).set({
          'uid': user.uid,
          'name': name,
          'email': email,
          'phoneNumber': phone,
          'city': city,
          'createdAt': FieldValue.serverTimestamp(),
          'walletBalance': 0,
          'kycStatus': 'unverified',
          'isSuspended': false,
          'profilePic': '',
        });

        // 3. 🚀 SEND EMAIL VERIFICATION LINK
        // This sends the email immediately after account creation
        await user.sendEmailVerification();
      }

      return null; // Success
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return "This email is already registered. Please Login.";
      }
      return e.message;
    } catch (e) {
      return "An unknown error occurred.";
    }
  }

  // --- 2. SIGN IN (Standard) ---
  // Note: Verification check usually happens in the UI (LoginPage), not here.
  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // --- 3. GOOGLE SIGN IN ---
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Sign in aborted";

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;

      if (user != null) {
        // Use email as ID if phone missing (Google Logic)
        final userDoc = await _firestore
            .collection('users')
            .doc(user.email)
            .get();

        if (!userDoc.exists) {
          await _firestore.collection('users').doc(user.email).set({
            'uid': user.uid,
            'name': user.displayName ?? "Google User",
            'email': user.email,
            'phoneNumber': "No Phone",
            'city': "Unknown",
            'createdAt': FieldValue.serverTimestamp(),
            'walletBalance': 0,
            'kycStatus': 'unverified',
            'isSuspended': false,
            'profilePic': user.photoURL ?? '',
          });
        }
        return null;
      }
      return "Google Sign In Failed";
    } catch (e) {
      return e.toString();
    }
  }

  // --- GET PHONE FROM EMAIL ---
  Future<String?> getPhoneFromEmail(String email) async {
    // 1. Check if doc exists with email ID (Google Login)
    final docRef = await _firestore.collection('users').doc(email).get();
    if (docRef.exists) return email;

    // 2. Check if field 'email' matches (Regular Login)
    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (query.docs.isNotEmpty) return query.docs.first.id;

    return null;
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
