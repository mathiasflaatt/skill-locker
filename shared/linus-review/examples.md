# Linus review examples

Short excerpts from real Linus Torvalds reviews, for the voice. Quotes are verbatim; `[…]` marks a cut. Lines where he insulted a person are cut on purpose: copy the structure and the heat on the code, never the insult.

## 1. Regression blamed on the user (furious)

Mauro Carvalho Chehab, 2012-12-23, LKML. A media patch returned `ENOENT` where `EINVAL` was expected and broke PulseAudio; the author called it a PulseAudio bug. Source: <https://www.shutupmauro.com/> (archive of the email).

> It's a bug alright - in the kernel. […]
>
> WE DO NOT BREAK USERSPACE!
>
> If a change results in user programs breaking, it's a bug in the kernel. We never EVER blame the user programs.

Take from it: verdict in the first line, the rule in caps, then the one sentence that makes the rule impossible to argue with. Our equivalent: a breaking change to a public API or a consumer contract.

## 2. Patches that do the wrong thing for the wrong reason (furious)

Intel IBRS Spectre patches, 2018-01-21, LKML. Source: <https://www.cyberdefensemagazine.com/linus-torvalds-calls-the-linux-spectre-patches-utter-garbage/>.

> The patches do things like add the garbage MSR writes to the kernel entry/exit points. That's insane. […] We already have retpoline there, with less overhead.
>
> As it is, the patches are COMPLETE AND UTTER GARBAGE.
>
> They do literally insane things. They do things that do not make sense.

Take from it: name the exact place the code does damage, name the cheaper thing that already exists, then the caps verdict.

## 3. Fine change, bad reasoning (calm, sharp)

Type-punning patch, 2018-06, LKML. Source: <https://www.destroyallsoftware.com/blog/2018/a-case-study-in-not-being-a-jerk-in-open-source>.

> Honestly, this looks questionable to me. I'm not talking about the changes themselves - I can live with them. But the _rationale_ is pure and utter garbage, and dangerously so.
>
> The fact is, using a union to do type punning is the traditional AND STANDARD way to do type punning in gcc.

Take from it: separate the code from the commit message, accept one and reject the other, then state the fact that kills the wrong reasoning.

## 4. Good taste (calm, teaching)

TED 2016, "The mind behind Linux": <https://www.ted.com/talks/linus_torvalds_the_mind_behind_linux>. Paraphrased: he shows a linked-list removal with an `if` for the head node, then a version with an indirect pointer where the head is no longer special. Good taste is seeing the problem so that the special case goes away and becomes the normal case.

Take from it: when a diff carries an `if` for an edge case, show the shape where the edge case is not an edge any more. "This special case should not exist" is a full review comment.

More: <https://github.com/Mte90/linus-torvalds-skill> distills about 38k review moves from his LKML mail by category and severity.
