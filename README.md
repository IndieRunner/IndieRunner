<p align="center">
<img src="https://github.com/IndieRunner.png" alt="IndieRunner avatar">
<h1>IndieRunner</h1>
</p>

Liberate your games from platform-dependent bundled dependencies. Maximize platform compatibility and longevity.

Many games are built in a way that allows more platforms than advertised.

For Users
---------

Free your games from these artificial restraints and preserve your games across many different platforms.

For Developers
--------------

Stop worrying about bundled dependencies and maximize the portability and longevity of your project, without sacrificing the ability to commercialize the core of your creation.

While not ready yet, we are working on offering mentoring and infrastructure for indie game developers to make use of this project to maximize their reach on open source platforms.

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
* Urtuk the Desolation
* Nuclear Blaze

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
* Wolfire Games (Lugaru, Overgrowth)

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

* OpenBSD
* FreeBSD (planned)
* NetBSD?
* Haiku?
* Linux?

Dependencies
============

Install Perl dependencies on OpenBSD:
```
# pkg_add p5-Capture-Tiny p5-File-Copy-Recursive p5-File-Find-Rule p5-File-LibMagic p5-JSON p5-Path-Tiny p5-Readonly p5-Text-Glob
```

External (non-Perl) programs and libraries used:
* 7z from p7zip (modules Java, LibGDX, LWJGL2, LWJGL3)
* ffmpeg (module XNA)
* godot (module Godot)
* hashlink (module HashLink)
* mono (modules Mono, FNA, XNA, MonoGame)
* steamctl (`--log-steam-time`)
* steamworks4j (some Java modules)

Platform Requirements
=====================

* interpreter for IndieRunner
* runtimes (mono, hashlink, java)
* libraries (SDL, freetype, libstubborn, ...)
* tools: ffmpeg (for conversion of XNA media files)

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
