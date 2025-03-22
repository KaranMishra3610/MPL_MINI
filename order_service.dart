import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final CollectionReference cartCollection =
  FirebaseFirestore.instance.collection("user_cart");

  Future<void> addToCart(String userEmail, String name, int quantity, double price, String orderId) async {
    DocumentReference itemRef =
    cartCollection.doc(userEmail).collection("items").doc(name);

    DocumentSnapshot doc = await itemRef.get();

    if (doc.exists) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      int unpaidQty = data['unpaidQuantity'] ?? 0;
      await itemRef.update({"unpaidQuantity": unpaidQty + quantity});
    } else {
      await itemRef.set({
        "name": name,
        "price": price,
        "orderId": orderId,
        "paidQuantity": 0,
        "unpaidQuantity": quantity
      });
    }
  }

  Future<List<Map<String, dynamic>>> getGroupedOrders(String userEmail) async {
    QuerySnapshot snapshot =
    await cartCollection.doc(userEmail).collection("items").get();

    Map<String, Map<String, dynamic>> orders = {};

    for (var doc in snapshot.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      String orderId = data["orderId"] ?? "Unknown";
      double price = data["price"] ?? 0.0;
      int paidQty = data["paidQuantity"] ?? 0;
      int unpaidQty = data["unpaidQuantity"] ?? 0;
      double itemTotal = price * (paidQty + unpaidQty);
      double unpaidTotal = price * unpaidQty;

      if (orders.containsKey(orderId)) {
        orders[orderId]!["totalQuantity"] += paidQty + unpaidQty;
        orders[orderId]!["totalPrice"] += itemTotal;
        orders[orderId]!["unpaidTotal"] += unpaidTotal;
      } else {
        orders[orderId] = {
          "orderId": orderId,
          "totalQuantity": paidQty + unpaidQty,
          "totalPrice": itemTotal,
          "unpaidTotal": unpaidTotal
        };
      }
    }

    return orders.values.toList();
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

