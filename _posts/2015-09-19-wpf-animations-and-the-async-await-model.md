---
layout: post
title:  "WPF Animations and the Async/Await Model"
date:   2015-09-19 17:00:00 +1300
tags: c# wpf threading
excerpt_separator: <!--more-->
---
I recently encountered this little gotcha at work, and thought it could benefit others, so... here you go.

<!--more-->

When you start an animation in WPF from code and then make an awaitable call, the animation fails to show until the call is complete. Why is this?

As an example, suppose we have this click handler on a button:

```c#
private async void _Button_Clicked(object sender, EventArgs e)
{
    firstAnimation.Begin();

    await _SomeAsyncCall();

    secondAnimation.Begin();
}

private Task _SomeAsyncCall()
{
    Thread.Sleep(5000);
}
```

Let's test it! When we click the button, we see... nothing. For five seconds anyways. Then we'll see both animations happen together (or if the first animation was less than the async call, it'll jump to the end or you just won't see it).

The issue here lies in the Dispatcher and how the async/await model tries to minimize threads. We all know that the async/await model runs tasks asynchronously, but what is less commonly known is that it attempts to do so on the thread from which it's called. In this case, we're making the async call from the UI thread. And since animations have such low priority, they're pushed aside to allow the call to complete first.

Here's the sequence of events occurring in this scenario:

1. The button is clicked, calling the handler method _Button_Clicked().
1. The first animation begins.
    - Internal to the animation, a management task is sent to the Dispatcher to handle the animation. The Dispatcher must complete its current task before moving on to the next one, so the task gets placed in a queue.
1. The async call occurs.
    - A task is sent to the Dispatcher to handle the call. Just as before, the task is placed in the Dispatcher's queue.
    - This time, we have an await, so the method actually ends here. The rest of it is part of a task continuation (Task.ContinueWith()). The continuation is treated as another task and will be placed in the queue once this task completes.
1. Since the method has ended, the Dispatcher is now free to select the next task. It does this by priority, and since the animation has an ultra-low priority, the async call wins.
1. The async call completes, but there is a continuation on the task. This is placed in the queue.
1. The Dispatcher makes another selection, which is the continuation, further deferring the animation.
1. The second animation begins, placing a management task in the queue, ending the continuation task.
1. The Dispatcher is now free again to make another selection, and it can handle both animations normally.

Now that we know what's going on, how can we fix this? The problem seems to be that the async call is being performed on the UI thread, so we need to move it to its own thread. To do this, we must abandon the glorious async and await keywords and manually implement tasks.

```c#
private void _Button_Clicked(object sender, EventArgs e)
{
    firstAnimation.Begin();

    Task.Run(_SomeAsyncCall)
        .ContinueWith(result => secondAnimation.Begin());
}

private void _Dispatch(Action action)
{
    if (Dispatcher.CheckAccess())
        action();
    else
        Dispatcher.Invoke(action);
}
```

By using the `Task.Run()` method, we've forced the call to `_SomeAsyncCall()` to be performed on a second thread. This means that the Dispatcher can use the UI thread to run the first animation. Once the async call ends, the continuation picks up on the thread we created, and the second animation can begin.

We need to be careful here because the animation must run on the UI thread. In order to ensure that it does, we have to verify that we have use the `Dispatcher.CheckAccess()` method. If we have access, we just run it; otherwise, we have to pass it to `Dispatcher.Invoke()` and let the Dispatcher run it.

Now, when we run the application and click the button, we see the first animation, then after five seconds, we see the second animation run, just as we wanted.