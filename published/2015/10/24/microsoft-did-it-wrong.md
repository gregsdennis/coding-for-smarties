# Microsoft Did It Wrong

It's been several years since Microsoft announced that Newtonsoft's Json.<span></span>Net would be the default JSON serializer. If you deal with JSON communication over the web at all, you probably already know this. It's not exactly news.

However, there does seem to be a small desire among those in the web development community who would like to use alternate serializers. Personally, I'd like to use my own serializer, Manatee.Json. I originally created it out of a dissatisfaction with Json.<span></span>Net, and naturally (and perhaps from some bias) think it to be superior.

Even so, Microsoft made their decision. In particular, I don't have a problem with them choosing a *de facto* serializer, but what puzzles me is that they have actually hard-coded references to the library within their own.

## So what's wrong with that?

They have created a hard dependency on a particular implementation of a service. Anyone familiar with the SOLID principles would immediately see that this violates the 'D' (Dependency Inversion).

The Dependency Inversion Principle states

> Depend upon abstractions. Do not depend upon concretions.

This means that within the code for the WebApi package, Microsoft should have created abstractions (like abstract classes or interfaces) and referenced only those rather than any particular implementation.

But they didn't, instead creating a hard dependency on Json.<span></span>Net. Now anyone who wants to use a different serializer must also download Json.<span></span>Net in order to prevent a `FileNotFoundException` thrown when the run-time is looking for the DLL and can't find it.

***NOTE** To be fair, Microsoft did create an abstract class to allow others to use their own serializers, but the issue here is that they directly reference Json.<span></span>Net.*

This gives me a sad. I spent quite a lot of time trying to make a Manatee.Json.WebApi library that would include a `MediaTypeFormatter` implementation that used Manatee.Json as the serializer. But in the end, I found that it was a useless venture since anyone who downloads one of the WebApi nuget packages would also download Json.<span></span>Net due to this dependency. I can hardly expect people to go out of their way to download and use my library unless Json.<span></span>Net just doesn't perform right for their specific application. But the fact is that for most applications, it does well. In addition, why download one library when another competing library automatically downloads with it?

## What they should have done

Instead of hard-coding a reference within their library, they should have only used the MediaTypeFormatter base class and released another library with their Json.<span></span>Net implementation. Better yet, Newtonsoft should have either:

- released the MediaTypeFormatter implementation in a separate library, or
- included the implementation in Json.<span></span>Net.

This way, the client can hook up the implementation in their bootstrapper or when they configure the web client. It's one extra line of code and not too much to ask of a client developer.

Then anyone who wanted to use their own serializer could create their own implementation of MediaTypeFormatter and hook that up instead without having to download Json.<span></span>Net.

## Doing it right

I did recently have an application for which Json.<span></span>Net just wasn't doing the trick. I was trying to abandon RestSharp in my Manatee.Trello library and use WebApi instead.

When I created Manatee.Trello, I recognized that my clients may not want to use my choice of serializer or REST client. I coded the main Manatee.Trello library to interfaces: `ISerializer` and `IDeserializer` for the JSON part and `IRestClientProvider` for the REST part. Manatee.Trello defines these interfaces but implements neither. The implementations are published in separate Nuget packages, Manatee.Trello.ManateeJson (backed by Manatee.Json) and Manatee.Trello.RestSharp (backed by RestSharp). In earlier versions, I also created a Manatee.Trello.NewtonsoftJson, but I've since dropped that and removed it from Nuget since configuration of Json.<span></span>Net became more and more difficult due to increasingly complex requirements inside Manatee.Trello.

***NOTE** If someone out there wanted to create a Json.<span></span>Net implementation for Manatee.Trello, they're welcome to. I don't wanna.*

In addition, the REST provider only interacts with the serializer interfaces with no references to any particular implementation.

This gives my clients a lot more flexibility. If they want to use a different serializer, they just need to implement `ISerializer` and `IDeserializer` and provide their implementation to the Manatee.Trello configuration. Similarly with the REST provider.

Enter WebApi. Because I created the architecture above, all I had to do was implement `IRestClientProvider`. In this implementation, I needed to created a MediaTypeFormatter that only depended on `ISerializer` and `IDeserializer`. That way, any JSON implementation could be used, and I already had one in Manatee.Trello.ManateeJson!

## The moral of the story

So now there's a Manatee.Trello.WebApi that works just as SOLID and modern software architecture intends, but since WebApi has a hard dependency on Json.<span></span>Net, you end up downloading that package as well. You would think that Microsoft, a leader in software development, would have thought to create this level of independence.

**Don't do this to yourself or your clients.** Always follow the Dependency Inversion Principle. Don't tie yourself to a particular implementation of anything. It'll pay off in the end.

## Bonus material

One thing I figured out as a part of this adventure is that Nuget inflates the download numbers of a package by counting when that package is a dependency of some other package. This means that every time you download Manatee.Trello.ManateeJson, you increase that package's download stats and those of Manatee.Trello and Manatee.Json.

So when you download WebApi, you download Json.<span></span>Net, regardless of whether you plan to use it or some other serializer, increasing the download count of both packages.

Although it was a long shot even before Microsoft wrote this dependency, it's likely my Manatee.Json serializer stats of 7,217 downloads will never catch up to Json.<span></span>Net's 19,157,482 downloads.