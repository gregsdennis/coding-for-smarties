---
layout: post
title:  "Static WPF Converters"
date:   2015-03-28 17:00:00 +1300
tags: c# wpf
excerpt_separator: <!--more-->
---
Most sites and books that teach WPF will tell you to declare all of your converters in XAML and then reference them using the `StaticResource` markup extension. I disagree. Unless you're super-careful about it, you'll end up creating mutliple instances of various converters.

<!--more-->

## Why is that bad?

Each instance uses memory. This isn't a really big deal since they should be relatively small classes. Even so, they do increase the application footprint and it makes more work for the garbage collector.
In general (not just for XAML), converters should be stateless. That is, they do their job exactly the same every single time, regardless of the data that comes in; they don't save any details about the data nor does the data cause them to change their behavior.

## What's the big deal about them being stateless?

From a purely run-time point of view, nothing; it's an application architecture thing. If an object is stateless, then you should only ever need one instance of that object (or make it a static class, but that's a different architectural topic).

## What is the solution?

There have been many solutions suggested.

- Declare all of your converters in *App.xaml* so that they're available throughout the application. While this resolves the issue of multiple instances, it can lead to a cluttered App.xaml file and is usually avoided. It's akin to declaring multiple classes in a single C# file. It's perfectly legal; we just don't do it because it tends to make the code base less maintainable.
- Declare all of your converters in a resource dictionary and reference that dictionary in your XAML files. Unfortunately this doesn't actually solve the problem. According to the link in the next suggestion, the WPF framework will still create separate instances of the resource dictionary, including all of its contents.
- Use merged resource dictionaries to solve the problem presented in the previous point. I've tried this (even using the class which is provided), but I never got it to work quite right. The designer doesn't really like it, either.
- Inheriting from `MarkupExtension` so that it can be more compact in the XAML. This is a great idea as it addresses the issues presented in the other points. However, you have to create a new converter class for each explicit conversion type. (One class for `false` to `Visibility.Collapsed`, another class for `false` to `Visibility.Hidden`, etc.) It would be nicer if we could implement all variations of a particular type of conversion within a single class. This also privately implements the singleton pattern.

## Here's what I suggest

As in the last point above, I like to create my converters using the singleton pattern. However, I don't inherit from `MarkupExtension`, and I expose the singleton publicly. This allows me to access them using the `x:Static` markup extension.

```xml
<MyControl MyProp="{Binding YourProp,
                            Converter={x:Static cvtr:MyConverter.Instance}}"/>
```

This has the added benefit of being able to create variations on a theme inside a single converter simply by adding a few instance properties to control behavior and some more static instances to expose the variance in that behavior.

Consider the simple `BoolToVisibilityConverter`:

```c#
public class BoolToVisibilityConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return (bool)value ? Visibility.Visible : Visibility.Collapsed;
    }
    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
```

Now convert it to a singleton. This allows you to use the x:Static markup extension to access the converter.

```c#
public class BoolToVisibilityConverter : IValueConverter
{
    public static BoolToVisibilityConverter Instance { get; private set; }

    public static BoolToVisibilityConverter()
    {
        Instance = new BoolToVisibilityConverter();
    }
    private BoolToVisibilityConverter() {}

    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return (bool)value ? Visibility.Visible : Visibility.Collapsed;
    }
    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }
}
```

Here's the cool part. Add instance properties for controlling non-visible state (in WPF `Visibility` can be `Visible`, `Hidden`, or `Collapsed`) and inversion.

```c#
public class BoolToVisibilityConverter : IValueConverter, IInvert
{
    public static BoolToVisibilityConverter Instance { get; private set; }

    public Visibility NonVisibleState { get; private set; }
    public bool Invert { get; private set; }

    public static BoolToVisibilityConverter()
    {
        Instance = new BoolToVisibilityConverter();
    }
    private BoolToVisibilityConverter()
    {
        NonVisibleState = Visibility.Collapsed;
    }

    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return _InvertIfNeeded((bool)value) ? Visibility.Visible : NonVisibleState;
    }
    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }

    private bool _InvertIfNeeded(bool value)
    {
        return Invert ? !value : value;
    }
}
```

Note This does not violate the stateless nature of the converter. Once configured, the converter will always behave the same way, even though differently-configured instances could behave differently.

Now you can add a multitude of other instance properties which are all configured differently.

```c#
public class BoolToVisibilityConverter : IValueConverter, IInvert
{
    public static BoolToVisibilityConverter FalseToCollapsed { get; private set; }
    public static BoolToVisibilityConverter FalseToHidden { get; private set; }
    public static BoolToVisibilityConverter TrueToCollapsed { get; private set; }
    public static BoolToVisibilityConverter TrueToHidden { get; private set; }

    public Visibility NonVisibleState { get; private set; }
    public bool Invert { get; private set; }

    public static BoolToVisibilityConverter()
    {
        FalseToCollapsed = new BoolToVisibilityConverter();
        FalseToHidden = new BoolToVisibilityConverter
            {
                NonVisibleState = Visibility.Hidden
            };
        TrueToCollapsed = new BoolToVisibilityConverter
            {
                Invert = true
            };
        TrueToHidden = new BoolToVisibilityConverter
            {
                NonVisibleState = Visibility.Hidden,
                Invert = true
            };
    }
    private BoolToVisibilityConverter()
    {
        NonVisibleState = Visibility.Collapsed;
    }

    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return _InvertIfNeeded((bool)value) ? Visibility.Visible : NonVisibleState;
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotImplementedException();
    }

    private bool _InvertIfNeeded(bool value)
    {
        return Invert ? !value : value;
    }
}
```

Yea! Now you have a single class which handles conversion from bool to `Visibility` every which way you can think of, it's all easily accessible from XAML, and you never create multiple instances with the same behavior.

If you need a control to collapse when a certain value is true, it's simple: just use the `TrueToCollapsed` variant:

```xml
<MyControl Visibility="{Binding YourProp,
                                Converter={x:Static cvtr:BoolToVisibilityConverter.TrueToCollapsed}}"/>
```

## Some notes on singletons

Ordinarily, I would avoid the use of singletons, opting instead for dependency injection and letting the DI container manage the lifetime of my instance(s). However, you can't inject an instance of `IValueConverter` into a binding, expecially from XAML. That leave the singleton as the next best option.

Next time, we'll examine some reasons to use static classes as sparingly as possible.