---
layout: post
title:  "Overriding Static Members in C#"
date:   2018-02-20 17:00:00 +1300
tags: c# language deep-thoughts
excerpt_separator: <!--more-->
---
Yeah, you read that right.  We're gonna break some rules!

<!--more-->

***NOTE** I feel I must apologize for my absence. I've been really busy over the past year.  New job, new house, all my stuff from TX finally arrived, had family visit (twice), Manatee.Trello and Manatee.Json picked up some activity, *and* I started participating in the JSON Schema discussions over at their GitHub repo for the specification.  I appreciate the reader's patience.*

One of the things that every C# developer should know is that you **cannot** declare static members as abstract or virtual and, therefore, cannot override them.  You *can* created *new* members with the same name, but that doesn't have the same behavior as inheritance.  Just for completeness, let's review how the `new` keyword works before we depart from sane development practices.

## `new`

Suppose we have a class with a member.  It could be a property, method, event, or a field.  For this example, we'll use a property.

```c#
public class ExistingClass
{
	public string Name { get; set; } // "Cat"
}
```

Nothing strange here.

Now suppose we want to inherit this class and override the `Name` property.  We can't override it because it's not virtual.  So we just recreate the property in our class.

```c#
public class MyClass : ExistingClass
{
	public string Name { get; set; } // "Dog"
}
```

Now Resharper (or the compiler) is complaining that we can't override this method and suggests that we put the `new` modifier on it.  Okay, sure.

```c#
public class MyClass : ExistingClass
{
	public new string Name { get; set; } // "Dog"
}
```

There.  No more whining.

But it still behaves... oddly.

```c#
var myClass = new MyClass();
var as3rdParty = (ExistingClass) myClass;

Console.WriteLine(myClass.Name);		// "Dog"
Console.WriteLine(as3rdParty.Name);	 // "Cat"
```

When we have a variable that is of type `ExistingClass` the original implementation is used.  This is the effect of the `new` keyword: it breaks polymorphism.  And while it *can* allow us to redefine some behaviors, we need to be very careful where and how we use it.  If anyone calls a redefined property while looking at the base class, they're going to get the base property, **not** the new one.

To properly get polymorphism, we need to make `ExistingClass.Name` virtual and override it in `MyClass`.

## Breaking the rules

Now, making members virtual is all well and good if they're defined on the instance.  But what if they're static?  C# explicitly disallows this.  Most architects would say, "You're doing it wrong."  I'd agree with them.

But just for fun, let's do it anyway.

We're going to start by creating a static class with a static property.

```c#
class Program
{
	static void Main(string[] args)
	{
		Console.WriteLine(Test.Value);
	}
}

public static class Test
{
	public static string Value { get; } = "start";
}
```

So far nothing squirrelly.  We run the app, and we see "start" printed to the console.  But there's no way we can change that value, right?  Maybe.

Let's start by converting this from a static class to a singleton, but we'll leave `Value` static so that we don't break any existing code.

```c#
public class Test
{
	public static Test Instance { get; }

	public static string Value { get; }
}
```

Then we get weird.  We're going to make this a partial class and declare a partial method.  While we're at it, we're going to break `Value` as an autoproperty and call the partial method on the instance before returning the backing field.

```c#
public partial class Test
{
	private string _value = "start";

	public static Test Instance { get; } = new Test();

	public static string Value
	{
		get
		{
			Instance.SetValue();
			return Instance._value;
		}
	}

	partial void SetValue();
}
```

Let's go through this.  When we call `Test.Value`, the property getter is then going to call `SetValue()` *if it exists* before returning the backing field.  If it *does not* exist, the compiler ignores the call as if it were never there!  This allows us to optionally create another part to this class that then defines `SetValue()` which has all the authority to set `_value`.

```c#
public partial class Test
{
	partial void SetValue()
	{
		_value = "changed";
	}
}
```

Now when we run our app, we get the text "changed" printed to the console instead of "start".

It's important to note however that partial classes cannot be defined across assemblies.  They're really supposed to be used to split an absurdly large class (you're doing it wrong) into multiple files or, in some cases, to share code in cross-platform development (because not all code works on all platforms).

## How does that help me?

It probably won't.  Maybe if you're doing cross-platform development, you can use this, but I'd suggest looking at other ways of modeling your classes.

I developed this to help us over a hurdle at work, where we had base tests that were run on all of our APIs by using a shared project (because they're in separate solutions), and we were using a testing framework that required that test data come from a static method.  We had that method defined in the shared project and it would auto-generate the required domain models.  It's quite impressive, really. (No, I didn't do it.)

I needed to override the data for one endpoint...  This is what I came up with.  It's hacky, but it works.

I don't suggest you use it, but if you're up against a wall, here it is.