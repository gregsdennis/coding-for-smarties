You found it!  After many hours of scouring the internet, you've finally discovered the library that does precisely what you need.  Except... it has a dependency... on a package that your architect has declared unfit for your company. <!-- MORE --> Your options are:

- Persuade your architect to accept this library because you really need it (not likely)
- Download the source and eliminate the dependency (only works if the source is available)
- Use it anyway (not recommended as this type of behavior can result in a job search)

Today I'm not going to present a magic bullet solution to that problem.  There is none.  Instead we're going to explore how to write your libraries so that you don't put others in this horrible position.

><small>**NOTE** I touched on this a bit in a [post I wrote last year](https://codingforsmarties.wordpress.com/2015/10/24/microsoft-did-it-wrong/).  But it seemed to me that the topic needed to be revisited.</small>

## The scenario

So you have a great idea for a library.  To satisfy the needs of this post, let's assume it's [yet](https://github.com/PrismLibrary/Prism) [another](http://caliburnmicro.com/) [MVVM](http://www.mvvmlight.net/) [framework](https://github.com/MvvmCross/MvvmCross).  As you code, you rely on the packages you're familiar with, one of which is the reliable and friendly logging framework, log4net.

Congratulations, you've just created a hard dependency.  Now any potential users of your package must also implement log4net, which also carries the burden of configuring it.

Here's the catch: I can guarantee that at least one of your users doesn't want to use log4net.  They've already built their entire solution around logging with NLog or one of the many other frameworks in existence.  Because of your hard dependency, you just lost a user.

Let's get that user back!

## Root cause analysis

The thing about this scenario is that it's really easy to fall into.  You can follow all of the SOLID design principles within your code and still have this happen.

For example, maybe you defined a logging interface then merely implemented it with log4net.  Your code is loosely coupled, so why is there still a problem?

The problem is that we have to now take what we know about code design and extent that to libraries.  After all libraries can have dependencies just like classes.  If you think about it, any libraries written in Java and .Net have dependencies on their respective frameworks, which are simply a collection of libraries.

By building a log4net implementation within your library, you create a dependency to a particular implementation.  This violates the Dependency Inversion Principle:  while our *code* may be depending on an abstraction, our *library* isn't. 

## Oh, whatever shall I do?!

The solution is really simple.  The simplest solutions are often overlooked.  There are two steps.

### Define a public interface inside your library

If you've followed SOLID in your code as mentioned above, you've likely already done this.  You may only need to make it public.  If not, do it.

Defining your own logging interface breaks the dependency of your code on log4net.

### Remove references to log4net from your library

You may ask how you're supposed to get any logging output without an implementation.  Well, if you're creating a library, you should be testing your code.  Test code is the perfect place to put your implementation (or a mock).

## The result

By doing this, you're not only testing the code base itself, but also its architecture.  You're putting yourself (as a tester) in your clients' shoes by having to provide an implementation of the logging interface to test your code.

Another big benefit of this, is that you can define the interface exactly how you need them, not subject to some other implementation.  Let the client decide how your functionality should translate to their log.