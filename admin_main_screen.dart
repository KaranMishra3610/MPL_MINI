import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'auth_screen.dart'; // Ensure this file exists and is correctly imported

class AdminMainScreen extends StatefulWidget {
  @override
  _AdminMainScreenState createState() => _AdminMainScreenState();
}

class _AdminMainScreenState extends State<AdminMainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Dashboard"),
        backgroundColor: Colors.redAccent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Recent Orders", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(child: _buildOrderList()),
            const SizedBox(height: 20),
            const Text("Item Popularity Chart", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(height: 250, child: _buildPopularityChart()),
          ],
        ),
      ),
    );
  }

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Confirm Logout"),
          content: const Text("Are you sure you want to log out?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: _logout,
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _logout() async {
    Navigator.pop(context);
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AuthScreen()));
  }

  Widget _buildOrderList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("user_cart").snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        List<Widget> orderWidgets = [];

        for (var userDoc in userSnapshot.data!.docs) {
          var userEmail = userDoc.id;

          orderWidgets.add(StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection("user_cart").doc(userEmail).collection("orders").snapshots(),
            builder: (context, orderSnapshot) {
              if (!orderSnapshot.hasData) return const SizedBox.shrink();

              return Column(
                children: orderSnapshot.data!.docs.map((orderDoc) {
                  var data = orderDoc.data() as Map<String, dynamic>;
                  var items = (data["items"] as List<dynamic>? ?? []);

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    elevation: 3,
                    child: ExpansionTile(
                      title: Text("Order #${data['orderId']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Total Price: ₹${data['totalPrice']}"),
                          Text("Total Items: ${data['totalQuantity']}"),
                          Text("Unpaid Amount: ₹${data['unpaidTotal']}", style: const TextStyle(color: Colors.redAccent)),
                        ],
                      ),
                      children: items.map<Widget>((item) {
                        return ListTile(
                          title: Text(item["name"], style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Paid: ${item["paidQuantity"]}"),
                              Text("Unpaid: ${item["unpaidQuantity"]}", style: const TextStyle(color: Colors.red)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ));
        }

        return ListView(children: orderWidgets);
      },
    );
  }

  Widget _buildPopularityChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("user_cart").snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        Map<String, int> productCount = {};

        List<Future<void>> fetchOrders = [];

        for (var userDoc in userSnapshot.data!.docs) {
          var userEmail = userDoc.id;

          fetchOrders.add(FirebaseFirestore.instance
              .collection("user_cart")
              .doc(userEmail)
              .collection("orders")
              .get()
              .then((orderSnapshot) {
            for (var orderDoc in orderSnapshot.docs) {
              var data = orderDoc.data();
              var items = data["items"] as List<dynamic>? ?? [];

              for (var item in items) {
                String productName = item["name"];
                int quantity = item["paidQuantity"] ?? 0;

                productCount[productName] = (productCount[productName] ?? 0) + quantity;
              }
            }
          }));
        }

        return FutureBuilder(
          future: Future.wait(fetchOrders),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productCount.isEmpty) {
              return const Center(child: Text("No Data Available"));
            }

            List<PieChartSectionData> chartData = productCount.entries.map((entry) {
              return PieChartSectionData(
                value: entry.value.toDouble(),
                title: entry.key,
                radius: 60,
                color: Colors.primaries[entry.key.hashCode % Colors.primaries.length],
              );
            }).toList();

            return PieChart(
              PieChartData(
                sections: chartData,
                borderData: FlBorderData(show: false),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            );
          },
        );
      },
    );
  }
}
