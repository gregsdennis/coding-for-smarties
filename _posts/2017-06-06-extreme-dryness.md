---
layout: post
title:  "Extreme DRYness"
date:   2017-06-06 17:00:00 +1300
tags: architecture
excerpt_separator: <!--more-->
---
I ran across an interesting scenario at work today that I think merits some discussion.  In this post, I'll cover what DRY is, and when following it religiously may actually cause problems.

<!--more-->

## What is DRY?

DRY is an acronym that stands for Don't Repeat Yourself.  The basic premise is that we shouldn't write any code block more than once.  If we use it in multiple places, we need to encapsulate it.

This leads to better maintainability in that we only have to update one block of code if we want the functionality to change.  It also leads to better readability more in line with Single Responsibility Principle.

## Taking it too far...

Let's start with the final code.

I was writing NUnit tests for a few (28) mapper classes today.  Each of the mappers implements the same interface:

```c#
interface ITypeMapper<TFrom, TTo>
{
    TTo Convert(TFrom source);
}
```

***NOTE** This is a bit of a contrived example.  I'm doing so because this post isn't about the mapper, but rather its test.*

The test looks like this:

```c#
[TestFixture]
public class MyMapperTests : MapperTestBase<int, string>
{
    public static IEnumerable TestCases
    {
        get
        {
            yield return new TestCaseData(1, "1.0");
            yield return new TestCaseData(135, "135.0");
            yield return new TestCaseData(6816, "6816.0");
        }
    }

    public override ITypeMapper<int, string> GetMapper()
    {
        return new MyMapper();
    }
}
```

Not really a whole lot functionally in there.  No test methods; just some test data.  Let's dig a bit deeper.

```c#
public abstract class MapperTestBase<TFrom, TTo>
{
    public static IEnumerable TestCases { get; }

    [TestCaseSource(nameof(TestCases))]
    public void Convert(TFrom source, TTo expected)
    {
        var target = GetMapper();
        var actual = target.Convert(source);

        actual.ShouldBeEquivalentTo(expected); // a little FluentAssertions magic
    }

    protected abstract ITypeMapper<TFrom, TTo> GetMapper();
}
```

To quote Buffalo Springfield, there's something happening here; what it is ain't exactly clear.  I'll break this down a bit, but I really want to address the reason this code exists at all.

***SUMMARY** In short, the `TestCaseSource` attribute can be detected by the test runner (I use Resharper's runner), but we need to be sure we put the `TestFixture` attribute on the derived class declaration.  Then when the test runs, it searches the current test fixture (the derived one) for a static property called `TestCases` to supply the various test cases.*

## What have I done?

I don't want to dive too deeply into how I derived this base class.  This post isn't about that.

Instead I'd like to start (or more likely continue) the conversation on when blindly following design and coding principles yields bad code, which is contrary to their purpose.

This code isn't really bad.  I like to think that it's rather creative, but I am somewhat biased since I wrote it.

Still, it doesn't read well at first.  According to [this post on readability](https://simpleprogrammer.com/2013/04/14/what-makes-code-readable-not-what-you-think/), readability can be measured by the level a developer would need to be to adequately understand what's going on without having to ask someone questions.

This code in particular, I think, would require at minimum an intermediate-level developer to correctly parse.

Then you have to ask yourself, do we want all of our code to be junior-readable, or do we just want to write awesome code?  I'd argue that writing better code, exposes the more junior developers to increase their code-reading skills.  And isn't training those in our posterity part of our job description?

What are your thoughts?