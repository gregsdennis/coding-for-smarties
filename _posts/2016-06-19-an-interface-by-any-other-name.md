---
layout: post
title:  "An Interface by Any Other Name"
date:   2016-06-19 17:00:00 +1300
categories: c# language code deep-thoughts
excerpt_separator: <!--more-->
---
We're going to take a brief break from our series on plug-ins to explore an idea that I had regarding naming conventions, specifically interface naming in .Net.

<!--more-->

For those of you who program in frameworks other than .Net, this may not apply in your world.  But in the .Net world, interfaces are like contracts for types.  Their sole purpose is to identify a set of functionality that will be implemented in a concrete type.  Any type can be made to implement any interface, or even multiple interfaces.  Wait... this is turning into a discussion of the merits of interfaces.  That's not what this post is.

Instead, I'm going to blow your mind with by changing a long-standing convention:

> Interfaces are named `I`*`WhatItIs`*.

For example, a common interface in WPF is `IValueConverter`, and typically classes that implement it are called *`WhatItConverts`*`Converter` (e.g. `FeetToInchesConverter`).  And the code looks like

```c#
class FeetToInchesConverter : IValueConverter
{
	... // implementation stuff
}
```

This is the usual pattern.  We think of the class name, slap an `I` in front of it, and we have an interface name.  This is even the approach that most code analyzers (like Resharper) take when refactoring code to extract an interface from a class.

---

I propose we drop the current convention in favor of a new one.  Instead of naming our interfaces like classes (what it is) we should name them by what they do.  It's a subtle difference.  It's changing the focus from the noun (or adjective) to the verb.  The interface mentioned above would then become `IConvertValues`, and the class would look like

```c#
class FeetToInchesConverter : IConvertValues
{
	... // implementation stuff
}
```

As another example, take a look at `ICommandManager`, probably extracted from some class called `CommandManager`.  This would become `IManageCommands`.

The primary benefit produced by this naming convention is code readability.  *Hi.  I'm `FeetToInchesConverter`.  I convert values... from feet to inches.*

Also, this is totally legal in just about every .Net version because it's just a renaming.

Some interfaces get a little weird, though.  Specifically the ones that describe model types (e.g. `ISerializable`) and generics (e.g. `ITypeConverter<TFrom, TTo>`).  For model types, you'd have to insert a verb that's not there, and it just doesn't feel... right (`IAmSerializable`,  or `ICanBeSerialized` (ew)).  For generics, well...

VB.<span></span>Net
```vb
	Class PointToVectorConverter
		Implements IConvertTypes(Of Point, Vector)
```

C#
```c#
	class PointToVectorConverter : IConvertTypes<Point, Vector>
```

Now that I've seen those, I don't really see much improvement. Maybe it's just good for service-defining interfaces.

Regardless, I'm going to try this with my next open source library.  If it doesn't work out, I'm going to delete this post and pretend it never happened.