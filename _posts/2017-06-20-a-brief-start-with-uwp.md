---
layout: post
title:  "A Brief Start with UWP"
date:   2017-02-20 17:00:00 +1300
categories: c# uwp wpf
excerpt_separator: <!--more-->
---
At work I was recently assigned to a UWP app.  This post chronicles my discoveries over the first couple days.

<!--more-->

## A first glance

I was fortunate enough to be assigned to this project after it had already started.  This gave some time for some other developers (maybe a couple who already had some experience with UWP) to lay down some framework.

When I first opened the solution, I set about reviewing the overall architecture:

- The business logic is housed in an API that will be hosted in Azure.  This leaves just validation concerns for any UI.  Good.
- There are a few light-weight UI projects on various platforms (UWP for Windows, Xamarin Android, and a Xamarin iOS planned).  Nice.
- For the clients, they decided to go with MvvmCross, which (as you may guess) is a cross-platform MVVM framework.  This way they can create the UI-layer logic in one project (the view model) that's shared, and then wire up a UI layer project for each platform.  For WPF, I've used a modification of Caliburn.Micro, but this is cool, too.  It'll be interesting to see the differences.

Overall, I like this project.  The solution is well-organized.  On to the UWP project.

## Diving into UWP

I have a fair amount of experience with WPF, which is the precursor to UWP, so I figured there would be some learning, but I should be able to just hit the ground running without too many problems.

My first task was to assess the state of the application and apply my experience.  I found a couple red flags.

### Styles organization

The styles were all located in a single, giant XAML file which was then referenced in every single view.  This is a problem because each reference to the file creates a new `ResourceDictionary` instance.  If you have multiple views loaded simultaneously, you have mulitple copies of every style in that file.  Even if you know that you'll load only one view at a time, UWP has to build that `ResourceDictionary` each time the view changes.

To address this, I reorganized all of the styles in separate XAML files based on its target type.  Then I created a single *Styles.xaml* file that referenced them in the `MergedDictionaries` property.  Then I created a *Generic.xaml* file which merged the *Styles.xaml* file, and put all of the XAML files into a *Themes* folder.

```
- MyProject.UWP
	- Folder1
	- Folder2
	- Themes
		- Styles
			- Buttons.xaml
			- TextBoxes.xaml
			- ...
		- Styles.xaml
		- Generic.xaml
	- Folder3
	- ...
```

Then I went to reference *Generic.xaml* in *App.xaml* and found that they had defined all of their brushes directly in that file... and on some `ThemeDictionaries` property that I've never seen.

A little research... okay.  UWP has this new property that makes theming apps easier.  Basically, they work like `DynamicResource` except that the collections are keyed.  This resource dictionary was keyed as "Default."  The idea is that we could define multiple sets with brushes of the same keys and change out the sets at run time.  The app then uses the new set like nothing happened.  It's like changing Visual Studio's theme from "Light" to "Dark". 

I didn't like the idea of them being defined directly in *app.xaml*, so I moved them to *DefaultBrushes.xaml* alongside *Styles.xaml*.  Then I added them to the `ThemeDictionaries` property within *Generic.xaml*.  Okay, *app.xaml* is clean; now I can reference *Generic.xaml*.

Once I had the XAML reorganized, I went through all of the views and removed the references to the single styles file.

Done.

*Generic.xaml* is now the root XAML file for look and feel of the application, just like in all of my WPF apps.    And because *app.xaml* references it, these resources are available throughout the application without specific references to the files that contain them.  That feels much better.

### Converters

The other issue I found had to do with converters.  This app had converters for everything:

- Boolean to Visibility
- Boolean to DataTemplate
- Boolean to Brush
- Any To Visibility (checks a collection for items)
- Any To Brush
- ... and many more!

The lack of generalization here made me cringe a little.  Also, why have a converter for switching out data templates or brushes based on view model property values?  That's what data triggers are for; converters should be for value transformation.  Lastly, for every view that needed a converter, they'd declare it in XAML.

Now, I've posted about [the use of static instances for converters](https://codingforsmarties.wordpress.com/2015/03/28/static-wpf-converters/) before, and that's the exact direction I wanted to take this.  I sent off my post to the project lead, and his response was, "Cool! Let's do it!"  So I set about fixing all of this.

I had two goals: create general-use converters, and make them static instances.

My enthusiasm about taking on this task didn't last, however.

## UWP has failed me

I first wanted to tackle the triggers issue.  If I could replace some of these converters with triggers, then I'd need fewer instances to provide that functionality.

### Writing triggers

I replaced my first use of `BooleanToDataTemplateConverter` with a data trigger.

But there was a problem:  UWP doesn't support triggers.

Instead the geniuses (not used sarcastically) who put this app together found another way to switch out the templates.  They created these converters with a couple of properties to indicate which value to use as output based on the input.  (For example, `BooleanToDataTemplate` has `TrueTemplate` and `FalseTemplate` properties.)  Okay.  I get it.  I'll leave that one.  Let's move on.

### So many converters

Next up, generalizing the converter classes for re-use.

I had an idea for all of the boolean-to-*something* converters.  I'd create a boolean-to-object multi-converter, pass in the view model property binding first, then bindings for the values I wanted to switch out.  Within the converter, I'd cast the first item in the `values` array to `bool` then, based on its value, return either the second or third item.  It's like a XAML version of the C# `?:` statement. 

But there was a problem:  UWP doesn't support multi-bindings, so no multi-converters either.

Then I had an idea for the any-to-*something* converters.  In working in WPF I found a way to create a markup extension that functioned as a converter and allowed me to specify a sequence of converters through which I'd pass the view model property.  (I'll do a post on this someday.)  Using this, I could create a `HasItemsConverter` and combine that with the `BooleanToVisibilityConverter` to achieve has-items-to-visibility conversions.  This has the added benefit of being able to use the has-items converter elsewhere if I needed to.

But there was a problem:  UWP doesn't support custom markup extensions.

Then I figured I might at least be able to implement my static converter instances concept.  So I found one of the converters that doesn't have any of those extra properties (e.g. `TrueValue` & `FalseValue`), and I make it a singleton.  Then I find where it's used and use the `x:Static` extension to reference the instance.

But there was a problem:  UWP doesn't support the `x:Static` markup extension.

So, as it turns out, the way that it's implemented *is* the best way to do it.  And now I find that I'm stuck with a bunch of specialized converters, all of which have to be declared in XAML.

## Ollenol ("all in all", but like the medicine I had to take)

That's where I am today: working with an MVVM framework I'm unfamiliar with, on a WPF-like-but-not-quite application, while missing some very handy WPF tools.  Honestly, it feels like a step backward.