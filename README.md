![IndieRunner avatar](https://github.com/IndieRunner.png)

IndieRunner
===========

Advantages
==========

* many platforms, even some that haven't been invented
* many architectures, even not-yet invented architectures can be leveraged
* preservation - as your project doesn't depend on the good will of a company to maintain a proprietary library, your application can be run far into the future, as long as there is someone willing and able to maintain the libraries and runtime that drive it
* You don't have to choose between going all-out opensource, losing control over the proliferation of your software, and the closed-source proprietary way that loses portability and longevity. Look at some examples and explanations below to see what may suit your project to leverage both.

Showcase
========

* Northgard
* Dead Cells
* Curse of the Crescent Isle DX

"Indie"?
========

"Indie" has 2 meanings in this project:

1. Run games (other software?) in a more platform-independent way.
2. The primary use is for engines primarily used in the indie game space (FNA, HashLink, etc.)

How to Make a Project that Can Run on as Many Platforms as Possible
===================================================================

Completely Opensource Your Project
----------------------------------

+ You're not limited in your engine design
- Can't use proprietary engines (Unity, Unreal, GameMaker)

Opensource your Engine Code; Sell the Assets
--------------------------------------------

Examples:
* Barony
* idTech

Use a ByteCode Framework that Relies on Opensource Native Libraries
-------------------------------------------------------------------

Examples:
* FNA
* MonoGame
* Java, lwjgl, libGDX
* Godot (ideally GDScript)

Caveats
-------

Any of the above will lose the portability options if closed-source libraries get involved. Examples include:

* FMOD (Celeste, Bastion, ...)
* Wwise (SOR4, WarTales, ...)
* hard dependency on Steam library (workarounds exist for many cases)


Platforms
=========

OpenBSD
FreeBSD
Linux
Haiku?

Platform Requirements
=====================

* interpreter for IndieRunner
* runtimes (mono, hashlink, java)

Problems:

* dotnet Core crossplatform support is incomplete. Use mono instead!

Similar Projects
================

* fnaify

But What About ...?
===================

Opensource Unity Projects
-------------------------

Wine
----

Virtual Machines
----------------

Dual-booting
------------

... you seriously have to ask?

Known (General) Problems
========================

Runtime Changes
---------------

* mono ...

Steam
-----

Library Changes
---------------

* jpeg ...
* mojoshader ...
