# Nulls and Extension Methods

I recently came across this blog post in which the author provides a tip on how extension methods can be used, suggesting that they can be safely used on null objects. While his suggestion is valid, I cringed at the idea because it severely hampers code readability.

><small>Mr. Mains, if you’re reading this, I’m not trying to rip apart your code or suggest anything about your ability to write quality code. I also had this idea about 8 months ago, and the points I make below were revealed by developers more seasoned than me. My intent is to make us all better developers by not only thinking about the functionality of the code we write, but also its readability and maintainability.</small>

In .Net, extension methods are used to provide additional functionality on an object in such a way so that the code reads as if the method were actually part of that object without actually having to change it. It’s syntactic sugar, nothing more. In reality, you’re calling a static method and passing in the object as a parameter. Let’s take a look at the LINQ extension method Count() to see what’s really going on.

The `Count()` method is defined in the static class `Enumerable`.

```c#
public static class Enumerable
{
    public static int Count<T>(this IEnumerable<T> collection)
    {
        ... // implementation details
    }
    ... // more extension methods
}
```

It can be used on any `IEnumerable<T>` instance.

```c#
var myList = new List<int> { 1, 2, 3, 4, 5, 6 };
var lessThan4Count = myList.Count();
```

***NOTE** `List<T>` also defines a Count property. The code above does not call that property; it instead calls the extension method.*

Behind the scenes, the compiler interprets the call to `Count()` as

```c#
var lessThan4Count = Enumerable.Count<int>(lessThan4);
```

Looking at it this way, it’s easy to see why passing a null is perfectly valid, but using the extension syntax, the code seems to imply that the myList is not null (disregarding that we can see it assigned on the line above). After all, if `Count()` were a real method (or if we used the `Count` property), this would throw a `NullReferenceException`. For this reason, Microsoft has implemented null checks which throw `NullArgumentException` in every one of the LINQ extension methods (and most of them even check for empty collections as well).

Take the first example that Mr. Mains gives:

```c#
public static class ObjectExtensions
{
    public bool IsNull(this object obj)
    {
       return obj == null;
    }
}
```

Usage is

```c#
var isNull = obj.IsNull();
```

Now, this isn’t a really good example of the power of what he’s trying to accomplish. It’s just as easy to write

```c#
var isNull = obj == null;
```

In fact, it’s one fewer keystroke. The power is in other example he gives. He wants to traverse an XML document for a particular element, but return null if the path to that element doesn’t exist.

```c#
var doc = XDocument.Load("test.xml");
doc.Root.GetElement("Customer")
        .GetElement("LastOrder")
        .GetElement("Details")
        .GetElementValue("Cost");
```

Each `GetElement(string)` method is an extension method call in which he returns null if the parameter is null. This allows the method chaining that you see in the code without the risk of throwing a `NullReferenceException`.

This is certainly one approach to the problem of extracting the value of one specific node buried deeply inside the document. However, there is a syntax which is designed specifically for drilling down into XML and returning matching values: `XPath`. I would prefer to utilize an `XPath` API to traverse the XML and return the value for you. Something like

```c#
var doc = XDocument.Load("test.xml");
var path = new XPath("/Customer/LastOrder/Details/Cost");
return path.Evaluate(doc);
```

***NOTE** The `XPath` class is something I made up for this post. It probably exists somewhere, but the API may not be quite as I have it represented here.*

However, if you’re determined to use the extension method (or you’re stuck with it because it’s in some code base you don’t have access to), you can always wait for C# 6.0 and its null-referencing operator `?.`. This will instruct the compiler to return null if the referenced object is null. This would transform the code to

```C#
var doc = XDocument.Load("test.xml");
doc.Root?.GetElement("Customer")
        ?.GetElement("LastOrder")
        ?.GetElement("Details")
        ?.GetElementValue("Cost");
```

Then the null checks in the extension methods aren’t necessary; the language handles it for you.

Next time, we’ll challenge a common WPF convention and see if we can change the world for the better.