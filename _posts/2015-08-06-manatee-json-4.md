---
layout: post
title:  "Manatee.Json (Part... Oops!"
date:   2015-08-06 17:00:00 +1300
tags: c# json
excerpt_separator: <!--more-->
---
The last time we looked at code, we covered user-defined serialization between data models and JSON. Today, we would have reviewed auto-serialization, but I've hit a snag. I recently did some performance testing, and found that Manatee.Json was quite slower than its nemesis, Newtonsoft.Json (or more familiarly, Json.<span></span>Net).

<!--more-->

## The Test

I don't know what inspired me to do the testing. Probably just a stray thought. Regardless, I set up my test procedure. At GameStop, we've been building some microservices that use REST APIs, so that seemed like the perfect place to get some real-world JSON to work with.

My initial test made a call and downloaded the JSON. I then proceeded to deserialize the JSON structure (still as a string) to my object model. This went swimmingly. Manatee outperformed Newtonsoft each time. I was in a happy place, but I couldn't see that large of a difference; it was just enough to know that mine was faster.

***NOTE** Sadly, I don't have the numbers on the single runs anymore. You'll just have to trust me that it was faster.*

Then I decided to exaggerate the results by running through the deserialization 10,000 times. This is where I died a little inside. Newtonsoft was killing Manatee. (Yes, Newtonsoft kills manatees every day... it's horrible, and something needs to be done.)

I had performed the test using both Manatee's `IJsonSerializable` and the autoserializer against Newtonsoft's `Convert.Deserialize<T>()` static method. Consistently, I received these results:

| Method                                 |    Time     |
| :------------------------------------- | :---------: |
| Manatee.Json using `IJsonSerializable` |  38s – 39s  |
| Manatee.Json using autoserializer      |  52s – 56s  |
| Newtonsoft.Json                        | 1.6s – 1.7s |

## Considering the Results

So how did Manatee beat Newtonsoft in the single run, but lose so badly with 10,000 iterations? Well, I don't know. I'm sure there's some manner of caching involved, but it's probably more than that.

The one that really puzzled me was that the `IJsonSerializable` serializer performed so poorly. Then I realized that my deserialization is actually a two-part process: parse to a JsonValue then deserialize to the object model. So I set up one more test: parse once, then deserialize 10,000 times. The timing was set up on just the deserialization so that parsing wasn't included.

| Method                                 |   Time    |
| :------------------------------------- | :-------: |
| Manatee.Json using `IJsonSerializable` | 3.8s – 4s |
| Manatee.Json using autoserializer      | 15s – 17s |

So, wow, it's taking a really long time to parse strings. At least 2/3 of the first test was just parsing the text!

This whole experience was my come-to-jesus moment for this library. I have some things to re-evaulate.

## Next Steps
So now I'm faced with a couple options:

Admit defeat and just let Newtonsoft continue its near-monopoly of the JSON arena
Realize that my concept of a dedicated JSON object model is better, and I simply need to make it more efficient.

Personally, I like the second option. I'm taking this as a challenge. Can I make my architecture as speedy as Newtonsoft? Honestly, I don't know, but that's my goal.

I'm not really doing this to take down Newtonsoft. I mean, if Manatee.Json somehow surpassed it in downloads to knock it off of its throne, it'd be frickin' awesome, but I don't expect it to. Newtonsoft was chosen by Microsoft as the default JSON serializer. In fact, they have a hard dependency on it built into their WebApi Nuget packages (more on this in another post). Each time someone downloads the WebApi packages, they also end up downloading Newtonsoft.Json, so its downloads just keep going up. It's going to be extremely hard to catch it.

For me, this is a learning experience. That's how my career in software started: a self-issued challenge. Practice will only make me better. Clearly, I have some work to do, so I'll be suspending posts on Manatee.Json for a while.

Next time, we'll discuss... something else.