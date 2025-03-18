import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final CollectionReference cartCollection = FirebaseFirestore.instance.collection("user_cart");

  Future<void> addToCart(String userEmail, String name, double price) async {
    DocumentReference itemRef = cartCollection.doc(userEmail).collection("items").doc(name);

    DocumentSnapshot doc = await itemRef.get();

    if (doc.exists) {
      await itemRef.update({"quantity": FieldValue.increment(1)});
    } else {
      await itemRef.set({"name": name, "price": price, "quantity": 1});
    }
  }

  Future<void> updateQuantity(String userEmail, String name, int change) async {
    DocumentReference itemRef = cartCollection.doc(userEmail).collection("items").doc(name);

    DocumentSnapshot doc = await itemRef.get();
    if (doc.exists) {
      int newQuantity = (doc["quantity"] as int) + change;
      if (newQuantity > 0) {
        await itemRef.update({"quantity": newQuantity});
      } else {
        await itemRef.delete(); // Remove item if quantity reaches zero
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems(String userEmail) async {
    QuerySnapshot snapshot = await cartCollection.doc(userEmail).collection("items").get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }
}
