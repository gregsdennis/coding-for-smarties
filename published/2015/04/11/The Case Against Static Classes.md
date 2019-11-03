The Case Against Static Classes

Static classes cannot be instantiated. That means they serve only serve one purpose: providing data and functionality to all areas of an application. They are a close relative to the evil global variable.

They can be very useful at times. However, modern software architecture practices suggest that we instead create an instance class which implements an interface and use an IoC (Inversion of Control, sometimes referred to as dependency injection) container to serve a single instance to whichever classes need its data or functionality. Furthermore, all functionality of the instance should only ever be accessed through said interface.

While I’m not going to dive too deeply into the merits of dependency injection, I would like to address a couple benefits to this approach. Because the consuming class is interacting only with the interface, any class which implements the interface should be able to provide the functionality which consumer needs. This allows all kinds of fun things. Most pertinent to this discussion are:

Extensibility – You can either replace the existing implementation with another that does something completely different, or decorate the implementation with any kind of additional functionality you need. The classic example of decoration is adding caching to a repository.
Service mocking – This is very beneficial for unit testing. You can provide exactly the functionality you expect from the interface which means that you’re only really testing the target class.
Extensibility
Decoration

Suppose you have a service class which requires functionality to read from a database. Being the knowledgeable developer you are, you decided to follow the Single Responsibility Principle (SRP) to provide that functionality, so you created a repository class.

public class DataRepository
{
    public IEnumerable<MyData> GetAll() { ... }
    public MyData Get(string id) { ... }
}
It’s simple, but it does the job. Using your IoC container, you inject your repository into the service, and you can now serve all the data you want. But there’s a problem. Your application hits the database so much that it’s making your application crawl. You want a sprint, so you think, “I’ll cache the data I get from the repository.” At this point, you have several options.

You can crack open the service and cache all of the data there.
You can crack open the repository and cache all of the data there.
Neither of these are particularly appealing since you want to keep to SRP and both of these classes work just fine as they are. They don’t need more functionality mucking them up. Fortunately for you, there is a third option.

If the repository implemented an interface, you can create a decorator for it and inject that into the service. That way the implementations of the repository and the service don’t have to change at all.
So you extract an interface that exposes the functionality of your repository and inject the interface into the service instead of the implementation. Your decorator merely has to provide caching for what it pulls out of the base implementation (also injected via the interface) which additionally follows SRP. This makes your boss happy. Your application is fast, which also makes your boss happy. There is much rejoicing.

Replacement

Now suppose the business decides they don’t want to store the data in a database. Instead they say that they want to provide data to your application via a WCF service. Well that’s simple. You don’t need to rewrite the repository; just create a new service-calling repository and use that one instead of the database-based repository. Since you’ve already wired up with a caching decorator, you just need to replace the repository and everything else can stay in place. Congratulations! You have a very maintainable codebase!

Service Mocking
As a secondary outcome of your awesomeness as a developer, you’ve been steadfast in unit-testing your code. To do that, you’ve recognized that by relying on interfaces for your dependencies, you can now mock them so that your tests focus specifically on the class being tested, not on its dependencies. A mock is simply a class which implements the interface you need and can be configured to provide any output. There are many mocking frameworks from which to choose, and the more advanced ones can also provide verification that certain method calls were made or properties accessed. This means that you can easily create tests which exercise specific code paths.

Exceptions to the Rule
Static WPF converters

How hypocritical of me to pontificate on the use of static properties for use with WPF and then spout off about how static classes are the most evil thing in existence. Okay, that may be going too far, but it makes a good point.

There are actually several reasons the WPF converters are a good candidate for static functionality:

WPF doesn’t allow constructor injection, so we have to provide values by other means. (This one actually puzzles me. ASP.Net does allow you to provide a custom resolver so that you can inject dependencies into controllers. It seems to me that WPF should provide similar behavior.)
The converters aren’t actually static classes; they’re static instances, an extension of the singleton pattern.
WPF interacts with them through the interface IValueConverter, not through the class itself, so they’re easily replaced by another implementation.
Extension methods

Extension methods are really just syntatic sugar on top of methods of static classes. I suggest that these methods are kept simple. Things like finding the date of the first day of the week containing a specific date would be ideal. The simpler, the better. I like to keep to this rule:

If you have to test it, don’t use an extension method; use an injectable service instead.

A service can be independently tested, and (as discussed earlier) can be mocked for testing its consumer. Code that uses extension methods are dependent upon them working properly.

Other scenarios

You may have other examples where using static data and functionality is more beneficial, and I’d like to hear about them. It all depends on your architecture, but just remember that, in general, static classes can lead to inflexibility in your code and should be avoided when possible.

So while static class aren’t actually inherently evil, there are other mechanisms which can be used which provide much higher benefits.

Next time, we’ll have a look at the list of upcoming C# 6 features and why I’m concerned about the direction the language is heading.