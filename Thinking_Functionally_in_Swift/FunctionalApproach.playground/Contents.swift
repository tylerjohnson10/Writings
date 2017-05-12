import UIKit

// Shared Code

enum JSONObject {
    indirect case array([JSONObject?])
    case dictionary([String: Any])
    case null
    case number(Int)
    case string(String)
    
    init?(_ object: Any?) {
        if let dictionary = object as? [String: Any] {
            self = .dictionary(dictionary)
        } else if let integer = object as? Int {
            self = .number(integer)
        } else if let string = object as? String {
            self = .string(string)
        } else if let array = object as? Array<Any> {
            self = .array(array.map { JSONObject($0) })
        } else {
            self = .null
        }
    }
}

struct User {
    let avatarURL: URL?
    let firstName: String
}

/* Functional Programming Approach */

// Conversion of Data to JSONObject

typealias Deserialize = (Data) -> (JSONObject?)

func JSON() -> Deserialize {
    return { data in
        do {
            return try JSONObject(JSONSerialization.jsonObject(with: data, options: .allowFragments))
        } catch {
            return nil
        }
    }
}

// Conversion of JSONObject to Model

typealias Decode<T> = (JSONObject?) -> (T?)

// Helper for Decoding JSON

func decode<T>(valueForKey key: String, inDictionary dictionary: Dictionary<String, Any>?) -> T? {
    guard let dictionary = dictionary, let object = dictionary[key] as? T else { return nil }
    return object
}

// Creating a User from a JSONObject

func decodeUser() -> Decode<User> {
    return { json in
        guard let json = json, case .dictionary(let dictionary) = json else {
            return nil
        }
        
        guard let firstName: String = decode(valueForKey: "FirstName", inDictionary: dictionary) else {
            return nil
        }
        
        let avatarURL = decode(valueForKey: "AvatarURL", inDictionary: dictionary).flatMap { return URL(string: $0) }
        
        return User(avatarURL: avatarURL, firstName: firstName)
    }
}

// Example Usage

let userJSON: [String: Any] = [
    "FirstName": "Tyler",
    "AvatarURL": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/William_Howard_Taft_1909b.jpg/1200px-William_Howard_Taft_1909b.jpg"
]
let userData = try JSONSerialization.data(withJSONObject: userJSON, options: [])
let user = decodeUser()(JSON()(userData))

let imageData = try Data(contentsOf: user!.avatarURL!)
UIImageView(image: UIImage(data: imageData))

