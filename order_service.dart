import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final CollectionReference cartCollection =
  FirebaseFirestore.instance.collection("user_cart");

  Future<void> addToCart(String userEmail, String name,int quantity, double price,String orderId) async {
    DocumentReference itemRef =
    cartCollection.doc(userEmail).collection("items").doc(name);

    DocumentSnapshot doc = await itemRef.get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int unpaidQty = data['unpaidQuantity'] ?? 0;
      await itemRef.update({"unpaidQuantity": unpaidQty + 1});
    } else {
      await itemRef.set({
        "name": name,
        "price": price,
        "paidQuantity": 0,
        "unpaidQuantity": 1
      });
    }
  }

  Future<void> updateQuantity(String userEmail, String name, int change) async {
    DocumentReference itemRef =
    cartCollection.doc(userEmail).collection("items").doc(name);

    DocumentSnapshot doc = await itemRef.get();
    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int unpaidQty = data['unpaidQuantity'] ?? 0;
      int paidQty = data['paidQuantity'] ?? 0;
      int newUnpaidQty = unpaidQty + change;

      if (newUnpaidQty > 0) {
        await itemRef.update({"unpaidQuantity": newUnpaidQty});
      } else {
        if (paidQty > 0) {
          await itemRef.update({"unpaidQuantity": 0});
        } else {
          await itemRef.delete();
        }
      }
    }
  }

  Future<List<Map<String, dynamic>>> getCartItems(String userEmail) async {
    QuerySnapshot snapshot =
    await cartCollection.doc(userEmail).collection("items").get();

    return snapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      return {
        "name": data["name"] ?? "Unknown",
        "price": data["price"] ?? 0.0,
        "paidQuantity": data["paidQuantity"] ?? 0,
        "unpaidQuantity": data["unpaidQuantity"] ?? 0,
      };
    }).toList();
  }

  Future<void> markOrdersPaid(String userEmail, double amountPaid) async {
    QuerySnapshot snapshot = await cartCollection
        .doc(userEmail)
        .collection("items")
        .where("unpaidQuantity", isGreaterThan: 0)
        .get();

    double remainingBalance = amountPaid;

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int unpaidQty = data['unpaidQuantity'] ?? 0;
      int paidQty = data['paidQuantity'] ?? 0;
      double price = data['price'] ?? 0.0;
      int payableQty = (remainingBalance ~/ price).toInt();

      if (payableQty > 0) {
        int paidNow = (payableQty > unpaidQty) ? unpaidQty : payableQty;
        remainingBalance -= paidNow * price;

        await doc.reference.update({
          "paidQuantity": paidQty + paidNow,
          "unpaidQuantity": unpaidQty - paidNow
        });

        if (remainingBalance <= 0) break;
      }
    }
  }
}

