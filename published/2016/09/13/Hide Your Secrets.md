In the last post we discussed why it could be preferred to expose all of your methods publicly.  However, I deliberately left something out.  Some of you may have noticed.<!--more-->

For reference, let's bring in the class again.

	class Service : IService
	{
		private IMultiuseFunctionality _multiuseFunctionality;

		public Service(IMultiuseFunctionality multiuseFunctionality)
		{
			_multiuseFunctionality = multiuseFunctionality;
		}

		public void DoSomething() // defined in interface
		{
			// initialize the process

			_multiuseFunctionality.DoIt();

			// prep for the next step

			_DoSomethingHere();

			// prep for the next step

			_DoTheThing();

			// finish up
		}

		public void DoSomethingHere()
		{
			// a chuck of code that's used only in this class
			// but in multiple places
		}

		public void DoTheThing()
		{
			// a chuck of code that's used only here
			// but is still somewhat distinct
		}
	}

So what's missing?  The accessibility modifier!  And what is inferred if it's missing?  `internal`!  The entire class is only visible from within the same assembly.

##Why would we want to do this?

Well, the way I figure it, if SOLID tells us to design our classes to only rely upon interfaces, then they don't really need to know about any implementations.  There are only two places where we need to reference the implementations: unit tests and the IoC container.

For unit tests, we can add the `InternalsVisibleTo` to the containing assembly and list the test project.  For the IoC container, well, that's a bit more complex.

##A little background before we continue

Most of the time, I see all of the bootstrapping occurring together.  This may exist in the entry project (the project that actually starts execution), or it may be in a dedicated project.  I see the logic behind both approaches.

Wherever you bootstrap, that's where you need references to the implementations.  Some developers recognize that they shouldn't have those references in the main project, so they create a separate project to house them, while other solutions may not be large enough to warrant a separate project just for bootstrapping so they just lump it in with the main project and call it done.

I don't like either of these approaches.  It's the idea that any assembly destined for a live environment has access to the internals of another assembly that disturbs me.

One approach to this is to make all of your implementations public, but that defeats the purpose of hiding them in the first place.

###Why should they be hidden?

In a SOLID application, we should only ever depend upon abstractions.  Extrapolate this concept and you realize that any implementation can (and should) be completely hidden from the class that uses it.  To ensure this, we make the implementations internal.

Hmm... I'm trying to segue into the next part of this, but coming up empty.  Let's start with an example.

##My typical solution

Over the years, I've developed what I consider to be the ideal solution organization.  It's derived from the [Onion Architecture](http://jeffreypalermo.com/blog/the-onion-architecture-part-1/) which states that the core components of the application (e.g. interfaces, models, etc.) should be... at the core.  As we move away from the core, items in each layer of the application should only be able to reference those things in the same layer and below.  It's a great concept that really aids maintainability.

For the purpose of this discussion, let's model a simple application that reads data from a source and then exports that data into another format.  We'll have 4 projects: a core project that contains interfaces and models that need to be shared, and three more that contain implementations for those interfaces.

Here is a summary of the overall architecture:

![](http://i.imgur.com/cUUw5tY.png)

>**NOTE** Not pictured here is the entry `Program` class.  It's in the Console project

See how the only references we have are to the Core project?  That's exactly what we want.

All of the implementations for those shared interfaces are declared internal.  I also have interfaces in the other projects, but they are only referenced from within those projects, so I declare them as internal, too.

Now we have an issue: bootstrapping.  If all of my implementations are internal, how do I bootstrap my application?

##The magic

While it seems okay to allow test code to see the internals, it's a bit odd to give production code the same access.

The solution lies in the IoC (Inversion of Control) container.  The one I'm most familiar with is Castle Windsor, so that's what I'll be using for my examples.

For most IoC containers, the task is the same: we need to hook up an abstraction with its concrete implementation; a task we call "bootstrapping."  Each container has its own mechanics for how this is done, but most will allow this registration to occur in multiple components.  Windsor calls them "installers," Ninject calls them "modules," but whatever they're called, the concept is the same.

If we want to keep the implementations internal and we don't want to explicitly expose them to another assembly just for bootstrapping, then it seems that the only alternative is to move the bootstrapping into the assembly.

So we create installer classes in each of the projects:

	// In the Console project
	public class ConsoleInstaller : IWindsorInstaller
	{
		public void Install(IWindsorContainer container, IConfigurationStore store)
		{
			container.Register(Component.For<IRunner>().ImplementedBy<Runner>());
		}
	}

	// In the DataImport project
	public class DataImportInstaller : IWindsorInstaller
	{
		public void Install(IWindsorContainer container, IConfigurationStore store)
		{
			container.Register(Component.For<IDataImporter>().ImplementedBy<DataImporter>());
		}
	}

	// In the DataExport project
	public class DataExportInstaller : IWindsorInstaller
	{
		public void Install(IWindsorContainer container, IConfigurationStore store)
		{
			container.Register(Component.For<IDataExporter>().ImplementedBy<DataExporter>());
		}
	}

The key here is to declare these installers as public.  Otherwise, the code to find them... won't.

In the `Program.Main()` method, we just need to load the installers using the following code:

	static void Main(string[] args)
	{
		// Create a new container.
		var container = new WindsorContainer();

		// This automatically installs all public IWindsorInstaller implementations from all
		// assemblies in the application directory.
		var assemblyDiretory = Path.GetDirectoryName(Assembly.GetEntryAssembly().Location);
		container.Install(FromAssembly.InDirectory(new AssemblyFilter(assemblyDiretory)));

		var runner = container.Resolve<IRunner>();

		runner.Go();
	}

Done!

All of the projects keep the implementations secret, but through the power of the IoC container, everything is wired properly.

Our application is SOLID.

Our components are testable.

##Other scenarios

###Selecting implementations

I've seen some applications that would list the installers in the `app.config` file in order to allow configuration of which implementations are used.  This is a good solution and is perfectly compatible with the architecture I'm espousing here.  We don't need a hard reference to an assembly to reference it in the `app.config` file, so we haven't broken our architecture.

###Decorator Pattern

The downside to letting the application search *all* assemblies is that *all* of the installers will be installed, and in any order.  Depending on your IoC container, this may cause problems.

For instance, with Windsor, the Decorator Pattern is achieved by properly sequencing the component registrations.  It will always use the first registration as the default, so you want your decorators to be registered first.  If you have your decorator in a separate project than the base implementation, the proper sequence can't be guaranteed.

With Ninject this kind of implicit decoration isn't supported; you have to explicitly state which classes are injected into which other classes.  This can be a problem because we have to know about the decorator when we register the class.  (I think this breaks SOLID a bit.  I like to think of the class's registration with the IoC container as part of the class itself.  A class shouldn't care (or be aware at all) whether the application decides to put a decorator around it.)

###Conflicts

Related to the above point, your container may also experience a conflict if there are multiple implementations for an interface in different assemblies.  The container must choose one, and every container handles this problem differently.

###Building your solution

When you follow this architecture, you may find that your other assemblies are not copied to the entry project.  This is because Visual Studio doesn't identify that there is a dependency between them.

Technically there is, but it's soft.  To remedy this, we have to make the entry project reference those other projects.  It's a little bit of a hack, but it does the trick.  Visual Studio will build the projects and copy the DLLs into the build folder.

Another benefit to having hard references is that we can explicitly orchestrate the installers as part of the application startup.  This can help resolve some of the other issues listed above.

In the long run, we don't care which projects have references to our other projects.  We made everything internal (except for the installers), so the main project can't see any of the implementations.

##Final thoughts

All in all, I find that the approach I've laid out works best in most applications.  As is the way of things, there are always exceptions and concessions that we have to make in order to get the application to work.