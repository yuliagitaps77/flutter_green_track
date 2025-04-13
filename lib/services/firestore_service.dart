import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

// A lightweight wrapper around FirebaseFirestore to simplify CRUD operations
class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references to avoid typos and make maintenance easier
  final CollectionReference userCollection;
  final CollectionReference tpkItemsCollection;
  final CollectionReference penyemaianItemsCollection;

  // Singleton pattern
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal()
      : userCollection = FirebaseFirestore.instance.collection('users'),
        tpkItemsCollection = FirebaseFirestore.instance.collection('tpkItems'),
        penyemaianItemsCollection =
            FirebaseFirestore.instance.collection('penyemaianItems');

  // GENERIC CRUD METHODS

  // Create or update a document (upsert)
  Future<void> setDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
    bool merge = true,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).set(
            data,
            SetOptions(merge: merge),
          );
    } catch (e) {
      print('Error setting document: $e');
      rethrow;
    }
  }

  // Get a document by ID
  Future<DocumentSnapshot> getDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      return await _firestore.collection(collection).doc(documentId).get();
    } catch (e) {
      print('Error getting document: $e');
      rethrow;
    }
  }

  // Update specific fields in a document
  Future<void> updateDocument({
    required String collection,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).update(data);
    } catch (e) {
      print('Error updating document: $e');
      rethrow;
    }
  }

  // Delete a document
  Future<void> deleteDocument({
    required String collection,
    required String documentId,
  }) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } catch (e) {
      print('Error deleting document: $e');
      rethrow;
    }
  }

  // Query documents with optional filters
  Future<QuerySnapshot> queryDocuments({
    required String collection,
    List<List<dynamic>> filters = const [],
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query query = _firestore.collection(collection);

      // Apply filters if any
      for (var filter in filters) {
        if (filter.length == 3) {
          query = query.where(
            filter[0],
            isEqualTo: filter[1] == '==' ? filter[2] : null,
            isGreaterThan: filter[1] == '>' ? filter[2] : null,
            isGreaterThanOrEqualTo: filter[1] == '>=' ? filter[2] : null,
            isLessThan: filter[1] == '<' ? filter[2] : null,
            isLessThanOrEqualTo: filter[1] == '<=' ? filter[2] : null,
            arrayContains: filter[1] == 'array-contains' ? filter[2] : null,
          );
        }
      }

      // Apply ordering if specified
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit if specified
      if (limit != null) {
        query = query.limit(limit);
      }

      return await query.get();
    } catch (e) {
      print('Error querying documents: $e');
      rethrow;
    }
  }

  // Get a realtime stream of a document
  Stream<DocumentSnapshot> documentStream({
    required String collection,
    required String documentId,
  }) {
    return _firestore.collection(collection).doc(documentId).snapshots();
  }

  // Get a realtime stream of a collection
  Stream<QuerySnapshot> collectionStream({
    required String collection,
    List<List<dynamic>> filters = const [],
    String? orderBy,
    bool descending = false,
    int? limit,
  }) {
    Query query = _firestore.collection(collection);

    // Apply filters if any
    for (var filter in filters) {
      if (filter.length == 3) {
        query = query.where(
          filter[0],
          isEqualTo: filter[1] == '==' ? filter[2] : null,
          isGreaterThan: filter[1] == '>' ? filter[2] : null,
          isGreaterThanOrEqualTo: filter[1] == '>=' ? filter[2] : null,
          isLessThan: filter[1] == '<' ? filter[2] : null,
          isLessThanOrEqualTo: filter[1] == '<=' ? filter[2] : null,
          arrayContains: filter[1] == 'array-contains' ? filter[2] : null,
        );
      }
    }

    // Apply ordering if specified
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }

    // Apply limit if specified
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots();
  }

  // Batch operations for better performance and atomicity
  Future<void> performBatchOperation(
      Future<void> Function(WriteBatch batch) operations) async {
    final batch = _firestore.batch();

    try {
      await operations(batch);
      await batch.commit();
    } catch (e) {
      print('Error in batch operation: $e');
      rethrow;
    }
  }

  // Transaction for ensuring atomicity
  Future<T> performTransaction<T>(
      Future<T> Function(Transaction transaction) operations) async {
    try {
      return await _firestore.runTransaction(operations);
    } catch (e) {
      print('Error in transaction: $e');
      rethrow;
    }
  }
}
