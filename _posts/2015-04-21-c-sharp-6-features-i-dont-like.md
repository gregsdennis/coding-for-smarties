---
layout: post
title:  "C# 6 Features I Don't Like"
date:   2015-04-21 17:00:00 +1300
categories: c# language rant
excerpt_separator: <!--more-->
---
There have been many posts on the [features of C# 6](https://roslyn.codeplex.com/wikipage?title=Language%20Feature%20Status&referringTitle=Documentation). Probably the most thorough (however now a bit dated) I've seen is [this one](https://msdn.microsoft.com/en-us/magazine/dn802602.aspx).

<!--more-->

When I first read about these new features, I was discouraged about the direction the language is headed, and I still am for some of these. I therefore emailed my [not-so-local C# expert](http://ericlippert.com/) to solicit his opinion on some of them. He has allowed me to share some of his responses to my concerns.

Here are the new features:

## Null-Conditional Operator

This feature adds a new complex (multi-character) operator which automatically checks for nulls before dereferencing an object. If a the object being dereferenced is null, then null is returned, and no exception is thrown.

```c#
var value = somePossiblyNullObject?.SomeProperty;
```

I like this one. I can't say anything bad about the feature specifically. It can't be misused as far as I can see; overused, maybe, but not misused.

One code smell I see coming out of this is the development of [fluent-interface patterns](http://en.wikipedia.org/wiki/Fluent_interface) that allow the [input and output of nulls](https://codingforsmarties.wordpress.com/2015/03/22/nulls-and-extension-methods/). I also foresee junior developers using this operator everywhere, causing their more senior developers to face-palm and then explain that the use of this operator incurs some additional processing time and should be avoided unless necessary.

Finally, this operator does not replace a good, old-fashioned null check. Checking for `null` explicitly early on can help you to catch potential errors before they happen.

It's nice to have, but I don't see myself using it a lot.

## Auto-Property Initializers

This feature adds field-like initialization to auto-properties, allowing one to create a truly read-only auto-property.

```c#
public bool IsInitialized { get; } = true;
```

As I typed that, I realized it's probably a really bad usage example, but it does show the syntax, and leads me to a better use-case. In WPF, there are the idea of commands, which are implemented as properties of type `ICommand`.

One common practice is to implement a read-only property in which you return new instance of the command:

```c#
public ICommand MyCommand { get { return new RelayCommand(_ExecuteMyCommand); } }
```

This has a lot of overhead in that it creates a new instance of the command each time the getter is called. The work-around is to either make the property publicly accessible and privately settable (get; private set;) which is not read-only, or to create a read-only field and return it inside an explicitly-implemented getter (get { return _myCommand; }).

This new feature offers a third option: create a read-only property and initialize it to a specific value.

```c#
public ICommand MyCommand { get; } = new RelayCommand(_ExecuteMyCommand);
```

Included with this is the ability to set read-only auto-properties from within a constructor. This is what I'll be using in my code.

While reading the summary page I linked to above, I died a little inside when I read the following:

> ... the need to declare read-only fields becomes virtually deprecated. Now, whenever a read-only field is declared, you can declare a read-only auto-property possibly as private, if that level of encapsulation is required.

Maybe I didn't read that right, but why is creating a private, read-only auto-property even desired? When we create an auto-property, the compiler comes behind us and adds a field to back it. So now your intent of not creating a field is undone. Worse yet, you have a property you don't need since you have access to the field! Just use the field and forego the private, read-only property.

All in all, this feature has valid usages. I just wish they had come up with a better syntax. This seems clunky at best.

## Primary Constructors

I'm not sure what problem this one solves. It seems like syntactic sugar for sugar's sake.

```c#
public class SomeClass(string aParameter, int anotherParamter)
{
    private string _aParameter = aParameter;
    private int _anotherParameter = anotherParameter;

    public bool SomeProperty { get; set; }

    public void SomeMethod() { ... }
}
```

This is ugly and unneeded. It makes the class name read like a method, not an object. I can see a singular use case for this when combined with *Auto-Property Initializers* from above, but we've already discussed the “merits” of that. However, given that they've included constructor-settable getter-only auto-properties (three hypenated words in a row! Yea!), that use case is moot.

Also, it doesn't preclude the existence of additional constructors, which still have to have the classic syntax. Why is one constructor considered “primary” over the others? Did it get a better grade in... class? (Okay. That was horrible, but I couldn't resist. I'm a dad. Making bad jokes in now inherent to my persona.)

My complaint to Mr. Lippert on this one was that no real functionality was being added, and that “it serves to obfuscate class initialization by spreading out initialization logic throughout the definition of the class.” His response addressed my complaint perfectly.

> Well, many things spread out initialization through the class, including field initializers and ctors which call each other. Putting all the initialization logic in one place isn't a design goal.
>
> The feature came out of a desire to make it easier to whip up small, preferably immutable, “record style” classes, and I think it does a good job of that. I wouldn't want to use it for a large, complex class in the middle of a class hierarchy.

I'm still concerned that it reduces readability. Classic constructors are correct: you have an object, and a method which creates it. They are distinct concepts and should be distinct in code.

## Expression Bodied Members

Again, I'm not sure what problem this solves; it's just more syntactic sugar.

```c#
public bool CanProcessImmediately()
{
    return _isActive && !_queue.Any();
}
```

becomes

```c#
public bool CanProcessImmediately() => _isActive && !_queue.Any();
```

This can apply to properties and functions (methods with return values).

Okay. It's on one line, but you're not really saving anything else. Again, readability is an issue here. This is a method, but it's being represented as an expression. That can be confusing, especially for new developers. Why have two completely equivalent ways of writing a property or method? And how far does this go? Is this valid?

```c#
public bool CanProcessImmediately() => 
    {
        return _isActive && !_queue.Any();
    };
```

If so, what have you gained?

Seriously, how hard is it to have a couple curly braces?! How it is an improvement to have `{ ... }` instead of (or, more correctly, in addition to) `=> ...`?

## Static Using Statement

```c#
using System;

public static Main(string[] args)
{
    Console.WriteLine("Hello, World!");
}
```

becomes

```c#
using System.Console;

public static Main(string[] args)
{
    WriteLine("Hello, World!");
}
```

I'm still on the fence about this one. I didn't like it at first, but Mr. Lippert's reply slowly persuades me of its usefulness. My complaint was that it makes `WriteLine()` appear as if it's part of the local class, not part of Console. His reply:

> Then why does “Console.WriteLine” not also make “Console” appear that it is a member of the local class, rather than a member of the System namespace? For that matter, why is “System.Console.Writeline” not an instance of a local member “System”?
>
> When you internalize the proposed feature — as VB programmers have for a long time — it will seem just as bizarre to be required to type “Math.Sin” when “Sin” is obviously clear as it would to be required to write “global::System.Math.Sin” instead of “Math.Sin”.

The only retort I could devise was to mention that `Console` is obviously a separate class because, in my code editor, the text is a different color. But that seemed childish at best.

I can also see an argument for this that involves extension methods not being part of the class that they're syntactically attached to.

***NOTE** I had wondered if there would be confusion between a class named `System.Console` and some user-defined `System.Console` namespace, but as it turns out, C# already forbids having a class and sub-namespace with the same namespace.*

## Declaration Expressions

```C#
int result;
if (int.Parse("123", out result))
    Console.WriteLine("It's an int: {0}!", result);
```

becomes

```C#
if (int.Parse("123", var out result))
    Console.WriteLine("It's an int!", result);
```

Okay. This one is actually pretty nice. It's like a `using()` statement for `out` parameters. I can see where it can get a little tricky determining field scope, though. In the first example, `result` would be in scope the remainder of the method, but in the second example, only the `if-else` scope has the field. If you were to use this directly (not as part of the `if-else`) the field would be in scope for the entire method.

## Async and Await in catch and finally blocks

```c#
// This is allowed in C# 5.
try { await SomeAsyncCall(); }

// These would not compile in C# 5, but would in C# 6.
catch { await SomeAsyncErrorHandlingCall(); } 
finally { await SomeAsyncFinalizingCall(); }
```

This one is also nice. The C# team admits that it's a feature that should have rolled out with async/await (C# 5), but didn't. That error has been rectified.

## Exception Filters

```c#
try { ... }
catch (ArgumentNullException e) if (e.ParamName == "endpoint") { ... }
catch (ArgumentNullException e) if (e.ParamName == "resource") { ... }
catch (ArgumentNullException e) { ... }
```

This is an interesting one. I can see where you'd like to only catch exceptions if they meet certain criteria aside from type. This could be more powerful if you have several criteria which you want to handle differently. I see page-long stacks of `catch-if`s in my future.

## `nameof()` Expressions

This new operator gives the as-coded name for just about anything that has one (namespaces, classes, fields, properties, and methods).

This is cool. It allows access to the actual variable name in code, not just the value it contains. This is very useful for throwing `ArgumentNullException`s and raising `PropertyChanged` events.

```c#
if (arg == null)
    throw new ArgumentNullException(nameof(arg));
```

or

```c#
public string MyProp
{
    get { return _myProp; }
    set
    {
        _myProp = value;
        if (PropertyChanged != null)
            PropertyChanged(nameof(MyProp));
    }
}
```

I wonder if there will be any issues with obfuscated code...

For the full details with examples, see the [feature page](https://roslyn.codeplex.com/discussions/570551).

## String Interpolation

This feature introduces a new prefix for string literals: `$`. This prefix directs the compiler to treat anything between curly braces (`{` and `}`) within the string as expressions rather than part of the string. This becomes a shorthand notation for `string.Format()`.

```c#
var message = string.Format("{0}, {1}", hello, world);
```

can be written

```c#
var message = $"{hello}, {world}";
```

Note that in both cases `hello` and `world` are actually the variable names. There are, of course, rules around what you can include and what you can't, as well as how to escape certain special characters.

This also allows imbedding C# expressions. While cool, I can see this being misused. Also, I wonder how functional this really is. For example, would it still work if the string is not hard-coded, but rather a resource string? That would be the ultimate usefulness since localization is performed via resources, not hard-coded strings.

For the full details with examples, see the feature page.

### Dictionary Initializers

```c#
var lengths = new Dictionary<string, int>
    {
        {"hello", 5},
        {"this", 4},
        {"is", 2},
        {"easy", 4},
    };
```

can be rewritten as

```c#
var lengths = new Dictionary<string, int>
    {
        ["hello"] = 5,
        ["this"] = 4,
        ["is"] = 2,
        ["easy"] = 4
    };
```

Just another way of initializing a dictionary. Personally, I don't see what's wrong with how it is now: a collection of key-value pairs. Again, it's not that difficult to type or read.

The practical benefit that you get from this is being able to repeat keys without worrying about throwing an `ArgumentException`. Even so, I like having that double-check sometimes, especially on manually-entered dictionaries.

When I had pointed out to Mr. Lippert that this is actually more keystrokes, his reply both addressed my comment and highlighted the motivation behind the addition.

> Not all productivity features minimize keystrokes. The real advantage of the feature is not that it changes the keystrokes, but that it moves something that used to be in a statement context into an expression context.

## The New ~Order~ Language

As I was researching other potentially-upcoming features (C# 7), I stumbled across [this feature request](https://github.com/dotnet/roslyn/issues/159) which had a really good example of a class combining some of these features. I've taken the example a bit further.

```c#
public class Person
{
    private readonly string _firstName;
    private readonly string _lastName;
    private readonly string _birthDay;

    public Person(string firstName, string lastName, DateTimeOffset birthDay)
    {
        _firstName = firstName;
        _lastName = lastName;
        _birthDay = birthDay;
    }

    public string FirstName { get { return _firstName; } }
    public string LastName { get { return _lastName; } }
    public DateTime BirthDay { get { return _birthDay; } }

    public string FullName { get { return string.Format("{0} {1}", FirstName, LastName); } }
    public TimeSpan Age { get { return DateTime.UtcNow – BirthDay; } }

    public override string ToString()
    {
        return FullName;
    }
}
```

becomes

```c#
public class Person(string firstName, string lastName, DateTimeOffset birthDay)
{
    public string FirstName { get; } = firstName;
    public string LastName { get; } = lastName;
    public DateTime BirthDay { get; } = birthDay;

    public string FullName => $"{FirstName} {LastName}";
    public TimeSpan Age => DateTime.UtcNow – BirthDay;

    public override string ToString() => FullName;
}
```

I'm still not sold on the primary constructor, but the rest seems... okay. I see the usefulness in this small class, but in larger, more complex, service-providing classes, I'll probably avoid many of these features.

~Next time, I'll spin a tale of deception and bad customer service.~ *[Edit: This post has been removed.]*