package IndieRunner::Mono::Dllmap;

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

use autodie;

use base qw( Exporter );
our @EXPORT_OK = qw( get_dllmap_target );

use IndieRunner::Cmdline qw( cli_dryrun cli_verbose );

Readonly::Scalar my $dllmap => <<"END_DLLMAP";
<!-- IndieRunner monolithic config -->
<configuration>
	<dllmap dll="FAudio" target="libFAudio.so"/>
	<dllmap dll="FNA3D" target="libFNA3D.so"/>
	<dllmap dll="MojoShader.dll" target="libFNA3D.so"/>
	<dllmap dll="SDL2.dll" target="libSDL2.so"/>
	<dllmap dll="SDL2_image.dll" target="libSDL2_image.so"/>
	<dllmap dll="SDL2_mixer.dll" target="libSDL2_mixer.so"/>
	<dllmap dll="SDL2_ttf.dll" target="libSDL2_ttf.so"/>
	<dllmap dll="freetype6" target="libfreetype.so" />
	<dllmap dll="freetype6.dll" target="libfreetype.so" />
	<dllmap dll="libtheorafile.dll" target="libtheorafile.so"/>
	<dllmap dll="libtheoraplay.dll" target="libtheoraplay.so"/>
	<dllmap dll="libvorbisfile.dll" target="libvorbisfile.so"/>
	<dllmap dll="libvorbisfile-3.dll" target="libvorbisfile.so"/>
	<dllmap dll="openal32.dll" target="libopenal.so"/>
	<dllmap dll="soft_oal.dll" target="libopenal.so"/>
	<dllmap dll="System.Native" target="libmono-native.so"/>
	<dllmap dll="System.Net.Security.Native" target="libmono-native.so"/>
	<dllmap dll="i:msvcrt" target="libc.so" os="!windows"/>
	<dllmap dll="i:msvcrt.dll" target="libc.so" os="!windows"/>
	<dllmap dll="msvcr100.dll" target="libc.so"/>

	<dllmap dll="i:CommunityExpressSW" target="libcestub.so"/>
	<dllmap dll="i:CommunityExpressSW.dll" target="libcestub.so"/>

	<dllmap dll="steam_api" target="libsteam_api.so"/>
	<dllmap dll="steam_api64" target="libsteam_api.so"/>
	<dllmap dll="CSteamworks.dll" target="libCSteamworks.so"/>
	<dllmap dll="i:SteamworksNative" target="libSteamworksNative.so"/>
	<dllmap dll="i:steamwrapper.dll" target="libsteamwrapper.so"/>

	<dllmap dll="user32.dll">
		<dllentry dll="libc.so" name="GetWindowThreadProcessId" target="getthrid"/>
		<dllentry dll="libstubborn.so" name="SetWindowsHookEx" target="int_0"/>
		<dllentry dll="libstubborn.so" name="GetClipCursor" target="int_0"/>
		<dllentry dll="libstubborn.so" name="DestroyIcon" target="int_0"/>
	</dllmap>

	<dllmap dll="ntdll.dll">
		<dllentry dll="libstubborn.so" name="NtQueryInformationProcess" target="int_0"/>
	</dllmap>

	<dllmap dll="ArkSteamWrapper.dll">
		<dllentry dll="libstubborn.so" name="ArkSteamInit" target="int_0"/>
		<dllentry dll="libstubborn.so" name="ArkGetPlayerId" target="int_0"/>
	</dllmap>

	<dllmap dll="discord-rpc">
		<dllentry dll="libstubborn.so" name="Initialize" target="int_0"/>
		<dllentry dll="libstubborn.so" name="Discord_Initialize" target="int_0"/>
		<dllentry dll="libstubborn.so" name="Discord_UpdatePresence" target="int_0"/>
		<dllentry dll="libstubborn.so" name="Discord_RunCallbacks" target="int_0"/>
	</dllmap>

	<dllmap dll="BrutallyUnfairDll.dll">
		<dllentry dll="libstubborn.so" name="loadSteamDll" target="int_0"/>
		<dllentry dll="libstubborn.so" name="initSteamAPI" target="int_0"/>
		<dllentry dll="libstubborn.so" name="GetModuleHandle" target="int_0"/>
	</dllmap>

	<dllmap dll="fmod_event.dll">
		<dllentry dll="libstubborn.so" name="FMOD_EventSystem_Create" target="int_0"/>
	</dllmap>

	<dllmap dll="kernel32">
		<dllentry dll="ld.so" name="LoadLibrary" target="dlopen"/>
	</dllmap>

	<dllmap dll="fmodstudio">
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Create" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Initialize" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_SetListenerAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Update" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_LoadBankFile" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetVCA" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_VCA_SetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_VCA_GetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetEvent" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_LoadSampleData" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_CreateInstance" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_Is3D" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Start" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetBus" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_SetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_GetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetDescription" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_GetPath" target="int_celeste_event"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bank_LoadSampleData" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetListenerAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Set3DAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Release" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Stop" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Get3DAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Release" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetParameterValue" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_IsOneshot" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_TriggerCue" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_StopAllEvents" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetPlaybackState" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetLowLevelSystem" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_GetInstanceCount" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_UnloadSampleData" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_FlushCommands" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_GetChannelGroup" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetCallback" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_UnloadAll" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetCoreSystem" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_SetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetPitch" target="int_0"/>
	</dllmap>

	<!-- Epic -->
	<dllmap dll="EOSSDK-Win64-Shipping.dll">
		<dllentry dll="libstubborn.so" name="EOS_Initialize" target="int_0"/>
		<dllentry dll="libstubborn.so" name="EOS_Logging_SetLogLevel" target="int_0"/>
		<dllentry dll="libstubborn.so" name="EOS_Logging_SetCallback" target="int_0"/>
		<dllentry dll="libstubborn.so" name="EOS_Platform_Create" target="ptr_zeroed"/>
		<dllentry dll="libstubborn.so" name="EOS_Platform_GetConnectInterface" target="ptr_zeroed"/>
		<dllentry dll="libstubborn.so" name="EOS_Connect_AddNotifyAuthExpiration" target="ptr_zeroed"/>
		<dllentry dll="libstubborn.so" name="EOS_Connect_AddNotifyLoginStatusChanged" target="ptr_zeroed"/>
	</dllmap>

	<!-- FMOD -->
	<dllmap dll="fmodstudio.dll">
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Create"	 target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Initialize" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_SetListenerAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Update" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_LoadBankFile" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetVCA" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_VCA_SetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_VCA_GetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetEvent" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_LoadSampleData" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_CreateInstance" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_Is3D" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Start" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetBus" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_SetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_GetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetDescription" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_GetPath" target="int_celeste_event"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bank_LoadSampleData" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetListenerAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Set3DAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Release" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Stop" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_Get3DAttributes" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_Release" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetParameterValue" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_IsOneshot" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_TriggerCue" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_StopAllEvents" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetPaused" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_GetPlaybackState" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_GetLowLevelSystem" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_GetInstanceCount" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventDescription_UnloadSampleData" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_LockChannelGroup" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_System_FlushCommands" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_Bus_GetChannelGroup" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_Studio_EventInstance_SetCallback" target="int_0"/>
	</dllmap>

	<dllmap dll="fmodex">
		<dllentry dll="libstubborn.so" name="FMOD_System_Create" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_System_GetVersion" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_System_Init" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_System_SetReverbProperties" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_System_Update" target="int_0"/>
	</dllmap>

	<dllmap dll="uP2P.dll">
		<dllentry dll="libstubborn.so" name="libuP2P_liaison_init" target="int_1"/>
		<dllentry dll="libstubborn.so" name="libuP2P_hook" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_part_read" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_part" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_sync_zero" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_persona_rich" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_liaison_poll" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_fake" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_take" target="int_0"/>
		<dllentry dll="libstubborn.so" name="libuP2P_liaison_exit" target="int_0"/>
	</dllmap>

	<dllmap dll="fmod">
		<dllentry dll="libstubborn.so" name="FMOD_System_GetVersion" target="int_fmf_getversion"/>
		<dllentry dll="libstubborn.so" name="FMOD_System_SetDSPBufferSize" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_System_SetAdvancedSettings" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_System_SetSoftwareChannels" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD5_System_SetSoftwareChannels" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD5_System_SetSoftwareFormat" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD5_System_Release" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_ChannelGroup_SetVolume" target="int_0"/>
		<dllentry dll="libstubborn.so" name="FMOD_ChannelGroup_SetPitch" target="int_0"/>
	</dllmap>

	<!-- PhotonBridge (Unrailed!) -->
	<dllmap dll="PhotonBridge">
		<dllentry dll="libstubborn.so" name="init" target="int_1"/>
		<dllentry dll="libstubborn.so" name="Init" target="int_1"/>
	</dllmap>

	<dllmap dll="SteamLink.dll">
		<dllentry dll="libstubborn.so" name="SteamLink_Init" target="int_1"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetMessageCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetDataReceivedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetPersonaStateChangeCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_Shutdown" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetLobbyChatUpdateCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetLobbyDataUpdatedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetLobbyCreatedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetLobbyEnteredCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetLobbyGameCreatedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetBeginAuthResponseCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetP2PSessionRequestCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetP2PSessionConnectFailCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetAvatarImageLoadedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetSteamServersConnectedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetSteamServersDisconnectedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetSteamServerConnectFailureCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetServerListRefreshCompleteCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetIPCFailureCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetSteamShutdownCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetUserStatsReceivedCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetUserStatsStoredCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetAchievementStoredCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetPolicyResponseCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetGSClientApproveCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetGSClientDenyCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_SetGSClientKickCallbackPtr" target="int_0"/>
		<dllentry dll="libstubborn.so" name="SteamLink_GetAchievementUnlockStatus" target="int_0"/>
	</dllmap>
</configuration>
END_DLLMAP

sub get_dllmap_target {
	# XXX: check	CLI-supplied file (-c argument?)
	#		~/.IndieRunner/IndieRunner.dllmap.config
	#		/usr/local/share/IndieRunner/IndieRunner.dllmap.config

	my $temp_dllmap_file = '/tmp/IndieRunner.dllmap';
	my $dryrun = cli_dryrun;
	my $verbose = cli_verbose;

	if ( -f $temp_dllmap_file ) {
		if ( $verbose ) {
			say "Dllmap file $temp_dllmap_file already present.";
		}
		return $temp_dllmap_file;
	}

	if ( $dryrun || $verbose ) {
		say "Writing Dllmap file to $temp_dllmap_file.";
	}
	unless ( $dryrun ) {
		open(my $fh, '>', $temp_dllmap_file);
		print $fh $dllmap;
		close $fh;
	}

	return $temp_dllmap_file;
}

1;
