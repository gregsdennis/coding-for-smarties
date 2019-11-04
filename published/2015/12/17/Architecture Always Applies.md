# Architecture Always Applies

I recently ran into an issue with Nuget packages. At work, we have a private Nuget repository for code that we'd like to share across applications. It's mostly common frameworks, like configuration and logging.

While we've done a fair job of segregating interface from implementation, we (read: I) have neglected to properly segregate inter-package dependencies. I figured that Nuget would keep it all straight since it can handle these kinds of dependencies, and Nuget has done what it was designed to do.

However, when we started upgrading some of the packages, we found that .Net didn't play along. To be fair, .Net was doing what it was supposed to do, too.

Our problem surfaced when one of our packages (**A**) referenced a specific version of another (**Bv1**) and we wanted to upgrade our application to use the next version of package B (**Bv2**).

You might think that the solution lies in how we were managing our Nuget or .Net versions. That's what we thought. But we were wrong.

It turns out that there was a flaw in our Nuget package architecture: they were too tightly coupled. To solve this we would have to eliminate the dependency in **A** on **B**. To explain how we did this, I have to give an example.

Avid readers should recognize this solution from a few posts ago where I described how Microsoft screwed up.

## Let's Nugetize

Suppose we have two packages:

- Logging.Framework – Defines some interfaces for logging interaction. No implementations.
- Web.Rest – A REST-supporting implementation of the Web.Interfaces package we have lying around somewhere.

Now when we were writing Web.Rest, we thought it would be a good idea to capture any exceptions and log them. This alleviates the client from having to do that. So somewhere in the assembly, we have a class that looks something like this:

```c#
public class RestWebClient : IWebClient
{
    private ILog log;

    public RestWebClient(ILog log)
    {
        _log = log
    }

    ... // IWebClient implementation
}
```

We have to have a reference to the Logging.Framework assembly to build this thing, because that's where `ILog` is defined. And as we're building Web.Rest, the current version of Logging.Framework is 1.6.10.

Once done with the library, we can add it to whatever application we're currently working on, and everyone plays nicely.

## Introducing a Problem

Fast forward a few months. Our Nuget repository has had an opportunity to grow and mature. Because our design choices lead us to creating the repository, we can reuse code at an alarming rate. We've been able to deploy new applications faster, and we've received raises and accolades due to our sheer awesomeness.

Then one day, the business wants to create a new application that integrates with some niche-y website they found. So who do they turn to? That's right: Team Sheer Awesomeness. And we're in luck! The website exposes a REST API for us to hook into. We have a package for that!

A project is funded, business requirements are written, and the architecture defined. Now we just have to grunt out the code. We create a new solution and import our Nuget packages:

- Logging implementation... check! The interfaces come down along with it. Yea! Nuget works!
- REST implementation... check! The interfaces come down along with it. Yea! Nuget still works!

We build out the application to that critical minimum viable product. It compiles... It starts up... But as soon as it tries to make a service call, we get a FileNotFoundException. “Wait... what?! I'm making a service call. What files can be involved with that?”

You dig into the exception details.

```
Could not load file or assembly 'Logging.Framework, Version 1.6.10 ...' or one of its dependencies.
```

You look up your logging reference, and sure enough, it's version 2.1.3. Now you see two options:

1. You can back out the logging reference and install the specific version from Nuget. But that could require that a lot of your code would have to change.
1. You can recompile the REST package to the newer version. But you shouldn't have to do this every time you update your logging framework.

Certainly, option #2 is easier, but there's a better solution still. It'll take a bit more work, but you'll never deal with this problem again.

3. Edit the REST package and remove the logging framework reference.

## Decoupling Nuget Packages

So, how do we remove the reference and keep the functionality? The answer lies in the [adapter pattern](https://en.wikipedia.org/wiki/Adapter_pattern). Basically, we need to define a logging interface within the REST package that for the classes within it to use. It may be identical to the one in the logging framework package. That's okay. The important things is severing the connection to the logging library.

Then within our new application, all we have to do is create an implementation of the REST logging package that simply forwards the logging functionality to an injected implementation of the logging framework interface. Here's what that looks like:

```c#
class RestLogAdapter : IRestLog
{
    private ILog _log;

    public RestLogAdapter(ILog log)
    {
        _log = log;
    }

    public void LogError(string message) // IRestLog implementation
    {
        _log.LogError(message);
    }
}
```

## Now We Are Awesomer

Because the two Nuget packages are now decoupled, we are free to use whatever version of each package we want to without having to worry about collisions.

You're travelling through another architecture, an architecture not only of the classes and structs, but of programs; a journey into a wondrous land whose boundaries are entire systems. You've just crossed over into Application Architecture.