---
layout: post
title:  "WPF Miller Columns, Part 2"
date:   2015-11-17 17:00:00 +1300
tags: c# wpf
excerpt_separator: <!--more-->
---
Last time, I walked through an implementation of Miller Columns in WPF that I had posted on StackOverflow, but it ended with a few issues.

- It was incomplete. I didn't post the entire implementation, and much of the context was lost between then and now.
- The implementation wasn't very MVVM. It required a specific type to be used as a data context, whereas in MVVM proper, the view model should be completely decoupled from the view.
- The solution required a code behind. This isn't necessarily a bad thing, but I'd like to see if we can develop a pure-XAML solution.

Let's get started.

<!--more-->

***NOTE** I'm actually creating this control as I write this post. We'll see how that works out for me.*

***TL;DR** I've uploaded the working sample. Enjoy.*

## The Scaffolding

To begin, let's assume that we're going to house our control in a control library so that we can use it wherever we want. So start a new WPF control library project and create a new custom control (I'm calling it MillerColumns). If you use the Custom Control template that comes with Visual Studio, you should get the following:

- A class definition
    ```c#
    public class MillerColumns : Control
    {
        static MillerColumns()
        {
            DefaultStyleKeyProperty.OverrideMetadata(typeof(MillerColumns), new FrameworkPropertyMetadata(typeof(MillerColumns)));
        }
    }
    ```

- A Themes\Generic.xaml file containing a default style.
    ```xml
    <Style TargetType="{x:Type local:MillerColumns}">
        <Setter Property="Template">
            <Setter.Value>
                <ControlTemplate TargetType="{x:Type local:MillerColumns}">
                    <Border Background="{TemplateBinding Background}"
                            BorderBrush="{TemplateBinding BorderBrush}"
                            BorderThickness="{TemplateBinding BorderThickness}">
                    </Border>
                </ControlTemplate>
            </Setter.Value>
        </Setter>
    </Style>
    ```

We'll probably need to bind a data source from the view model, so let's add a dependency property to our control to manage that.

- ItemsSource – we need to show items...
    ```c#
    public static readonly DependencyProperty ItemsSourceProperty =
        DependencyProperty.Register("ItemsSource", typeof(IEnumerable), typeof(MillerColumns), new PropertyMetadata(null));
    public IEnumerable ItemsSource
    {
        get { return (IEnumerable)GetValue(ItemsSourceProperty); }
        set { SetValue(ItemsSourceProperty, value); }
    }
    ```

This will allow us to use the control like this:

```xml
<local:MillerColumns ItemsSource="{Binding Items}"/>
```

We could also add an `ItemTemplate` property, but let's let WPF handle data templates for item content.

I think the XAML we had before is a good place to start. It's clean and concise. Let's reorganize it into a single code block for now.

```xml
<ItemsControl x:Name="MillerColumnsView" VerticalContentAlignment="Stretch">
    <ItemsControl.ItemsPanel>
        <ItemsPanelTemplate>
            <StackPanel Orientation="Horizontal"/>
        </ItemsPanelTemplate>
    </ItemsControl.ItemsPanel>
    <ItemsControl.ItemTemplate>
        <DataTemplate DataType="my:DataNode">
            <ListBox ItemsSource="{Binding Children}"
                     Style="{StaticResource StackedListBoxStyle}"/>
        </DataTemplate>
    </ItemsControl.ItemTemplate>
</ItemsControl>
```

Now we have a few clean-up tasks:

- That `ListBox` still has that unknown style on it.
- The `DataTemplate` is tied to a specific type.
- In order to do a XAML-only approach, that `ItemsControl` will need an `ItemsSource`.

That last one has me concerned a bit. If we use the `MillerColumns.ItemsSource` property, we'll just get a `ListBox` for each of the items at the top level. That's not what we want. We want a single list showing all of the top-level items, then a list showing the sub-items of the item selected in the first list. Carrying this pattern forward, we find that we need a “bread crumbs” collection to source items for the `ItemsControl`. I can't think of a way to do that with just XAML, which means we need some code behind. Oh, well. That's what it's for, I suppose.

## A Small Aside

Ordinarily, I don't like code-behind logic, but that feeling really comes out of how it's usually (mis)used. Developers new to MVVM (I'm looking at you, WinForms) will tend to put business logic in the code-behind of windows and other views. This is where the problem arises. In MVVM the view should merely be a rendering of the application and it should not contain any behavioral logic. When we define a clear separation between the business logic and the view, parts of the application become reusable.

Let's say that we've built our WPF application with validation logic in code-behind files of the windows. Then one day, our client comes back and says they want to enable their users to access cloud-hosted data through a new online interface. When we build the new online interface, we have to duplicate the validation logic in the new web view. Furthermore, when our client returns again to say that they accept new kinds of input, we now have to update the logic in two places.

This scenario allows at least three opportunities for bugs:

- The original application.
- Copying the business logic to the new interface.
- Having to make business logic changes in two places.

If we, instead, separate the business logic from the view, we can reuse the business portion and simply replace the view with a web interface.

It just makes life easier when you do things right the first time.

In this case. we're building a view component. We have the power to ensure that any logic we put in the code-behind pertains only to the rendering of this component and not to any business rules.

# Back to Our Regularly Scheduled Program

Let's go ahead and add a new read-only dependency property to the MillerColumns control.

```c#
public static readonly DependencyProperty ChainProperty =
    DependencyProperty.Register("Chain", typeof(IEnumerable), typeof(MillerColumns), new PropertyMetadata(null));

public IEnumerable Chain
{
    get { return (IEnumerable)GetValue(ChainProperty); }
    private set { SetValue(ChainProperty, value); }
}
```

This property will be updated whenever the selection changes within one of our `ListBox`es. So now we need to be notified whenever the selection of one of our `ListBox`es is updated. Back to the XAML!

If you recall, we cleaned up the data template a bit. That left us with this for the `ListBox`:

```xml
<ListBox ItemsSource="{Binding ???}"/>
```

We still need to address that `???`, but we're here to track selection changes right now. You might think that you can just add an event handler, like you would in a window. You can, but it's weird and not quite what we want. We want the handler in the control.

```xml
<ListBox ItemsSource="{Binding}" SelectionChanged="_ListBox_SelectionChanged"/>
```

It looks like we may need to assign this in the code-behind. If we can attach a handler to that first `ListBox` that shows the top-level items, we can attach to the others as we update the chain. Let's start by overriding `OnApplyTemplate()`.

When building this out, we need to be aware that as the control loads, we don't know whether ItemsSource will be bound yet, so we're going to funnel our overridden method and a change handler for ItemsSource through a private method.

```c#
private ItemsControl _itemsHost;

public override void OnApplyTemplate()
{
    base.OnApplyTemplate();

    _itemsHost = Template.FindName("PART_ItemsHost", this) as ItemsControl;
    if (_itemsHost == null)
        throw new InvalidOperationException("Could not find ItemsControl named PART_ItemsHost.");

    _UpdateChain();
}

private static void _OnItemsSourceChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
{
    ((MillerColumns) d)._UpdateChain();
}
```

We also need to add `_OnItemsSourceChanged()` to the the declaration of ItemsSourceProperty.

```c#
public static readonly DependencyProperty ItemsSourceProperty =
    DependencyProperty.Register("ItemsSource", typeof (IEnumerable), typeof (MillerColumns), new PropertyMetadata(null, _OnItemsSourceChanged));
```

Now let's create `_UpdateChain()`.

... Um... Please hold. I have to figure out how to make this work...

... digging throuh code... searching the web... somewhere, a cat screeches... writing some more code...

Okay, I'm back. That probably took less time for you than it did me. I went through several ideas before I got something that worked. That's how development goes, though.

Rather than bore you with what went wrong, let's just focus on the good. Besides, I usually search online for stuff that works rather than stuff that doesn't. I figure you probably do, too.

## The Solution

So as it turns out, I didn't need to get a reference to the `ItemsControl`, and I didn't need to override `OnApplyChanges()`. I found the trick to setting up the event handler for the `SelectionChanged` event is by using an attached property. Finally, I figured out how to deal with the `???`. Let's tackle the XAML first. That'll give us a goal to work toward in the code.

```xml
<Style TargetType="{x:Type local:MillerColumns}">
    <Setter Property="Template">
        <Setter.Value>
            <ControlTemplate TargetType="{x:Type local:MillerColumns}">
                <Border Background="{TemplateBinding Background}"
                        BorderBrush="{TemplateBinding BorderBrush}"
                        BorderThickness="{TemplateBinding BorderThickness}">
                    <ItemsControl ItemsSource="{TemplateBinding Chain}" VerticalContentAlignment="Stretch">
                        <ItemsControl.ItemsPanel>
                            <ItemsPanelTemplate>
                                <StackPanel Orientation="Horizontal"/>
                            </ItemsPanelTemplate>
                        </ItemsControl.ItemsPanel>
                        <ItemsControl.ItemTemplate>
                            <DataTemplate>
                                <ListBox ItemsSource="{Binding}" Width="100"
                                         local:MillerColumns.Track="{Binding RelativeSource={RelativeSource AncestorType={x:Type local:MillerColumns}}}"/>
                            </DataTemplate>
                        </ItemsControl.ItemTemplate>
                    </ItemsControl>
                </Border>
            </ControlTemplate>
        </Setter.Value>
    </Setter>
</Style>
```

Not much has changed here. I've essentially removed all of the unnecessary properties. You will notice, however, a new attached property on the `ListBox`: `MillerColumns.Track`. The other thing that changed is that the `ItemsSource` for the ListBox is merely an empty binding. This means that its data context must be `IEnumerable`. This is a good thing: we can make `Chain` a collection of `IEnumerable`s.

The attached property is used to identify the `MillerColumns` instance to which this `ListBox` belongs. The binding works by travelling up the visual tree until it finds a MillerColumns instance. Once we have the `ListBox` instance with the `MillerColumns` instance in the same scope, we can subscribe to the `ListBox`'s `SelectionChanged` event, which is what we wanted to do from the beginning. Let's see what that looks like in code.

```c#
public static readonly DependencyProperty TrackProperty =
    DependencyProperty.RegisterAttached("Track", typeof(MillerColumns), typeof(MillerColumns), new PropertyMetadata(null, _OnTrackChanged));

public static MillerColumns GetTrack(DependencyObject obj)
{
    return (MillerColumns)obj.GetValue(TrackProperty);
}
public static void SetTrack(DependencyObject obj, MillerColumns value)
{
    obj.SetValue(TrackProperty, value);
}

private static void _OnTrackChanged(DependencyObject d, DependencyPropertyChangedEventArgs e)
{
    var listBox = (ListBox) d;
    var millerColumns = (MillerColumns) e.NewValue;
    listBox.SelectionChanged += (s, ea) => millerColumns._UpdateChain((ListBox)s);
}
```

All pretty basic WPF stuff.

Finally, we need to address that `_UpdateChain()` method. This one's complicated, so rather than walking through building it, I've annotated the code.

```c#
private void _UpdateChain(ListBox sender = null)
{
    // If we don't have a source, we don't have anything to display.
    if (ItemsSource == null || !ItemsSource.Cast<object>().Any()) return;

    // If sender is null, ItemsSource changed.  Rebuild.
    if (sender == null)
    {
        Chain = new ObservableCollection<IEnumerable> {ItemsSource};
        return;
    }

    // Get the sender ListBox's data context (its ItemSource)
    var enumerable = sender.DataContext as IEnumerable;
    if (enumerable == null) return; // This may happen during initialization.

    // We need to cast Chain so that we can modify it.
    var collection = (ObservableCollection<IEnumerable>) Chain;

    // Remove all ListBoxes after the one that changed.
    var index = collection.IndexOf(enumerable);
    if (index == -1) return;

    index++;
    while (collection.Count > index)
        collection.RemoveAt(index);

    // Now we need to get the list of children from the selected item. To do this,
    // we need to find the HierchicalDataTemplate for the specified type and
    // get its ItemsSource property.  The property is the raw binding, which we'll
    // need to resolve, given the item as a data context.  This requires a dummy
    // dependency object.

    // Get the selected item.
    var item = sender.SelectedItem;
    if (item == null) return;

    // Find the HierarchicalDataTemplate.
    var template = _FindTemplate(item.GetType());

    // Resolve the binding to get the new collection.
    var newSource = _EvaluateBinding(item, template.ItemsSource);

    // Add to Chain.
    if (newSource != null)
        collection.Add(newSource);
}
```

In here, there are two methods still left to be defined: `_FindTemplate()` and `_EvaluateBinding()`. Let's start with `_EvalBinding()`.

As mentioned in the comment block of the code above, in order to evaluate a binding, we need to bind it to a dependency property. Then we can simply extract the value from the property. So first we create a dummy class to host the dependency property.

***NOTE** We create a dummy class because we need to set the data context, and if we did that on this class, it could break other bindings.*

```c#
private class DummyObject : FrameworkElement
{
    public static readonly DependencyProperty ValueProperty =
        DependencyProperty.Register("Value", typeof(object), typeof(DummyObject), new PropertyMetadata(null));

    public object Value
    {
        get { return (object)GetValue(ValueProperty); }
        set { SetValue(ValueProperty, value); }
    }

    public DummyObject(object dc)
    {
        DataContext = dc;
    }
}
```

Now, the method is simple:

```c#
private static IEnumerable _EvaluateBinding(object item, BindingBase binding)
{
    var dummy = new DummyObject(item);
    BindingOperations.SetBinding(dummy, DummyObject.ValueProperty, binding);
    return dummy.Value as IEnumerable;
}
```

This allows the client to create whatever `HierarchicalDataTemplate` they want, specifying the source for child items, without having to use a specific data type for each level in the hierarchy. This addresses the second point from the list way up there at the top.

Lastly, we need to find the data template. This one was tricky and took up most of my time. At first, I tried the traditional method of finding a resource, `TryFindResource()`, but this always returned null. Per MSDN, this is supposed to traverse up the visual tree looking for a resource with a specified key. But apparently it doesn't search merged dictionaries very well (if at all). I had to write that functionality. So here it is in all of its glory.

```c#
// Searches the local visual tree resources, up to the window, then
// searches the application resources.
private HierarchicalDataTemplate _FindTemplate(Type key)
{
    HierarchicalDataTemplate template;
    return _SearchUpToWindow(key, out template) || _SearchDictionary(Application.Current.Resources, key, out template)
               ? template
               : null;
}

private bool _SearchUpToWindow(Type key, out HierarchicalDataTemplate template)
{
    FrameworkElement currentHost = this;
    while (currentHost != null)
    {
        if (_SearchDictionary(currentHost.Resources, key, out template)) return true;
        currentHost = currentHost.Parent as FrameworkElement;
    }
    template = null;
    return false;
}

// Searches the specified resource dictionary and its merged dictionaries for the key.
private static bool _SearchDictionary(ResourceDictionary resources, Type key, out HierarchicalDataTemplate template)
{
    var resourceKey = resources.Keys.OfType<DataTemplateKey>().FirstOrDefault(k => (Type)k.DataType == key);
    if (resourceKey != null)
    {
        template = resources[resourceKey] as HierarchicalDataTemplate;
        return true;
    }
    foreach (var source in resources.MergedDictionaries)
    {
        if (_SearchDictionary(source, key, out template)) return true;
    }
    template = null;
    return false;
}
```

With that done, the client can put their data templates just about anywhere in the application.

## And I'm Spent

Wow! That was a lot more than I expected when I started this series. If you made this far, please apologize to whomever you've had to ignore while reading it.

Next time, we'll take a way to implement data that can be very flexible.