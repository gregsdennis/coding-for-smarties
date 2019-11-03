Implicit Interfaces

Today’s topic is based on a question I posted on StackOverflow some time ago. There were several workarounds, but in the end, I’d still like this added as a C# feature. Since posting the question, I’ve had some time to ponder the idea a bit more, and here’s my final suggestion.

The Problem
Define an interface in such a way that its entire purpose is to represent a set of other interfaces.

Suppose you have two interfaces:

interface IA
{
    void SomeMethod();
}

interface IB
{
    void SomeOtherMethod();
}
Now suppose you want to create a property on an object into which you can place an object of either type. Since they have no common ancestry, you would have three options (that I’ve seen, you may devise your own):

declare the property as object and then test/cast in order to access the functionality
class MyImpl : IA, IB
{
    public void SomeMethod() { ... }
    public void SomeOtherMethod() { ... }
}

class MyClass
{
    public object MyProp { get; set; }
}

class MyApp
{
    static void Main(string[] args)
    {
        var myClass = new MyClass { MyProp = new MyImpl() };
        ((IA)myClass.MyProp).SomeMethod();
        ((IB)myClass.MyProp).SomeOtherMethod();
    }
}
create a third interface defined as the combination of the two
interface ICombined : IA, IB {}

class MyImpl : ICombined
{
    public void SomeMethod() { ... }
    public void SomeOtherMethod() { ... }
}

class MyClass
{
    public ICombined MyProp { get; set; }
}

class MyApp
{
    static void Main(string[] args)
    {
        var myClass = new MyClass { MyProp = new MyImpl() };
        myClass.MyProp.SomeMethod();
        myClass.MyProp.SomeOtherMethod();
    }
}
create a proxy type which exposes a single field via independent properties
class MyProxy<T, TA, TB> where T : TA, TB
{
    private object _value;

    public TA AsA { get { return (TA)_value; } }
    public TB AsB { get { return (TB)_value; } }

    public MyProxy(T value) { _value = value; }
}

class MyClass
{
    public MyProxy MyProp { get; set; }
}

class MyImpl : IA, IB
{
    public void SomeMethod() { ... }
    public void SomeOtherMethod() { ... }
}

class MyApp
{
    static void Main(string[] args)
    {
        var myClass = new MyClass { MyProp = new MyProxy<MyImpl, IA, IB>(new MyImpl()) };
        myClass.MyProp.AsIA.SomeMethod();
        myClass.MyProp.AsIB.SomeOtherMethod();
    }
}
The second option is generally the more preferred option, however, it’s not always doable. What if, instead of IA and IB, we use IComparableand IConvertible?

interface ICombined : IComparable, IConvertible {}

class MyImpl : ICombined
{
    // IComparable implementation
    public int CompareTo(object obj) { ... }

    // IConvertible implementation
    public int ToInt32() { ... }
    ...
}

class MyClass
{
    public ICombined MyProp { get; set; }
}

class MyApp
{
    static void Main(string[] args)
    {
        var myClass = new MyClass { MyProp = new MyImpl() };
        var comparison = myClass.MyProp.CompareTo(new object());
        var newInt = myClass.MyProp.ToInt32();
    }
}
This only works for classes which specifically implement the ICombined interface. You would not be able to assign types like int, double, andstring, each of which implement both IComparable and IConvertible.

The Solution
We introduce a new usage of the implicit keyword for interfaces.

implicit interface ICombined : IComparable, IConvertible {}
This tells both the compiler and the run-time that any class which implements both IComparable and IConvertible can be interpreted as implementing ICombined.

The remainder of the code could stay the same, but now, in addition to explicit implementations of ICombined we could also assign any type which implements both IComparable and IConvertible, including int, double, and string.

class MyApp
{
    static void Main(string[] args)
    {
        var myClass = new MyClass { MyProp = 6 };
        var comparison = myClass.MyProp.CompareTo(new object());
        var newInt = myClass.MyProp.ToInt32();

        myClass.MyProp = "example";
        var newComparison = myClass.MyProp.CompareTo(new object());
        ...
    }
}
Additionally, you could use this new interface to define a collection of such objects:

var list = new List<ICombined> { 6, "string" };
Defining an interface this way, it becomes retroactive. That is, types which implement all base interfaces for the implicit interface also are said to implement the implicit one.

The Rules
An implicit interface may combine any number of interfaces.
An implicit interface may not define any additional functionality. That is, it must be empty.
That’s really it.

Finally, the run-time will have to do some type checking, which it should do already for the is and as keywords. It wouldn’t need to know all implicit interfaces that a type implements, it would just need to check as requested.

var implemented = 6 is ICombined;
This basically asks, “Does the type of 6, which is int, implement ICombined?” To determine that, it sees that ICombined is an implicit interface so it asks, “Does it implement all of the interfaces implmented by ICombined?” So it’s equivalent to writing:

var implemented = 6 is IConvertible && 6 is IComparable;
Simple field and property assignments would be compiler-verifiable.

A Practical Example
As with any framework, there are a few holes in WPF. ObservableCollection<T> is one of these. The class is coded in such a way that you can only access it (read and write) on the thread which it was created. I’m sure they had their reasons, but this has caused me issues in asynchronous applications.

Suppose you want to show a screen, but the view model contains a collection of strings which may take some time to populate. Being the good MVVM developer you are, you decided to use ObservableCollection<string> to back the property. And wanting to ensure that the property is always a collection which notifies of any changes, you made that the property type as well. You also returned the view model with the collection empty and are populating it off of the UI thread so that your interface doesn’t freeze while loading the data because you know that’s really annoying for the user.

Now that you have your asynchronous solution all coded up to architectural perfection, you run the app and it crashes because theObservableCollection<string> you used isn’t thread safe and editing it off of the UI thread (as is good practice) causes it to barf. Great. now you have to either load synchronously or develop your own thread-safe notifying collection. Fortunately for you, there are such collections available online.

So you have a problem. What type can you use for your property which implements IEnumerable and INotifyCollectionChanged? I’ll give you a hint: there isn’t a built-in abstraction type that does this. So you make one:

public interface INotifyingEnumerable : IEnumerable, INotifyCollectionChanged {}
Awesome. Sort of. Now you have to make either a wrapper class or a subclass which implements this interface and passes implementation details down to the fantastic thread-safe solution you found online.

public class MyNotifyingEnumerable : INotifyingEnumerable
{
    private FantasticDownloadedCollection _collection;

    public IEnumerator GetEnumerator() { return _collection.GetEnumerator(); }
    ...
}
This sucks! You know that FantasticDownloadedCollection implements both of these interfaces. It’s stupid that you have to create a new class just to implement your custom interface. If only there were a way that the compiler could know that you just want any class which implements both interfaces!

Then you remember this blog post, and amazingly enough, the good people over at Microsoft read it, too. They have implemented implicit interfaces for people just like you. Now you can add a single keyword to your interface declaration

public implicit interface INotifyingEnumerable : IEnumerable, INotifyCollectionChanged {}
and remove your custom class altogether. Qapla’!

A Final Take
There is some debate as to whether empty interfaces should be allowed or have a place in applications. Usually they’re little more than marker interfaces. On occasion, they can be helpful with DI containers such as Castle.Windsor. Other than that, I think they’re fairly useless.

This feature proposal gives true purpose and utility to empty interfaces.

Next time, I’ll respond to a post which suggested a coding practice that made me cringe.