# Copyright (c) 2022-2024 Thomas Frohwein
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package IndieRunner::Engine::Mono::Iomap;
use v5.36;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp;
use Readonly;

# XXX: go over all of them and see which are still needed now that FNA
#      is built with CASE_SENSITIVITY_HACK

Readonly my %iomap => {
	'Aces Wild.exe' => [
		[ 'HitSparks', 'Content/Sprites/Hitsparks' ],
		[ 'preFabs.awx', 'Content/Data/prefabs.awx' ],
		],
	'AtTheGates.exe' => [
		[ '../../Components/GraphicalButtons/Pillage_64.xnb',
			'Content/Images/Interface/Icons/Concepts/Pillage.xnb' ],
		],
	'CSTW.exe' => [
		[ 'paws_Happy.xnb', 'Content/Portrait/Paws/Paws_Happy.xnb' ],
		],
	'CameraObscura.exe' => [
		[ 'enemies', 'Content/Enemies' ],
		[ 'buttons', 'Content/Buttons' ],
		[ 'ui', 'Content/UI' ],
		[ 'particle', 'Content/Particle' ],
		],
	'CupOfEthanolFNA.exe' => [
		[ 'SkyA.PNG', 'Content/Textures/Backgrounds/SkyA' ],
		[ 'SkyB.PNG', 'Content/Textures/Backgrounds/SkyB' ],
		[ 'Button4.PNG', 'Content/Textures/Menu/Button4' ],
		[ 'Button5.PNG', 'Content/Textures/Menu/Button5' ],
		[ 'EPauseMenuBackground.PNG', 'Content/Textures/Menu/EPauseMenuBackground' ],
		[ 'PauseMenuBackground.PNG', 'Content/Textures/Menu/PauseMenuBackground' ],
		[ 'Platform.PNG', 'Content/Textures/Entities/Platform' ],
		[ 'ConcretePlatform.PNG', 'Content/Textures/Entities/ConcretePlatform' ],
		[ 'Cannon.png', 'Content/Textures/Entities/cannon' ],
		[ 'grass.PNG', 'Content/Textures/Tiles/grass' ],
		[ 'Ugrass.PNG', 'Content/Textures/Tiles/Ugrass' ],
		[ 'metal.PNG', 'Content/Textures/Tiles/metal' ],
		[ 'gravel.PNG', 'Content/Textures/Tiles/gravel' ],
		[ 'ice.PNG', 'Content/Textures/Tiles/ice' ],
		[ 'Ulava.PNG', 'Content/Textures/Tiles/Ulava' ],
		[ 'vgrass.PNG', 'Content/Textures/Tiles/vgrass' ],
		[ 'Uvgrass.PNG', 'Content/Textures/Tiles/Uvgrass' ],
		[ 'sand.PNG', 'Content/Textures/Tiles/sand' ],
		],
	'DLC.exe' => [
		[ '../../campaigns/dlcquest/texture/awardmentSpriteSheet.xnb',
			'Content/base/texture/awardmentSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/texture/dlcSpriteSheet.xnb',
			'Content/base/texture/dlcSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/data/map',
			'Content/base/data/map' ],
		[ '../../campaigns/dlcquest/texture/tiles_16x16.xnb',
			'Content/base/texture/tiles_16x16.xnb' ],
		[ '../../campaigns/dlcquest/texture/skyNightSpriteSheet.xnb',
			'Content/base/texture/skyNightSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/texture/backgroundSpriteSheet.xnb',
			'Content/base/texture/backgroundSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/texture/background2SpriteSheet.xnb',
			'Content/base/texture/background2SpriteSheet.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/shopkeep.xnb',
			'Content/base/data/npc/shopkeep.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/shopkeep2.xnb',
			'Content/base/data/npc/shopkeep2.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/shepherd.xnb',
			'Content/base/data/npc/shepherd.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/random.xnb',
			'Content/base/data/npc/random.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/filler.xnb',
			'Content/base/data/npc/filler.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/blacksmith.xnb',
			'Content/base/data/npc/blacksmith.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/sidequest.xnb',
			'Content/base/data/npc/sidequest.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/troll.xnb',
			'Content/base/data/npc/troll.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/gunsmith.xnb',
			'Content/base/data/npc/gunsmith.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/princess.xnb',
			'Content/base/data/npc/princess.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/horse.xnb',
			'Content/base/data/npc/horse.xnb' ],
		],
	'EvilQuest.exe' => [
		[ 'Weapons', 'Content/weapons' ],
		[ 'DialogWindow.xnb', 'Content/HUD/dialogWindow.xnb' ],
		[ 'SpellSprites', 'Content/spellSprites' ],
		[ 'PromptMessageWindow.xnb', 'Content/HUD/promptMessageWindow.xnb' ],
		[ 'PromptWindow.xnb', 'Content/HUD/promptWindow.xnb' ],
		[ 'Menu', 'Content/menu' ],
		[ 'smallCursor.xnb', 'Content/Menu/smallcursor.xnb' ],
		[ 'ItemIcons.xnb', 'Content/Menu/itemIcons.xnb' ],
		[ 'SpellIcons.xnb', 'Content/Menu/spellIcons.xnb' ],
		[ 'SplashSymbol.xnb', 'Content/Menu/splashSymbol.xnb' ],
		[ 'SplashChaosoftLogo.xnb', 'Content/Menu/splashChaosoftLogo.xnb' ],
		[ 'SplashGamesText.xnb', 'Content/Menu/splashGamesText.xnb' ],
		[ 'PrisonGalvis_NoShadow.xnb', 'Content/prisonGalvis_NoShadow.xnb' ],
		[ 'EnemySprites', 'Content/enemysprites' ],
		[ 'Galvis_NoShadow.xnb', 'Content/EnemySprites/galvis_noShadow.xnb' ],
		[ 'DemonGalvis.xnb', 'Content/demonGalvis.xnb' ],
		[ 'StunnedEffect.xnb', 'Content/SpellSprites/stunnedEffect.xnb' ],
		[ 'Colorize.xnb', 'Content/colorize.xnb' ],
		[ 'bossDialogMusic.xnb', 'Content/BossDialogMusic.xnb' ],
		[ 'Equip.xnb', 'Content/Menu/equip.xnb' ],
		[ 'MessageWindow.xnb', 'Content/Menu/messageWindow.xnb' ],
		[ 'Shop.xnb', 'Content/shop.xnb' ],
		[ 'Title.xnb', 'Content/Menu/title.xnb' ],
		[ 'TitleNewGame.xnb', 'Content/Menu/titleNewGame.xnb' ],
		[ 'TitleNewGameActive.xnb', 'Content/Menu/titleNewGameActive.xnb' ],
		[ 'GalvisTheme.xnb', 'Content/galvisTheme.xnb' ],
		[ 'FlamesBG.xnb', 'Content/Intro/Screen1/flamesBG.xnb' ],
		[ 'FlamesFG.xnb', 'Content/Intro/Screen1/flamesFG.xnb' ],
		[ 'ForegroundMask.xnb', 'Content/Intro/Screen1/foregroundMask.xnb' ],
		[ 'VillageBGFire.xnb', 'Content/Intro/Screen3/villageBGFire.xnb' ],
		[ 'VillageFG.xnb', 'Content/Intro/Screen3/villageFG.xnb' ],
		[ 'VillageFire.xnb', 'Content/Intro/Screen3/villageFire.xnb' ],
		[ 'Galvis1.xnb', 'Content/Intro/Screen3/galvis1.xnb' ],
		[ 'Galvis2.xnb', 'Content/Intro/Screen3/galvis2.xnb' ],
		[ 'Silhouettes.xnb', 'Content/Intro/Screen4/silhouettes.xnb' ],
		[ 'FullColor.xnb', 'Content/Intro/Screen4/fullcolor.xnb' ],
		[ 'FlamesBG.xnb', 'Content/Intro/Screen4/flamesBG.xnb' ],
		[ 'FlamesFG.xnb', 'Content/Intro/Screen4/flamesFG.xnb' ],
		[ 'ForegroundMask.xnb', 'Content/Intro/Screen4/foregroundMask.xnb' ],
		[ 'ArrestFG1.xnb', 'Content/Intro/Screen5/arrestFG1.xnb' ],
		[ 'ArrestFG2.xnb', 'Content/Intro/Screen5/arrestFG2.xnb' ],
		[ 'ArrestFG3.xnb', 'Content/Intro/Screen5/arrestFG3.xnb' ],
		[ 'GalvisEndingCloseUpBG1.xnb', 'Content/Intro/Screen9/GalvisEndingCloseupBG1.xnb' ],
		[ 'ControlsPC.xnb', 'Content/Menu/controlsPC.xnb' ],
		[ 'amethyst.xnb', 'Content/Amethyst.xnb' ],
		[ 'BattlefieldIntro.xnb', 'Content/BATTLEFIELDINTRO.xnb' ],
		[ 'Prison2.xnb', 'Content/PRISON2.xnb' ],
		[ 'Prison1.xnb', 'Content/PRISON1.xnb' ],
		[ 'Items.xml', 'Data/items.dat' ],
		[ 'NPCs.xml', 'Data/NPCS.dat' ],
		],
	'Grand Class Melee.exe' => [
		[ 'water.xnb', 'Content/Sounds/Water.xnb' ],
		[ 'grass.xnb', 'Content/Sounds/Grass.xnb' ],
		[ 'move.xnb', 'Content/Sounds/Move.xnb' ],
		[ 'select.xnb', 'Content/Sounds/Select.xnb' ],
		[ 'back.xnb', 'Content/Sounds/Back.xnb' ],
		[ 'squire_base.xnb', 'Content/Textures/Players/Squire_base.xnb' ],
		[ 'squire_greyscale.xnb', 'Content/Textures/Players/Squire_greyscale.xnb' ],
		[ 'militia_base.xnb', 'Content/Textures/Players/Militia_base.xnb' ],
		[ 'militia_greyscale.xnb', 'Content/Textures/Players/Militia_greyscale.xnb' ],
		[ 'apprentice_base.xnb', 'Content/Textures/Players/Apprentice_base.xnb' ],
		[ 'apprentice_greyscale.xnb', 'Content/Textures/Players/Apprentice_greyscale.xnb' ],
		[ 'savant_base.xnb', 'Content/Textures/Players/Savant_base.xnb' ],
		[ 'savant_greyscale.xnb', 'Content/Textures/Players/Savant_greyscale.xnb' ],
		[ 'sword.xnb', 'Content/Textures/Weapons/Sword.xnb' ],
		[ 'arrow.xnb', 'Content/Sounds/Arrow.xnb' ],
		[ 'scorch.xnb', 'Content/Sounds/Scorch.xnb' ],
		[ 'bigspeed.xnb', 'Content/Sounds/Bigspeed.xnb' ],
		[ 'frame_ingame_left_ruin.xnb', 'Content/Textures/Menu/frame_ingame_left_Ruin.xnb' ],
		[ 'frame_ingame_left_mire.xnb', 'Content/Textures/Menu/frame_ingame_left_Mire.xnb' ],
		[ 'frame_ingame_right_ruin.xnb', 'Content/Textures/Menu/frame_ingame_right_Ruin.xnb' ],
		[ 'frame_ingame_left_wood.xnb', 'Content/Textures/Menu/frame_ingame_left_Wood.xnb' ],
		[ 'ruin_leaf.xnb', 'Content/Textures/Terrain/Ruin_leaf.xnb' ],
		[ 'frame_ingame_right_wood.xnb', 'Content/Textures/Menu/frame_ingame_right_Wood.xnb' ],
		[ 'bigblow1.xnb', 'Content/Sounds/Bigblow1.xnb' ],
		[ 'ruin_grassmove.xnb', 'Content/Textures/Terrain/Ruin_grassmove.xnb' ],
		[ 'wood_leaf.xnb', 'Content/Textures/Terrain/Wood_leaf.xnb' ],
		[ 'ruin_watermove.xnb', 'Content/Textures/Terrain/Ruin_watermove.xnb' ],
		[ 'castshort.xnb', 'Content/Sounds/Castshort.xnb' ],
		[ 'frame_ingame_right_mire.xnb', 'Content/Textures/Menu/frame_ingame_right_Mire.xnb' ],
		[ 'frame_ingame_left_dune.xnb', 'Content/Textures/Menu/frame_ingame_left_Dune.xnb' ],
		[ 'sword1.xnb', 'Content/Sounds/Sword1.xnb' ],
		[ 'frame_ingame_right_dune.xnb', 'Content/Textures/Menu/frame_ingame_right_Dune.xnb' ],
		[ 'staff1.xnb', 'Content/Sounds/Staff1.xnb' ],
		],
	'HonourRuns.exe' => [
		[ 'Sprites', 'Content/sprites' ],
		[ 'Textures', 'Content/textures' ],
		[ 'Levels', 'Content/levels' ],
		],
	'LaserCat.exe' => [
		[ 'audio', 'Content/Audio' ],
		],
	'MountYourFriends.exe' => [
		[ 'menuBg.xnb',
			'Content/images/menubg.xnb' ],
		[ 'humanClean.xnb',
			'Content/images/humanclean.xnb' ],
		[ 'humanCleanNorm.xnb',
			'Content/images/humancleannorm.xnb' ],
		[ 'menuMarker.xnb',
			'Content/images/menumarker.xnb' ],
		[ 'stegersaurusLogo.xnb',
			'Content/images/backdrops/stegersauruslogo.xnb' ],
		[ 'UIComponents.xnb',
			'Content/images/uicomponents.xnb' ],
		[ 'restrictedArea.xnb',
			'Content/images/restrictedarea.xnb' ],
		[ 'goatSheet.xnb',
			'Content/images/goatsheet.xnb' ],
		[ 'BP3_SSTRIP_64.xnb',
			'Content/images/bp3_sstrip_64.xnb' ],
		[ 'BP3_SSTRIP_32.xnb',
			'Content/images/bp3_sstrip_32.xnb' ],
		[ 'keySheet.xnb',
			'Content/images/keysheet.xnb' ],
		],
	'POOF.exe' => [
		[ 'QuadNoir.xnb', 'Content/QUADNOIR.xnb' ],
		[ 'QuadBlanc.xnb', 'Content/QUADBLANC.xnb' ],
		[ 'TRANS_Mask.xnb', 'Content/TRANS_MASK.xnb' ],
		],
	'PhoenixForce.exe' => [
		[ 'LIfeBar.xnb', 'Content/1.4/Boss/lifeBar.xnb' ],
		[ 'firewavexml.xml', 'Content/1.4/Player/fireWavexml.xml' ],
		[ 'firewave.xnb', 'Content/1.4/Player/fireWave.xnb' ],
		],
	'SSGame.exe' => [
		# SSDD and SSDDXXL have the same named SSGame.exe
		# SSDDXXL
		[ 'HUD_ShopBackground.xnb',
			'Content/textures/menus/HUD_Shopbackground.xnb' ],
		[ 'GLOBAL.xnb',
			'Content/levels/global.xnb' ],
		[ 'HUD_challenge_skull.xnb',
			'Content/textures/menus/hud_challenge_skull.xnb' ],
		[ 'LEVEL1.xnb',
			'Content/levels/level1.xnb' ],
		# SSDD
		[ 'FRONT.xnb',
			'Content/levels/front.xnb' ],
		],
	'Streets of Fury EX.exe' => [
		[ 'ShockWave.xnb', 'Content/Texture2D/Shockwave.xnb' ],
		],
	'TheFallOfGods2.exe' => [
		[ 'Data', 'Content/data' ],
		],
	'ThePit.exe' => [
		[ 'UI',
			'Content/ui' ],
		[ 'm_security_bot_C_sprites.xnb',
			'Content/characters/enemies/security_bot/m_security_bot_c_sprites.xnb' ],
		[ 'retriever_sprites.xnb',
			'Content/characters/enemies/retriever/retriever_Sprites.xnb' ],
		[ 'retrieverB_sprites.xnb',
			'Content/characters/enemies/retriever/retrieverB_Sprites.xnb' ],
		[ 'retrieverC_sprites.xnb',
			'Content/characters/enemies/retriever/retrieverC_Sprites.xnb' ],
		[ 'zuul_infant_swarm_sprites.xnb',
			'Content/characters/enemies/zuul_infant_swarm/zuul_infant_swarm_Sprites.xnb' ],
		[ 'zuul_infant_swarmB_sprites.xnb',
			'Content/characters/enemies/zuul_infant_swarm/zuul_infant_swarmB_Sprites.xnb' ],
		[ 'tarkodileA_Sprites.xnb',
			'Content/dlc/mg/characters/enemies/tarkodile/tarkodileA_sprites.xnb' ],
		[ 'tarkodileB_Sprites.xnb',
			'Content/dlc/mg/characters/enemies/tarkodile/tarkodileB_sprites.xnb' ],
		[ 'tarkodileC_Sprites.xnb',
			'Content/dlc/mg/characters/enemies/tarkodile/tarkodileC_sprites.xnb' ],
		[ 'cow_sprites.xnb',
			'Content/dlc/mg/characters/enemies/cow/cow_Sprites.xnb' ],
		[ 'fryoid_Sprites.xnb',
			'Content/dlc/mg/characters/enemies/protean_blob/fryoid_sprites.xnb' ],
		[ 'cryoid_Sprites.xnb',
			'Content/dlc/mg/characters/enemies/protean_blob/cryoid_sprites.xnb' ],
		],
	'WagonAdventure.exe' => [
		[ 'CRT.xnb', 'Content/FX/Crt.xnb' ],
		],
	'Wizorb.exe' => [
		# Wizorb opens some files via Paris Engine, e.g. Paris.Engine.Audio.Song
		# This needs the workaround, as FNA's TitleContainer isn't involved
		[ 'Audio/Music/BGM_AttractMode.wav',
			'Content/Audio\\Music\\BGM_AttractMode.wav' ],
		[ 'Audio/Music/BGM_Bonus.wav',
			'Content/Audio\\Music\\BGM_Bonus.wav' ],
		[ 'Audio/Music/BGM_Boss.wav',
			'Content/Audio\\Music\\BGM_Boss.wav' ],
		[ 'Audio/Music/BGM_Castle.wav',
			'Content/Audio\\Music\\BGM_Castle.wav' ],
		[ 'Audio/Music/BGM_CloverVillage.wav',
			'Content/Audio\\Music\\BGM_CloverVillage.wav' ],
		[ 'Audio/Music/BGM_EndCredits.wav',
			'Content/Audio\\Music\\BGM_EndCredits.wav' ],
		[ 'Audio/Music/BGM_EndImages.wav',
			'Content/Audio\\Music\\BGM_EndImages.wav' ],
		[ 'Audio/Music/BGM_EvilEnding.wav',
			'Content/Audio\\Music\\BGM_EvilEnding.wav' ],
		[ 'Audio/Music/BGM_Forest.wav',
			'Content/Audio\\Music\\BGM_Forest.wav' ],
		[ 'Audio/Music/BGM_GameOver.wav',
			'Content/Audio\\Music\\BGM_GameOver.wav' ],
		[ 'Audio/Music/BGM_LevelComplete.wav',
			'Content/Audio\\Music\\BGM_LevelComplete.wav' ],
		[ 'Audio/Music/BGM_Mines.wav',
			'Content/Audio\\Music\\BGM_Mines.wav' ],
		[ 'Audio/Music/BGM_Netherworld.wav',
			'Content/Audio\\Music\\BGM_Netherworld.wav' ],
		[ 'Audio/Music/BGM_Shop.wav',
			'Content/Audio\\Music\\BGM_Shop.wav' ],
		[ 'Audio/Music/BGM_Title.wav',
			'Content/Audio\\Music\\BGM_Title.wav' ],
		[ 'Audio/Music/BGM_Village.wav',
			'Content/Audio\\Music\\BGM_Village.wav' ],
		[ 'Audio/Music/BGM_WorldMap.wav',
			'Content/Audio\\Music\\BGM_WorldMap.wav' ],
		],
	'WoCGame.exe' => [
		[ 'Arial14.xnb', 'Content/fonts/arial14.xnb' ],
		],
	};

sub iomap_symlink () {
	my %symlink_hash;
	my $index_file;

	foreach my $k ( keys %iomap ) {
		$index_file = $k if -e $k;
		last if $index_file;
	}
	return unless $index_file;

	foreach my $symlink_pair ( @{ $iomap{ $index_file } } ) {
		my ($oldfile, $newfile) = @{ $symlink_pair };
		next if ( -e $newfile );
		$symlink_hash{ $newfile } = $oldfile;
	}
	return %symlink_hash;
}

1;
