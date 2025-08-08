import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../model/expense.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _userId => _auth.currentUser?.uid;

  // Get user's expense collection reference
  CollectionReference? get _expensesCollection {
    if (_userId == null) return null;
    return _db.collection('users').doc(_userId).collection('expenses');
  }

  // Sync expenses to Firestore
  Future<void> syncExpensesToCloud(List<Expense> expenses) async {
    if (_expensesCollection == null) return;

    final batch = _db.batch();

    for (final expense in expenses) {
      final docRef = _expensesCollection!.doc(expense.id);
      batch.set(docRef, expense.toJson());
    }

    await batch.commit();
  }

  // Load expenses from Firestore
  Future<List<Expense>> loadExpensesFromCloud() async {
    if (_expensesCollection == null) return [];

    try {
      final snapshot = await _expensesCollection!.get();
      return snapshot.docs
          .map((doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading expenses from cloud: $e');
      return [];
    }
  }

  // Add single expense to Firestore
  Future<void> addExpenseToCloud(Expense expense) async {
    if (_expensesCollection == null) return;

    try {
      await _expensesCollection!.doc(expense.id).set(expense.toJson());
    } catch (e) {
      print('Error adding expense to cloud: $e');
    }
  }

  // Delete expense from Firestore
  Future<void> deleteExpenseFromCloud(String expenseId) async {
    if (_expensesCollection == null) return;

    try {
      await _expensesCollection!.doc(expenseId).delete();
    } catch (e) {
      print('Error deleting expense from cloud: $e');
    }
  }

  // Listen to real-time expense changes
  Stream<List<Expense>>? expenseStream() {
    if (_expensesCollection == null) return null;

    return _expensesCollection!.snapshots().map(
          (snapshot) => snapshot.docs
              .map(
                  (doc) => Expense.fromJson(doc.data() as Map<String, dynamic>))
              .toList(),
        );
  }

  // Save user preferences
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    if (_userId == null) return;

    try {
      await _db.collection('users').doc(_userId).set({
        'preferences': preferences,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving user preferences: $e');
    }
  }

  // Load user preferences
  Future<Map<String, dynamic>?> loadUserPreferences() async {
    if (_userId == null) return null;

    try {
      final doc = await _db.collection('users').doc(_userId).get();
      return doc.data()?['preferences'] as Map<String, dynamic>?;
    } catch (e) {
      print('Error loading user preferences: $e');
      return null;
    }
  }
}
