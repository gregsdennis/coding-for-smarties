# C# 7 Features I Don't Like

It's that time again!  Time for my inner grumpy old man to come out and describe all that is wrong with the development of C# as a language!

But before we dive in to C# 7, let's review [my criticisms of C# 6](https://codingforsmarties.wordpress.com/2015/04/21/c-6-features-i-dont-like/) and compare that to how I have adapted.

## C# 6, one(ish) year later

So as it turns out, I use quite a lot of the new features.

- **Null-Conditional Operator** - Yeah, I use this all the time.  It's very handy.
- **Auto-Property Initializers** - I've used this once, and that was in an object builder for unit tests.  I still don't like the syntax, and I'd probably use the feature more if it were expressed differently.
- **Primary Constructors** - This one didn't make the final cut (thankfully).
- **Expression-Bodied Members** - I've used this only on read-only properties and only because Resharper suggests that I do.  I could turn it off, but I really don't care.  The syntax is a little terser than writing a `get` with a `return`, but I don't think it has improved my efficiency as a coder at all.
- **Static Using Statement** - Nope.  Haven't used this one.  I still think it detracts from readability.
- **Declaration Expressions** - This one didn't make the final cut for C# 6 either, but it *did* land in C# 7, so we'll discuss this a bit later.
- **Async/Await in Catch/Finally blocks** - Nope.  Don't use this either.  I haven't had a need to, though.  Probably will once the need arises.
- **Exception Filters** - I liked this feature, but sadly it didn't make the final cut either.  *And* it didn't make C# 7!
- **`nameof()` Expressions** - This is nice, too.  I use this constantly.
- **String Interpolation** - I use this one, but it's useless when you have your format string stored away in a resources file (*.resx*), which is what you do when you want a localized app.
- **Dictionary Initializers** - I've used this a few times.  Because they're in the public domain, I've updated my open-source libraries to use them, but beyond that I typically stick to the traditional initializers.

So overall, it seems that I've come to terms with C# 6.  Interesting.

## Bump the version

Let us now take a look at all the syntactic goodness that C# 7 claims to offer.

*For those interested, I'm following [this list](https://docs.microsoft.com/en-us/dotnet/csharp/whats-new/csharp-7) of features.  Occasionally, I'll use their examples.*

### Out variables

This is the same feature as *Declaration Variables* that didn't make C# 6.  I'm not sure why they changed what they're calling it, but my opinion is the same.  I think this is a good addition.

The part I'm not quite sure of is the "discard" variable.  Basically, when you have an `out` variable that you don't care about, you can substitute the declaration (type and variable name) with an underscore (`_`) and the compiler will generate a variable for you.  I think it's a bit weird because in any other scenario, the underscore is a valid variable name, and this creates a special case for it.  Still, `value` is a valid name anywhere except in property setters, so maybe I'll get used to it.

```c#
// We don't care about the second output.
// The compiler will generate something so that it works.
SomeMethod(out int i, out _);
```

I'm not terribly sure if the discard variable works for multiple `out` variables simultaneously, but I imagine it probably would.  The C# team is pretty good at covering those types of scenarios.

### Pattern matching

This one is both nice and horrible.  Pattern matching allows us to query what *shape* an object is.  It comes in two flavors, and they're planning on adding more as the need or desire arises.

#### Is-expression matching

This extends the `is` keyword to support patterns.

```c#
myVar is [some constant expression]
myVar is [some variable declaration]
```

I'm not so sure about the `is <constant>` one.  The only examples I've seen have the constant as `null`.  I can't tell a difference between this expression and just a plain equality comparison.

But the variable declaration one seems useful, and the idea looks to merge in with the out variables.  So now, instead of doing this

```c#
int i;
if (someObject is int)
	i = (int)someObject;
else return;
Console.WriteLine($"value = {i}");
```

*See how I used string interpolation from C# 6?*

now you can do this

```c#
if (!(someObject is int i)) return;
Console.WriteLine($"value = {i}");
```

It makes sense.  I may use this.

#### Case-expression matching.

The other one extends the `switch`-`case` statements to allow us to switch on any object, not just primitive types (and enums).  It also allows us to provide non-constant values or even type patterns as the cases.

```c#
Shape shape = [something];
switch (shape)
{
	case Circle c:
		Console.WriteLine($"This is a circle with radius {c.Radius}.");
		break; 
	case Rectangle s where s.X == s.Y:
		Console.WriteLine($"This is a {s.X} x {s.Y} square.");
		break; 
	case Rectangle r:
		Console.WriteLine($"This is a {s.X} x {s.Y} rectangle.");
		break; 
	default:
		Console.WriteLine("I don't know what kind of shape this is.");
		break;
	case null:
		throw new Exception("What have you done?");
}
```

This seems useful.  We've all wanted to switch on types.  I've even created a few classes that will allow me to do that.  This makes those masterpieces defunct.  Thanks, ~Obama~ Microsoft.

### Tuples

This is no more than allowing methods to return anonymous types.  I'm not sure why they called them "tuples."

The feature looks like this:

```c#
(string, string, string) LookupName(long, id)
{
	[do the lookup]
	return (first, middle, last);
}
```

To access the return values, you take the object that's returned (yes, it's still a single object) and use properties `Item1`, `Item2`, and `Item3`.  Thus is the pattern.

There are other options, like creating labels for your return properties (just like anonymous types).  This will change the property names used.

All in all, it's just "methodizing" anonymous types.  For example, this is old news:

```c#
var names = people.Select(p => new {p.First, p.Middle, p.Last});
```

Same thing.  `names` is now an `IEnumerable<<<<SomeCompilerGeneratedType>>>>`.  Why give the feature a new name?  That's just confusing.

### Deconstruction of tuples

This is a quite a new feature, though.  For some reason, they had to do the tuples in order to pull this off, though.

So let's say you have received your tuple from the method above, and you want to store all of the properties in separate variables. (I'm not really sure why; you just want to.)

This

```c#
class Name { ... }

...

var name = LookupName(<some id>);
var first = name.First;
var middle = name.Middle;
var last = name.Last;
```

turns into this

```c#
var (first, middle, last) = LookupName(<some id>);
```

And just like the new out variables, you can use an underscore for any values you don't care about.

Functionally, you don't gain anything, but I can see where it could clean up code quite a bit.

### Local functions

This is the one that I really don't understand.  I haven't been able to find a scenario to make me say, "We need local functions to solve this problem."

In C# 6, we have lambda functions.  The primary way most of us use lambdas is in Linq, but we can use them in other ways, too.  I've used them in handling events (when I don't care about unsubscribing), creating factory functions for dependency injection, and a few other uses.

One of the more exotic uses I've had for lambdas is conditional operations: if a condition is met, do one thing with some data, otherwise do some other thing.  Simplistically, it looks like this:

```c#
Func<int, int> doMath;
if (shouldIncrease)
	doMath = i => i++;
else
	doMath = i => i >> 1;
Console.WriteLine(doMath(value));
```

Now with local functions, we have the ability to replace the lambdas with functions that are only scoped within this method (just like our lambdas).

```c#
int Increment(int i)
{
	return i++;
}
int Half(int i)
{
	return i >> 1;
}
Func<int, int> doMath;
if (shouldIncrease)
	doMath = Increment;
else
	doMath = Half;
Console.WriteLine(doMath(value));
```

No real improvement there.  In fact I think it's worse.

What's interesting here, though is that we can do funky things with these methods that we can't do with lambdas, like the new tuple returns.

> While writing this, I thought that lambdas couldn't do recursion, but then I worked out this awesomeness.
>```c#
>Func<Func<int, int>> getFib;
>Func<int, int> fibonacci = i => 
>{
>	if (i < 0) throw new 
>	if (i == 0 || i == 1) return 0;
>	return getFib()(i-1)+getFib(i-2);
>};
>getFib = () => fibonacci;
>Console.WriteLine(fibonnaci(value));
>```
> This'll work... to the frustration of your peers.

Here's an interesting example from the post I mentioned before:

```c#
public IEnumerable<T> Filter<T>(IEnumerable<T> source, Func<T, bool> filter)
{
	if (source == null) throw new ArgumentNullException(nameof(source));
	if (filter == null) throw new ArgumentNullException(nameof(filter));

	return Iterator();

	IEnumerable<T> Iterator()
	{
		foreach (var element in source) 
		{
			if (filter(element)) { yield return element; }
		}
	}
}
```

The author argues that with this approach, the arguments can be checked outside of enumeration.  This is true.  But it can be done like this, too:

```c#
public IEnumerable<T> Filter<T>(IEnumerable<T> source, Func<T, bool> filter)
{
	if (source == null) throw new ArgumentNullException(nameof(source));
	if (filter == null) throw new ArgumentNullException(nameof(filter));

	return Iterator(source, filter);
}
private IEnumerable<T> Iterator(IEnumerable<T> source, Func<T, bool> filter)
{
	foreach (var element in source) 
	{
		if (filter(element)) { yield return element; }
	}
}
```

In fact, any local function can be implemented as a private function.  And it becomes available for any other member within the class.

I just can't see the great problem this solves.

### Literal improvements

Aren't all of these features *literal* improvements?  Huh?  HUH?  Get it?  It's a word play on "literal" implying that these features actually exist and none of them are figurative, meaning that there's some hidden feature that you have to discover for yourself through some spiritual journey, guided by a old guy in a technicolor hemp cloak.

Moving on...

So some whiny people wanted to be able to actually read the absurdly large numbers that they hard-coded.  Well now they can.  The underscore is now a digits separator in numeric constants.  Congratulations.  Not going to use this.

The other improvement is that we now get binary literals (`0b0001`), whereas we could only write out integers in decimal or hexadecimal (`0x0001`) before.  Sure.  Okay.  Someone will use it.  Maybe.

Combining these literal features, we get the ability to write out horrific chains of ones and zeros, *but* we get to separate their digits *however we like*.

```
0b1100101001100101
0b1100_1010_0110_0101
0b11_001010011_00101
```

All of these are valid and equivalent.  Yeah, this'll help readability.

### Ref returns and locals

This is just pointers to structs, even then not quite pointers as they are in C/C++.  Seriously, if you want to pass an object around by reference, make it a class.

"But," you say, "what if I didn't create the struct?  Suppose it's in a library?"

Okay.  This may be useful for that scenario.  But who uses structs?!

"What about enums?"

Yeah, maybe.  I don't see myself using this.

### Generalized async return types

There's not an example for this one, but apparently async methods can now return types other than `Task` and its derivatives.  I might use this once I see it in action and get used to it.

### More expression-bodied members

Constructors, destructors, and property accessors (`get` & `set`) can all be defined with expressions instead of brace notation (`{` & `}`).

Meh.  You already know my feelings on expression-bodied members.

### Throw expressions

This lets us throw exceptions pretty much everywhere, like inside the conditional operator `? :`.  I've tried to do this on occasion, to only be disheartened by Resharper telling me I can't.  It seems to me that we should have always been able to do this.

## Summary

So, some good, some... not so good.  I figure my usage will be at about the same level as C# 6, maybe a little less.  Truthfully, though, I'm not looking forward to code reviews.

I guess we'll see how I feel about it in a year when I start complaining about C# 8.