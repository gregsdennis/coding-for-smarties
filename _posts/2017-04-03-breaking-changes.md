---
layout: post
title:  "Breaking Changes"
date:   2017-04-03 17:00:00 +1300
tags: nuget package version
excerpt_separator: <!--more-->
---
Today we're going to talk about breaking changes in libraries.  Specifically, we're going to answer the following:

- What constitutes a breaking change?
- How can I avoid making breaking changes?
- When is a breaking change a good idea?
- How do I indicate that a new version contains a breaking change?

<!--more-->

## What constitutes a breaking change?

A breaking change is any change which modifies the **public interface** to a module in such a way that causes any consuming modules to fail either at compile-time or run-time.  In other words, any change which requires consuming code to change in order to maintain the same behavior.

***NOTE** In this post, we're only going to cover compile-time breakages.  Run-time breakages only occur when the intended behavior of a module changes.  We're going to assume that we want the same (or additional) behavior as the previous version.*

In order to explore this further we need to first consider the code which consumes our library.  This code relies on certain types which are defined by our library.  When these types change, the code which uses them is affected.

There are three basic types of compile-time changes that a library can have:

1. Adding new types
1. Modifying existing types
	1. Adding members
	1. Removing members
1. Removing types

The last one (removing types) seems obvious.  If we remove a type that a consumer is using, the code which references that type will no longer compile.  This is always a breaking change.

Conversely, if we add new types, any code which references the library can't have references to the new types, so this is a non-breaking change.  (No harm, no foul.)

This leaves us with modifying types.  For this, we need to break it down a bit further into the kind of type that is modified.

### Concrete types

Concrete types are well-defined and complete.  That is, they don't have any other types depending on functionality that isn't defined in either the class itself or a base class.

Given that, changes to their members are analogous to changes to the library's type offerings: adding members causes no pain, while removing members could break consumers.

### Abstract types

Abstract types are a bit different, however.  The contract they define is a list of requirements for implementers.  So by adding a member to an abstraction, any implementers must now implement this new member.  Since we must consider that consuming code *may* provide an implementation, any new functionality that **must** be implemented now breaks that implementation.  So adding members to an abstract type is a breaking change.

Removing members is even trickier.  If we remove a member from an abstraction, then implementers are no longer *required* to provide that functionality, but if they do, it's fine.  Any consumer-defined implementations will simply have code that's not needed any more; we're not *requiring* that the consumer remove this portion of code.

But then we have to consider that there may be code that depends on that method being on the abstraction (Dependency Inversion Principle).  This code will break when we remove the member.

This means that *any* change to an abstraction should be considered a breaking change.

***NOTE** In .Net (and other frameworks) we have abstract classes as an abstraction type.  These abstractions can also define their own implementations.  This is the exception to the above rule: if an abstract class adds functionality *and* provides its own implementation, then the change is like an addition to a concrete class and is non-breaking.*

## How can I avoid making breaking changes?

In short, use the language and framework tools you have available.  In .Net, this means function overloading and use of the `Obsolete` attribute.

The general idea is to give the author of the consuming code the choice of whether to update their code immediately or defer updating until it's more convenient for them and their process.  (Maybe they don't have the time right now to update, so they log some tech debt and carry on their merry way.)

### Function overloading

Many times a change will add or modify the signature of a method or property.

For properties, rather than changing the property, to you'll want to add a new property, perhaps similarly named, and document that the old property is now defunct.

For methods, (in languages that support it) you can add an overload (same name, different parameters or return).

### The `Obsolete` attribute

In .Net, we have the `Obsolete` attribute.  This is a nice compiler-sensitive option that tags a member as being... well... obsolete.  The benefit of this attribute is that the compiler will generate a warning for any usages of the attributed member.  This provides an easy link for your consumers to follow in their quest to update their code.

## When is a breaking change a good idea?

Breaking changes are typically used in several cases.

- Maybe you made a large refactor to the public interface because you found an easier way to use your library (e.g. converted to a fluent interface).
- Maybe you found that you needed a new parameter to perform some functionality, and the old way just won't work anymore (e.g. you need a security token for an API that didn't need it before).  In cases like these, overloading won't work because the old functionality will just throw a run-time exception anyway.
- Maybe half of your code base is marked obsolete because you've been avoiding a breaking change, and it's time to perform some housekeeping.
- Maybe you found a scenario that I haven't run across, and you think a breaking your consumer's code is warranted.

Most of the time, you want to avoid publishing breaking changes because working with code that's constantly changing is a headache, and you don't want that for your consumers.  But sometimes it's necessary, and ultimately it's up to you to make that call.

## How do I indicate that a new version contains a breaking change?

This is probably the nicest benefit of following a semantic versioning scheme.  We've discussed [versioning of libraries](https://codingforsmarties.wordpress.com/2016/01/21/how-to-version-assemblies-destined-for-nuget/) before on Coding for Smarties, so many of you may see where this is going.

The idea behind semantic versioning is that the change in the version number indicates the type of change in the library.

- For bug fixes and internal updates *that the consumer will never see*, we increment the last number (semantic versions have three numbers)
- For augmentations and other non-breaking changes *that the consumer will see*, we increment the minor version (the second number).
- For breaking changes, we increment the major version (the first number).

Thus we increment the first number and reset the others to zero. (5.2.1 → 6.0.0).

The thing to remember here, though, is that most of us are used to application versioning, where a jump in major version usually corresponds to a large overhaul of the app.  Library versions are different though.  Just because we have a bump in the major version, it doesn't necessarily follow that an overhaul has taken place.  Such a change *may* have occurred, but we don't know.  We just know that something changed that *may* cause problems.  (We don't even know if the breaking change affects us.)

It's our consumption of versions of things that shapes our perception of how we should version our things.  Higher versions tend to imply older product but may merely indicate growth.  ("You're on version 3 already?!  You just released version 1 last month!")  We need to remember that in the end, it's all just numbers.  It's better to have those numbers be meaningful somehow.  Once that clicks, it doesn't matter so much what the numbers are.

***BONUS** And don't skip numbers; that's just confusing.  (Angular, I'm looking at you.)*