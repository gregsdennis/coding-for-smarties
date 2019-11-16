---
layout: post
title:  "They Think of Everything!"
date:   2017-03-25 17:00:00 +1300
categories: c# language rave
---
Ordinarily I like to pontificate on the merits (or detriments) of particular code design decisions.  Instead today, I'd like to share a neat consequence of C# 6 that I found the other day.

We're all familiar with the null-conditional operator `?.` when accessing members (properties/functions).  What you may not immediately see is the ability to use the `?` when accessing an object via indexers.  Check it out:

```c#
var value = myObj?[5];
```

As you might expect, this line of code returns `myObj[5]` when `myObj` is not null, or `null` if it is.

What I find interesting is that reading the code, it makes sense, but it's not something that I immediately considered when learning about the `?.` operator.

I guess what's really happening here is that the real operator isn't `?.` but merely `?`.  After this operator, you can access the data on the object, and it magically checks for null before proceeding with the access!

---

After writing this, I thought it sounded like I'm a total noob to .Net.  I don't even care.  It's nice that I can still learn basic things.