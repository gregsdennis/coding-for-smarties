---
layout: post
title:  "The Disparity between APIs and SDKs"
date:   2016-09-08 16:00:00 +1300
tags: software deep-thoughts
excerpt_separator: <!--more-->
---
I think it's time for us all to accept the truth:  I'm abandoning the plugin series.  I had a functioning proof of concept at my previous job, but I didn't think to grab it when I left and moved halfway around the world, and I don't feel like trying to recreate it right now.  Maybe I'll come back to it someday.  Instead, today we're going to talk about APIs and why there are so few SDKs to consume them.

<!--more-->

## What is this API of which you speak?

Application Programming Interfaces (or APIs) seem to be everywhere these days.  The idea is that you want to allow other developers to have access to your application or data without them having to interact with your application directly.  There could be many reasons for this: automation, reporting, mobile applications, or maybe just a new UI.


Mostly, these APIs are exposed over the internet, as websites like [Trello](http://developers.trello.com/advanced-reference), [Twitter](https://dev.twitter.com/rest/public), and [E\*Trade](https://developer.etrade.com/ctnt/dev-portal/getArticleByCategory?category=Documentation) do.  More recently, software architecture has seen the microservice architecture, which often means hosting and consuming APIs on the same machine.  In either case, these APIs are merely web-based services (often using REST with JSON-encoded data).

Through these APIs, programmers now have a mechanism to interact with the applications that other people create.  For instance, if you want to add a card to a list on your Trello board, you just need to POST to

```
https://api.trello.com/1/cards/
```

with the data about the card you want to create encoded in JSON.

## APIs sound nice.  What's the problem?

The domain doesn't exactly translate over the API.  Most APIs do a fair job of serializing the data in such a way that the consuming developer can infer the data structure, but it's still up to that  developer to create an object model that can be manipulated easily within their application.  In my experience, this is a tedious process which is not always done right.

## That sounds like a problem.

The solution is the SDK, or Software Developer's Kit.  An SDK is a library or collection of libraries designed to consume a specific API.  The nice thing about SDKs is that they provide an object model which properly represents the data being sent.

It seems to me that the best person to build an SDK is the same person who created the API.  They have first-hand knowledge of the domain.  I would think that if a developer creates an API, they would want others to consume it.  And what better way to have people to consume your API than with an SDK?

## So why do we see so few SDKs?

Well, the solution to granting access to your application is actually the problem: the API.  In order to allow *anyone* to consume them, APIs have to be generally language-agnostic.  That means I can create an API in JavaScript that you can consume in .Net, or PHP... or VB 6.  But a single, global SDK for all languages *cannot* be created; I'd have to create a separate SDK for each language or framework that my clients might use.  You can see an example of this with [E\*Trade's SDK page](https://developer.etrade.com/ctnt/dev-portal/getContent?contentUri=Downloads-DocumentationSDKDownloads).  They have SDKs for Java, PHP, and C++, likely because their website is built using these technologies, which means they have expertise in these specific areas.

If I'm building a microservice architecture, I can be fairly sure that I know all of the technologies that will be used to consume it, so I *could* create SDKs in those cases.  However, for public APIs, I have no idea who may consume it.  Because it's quite lot of work to build an SDK, and I'd have to actually build multiple versions, I generally just don't.  It's not laziness; it's a conscious decision.  Letting other developers create SDKs is the approach that [Trello](https://developers.trello.com/community) has taken.

So we leave it to the consumers to create their own SDKs.  There are a couple primary advantages to this.  As mentioned before, an API author doesn't have to anticipate the language or framework that their client will use, so that saves work for them.  Secondly, the client is free to create their own domain model, leaving out portions of the data that they may never use.

As a result, SDKs are created by those who need them.  However, there are often developers who recognize that they may not be the only ones who have a need for that particular SDK and will publish their hard work for free (usually open source) or paid use.

These are the real heroes.
