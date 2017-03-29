# HHBackand-iOS-SDK
Backand SDK for iOS.

## About

HHBackand-iOS-SDK is written in Swift 3 and provides most of the functionality that the Backand REST API offers.

## Contents
* [Installation](#installation)
* [Basic usage](#basic-usage)
    * [Setup](#setup)
    * [Get items](#get-items)
    * [Create items](#create-item)
    * [Update items](#update-item)
    * [Delete items](#delete-item)
    * [User sign up](#user-sign-up)
    * [User sign in](#user-sign-in)
* [Advanced usage](#advanced-usage)
    * [Custom queries](#run-a-custom-defined-query)
    * [Bulk actions](#bulk-actions)
    * [Options & filters](#options--filters)

## Requirements

- iOS 8.0+
- Xcode 8.2

## Installation

### CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

To integrate HHBackand-iOS-SDK into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'HHBackand-iOS-SDK'
```

Then, run the following command:

```bash
$ pod install
```

### Manually

Add [Backand.swift](Source/Backand.swift) to your project in Xcode.

## Basic Usage

### Setup
Import Backand into your AppDelegate.swift:
```swift
import Backand
```
Setup the SDK in `application:didFinishLaunchingWithOptions:`

```swift
Backand.sharedInstance.setAppName("app-name")
Backand.sharedInstance.setAnonymousToken("anonymous-token")
Backand.sharedInstance.setSignUpToken("sign-up-token")
``` 

### Get Item(s)

To retrieve a single item:
```swift
let backand = Backand.sharedInstance
backand.getItemWithId("id", "ObjectName", options: nil) { result in
    switch result {
    case .success(let item):
        print(item)
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

To retrieve multiple items:
```swift
let backand = Backand.sharedInstance
backand.getItemsWithName("ObjectName", options: nil) { result in
    switch result {
    case .success(let item):
        print(item)
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

### Create item

```swift
let backand = Backand.sharedInstance
backand.createItem(["name": "Jake", "message": "Hello world!", "score": 36], name: "MessageOfTheDay", options: nil) { result in
    switch result {
    case .success:
        // Yay.
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

### Update item

```swift
let backand = Backand.sharedInstance
backand.updateItemWithId("47", item: ["message": "Hello everyone."], name: "MessageOfTheDay", options: nil) { result in
    switch result {
    case .success:
        // Yay.
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

### Delete item

```swift
let backand = Backand.sharedInstance
backand.deleteItemWithId("47", name: "MessageOfTheDay") { result in
    switch result {
    case .success:
        // Yay.
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

### User sign up

```swift
let backand = Backand.sharedInstance
let user = [
    "firstname": "First name",
    "lastname": "Last name"
    "email": "example@email.com"
    "password": "password"
    "confirmPassword": "password again"
]
backand.signUp(user) { result in
    switch result {
    case .success:
        // Yay.
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

### User sign in

```swift
let backand = Backand.sharedInstance
backand.signIn("example@email.com", password: "password") { result in
    switch result {
    case .success:
        // Yay.
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

## Advanced usage

### Run a custom defined query
Backand allows you to define queries in the cloud. Here's how you can run them:

```swift
let backand = Backand.sharedInstance
backand.runQueryWithName("query-name", parameters: nil) { result in
    switch result {
    case .success(let item):
        print(item)
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

### Bulk actions
Bulk actions allow you to perform more than one operation in a single request.

```swift
let backand = Backand.sharedInstance
let baseURL = backand.getApiUrl()
let createAction = Action(method: .POST, url: baseURL+"/1/ObjectNameHere", data: ["name": "Jake", "message": "Hi!"])]
let updateAction = Action(method: .PUT, url: baseURL+"/1/ObjectNameHere/ID", data: ["name": "Alex", "message": "Hello!"])
let deleteAction = Action(method: .DELETE, url: baseURL+"/1/ObjectNameHere/ID", data: nil)
let actions = [createAction, updateAction, deleteAction]

backand.performActions(actions) { result in
    switch result {
    case .success:
        // Yay.
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```

### Options & filters

```swift
let backand = Backand.sharedInstance

// More operator types available 
let filterName = Filter(fieldName: "name", operatorType: .Equal, value: "Jake")
let filterMessage = Filter(fieldName: "message", operatorType: .StartsWith, value: "Hello")

// More options available
let options: [BackandOption] = [
    .PageSize(10),
    .PageNumber(7),
    .FilterArray([filterName, filterMessage]),
    .ExcludeArray([.Metadata, .TotalRows])
]

// Example request
backand.getItemsWithName("ObjectName", options: options) { result in
    switch result {
    case .success(let items):
        print(items)
    case .failure(let error):
        // Ouch. Should probably do something here.
    }
}
```
