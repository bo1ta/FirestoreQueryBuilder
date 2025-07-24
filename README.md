# FirestoreQueryBuilder
A type-safe, Swift-friendly wrapper for Firebase Firestore queries

## Features

- Type-safe query building with KeyPath support
- Support for both top-level collections and subcollections
- Automatic field name mapping (with custom override support)
- Fluent builder pattern for constructing queries
- Full CRUD operations support
- Comprehensive error handling

## Installation

### Swift Package Manager

Add the package dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/bo1ta/FirestoreQueryBuilder.git", from: "1.0.0")
]

Or add it directly in Xcode via File > Add Packages...

# Usage

## 1. Define your model

```swift
struct User: Queryable, Codable {
    let id: String
    let name: String
    let email: String
    let age: Int
    let friends: [String]
    
    static let collectionName = "users"
    
    // Optional: Provide custom field name mapping if your property names differ from Firestore fields
    static func firestoreFieldName<Value>(for keyPath: KeyPath<User, Value>) -> String? {
        switch keyPath {
        case \.id: return "user_id"  // Example of custom mapping
        default: return nil          // Fall back to default implementation
        }
    }
}
```

## 2. Basic Query Examples

**Fetch all documents**:
```swift
let users = try await User.query().all()
```

**Filter queries**:
```swift
let adults = try await User.query()
    .where(\.age, isGreaterThanOrEqualTo: 18)
    .all()

// Multiple conditions
let activeAdults = try await User.query()
    .where(\.age, isGreaterThanOrEqualTo: 18)
    .where(\.isActive, isEqualTo: true)
    .all()
```

**Ordering and limiting**:
```swift
let oldestUsers = try await User.query()
    .orderBy(\.age, descending: true)
    .limit(to: 10)
    .all()
```

**Array operations**:
```swift
let friendsOfAlice = try await User.query()
    .where(\.friends, arrayContains: "alice123")
    .all()
```

## 3. Subcollections

```swift
let userRef = Firestore.firestore().collection("users").document("user123")
let messages = try await Message.query(in: userRef)
    .orderBy(\.timestamp, descending: true)
    .all()
```

## 4. CRUD Operations

**Create**:
```swift
let newUser = User(id: "123", name: "John", email: "john@example.com", age: 30, friends: [])
let docRef = try await User.query().set(newUser)
```

**Read**:
```swift
// Get by ID
let user = try await User.query().getByDocumentID("123")

// Get first matching document
let user = try await User.query()
    .where(\.email, isEqualTo: "john@example.com")
    .first()
```

**Update**:
```swift
try await User.query().updateDocumentID("123", newValues: [
    \.name: "John Smith",
    \.age: 31
])

// Or full document update
try await User.query().setDocumentID("123", newValues: updatedUser, merge: true)
```

**Delete**:
```swift
try await User.query().delete(documentID: "123")
```

# Advanced Usage

## Custom Field Name Mapping

If your Swift property names differ from Firestore field names (due to CodingKeys or other reasons), override the firestoreFieldName method:

```swift
static func firestoreFieldName<Value>(for keyPath: KeyPath<User, Value>) -> String? {
    switch keyPath {
    case \.id: return "document_id"
    case \.name: return "full_name"
    default: return NSExpression(forKeyPath: keyPath).keyPath
    }
}
```

## Requirements

- iOS 16.0+ / macOS 10.11+ 
- Swift 5.5+
- FirebaseFirestore SDK

## License
**MIT License**
