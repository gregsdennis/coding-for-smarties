# Lord of the Converters

> ...One Converter to bring them all and in the XAML bind them...

Last time, I briefly mentioned a converter that I created for WPF that helps solve the Cambrian Explosion problem that comes with creating specialized converters.  Today I'll go over that converter and what makes it tick.

## The scenario

You have been happily building your awesome WPF application.  On occasion, as it happens, you need to convert view model values or change view properties based on view model values.

You find that you need to hide a control when a list is empty, so you check your converters.  Nope, you don't have a converter that does that.  But... you *do* have one that returns a determines whether a list is empty, returning a boolean, *and* you have one that converts booleans into visibility.

If only you had a way to combine them.

## The hero

Let's start by simply creating a converter that combines our two converters explicitly.  We're going to skip the static instance stuff as we're not going to use it in this case.

```c#
public class AggregateConverter : IValueConverter
{
	public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
	{
		var currentValue = HasItemsConverter.Instance.Convert(value, targetType, parameter, culture);
		currentValue = BoolToVisibilityConverter.FalseToCollapsed.Convert(currentValue, targetType, parameter, culture);

		return currentValue;
	}

	public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
	{
		throw new NotImplementedException();
	}
}
```

Okay.  Not bad, but we need to make this a bit more generic so that we can specify which converters to use in the XAML.  To support this, we need to create an `IList` property and initialize it, then we tell the compiler that this property is the default so that we can just list our converters directly as content.  Lastly, we take advantage of a little LINQ magic to combine them in the proper sequence.

```c#
// These attributes let us just add converters as content.
[DefaultProperty(nameof(Converters))]
[ContentProperty(nameof(Converters))]
public class AggregateConverter : IValueConverter
{
	// Definitely need to initialize this; otherwise we'd get a NullReferenceException.
	public IList Converters { get; } = new List<IValueConverter>();

	public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
	{
		return Converters.Aggregate(value, (v, c) => Apply(c, v, targetType, parameter, culture);
	}

	private object Apply(IValueConverter converter, object value, Type targetType,
							object parameter, CultureInfo culture)
	{
		return converter.Convert(value, targetType, parameter, culture);
	}
}
```c#

We can use it like this:

```xml
<Border>
	<Border.Visibility>
		<Binding Path="MyList">
			<Binding.Converter>
				<cvtr:AggregateConverter>
					<x:Static Member="cvtr:HasItemsConverter.Instance"/>
					<x:Static Member="cvtr:BoolToVisibilityConverter.FalseToCollapsed"/>
				</cvtr:AggregateConverter>
			</Binding.Converter>
		</Binding>
	</Border.Visibility>
</Border>
```

Meh.  Not great to look at... or use... but it works.  Let's see if we can clean it up a bit.

## Making it pretty

So the nice thing about using things like bindings and static resources is that they have markup extensions that allow a really simple and terse syntax.  You've seen them:

```js <!-- not really js, but it give the highlighting I want -->
Visibility="{Binding MyValue, Converter={x:Static cvtr:BoolToVisibilityConverter.FalseToCollapsed}}"
Foreground="{StaticResource MyBrush}"
```

This syntax is our goal.  But unlike `BindingExtension` and `StaticResourceExtension`, we won't build a separate class; we're just going to make our converter do it directly.

To implement this, we need to update our converter so that it derives from `MarkupExtension` and then override the `ProvideValue()` method.  I've [written about markup extensions before](https://codingforsmarties.wordpress.com/2016/12/20/reinventing-the-wheel/) so I'm going to gloss over some of the details.  Instead, here's the completed method.

```c#
public override object ProvideValue(IServiceProvider serviceProvider)
{
	return this;
}
```

Shockingly complex, I know.  Now we can do this:

```
{cvtr:AggregateConverter}
```

Well that doesn't help much.  We can create a converter, but we have no way of passing the sub-converters into it.  What we want is:

```
{cvtr:AggregateConverter {x:Static cvtr:HasItemsConverter.Instance}
						 {x:Static cvtr:BoolToVisibilityConverter.FalseToCollapsed}}
```

To do this, we need to create a constructor.  Ideally, we'd want our constructor to take any number of converters.  In C#, this means we need to use the `params` keyword, like this:

```c#
	public AggregateConverter(params IValueConverter[] converters)
	{
		Converters = converters.ToList();
	}
```

Now we're getting an error that says there isn't a constructor that takes two arguments, and you're like, "IT'S RIGHT THERE!"  That's when you figure out that the `params` keyword is really just a C# compiler trick, and there's actually only one parameter of type `IValueConverer[]`, an array.  So instead we have to create a series of constructors, each one taking a different number of converters.  I decided to create constructors to support between two and five converters.  I'm sure you can imagine how to build those.

Done.  Now we can combine very simple, generic converters to come up with all sorts of crazy conversions and behaviors.  I've chained up to four so far.  Can you come up with a reason to do more?

You can download the code for it [here](https://1drv.ms/u/s!AsfebNc2nZnZh58s6rVs7MvazSwedg).  This version also implements `IMultiValueConverter` and will accept one as the first converter in the collection.