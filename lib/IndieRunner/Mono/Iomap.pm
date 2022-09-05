package IndieRunner::Mono::Iomap;

# Copyright (c) 2022 Thomas Frohwein
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

use strict;
use warnings;
use v5.10;
use version 0.77; our $VERSION = version->declare('v0.0.1');
use Carp;
use Readonly;

use base qw( Exporter );
our @EXPORT_OK =qw( iomap_symlink );

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );

Readonly::Hash my %iomap => {
	'AJ1.exe' => [
		[ 'j_rip.xnb', 'Content/AJ1/j_Rip.xnb' ],
		[ 'j_rip.xnb', 'Content/AJ2/j_Rip.xnb' ],
		[ 'Owlturnneo2.xnb', 'Content/AJ1/owlturnneo2.xnb' ],
		[ 'Owlturnneo2.xnb', 'Content/AJ2/owlturnneo2.xnb' ],
		],
	'Aces Wild.exe' => [
		[ 'HitSparks', 'Content/Sprites/Hitsparks' ],
		[ 'preFabs.awx', 'Content/Data/prefabs.awx' ],
		],
	'AtTheGates.exe' => [
		[ '../../Components/GraphicalButtons/Pillage_64.xnb', 'Content/Images/Interface/Icons/Concepts/Pillage.xnb' ],
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
	'DLC.exe' => [
		[ '../../campaigns/dlcquest/texture/awardmentSpriteSheet.xnb', 'Content/base/texture/awardmentSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/texture/dlcSpriteSheet.xnb', 'Content/base/texture/dlcSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/data/map', 'Content/base/data/map' ],
		[ '../../campaigns/dlcquest/texture/tiles_16x16.xnb', 'Content/base/texture/tiles_16x16.xnb' ],
		[ '../../campaigns/dlcquest/texture/skyNightSpriteSheet.xnb', 'Content/base/texture/skyNightSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/texture/backgroundSpriteSheet.xnb', 'Content/base/texture/backgroundSpriteSheet.xnb' ],
		[ '../../campaigns/dlcquest/texture/background2SpriteSheet.xnb', 'Content/base/texture/background2SpriteSheet.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/shopkeep.xnb', 'Content/base/data/npc/shopkeep.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/shopkeep2.xnb', 'Content/base/data/npc/shopkeep2.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/shepherd.xnb', 'Content/base/data/npc/shepherd.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/random.xnb', 'Content/base/data/npc/random.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/filler.xnb', 'Content/base/data/npc/filler.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/blacksmith.xnb', 'Content/base/data/npc/blacksmith.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/sidequest.xnb', 'Content/base/data/npc/sidequest.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/troll.xnb', 'Content/base/data/npc/troll.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/gunsmith.xnb', 'Content/base/data/npc/gunsmith.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/princess.xnb', 'Content/base/data/npc/princess.xnb' ],
		[ '../../../campaigns/dlcquest/data/npc/horse.xnb', 'Content/base/data/npc/horse.xnb' ],
		],
	'Dead Pixels.exe' => [
		[ 'Sprites', 'Content/sprites' ],
		[ 'Effects', 'Content/Sprites/effects' ],
		[ 'Splash', 'Content/Sprites/splash' ],
		[ 'Items',  'Content/Sprites/InGame/items' ],
		[ 'Grenades',  'Content/Sprites/InGame/grenades' ],
		[ 'Hud',  'Content/Sprites/InGame/hud' ],
		[ 'insideBuildings',  'Content/Sprites/InGame/InsideBuildings' ],
		[ 'Character',  'Content/Sprites/InGame/character' ],
		[ 'City',  'Content/Sprites/InGame/city' ],
		[ 'Traders',  'Content/Sprites/InGame/traders' ],
		[ 'Zombies',  'Content/Sprites/InGame/zombies' ],
		[ 'Objects',  'Content/Sprites/InGame/objects' ],
		[ 'Other',  'Content/Sprites/InGame/other' ],
		[ 'GunShots',  'Content/Sprites/InGame/gunShots' ],
		[ 'Buttons', 'Content/Sprites/buttons' ],
		[ 'Menu', 'Content/Sprites/menu' ],
		[ 'Cursor', 'Content/Sprites/cursor' ],
		[ 'Achievements', 'Content/Sprites/achievements' ],
		[ 'Credits', 'Content/Sprites/credits' ],
		[ 'Font', 'Content/Sprites/font' ],
		[ 'preview', 'Content/Sprites/Preview' ],
		[ 'preview',  'Content/Sprites/Menu/Preview' ],
		[ 'PsxButtons',  'Content/Sprites/buttons/psxButtons' ],
		[ 'Cutscene', 'Content/Sprites/CutScene' ],
		[ 'buildings', 'Content/Sprites/InGame/City/Buildings' ],
		[ 'mainbackground.xnb', 'Content/ConfigSprites/mainBackground.xnb' ],
		[ 'largeCuts.xnb', 'Content/Sprites/effects/largecuts.xnb' ],
		[ 'smallCuts.xnb', 'Content/Sprites/effects/smallcuts.xnb' ],
		[ 'cuemark.xnb', 'Content/Sprites/effects/cueMark.xnb' ],
		[ 'Static.xnb', 'Content/Sprites/Menu/Preview/static.xnb' ],
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
	'HELLYEAH.exe' => [
		[ 'QuadNoir.xnb', 'Content/QUADNOIR.xnb' ],
		[ 'QuadBlanc.xnb', 'Content/QUADBLANC.xnb' ],
		[ 'TRANS_Mask.xnb', 'Content/TRANS_MASK.xnb' ],
		[ 'Popup', 'Content/GAME/HUD/POPUP' ],
		[ 'pop_u_trung.xnb', 'Content/GAME/HUD/Popup/POP_U_TRUNG.xnb' ],
		[ 'popup_cartouche_noir.xnb', 'Content/GAME/HUD/Popup/POPUP_CARTOUCHE_NOIR.xnb' ],
		[ 'popup_barre_rouges.xnb', 'Content/GAME/HUD/Popup/POPUP_BARRE_ROUGES.xnb' ],
		[ 'Menu_\(arial\).xnb', 'Content/TITLE/FONTS/MENU_\(ARIAL\).xnb' ],
		[ 'cursor.xnb', 'Content/PCONLY/CURSORS/CURSOR.xnb' ],
		[ 'viseur.xnb', 'Content/PCONLY/CURSORS/VISEUR.xnb' ],
		[ 'Shaders', 'Content/SHADERS' ],
		[ 'WhiteFlash.xnb', 'Content/Shaders/WHITEFLASH.xnb' ],
		[ 'VaguePoison.xnb', 'Content/Shaders/VAGUEPOISON.xnb' ],
		[ 'Black.xnb', 'Content/Shaders/BLACK.xnb' ],
		[ 'White.xnb', 'Content/Shaders/WHITE.xnb' ],
		[ 'BloomExtract.xnb', 'Content/Shaders/BLOOMEXTRACT.xnb' ],
		[ 'BloomCombine.xnb', 'Content/Shaders/BLOOMCOMBINE.xnb' ],
		[ 'GaussianBlur.xnb', 'Content/Shaders/GAUSSIANBLUR.xnb' ],
		[ 'Sobel.xnb', 'Content/Shaders/SOBEL.xnb' ],
		[ 'RadialBlur.xnb', 'Content/Shaders/RADIALBLUR.xnb' ],
		[ 'VagueFeu.xnb', 'Content/Shaders/VAGUEFEU.xnb' ],
		[ 'ColorEffects.xnb', 'Content/Shaders/COLOREFFECTS.xnb' ],
		[ 'Explosion.xnb', 'Content/Shaders/EXPLOSION.xnb' ],
		[ 'Ripple.xnb', 'Content/Shaders/RIPPLE.xnb' ],
		[ 'RedFilter.xnb', 'Content/Shaders/REDFILTER.xnb' ],
		[ 'Distortion.xnb', 'Content/Shaders/DISTORTION.xnb' ],
		[ 'Lightning.xnb', 'Content/Shaders/LIGHTNING.xnb' ],
		[ 'LoadingWheel.xnb', 'Content/GAME/LOADING/LOADINGWHEEL.xnb' ],
		[ 'LOGO_Sega.xnb', 'Content/LOGO/LOGO_SEGA.xnb' ],
		[ 'LOGO_Arkedo.xnb', 'Content/LOGO/LOGO_ARKEDO.xnb' ],
		[ 'Sounds', 'Content/GAME/WORLD/SOUNDS' ],
		[ 'HY_Sounds.xnb', 'Content/GAME/WORLD/Sounds/HY_SOUNDS.xnb' ],
		[ 'picto_A.xnb', 'Content/GAME/FONTS/PICTO/PICTO_A.xnb' ],
		[ 'picto_B.xnb', 'Content/GAME/FONTS/PICTO/PICTO_B.xnb' ],
		[ 'picto_BK.xnb', 'Content/GAME/FONTS/PICTO/PICTO_BK.xnb' ],
		[ 'picto_LB.xnb', 'Content/GAME/FONTS/PICTO/PICTO_LB.xnb' ],
		[ 'picto_LS.xnb', 'Content/GAME/FONTS/PICTO/PICTO_LS.xnb' ],
		[ 'picto_LT.xnb', 'Content/GAME/FONTS/PICTO/PICTO_LT.xnb' ],
		[ 'picto_PAD.xnb', 'Content/GAME/FONTS/PICTO/PICTO_PAD.xnb' ],
		[ 'picto_RB.xnb', 'Content/GAME/FONTS/PICTO/PICTO_RB.xnb' ],
		[ 'picto_RS.xnb', 'Content/GAME/FONTS/PICTO/PICTO_RS.xnb' ],
		[ 'picto_RT.xnb', 'Content/GAME/FONTS/PICTO/PICTO_RT.xnb' ],
		[ 'picto_ST.xnb', 'Content/GAME/FONTS/PICTO/PICTO_ST.xnb' ],
		[ 'picto_X.xnb', 'Content/GAME/FONTS/PICTO/PICTO_X.xnb' ],
		[ 'picto_Y.xnb', 'Content/GAME/FONTS/PICTO/PICTO_Y.xnb' ],
		[ 'picto_RS1.xnb', 'Content/GAME/FONTS/PICTO/PICTO_RS1.xnb' ],
		[ 'picto_RS2.xnb', 'Content/GAME/FONTS/PICTO/PICTO_RS2.xnb' ],
		[ 'picto_RS3.xnb', 'Content/GAME/FONTS/PICTO/PICTO_RS3.xnb' ],
		[ 'picto_RS4.xnb', 'Content/GAME/FONTS/PICTO/PICTO_RS4.xnb' ],
		[ 'picto_360.xnb', 'Content/GAME/FONTS/PICTO/PICTO_360.xnb' ],
		[ 'saving.xnb', 'Content/LOGO/SAVING.xnb' ],
		[ 'branchetonpad.xnb', 'Content/PCONLY/MENUS/BRANCHETONPAD.xnb' ],
		[ 'pckey.xnb', 'Content/PCONLY/MENUS/PCKEY.xnb' ],
		[ 'mousecenter.xnb', 'Content/PCONLY/MENUS/MOUSECENTER.xnb' ],
		[ 'mousedefault.xnb', 'Content/PCONLY/MENUS/MOUSEDEFAULT.xnb' ],
		[ 'mousedirections.xnb', 'Content/PCONLY/MENUS/MOUSEDIRECTIONS.xnb' ],
		[ 'mouseleftbt.xnb', 'Content/PCONLY/MENUS/MOUSELEFTBT.xnb' ],
		[ 'mouserightbt.xnb', 'Content/PCONLY/MENUS/MOUSERIGHTBT.xnb' ],
		[ 'mousewheelup.xnb', 'Content/PCONLY/MENUS/MOUSEWHEELUP.xnb' ],
		[ 'mousewheeldown.xnb', 'Content/PCONLY/MENUS/MOUSEWHEELDOWN.xnb' ],
		[ 'ls.xnb', 'Content/PCONLY/MENUS/LS.xnb' ],
		[ 'ls1.xnb', 'Content/PCONLY/MENUS/LS1.xnb' ],
		[ 'ls2.xnb', 'Content/PCONLY/MENUS/LS2.xnb' ],
		[ 'ls360.xnb', 'Content/PCONLY/MENUS/LS360.xnb' ],
		[ 'rs1.xnb', 'Content/PCONLY/MENUS/RS1.xnb' ],
		[ 'rs2.xnb', 'Content/PCONLY/MENUS/RS2.xnb' ],
		[ 'rs3.xnb', 'Content/PCONLY/MENUS/RS3.xnb' ],
		[ 'rs4.xnb', 'Content/PCONLY/MENUS/RS4.xnb' ],
		[ 'INT_Radar_(good_girl).xnb', 'Content/GAME/FONTS/INT_RADAR_(GOOD_GIRL).xnb' ],
		[ 'DLG_Name_(trashand).xnb', 'Content/GAME/FONTS/DLG_NAME_(TRASHAND).xnb' ],
		[ 'Particules', 'Content/TITLE/PARTICULES' ],
		[ 'boum.xnb', 'Content/TITLE/Particules/BOUM.xnb' ],
		[ 'flameches.xnb', 'Content/TITLE/Particules/FLAMECHES.xnb' ],
		[ 'fumee_background_flou.xnb', 'Content/TITLE/Particules/FUMEE_BACKGROUND_FLOU.xnb' ],
		[ 'fumee_noire.xnb', 'Content/TITLE/Particules/FUMEE_NOIRE.xnb' ],
		[ 'gaz_multicolor.xnb', 'Content/TITLE/Particules/GAZ_MULTICOLOR.xnb' ],
		[ 'TITLE_Cartouche.xnb', 'Content/TITLE/TITLE_CARTOUCHE.xnb' ],
		[ 'TITLE_Subtitle-EN.xnb', 'Content/TITLE/TITLE_SUBTITLE-EN.xnb' ],
		[ 'TITLE_Logo.xnb', 'Content/TITLE/TITLE_LOGO.xnb' ],
		[ 'TITLE_FlameScroll.xnb', 'Content/TITLE/TITLE_FLAMESCROLL.xnb' ],
		[ 'TITLE_LogoMask.xnb', 'Content/TITLE/TITLE_LOGOMASK.xnb' ],
		[ 'TITLE_Background.xnb', 'Content/TITLE/TITLE_BACKGROUND.xnb' ],
		[ 'TITLE_Select.xnb', 'Content/TITLE/TITLE_SELECT.xnb' ],
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
		[ 'menuBg.xnb', 'Content/images/menubg.xnb' ],
		[ 'humanClean.xnb', 'Content/images/humanclean.xnb' ],
		[ 'humanCleanNorm.xnb', 'Content/images/humancleannorm.xnb' ],
		[ 'menuMarker.xnb', 'Content/images/menumarker.xnb' ],
		[ 'stegersaurusLogo.xnb', 'Content/images/backdrops/stegersauruslogo.xnb' ],
		[ 'UIComponents.xnb', 'Content/images/uicomponents.xnb' ],
		[ 'restrictedArea.xnb', 'Content/images/restrictedarea.xnb' ],
		[ 'goatSheet.xnb', 'Content/images/goatsheet.xnb' ],
		[ 'BP3_SSTRIP_64.xnb', 'Content/images/bp3_sstrip_64.xnb' ],
		[ 'BP3_SSTRIP_32.xnb', 'Content/images/bp3_sstrip_32.xnb' ],
		[ 'keySheet.xnb', 'Content/images/keysheet.xnb' ],
		],
	'One Finger Death Punch.exe' => [
		[ 'font2.xnb', 'Content/Font2.xnb' ],
		[ 'font5.xnb', 'Content/Font5.xnb' ],
		[ 'font6.xnb', 'Content/Font6.xnb' ],
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
		[ 'HUD_ShopBackground.xnb', 'Content/textures/menus/HUD_Shopbackground.xnb' ],
		[ 'GLOBAL.xnb', 'Content/levels/global.xnb' ],
		[ 'HUD_challenge_skull.xnb', 'Content/textures/menus/hud_challenge_skull.xnb' ],
		[ 'LEVEL1.xnb', 'Content/levels/level1.xnb' ],
		# SSDD
		[ 'FRONT.xnb', 'Content/levels/front.xnb' ],
		],
	'Snails.exe' => [
		[ 'ScreensData.xnb', 'Content/screens/screensdata.xnb' ],
		[ 'footerMessage.xnb', 'Content/fonts/footermessage.xnb' ],
		[ 'MainMenu.xnb', 'Content/screens/mainmenu.xnb' ],
		[ 'UISnailsMenu.xnb', 'Content/screens/controls/uisnailsmenu.xnb' ],
		[ 'UIMainMenuBodyPanel.xnb', 'Content/screens/controls/uimainmenubodypanel.xnb' ],
		],
	'Streets of Fury EX.exe' => [
		[ 'ShockWave.xnb', 'Content/Texture2D/Shockwave.xnb' ],
		],
	'TheFallOfGods2.exe' => [
		[ 'Data', 'Content/data' ],
		],
	'ThePit.exe' => [
		[ 'UI', 'Content/ui' ],
		[ 'm_security_bot_C_sprites.xnb', 'Content/characters/enemies/security_bot/m_security_bot_c_sprites.xnb' ],
		],
	'WagonAdventure.exe' => [
		[ 'CRT.xnb', 'Content/FX/Crt.xnb' ],
		],
	'WoCGame.exe' => [
		[ 'Arial14.xnb', 'Content/fonts/arial14.xnb' ],
		],
	};

sub iomap_symlink {
	my ($index_file) = @_;
	my $dryrun = cli_dryrun();
	my $verbose = cli_verbose();

	return 0 unless ( grep( /^\Q$index_file\E$/, keys %iomap ) );
	say "Found $index_file; create symlinks to make up for abandoned MONO_IOMAP"
		if $verbose;

	foreach my $symlink_pair ( @{ $iomap{ $index_file } } ) {
		my ($oldfile, $newfile) = @{ $symlink_pair };
		next if ( -e $newfile );
		say "Symlink: $newfile -> $oldfile" if ( $dryrun || $verbose );
		unless ( $dryrun ) {
			symlink($oldfile, $newfile) or
				croak "Failed to create symlink $newfile: $!";
		}
	}

	return 1;
}

1;
