//
//  QueryBuilder.swift
//  FirestoreQueryBuilder
//
//  Created by Alexandru Solomon on 16.07.2025.
//

import FirebaseFirestore
import OSLog

public class QueryBuilder<T: Queryable> {
  private let logger = Logger(subsystem: "FirestoreQueryBuilder", category: "QueryBuilder")
  
  private static var firestore: Firestore {
    Firestore.firestore()
  }
  
  /// The internal Firestore Query object that gets build up with predicates.
  private var currentFirestoreQuery: Query
  
  /// Initializes a new `QueryBuilder` for the specified `Queryable` type
  /// starting from its top-level collectiom.
  public init() {
    self.currentFirestoreQuery = Self.firestore.collection(T.collectionName)
  }
  
  /// Initializes a new `QueryBuilder` for the specified `Queryable` type
  /// starting as a subcollection within a given parent document.
  public init(parentDocumentRef: DocumentReference) {
    self.currentFirestoreQuery = parentDocumentRef.collection(T.collectionName)
  }
}

// MARK: - Filtering methods

extension QueryBuilder {
  func `where`<Value: Equatable>(
    _ keyPath: KeyPath<T, Value>,
    isEqualTo value: Value
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, isEqualTo: value)
    return self
  }
  
  func `where`<Value: Comparable>(
    _ keyPath: KeyPath<T, Value>,
    isLessThan value: Value
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, isLessThan: value)
    return self
  }
  
  
  func `where`<Value: Comparable>(
    _ keyPath: KeyPath<T, Value>,
    isLessThanOrEqualTo value: Value
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, isLessThanOrEqualTo: value)
    return self
  }
  
  func `where`<Value: Comparable>(
    _ keyPath: KeyPath<T, Value>,
    isGreaterThan value: Value
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, isGreaterThan: value)
    return self
  }
  
  func `where`<Value: Comparable>(
    _ keyPath: KeyPath<T, Value>,
    isGreaterThanOrEqualTo value: Value
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, isGreaterThanOrEqualTo: value)
    return self
  }
  
  func `where`<Value: Equatable>(
    _ keyPath: KeyPath<T, [Value]>,
    arrayContains value: Value
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, arrayContains: value)
    return self
  }
  
  func `where`<Value: Equatable>(
    _ keyPath: KeyPath<T, [Value]>,
    arrayContainsAny values: [Value]
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, arrayContainsAny: values)
    return self
  }
  
  func `where`<Value: Equatable>(
    _ keyPath: KeyPath<T, Value>,
    `in` values: [Value]
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping filter.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.whereField(fieldName, in: values)
    return self
  }
}

// MARK: - Ordering Methods

extension QueryBuilder {
  func orderBy<Value: Comparable>(
    _ keyPath: KeyPath<T, Value>,
    descending: Bool = false
  ) -> QueryBuilder<T> {
    guard let fieldName = T.firestoreFieldName(for: keyPath) else {
      logger.warning("WARNING: Could not find Firestore field name for KeyPath '\(String(describing: keyPath))'. Skipping order by.")
      return self
    }
    self.currentFirestoreQuery = currentFirestoreQuery.order(by: fieldName, descending: descending)
    return self
  }
  
  func limit(to limit: Int) -> QueryBuilder<T> {
    self.currentFirestoreQuery = currentFirestoreQuery.limit(to: limit)
    return self
  }
}

// MARK: - Fetching methods

extension QueryBuilder {
  func all() async throws -> [T] {
    do {
      let snapshot = try await currentFirestoreQuery.getDocuments()
      return try snapshot.documents.map {
        try $0.data(as: T.self)
      }
    } catch {
      throw QueryError.sdkError(error.localizedDescription)
    }
  }
  
  func first() async throws -> T? {
    try await limit(to: 1).all().first
  }
  
  func getByDocumentID(_ documentID: String) async throws -> T {
    do {
      let documentRef = Self.firestore.collection(T.collectionName).document(documentID)
      let snapshot = try await documentRef.getDocument()
      guard snapshot.exists else {
        logger.info("Document with ID '\(documentID)' not found in collection '\(T.collectionName)'.")
        throw QueryError.notFound
      }
      
      return try snapshot.data(as: T.self)
      
    } catch {
      logger.error("Error fetching document with ID '\(documentID)': \(error)")
      throw QueryError.sdkError(error.localizedDescription)
    }
  }
}

// MARK: - Write methods

extension QueryBuilder {
  @discardableResult
  func set(_ data: T, documentID: String? = nil, merge: Bool = false) async throws -> DocumentReference {
    let id = documentID ?? Self.firestore.collection(T.collectionName).document().documentID
    let documentRef = Self.firestore.collection(T.collectionName).document(id)
    try await documentRef.setData(from: data, merge: merge)
    return documentRef
  }
  
  @discardableResult
  func set(_ data: [String: Any], documentID: String? = nil, merge: Bool = false) async throws -> DocumentReference {
    let id = documentID ?? Self.firestore.collection(T.collectionName).document().documentID
    let documentRef = Self.firestore.collection(T.collectionName).document(id)
    try await documentRef.setData(data)
    return documentRef
  }
  
  func update(_ fields: [PartialKeyPath<T>: Any], forDocumentID documentID: String) async throws {
    let documentRef = Self.firestore.collection(T.collectionName).document(documentID)
    try await documentRef.updateData(fields)
  }
  
  func delete(documentID: String) async throws {
    let documentRef = Self.firestore.collection(T.collectionName).document(documentID)
    try await documentRef.delete()
  }
}

// MARK: - Error Type

extension QueryBuilder {
  enum QueryError: Error {
    case sdkError(String)
    case notFound
  }
}

extension DocumentReference {
  func setData<T: Encodable>(from value: T, merge: Bool) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      do {
        try setData(from: value, merge: merge) { error in
          if let error {
            continuation.resume(throwing: error)
          } else {
            continuation.resume(returning: ())
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }
}
