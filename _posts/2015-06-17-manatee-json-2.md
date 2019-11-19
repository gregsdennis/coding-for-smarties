---
layout: post
title:  "Manatee.Json (Part 2: Parsing)"
date:   2015-06-17 17:00:00 +1300
tags: c# json
excerpt_separator: <!--more-->
---
We've been reviewing my open-source JSON library, Manatee.Json. [Last time](../../05/31/an-introduction-to-manateee-json) we built an object model for the language. Today, we'll cover parsing, or converting a string with JSON content into our object model. Let's start with a short review of the syntax.

<!--more-->

## JSON as a Language

[JSON.org](http://json.org/) has a great review of the language, including some fantastic flow charts illustrating the syntaxes of each part. Here's a brief summary.

- **Null** – For this we use the keyword `null`.
- **Boolean** – Two more keywords are used to represent this type: `true` and `false`.
- **Number** – This may be any decimal-formatted number, including scientific notation.
- **String** – This is any series of Unicode characters contained between double quotes `"`. The only characters which must be escaped are `"`, `\`, and control characters. This is because `"` is used for the beginning and end of strings, `\` is used as the escape character, and control characters cannot be propertly represented in text. In addition there is a syntax for encoding the hexadecimal code point of a Unicode character.
- **Array** – Arrays are comma-delimited lists contained within square brackets, `[` and `]`. Arrays can be of any size (within system limitations) and can contain any mixture of types.
- **Object** – Objects are comma-delimited lists of key-value pairs contained within curly braces, `{` and `}`. A key-value pair uses a string for the key and a value of any type. The key and value are separated by a colon :.

## Breaking it down

In general parsing strings consists of several steps: finding tokens, checking syntax, then assembling the model. Manatee.Json actually performs these three steps simultaneously as it iterates over the string, but for each token, these steps are taken in turn. For now, let's review each step, and then we'll see it all put together.

### Finding Tokens
For JSON identifying which token we have is actually quite easy. We can create an array of tokens by iterating through the characters based on the rules and symbols discussed above. In short, the following table gives the characters and the tokens to which they map.

| Character          | Token                       |
| :----------------- | :-------------------------- |
| `{`                | OpenBrace                   |
| `}`                | CloseBrace                  |
| `[`                | OpenBracket                 |
| `]`                | CloseBracket                |
| `"`                | Quote (string)              |
| `:`                | Colon (key/value delimiter) |
| `,`                | Comma (item delimiter)      |
| `-`, `0`–`9`, `.`  | Number                      |
| `T`, `t`, `F`, `f` | Boolean                     |
| `N`, `n`           | Null                        |

***NOTE** You may have noticed I don't have any whitespace characters listed. That's because Manatee.Json strips all whitespace not contained within string values before processing.*

Note that we only map the starting characters of our tokens. It's really all we need. We assume the syntax is correct for now and make tokens. Checking syntax is not our current responsibility.

Let's look at an example.

```c#
{
    "string":"a string value",
    "array":[
        "an array of",
        4,
        "values",
        true
    ],
    "null":null
}
```

If we were to tokenize the entire string, we'd end up with

```
OpenBrace,
    Quote, Colon, Quote, Comma,
    Quote, Colon, OpenBracket,
        Quote, Comma,
        Number, Comma,
        Quote, Comma,
        Boolean,
    CloseBracket, Comma
    Quote, Colon, Null
CloseBrace
```

That's really all there is for tokenizing. We have now devised a model on which we can check syntax. So let's do that; let's do exactly that.

### Check Syntax
Long ago, when I was first learning about programming, I thought my teacher was on the cutting edge by teaching us C++. I didn't realize that in 1995, C++ was already fairly established (by more than a decade). Even so, one of the assignments that we had was to build a finite state machine for parsing mathematical expressions (in prefix, or operator-first, format) and using it to build an expression tree. I took it a bit farther and make one that could parse limited infix (operand-operator-operand, a.k.a. “human readable”) expression strings. I was really impressed with myself... until I got a graphing calculator. But I digress.

The point of telling you that is the finite state machine that we built all those years ago is still the basis for checking syntax that I use today. The premise is this:

1. You are in a state.
1. You receive an input.
1. Processing that input should put you in another state.
1. Repeat 2 & 3 until there are no more inputs (or until an 'end' input is found).

The nice thing about this is that the logic can be laid out in a simple matrix, with states as the rows and inputs as the columns. The cells contain an action to take and return the state in which you find yourself afterward. This, in essence, hardwires the syntax logic, making computation faster (you don't have to have stacks of if-else or switch statements to go through). And it has a nice side effect of cleaning up the code considerably.

When you really get down to it, there are two matrices we need to make because there are two different syntaxes: object and array. All other values are just that: values. Simple values can be easily parsed without any complex logic.

For arrays:

| ▼ STATE / INPUT ► | array `[`                      | object `{` <br> string <br> number <br> boolean <br> null | `,`            | `]`                      |
| :---------------- | :----------------------------- | :-------------------------------------------- | :------------- | :----------------------- |
| **start**         | goto *value*                   |                                               |                |                          |
| **value**         | add *value*<br>goto **delimiter** | add *value*<br>goto **delimiter**                |                | *end* (empty array only) |
| **delimiter**     |                                |                                               | goto **value** | *end*                    |

For objects:

| ▼ STATE / INPUT ► | object {                     | array [ <br> number <br> boolean <br> null | string                       | ,        | :          | }                       |
| :---------------- | :--------------------------- | :-------------------------------- | :--------------------------- | :------- | :--------- | :---------------------- |
| **start**             | goto **key**                     |                                   |                              |          |            |                         |
| **key**               |                              |                                   | store *key*<br>goto **colon**         |          |            | *end* (empty object only) |
| **colon**             |                              |                                   |                              |          | goto **value** |                         |
| **value**             | add *key/value*<br>goto **delimiter** | add *key/value*<br>goto **delimiter**      | add *key/value*<br>goto **delimiter** |          |            |                         |
| **delimiter**         |                              |                                   |                              | goto **key** |            | *end*                     |

To implement these tables, we use the same approach as with my math expression assignment from school. For Manatee.Json, I ended up putting together a generic state machine, [Manatee.StateMachine](https://github.com/gregsdennis/Manatee.StateMachine). I'll leave the details of how that works for another post. For now, a brief overview will suffice.

Manatee.StateMachine is a generic state machine (defining the state type and input type) which allows the user to specify functions which take the current input, do stuff, and then return the new state. While it was designed specifically to support Manatee.Json, it is quite powerful and can even be modified during evaluation, yielding potentially unlimited states. Furthermore, Manatee.StateMachine is designed to be able to evaluate multiple owners simultaneously. In this way, a single instance of the state machine can be created and different objects can use it without issue.

For each state/input intersection, we define a function which is to run. That function is given the input received as well as the owner of the state machine execution (for context) and is expected to return the next state.

In `JsonArray`:

```c#
StateMachine[State.Start, JsonInput.OpenBracket] = GotStart;
StateMachine[State.Value, JsonInput.OpenBrace] = GotValue;
StateMachine[State.Value, JsonInput.Quote] = GotValue;
StateMachine[State.Value, JsonInput.Number] = GotValue;
StateMachine[State.Value, JsonInput.Boolean] = GotValue;
StateMachine[State.Value, JsonInput.Null] = GotValue;
StateMachine[State.Value, JsonInput.OpenBracket] = GotValue;
StateMachine[State.Value, JsonInput.CloseBracket] = GotEmpty;
StateMachine[State.End, JsonInput.Comma] = GotEnd;
StateMachine[State.End, JsonInput.CloseBracket] = GotEnd;
```

In `JsonObject`:

```c#
StateMachine[State.Start, JsonInput.OpenBrace] = GotStart;
StateMachine[State.Key, JsonInput.Quote] = GotKey;
StateMachine[State.Key, JsonInput.CloseBrace] = GotEmpty;
StateMachine[State.Colon, JsonInput.Colon] = GotColon;
StateMachine[State.Value, JsonInput.OpenBrace] = GotValue;
StateMachine[State.Value, JsonInput.Quote] = GotValue;
StateMachine[State.Value, JsonInput.Number] = GotValue;
StateMachine[State.Value, JsonInput.Boolean] = GotValue;
StateMachine[State.Value, JsonInput.Null] = GotValue;
StateMachine[State.Value, JsonInput.OpenBracket] = GotValue;
StateMachine[State.End, JsonInput.Comma] = GotEnd;
StateMachine[State.End, JsonInput.CloseBrace] = GotEnd;
```

The `Got*` methods are the kind of functions we discussed before, taking an input, doing stuff, and returning a state. Here's an example from `JsonArray`.

```c#
private static State GotValue(object owner, JsonInput input)
{
    var array = owner as JsonArray;
    array._value = JsonValue.Parse(array._source, ref array._index);
    return State.End;
}
```

Within the context of this method, `_source` is the string, and `_index` is the current parsing index of the string. Notice how when we get a value, we simply defer to `JsonValue's` parsing logic.

### Build the Model

As mentioned before, parsing basic values is implemented very simplistically. We look at the input character and use a switch statement to determine the proper parsing technique.

|Character| Parsing Logic|

| `"`             | 1. Scan the input string for the next `"` (but not `\"`).<br>2. Extract that substring.<br>3. Process the substring for delimited characters.                                                                                                                                         |
| :------------ | :----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `[`             | Use `JsonArray` to parse.                                                                                                                                                                                                                                                  |
| `{`             | Use `JsonObject` to parse.                                                                                                                                                                                                                                                 |
| Anything else | 1. Scan the input string for the next `,`, `]`, or `}`.<br>2. Extract that substring.<br>3. If it's `true`, `false`, or `null`, use the appropriate type, otherwise<br>4. Assume it's a number and use `Double.TryParse()`. If that fails throw a `JsonValueParseException` (we don't recognize it). |

Now that we have our `JsonArray`, `JsonObject`, and `JsonValue` parsing logic, let's put all of the steps together.

### Integrating the Steps

There is a delegate property on the state machine which allows us to run a method after each input evaluation: `UpdateFunction`. We're going to use this to actually get the next input from the string. This will help us integrate the steps so that with each input, we translate the character to our input enumeration, run the input through the state machine, and parse the appropriate value.

For both `JsonArray` and `JsonObject`, we assign the `GetNextInput` method. Here's the method from the `JsonArray` class.

```c#
private static void GetNextInput(object owner)
{
    var array = owner as JsonArray;
    if (array == null) return;
    if (array._done || (array._index == array._source.Length)) return;
    var c = default(char);
    try
    {
        c = array._source[array._index++];
        var next = CharacterConverter.Item(c);
        array._stream.Add(next);
    }
    catch (KeyNotFoundException)
    {
        throw new JsonSyntaxException("Unrecognized character '{0}' in input string.", c);
    }
}
```

Let's expand on those instance variables so that you can see what's going on.

- `_done` – This is an indicator that we have completed our array (we've received the `]`) and we can stop parsing. It's set in `GotEmpty` and `GotEnd`.
- `_source` & `_index` – The array keeps a reference to the input string and the current parsing index. This allows all of these methods to remain disjoint from any particular `JsonArray` instance.
- `_stream` – This is a queue of our input enumeration type. With this implementation, there really should only ever be one item in the queue, but Manatee.StateMachine allows for a filled queue from the outset. Building it here just works out better for us.

Also referenced in this code is `CharacterConverter`. This is our mapping from characters to our input enumeration. It has the potential to throw a `KeyNotFoundExcption`, so we catch it and rebrand it as our own `JsonSyntaxException`.

That's the final piece. Now we just need to run the state machine and handle any exceptions that result. The internal `Parse` method from `JsonArray` looks like this:

```c#
private int Parse(int i)
{
    _stream.Clear();
    _value = null;
    _index = i;
    _done = false;
    try
    {
        StateMachine.Run(this, State.Start, _stream);
        if (!_done)
            throw new JsonSyntaxException("Found incomplete JSON array.");
    }
    catch (InputNotValidForStateException<State, JsonInput> e)
    {
        switch (e.State)
        {
            case State.Start:
                throw new JsonSyntaxException("Expected '['.");
            case State.Value:
                throw new JsonSyntaxException("Expected a value at array index {0}.", Count);
            case State.End:
                throw new JsonSyntaxException("Expected either ',' or ']' after array index {0}.", Count);
            default:
                throw new IndexOutOfRangeException();
        }
    }
    catch (StateNotValidException<State>)
    {
        throw new JsonSyntaxException("An unrecoverable error occurred while parsing a JSON array. Please report to littlecrabsolutions@yahoo.com.");
    }
    catch (ActionNotDefinedForStateAndInputException<State, JsonInput>)
    {
        throw new JsonSyntaxException("An unrecoverable error occurred while parsing a JSON array. Please report to littlecrabsolutions@yahoo.com.");
    }
    catch (JsonSyntaxException e)
    {
        e.PrependPath(string.Format("[{0}]", Count));
        throw;
    }
    return _index;
}
```

The various exceptions which can be thrown are as follows:

- `InputNotValidForStateException` – This is thrown when a token is unexpected. If you go back and look at those syntax tables we put together, this would be thrown for any of those blank cells. Depending on the current state, we want to handle this differently.
- `StateNotValidException<State>` & `ActionNotDefinedForStateAndInputException<State, JsonInput>` – These mean that something is wrong with our logic and the state machine is set up incorrectly. This should never happen. We want feedback on these.
- `JsonSyntaxException` – A value didn't parse properly. Capture the local point in the JSON structure and rethrow.

And that's a general overview of parsing. Feel free to [download the source](https://bitbucket.org/gregsdennis/manatee.json/src) to have a closer look.

Next time, we'll start in on arguably the most useful aspect of JSON: serialization.