---
layout: post
title:  "The Art of Coding"
date:   2015-09-16 17:00:00 +1300
tags: deep-thoughts
excerpt_separator: <!--more-->
---
We often hear about a turning a field from an art into a science, but we rarely (if ever) hear about turning a science into an art. I assure you it's there, and I assert that one without the other is usually a horrible thing.

<!--more-->

If you have science without art, you'll end up creating products that function but are not very appealing. Case in point: NyQuil. The stuff tastes horrible, but it works. Even the "cherry" flavored kind isn't very good, and it certainly doesn't taste like cherries.

Going the other direction, we have things that are very appealing but don't function well. Remember Windows Vista? It looked pretty, but it was an abomination of an operating system. Microsoft very quickly released Windows 7 in order to correct the shortcomings of Vista.

## So what about pure art?

Some might say that a "pure art," like music, cuisine, or painting, doesn't have any science in it. They're wrong. These fields have a lot of science in them.

Even disregarding the mathematical nature of tones and rhythm, music still has a considerable amount of science. Considering psycology, studies have been performed attempting to correllate why we have different emotional reactions to certain kinds of music. In the ones that I have read, it was found that there are many factors that can influence this. Higher tempos combined with deep percussion can cause the body to increase adrenaline causing a tenser feeling, whereas strings playing longer notes in minor keys can invoke sadness. What's amazing is that certain "formulas" can be devised to produce specific emotions. Composers have known this for centuries, but these studies exposed them as distinct techniques.

Chefs have to consider several scientific fields when employing their culinary craft. Like music, they have to know what is considered pleasing (psychology). But they also have to know what is healthy (biology) and how certain ingredients will react with each other (chemistry). With this knowledge, new foods are created daily in kitchens around the world. Chefs have to know their craft, even if they may not understand the "lab-science" side of it.

Also, any UX person will tell you there is a science to color selection, matching, and grouping. Certain colors look better together. Sure, there is a deep element of style, which you can see by looking at the various color schemes of the past few decades. But in the end, you can see that there seems to be a common idea about which colors belong together, even if the particular scheme is unpopular in a given culture.

## How does this apply to software?

For this discussion, let's put the aforemented UX part aside and consider only the application itself. Better yet, let's think about web services and other applications where there is no UI.

I've been programming in some capacity for almost two decades now. When I started taking computer science classes in high school, I found it akin to learning math.

In learning math, there are generally two phases. You learn how do perform the math, then you learn why this technique works. Sadly, most people get frustrated with the how and give up before ever getting to the why, which is the part that I find most interesting. Although I received what I could at best consider a primer on proofs in high school geometry, I didn't really learn how to prove theorems properly until I reached college. It was there I realized that there is an inherent beauty to developing a proof. I've heard mathematicians calling some proofs "beautiful" and "elegant." These are words we typically use in an artistic sense. Many times these descriptions coincide with the sheer simplicity of one solution over another, more commonly known approach. If something so rigorous and structured as math can have beauty and elegance, surely anything can.

So we come to software. No human language is nearly as structured as the various programming languages we've developed over the relatively brief history of computing. Mostly this is due to the need for a compiler to be able to interpret them, and that usually means a simple, straightforward language makes a simple compiler. However, even transcending the structure of the language, we find that developers have a particular style about their code. In fact we have entire software packages built around code formatting and refactoring just to allow the developer to easily maintain their personal coding style. Resharper and StyleCop are two examples in the .Net sphere.

But the art extends beyond the code. We see it in the architecture. Not just at the application level, but at the system level as well. And the common thread seems to be the same as it is in math: a simpler solution seems more elegant and beautiful. So that's what we as developers strive for: the simplest solution.

Now, the simplest solution doesn't necessarily mean the shortest code or the easiest or fastest to develop. Over the past decade or so, there has been a huge push for maintainability. This means that it's not in our best interest to create an obese monolithic application, which was the pattern in the past, but to divide the application into smaller parts, each of which have a distinct purpose. We can see this trend with architectural paradigms like MVVM (Model-View-ViewModel) and SOA (Service-Oriented Architecture).

The curious thing is that when we apply these paradigms, our code base usually (if not always) grows. It seems counter-intuitive that a larger code base is easier to maintain, but you also gain organization, which means it's easier to identify problems or make modifications.

## Um... I thought we were discussing art.

Think back to when you first started coding, even the first few years. Most of us would agree that if we were to dig up some of those programs, we'd be appalled by them. Many of us would have to reformat the code just to figure out what it does. (I remember receiving a colleague's code that had no discernable indentation pattern. Random lines were indented a random mixture of spaces and tabs. He was a PCB designer. I didn't let him code anymore. Maybe that could have been handled better.) But if you continue to ponder those days, you'll realize that you were just learning *how* to code, not necessarily the *why* of what you were doing.

> When we create an if-else, we indent the functional parts under each clause. We do this so that the scope of this set of statements is clear while reading the code.

It's pretty easy to teach the *how* and *why* of indentation rules together. But what about a design pattern?

> To create a singleton, we need to create a static instance and make the instance constructor private.

That's the *how* of singletons. It really doesn't get much simpler than that. But [there is no why](https://www.youtube.com/v/TJ8KIzkCAto?start=1&end=3&autoplay=1). Why do we want to create a singleton? When is the best scenario to use this pattern? These questions can't be answered as simply as the rules for indentation. And while we can teach the rules which answer these questions, it's harder to teach why these rules exist. Mostly that comes from the experience of not following said rules and reaping the consequences. It certainly has for me.

## Dude... Art.

Right. Sorry.

I was raised in the Church, believing Jesus is my savior and that God created everything. When I was young, this was in conflict with my more logical, scientific nature. At some point during my adolescence, I had a realization that resolved this conflict. Science and religion aren't in conflict; they are in concert. While science strives to tell us the *how*, religion is telling us the *why*.

***NOTE** I understand that the Bible also very specifically describes the how, particularly in regard to the Creation, but I reserve that for another non-code-related post.*

The situation is similar with science and art. It seems to me that the science is detailing how things work, while the art is trying to describe why a particular solution is used.

Does our code work? Hopefully. That means that there is some science and structure to the program. But why did we structure it that way? Simply because we read some architecture book that said this is the best way?

Why do we bother to style the code? Most compilers don't care; certainly not for most C-based languages.

To become great developers, architects, engineers, etc., we certainly must know how to do the job. But it's not until we know the why behind what we do that we really flourish.

Strive to understand *why* things work. It's not the science of coding that makes you great. A lot of people know *how* to code. It's the **art of coding** that separates the great from the good.

*Why* do you code? *Why* do you make a particular architectural decision? And for goodness sake, *why* do you indent with spaces and not tabs?