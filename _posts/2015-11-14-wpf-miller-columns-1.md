---
layout: post
title:  "WPF Miller Columns, Part 1"
date:   2015-11-14 17:00:00 +1300
categories: c# wpf
excerpt_separator: <!--more-->
---
Today we're going to look at a very useful UI element: [Miller Columns](https://en.wikipedia.org/wiki/Miller_columns). If you've ever worked in a Mac environment, you'll probably recognize this from the [Finder's column view](https://www.google.com/search?q=finder+column+view&safe=active&espv=2&biw=1920&bih=955&source=lnms&tbm=isch&sa=X&ved=0CAYQ_AUoAWoVChMIutnoqPeQyQIVjCsmCh2Wgwzr). In fact, Apple likes to use this mechanism throughout their operating system and within various applications. But we rarely see them (if ever) in a Windows environment. (Why is that?!)

<!--more-->

## An Overview

Miller Columns are a way of displaying hierarchical data that utilizes a series of lists to show the items at each level. You start with a single list of top-level items. When an item is selected, a new list appears to the right (or to the left for right-to-left reading cultures) displaying the subitems. This continues with each list.

Microsoft seems content to only display hierarchical data in a [tree-view](https://www.google.com/search?q=finder+column+view&safe=active&espv=2&biw=1920&bih=955&source=lnms&tbm=isch&sa=X&ved=0CAYQ_AUoAWoVChMIutnoqPeQyQIVjCsmCh2Wgwzr#safe=active&tbm=isch&q=tree+view). This is advantageous in that you can see the contents of multiple items simultaneously. However, it is less useful for vertically challenged UIs (determined more by the control's container than actual display real estate). In these cases it's nice to have an alternative to the vertically-oriented tree view. This is the bread and butter of Miller Columns.

Oddly enough, it's rather hard to find a complete, off-the-shelf Miller Column control for WPF. I couldn't find one in my [searching](https://www.google.com/webhp?sourceid=chrome-instant&ion=1&espv=2&ie=UTF-8#q=wpf%20miller%20columns) (my SO question is at the top of the list). So let's build one!

***BONUS MATERIAL** Given that I'm the more technically-oriented person of the house, you might expect that I'm also the better computer user. I'm not. That title belongs to my wife, especially when it comes to finding things online. She's a wonder; I'm usually lucky to find Google.*

For this post, we will be reviewing the [solution I posted on StackOverflow](http://stackoverflow.com/a/10720725/878701) some years ago. In the next post, we'll examine this approach and see if we can improve it.

## Let's Build It

Before we dive into code, let's take a look at the requirements:

1. Start with a single list displaying options.
1. As an item is selected, a new list appears (expanding horizontally) showing sub-options.
1. Wash, rinse, repeat.

So it seems that, at a high level, we need to dynamically generate `ListBox`es horizontally. To do this, let's plan on hosting the `ListBox`es in an `ItemsControl`. By default, the `ItemsControl` is backed by a vertically-oriented `StackPanel`. We need it to expand horizontally, so we'll need to override the panel.

As it turns out, the XAML for this is quite simple. It's exactly what we've described above.

The `DataTemplate` for the items:

```xml
<DataTemplate x:Key="DataNodeStackedDataTemplate" DataType="my:DataNode">
    <ListBox ItemsSource="{Binding Children}"
             Style="{StaticResource StackedListBoxStyle}"/>
</DataTemplate>
```

*What settings are in that style?!*

The `ItemsControl`:

```xml
<ItemsControl x:Name="MillerColumnsView" VerticalContentAlignment="Stretch"
              ItemTemplate="{StaticResource DataNodeStackedDataTemplate}">
    <ItemsControl.ItemsPanel>
        <ItemsPanelTemplate>
            <StackPanel Orientation="Horizontal"/>
        </ItemsPanelTemplate>
    </ItemsControl.ItemsPanel>
</ItemsControl>
```

So this gives us the structure. Now we need to provide some functionality. So when an item in one of the `ListBox`es changes, we need to generate the appropriate `ListBox`es behind it.

***NOTE** So it looks like I posted code on SO that made sense to me at the time. Looking at it now, I realize I was assuming some context without communicating it. This sounds like an important lesson which may generate another post here sometime.*

```c#
private void StackedListBox_SelectionChanged(object sender,
                                             SelectionChangedEventArgs e)
{
    // Get the ListBox whose selection changed.
    var lb = sender as ListBox;
    if (lb == null) return;

    // Get the data context of the ListBox
    var dn = lb.DataContext as DataNode;
    if (dn == null) return;

    // Remove all ListBoxes after the one that changed
    int index = MillerColumnsView.Items.IndexOf(dn);
    if (index == -1) return;
    index++;
    while (MillerColumnsView.Items.Count > index)
        MillerColumnsView.Items.RemoveAt(index);

    // If the new selected item doesn't have children, we're done.
    if (dn.Children == null) return;

    // This Select() method was defined on DataNode.  Apparently,
    // it had to do some things in the background in order to
    // make the new set of children available.  Anyway, this line
    // does that.
    dn.Select(dn.AvailableItems.ElementAt(lb.SelectedIndex));

    // Add a new list to display this node's children.
    if (dn.Children.Count() == 0) return;
    MillerColumnsView.Items.Add(dn.Children.ElementAt(0));
}
```

## That Was Easy

Well... sort of. Just in copying and annotating this code, I found a couple things I'd like to try to improve:

- It's not very MVVM because it requires that the data context is a specific type.
- I'd like to see if we can build a XAML-only solution.

Next time, we'll go over these a bit and try to resolve them. We'll also look at ways we might be able to improve the control functionally.