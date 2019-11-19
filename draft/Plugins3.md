### Fixing the app in order to break it (again)

The other scenario I want to cover has to do with referenced libraries.  It's likely that many of you have run into this issue before.  One project references one version of a library and another references a different version.  When it builds, you either get a complaint from the compiler or a run-time `FileNotFoundException` stating it can't find the proper version of the referenced library.

It's actually easier to run into this error in a pluggable application because the base application and the plug-in are built independently, meaning there's no compiler warning.  Even if the plug-in and application are initially built with the same version of this shared assembly, if the application is ever updated to reference the next version and the plug-in isn't, chaos will ensue. (It's likely that your computer will phase out of our space-time continuum.)

In order to do this, we need to ensure our application references a library that we can incorporate into one of our plug-ins.

***NOTE** For this scenario, the shared library doesn't have to be referenced by the plug-in definition library.  In these cases, that library's version is likely to change, prompting a required change from the plug-ins anyway.  Here, we're just talking about some third-party library that happens to be used by both.*

Because I'm proud of it, and it's largely text-based, we're going to incorporate Manatee.Json into the app by reading the "stock" values from a `.json` file.

    [
	  {
		"lang":"English",
		"msg":"Hello, World!"
	  },
	  {
		"lang":"Spanish",
		"¡Hola Mundo!"
	  }
	]

This means that we just need to change the program a little to load the contents of the file:

	var translations = new List<string>
		{
			"Hello, World!",
			"¡Hola Mundo!"
		};

becomes

	var text = File.ReadAllText("stockGreetings.json");
	var translations = JsonValue.Parse(text)
								.OfType(JsonValue.Object)
								.Select(o => o["msg"].String)
								.ToList();

Then the rest doesn't change.

***NOTE** We should also change the type of `translations` to a dictionary to dynamically update the "stock" languages by updating the file, but this works for my purposes.*

Then let's say we have a plug-in that provides the text in German that also wants to read from a `.json` file and uses my library.  (I'm willing to bet you can work out the code, so I'll leave that to you.  Consider it homework.)

Now we have a scenario where the application can update separately from the plugins.  For the purposes of this scenario, let's say that both of these projects were built using the 3.2.3 version of Manatee.Json.

###Let's break it!

Now, in the main application, let's upgrade Manatee.Json to the current 4.0.1 version.  Really, it could be either the app or the plugin that upgrades; the point is that they're different.

What happens?  We start the application, then it crashes.  If we had logging, we'd know why.  Instead, we just have my experience.  Or, if you've been following along in Visual Studio, you have that.

The error we receive is a `FileNotFoundException` stating that the version that the plugin is looking for can't be found.  This is because the application has already loaded its own version into memory.  That the specific functionality isn't broken between them makes no difference; .Net wants a specific version and it'll complain until it gets what it wants (much like a small child).

###There's gotta be a better way

There is!  And the good people at Microsoft have already provided it for you as part of .Net:  the `AppDomain` class.  Application domain is an interesting concept in that it can provide separate memory silos within a single process.  This allows different portions of code to live in completely separate memory spaces.

Most of you probably see where I'm going with this.  If the application loads the plugin in its own application domain, then the plugin is free to load whatever version of Manatee.Json it wants to, without causing a conflict with the main application.  This is precisely the behavior we want.

There are some caveats, though.

- While communication is possible over the application domain boundary, it can be tricky.  You can only use objects that are serializable (marked with `SerializableAttribute`), and you have to have carrier object which derives from `MarshalByRefObject`.
- While solving the problem of loading multiple versions of the same assembly, we've introduced a second problem: all libraries that are used by both the main application and the plug-in will have to be loaded into the secondary domain for each plug-in that uses those libraries.  This means that the overall memory footprint of the process *will* increase per plug-in.

