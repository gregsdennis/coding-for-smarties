---
layout: post
title:  "C# 8 Features I Don't Hate"
date:   2019-11-20 17:00:00 +1300
tags: c# language rave
excerpt_separator: <!--more-->
---
I expect my readers are wondering where my continuation of the *C# x Features I Don't Like* series is for version 8.  Well, I'm sorry to disappoint, but I won't be continuing that.  I'm trying to make a change and be less grumpy about things.  I consider it growth.  Deal with it.

So instead, let's go over the new feature set with a bit more openness and optimism.  This isn't to say that I think all of these features are amazing additions or that I'm excited about all of them, but I will be a bit more accepting of their inclusion into the language.

<!-- more -->

## C# 7 in review

As was established by the previous iteration of the language series, let's start off by reviewing the C# 7 features I covered before and see if and how I use them.

- **Out variables** - Yes.  This is nice.  I like being able to declare a variable as part of the function that is used to initialize it.  It's analogous to the shift from having to declare *then* initialize your variable to being able to declare *and* initialize in one statement.
- **Pattern matching**
  - **Is-expression matching** - I use the variable declaration variation of this.  It has the same utility as `out` variables.  I still haven't found a need for the constant variation, though.  (I just read "constant variation" and giggled at my cleverness.)
  - **Case-expression matching** - This is useful as well, especially in scenarios where your switch target implements some interface and you have to do something different depending on what implementation it is.  Personally, I think employing a visitor or abstract factory pattern is a better approach, architecturally, but I can see this as a good quick'n'dirty alternative.
- **Tuples** - I have used this a couple times to return multiple values as an alternative to `out` variables, but I use it sparingly.  I still think it's little more than a returnable anonymous type.
- **Deconstruction of tuples** - Again, just allows returning multiple values.  This is just the other end of the rope.
- **Local functions** - Nope.  Don't use them.  Haven't found a time when I need them.  Just create a proper method or use a lambda.
- **Literal improvements** - Digits separation and binary literals.  Honestly, I forgot this was a thing.  The only general (non-special-case) use for binary literals I can think of is on a `Flags` enum, but even then using something like `1 << 4` is easier in my opinion.  Maybe you're doing a lot of bit-logic, say over a serial port...
- **Ref returns and locals** - I haven't used this either.  Don't really think I've had a scenario where it'd be helpful, either.
- **Generalized async return types** - Never saw an example of this, but I think it's the foundation for things like async streams.
- **More expression-bodies members** - Yeah, I avoid expression-bodied things like the Plague.  They're properties and methods, not lambdas.  I like my braces.
- **Throw expressions** - I like that we can finally throw exceptions from behind a null-coalescing operator (`??`) and inside a conditional operator (`? :`).  This cleans up code quite a bit.

Yeah, I'm pretty used to some of these.  The ones I don't use seem to be edge case usage: they're there if I need them, but I haven't needed them yet.

Let's get on with C# 8 then.

## Another player has entered the game

I'll be going through [this list](https://docs.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-8#switch-expressions) published by Microsoft.  They give some examples and details that I won't get into here.

> <small>Honestly, in typing this list, I realized that I haven't read much about many of these.  Let's see how this goes!</small>

### Readonly members

This allows adding the `readonly` keyword to methods and properties.  It's basically a signal to the compiler that you intend that member to be read-only and so it should only utilize other read-only members.  If it happens to access a writable member, then you'll get a nice compiler warning to let you know.

It's kind of like how you'd get a warning when you overrode `GetHashCode()` but included a mutable property; this feature extendeds that behavior to other methods.

I *may* use it, but I'll have to try it out to get a feel for it before I really incorporate into my default coding style.

### Default interface methods

I'm not really a fan of this.  I can see the utility, but I think it's counter to what an interface is.  It's blurring the line between an interface and an abstract class.

That said, one neat benefit is that you can now add members to an interface without it being a breaking change.  (See [my post on breaking changes](../../../2017/04/03/breaking-changes.html) for why *adding* a member to an interface would be breaking.)

I'll probably not use this personally, but it may someday solve a problem at work.

### More patterns

#### Switch expressions

This isn't so much a pattern as expression-bodied switch statements.  You've read my feelings on expression-bodied things, but I think this one is decent.  The Microsoft article shows a good example of how well it can clean up a simple returning switch statement.

This also enables switch statements in expression-bodied members.  Yuck.  I wonder if the switch expression *must* be used within an expression-bodied member...  I hope not.

#### Property patterns

This extends switch expressions so that they can key off of more complex objects based on property values.  The example in the Microsoft article shows it being used with a single property match, but it *may* work with multiple properties.  This seems niche but useful.

#### Tuple patterns

A single switch statement on multiple values.  What a time to be alive!  I wonder if this is converted to nested switch statements by the compiler.

#### Positional patterns

This is like defining an implicit cast between a POCO and a tuple.  Weird.

What this also enables is switch statements that deconstruct a POCO, evaluate the values *conditionally* (not by discrete values), and return accordingly.  The example they give is neat, but I'm struggling to determine when I'll be able to use this.

### Using declarations

This is pretty cool.  It's a bit related to a feature request that I put in about [allowing `using` on fields](https://github.com/dotnet/csharplang/issues/1451).

This is scoped to within a method.  Instead of requiring braces, a disposable variable can be declared with `using`.  It will be in scope for the remainder of the method, then it'll be cleaned up when the method exits.

Note that this may not be the desired effect.  In C# 7, if your using statement ends before the end of the method, it'll be cleaned up earlier than in C# 8.  It may not be of much consequence, but it *is* different, so be wary.

### Static local functions

More local functions.  Now they can be static.  Why?

Methods that are private to methods.  *Why?*

### Disposable ref structs

Apparently there is a requirement that a ref struct can't declare any interfaces.  I'm not sure why this requirement is there, but I don't use this feature of C# 7 anyway.

This allows these structs to be disposed by (I guess reflectively) checking if they implement a `void Dispose()` method and calling it if they do when cleaning up the class.

### Nullable reference types

*[Inhales deeply in an effort to subdue the rage]*

This one has everyone excited, and I can't figure out why.  It flies in the face of one of the basic premises of .Net: there are value types, which are stored on the stack, and reference types, which are stored on the heap.  (It's a staple interview question!)  Because they live on the stack, value types are non-nullable.  To make one nullable, there is the `Nullable<T>` struct (which is itself non-nullable) which also has the special syntax `T?`.  However, reference types are analogous to C/C++'s pointers (except much safer), and so are *by their nature* nullable.  Reference types point to some other object in memory.  When they don't point to an object, they're null.

This feature now turns all that around, saying reference types are no longer nullable by default.  instead, to make it nullable, we now have to add a `?` after the type, like a value type.

So where `MyType?` used to be easily readable as, "`MyType` is a struct, and I really want `Nullable<MyType>`," we now have to contend with the possibility that `MyType` is a class, and it's not wrapped in a `Nullable<T>`.

It's really just a compiler trick, but it's one that I don't think we need.

To completely disprove my point, Jon Skeet [wrote a post](https://codeblog.jonskeet.uk/2019/02/10/nullableattribute-and-c-8/) about his efforts to convert his NodaTime library to use nullable reference types, and he found a number of bugs.  So... ¯\\\_(ツ)_/¯

Personally, I think this is the wrong approach to solving the problem.  I think a `[NotNull]` attribute (like the one implemented by Resharper's analysis engine) is better because it doesn't change how we read the language.

Fortunately, they're opt-in (for now), so I don't have to update all of my code to take advantage of the other features listed here.

### Async streams

Not quite what I expected when I read "stream," this is really async enumerables.  A new interface `IAsyncEnumerable<T>` has been introduced, and it's consumed using an `await foreach` statement.

I expect that `IAsyncEnumerable<T>` will be used by the framework in places, so I'll be forced to use this one.  I can see where you'd want to async operation from within Linq-style extension methods, so I think this is a good addition.

### Indices and ranges

Well, I guess I need to update [my implementation of this for JSONPath](https://github.com/gregsdennis/Manatee.Json/blob/master/Manatee.Json/Path/Slice.cs).  It'd be nice to have something in-built to do this for me.  (It's probably faster anyway.)  Plus, it has its own syntax!

### Null-coalescing assignment

From the Microsoft page:

```c#
List<int> numbers = null;
int? i = null;

numbers ??= new List<int>();
numbers.Add(i ??= 17);
numbers.Add(i ??= 20);

Console.WriteLine(string.Join(" ", numbers));  // output: 17 17
Console.WriteLine(i);  // output: 17
```

What?!  I'm not even sure this is useful, but... sure!

```c#
numbers.Add(i ??= 17);
```

So here, they're saying, "use `i` if it's not null, otherwise use 17 *and* assign 17 to `i` for next time.

I *can* see it being useful for lazy properties, maybe...

```c#
private MyService _service;
public MyService Service => _service ?? (_service = new MyService());
```

becomes

```c#
private MyService _service;
public MyService Service => _service ??= new MyService();
```

I guess.  (Yes, I'm aware that I just used an expression-bodied property.  Read-only properties are the *only* case where I do.)

## Summary

There are a few other features that I didn't mention, but they're pretty low-level stuff that most people won't use.

Aside from null reference types (*[breathe, Greg...]*), these seem a fairly decent feature set, and I see myself using a few of them soon.

Overall, I think that language improvements should enable functionality that was previously impossible or at least really difficult or cumbersome.  This is the first upate since C# 5 (introduced `async`/`await`) that really does this.  The past two versions seem to have only given us "pretty" ways of doing things we could already do (I'm looking at you, expression-bodied members).