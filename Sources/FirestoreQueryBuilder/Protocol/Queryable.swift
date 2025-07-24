//
//  Queryable.swift
//  FirestoreQueryBuilder
//
//  Created by Alexandru Solomon on 16.07.2025.
//

import FirebaseFirestore

/// Protocol for types that can be queried from Firestore.
/// Conforming types must provide their collection name
///
public protocol Queryable: Codable {
  /// The name of the Firestore collection for this type.
  /// For subcollections, this is just the name of the subcollection itself
  /// (e.g., "messages", not "users/userID/messages").
  ///
  static var collectionName: String { get }
  
  /// Maps a Swift KeyPath to its corresponding string field name in Firestore.
  ///
  /// The default implementation uses `NSExpression(forKeyPath: keyPath).keyPath`
  /// to derive the field name directly from the Swift property name.
  ///
  /// **Important:** If your Swift property names differ from your Firestore field names
  /// (e.g., due to `CodingKeys` renaming), you **must** override this method
  /// in your conforming type to provide the correct mapping (e.g., using a `switch` statement).
  ///
  /// - Parameter keyPath: The KeyPath to the property.
  /// - Returns: The string name of the Firestore field.
  ///
  static func firestoreFieldName<Value>(for keyPath: KeyPath<Self, Value>) -> String?
  
  /// Creates a new QueryBuilder instance for this `Queryable` type, starting from the top-level collection.
  ///
  static func query() -> QueryBuilder<Self>
  
  /// Creates a new QueryBuilder instance for this Queryable type, starting as a subcollection,
  /// within a specific parent document.
  ///
  /// - Parameter parentDocumentRef: The `DocumentReference` of the parent document.
  ///
  static func query(in parentDocumentRef: DocumentReference) -> QueryBuilder<Self>
  
  /// Creates a `Queryable` object from the document reference
  ///
  /// - Parameter documentReference: The documentID of the object
  ///
  static func createFrom(_ documentReference: DocumentReference) async throws -> Self
  
}

// MARK: - Default Implementations

extension Queryable {
  public static func query() -> QueryBuilder<Self> {
    QueryBuilder<Self>()
  }
  
  public static func query(in parentDocumentRef: DocumentReference) -> QueryBuilder<Self> {
    QueryBuilder<Self>(parentDocumentRef: parentDocumentRef)
  }
  
  /// This works if Swift property names match the Firestore field names.
  public static func firestoreFieldName<Value>(for keyPath: KeyPath<Self, Value>) -> String? {
      return NSExpression(forKeyPath: keyPath).keyPath
  }
  
  public static func createFrom(_ documentReference: DocumentReference) async throws -> Self {
    return try await documentReference.getDocument().data(as: Self.self)
  }
}
