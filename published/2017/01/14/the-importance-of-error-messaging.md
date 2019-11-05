# The Importance of Error Messaging

When I was young, taking my first class in computer science, my mother told me about her experiences with computer programming coming through college in the late 70s.

> We programmed with punch cards.  You had to feed them into a computer to be analyzed, and if you got anything wrong, the computer output would simply be: "Error".

By that time, I was already blessed with a compiler that reported not only different, more specific errors, but also the line on which they occurred!  What a time to be alive!

Even today, however, the error messages that arise could be somewhat vague or misleading or just have some strange language.  Take the error found in [this SO post](http://stackoverflow.com/q/2229768/878701) (and [this one](http://stackoverflow.com/q/10704654/878701), too) for example:

> "The 'this' parameter (or 'Me' in Visual Basic) of 'ImportForm.ProcessFile(StreamReader)' is never used. Mark the member as static (or Shared in Visual Basic) or use 'this/Me' in the method body or at least one property accessor, if appropriate."

"The this parameter..."?  Reading it as English, the reader assumes that it *must* contain a typo, but in the context of C# and knowing that `this` holds special meaning, the error message is understandable.

I ran across another example of poor error messaging the other day while writing some unit tests.  This time from the well-known mocking framework *Moq*.

> Invalid verify on a non-virtual (overridable in VB) member: l => l.Error(It.IsAny<Exception>())

This error message is intended to indicate that a particular method on a class can't be mocked because it can't be overridden.  But in my case, the method was on an interface, so it couldn't *not* be overridable.

Here's my test code:

```c#
[TestMethod]
public void TestIt()
{
	var logger = new Mock<ILogger>();
	logger.Verify(l => l.Error(It.IsAny<Exception>()));
}
```

It looks like everything is fine, but the error was saying that `Error(Exception)` wasn't an overridable method of `ILogger`.  But *everything* is overridable on interfaces!  And it compiles, so the method *must* be defined.

After some searching, I figured out that `Error(Exception)` is an *extension* method on the interface.  That meant the method was not a member of the interface, and therefore not overridable.  So the error message was [*technically* correct](https://www.youtube.com/watch?v=hou0lU8WMgo).  However in this instance, it would have been nice for the error message to state:

> Are you aware, good sir, that the method you are attempting to mock is, in fact, an extension method?  *Moq* can only properly intercept and modify behavior of methods which are 1) on interfaces or 2) on classes and marked as virtual.  Please review the expression you would like to mock and try again.

Now, while butler-esque error messages like this one would be nice, I don't think that's going to happen for compiler errors.  Like the code on which they report, we need them to be non-verbose and to the point.  But they should also explain what the problem *is* so that the issue can be fixed and the programmer can get on with their life.

> That's an extension method... <span style="font-size: xx-small;">idiot</span>.

That's a bit harsh.

***NOTE** Error messages for us programmers should be terse.  Error messages in general use applications are for normal people who like socializing and conversing with others, and should therefore be longer and more comforting and more... hand-holdy.*

So when you're developing your awesome library that does that one thing that millions of developers never knew they couldn't live without, please remember to word your messages in a way that doesn't assume they know your library's inner workings.  Better yet, have the error message suggest fixes or common causes (or at least link to more information about it).

I should probably go back and make sure my Trello and JSON libraries do that...