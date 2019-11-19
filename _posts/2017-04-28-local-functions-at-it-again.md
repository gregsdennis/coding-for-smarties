---
layout: post
title:  "Local Functions, At It Again"
date:   2017-04-28 17:00:00 +1300
tags: c# language rant
excerpt_separator: <!--more-->
---
I thought I got out everything during [my rant about the new C# features](../05/c-sharp-7-features-i-dont-like), but apparently I missed something...

<!--more-->

I was working on a WPF app for work and I used this to check if the code I wanted to execute could do so on the current thread (a common task in WPF development):

```c#
Action action = () =>
    {
        // do stuff
    };

if (Dispatcher.CurrentDispatcher.CheckAccess())
    action();
else
    Dispatcher.CurrentDispatcher.BeginInvoke(action);
```

Looks good.

Well Resharper, being the passive aggressive helper that it is, suggested that I convert the `action` variable to a local function, which resulted in this:

```c#
void Action()
{
    // do stuff
}

if (Dispatcher.CurrentDispatcher.CheckAccess())
    Action();
else
    Dispatcher.CurrentDispatcher.BeginInvoke((Action) Action);
```

Take a long look at that last line.  Now, instead of creating an `Action` from a lambda expression, I have to **cast a method** to an `Action`.  How is this better?