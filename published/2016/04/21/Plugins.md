# A Plugin Primer

First of all, I'm sorry.  It's been a while.  I committed to writing this blog, and I got a little lazy.  That's not to say that I haven't been *really* busy, though.

Secondly, I'd like to say... **LET'S GO STARS!!!**  (The Dallas Stars are currently in the Stanley Cup playoffs after having won the Western Conference and coming in #2 in the NHL during the regular season!)

Okay.  Now that that's out of the way, let's get on with this blog post.

---

Today, we're going to embark on a new journey: building WPF applications that support plugins.  There are a number of ways to build plugable applications, and I recently had the opportunity to play around with a few ideas.  In this series we'll explore some of our options and their merits.  But first, let's look at what a plug-in is.

## Plug-ins: what are they, where do they come from, and what do they taste like?

Odds are you know what a plug-in is, from a user point of view, but many of us (yes, "us" means "developers" here) haven't stopped to think about how they work.

A plug-in is a chunk of code, supplied by a library not directly part of the application, that extends (or alters) the application in some way.  Plug-ins can be written by the application's developer or by a third party.  Either way, the application must be written to incorporate plug-ins at run time.

The most common method for supporting plugins is designating a folder into which plugins will be installed.  The application then searches for specific basic functionality that allows the application to hook in the plug-in and run the functionality it contains.

While extensibility is probably the main reason that a plug-in architecture is used, another advantage is separate deployables.  If an application is determined to have a bug, a plug-in architecture allows you to deploy a new version of the plug-in without having to redeploy the entire application.  In a way, it's like the Single Responsibility Principle applied at the application level.

## What does a plugin look like for my application?

You're probably ahead of me on this.  If the application is to hook in plug-ins based on some basic functionality, it probably needs to know what that basic functionality is.

To facilitate this, the application author writes an abstraction that defines the required functionality to hook into the application, and then publishes it separately from the application.  Then the application is coded to search a specified plug-in directory for implementations of that abstraction.

Because the abstraction only defines the contract, the plug-in is free to do just about anything once it's loaded.

## A plug-in architecture at its simplest

Let's create a simple console application that uses a plug-in architecture.  Our application will present the classic numerically-indexed menu which will present a number of options to print `Hello, World!` in a variety of languages.

In our solution, we'll have the following projects:

- A console application (the main application and entry point)
- A plug-in definition library (this would be distributed for plug-in development)
- Several plug-in projects, each one providing a single plug-in implementation.

##The plugin project

To start, we need to define our plug-in.  For us, this means an interface.

```c#
public interface IHelloPlugin
{
	string Language { get; }
	string GetMessage();
}
```

This completes the plug-in project.  Well done.

## The application

The main application will build the menu, interpret the responses, and coordinate the plugins.  We'll also want it to have some built-in languages as "out of the box" functionality.

In building the menu, we want to present our built-in options first, then enumerate the options supported by the plug-ins.

Because the two most common languages here in Texas are English and Spanish, we'll build those in.  The plugins will provide other language options.

Update your `Main()` method as follows:

```c#
	public static void Main(params string[] args)
{
	var translations = new List<string>
		{
			"Hello, World!",
			"¡Hola Mundo!"
		};

	var plugins = _LoadPlugins();

	var selectedOption = -1;
	// For the purpose of this example, we're not
	// worried about letting the user quit.
	while (true)
	{
		// output menu
		Console.WriteLine("1) English");
		Console.WriteLine("2) Spanish");
		var index = 3;
		foreach(var plugin in plugins)
		{
			Console.WriteLine("{0}) {1}", index, plugin.Language);
			index++;
		}

		// get selection
		Console.WriteLine("Pick a language: ");
		var input = Console.ReadLine();

		// be sure you validate!
		if (!int.TryParse(input, out selectedOption) ||
			selectedOption <= 0 ||
			selectionOption > translations.Count + plugins.Count)
			continue;

		// process selection
		if (selectedOption <= translations.Count)
		{
			// if 1 or 2, we need one of the built-in translations
			index = selectedOption - 1;
			Console.WriteLine(translations[index]);
		}
		else
		{
			// otherwise, use a plugin
			index = selectedOption - translations.Count - 1;
			Console.WriteLine(plugins[index].GetMessage());
		}
	}
}
```

Pretty simple.  But what is that `_LoadPlugins()` method?  I'll give you a hint... it loads the plugins.  To do that, we'll need to get our plugin directory, scan the assemblies, and instantiate any classes that implement `IHelloPlugin`.

***NOTE** Ordinarily, I'd break this up into smaller methods like `_PrintMenu()` and `_ProcessSelection()` (or even dependency-injected, SOLID-compliant classes), but given this context, I think it's better to be explicit than architecturally sound.*

***NOTE** We could also implement English and Spanish as plug-ins that happen to ship with the application, but I wanted to showcase that the application will usually have inherent functionality instead of merely being a plug-in host.*

## Loading the plug-ins

Now let's tackle that `_LoadPlugins()` method.  As mentioned, we have several steps:

1. Get the plugin directory.
2. Scan any assemblies for implementations of `IHelloPlugin`.
3. Return a collection of instances.

Getting the plugin directory is simple.  Let's just put it in an app setting.

```xml
<add key="pluginDir" value="Plugins\"/>
```

To get the directory and its files, and to create instances:

```c#
private IEnumerable<IHelloPlugin> _LoadPlugins()
{
	var directory = ConfigurationManager.AppSettings["pluginDir"];
	// the SearchOption.AllDirectories searches recursively
	// we do this in case the plugins are in separate folders
	var files = Directory.GetFiles(directory, "*.dll",
									SearchOption.AllDirectories);
	var plugins = new List<IHelloPlugin>();

	// there's a lot of error handling that I'm skipping...
	foreach(var file in files)
	{
		var assembly = Assembly.LoadFrom(file);
		var implementations = assembly.GetTypes()
			.Where(t => t.IsAssignableFrom(typeof(IHelloPlugin)) &&
						// we need these because we have to instantiate the types
						!t.IsAbstract && !t.IsGeneric);
		// although not recommended, an assembly could define multiple plug-ins
		var instances = implementations.Select(i => Activator.CreateInstance(i);

		plugins.AddRange(instances);
	}

	return plugins;
}
```

That's it.  The main application is done.  If we were to run it now, we'd see a menu with two options.

```
 1) English
 2) Spanish
Pick a language: |
```

(That last bit is supposed to be the cursor.)

From here, we pick a language and get the expected output.

## Creating a plugin

We have our framework, now we need to pretend to be a third-party developer who wants to augment this application to add more languages.

In one of the plug-in projects, we'll create a new class to implement `IHelloPlugin`.

```c#
public class RussianHelloPlugin : IHelloPlugin
{
	public string Language { get { return "Russian"; } }

	public string GetMessage()
	{
		return "Привет мир!";
	}
}
```

And we're done.  This assembly can be deployed separately from the application and installed into the plug-in folder.  When the application runs, we'll get a new option:

```
1) English
2) Spanish
3) Russian
Pick a language: |
```
We can repeat this *ad nauseum* to support other languages.

## Summing things up since 2015

We've created a fairly useless application which is completely extensible via plugins.  Furthermore, if any language is incorrect (except for English and Spanish), we just need to deploy an update for that plug-in; we don't need to redeploy the entire application.

What's not completely evident in this example is that the plugin doesn't have to merely return the message.  It has full control of the application once `GetMessage()` is called.  This means that the developer is free to prompt the user for their age, make web service calls, or just about anything else.

***NOTE** This brings up an important issue.  Since the plugin has control, it really *can* do anything.  This includes actions that may pose a security threat to the end user.  This is an issue that needs to be considered when creating a plug-in-based application.  You may want to consider an approval process to certify plug-ins for use with the application.*

Next time, we'll look at the primary issue with this approach as well as its solution.  Then we'll discuss the benefits and consequences of each.