Just a fun thought I had today.

Many people have pondered the uniqueness of various ID structures we have for computing (GUIDs, UUIDs, etc).  In the end, any structure that must be represented by a finite number of bits has a finite number of combinations of those bits.

That said, for the .Net `Guid` class, [Mr. Dee](http://mrdee.blogspot.co.nz/2005/11/how-many-guid-combinations-are-there.html) has a nice/funny thread about this inherent limit.

>There are 122 random bits (128 - 2 for variant - 4 for version) so this calculates to 2^122 or 5,316,911,983,139,663,491,615,228,241,121,400,000 possible combinations.

Knowing this, I've concluded that it's our responsibility as computer scientists to generate *every single GUID* at some point in our collective lifetimes.  To that end, I've started writing my unit tests so that they generate new GUIDs with each test.  The more, the better!

With your help, I believe that we can achieve this goal.