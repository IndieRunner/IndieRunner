Adding Engine Modules
=====================

When thinking about adding an engine, the following questions need to be answered and implemented:

1. What is the runtime?
-----------------------

The executable that will run the game. This is usually going to be the name of the perl module in [lib/IndieRunner/Engine](../../lib/IndieRunner/Engine). Examples: mono, hashlink...

2. How to identify games for this runtime?
------------------------------------------

When looking at the contents of a game, what are the testable aspects that identify the game as one that is compatible with the runtime? The goal is maximum sensitivity and specificity, with minimum complexity.

The main decisions about the game runtime are made in [GrandCentral.pm](../../lib/IndieRunner/GrandCentral.pm). Many engines have typical files that are always included with the same name. Examples are: `FNA.dll`, `MonoGame.Framework.dll`, `hlboot.dat`. If this mechanism isn't enough, there is a mechanism to identify byte sequences or strings in files for engine identification.

3. What is needed to configure the runtime?
-------------------------------------------

This concerns the CLI arguments for the runtime, environment variables, as well as occasionally a specific version of the runtime when multiple exist. Some runtimes need to be invoked with a particular file as argument to launch, for example a specific `.exe` file for mono.

This is the main part of the perl module in [lib/IndieRunner/Engine](../../lib/IndieRunner/Engine/). This configuration is passed back to IndieRunner via the methods `get_bin`, `get_args_ref`, and `get_env_ref`.

4. What are the games to test the module?
-----------------------------------------

No engine module is worth anything if it can't run any games. That's why as many games as possible need to be tested, to look for edge cases. Are there resources that enumerate all or a large part of the games that use the runtime? Consider checking out engine webpage and documentation for *showcase* lists, or automated tools like [SteamDB's Tech page](https://steamdb.info/tech/).
