---
layout: post
title:  "How to Version Assemblies Destined for Nuget"
date:   2016-01-21 17:00:00 +1300
tags: nuget package version
excerpt_separator: <!--more-->
---
Okay. Seriously. Versioning of third-party Nuget packages has been the bane of my existence for the past week. Nuget declares that packages under its system should follow Sematic Versioning, and that's great... for the package. But it becomes a problem when the same versioning scheme is followed for the assembly.

<!--more-->

## What is Semantic Versioning?

Basically it's a versioning system that's different (and I think a bit easier to understand) than Microsoft's system. Instead of four numbers, you have three.

| Microsoft                  | Semantic          |
| :------------------------- | :---------------- |
| Major.Minor.Build.Revision | Major.Minor.Patch |

Semantic versioning brings in the idea that each number carries meaning behind it, especially for libraries. (I can't see trying to use this versioning scheme for an application.)

Major releases are releases that contain breaking code. If you want to upgrade to a new major version of a library, be prepared to change your code to support the new version.

Minor releases contain new non-breaking functionality. You can safely upgrade to the new version without worrying that your existing code will fail, and you'll have access to new functionality.

Patch releases contain things like bug fixes and performance enhancements. There should be no concern about compatibility when upgrading to a new patch version.

## Sounds great! What's the problem?

To understand the problem, we need to review a couple things:

- How assembly versions work.
- How Nuget manages dependencies.

### Assembly versions

When you create a project in Visual Studio (whether executable or library), you'll get a *AssemblyInfo.cs* file in the *Properties* folder. This file contains all of the information pertinent to the assembly as a whole.

Here's the important stuff from a sample file:

```c#
// Version information for an assembly consists of the following four values:
//
//      Major Version
//      Minor Version 
//      Build Number
//      Revision
//
// You can specify all the values or you can default the Build and Revision Numbers 
// by using the '*' as shown below:
// [assembly: AssemblyVersion("1.0.*")]
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
```

This section defines the version properties for the assembly. If you'll notice there are two different versions.

- Assembly Version. This is the version that .Net looks at during run-time for loading packages and finding types.
- Assembly File Version. This defines the version reported by the OS to other applications like Windows Explorer.

And then there's Nuget. Nuget doesn't use either of these. It uses a third versioning attribute: `AssemblyInformationalVersion`. It uses this attribute because nothing else seems to care about it. The informational version isn't used by the OS or by .Net, which means it's available for Nuget to claim. All we have to do is add it.

***NOTE** The information version is only required if you use a script to automatically build the .nupkg file that is uploaded to Nuget.org. If you're building your packages manually, like I do, then you don't need it.*

So what do we do? We remove the comments because they don't apply to semantic versioning, and we add the version attribute that Nuget wants to see.

```c#
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.0.0.0")]
[assembly: AssemblyInformationalVersion("1.0.0")]
```

Notice that the informational version only contains three numbers. This is important. Nuget will actually apply whatever is in that string as the package version. This means that we can use versions like `1.0.0-beta` for prerelease versions, and everyone plays nicely.

### Nuget dependency management

Nuget has a really nice feature built into it: the packages can define dependencies on other packages. This extends down to the package version as well.

What's more is that the package can declare a range of versions that should be compatible. This was done to maximize the possibility that substituting a newer version would be as painless as possible.

Let's look at an example. Manatee.Json, my awesome JSON package, is currently at version 3.2.1. It depends on Manatee.StateMachine for parsing JSONPath strings. Manatee.StateMachine is currently at version 1.1.2, but I want to be sure that if Manatee.StateMachine is updated to 1.1.3 or 1.2.0 it can replace the 1.1.2 package without breaking the dependency. But I don't want to allow a breaking change. So in the Manatee.Json Nuget package, I declare the dependency as `[1.1.2,2.0.0)`. This means that I should be able to let Nuget manage the package dependencies without having to worry about compatibility.

### Enter the ~dragon~ problem

Now bear with me. This example is a bit contrived, but the scenario seems to happen more often than you might think.

Let's say you're building an application that needs to read JSON from a file and... do... things. You do your research and come to the correct conclusion: Manatee.Json is the best.

Also, you decide that you want some business logic to be managed by a state machine, and you decide to use Manatee.StateMachine since you already have a reference to it from Manatee.Json.

During development you find that I've added an awesome feature to Manatee.StateMachine that you want to utilize, so you upgrade to 1.2.0. Nuget doesn't have a problem with it because the version is within the compatible range. Once you get the code to a state where it will build, you run the app.

`MissingMethodException`. The exception reports that it can't find a method which is clearly there. If it weren't the solution wouldn't build. Looking at the exception message more closely, you find that the run-time is looking for the method in Manatee.StateMachine version 1.1.2.

Wait... what?!

Yes. Even though your code knows to look for version 1.2.0 Manatee.Json is looking for 1.1.2. .Net can't find that version of the assembly, so it throws up.

## The Solution

Unfortunately, you're down to two options:

- Downgrade Manatee.StateMachine to version 1.1.2 and not use the awesome new feature, or
- Email me and (politely) inform me that Manatee.Json should reference the latest version.

You don't want to downgrade, so you email me. I reply that Nuget should manage dependencies properly, but I'll publish a new version because that's just good customer service.

## The Real Solution

Ultimately the problem was really in how I declared my assembly versions in Manatee.StateMachine:

```c#
[assembly: AssemblyVersion("1.1.2.0")]
[assembly: AssemblyFileVersion("1.1.2.0")]
[assembly: AssemblyInformationalVersion("1.1.2")]
```

When the code in Manatee.Json references this library, the run-time is looking specifically for the 1.1.2 version. The compiler builds and encodes that it must use this version in order to run. When we give it 1.2.0 instead, .Net complains.

.Net doesn't know about compatible versions or semantic versioning. It only knows that it was built with a specific version, and so it must use that version and nothing else. To the run-time all other versions are incompatible.

So let's think about how to remedy this.

- .Net must be able to use any version we deem compatible.
- It'd be nice to be able to determine which version of a library we have once the app has been installed.
- Nuget must be able to differentiate between versions.

For the second and third numbers, we can use the semantic version, like we're doing now.

For the first, though, we know that compatible versions will be the one we build against and any version up to, but not including, the next major version. In order to have .Net view all of these versions as the version it needs, we only use the major version.

The attributes become:

```c#
[assembly: AssemblyVersion("1.0.0.0")]
[assembly: AssemblyFileVersion("1.1.2.0")]
[assembly: AssemblyInformationalVersion("1.1.2")]
```

Now .Net will look for version 1.0.0.0, when we view the assembly in Windows Explorer, it'll show 1.1.2.0, and Nuget will create a 1.1.2 package.

When Manatee.StateMachine is eventually upgraded to 2.0.0, indicating that there are breaking changes, we want .Net to complain so we update the assembly version to 2.0.0. But it stays there for all 2.x.x versions.

This is how it should be done. And to be fair, the Nuget documentation isn't clear about this. It seems, however, that most developers who publish on Nuget update the assembly version to the package version, so I know I'm not the only one experiencing this pain.

But I'm sure that you already version your Nuget packages this way. I'm just preaching to the choir.