import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = "wallets";

  Future<double> getBalance(String userEmail) async {
    DocumentSnapshot snapshot =
    await _firestore.collection(collectionName).doc(userEmail).get();
    if (snapshot.exists && snapshot.data() != null) {
      return (snapshot.data() as Map<String, dynamic>)["balance"]?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<void> addMoney(String userEmail, double amount) async {
    DocumentReference userWalletRef = _firestore.collection(collectionName).doc(userEmail);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userWalletRef);
      double currentBalance =
      snapshot.exists ? (snapshot.data() as Map<String, dynamic>)["balance"]?.toDouble() ?? 0.0 : 0.0;

      transaction.update(userWalletRef, {"balance": currentBalance + amount});
    }).catchError((error) {
      // If the document doesn't exist, create it with the initial amount
      return userWalletRef.set({"balance": amount});
    });
  }

  Future<bool> deductMoney(String userEmail, double amount) async {
    DocumentReference userWalletRef = _firestore.collection(collectionName).doc(userEmail);

    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(userWalletRef);
      if (!snapshot.exists) return false;

      double currentBalance = (snapshot.data() as Map<String, dynamic>)["balance"]?.toDouble() ?? 0.0;
      if (currentBalance < amount) return false; // Insufficient funds

      transaction.update(userWalletRef, {"balance": currentBalance - amount});
      return true;
    }).then((value) => value).catchError((_) => false);
  }
}
