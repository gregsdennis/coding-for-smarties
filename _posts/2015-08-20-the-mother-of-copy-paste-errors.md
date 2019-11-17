---
layout: post
title:  "The Mother of Copy/Paste Errors"
date:   2015-08-20 17:00:00 +1300
tags: update
excerpt_separator: <!--more-->
---
Sometimes, when we're building an application, we need to run a script either before or after the build process. Fortunately, Microsoft took this need into consideration when they built Visual Studio. There, in the project properties, under Build (Compile if your one of those weird VBers), you have two multiline text boxes in which you can write your scripts: one for pre-build, and one for post-build. They even give you a button which opens a window with a scrollbar for when your script is more than three lines long. But still, something seems to be off with it. And this “something” is the primary cause of (read: what I'm blaming for) my latest computer panic/fiasco.

<!--more-->

## What Happened? Tell me everything.

Over the past few weeks, I have been attempting to develop a proof-of-concept WPF application that uses plugins in separate application domains. This has been a challenge since WPF doesn't natively support multiple AppDomains. But I was determined to make it happen. (I did finally make it work, but that's another story.)

As part of my solution, alongside the main application and other projects, I made a project to implement a simple plugin. I opened the project properties and pasted in a build script from another plugin project I was working for my job. The script was simple.

1. Make sure the plugin root folder was there,
2. Make sure the individual plugin folder was there,
3. Delete anything that may be in that folder, and
4. Copy the output from the project to that folder.

So I copied the script and modified the folder names for the new POC app. Because I'm so efficient, I edited the folder at the first entry in the script, copied it, and pasted it into the other entries. After all was said and done, this is what it looked like.

![Visual Studio Text Editor](../../../images/build-script.png)

*Awesome. Now build. For some reason, my other instance of Visual Studio just crashed. Odd, but not too concerning. Hang on, the build is stuck. Ctrl+C to halt it. Now other applications are having problems. Maybe something just went haywire on my box. I'll just restart and see if that fixes it.*

Nope. Restarting didn't fix it. Every application that starts when I log in was giving me hell. Then I saw my desktop. Every file was missing. The folders were there, but the files were not. I tried opening a new Explorer window from my icon on the taskbar. Windows said the file it references is missing and asked if I wanted to delete it. *Win+R explorer* brought up a new window, so I know that the application is still there... that and Windows is running.

Not knowing what else to do, I close the lid to my laptop and take it to Desktop Support, the group who fixes things when things go wrong. You may think it odd that I, a developer, have to take my computer to someone else to have it fixed, but I'm an expert at code ([StackOverflow](http://stackoverflow.com/)). They're experts at fixing my computer ([SuperUser](http://superuser.com/)).

## The Assessment

The symptoms were all there; it looked like a hard drive failure. So they imaged a new computer for me and migrated what user files they could salvage (including my POC project). It took almost a full day for this to happen (Installing Windows updates, etc.). It took another half-day to install all of my dev software and reconfigure my computer to the way I like it. That was Thursday and Friday.

## No Safety Net

At home the next day, I decide to break out the new laptop and try to catch up on some of the work that I missed. I looked over the email traffic, and didn't find anything that required my personal attention. So I loaded my plugin POC solution, made some edits, and rebuilt. The build was hanging again. So I freaked out a little. Then I stopped the build. Then I tried to open a new Explorer window. Same error saying it can't find the file. I freaked out some more. Then I opened Explorer via the *Run...* command.

This time it was worse: *all* of the files up to the Windows directory were missing. The strange thing was that it left the folder structure. I couldn't figure it out. It being Saturday, I didn't really want to, so I shut down and left the computer alone until Monday.

But it ate at me. *What could it be?!* I finally concluded that it had to be the build script. I had just recently added it, and somehow it had to have deleted all of the files from the computer. I just couldn't figure out where. It's supposed to delete the files from the plugin folder only. How would it have access to the entire drive?

## The Assessment (Redux)

Come Monday, [I took it in to Desktop Support again](https://www.youtube.com/watch?v=6aVzEOjGQBg). I said it happened again, and asked if he still had my backup. He did (in my head I thank God while jumping around like a three-year-old waiting for an ice cream cone). While he set up my computer for another round of the day-long restoration process, I described my theory of how it happened and asked to get a couple files from the backup onto a USB drive. He obliged, so I copied the POC project file to have a look at the build script.

While my computer was being restored, I went to another computer and loaded the project file in the nearest text editor (Notepad) and extracted the post-build. This is what I saw:

```batch
if not exist C:\Plugins MD C:\Plugins
if not exist C:\Plugins\CirclePlugin MD C:\Plugins\CirclePlugin 
del C:\Plugins\CirclePlugin \*.* /f /s /q
copy $(TargetDir) C:\Plugins\CirclePlugin
```

And there it was, staring me in the face. A space. If you missed it, look again on the `del` line, right after `CirclePlugin`.

After some research on the `del` command, I found out that you can actually use it to delete multiple files by providing a list of items. That space meant that I want to delete everything in the `C:\Plugins\CirclePlugin` directory as well as anything in the `\` directory matching `*.*`. That second one is the root folder of the drive! Here's what the switches mean

- `/f` – Force delete. Deletes all files, even if they're read-only.
- `/s` – Recursively search all subfolders.
- `/q` – Quiet mode. Don't show a confirmation.

Yep. That'll do it.

## The Culprit

This section could also be titled *I'm a Moron*. I should have checked my copy/paste before running the script. But that thought lead me to another. I was pretty sure I at least glanced over it, if for no other reason than to make sure the folders were correct. That's when it hit me: Visual Studio's text box uses a variable-width font. That space is nearly imperceptible. Even if I *had* been looking for it, I still might have missed it. I'm sure some of my readers did (not you, of course... other readers).

And why did it insert the space when all I wanted to paste was the folder name?

While I know that I share some of the burden in this, I'm happy to blame Microsoft for not giving that field the fixed-width font it should very plainly have.

## The Lesson

I've learned a couple things from this experience, and I thought that others could benefit from my misfortune.

- Copy/Paste is a bitch. Never trust it. Always verify what is pasted.
- Pre- and post-build steps can get you into some serious trouble. Always check it two, three, five hundred and sixty six times, whatever it takes to make sure that it won't do something horrible.

Next time, we'll have a look at writing code from a slightly different viewpoint.