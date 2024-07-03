<p align="center">
<img src="https://github.com/IndieRunner.png" alt="IndieRunner avatar">
<h1>IndieRunner</h1>
</p>

Liberate your games from platform-dependent bundled dependencies. Maximize platform compatibility and longevity.

Many games are built in a way that allows more platforms than advertised.

For Users
---------

Free your games from these artificial restraints and preserve your games across many different platforms. IndieRunner provides a universal CLI launcher for a variety of independent games built with frameworks like FNA, XNA, LWJGL, LibGDX, HashLink, GZDoom, ScummVM, Love2D. It selects a runtime, configures it as needed, and takes care of outdated or incompatible bundled libraries.

[Status Tracker](share/Status-Tracker.md)

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

Highlights
==========

The following selection of high profile games have been working with IndieRunner (and still are to the best of my knowledge);

* Brotato
* Dead Cells
* Deepest Chamber: Resurrection
* Gravity Circuit
* Northgard
* Nuclear Blaze
* Owlboy
* Salt and Sanctuary
* Slay the Spire
* Stardew Valley
* Terraria

"Indie"?
========

"Indie" has 2 meanings in this project:

1. Run games (other software?) in a more platform-independent way.
2. The primary use is for engines primarily used in the indie game space (FNA, HashLink, etc.)

How to Make a Project that Can Run on as Many Platforms as Possible
===================================================================

Completely Open-Source Your Project
-----------------------------------

* (+) You're not limited in your engine design
* (-) Can't use proprietary engines (Unity, Unreal, GameMaker)

Opensource your Engine Code; Sell the Assets
--------------------------------------------

Examples:
* Barony
* idTech (gzdoom)
* Wolfire Games (Lugaru, Overgrowth)

Use a ByteCode Framework that Relies on Open-Source Native Libraries
--------------------------------------------------------------------

Examples:
* FNA
* MonoGame
* Java, LWJGL, libGDX
* Godot (ideally GDScript)
* Love2D

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

For prerequisite Perl modules, see `PREREQ_PM` in [Makefile.PL](Makefile.PL).

Other (non-Perl) programs and libraries used:
* 7z from p7zip (modules Java, LibGDX, LWJGL2, LWJGL3)
* CSteamworks (module FNA)
* FAudio (modules FNA, XNA)
* ffmpeg (module XNA)
* FNA (modules FNA, XNA)
* godot (module Godot)
* goldberg_emulator, if no native support for libsteam_api.so
* gzdoom (module GZDoom)
* hashlink (module HashLink)
* hlsteam (module HashLink)
* Java JDK 1.8, 11, 17 (modules Java, LibGDX, LWJGL2, LWJGL3)
* LibGDX - different versions, depending on the game
* libstubborn (modules FNA, XNA)
* libtheora, libtheorafile, libtheoraplay (modules FNA, XNA)
* love (module Love2D)
* luasteam (some Love2D games)
* LWJGL, LWJGL3
* mono (modules Mono, FNA, XNA, MonoGame)
* OpenAL (module LibGDX)
* rigg (optional, as alternative runtime for selected engines to apply unveil(2))
* ScummVM (module ScummVM)
* SDL2 (modules FNA, XNA, HashLink)
* SDL2-image
* SDL2-mixer
* steamworks4j (some Java modules)
* steamworks-nosteam (modules FNA, XNA)

Install them all with:
```
# pkg_add faudio ffmpeg fna godot gzdoom hashlink hlsteam jdk libgdx libstubborn libtheora{,file,play} love lwjgl{,3} mono openal p7zip sdl2-image sdl2-mixer
```

Platform Requirements
=====================

* interpreter for IndieRunner
* runtimes (mono, hashlink, java, love)
* libraries (SDL, freetype, libstubborn, ...)
* tools: ffmpeg (for conversion of XNA media files)

Problems:

* dotnet Core crossplatform support is incomplete. Use mono instead!

Similar Projects
================

* fnaify
* Luxtorpeda

But What About ...?
===================

Opensource Unity Projects
-------------------------

* published source code that requires a proprietary, closed-source engine to run isn't really opensource

Wine
----

* not available on OpenBSD

Virtual Machines
----------------

* hassle
* performance
* no performant option on OpenBSD

Dual-booting
------------

* hassle

Known (General) Problems
========================

Runtime Changes
---------------

* mono abandoned MONO_IOMAP with version 6, which has rendered games using Windows pathnames with '\\' largely unplayable.

Steam
-----

* no Steam client on OpenBSD
* other platforms requiring wine to run Steam client

Library Changes
---------------

* libjpeg has had breaking API changes that break the game MidBoss which is expecting old API.

License
=======

[ISC License](share/LICENSE)
