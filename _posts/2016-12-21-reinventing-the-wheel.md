---
layout: post
title:  "Reinventing the Wheel"
date:   2016-12-21 17:00:00 +1300
categories: c# wpf
excerpt_separator: <!--more-->
---
It's an age-old question that just about every WPF developer has asked:  How can I bind an event to a command?

<!--more-->

The internet would have you believe that the only way to bind a command on the view model to an event in the view is by using the *Microsoft.Windows.Interactivity* library.  This works, but the syntax to accomplish it is so remarkably verbose that it's almost a hindrance.

Suppose you wanted to execute a command when the focus left a text box.  The *Interactivity* way to do this is:

```xml
<TextBox Text="{Binding SomeText}">
	<i:Interaction.Triggers>
		<i:EventTrigger EventName="LostFocus">
			<i:InvokeCommandAction Command="{Binding SomeCommand}"/>
		</i:EventTrigger>
	</i:Interaction.Triggers>
</TextBox>
```

That's a lot of code for a simple binding!

## An attempt was made

Caliburn.Micro has completely mooted the issue by its strange "convention" black magic.  I, for one, prefer to be able to read my code (and that written by my peers), and many of the things that they do simply serve to obfuscate the intent.  They use runtime reflection to "bind" handlers on the view model by name.  There are a lot of options, but rather than replicate them here, I'll [link to the docs](https://caliburnmicro.codeplex.com/wikipage?title=Cheat%20Sheet) instead.  (They even mention the method above as their "long version.")  You can see that there's a lot of Angular-style magic happening here.

Another problem with what they've done is there's little to no design-time support.  It's all just magic strings, and if it's not set up just right, it won't work.

On the other hand, being explicit with your bindings tends to aid code readability.  And if you use the `d:DataContext` directive to set a view model type, you get design-time checking and Intellisense for view model properties on bindings.  If something isn't right, you'll get at least a warning from the compiler.

There are other issues that I have with this framework, but that's not what this post is about.  In fact, I like many parts of it and use a reduced version in my own private and professional development.

## A (The) new solution

What we need is a way to bind the command to the event <u>in a familiar way</u> that also provides as much design-time checking as possible.

Enter the `EventBinding` class.  This is a special markup extension that solves this pesky problem.  Using `EventBinding`, a handler can be attached which invokes the desired command and with the familiar binding markup syntax.

```xml
<TextBox Text="{Binding SomeText}"
		 LostFocus="{fmwk:EventBinding SomeCommand}"/>
```

That's it!  When the event fires, the command will execute.

## How it works

First, in order to use any class as a markup extension, it must derive from `MarkupExtension`.  So let's start there.

```c#
public class EventBinding : MarkupExtension
{
	public override object ProvideValue(IServiceProvider serviceProvider)
	{
		throw new NotImplementedException();
	}
}
```

Right now it only explodes.  But we can still use it if we like crashing our application.

To get the command name, we need to add a constructor that accepts a single string argument.  We'll save that name for later.

```c#
private string _commandName;

public EventBinding(string commandName)
{
	if (_commandName == null)
		throw new ArgumentNullException(nameof(commandName));

	_commandName = commandName;
}
```

Next, consider that an event is just a delegate.  In order to execute the command, we'll need something that wraps the execution in a method which matches the event delegate signature.  Then we just return the method as a new delegate.

*Just*.  As if it were that simple.  The problem is that different event handlers have different signatures, so we need to make sure that our method can morph into the common event handler delegate signatures.  Fortunately they tend to follow a pattern: an `object`-typed sender, a typed event argument, and a void return.  We can use this pattern combined with generics to our advantage.

To wrap the command, we'll create a new class.  It should be private and contained within `EventBinding` since it's an implementation detail and nothing else needs to know about it.

```c#
private class EventCommandHandler
{
	private readonly ICommand _command;

	public EventCommandHandler(ICommand command)
	{
		if (command == null)
			throw new ArgumentNullException(nameof(command));

		_command = command;
	}

	public void Handle<T>(object sender, T e)
	{
		if (_command.CanExecute(e))
			_command.Execute(e);
	}
}
```

Not much to that.  We'll handle providing a type for the generic parameter within the implementation of `ProvideValue()`.  But first, let's turn our attention to the delegate we wish to return.

To create a delegate, we'll need a few things:

- the type of the event handler delegate
- an `EventCommandHandler` instance
- the `MethodInfo` for the `EventCommandHandler.Handle<T>()` method with generic type provided

Getting the handler instance is easy: we create it.  But to do that we need the command instance from the view model (it's a parameter in the `EventCommandHandler` constructor).  To get *that*, we cheat a little.

Instead of jumping through hoops to manually evaluate a binding, we let bindings work for us.  We need an object that has a data context and an `ICommand`-typed dependency property.  We could use an existing control like a `Button`, but by creating one we incur slightly less overhead.  This class should be private to `EventBinding` as well.

```c#
private class BindingTarget : FrameworkElement
{
	public static readonly DependencyProperty CommandProperty =
		DependencyProperty.Register("Command", typeof(ICommand),
									typeof(BindingTarget),
									new PropertyMetadata(null));

	public ICommand Command
	{
		get { return (ICommand)GetValue(CommandProperty); }
		set { SetValue(CommandProperty, value); }
	}
}
```

Now we instantiate our `BindingTarget`, set the data context, and apply the binding, then the `Command` property should be the instance on the view model.  So where do we get the data context?

Fortunately for us, `ProvideValue()` comes with an `IServiceProvider` parameter.  And yes, it's exactly what it says it is.  Since it's built into WPF we just smile and nod; we don't argue about how service providers are a hideous anti-pattern from the devil.  In this case, it benefits us.  We need an instance of an `IProvideValueTarget`.  This exposes two properties: `TargetObject` which gives us the control that contains our event, and `TargetProperty` which gives us (in this case) an `EventInfo` for the event we're trying to handle.  With these two properties (properly cast) we can acquire all the information we need to ultimately create our delegate.

Since we have an immediate need for the binding target, let's start there.  First we check whether our target has a `DataContext` property by ensuring it derives from `FrameworkElement`.

```c#
var target = provider.TargetObject as FrameworkElement;
if (target == null)
	throw new ArgumentException(
		"Event bindings can only be set on types derived from FrameworkElement.");
```

Next we create a new `BindingTarget` instance, set the data context, and apply the binding.

```c#
var tempTarget = new BindingTarget {DataContext = target.DataContext};
var binding = new Binding(_commandName);
BindingOperations.SetBinding(tempTarget, BindingTarget.CommandProperty, binding);
```

Now we can get the view model's command instance from our temporary target.

```c#
var command = tempTarget.Command;
```

And we can finally create our `EventCommandHandler` instance.

```c#
var handler = new EventCommandHandler(command);
```

That takes care of the handler instance.  We still need a typed `MethodInfo` for the `Handle<T>()` method and the event handler delegate type.  To get the typed `MethodInfo` we need to know the type of event arguments used by the event handler delegate.  Since we can get the parameter type from the event delegate type, let's start there.

```c#
var handledEvent = provider.TargetProperty as EventInfo;
Type eventType;
if (handledEvent == null)
{
	var handledMethod = provider.TargetProperty as MethodInfo;
	if (handledMethod == null)
		throw new ArgumentException("Event bindings can only be set on events.");
	eventType = handledMethod.GetParameters()
							 .Last()
							 .ParameterType;
}
else
	eventType = handledEvent.EventHandlerType;

var eventType = handledEvent.EventHandlerType;
```

***EDIT** In testing this code, I found that events like `MouseEnter` and `LostFocus` actually come through the `TargetProperty` as methods, not events.  This is because these events forward their implementation to the `Mouse` and `FocusManager` classes, respectively.  I *did* find, however, that there was a pattern here as well: the last parameter in these methods is the event handler, so we can grab it from there.*

That's our event delegate type.  The parameter type just requires a little reflection.

```c#
var eventArgsType = eventType.GetMethod("Invoke")
							 .GetParameters()
							 .Last()
							 .ParameterType;
```

Now we use a little more reflection to get a typed `MethodInfo` from the handler and we can create our delegate.

```c#
var handlerMethod = typeof(EventCommandHandler)
						.GetMethod(nameof(handler.Handle))
						.MakeGenericMethod(eventArgsType);

return Delegate.CreateDelegate(eventType, handler, handlerMethod);
```

And we're done.  We have successfully bound a command to an event.

Technically, it's not a true binding in that updates on the view model won't be reflected in the view.  It's more akin to a one-time binding: the handler is created once.  And if the command isn't set by the time the view binds to the view model, then you'll likely get a nasty run-time error.

### Design-time support

Sadly, support for custom markup extensions is somewhat limited.  [This SO answer](http://stackoverflow.com/a/1702978/878701) gives a good explanation as to why and a possible workaround if you're into that sort of thing.  But since his workaround isn't something that can easily be packaged, I've decided to just live with the shortcomings.

The parts that aren't supported are the two exceptions we throw in `ProvideValue()`.  If you try to use this binding on a property instead of an event, or if you manage to bind to an event on a non-`FrameworkElement`, you won't hear about it until runtime.  Even so, the whole application will die when you do something like that, so I don't think it's too big of an issue.

Interestingly, however, the property checking and Intellisense still work.  So if you mistype your property name, the compiler will complain about it.  It's not anything specific that we did; it just works.  +1 for the win!

### The completed code

You can find the complete class [here](https://1drv.ms/u/s!AsfebNc2nZnZhqJZalJvB8YSJx2dAA), if you'd like to download and go.  I'll also consider putting it up on Nuget if any interest is shown.