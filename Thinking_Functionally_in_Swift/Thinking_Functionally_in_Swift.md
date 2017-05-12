# Thinking Functionally in Swift
 
The goal of this article is to show how the functional programming mindset can change the way we write our code. It is a lite introduction to functional programming using a real world example - parsing a server JSON response into a model.
 
There is one core concept that is going to drive our thought process. We're going to think of each step in the process as a transformation independent of variables that are not passed into our function.
 
### Real World Example: Parsing a JSON Response from a Server
 
 In order to create models from the data we receive, we are going to perform two transformations:
 
 1. Transform the received data into a JSON object.
 2. Transform the JSON object into a model.
 
#### Transformation 1: Data to a JSON Object.
 
If you read the docs for [`JSONSerialization`](https://developer.apple.com/reference/foundation/jsonserialization), you'll notice one of the rules for valid JSON is:
 
> All objects are instances of `NSString`, `NSNumber`, `NSArray`, `NSDictionary`, or `NSNull`.
 
Since there are a limited number of cases, this seems like a good situation to use an `enum`.

```Swift
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
```

With the `JSONObject` type defined, we can now define a type that allows us to transform `Data` into a `JSONObject`. In functional programming, types are defined by their method signature.

```swift
typealias Deserialize = (Data) -> (JSONObject?)
```

To use this type, we write a function that returns our new `Deserialize` type.

```swift
func JSON() -> Deserialize {
    return { data in
        do {
            return try JSONObject(JSONSerialization.jsonObject(with: data, options: .allowFragments))
        } catch {
            return nil
        }
    }
}
```

#### Transformation 2: JSON Object to a Model
 
Since we don't have any models defined yet, all we need to do for this step is define a type that accepts a `JSONObject` as a parameter and returns some type `T`:

```swift
typealias Decode<T> = (JSONObject?) -> (T?)
```

And that's it, that's all the code we need to start creating models from JSON!
 
#### Putting It All Together
 
Let's derive a simple example to show what it looks like to interact with this code. For this example, we're going to expect the server to send us information about a particular user.

```swift
struct User {
    let avatarURL: URL?
    let firstName: String
}
```

Now we can write a function that allows us to transform a dictionary into a `User`.

```swift
func decode<T>(valueForKey key: String, inDictionary dictionary: Dictionary<String, Any>?) -> T? {
    guard let dictionary = dictionary, let object = dictionary[key] as? T else { return nil }
    return object
}

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
```

The proof is in the pudding as they say, so let's see what our functional code looks like.

```swift
let userJSON: [String: Any] = [
    "FirstName": "Tyler",
    "AvatarURL": "https://upload.wikimedia.org/wikipedia/commons/thumb/3/3c/William_Howard_Taft_1909b.jpg/1200px-William_Howard_Taft_1909b.jpg"
]
let userData = try JSONSerialization.data(withJSONObject: userJSON, options: [])
let user = decodeUser()(JSON()(userData))
```

And just to prove that it works as expected

```swift
let imageData = try Data(contentsOf: user!.avatarURL!)
UIImageView(image: UIImage(data: imageData))
```



### Additional Resources

A Swift playground is available 

If you're curious about learning more about functional programming, here are some resources that I've found particularly interesting/informative.

- https://purelyfunctional.tv
- https://fsharpforfunandprofit.com/video/
- https://www.destroyallsoftware.com/talks/boundaries
- http://2017.funswiftconf.com
- λπω.com
- http://learnyouahaskell.com
