import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  final CollectionReference cartCollection =
  FirebaseFirestore.instance.collection("user_cart");

  Future<void> addToCart(String userEmail, String name, int quantity, double price, String orderId) async {
    DocumentReference orderRef = cartCollection.doc(userEmail).collection("orders").doc(orderId);
    DocumentSnapshot orderDoc = await orderRef.get();

    if (orderDoc.exists) {
      Map<String, dynamic> orderData = orderDoc.data() as Map<String, dynamic>;
      List<dynamic> items = orderData["items"] ?? [];
      int totalQuantity = orderData["totalQuantity"] ?? 0;
      double totalPrice = orderData["totalPrice"] ?? 0.0;
      double unpaidTotal = orderData["unpaidTotal"] ?? 0.0;

      bool itemExists = false;
      for (var item in items) {
        if (item["name"] == name) {
          item["unpaidQuantity"] += quantity;
          itemExists = true;
          break;
        }
      }

      if (!itemExists) {
        items.add({
          "name": name,
          "price": price,
          "paidQuantity": 0,
          "unpaidQuantity": quantity
        });
      }

      totalQuantity += quantity;
      totalPrice += price * quantity;
      unpaidTotal += price * quantity;

      await orderRef.update({
        "items": items,
        "totalQuantity": totalQuantity,
        "totalPrice": totalPrice,
        "unpaidTotal": unpaidTotal
      });
    } else {
      await orderRef.set({
        "orderId": orderId,
        "totalQuantity": quantity,
        "totalPrice": price * quantity,
        "unpaidTotal": price * quantity,
        "items": [
          {
            "name": name,
            "price": price,
            "paidQuantity": 0,
            "unpaidQuantity": quantity
          }
        ]
      });
    }
  }

  Future<List<Map<String, dynamic>>> getGroupedOrders(String userEmail) async {
    QuerySnapshot snapshot = await cartCollection.doc(userEmail).collection("orders").get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  Future<void> markOrdersPaid(String userEmail, double amountPaid) async {
    QuerySnapshot snapshot = await cartCollection
        .doc(userEmail)
        .collection("orders")
        .where("unpaidTotal", isGreaterThan: 0)
        .get();

    double remainingBalance = amountPaid;

    for (var doc in snapshot.docs) {
      Map<String, dynamic> orderData = doc.data() as Map<String, dynamic>;
      List<dynamic> items = orderData["items"] ?? [];
      double unpaidTotal = orderData["unpaidTotal"] ?? 0.0;
      double totalPrice = orderData["totalPrice"] ?? 0.0;

      for (var item in items) {
        int unpaidQty = item["unpaidQuantity"] ?? 0;
        double price = item["price"] ?? 0.0;
        int payableQty = (remainingBalance ~/ price).toInt();

        if (payableQty > 0) {
          int paidNow = (payableQty > unpaidQty) ? unpaidQty : payableQty;
          remainingBalance -= paidNow * price;

          item["paidQuantity"] += paidNow;
          item["unpaidQuantity"] -= paidNow;
        }

        if (remainingBalance <= 0) break;
      }

      unpaidTotal -= (amountPaid - remainingBalance);
      await doc.reference.update({
        "items": items,
        "unpaidTotal": unpaidTotal > 0 ? unpaidTotal : 0
      });

      if (remainingBalance <= 0) break;
    }
  }
}
