# An Introduction to Manateee.Json (Part 1: Object Model)

Today we're going to start in on my open source JSON library, [Manatee.Json](https://bitbucket.org/gregsdennis/manatee.json). In this post, we'll quickly review JSON as a language and build an object model.

## What is JSON?

JSON stands for JavaScript Object Notation. As you might have guessed, it integrates seamlessly with JavaScript. It's widely used as an alternative for XML, which means that other languages need to be able to work with it as well. From my experience, it's just as flexible as XML, but it's much more compact and human-readable.

There are six basic types:

- **Object** – This is nothing more than a string-based key/value collection. The keys are strings and the values can be any other JSON type.
- **Array** – This is an ordered collection of values. Again, any JSON value is valid in an Array; even mixing values types within a single array is valid. Coming from a .Net background, you may think that an array should only contain one type of object. In JSON, that's not the case.
- **String** – This is a sequence of Unicode characters surrounded by double-quotes. There are some rules around the higher-range of Unicode, but we'll cover that when we come to parsing.
- **Number** – Any numeric value. This can be in any common decimal format, even scientific notation.
- **Boolean** – This uses the special keywords `true` and `false`. According to the specification, they must be lowercase, but I haven't seen an implementation yet that enforces that rule while reading JSON.
- **Null** – This uses a special keyword `null` which means there is no value.

We'll review the syntax a bit when we get to parsing in the next post. If you'd like to learn more about it now, please visit json.org. Understanding the basic structure is all we need to build an object model. But before we do that, let's take a step back. I'd like to explain why I created yet another JSON library in an already robust market.

## See a need, Fill a need

Some time ago, I worked for a company that built cockpit instrumentation panels for (usually military) aircraft. Part of that was also building components for simulator systems. One client had required that these simulator components communicate with the control computer using JSON. That is when I was introduced to the language.

As part of building these components, I realized that I needed a way to easily test the communication, which in turn meant that I needed a desktop application that could parse and validate the JSON received from the device. Initially, I looked into Newtonsoft's Json.<span></span>Net, but I couldn't figure it out. I was looking for an object model, an analog to `XDocument`, but I couldn't find it. Eventually I gave up and just wrote my own in my spare time.

Once I got it going, I realized that perhaps there were likely other people who were having the same problems with the (unquestionably) most downloaded JSON library on Nuget. I decided to take my chances and release it to the masses as open-source.

The goals of Manatee.Json:

- Expose the object model of the JSON so that its structure can be easily created, navigated, and manipulated.
- Provide an API which can be learned quickly, yet is powerful enough to do everything we need it to do.
- 
I feel I have succeeded in creating a JSON library which is easier to understand and use.

## Building an Object Model
The first step I took in creating the object model was to look at the various types and see how they could be represented in .Net.

- **Object** – Can be represented by `Dictionary<string,something>`. Let's create an explicit type called `JsonObject`.
- **Array** – Can be represented by `List<something>`. Create `JsonArray` : `List<something>`.
- **String** – Um... `string`.
- **Number** – There are several numeric representations in .Net. Considering the options, I chose `double`. Reflecting on it, I suppose I could have chosen `decimal` for a bit more accuracy considering that JSON numbers are base-10, but I haven't had any problems yet (nor have I received any input suggesting it).
- **Boolean** – Um... `bool`.
- **Null** – This can be represented by making a globally-known (static) property on whatever `something` ends up being.

Now we need to figure out what `something` is. Let's consider what functionality we want to keep and what we want to avoid. I'd like to have a type that allows us to represent any of these types in a strong manner, yet also avoid casting if possible. There are several options:

- We could use `object`, but then we lose strong typing. We'd have to test and cast every value which comes out of the structure.
- We could use an interface. We'd then have implementations which encapsulate each of these .Net types. There is no common functionality which applies to all of these types, so we still lose strong typing because we'd have to test and cast the interface before we can really do anything with a value.
- We could create a concrete type which exposes properties for each type. Now we have something. Encasupsulation of all of the JSON types in one .Net type is the key.

So now we can create our JSON value object. Let's call it `JsonValue`. I know. Creative, right? `JsonValue` has several properties to expose the other types. It's pretty straightforward.

- `Type` – Gets the type of value which is held.
- `Object` – Get the value as a `Dictionary<JsonValue>`
- `Array` – Get the value as a `List<JsonValue>`.
- `String` – Get the value as a `string`.
- `Number` – Get the value as a `double`.
- `Boolean` – Get the value as a `bool`.

There's also a static `JsonValue.Null` property to represent the JSON value `null`. We also want `JsonValue` to be immutable, like a string; once created, it can't be changed. So we want read-only properties and a set of constructors which initialize one of the properties and set the appropriate type.

Now that we have a model, let's make it awesome to use.

## Bells and Whistles

As it stands, we can create new `JsonValue`s by calling one of the constructors:

```c#
var number = new JsonValue(5);
```

This will create a number-valued `JsonValue`. This is fine, but what if we wanted to create a `JsonArray` and initialize it with values?

```c#
var array = new JsonArray
    {
        new JsonValue(5),
        new JsonValue("hello")
    };
```

This can get quite complex, especially when you consider that JSON can be extensively nested. So what we want is a simpler way to declare these complex hierarchies. Let's define some implicit casts.

***NOTE** I understand that there is a semantic difference between a conversion and a cast. It is implied that the object you get out of a cast is the same object, just in a different shape; whereas a conversion yields a new object. Technically, we are converting with these implicit casts, but I feel the benefit of creating clean, concise code is worth it.*

So for each type we create a simple implicit cast which yields a JsonValue containing the appropriate type and value.

```c#
public static implicit operator JsonValue(JsonObject o)
{
    return new JsonValue(o);
}
...
```

Now, we can write the above declarations as:

```c#
JsonValue number = 5;
JsonValue array = new JsonArray {5, "hello"};
```

On top of simplifying the array intialization, we have also allowed declaring the variable as `JsonValue` without having to explicitly pass it into the constructor. It's almost as simple as it would be with JavaScript, which is the idea.

Lastly, we override the equality methods (`Equals()` and `GetHashCode()`) and overload the equality operators.

***NOTE** The JSON specification states that array equality implies a sequential equality. So if two arrays contain the same values but in a different order, they are not considered equal.*

And that wraps up our object model. Next time, we'll take a look at how Manatee.Json parses JSON in string data to build up the object model.