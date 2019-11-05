# Self-Registering APIs – Part 1: An Overview

Several months ago, I started working on a new desktop application project that was to be backed by an microservice ecosystem. I ended up designing an API where the only well-known service is the one that handles authentication, and all other services register themselves with the authentication API and only access each other via service discovery. This yields extensibility: a new service doesn't need to be explicitly set up in the ecosystem; just add it and go.

***NOTE** This approach is analogous to the "O" in SOLID: the Open/Closed Principle. Our architecture happily accepts new components without having to change itself.*

While discussing this, I'll be using the terms "client" and "service". A service will expose API calls and provide functionality or data. (In OAuth 2 parlance, they're "resources.") A client calls a service. These terms are not mutually exclusive. If *Service A* calls *Service B*, then *Service A* is considered a client to *Service B*. However you could also have a pure client, like a web page or desktop app.

## The View at 10,000ft

The tl;dr of it is this:

- We start with a basic authentication API.
- Other services will, at startup, register themselves with the authentication API with credentials that they generate.
- The authentication API then provides two functions:
    - service discovery so that clients can learn about the ecosystem, and
    - token issuance so that clients can talk to each other.

One reason I want the clients to register themselves is that I don't want clients to be aware of each other, specifically. Instead I want a client to be aware that another client exists and let service discovery provide the details of where it is. This allows me to host an API anywhere, and even move it, without having to update the configurations of all the clients that talk to it.

By having the services generate their credentials I only need to restart a service to change them. Again, no configuration changes. This can be a nice mitigation feature for when the service is comprimised. (Protect against it, assume it's going to happen anyway, and plan for it. You'll sleep better.)

To get started with a deeper dive, let's take a tour around the registration process.

## Getting a microservice to register itself

In order to allow a service to register itself, we need to expose an unauthenticated endpoint. Why unauthenticated? I'm glad you asked. The registration process sets up the data to allow the authentication service to recognize it as a client to which it can issue a token. Since the service hasn't yet registered, it can't get a token. Without a token, it can't call an authenticated endpoint. So we need to rely on other means to authenticate the caller.

The best means that I've found is using a public/private key pair to encrypt the data. A microservice will need to know the public key of the authentication API so that it can encrypt its registration information. Upon receiving the call, the authentication API decrypts the information and proceeds with the registration. (To prevent just anyone registering a client, the authentication API's public key can be well-known to the services you build but unknown to the public at large.)

The registration information will be anything that the authentication API needs to know in order to issue tokens to the service and on its behalf (so that others can call it). From what I've worked out, this is the minimal data set:

- Client ID
- Client Secret
- Service Name
- Host Base URI
- Whether this client is a resource
- Defined Scopes
- Scopes that will be requested
- (Optional) Public Encryption Key

The client ID and secret are provided so that the service can have a token issued and simply make calls using the OAuth 2.0 client credentials grant. If you prefer to use a different or custom grant type (e.g. AWS's IAM Roles), then you'll need to provide whatever details the authentication API will need to issue a token under that grant type.

The service name is simply a human-readable name for the service. It's not really necessary for the ecosystem to operate, but it's really handy for logs and such. In a pinch, the client ID will do.

The host base URI is... the host base URI for the microservice. It's used for service discovery.

A client is considered a resource if it can act as an audience. This means that APIs will be resources, but an end client (e.g. a mobile app) would not be.

The defined scopes are the scopes that this microservice defines. These scopes are used as permissions for accessing various components of the microservice's API.

Additionally, if the service will be talking to other services, the authentication API will need to know what scopes it will be requesting. This is like setting permissions for users. I haven't yet found a way around this other than to just grant all scopes to all clients, which seems bad.

Lastly, an optional public encryption key that can be used by the authentication API to communicate back to the microservice over open endpoints but still in a secure manner. (This may not be necessary, but I needed a way to do this. When I get there, I'll circle back around and explain why.)

So to register itself, a microservice will encrypt the client ID and secret using the authentication API's public key, package this and the rest of the above information, and then send it to the authentication API.

Internally, the authentication API, decrypts the client credentials, and stores all of this information in a database of available clients which is wired into the authentication and token issuance logic. I used IdentityServer4 for this, which was pretty simple. We'll get into implementation stuff next time.

## What about users?
In my experience, the user details are typically stored within the authentication API alongside the clients, but for this project I elected to use a separate API for users. This has a few effects, and I'm not really sure which (if any) of these are beneficial, yet.

1. User's can't log in without a separate service running and registered.
1. The concept of a users API and it's contract have to be well-known to the authentication API, though the host won't be known until one registers.
1. Logging in could take longer since I now have a timeout for the authentication API *and* a timeout for the users API.

Yeah, none of those really sound beneficial. I jsut wanted to do this to separate the concerns of user management from the authentication API. I'm not sure it's worth it.

This separate service is actually why I include the service's public key in the registration details. I needed a way to securely send login details (username and password) from the authentication API to the users API for verification. Now that I think about it, a self-issued token with the user API as an audience should do the trick (sigh).

I'll probably end up just merging the users API into the authentication API eventually as it would resolve the above issues, but it's a separate thing for now. Regardless, this a learning process, and seeing the fallout of having this separate is a good lesson.

Service discovery
Once a service has registered, clients can get tokens and start making calls to it. In theory. They can't really make calls to it unless they know where it is. That's where service discovery comes in.

The authentication API exposes a second endpoint for discovery; this one is authenticated to protect the API ecosystem. It takes a client ID as an argument and returns a subset of the information the service used to register. The returned service information includes

- Client ID
- Service Name
- Host Base URI
- Defined Scopes
- Public Encryption Key

The other information supplied during the registration process is kept private to the authentication API.

Now, a registered service can locate and call another registered service.

In the next post, I'll go over my implementation of this architecture in ASP.Net Core 2.