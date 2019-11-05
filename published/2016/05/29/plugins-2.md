# Handling Errors from Plugins

Before we get into today's topic, I have some sadness to report.  My beloved Dallas Stars were eliminated from the NHL playoffs.  Also, my favorite player, Trevor Daley, who now plays for the Pittsburgh Penguins, has suffered a broken ankle and will not be able to play in the Stanley Cup games.  Happily, if they do, and the Penguins win the Cup, he'll still get his name engraved on its holy base!

Anyway, enough of that.  Let's get on to software.

Last time we built a very simple pluggable program where each plugin provides a translation of the string `Hello, World!`  Today, we're going to explore some of the problems inherent in our approach.

But first, we need to make a slight modification in order to create the more real-world scenario in which we might find these problems.

###Fixing the app in order to break it

The first scenario I'd like to discuss is when the plugin fails dramatically.  Usually when a piece of code fails, it will throw an exception.  Did you know that unhandled exceptions are the most common cause of applications closing unexpectedly?  Fortunately, there are a couple ways we can mitigate this.

To test our changes, let's write a plugin that will always fail when we call it.

```c#
public class GermanHelloPlugin : IHelloPlugin
{
	public string Language
	{
		get { throw new NotImplementedException(); }
	}

	public string GetMessage()
	{
		throw new NotImplementedException();
	}
}
```

Now, whenever we call on any functionality for `GermanHelloPlugin`, an exception will be thrown.  And remember, from the point of view of the application, we have no idea what kind of exception will be thrown.

## A small aside

The end users for the software I write are also employees of the company.  This means that I am (un)fortunate enough to have a close relationship with them.  This also means that if anything goes wrong, I'm generally the one who receives the blame.  Not QA, and certainly not those responsible for the broken configuration.

Now, if I were writing an application for which other developers could write plug-ins, I just know that if any of the plug-ins failed (and the application with it), I would receive the brunt of the users' frustration, even though it's not my code that failed.  So I want to be sure that the application doesn't fail, even when someone else's contribution does.

One way I could manage this is by requiring all plug-ins to catch any thrown exceptions.  While this seems like a nice solution, there's an issue of trust here.  I know that I have a hard time trusting code from other people unless I've worked with them for a while and have seen their genius first hand (and we have quite a bit of genius).  So unless I really want to verify that *every* plug-in follows these rules, I need another solution.

I need to be responsible and catch any exceptions at the plug-in entry and exit points.  (I separate the entry and exit points to account for asynchronous programming, which may be supported by your particular need.)  So let's update our application by adding a `try-catch` around the plug-in invocation.

## Fixing the application to properly handle exceptions

Looking back at the code we had for our `Main()` method, we identify two potential breaking points:

1. Building the menu
	```c#
	foreach(var plugin in plugins)
	{
		Console.WriteLine("{0}) {1}", index, plugin.Language);
		index++;
	}
	```
2. Invoking the plug-in
	```c#
	// otherwise, use a plugin
	index = selectedOption - translations.Count - 1;
	Console.WriteLine(plugins[index].GetMessage());
	```

Let's break these down a bit.

## Building the menu

When we build our menu, we obviously don't want the application to crash, but we also need to consider the output.  I'm going to leave that to a business analyst somewhere.  For now, I'm just going to output the type name of the plug-in and say there was an error loading it.

```c#
foreach(var plugin in plugins)
{
	string language;
	try
	{
		language = plugin.Language;
	}
	catch //everything
	{
		language = string.Format("There was an error " + 
									"loading plug-in `{0}`",
									plugin.GetType().Name);
	}
	Console.WriteLine("{0}) {1}", index, language);
	index++;
}
```

Note that we only catch errors that occurr when accessing the plug-in so that we still get a menu entry displayed.  In this way, the user is notified which plugin had an issue.

## Invoking the plug-in

This fix is similar to the other one.  In fact it uses the same code.  (We're going to ignore DRY for right now, though.  Ideally we'll move this kind of logic into a new method.)

```c#
// otherwise, use a plugin
index = selectedOption - translations.Count - 1;
string message;
try
{
	message = plugins[index].GetMessage();
}
catch //everything
{
	message = string.Format("There was an error " + 
							"loading plug-in `{0}`",
							plugins[index].GetType().Name);
}
Console.WriteLine(message);
```

## That wasn't so bad

But it is a little ugly: `try-catch`es everywhere.  And there is one other scenario that this doesn't handle very well.  We'll get into that next time, along with its solution.