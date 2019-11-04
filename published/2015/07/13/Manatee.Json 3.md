# Manatee.Json (Part 3: User-Defined Serialization)

In the past couple posts, we’ve looked at JSON as a language, how to represent it in code, and how to translate between JSON in a string and our object model. Now, let’s take a look at how we can make JSON work for us.

Most notably, JSON is used as an alternative data transfer format to XML in web API calls (usually, but not exclusively, in REST services). This is accomplished through the power of serialization. Serialization is merely the conversion from a data model to a format which can be persisted or transmitted and converted back (or deserialized) into the data model at some later time. This allows us to work around difficulties such as mismatched frameworks (like Java vs. .Net) or even platforms (like Windows vs. Mac). We no longer have to worry about how bits are saved within competing data models. We merely serialize to a format everyone recognizes, and each participant can deserialize into whatever data model they need.

So how does Manatee.Json handle this? Most frameworks will serialize/deserialize directly from the data model to/from strings, bypassing (or internalizing) the JSON object model. We don’t like this approach. Rather, we want to expose the JSON object model so that customization of the output is easier.

For us, serialization all the way to a string is a two-part process.

- Serialize the object into a `JsonValue`.
- Call `ToString()` on the `JsonValue`.

Similarly, deserialization mirrors this process.

- Parse the string into a `JsonValue`.
- Deserialize the `JsonValue` into the desired object type.

This separation isn’t a lot of work for our client, and it allows serialization to focus on translating between the data model and the JSON object model instead of also having to handle string manipulation (Single Responsibility Principle).

## Methods of Serialization

When you think about it, there are really only two mechanisms that any serializer can use to serialize an object:

- User-defined serialization – The client implements their own custom serialization. This is typically the more performant option.
- Auto-serialization – The serializer analyzes the type and determines the best strategy. Usually, it reflects the requested type to determine which properties need to be included, but there are some other tricks it can use as well.

In this post, we’ll cover user-defined serialization. We’ll save auto-serialization for next time. We’ll also defer building the serializer until we’ve covered both of these mechanisms. (It’s important to know what the pieces are before we start building the final product.)

For now, let’s assume that the serializer has at least the following functionality:

```c#
public class JsonSerializer
{
    public JsonValue Serialize<T>(T obj) { ... }
    public T Deserialize<T>(JsonValue json) { ... }
}
```

This will allow us to plan ahead a bit.

## Defining Serialization for Client-Owned Code

When we write our own class, the simplest method to convert to a JsonValue is to create one using the class’s data. To let the serializer know that this class can serialize itself, we need to define an interface for the serializer to recognize. We’ll name him IJsonSerializable.

```c#
public interface IJsonSerializable
{
    void FromJson(JsonValue json, JsonSerializer serializer);
    JsonValue ToJson(JsonSerializer serializer);
}
```

Classes which implement this interface control their own fate when it comes to serialization. They can control how the data is represented in the JSON and many other aspects of serialization, like whether to save private data. This is the preferred serialization mechanism when the client defines the class to be serialized.

Consider the classic example for serialization, the Person class:

```c#
public class Person
{
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string FullName { get { return FirstName + LastName; } }
    public int Age { get; set; }
    public Color FavoriteColor { get; set; } 
}
```

***NOTE** `Color` is `System.Windows.Media.Color`. We’ll cover how this is serialized shortly.*

For this we’d want to be able to get output like:

```json
{
    "FirstName" : "John",
    "LastName" : "Doe",
    "Age" : 25,
    "FavoriteColor" : {
        "R" : 32,
        "G" : 79,
        "B" : 21
    }
}
```

To do this we merely need to implement IJsonSerializable and build the JsonValue ourselves.

```c#
public class Person : IJsonSerializable
{
    public string FirstName { get; set; }
    public string LastName { get; set; }
    public string FullName { get { return FirstName + LastName; } }
    public int Age { get; set; }
    public Color FavoriteColor { get; set; }

    public void FromJson(JsonValue json, JsonSerializer serializer)
    {
        ... // we'll come back to this in a little bit
    }

    public JsonValue ToJson(JsonSerializer serializer)
    {
        return new JsonObject
            {
                {"FirstName", FirstName},
                {"LastName", LastName},
                {"Age", Age},
                {"FavoriteColor", serializer.Serialize(FavoriteColor)}
            };
    }
}
```

***NOTE** Recall from the first post that we created implicit cast operators to convert the applicable types to JsonValue. The simplicity of this code is possible because of those casts.*

Notice that the serializer is passed into the method so that we have the option to defer serialization of our members back to the serializer. This is done so that the serializer can then select the best mechanism for serializing those types.

That’s it! The class now controls how it is converted to JSON. Deserialization is just as simple: we browse the JSON structure for the values we’re looking for and assign them to our properties.

```c#
public void FromJson(JsonValue json, JsonSerializer serializer)
{
    var obj = json.Object;
    FirstName = obj["FirstName"].String;
    LastName = obj["LastName"].String;
    Age = (int) obj["Age"].Number;
    Color = serializer.Deserialize<Color>(obj["FavoriteColor"]);
}
```

Super simple! There are some checks we could do to ensure that each value is of the correct type, but this is sufficient to understand what’s going on here.

## Defining Serialization for Other People’s Code

Very often, you will find that the type you have to serialize is not one that you create, which means that it most likely doesn’t implement IJsonSerializable. Some examples of these classes are DateTime, TimeSpan, Guid, and our Color object from the above example. We need to instruct the serializer that, for these types, we want custom output instead of what the auto-serializer would produce. It also provides a mechanism by which we can serialize types that the auto-serializer can’t quite handle (which does occur every now and then). This can be accomplished by a well-known registry which saves delegates which can perform the conversions for us; let’s name him JsonSerializationTypeRegistry.

When we register a serialization delegate, it would behoove us to also register a deserialization delegate. To get started, let’s define our delegates:

```c#
public delegate JsonValue ToJsonDelegate<in T>(T input, JsonSerializer serializer);
public delegate T FromJsonDelegate<out T>(JsonValue json, JsonSerializer serializer);
```

These are essentially the same pattern we saw in IJsonSerializable. The main difference is that we have to pass our data model into the to-JSON delegate, and it is returned by the from-JSON delegate, as opposed to these methods being defined on the data model.

Now we can build our registry. To store the delegates we’ll use simple dictionaries, keyed by Type.

```c#
public static class JsonSerializationTypeRegistry
{
    // We could use a single dictionary here where the value is the converter pair
    // so that we get both with a single lookup, but it doesn't matter in the end
    // because we'll never need both the serializer and deserializer at the same time.
    private static readonly Dictionary<Type, Delegate> ToJsonConverters;
    private static readonly Dictionary<Type, Delegate> FromJsonConverters;

    // This throws an exception if one but not both of the converter delegates is null.
    // If both are provided it adds (or overwrites) the delegates to the registry.
    // If neither is provided it removes any registered delegates for the indicated type.
    public static void RegisterType<T>(ToJsonDelegate<T> toJson, FromJsonDelegate<T> fromJson)
    {
        if (((toJson == null) && (fromJson != null)) ||
            ((toJson != null) && (fromJson == null)))
            throw new TypeRegistrationException(typeof(T));
        var type = typeof(T);
        if (toJson == null)
        {
            ToJsonConverters.Remove(type);
            FromJsonConverters.Remove(type);
            return;
        }
        ToJsonConverters[type] = toJson;
        FromJsonConverters[type] = fromJson;
    }
}
```

Now we just need to give the serializer a way to invoke the delegates. For this we define internal `Encode()` and `Decode()` methods.

```c#
internal static void Encode<T>(this JsonSerializer serializer, T obj, out JsonValue json)
{
    var converter = GetToJsonConverter<T>();
    if (converter == null)
    {
        json = null;
        return;
    }
    json = converter(obj, serializer);
}

internal static void Decode<T>(this JsonSerializer serializer, JsonValue json, out T obj)
{
    var converter = GetFromJsonConverter<T>();
    if (converter == null)
    {
        obj = default(T);
        return;
    }
    obj = converter(json, serializer);
}
```

***NOTE** I chose to make these methods extension methods because it helped me a little bit syntactically later on. They don’t really need to be extensions, though.*

These methods are fairly simple: look for a registered converter method for the type. If found, run it; otherwise, return a default value: the default value may be the proper serialization of the value. The `GetToJsonConverter()` and `GetFromJsonConverter()` orivate methods merely encapsulate a dictionary lookup.

Finally, it would be nice if the serializer could query the registry to see if a type is registered. It can’t rely on a default return value being an indication that a type isn’t registered. We can make a couple versions of a method to do this.

```c#
public static bool IsRegistered<T>()
{
    return IsRegistered(typeof (T));
}

public static bool IsRegistered(Type type)
{
    return ToJsonConverters.ContainsKey(type);
}
```

We make them public because it may also be helpful to our client to be able to query the registry.

Now that our registry is built, let’s see how it works by writing some code to serialize and deserialize that Color object and add the delegates to the registry. First, we need to define a couple methods that perform the conversions. While it’s not necessary, we can place these in a static class (remember this would be in client code, not our library).

```c#
static class JsonConversionMethods
{
    public static JsonValue ColorToJson(Color color, JsonSerializer serializer)
    {
        return new JsonObject
            {
                {"R", color.R},
                {"G", color.G},
                {"B", color.B},
            };
    }

    public static Color JsonToColor(JsonValue json, JsonSerializer serializer)
    {
        var obj = json.Object;
        return new Color
            {
                R = (byte) obj["R"].Number,
                G = (byte) obj["G"].Number,
                B = (byte) obj["B"].Number
            };
    }
}
```

Now all we have to do is register these methods, and the serializer will use them.

```c#
JsonSerializationTypeRegistry.RegisterType(ColorToJson, ColorFromJson);
```

If ever we wanted to remove the registration for `Color`, we just pass in nulls for both converter methods.

```c#
JsonSerializationTypeRegistry.RegisterType<Color>(null, null);
```

The "meat and potatoes" of the registry is done.

### Pre-registering some well-known types

Because we’re the client-minded developers that we are, we’re going to auto-register some types. The types we’ll register are:

- `DateTime`
- `TimeSpan`
- `Guid`
- `Nullable<T>`
- `T[]` (Arrays)
- `List<T>`
- `Dictionary<TKey, TValue>`
- `Queue<T>`
- `Stack<T>`

The first three should be simple: we could just create discrete methods which serialize those types. But, given our registry’s setup, we can’t just register generic delegates. For instance, given these List<T> conversion methods

```c#
JsonValue ListToJson<T>(List<T> list, JsonSerializer serializer) { ... }
List<T> JsonToList<T>(JsonValue json, JsonSerializer serializer) { ... }
```

we can register specific list types

```c#
JsonSerializationTypeRegistry.Register(ListToJson<int>, JsonToList<int>);
```

but we can’t realistically register all of them (how would we register a list of a type our client creates?), and we can’t register a generic List<T>

```c#
// This won't compile.
JsonSerializationTypeRegistry.Register(ListToJson<>, JsonToList<>);
```

What we need to do is create a mechanism that will provide the required delegates to the registry on-demand. Let’s create an interface which defines that functionality. It should also specify whether it can provide delegates for a given type.

```c#
internal interface ISerializationDelegateProvider
{
    bool CanHandle(Type type);
    JsonSerializationTypeRegistry.ToJsonDelegate<T> GetEncoder<T>();
    JsonSerializationTypeRegistry.FromJsonDelegate<T> GetDecoder<T>();
}
```

Since we’re going to have one for each type, we need a collection to hold these things in the registry.

```c#
private static readonly List<ISerializationDelegateProvider> DelegateProviders;
```

Now, before we create the implementations, let’s consider our approach. We have several types, each of which have a different number of generic arguments. We could follow the example of the .Net Framework’s `Action<>` and `Func<>` delegates by creating multiple versions based on the number of generic arguments, but we don’t want to duplicate efforts. Let’s start with a base class which implements the interface.

```c#
internal abstract class SerializationDelegateProviderBase : ISerializationDelegateProvider
{
    public abstract bool CanHandle(Type type);
    public JsonSerializationTypeRegistry.ToJsonDelegate<T> GetEncoder<T>()
    {
        ...
    }
    public JsonSerializationTypeRegistry.FromJsonDelegate<T> GetDecoder<T>()
    {
        ...
    }
}
```

The idea we’re going for is that each subclass defines an `Encode()` and `Decode()` method appropriate for the given type. Ordinarily, we’d define these as abstract methods, but the providers for Guid, `List<T>`, and `Dictionary<TKey, TValue>` should implement these methods with zero, one, and two generic parameters, respectively. If we used abstract methods, we’d have to define the generic parameters as well. Instead, since this interface is internal, we can assume that subclasses will implement these methods, and then just make sure we do it.

So let’s fill out the methods in the base class.

```c#
public JsonSerializationTypeRegistry.ToJsonDelegate<T> GetEncoder<T>()
{
    var typeArguments = GetTypeArguments(typeof (T));
    var toJson = GetType().GetMethod("Encode", BindingFlags.NonPublic | BindingFlags.Static);
    if (toJson.IsGenericMethod)
        toJson = toJson.MakeGenericMethod(typeArguments);
    return (JsonSerializationTypeRegistry.ToJsonDelegate<T>)
        Delegate.CreateDelegate(typeof (JsonSerializationTypeRegistry.ToJsonDelegate<T>), toJson);
}

public JsonSerializationTypeRegistry.FromJsonDelegate<T> GetDecoder<T>()
{
    var typeArguments = GetTypeArguments(typeof (T));
    var fromJson = GetType().GetMethod("Decode", BindingFlags.NonPublic | BindingFlags.Static);
    if (fromJson.IsGenericMethod)
        fromJson = fromJson.MakeGenericMethod(typeArguments);
    return (JsonSerializationTypeRegistry.FromJsonDelegate<T>)
        Delegate.CreateDelegate(typeof (JsonSerializationTypeRegistry.FromJsonDelegate<T>), fromJson);
}
```

These methods use reflection to find methods named Encode and Decode, create typed versions using the generic arguments from the requested type (if any), and then create and return a delegate from the resulting `MethodInfo`. All that’s left is to create subclasses which have `Encode()` and `Decode()` with the appropriate number of generic arguments for the desired type. Let’s start with `Guid`.

```c#
internal class GuidSerializationDelegateProvider : SerializationDelegateProviderBase
{
    public override bool CanHandle(Type type)
    {
        return type == typeof(Guid);
    }

    private static JsonValue Encode(Guid guid, JsonSerializer serializer)
    {
        return guid.ToString();
    }
    private static Guid Decode(JsonValue json, JsonSerializer serializer)
    {
        return json.Type == JsonValueType.String ? new Guid(json.String) : default(Guid);
    }
}
```

Easy enough. For `List<T>`, we’re going to have to be a little more inventive. When you think about it, we’re really just serializing the list; we don’t care what its contents are. We can let the serializer manage that. Lists are (usually) serialized as JsonArray, so we make one and fill it with the items as returned by the serializer. Here’s the implementation for `List<T>`.

```c#
internal class ListSerializationDelegateProvider : SerializationDelegateProviderBase
{
    public override bool CanHandle(Type type)
    {
        return type.IsGenericType && type.GetGenericTypeDefinition() == typeof(List<>);
    }

    private static JsonValue Encode<T>(List<T> list, JsonSerializer serializer)
    {
        var array = new JsonArray();
        array.AddRange(list.Select(serializer.Serialize));
        return array;
    }

    private static List<T> Decode<T>(JsonValue json, JsonSerializer serializer)
    {
        var list = new List<T>();
        list.AddRange(json.Array.Select(serializer.Deserialize<T>));
        return list;
    }
}
```

We can repeat this pattern for all of the other types we want to auto-register. We’ll add them to the registry’s list of providers in the static constructor.

Okay… we have a mechanism for auto-registering our types. Now we need to wire it up to the registry. Fortunately, while we’ve been building out all of this fantastic infrastructure, we’ve also been thinking about the serializer. Remember those `IsRegistered()` methods we made? Let’s remember to ensure that the serializer always calls one of those before trying to serialize/deserialize. Knowing that, we can check our delegate providers in that method to ensure that if one of them can provide a conversion method, it will. Let’s update the `IsRegistered()` method and write logic to check the delegate providers.

```c#
public static bool IsRegistered(Type type)
{
    ValidatePotentialAutoregisteredType(type);
    return ToJsonConverters.ContainsKey(type);
}

private static void ValidatePotentialAutoregisteredType(Type type)
{
    if (ToJsonConverters.ContainsKey(type)) return;

    var delegateProvider = DelegateProviders.FirstOrDefault(p => p.CanHandle(type));
    if (delegateProvider == null) return;

    var registerMethod = typeof (JsonSerializationTypeRegistry)
        .GetMethod("RegisterProviderDelegates", BindingFlags.Static | BindingFlags.NonPublic)
        .MakeGenericMethod(type);
    registerMethod.Invoke(null, new object[] {delegateProvider});
}

private static void RegisterProviderDelegates<T>(ISerializationDelegateProvider provider)
{
    var type = typeof (T);
    ToJsonConverters[type] = provider.GetEncoder<T>();
    FromJsonConverters[type] = provider.GetDecoder<T>();
}
```

The process is as follows:

- Check the registry to see if a delegate as already been registered for the type. If it has, return. IsRegistered() will return true.
- Check the delegate providers to see if any of them can handle the type. If not, return. IsRegistered() will return false.
- Invoke the delegate provider to create the required methods and register them. IsRegistered() will return true.

Now we’re done with the registry, and the auto-registration process is extensible by adding new subclasses of SerializationDelegateProviderBase, which we’ve seen is really easy.

## That’s User-Defined Serialization!

To verify that’s all we have to do, let’s cover the scenarios and make sure that the client can define serialization for any type. To do this we ask one simple question:

- Did the client write the code for the type?
    - Yes: They can implement `IJsonSerializable`.
    - No: They can register a pair of methods which perform the conversion.
I might be a little fuzzy on the yes/no question paradigm, but I think that covers all of the possible scenarios.

Next time, we’ll build out an auto-serializer. To do that, we’ll need to consider some common scenarios, so we’ll look at those as well.