#!perl -T

use Test::More tests => 32;

BEGIN {
    require_ok( 'IndieRunner' )				|| print "Bail out!\n";
    require_ok( 'IndieRunner::Cmdline' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine' )			|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::FNA' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::GZDoom' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Godot' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::HashLink' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Love2D' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Java' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Java::JavaMod' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Java::LibGDX' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Java::LWJGL2' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Java::LWJGL3' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Java::Steamworks4j' ) || print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Mono' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Mono::Dllmap' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::Mono::Iomap' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::MonoGame' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::ScummVM' )	|| print "Bail out!\n";
    require_ok( 'IndieRunner::Engine::XNA' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Game' )			|| print "Bail out!\n";
    require_ok( 'IndieRunner::GrandCentral' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Helpers' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::IdentifyFiles' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Info' )			|| print "Bail out!\n";
    require_ok( 'IndieRunner::Io' )			|| print "Bail out!\n";
    require_ok( 'IndieRunner::Mode' )			|| print "Bail out!\n";
    require_ok( 'IndieRunner::Mode::Dryrun' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Mode::Run' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Mode::Script' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Platform' )		|| print "Bail out!\n";
    require_ok( 'IndieRunner::Platform::openbsd' )	|| print "Bail out!\n";
}

diag( "Testing IndieRunner $IndieRunner::VERSION, Perl $], $^X" );
