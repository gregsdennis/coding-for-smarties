---
layout: post
title:  "The Case Against Private Methods"
date:   2016-09-08 17:00:00 +1300
tags: c# code
excerpt_separator: <!--more-->
---
Yeah.  This post is titled that.

<!--more-->

## [Please, consider the following](https://youtu.be/71VT6oTto1g)

Suppose we have a class with an absurdly large method.  (For convenience, I'm going to use comments.)

```c#
class Service : IService
{
	public void DoSomething()
	{
		// initialize the process

		// a chunk of code that's used in other classes

		// prep for the next step

		// a chuck of code that's used only in this class
		// but in multiple places

		// prep for the next step

		// a chuck of code that's used only here
		// but is still somewhat distinct

		// finish up
	}
}
```

This class is suffering from a dire need to be refactored.  The reason we want to refactor this code is three-fold.

- Readability
- Eliminate code duplication
- Testability

Let's take each refactoring opportunity separately.

## Code used in other classes

This one's pretty easy actually, and fairly common.  The steps we take are:

1. Refactor the functionality into a new class.
1. Abstract an interface.
1. Inject the interface into this class (and any other classes which contained the duplicated code).
1. Use the interface instead of the code chunk.

Our class how looks like this:

```c#
class Service : IService
{
	private IMultiuseFunctionality _multiuseFunctionality;

	public Service(IMultiuseFunctionality multiuseFunctionality)
	{
		_multiuseFunctionality = multiuseFunctionality;
	}

	public void DoSomething()
	{
		// initialize the process

		_multiuseFunctionality.DoIt();

		// prep for the next step

		// a chuck of code that's used only in this class
		// but in multiple places

		// prep for the next step

		// a chuck of code that's used only here
		// but is still somewhat distinct

		// finish up
	}
}
```

Good.  Now that that's done, let's see how well we've accomplished our goals.

### Readability

The code looks a bit better.  We've isolated the code, which means less code to concentrate on.  Because we've named the interface and its method appropriately, we know what that chunk of code does, and it makes the code around its usages easier to read, too.

### Eliminate code duplication

The we've consolidated the logic into a single place.  If we need to change it (for bug fixes or enhancements), we only have to modify one portion of the code.

### Testability

Because the code is now located in an interface-implementing method, we can easily access it in a unit test.

Well done!

## Code that's used multiple times in only this class

We *could* use the exact same approach as before to achieve the same result, but this time we don't think that it's of any benefit to move the functionality into an entirely separate class since it's not used anywhere else.  A private method could handle this.

After that our class looks like this:

```c#
class Service : IService
{
	private IMultiuseFunctionality _multiuseFunctionality;

	public Service(IMultiuseFunctionality multiuseFunctionality)
	{
		_multiuseFunctionality = multiuseFunctionality;
	}

	public void DoSomething()
	{
		// initialize the process

		_multiuseFunctionality.DoIt();

		// prep for the next step

		_DoSomethingHere();

		// prep for the next step

		// a chuck of code that's used only here
		// but is still somewhat distinct

		// finish up
	}

	private void _DoSomethingHere()
	{
		// a chuck of code that's used only in this class
		// but in multiple places
	}
}
```

Not bad.  Let's see how our goals are doing.

### Readability

The code still looks a bit better from before.  We've still isolated the code, albeit locally.  Because we've named the method appropriately, we know what that chunk of code does, and it makes the code around its usages easier to read, too.

### Eliminate code duplication

The we've consolidated the logic into a single place.  If we need to change it (for bug fixes or enhancements), we only have to modify one portion of the code.

### Testability

Um... no.  We didn't improve the testability.  In order to access the code we refactored, we still have to go through the main `DoSomething()` method.

Meh.  The interface option is probably better, but we can live with this... I guess.

## Code that only used in one place but still implements distinct functionality

This is probably the hardest one to see.  It's code that generally performs the heart of the logic that the main method is intended to do.  But since it still is distinct functionality, it can be refactored into its own method.  So we use the private method approach again.

Now our code looks like this:

```c#
class Service : IService
{
	private IMultiuseFunctionality _multiuseFunctionality;

	public Service(IMultiuseFunctionality multiuseFunctionality)
	{
		_multiuseFunctionality = multiuseFunctionality;
	}

	public void DoSomething()
	{
		// initialize the process

		_multiuseFunctionality.DoIt();

		// prep for the next step

		_DoSomethingHere();

		// prep for the next step

		_DoTheThing();

		// finish up
	}

	private void _DoSomethingHere()
	{
		// a chuck of code that's used only in this class
		// but in multiple places
	}

	private void _DoTheThing()
	{
		// a chuck of code that's used only here
		// but is still somewhat distinct
	}
}
```

Okay.  Now our interface method seems relatively succinct.  But this refactoring has the same problems as before: we can't test the methods because they're private.  Ordinarily, we just deal with it.

## The remedy

As I mentioned before, one solution would be to refactor into interfaces.  But that seems like [overtaking the plumbing](https://youtu.be/mkJ3--2K7yo#t=5m44s).

I suggest continuing with the method refactor (as we did), except rather than making the methods private, they should be public!

"But wait," you cry. "if you make them public, then anyone can call them!"

True... sort of.

Note that our class is implementing an interface, `IService`.  This is because we're building our application the right way, using dependency injection and an IoC container.  That means that there should only be two references to the actual class:  the IoC container and the unit test.  Everything else should be interacting solely with interfaces.  And since these public methods are not defined on any interfaces, you have to have a reference specifically typed to this class in order to call them.

We know we're not going call any specific methods (interface or otherwise) from the IoC, and we'd like to be able to call these methods specifically from unit tests.  So I think we're good.

Now, our method is readable, we've eliminated any code duplication, and all of our chunks of code are independently testable.  Yea!

## Wrapping things up

Given that we want to be able to modularly test things, it really seems like we would want to test each chunk of code that we write independently.  We can't do that if we hide details in private methods.

***NOTE** There is an argument to be made that if we have a method with portions that we should test independently, then we **should** refactor it into separate interfaces because our class is doing to much, thereby violating SRP.  However, on occasion, even when we adhere to SRP, we can still end up with a few large methods.*

Understanding this, I can't think of a terribly convincing reason to have a method be private.

The next post will be a bit shorter, but we'll expand on this idea a bit, focusing on the IoC container.