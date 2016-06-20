# ER Locator

A prototype developed by Jeffrey Fulton aimed at getting rural Manitobans to the nearest open emergency room as quickly as possible.

## Problem

Rural Manitobans in need of emergency medical services currently do not know which of the surrounding hospitals have emergency personnel on staff. Currently they need to call ahead to each one individually. Forgetting to call ahead can result in a patient driving to a hospital only to discover they need to backtrack in the opposite direction towards the hospital handling emergency services that day.

## Solution

ER Locator uses location services on the device to lookup the nearest hospitals with emergency personnel on staff. Users are then instructed to call ahead and get turn-by-turn directions with "call" and "directions" buttons built into the app. Poor network conditions common in rural areas are gracefully handled by falling back to cached data and updating the UI accordingly. i.e. Schedule information is replaced with "Possibly Closed" and "Call Ahead".

## Getting Started

In order to run this application in your development environment you will need to:

1. Change the Bundle Identifier in Xcode to your own.
2. Add the iCloud entitlement to your App ID from the capabilities pane in Xcode.
3. Open your CloudKit Dashboard in a web browser and add the following Record Types:
  - ER: (location: `Location`, name: `String`, phone: `String`)
  - ScheduleDay: (date: `Date/Time`, er: `Reference`, firstOpen: `Date/Time`, firstClose: `Date/Time`)
  - ScheduleRole: (stringField: `String`)
4. Add some ER records.

Authentication rules are handled almost entirely in the CloudKit Dashboard by:

1. Creating a `Scheduler` Security Role.
2. Limiting SchduleRole read access to the Scheduler role and disabling all other access.
3. Limiting ScheduleDay write access to the Scheduler role.

## Technologies Used

I used this opportunity to explore a number Apple technologies and design patterns including:

- CloudKit
- Swift Generics
- Protocol-Oriented Programming
- Concurrency with NSOperationQueues

### CloudKit

CloudKit is a "backend as a service" provided by Apple which provides authentication, a private and a public database, and structured asset storage services. ER Locator is using authentication and the public database only. See Apple's documentation for more info: http://apple.co/28J29xx

Authentication is based on the Apple ID signed into iCloud on the device. This negates the need for a custom sign-in/up UI and creates a seamless experience for users. 

Everyone has access to the main ER Locator functionality of the app, with or without signing into iCloud. However only authenticated users granted the "Scheduler" role are able to access the Scheduler functionality of the app.

### Swift Generics

Generics is a feature of the Swift language which significantly reduces code duplication while maintaining type safety. It can be confusing at first but is fairly straight forward and hugely powerful.

As my first foray into programming with generics, I used it throughout this project as much as is reasonable... and maybe a little more than that. See Apple's documentation for more info: http://apple.co/28JseZF

### Protocol-Oriented Programming

Apple introduced the concept of Protocol-Oriented Programming at WWDC 2015 and I'm still getting a feel for it. The concept is very similar to "Coding to the Interface" in Java. I'm sure other languages have similar concepts.

The idea is to write a "protocol" defining required properties and methods, create a type which conforms to the protocol, then only ever refer to these types by the protocol rather than directly by their type name. This enables you to switch out that type for any other type which adopts/conforms to the required protocol. Great for unit testing and code portability.

I've attempted to use Protocols as much as possible, often in conjunction with Generics, to reduce coupling between types and improve testability. While this has made the code a little harder to read, my gut feeling is it's worth it.

See the 2015 WWDC session video "Protocol-Oriented Programming in Swift" for more info: http://apple.co/28JslEx

### Concurrency with NSOperationQueues
Speaking of making the code harder to read...

There is no question: concurrent/multi-threaded programming is hard. NSOperationQueues make it much easier by modularizing functionality into independent "operations" which can be run asynchronously and allowing you to define dependencies when one operation cannot start before a different operation completes. NSOperationQueues also enable advanced features like re-prioritizing and cancelling operations already in the queue. 

This is hugely powerful... but makes the code very hard to read. I endeavoured to use NSOperations as much as possible in this project to gain experience with them. However this may not have been the best place to use them. The additional complexity of the code may not be worth the additional features provided. 

See Apple's Concurrency Programming Guide for more info: http://apple.co/28Juq3e

