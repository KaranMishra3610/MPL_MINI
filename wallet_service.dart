import 'package:cloud_firestore/cloud_firestore.dart';

class WalletService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String collectionName = "wallets";

  Future<double> getBalance(String userEmail) async {
    DocumentSnapshot snapshot = await _firestore.collection(collectionName).doc(userEmail).get();
    if (snapshot.exists && snapshot.data() != null) {
      return (snapshot.data() as Map<String, dynamic>)["balance"]?.toDouble() ?? 0.0;
    }
    return 0.0;
  }

  Future<bool> addMoney(String userEmail, double amount) async {
    DocumentReference userWalletRef = _firestore.collection(collectionName).doc(userEmail);

    try {
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userWalletRef);
        double currentBalance = snapshot.exists
            ? (snapshot.data() as Map<String, dynamic>)["balance"]?.toDouble() ?? 0.0
            : 0.0;

        double newBalance = currentBalance + amount;
        transaction.set(userWalletRef, {"balance": newBalance}, SetOptions(merge: true));
        return true;
      });
    } catch (e) {
      return false;
    }
  }

  Future<bool> deductMoney(String userEmail, double amount) async {
    DocumentReference userWalletRef = _firestore.collection(collectionName).doc(userEmail);

    try {
      return await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(userWalletRef);
        if (!snapshot.exists) return false;

        double currentBalance = (snapshot.data() as Map<String, dynamic>)["balance"]?.toDouble() ?? 0.0;
        if (currentBalance < amount) return false;

        transaction.update(userWalletRef, {"balance": currentBalance - amount});
        return true;
      });
    } catch (e) {
      return false;
    }
  }
}
