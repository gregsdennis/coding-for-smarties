Self-Registering APIs – Part 2: Authentication API, Registering Other Services, and Service Discovery

Today, I'll be continuing the tour of my self-registering API architecture by taking a look at the authentication API and the mechanics of how a service registers itself. This will be a more practical dive than the previous post's theory-heavy chit-chat.

Authentication
In order to support OAuth 2, I've decided to use IdentityServer4. It's fairly straightforward to set up and the documentation is pretty good. The hardest part about building an OAuth 2 server is, well, OAuth 2. Once you get your head wrapped around the concepts, it's... still quite complex. We start with this:

services.AddIdentityServer(options => { ... })
        .AddDeveloperSigningCredential(); 
To support issuing tokens to APIs and other clients, we'll need to set up the Client Credentials grant. For this, you'll need to implement two interfaces: IResourceStore and IClientStore.

IResourceStore allows IdentityServer4 to verify that the scopes and audiences from the token request are in alignment and that the client has access to those scopes. This implementation will need to be wired into your client data store (or repository class).

IClientStore is simply a client lookup service that can find a client by ID. This will also need to connect to the client data.

Register both of these in the Startup.ConfigureServices() method

services.AddIdentityServer(options => { ... })
        .AddDeveloperSigningCredential()
        .AddResourceStore<ResourceStore>()
        .AddClientStore<ClientStore>(); 
If you also need to have users who can sign in through a client (e.g. a mobile app), you'll need to enable username/password authentication. This requires two more interface implementations: IUserProfileService and IResourceOwnerPasswordValidator.

IUserProfileService is the user equivalent to IClientStore above. It basically performs a lookup of the user. I'm not sure what GetProfileDataAsync() does; I just return Task.CompletedTask and it works fine. IsActiveAsync() validates that the client requesting the user login is valid and active.

IResourceOwnerPasswordValidator integrates the heavy lifting of validating a username and password. I pass this on to my Users API, but the more I think about it, I should be managing users in the Authentication API alongside the clients. I'll have to merge that functionality in... someday.

Just like the client classes, we'll need to register our implementations in the startup.

services.AddIdentityServer(options => { ... })
        .AddDeveloperSigningCredential()
        .AddResourceStore<ResourceStore>()
        .AddClientStore<ClientStore>()
        .AddProfileService<UserProfileService>()
        .AddResourceOwnerValidator<UserResourceOwnerPasswordValidator>(); 
And that's pretty much it. There are some other IdentityServer4 configuration details, but they go into it in their docs, so I'm not going to cover it here.

Registering Clients
The tricky part about self-registering clients is authentication. We need some sort of authentication, but we can't issue a token to a client we don't know about.

Looking into the OAuth2 grant types, you'd think that maybe we could use the authorization code grant type: just ensure that our clients have an auth code and they get a token, right? Well, no.

The Authorization Code Grant Type ... is used by both web apps and native apps to get an access token after a user authorizes an app. [emphasis added]

So that's out. The next candidate is the implicit grant type. Sorry, that's bad practice now.

The OAuth 2.0 Security Best Current Practice document recommends against using the Implicit flow entirely...

Okay. Device code? Nope. That requires user interaction.

Hmmm... none of the others (password, client credentials, and refresh token) apply at all. We're going to have to come up with something else.

The Authentication API Part
My solution was to create an open, unauthenticated REST endpoint. To ensure that only my clients can register, I require that a portion of the registration request is encrypted with a public key that only my clients know. This controller handles that.

[Route("api/[controller]")]
[ApiController] 
public class ClientsController : ControllerBase
{
    private readonly IClientService _clientsService;
    public ClientsController(IClientService clientsService)
    {
        _clientsService = clientsService;
    }
    [HttpPost]
    public async Task<ActionResult> Post([FromBody] ClientRegistrationRequest request)
    {
        await _clientsService.SaveClientDetails(request, ControllerContext.HttpContext.RequestAborted);
        return Ok();
    }
} 
Then in SaveClientDetails(), I just need to decrypt the encrypted portion, and then save the client data so that the IResourceStore and IClientStore implementations can read it.

For reference, the ClientRegistrationRequest is shown below. You can see what each property does in the previous post.

public class ClientRegistrationRequest 
{
    public string Name { get; set; }
    public string Host { get; set; }
    public string Credentials { get; set; }
    public List<string>  DefinedScopes { get; set; }
    public List<string> RequestedScopes { get; set; }
    public bool IsResource { get; set; }
    public string EncryptionKey { get; set; } 
} 
Credentials is the client ID and secret encrypted. For my services, I embedded these inside a JSON object, serialized it, then encrypted that, but perhaps a basic authentication format (client_id:client_secret) would do just as well. Basically you want to be able to decrypt the string and then parse out these two fields.

That takes care of the authentication API portion.

The Client Part
Now we need to get the client to build that ClientRegistrationRequest object.

The service information should be kept somewhere. I put things like the host and encryption keys (its own public/private key pair and the authentication API's public key) in configuration and hard-code everything else except for the secret, which is generated at run time.

Given those things, here's what I use to generate a registration request.

var serviceInfo = _serviceInfoProvider.GetServiceInfo();
 serviceInfo.Secret = $"{Guid.NewGuid():N}{Guid.NewGuid():N}";
 _serviceInfoProvider.UpdateServiceInfo(serviceInfo);
var credentials = _encryptionProvider.Encrypt(_config.AuthApiPublicKey, 
                                              $"{serviceInfo.Id}:{serviceInfo.Secret}"); 
return new ClientRegistrationRequest
    {
        Name = serviceInfo.Name,
        Host = serviceInfo.Url,
        Credentials = credentials,
        DefinedScopes = serviceInfo.DefinedScopes.ToList(),
        RequestedScopes = serviceInfo.RequestedScopes.ToList(),
        IsResource = isResource,
        EncryptionKey = EncryptionKeys.Service.Public
    }; 
The secret isn't anything special, and you could probably come up with something better and perhaps even meaningful, but it's good enough.

Now we send that off to the authentication API, and our client is registered and can be issued tokens!

Discovery
It doesn't really help us much to be able to register APIs if no one knows where they are. You could make an API host well-known, but that defeats part of the intent behind self-registration. Instead we need to create service discovery functionality that one client can use to find another.

To do this, we need to add a new REST endpoint. I added a method to the existing ClientsController class, but you could create an entirely new controller as well. It just depends on how you want to organize your authentication API endpoints. I thought it would be nice to have a GET request at the same path as the registration.

[Route("api/[controller]")]
[ApiController] 
public class ClientsController : ControllerBase 
{
    ... 
    [HttpGet("{clientId}")] 
    public Task<ActionResult<ServiceInfo>> Get(string clientId) 
    { 
        return _clientsService.GetServiceInfoById(clientId, ControllerContext.HttpContext.RequestAborted); 
    } 
    [HttpPost] 
    public async Task<ActionResult> Post([FromBody] ClientRegistrationRequest request) { ... } 
} 
I encountered a snag here that (happily) was easily resolved. My new GET request was unauthenticated. This isn't what we want. If it's unauthenticated, then anyone can discover the topology of our API ecosystem.

To fix this, we need to add authentication to the controller, and allow anonymous requests to the registration method. Add [Authorize] at the class level and [AllowAnonymous] to the Post() method.

Lastly, here's ServiceInfo for you:

public class ServiceInfo 
{ 
    public string Id { get; set; } 
    public string Name { get; set; } 
    public string Url { get; set; } 
    public IEnumerable<string> DefinedScopes { get; set; }; 
    public IEnumerable<string> RequestedScopes { get; set; }; 
} 
It's just a subset of the information that is used to register. We don't want to give out its secret, and the public key is really just for the authentication API to talk back to the client, not for inter-client communication. (I really just added the key because I needed to support calling back to the users API from the authentication API. When I merge that into the authentication API, I'll probably get rid of the key.)

Wrapping Up
Let's take a look at what we've achieved:

We have an authentication API.
We can create a client, be it another API or an end client app, and register it so that the authentication API can issue tokens to it.
An authenticated (token issued) client can discover details about other registered clients.
Sounds like we accomplished what we wanted! Time for a drink!