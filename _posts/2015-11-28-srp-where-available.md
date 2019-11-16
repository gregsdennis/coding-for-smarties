---
layout: post
title:  "SRP (where available)"
date:   2015-11-28 17:00:00 +1300
categories: deep-thoughts
excerpt_separator: <!--more-->
---
# SRP (where available)

I was watching WALL-E with my children the other day... Okay, I'll be honest. I put on WALL-E for my children the other day, then watched it with my wife while both of our kids ran around the house all crazy-like. Anyway, the movie was on, and the final scene struck a chord with me. It shows a shot of the earth with a hazy cloud of satellites surrounding it.

<!--more-->

![WALL-E Earth](images/wall-e-earth.png)

***COOL SITE** DailyMail.com posted an [interactive map](http://www.dailymail.co.uk/sciencetech/article-3152148/) of all of the stuff we've put in orbit. It's remarkable how crowded it is up there.*

## Why do we have so many satellites?

Of course, one main reason is that different governments, corporations, and other organizations have different purposes for each one. If you think about it, we have satellites for astronomy, telecommunications, weather tracking, espionage, and a host of other functions.

Interesting: one function per satellite. That sounds a lot like the Single Responsibility Principle (SRP) that we use in software. This wonderful ideal greatly aids us in software design, but it seems it may actually hinder us in other areas, specifically those where space is a premium.

A prime example of where SRP hurts is printed circuit board (PCB) layout and design. Imagine trying to build a circuit board for a modern touch-screen cell phone while only having chips that provide individual capabilities. You'd have to have to include chips for:

- cellular communication
- wifi
- bluetooth
- nfc
- sound
- graphics
- touch
- general processing
- data storage
- and many more...

This problem has been recognized in the compact electronics industry, and as a result, chips are designed to combine many of these features. This combination of functionality into a single device enables us to create things like FitBit and Raspberry Pi.

## So why does SRP work so well for software development?

There are two primary reasons we want SRP for software.

First, space is not really considered a premium in the digital realm. In reality, we're only limited by storage (which is much bigger than any software we could write) and data transfer rates (which are becoming faster daily).

The second is code maintainability. When we segregate the functionality of each class, we gain several benefits:

- Code complexity is reduced by being more explicit and straightforward
- Readability is greatly improved
- Coupling is generally reduced
- Your code has a better chance of cleanly evolving

([source](http://codebetter.com/karlseguin/2008/12/05/get-solid-single-responsibility-principle/))

In short, SRP makes our jobs as developers easier, even if it is a bit more planning and effort.

## Can we reconcile these differences?

I don't really think that we need to. Rather, I feel that the people putting objects in orbit need to follow the pattern that the PCB industry has put forth. Combine functionality of these satellites. Surely it must be less expensive to put up one satellite that combines five features than to put up five satellites. Maybe that will requrie some level of inter-organizational cooperation that we as a race are not comfortable with yet.