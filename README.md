A [bup](https://github.com/bup/bup/)-like system for retrieving changed
part of a page over HTTP.

## Brief description

A hdiff is a signature of a document (currently, anything that is
streamable can be considered a document) that can be efficiently used to 
calculate the difference between two similar versions of this document,
and retrieve only the changed part.

By using a hdiff for a resource you share on a web site, users can use
only the needed amount of bandwith to obtain the latest version of your
document. This kind of workflow was mostly useless in the early days of
the web, were all content was static; today, the web is getting more and
more dynamic, and the only solution we have to cope with that is to
download the new version from scratch whenever it changes or, as most
website do, tell the client to never cache anything. Combine that with
the natural appetite for more and more content of the web 2.0 bandwagon,
and your clients download multiple kB of data everytime you update
anything.

The inspiration for this work comes from the venerable
[rsync](https://samba.org/rsync) and one of its numerous derivatives,
[zsync](http://zsync.moria.org.uk/). While functional, zsync is written
in C, and I'm not a smart enough programmer to hack this, so I set out
to re-implement the idea in ruby. I also took the main idea from bup to
efficiently compute the difference between two similar documents.

## How it works

The workflow is straightforward:

1. Download a content, along with its hdiff signature
2. Whenever you want the new version, check the hdiff signature. It
   is notably smaller, so downloading it completely is not as bad as
   before (currently, around 5% of original size). If the content hasn't
   changed the hdiff hasn't changed, so you get a 304
3. If it has changed, compute the difference from your stored hdiff and
   the new hdiff. This gives you an array of byteranges to ask to the
   content provider
4. Download those ranges. HTTP has had [everything built-in for
   this](https://en.wikipedia.org/wiki/Byte_serving) for ages.
5. Build the new version from the old ones and the new bytes.

One of the key designs of this solution is that the Webserver that
distributes your content isn't changed at all. There is only one
supplementary piece of information (the hdiff signature) that needs to
be computed and distributed.

## Drawbacks

There are a few drawbacks to the approach, though:

1. There is one more round-trip before downloading real content. The
   time you win by skipping redundant bytes is lost on waiting for the
   packets to travel. We could mitigate this by putting more logic on
   the webserver and have it compute what needs to be sent and send it
   directly, but it would break the simple goal of the solution.
2. The bup hashsplitting algorithm gives arbitrary block sizes of
   fetchable content, the smaller being in the ~100B zone, and the
   bigger being in the ~5kB zone. Losing a round-trip for a 5kB download
   when only a few bytes changed can be bothersome.
3. There is a strong need of atomicity here: you have to be sure that
   the blocks you download really are related to the hdiff signature you
   got earlier.

## Licence
[CC0](https://creativecommons.org/publicdomain/zero/1.0/)
