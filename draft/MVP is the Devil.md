# MVP is the Devil

In this post, I'm going to rant a bit about a concept that is prevalent in the world of Agile: Minimum Viable Product, or MVP.

### The idea

Under an Agile process, development is broken into features.  These features are then sequenced so that each feature builds upon the ones that were previously developed.  The next step is to assign a level of effort to each feature.  Finally, the features are placed into groups of roughly the same amount of effort.  Each of these groups will usually be called a sprint or iteration.

MVP comes in at the feature.  Each feature is defined by the question, "What is the minimum implementation for this feature to be considered complete?"  Usually, earlier on in development, "complete" means "functional."  For features scheduled later in development, "complete" may mean a finalized UX or other refinements to existing features.

In teaching Agile, it's common for the instructor to present an analogy to manufacturing and this image:

![image](http://blog.crisp.se/wp-content/uploads/2016/01/Making-sense-of-MVP-.jpg)

This image is from [this blog post](http://blog.crisp.se/2016/01/25/henrikkniberg/making-sense-of-mvp), and Mr. Kniberg makes a lot of good points.  However, as a developer I find much of this process frustrating and unnecessarily time-consuming.

### The project

The first step is a skateboard.  This usually means an application that runs.  Build out the infrastructure.  At the end of the first iteration, we essentially have an empty feature bag.  The customer isn't pleased, but at least they have something.

During the next iteration, we add in the first few features.  This is represented by a set of handlebars attached to the skateboard which turns it into a scooter (of sorts).

Then we get to stage three: the bicycle.  This is the beginning of where I get frustrated.  The features we want to add are a seat and gearing to make it go faster.  But there's a problem: there isn't a good way to add a seat to a skateboard or a foot-powered scooter.  This means we have to refactor and add a frame to support the seat.  This has fallout: we can't use the same wheels.  We may be able to use the same handlebars, but we'll likely want to revisit that later (tech debt).

Next up is iteration four when we upgrade to the motorcycle.  The primary piece we have to add is an engine.  Fortunately, we have an engine framework that just needs to be integrated into the application.  We need to create an adapter for the transmission so that we can use it through our existing gearing interface, and another for the engine so we can use our propulsion interface.  Not really a refactor here.

Finally, we get the car.  Oh, look!  Another major refactor to move back to a four-wheel platform.  Yeah, I'm already tired of this project.

### My view

Before I entered the world of professional software development, I was in the manufacturing industry, being guided in the ways of Lean Manufacturing.  The primary philosophy of Lean Manufacturing is reduction of waste, and the number one cause of waste is rework.  You save the most money by only having to do a particular task once.

I don't know if you noticed, but I used the word "refactor" three times in there.  Refactoring is (many times) rework.  Something you wrote doesn't work for what you're now planning to write.  With proper software practices, [refactoring can be a good thing](http://www.telerik.com/blogs/top-5-reasons-why-you-should-refactor-your-code).  However, with my manufacturing background (and general laziness), I still tend toward minimizing rework.  I like to think about my designs ahead of time and plan out my code so that I don't have to redo it later.  Do it right the first time, and you won't have to do it again.

I understand that sometimes plans don't work out just right, and sometimes you see better solutions mid-way through development.  In these times, refactoring is necessary.  But we still try to minimize these occasions.

I see the approach to software development above as merely planning rework.  Why would you want to do this?!  Why would any developer want to build a portion of code in full knowledge that they were going to just throw it away in a few weeks?  This truly boggles my mind.

In my mind, I take a more manufacturing-inspired approach when building software.  I design the car in detail, then I build it, starting with the frame and then attaching complete components.  And I don't add just any wheels or the minimum wheels, but the proper wheels that I intend to have for the finished product.  To help set the stage for this, I don't add them until I already have a way to drive them (engine, transmission, axles).

This doesn't mean that I can't communicate with my client along the way, or that they don't get incremental, usable deliveries.  What it *does* mean is that when I present a client with a new feature, they get to see the feature in its full functionality.  And of course, I have discussions with the client during development so that I minimize (ideally eliminate) assumptions.

### A comparison

I think maybe the issue is the analogy, or perhaps the illustration.

Cars aren't built starting with the wheels, as it's shown in this drawing.  They're built starting with the frame.  Next primary functional components are added (drive train, electrical systems, etc.).  And with each successive component, the shift continues from the essential to the luxury.  Even the paint and finish is done in the middle; after the required items, but before the niceties.

Building an application should work the same way.  Start with the framework, and add those components which are required.  These are your MVP features.  But build them completely.  Build them the way they are intended to be.

Finally, I don't think that manufacturing a car is the correct analogy because when we buy a car, we don't see it until it's done.  Furthermore, the manufacturer isn't coming to us to ask, "Is this what you intended for this feature?" with the intent of changing it to suit our needs.  Once it's built, that's it; they're done.  Any modifications usually involve a third party.  The manufacturers build high quantities of cars that vary in feature sets, knowing (hoping) that *someone* will buy each one.

Software development for clients is different.  We're building a product where the client has specified the feature list and end design.  We allow them to make changes, both in and out of the original scope of the project (hopefully we're charging for out of scope changes), *during* the development process.