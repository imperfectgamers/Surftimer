/*=======================================================
=                    CS:GO Surftimer                    =
 This is a heavily modified version of ckSurf by fluffys 
 The original version of this timer was by jonitaikaponi 
= https://forums.alliedmods.net/showthread.php?t=264498 =
=======================================================*/

/*====================================
=              Includes              =
====================================*/

#include <sourcemod>
// #include <regex>
#include <sdkhooks>
#include <adminmenu>
#include <cstrike>
#include <smlib>
#include <geoip>
#include <basecomm>
#include <colorvariables>
#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <dhooks>
#include <mapchooser>
#include <sdktools>
// #include <store>
#include <discord>
#include <sourcecomms>
#include <surftimer>

/*====================================
=            Declarations            =
====================================*/

/*===================================
=            Definitions            =
===================================*/

#define MAX_STEAMID_LENGTH 32
#define MAX_MAPNAME_LENGTH 128
#define MAX_TITLE_LENGTH 128
#define MAX_TITLES 32
#define MAX_RAWTITLE_LENGTH 1024

// Require New Syntax & Semicolons
#pragma newdecls required
#pragma semicolon 1

// Plugin Info
#define VERSION "2.2"
#define PLUGIN_VERSION 220

// Database Definitions
#define MYSQL 0
#define SQLITE 1
#define PERCENT 0x25
#define QUOTE 0x22

// Chat Colors
#define WHITE 0x01
#define DARKRED 0x02
#define PURPLE 0x03
#define GREEN 0x04
#define LIGHTGREEN 0x05
#define LIMEGREEN 0x06
#define RED 0x07
#define GRAY 0x08
#define YELLOW 0x09
#define ORANGE 0x10
#define DARKGREY 0x0A
#define BLUE 0x0B
#define DARKBLUE 0x0C
#define LIGHTBLUE 0x0D
#define PINK 0x0E
#define LIGHTRED 0x0F

// Paths for folders and files
#define CK_REPLAY_PATH "data/replays/"
#define MULTI_SERVER_MAPCYCLE "configs/surftimer/multi_server_mapcycle.txt"
#define CUSTOM_TITLE_PATH "configs/surftimer/custom_chat_titles.txt"
#define SKILLGROUP_PATH "configs/surftimer/skillgroups.cfg"
#define DEFAULT_TITLES_WHITELIST_PATH "configs/surftimer/default_titles_whitelist.txt"
#define DEFAULT_TITLES_PATH "configs/surftimer/default_titles.txt"

// Paths for sounds
#define PRO_FULL_SOUND_PATH "sound/quake/holyshit.mp3"
#define PRO_RELATIVE_SOUND_PATH "*quake/holyshit.mp3"
#define CP_FULL_SOUND_PATH "sound/quake/wickedsick.mp3"
#define CP_RELATIVE_SOUND_PATH "*quake/wickedsick.mp3"
#define UNSTOPPABLE_SOUND_PATH "sound/quake/unstoppable.mp3"
#define UNSTOPPABLE_RELATIVE_SOUND_PATH "*quake/unstoppable.mp3"
#define WR_FULL_SOUND_PATH "sound/surftimer/wr/1/valve_logo_music.mp3"
#define WR_RELATIVE_SOUND_PATH "*surftimer/wr/1/valve_logo_music.mp3"
#define WR2_FULL_SOUND_PATH "sound/surftimer/wr/2/valve_logo_music.mp3"
#define WR2_RELATIVE_SOUND_PATH "*surftimer/wr/2/valve_logo_music.mp3"
#define TOP10_FULL_SOUND_PATH "sound/surftimer/top10/valve_logo_music.mp3"
#define TOP10_RELATIVE_SOUND_PATH "*surftimer/top10/valve_logo_music.mp3"
#define PR_FULL_SOUND_PATH "sound/surftimer/pr/valve_logo_music.mp3"
#define PR_RELATIVE_SOUND_PATH "*surftimer/pr/valve_logo_music.mp3"
#define WRCP_FULL_SOUND_PATH "sound/surftimer/wow_fast.mp3"
#define WRCP_RELATIVE_SOUND_PATH "*surftimer/wow_fast.mp3"
#define DISCOTIME_FULL_SOUND_PATH "sound/surftimer/discotime.mp3"
#define DISCOTIME_RELATIVE_SOUND_PATH "*/surftimer/discotime.mp3"

#define ZONE_REFRESH_TIME 5.0

#define MAX_STYLES 7

#define VOTE_NO "###no###"
#define VOTE_YES "###yes###"

// Checkpoint Definitions
// Maximum amount of checkpoints in a map
#define CPLIMIT 37

// Zone Definitions
#define ZONE_MODEL "models/props/de_train/barrel.mdl"

#define ZONETYPE_STOP 0
#define ZONETYPE_START 1
#define ZONETYPE_END 2
#define ZONETYPE_STAGE 3
#define ZONETYPE_CHECKPOINT 4
#define ZONETYPE_SPEEDSTART 5
#define ZONETYPE_TELETOSTART 6
#define ZONETYPE_VALIDATOR 7
#define ZONETYPE_CHECKER 8
#define ZONETYPE_ANTIJUMP 9
#define ZONETYPE_ANTIDUCK 10
#define ZONETYPE_MAXSPEED 11

// Zone Amount
// Types: Start(1), End(2), Stage(3), Checkpoint(4), Speed(5), 
// TeleToStart(6), Validator(7), Chekcer(8), Stop(0), AntiJump(9), 
// AntiDuck(10), MaxSpeed(11)
#define ZONEAMOUNT 12
// Maximum amount of zonegroups in a map
#define MAXZONEGROUPS 12
// Maximum amount of zones in a map
#define MAXZONES 128	

// Ranking Definitions
#define MAX_PR_PLAYERS 1066
#define MAX_SKILLGROUPS 64

// UI Definitions
#define HIDE_RADAR (1 << 12)
#define HIDE_CHAT ( 1<<7 )
#define HIDE_CROSSHAIR 1<<8

// Replay Definitions
#define BM_MAGIC 0xBAADF00D
#define BINARY_FORMAT_VERSION 0x01
#define ADDITIONAL_FIELD_TELEPORTED_ORIGIN (1<<0)
#define ADDITIONAL_FIELD_TELEPORTED_ANGLES (1<<1)
#define ADDITIONAL_FIELD_TELEPORTED_VELOCITY (1<<2)
#define FRAME_INFO_SIZE 15
#define AT_SIZE 10
#define ORIGIN_SNAPSHOT_INTERVAL 500
#define FILE_HEADER_LENGTH 74

// Show Triggers
#define EF_NODRAW 32

// New Save Locs
#define MAX_LOCS 1024

/*====================================
=            Enumerations            =
====================================*/

enum UserJumps
{
	LastJumpTimes[4],
}

enum FrameInfo
{
	playerButtons = 0,
	playerImpulse,
	Float:actualVelocity[3],
	Float:predictedVelocity[3],
	Float:predictedAngles[2],
	CSWeaponID:newWeapon,
	playerSubtype,
	playerSeed,
	additionalFields,
	pause,
}

enum AdditionalTeleport
{
	Float:atOrigin[3],
	Float:atAngles[3],
	Float:atVelocity[3],
	atFlags
}

enum FileHeader
{
	FH_binaryFormatVersion = 0,
	String:FH_Time[32],
	String:FH_Playername[32],
	FH_Checkpoints,
	FH_tickCount,
	Float:FH_initialPosition[3],
	Float:FH_initialAngles[3],
	Handle:FH_frames
}

enum MapZone
{
	zoneId,
	zoneType,
	zoneTypeId,
	Float:PointA[3],
	Float:PointB[3],
	Float:CenterPoint[3],
	String:zoneName[128],
	String:hookName[128],
	String:targetName[128],
	oneJumpLimit,
	Float:preSpeed,
	zoneGroup
}

enum SkillGroup
{
	PointsBot,
	PointsTop,
	PointReq,
	RankBot,
	RankTop,
	RankReq,
	String:RankName[128],
	String:RankNameColored[128],
	String:NameColour[32]
}

/*===================================
=            Plugin Info            =
===================================*/

public Plugin myinfo =
{
	name = "SurfTimer",
	author = "fluffys",
	description = "A fork of ckSurf",
	version = VERSION,
	url = "http://steamcommunity.com/profiles/76561198000303868/"
};

/*====================================
=              Includes              =
====================================*/

#include "surftimer/globals.sp"
#include "surftimer/convars.sp"
#include "surftimer/misc.sp"

#include "surftimer/db/queries.sp"
#include "surftimer/sql.sp"
#include "surftimer/sql2.sp"
#include "surftimer/db/map_loader.sp"
#include "surftimer/db/map_loader_steps.sp"
#include "surftimer/db/player_loader.sp"
#include "surftimer/db/player_loader_steps.sp"

#include "surftimer/admin.sp"
#include "surftimer/commands/commands.sp"
#include "surftimer/commands/mapsettings.sp"
#include "surftimer/commands/titles.sp"
#include "surftimer/hooks.sp"
#include "surftimer/buttonpress.sp"
#include "surftimer/sqltime.sp"
#include "surftimer/timer.sp"
#include "surftimer/replay.sp"
#include "surftimer/surfzones.sp"
#include "surftimer/cvote.sp"
#include "surftimer/func.sp"
#include "surftimer/natives.sp"

/*====================================
=               Events               =
====================================*/

public void OnLibraryAdded(const char[] name)
{
	Handle tmp = FindPluginByFile("mapchooser_extended.smx");
	if ((StrEqual("mapchooser", name)) || (tmp != null && GetPluginStatus(tmp) == Plugin_Running))
		g_bMapChooser = true;
	if (tmp != null)
		CloseHandle(tmp);

	// botmimic 2
	if (StrEqual(name, "dhooks") && g_hTeleport == null)
	{
		// Optionally setup a hook on CBaseEntity::Teleport to keep track of sudden place changes
		Handle hGameData = LoadGameConfigFile("sdktools.games");
		if (hGameData == null)
			return;
		int iOffset = GameConfGetOffset(hGameData, "Teleport");
		CloseHandle(hGameData);
		if (iOffset == -1)
			return;

		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if (g_hTeleport == null)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		if (GetEngineVersion() == Engine_CSGO)
			DHookAddParam(g_hTeleport, HookParamType_Bool);

		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
				OnClientPutInServer(i);
		}
	}
}

public void OnPluginEnd()
{
	// remove clan tags
	for (int x = 1; x <= MaxClients; x++)
	{
		if (IsValidClient(x)) {
		    if (IsValidEntity(x)) {
			    SetEntPropEnt(x, Prop_Send, "m_bSpotted", 1);
			    SetEntProp(x, Prop_Send, "m_iHideHUD", 0);
			    SetEntProp(x, Prop_Send, "m_iAccount", 1);
			}
			CS_SetClientClanTag(x, "");
			OnClientDisconnect(x);
		}
	}


	// set server convars back to default
	ServerCommand("sm_cvar sv_enablebunnyhopping 0;sv_friction 5.2;sv_accelerate 5.5;sv_airaccelerate 10;sv_maxvelocity 2000;sv_staminajumpcost .08;sv_staminalandcost .050");
	ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0;mp_respawnwavetime_ct 10.0;mp_respawnwavetime_t 10.0;bot_zombie 0;mp_ignore_round_win_conditions 0");
	ServerCommand("sv_infinite_ammo 0;mp_endmatch_votenextmap 1;mp_do_warmup_period 1;mp_warmuptime 60;mp_match_can_clinch 1;mp_match_end_changelevel 0");
	ServerCommand("mp_match_restart_delay 15;mp_endmatch_votenextleveltime 20;mp_endmatch_votenextmap 1;mp_halftime 0;mp_do_warmup_period 1;mp_maxrounds 0;bot_quota 0");
	ServerCommand("mp_startmoney 800; mp_playercashawards 1; mp_teamcashawards 1");
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))
		g_hAdminMenu = null;
	if (StrEqual(name, "dhooks"))
		g_hTeleport = null;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	// if (StrContains(classname, "trigger_", true) != -1 || StrContains(classname, "_door")!= -1)
	// {
	// 	SDKHook(entity, SDKHook_StartTouch, OnTouchAllTriggers);
	// 	SDKHook(entity, SDKHook_Touch, OnTouchAllTriggers);
	// 	SDKHook(entity, SDKHook_EndTouch, OnEndTouchAllTriggers);
	// }
}

public void OnMapStart()
{
	// Get mapname
	GetCurrentMap(g_szMapName, 128);

	// Create nav file
	CreateNavFile();

	// Workshop fix
	char mapPieces[6][128];
	int lastPiece = ExplodeString(g_szMapName, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[]));
	Format(g_szMapName, sizeof(g_szMapName), "%s", mapPieces[lastPiece - 1]);
	
	// Debug Logging
	if (!DirExists("addons/sourcemod/logs/surftimer"))
		CreateDirectory("addons/sourcemod/logs/surftimer", 511);

	BuildPath(Path_SM, g_szLogFile, sizeof(g_szLogFile), "logs/surftimer/%s.log", g_szMapName);

	// Get map maxvelocity
	g_hMaxVelocity = FindConVar("sv_maxvelocity");

	// Load spawns
	checkSpawnPoints();

    LoadMapStart();

	// Get Map Tag
	ExplodeString(g_szMapName, "_", g_szMapPrefix, 2, 32);

	// sv_pure 1 could lead to problems with the ckSurf models
	ServerCommand("sv_pure 0");

	// reload language files
	LoadTranslations("surftimer.phrases");
	LoadTranslations("common.phrases.txt");

	CheatFlag("bot_zombie", false, true);
	g_bTierFound = false;
	for (int i = 0; i < MAXZONEGROUPS; i++)
	{
		g_fBonusFastest[i] = 9999999.0;
		g_bCheckpointRecordFound[i] = false;
	}

	// Precache
	InitPrecache();
	SetCashState();

	// Timers
	CreateTimer(0.1, CKTimer1, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(1.0, CKTimer2, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(60.0, AttackTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(600.0, PlayerRanksTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
	CreateTimer(ZONE_REFRESH_TIME, BeamBoxAll, _, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

	// AutoBhop
	if (GetConVarBool(g_hAutoBhopConVar))
		g_bAutoBhop = true;
	else
		g_bAutoBhop = false;

	// main.cfg & replays
	CreateTimer(1.0, DelayedStuff, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(10.0, LoadReplaysTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);

	if (g_bLateLoaded)
		OnAutoConfigsBuffered();

	g_Advert = 0;
	CreateTimer(180.0, AdvertTimer, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);

	int iEnt;
	for (int i = 0; i < sizeof(EntityList); i++)
	{
		while ((iEnt = FindEntityByClassname(iEnt, EntityList[i])) != -1)
		{
			AcceptEntityInput(iEnt, "Disable");
			AcceptEntityInput(iEnt, "Kill");
		}
	}

	// PushFix by Mev, George, & Blacky
	// https://forums.alliedmods.net/showthread.php?t=267131
	iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "trigger_push")) != -1)
	{
		SDKHook(iEnt, SDKHook_Touch, OnTouchPushTrigger);
		SDKHook(iEnt, SDKHook_EndTouch, OnEndTouchPushTrigger);
	}

	// Trigger Gravity Fix
	iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "trigger_gravity")) != -1)
	{
		SDKHook(iEnt, SDKHook_EndTouch, OnEndTouchGravityTrigger);
	}

	// Hook Zones
	iEnt = -1;
	if (g_hTriggerMultiple != null)
		CloseHandle(g_hTriggerMultiple);

	g_hTriggerMultiple = CreateArray(256);
	while ((iEnt = FindEntityByClassname(iEnt, "trigger_multiple")) != -1)
	{
		PushArrayCell(g_hTriggerMultiple, iEnt);
	}

	g_mTriggerMultipleMenu = CreateMenu(HookZonesMenuHandler);
	SetMenuTitle(g_mTriggerMultipleMenu, "Select a trigger");

	for (int i = 0; i < GetArraySize(g_hTriggerMultiple); i++)
	{
		iEnt = GetArrayCell(g_hTriggerMultiple, i);

		if (IsValidEntity(iEnt))
		{
			char szTriggerName[128];
			GetEntPropString(iEnt, Prop_Send, "m_iName", szTriggerName, 128, 0);
			//PushArrayString(g_TriggerMultipleList, szTriggerName);
			AddMenuItem(g_mTriggerMultipleMenu, szTriggerName, szTriggerName);
		}
	}

	SetMenuOptionFlags(g_mTriggerMultipleMenu, MENUFLAG_BUTTON_EXIT);

	// info_teleport_destinations
	iEnt = -1;
	if (g_hDestinations != null)
		CloseHandle(g_hDestinations);
	
	g_hDestinations = CreateArray(128);
	while ((iEnt = FindEntityByClassname(iEnt, "info_teleport_destination")) != -1)
		PushArrayCell(g_hDestinations, iEnt);

	// Set default values
	g_fMapStartTime = GetGameTime();
	g_bRoundEnd = false;

	// Playtime
	CreateTimer(1.0, PlayTimeTimer, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	// if (FindPluginByFile("store.smx") != INVALID_HANDLE)
	// 	LogMessage("Store plugin has been found! Timer credits enabled.");
	// else 
	// 	LogMessage("Store not found! Timer credits have been disabled");
	
	// Server Announcements
	g_iServerID = GetConVarInt(g_hServerID);
	if (GetConVarBool(g_hRecordAnnounce))
		CreateTimer(45.0, AnnouncementTimer, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

	// Show Triggers
	g_iTriggerTransmitCount = 0;

	// Save Locs
	ResetSaveLocs();
}

public void OnMapEnd()
{
	// ServerCommand("sm_updater_force");
	g_bHasLatestID = false;
	for (int i = 0; i < MAXZONEGROUPS; i++)
		Format(g_sTierString[i], 512, "");

	g_RecordBot = -1;
	g_BonusBot = -1;
	g_WrcpBot = -1;
	db_Cleanup();

	if (g_hSkillGroups != null)
		CloseHandle(g_hSkillGroups);
	g_hSkillGroups = null;

	if (g_hBotTrail[0] != null)
		CloseHandle(g_hBotTrail[0]);
	g_hBotTrail[0] = null;

	if (g_hBotTrail[1] != null)
		CloseHandle(g_hBotTrail[1]);
	g_hBotTrail[1] = null;

	Format(g_szMapName, sizeof(g_szMapName), "");

	// wrcps
	for (int client = 1; client <= MAXPLAYERS; client++)
	{
		g_fWrcpMenuLastQuery[client] = 0.0;
		g_bWrcpTimeractivated[client] = false;
	}

	// Hook Zones
	if (g_hTriggerMultiple != null)
	{
		ClearArray(g_hTriggerMultiple);
		CloseHandle(g_hTriggerMultiple);
	}

	g_hTriggerMultiple = null;
	delete g_hTriggerMultiple;

	CloseHandle(g_mTriggerMultipleMenu);

	// if (g_hStore != null)
	// 	CloseHandle(g_hStore);

	if (g_hDestinations != null)
		CloseHandle(g_hDestinations);

	g_hDestinations = null;
}

public void OnConfigsExecuted()
{
	// Get Chat Prefix
	GetConVarString(g_hChatPrefix, g_szChatPrefix, sizeof(g_szChatPrefix));
	GetConVarString(g_hChatPrefix, g_szMenuPrefix, sizeof(g_szMenuPrefix));
	CRemoveColors(g_szMenuPrefix, sizeof(g_szMenuPrefix));

	// Count the amount of bonuses and then set skillgroups
	SetSkillGroups();

	ServerCommand("sv_pure 0");

	if (GetConVarBool(g_hAllowRoundEndCvar))
		ServerCommand("mp_ignore_round_win_conditions 0");
	else
		ServerCommand("mp_ignore_round_win_conditions 1;mp_maxrounds 1");

	if (GetConVarBool(g_hAutoRespawn))
		ServerCommand("mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0");
	else
		ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0");

	ServerCommand("mp_endmatch_votenextmap 0;mp_do_warmup_period 0;mp_warmuptime 0;mp_match_can_clinch 0;mp_match_end_changelevel 1;mp_match_restart_delay 10;mp_endmatch_votenextleveltime 10;mp_endmatch_votenextmap 0;mp_halftime 0;bot_zombie 1;mp_do_warmup_period 0;mp_maxrounds 1");

	if (GetConVarInt(g_hServerType) == 1)
	{
		// Bhop
		ServerCommand("sv_infinite_ammo 1");
	}
	else
	{
		// Surf
		ServerCommand("sv_infinite_ammo 2");
		ServerCommand("sv_autobunnyhopping 1");
	}
}

public void OnAutoConfigsBuffered()
{
	// just to be sure that it's not empty
	char szMap[128];
	char szPrefix[2][32];
	GetCurrentMap(szMap, 128);
	char mapPieces[6][128];
	int lastPiece = ExplodeString(szMap, "/", mapPieces, sizeof(mapPieces), sizeof(mapPieces[]));
	Format(szMap, sizeof(szMap), "%s", mapPieces[lastPiece - 1]);
	ExplodeString(szMap, "_", szPrefix, 2, 32);

	// map config
	char szPath[256];
	Format(szPath, sizeof(szPath), "sourcemod/surftimer/map_types/%s_.cfg", szPrefix[0]);
	char szPath2[256];
	Format(szPath2, sizeof(szPath2), "cfg/%s", szPath);
	if (FileExists(szPath2))
		ServerCommand("exec %s", szPath);
	else
		SetFailState("<Surftimer> %s not found.", szPath2);
}

public void OnClientPutInServer(int client) {
	if (!IsValidClient(client)) {
	    return;
	}

	// Defaults
	SetClientDefaults(client);
	//Command_Restart(client, 1);

    // Sometimes, player buttons get stuck because of our csgo panorama "retry" before map change fix
    // Reset all buttons to unpressed on next tick
	g_resetButtons[client] = true;

	// SDKHooks
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKHook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKHook(client, SDKHook_PreThink, OnPlayerThink);
	SDKHook(client, SDKHook_PreThinkPost, OnPlayerThink);
	SDKHook(client, SDKHook_Think, OnPlayerThink);
	SDKHook(client, SDKHook_PostThink, OnPlayerThink);
	SDKHook(client, SDKHook_PostThinkPost, OnPlayerThink);

	// Footsteps
	if (!IsFakeClient(client))
		SendConVarValue(client, g_hFootsteps, "0");

	g_bReportSuccess[client] = false;
	g_fCommandLastUsed[client] = 0.0;

	// fluffys set bools
	g_bToggleMapFinish[client] = true;
	g_bRepeat[client] = false;
	g_bNotTeleporting[client] = false;

	if (IsFakeClient(client))
	{
		g_hRecordingAdditionalTeleport[client] = CreateArray(view_as<int>(AdditionalTeleport));
		CS_SetMVPCount(client, 1);
		return;
	}
	else
		g_MVPStars[client] = 0;

	// Client Country
	GetCountry(client);

	if (LibraryExists("dhooks"))
		DHookEntity(g_hTeleport, false, client);

	// Get SteamID
	g_szSteamID[client] = "";
	if (!GetClientAuthId(client, AuthId_Steam2, g_szSteamID[client], MAX_NAME_LENGTH, true)) {
	    g_szSteamID[client] = "";
	}

	// char fix
	FixPlayerName(client);

	// Position Restoring
	if (GetConVarBool(g_hcvarRestore))
	    db_selectLastRun(client);

	if (g_bTierFound)
		AnnounceTimer[client] = CreateTimer(20.0, AnnounceMap, client, TIMER_FLAG_NO_MAPCHANGE);

	if (!IsFakeClient(client)) {
	    LoadPlayerStart(client);
	}
}

public void OnClientAuthorized(int client)
{
	if (GetConVarBool(g_hConnectMsg) && !IsFakeClient(client))
	{
		char s_Country[32], s_clientName[32], s_address[32];
		GetClientIP(client, s_address, 32);
		GetClientName(client, s_clientName, 32);
		Format(s_Country, 100, "Unknown");
		GeoipCountry(s_address, s_Country, 100);
		if (!strcmp(s_Country, NULL_STRING))
			Format(s_Country, 100, "Unknown", s_Country);
		else
			if (StrContains(s_Country, "United", false) != -1 ||
			StrContains(s_Country, "Republic", false) != -1 ||
			StrContains(s_Country, "Federation", false) != -1 ||
			StrContains(s_Country, "Island", false) != -1 ||
			StrContains(s_Country, "Netherlands", false) != -1 ||
			StrContains(s_Country, "Isle", false) != -1 ||
			StrContains(s_Country, "Bahamas", false) != -1 ||
			StrContains(s_Country, "Maldives", false) != -1 ||
			StrContains(s_Country, "Philippines", false) != -1 ||
			StrContains(s_Country, "Vatican", false) != -1)
		{
			Format(s_Country, 100, "The %s", s_Country);
		}

		if (StrEqual(s_Country, "Unknown", false) || StrEqual(s_Country, "Localhost", false))
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && i != client)
				{
					CPrintToChat(i, "%t", "Connected1", s_clientName);
				}
			}
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && i != client)
				{
					CPrintToChat(i, "%t", "Connected2", s_clientName, s_Country);
				}
			}
		}
	}
}

public void OnClientDisconnect(int client)
{
	if (g_hRecordingAdditionalTeleport[client] != null)
	{
		CloseHandle(g_hRecordingAdditionalTeleport[client]);
		g_hRecordingAdditionalTeleport[client] = null;
	}

	LoadPlayerStop(client);

	StopRecording(client);
	StopPlayerMimic(client);

	db_savePlayTime(client);

	g_fPlayerLastTime[client] = -1.0;
	if (g_fStartTime[client] != -1.0 && g_bTimerRunning[client])
	{
		if (g_bPause[client])
		{
			g_fPauseTime[client] = GetGameTime() - g_fStartPauseTime[client];
			g_fPlayerLastTime[client] = GetGameTime() - g_fStartTime[client] - g_fPauseTime[client];
		}
		else
			g_fPlayerLastTime[client] = g_fCurrentRunTime[client];
	}

	SDKUnhook(client, SDKHook_SetTransmit, Hook_SetTransmit);
	SDKUnhook(client, SDKHook_PostThinkPost, Hook_PostThinkPost);
	SDKUnhook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
	SDKUnhook(client, SDKHook_PreThink, OnPlayerThink);
	SDKUnhook(client, SDKHook_PreThinkPost, OnPlayerThink);
	SDKUnhook(client, SDKHook_Think, OnPlayerThink);
	SDKUnhook(client, SDKHook_PostThink, OnPlayerThink);
	SDKUnhook(client, SDKHook_PostThinkPost, OnPlayerThink);

	if (client == g_RecordBot) g_RecordBot = -1;
	if (client == g_BonusBot) g_BonusBot = -1;
	if (client == g_WrcpBot) g_WrcpBot = -1;

	// Database
	if (IsValidClient(client)) {
		if (!g_bIgnoreZone[client] && !g_bPracticeMode[client])
			db_insertLastPosition(client, g_szMapName, g_Stage[g_iClientInZone[client][2]][client], g_iClientInZone[client][2]);

		db_updatePlayerOptions(client);
	}

	// Stop Showing Triggers
	if (g_bShowTriggers[client])
	{
		g_bShowTriggers[client] = false;
		--g_iTriggerTransmitCount;
		TransmitTriggers(g_iTriggerTransmitCount > 0);
	}
}

public void OnSettingChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (convar == g_hChatPrefix)
	{
		GetConVarString(g_hChatPrefix, g_szChatPrefix, sizeof(g_szChatPrefix));
		GetConVarString(g_hChatPrefix, g_szMenuPrefix, sizeof(g_szMenuPrefix));
		CRemoveColors(g_szMenuPrefix, sizeof(g_szMenuPrefix));
	}
	if (convar == g_hReplayBot)
	{
		if (GetConVarBool(g_hReplayBot))
			LoadReplays();
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (i == g_RecordBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
					}
					else
					{
						if (!GetConVarBool(g_hBonusBot) && !GetConVarBool(g_hWrcpBot)) // if both bots are off, no need to record
							if (g_hRecording[i] != null)
								StopRecording(i);
					}
				}
			}
			if (GetConVarBool(g_hInfoBot) && GetConVarBool(g_hBonusBot))
				ServerCommand("bot_quota 2");
			else
				if (GetConVarBool(g_hInfoBot) || GetConVarBool(g_hBonusBot))
					ServerCommand("bot_quota 1");
				else
					ServerCommand("bot_quota 0");

			if (g_hBotTrail[0] != null)
				CloseHandle(g_hBotTrail[0]);
			g_hBotTrail[0] = null;
		}
	}
	else if (convar == g_hBonusBot)
	{
		if (GetConVarBool(g_hBonusBot))
			LoadReplays();
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (i == g_BonusBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
					}
					else
					{
						if (!GetConVarBool(g_hReplayBot) && !GetConVarBool(g_hWrcpBot)) // if both bots are off
							if (g_hRecording[i] != null)
								StopRecording(i);
					}
				}
			}
			if (GetConVarBool(g_hInfoBot) && GetConVarBool(g_hReplayBot))
				ServerCommand("bot_quota 2");
			else
				if (GetConVarBool(g_hInfoBot) || GetConVarBool(g_hReplayBot))
					ServerCommand("bot_quota 1");
				else
					ServerCommand("bot_quota 0");

			if (g_hBotTrail[1] != null)
				CloseHandle(g_hBotTrail[1]);
			g_hBotTrail[1] = null;
		}
	}
	else if (convar == g_hWrcpBot)
	{
		if (GetConVarBool(g_hWrcpBot))
		{
			LoadReplays();
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i))
				{
					if (i == g_WrcpBot)
					{
						StopPlayerMimic(i);
						KickClient(i);
					}
					else
					{
						if (!GetConVarBool(g_hReplayBot) && !GetConVarBool(g_hBonusBot)) // if both bots are off
							if (g_hRecording[i] != null)
								StopRecording(i);
					}
				}
			}
		}
	}
	else if (convar == g_hAutoRespawn)
	{
		if (GetConVarBool(g_hAutoRespawn))
		{
			ServerCommand("mp_respawn_on_death_ct 1;mp_respawn_on_death_t 1;mp_respawnwavetime_ct 3.0;mp_respawnwavetime_t 3.0");
		}
		else
		{
			ServerCommand("mp_respawn_on_death_ct 0;mp_respawn_on_death_t 0");
		}
	}
	else if (convar == g_hPlayerSkinChange)
	{
		if (GetConVarBool(g_hPlayerSkinChange))
		{
			char szBuffer[256];
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i))
				{
					if (i == g_RecordBot || i == g_BonusBot || i == g_WrcpBot)
					{
						// Player Model
						GetConVarString(g_hReplayBotPlayerModel, szBuffer, 256);
						SetEntityModel(i, szBuffer);
						// Arm Model
						GetConVarString(g_hReplayBotArmModel, szBuffer, 256);
						SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
						SetEntityModel(i, szBuffer);
					}
					else
					{
						GetConVarString(g_hArmModel, szBuffer, 256);
						SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);

						GetConVarString(g_hPlayerModel, szBuffer, 256);
						SetEntityModel(i, szBuffer);
					}
				}
		}
	}
	else if (convar == g_hCvarNoBlock)
	{
		if (GetConVarBool(g_hCvarNoBlock))
		{
			for (int client = 1; client <= MAXPLAYERS; client++)
				if (IsValidEntity(client))
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 2, 4, true);

		}
		else
		{
			for (int client = 1; client <= MAXPLAYERS; client++)
				if (IsValidEntity(client))
					SetEntData(client, FindSendPropInfo("CBaseEntity", "m_CollisionGroup"), 5, 4, true);
		}
	}
	else if (convar == g_hCleanWeapons)
	{
		if (GetConVarBool(g_hCleanWeapons))
		{
			char szclass[32];
			for (int i = 1; i <= MaxClients; i++)
			{
				if (IsValidClient(i) && IsPlayerAlive(i))
				{
					for (int j = 0; j < 4; j++)
					{
						int weapon = GetPlayerWeaponSlot(i, j);
						if (weapon != -1 && j != 2)
						{
							GetEdictClassname(weapon, szclass, sizeof(szclass));
							RemovePlayerItem(i, weapon);
							RemoveEdict(weapon);
							int equipweapon = GetPlayerWeaponSlot(i, 2);
							if (equipweapon != -1)
								EquipPlayerWeapon(i, equipweapon);
						}
					}
				}
			}
		}
	}
	else if (convar == g_hAutoBhopConVar)
	{
		g_bAutoBhop = view_as<bool>(StringToInt(newValue[0]));
	}
	else if (convar == g_hInfoBot)
	{
		if (GetConVarBool(g_hInfoBot))
		{
			LoadInfoBot();
		}
		else
		{
			for (int i = 1; i <= MaxClients; i++)
				if (IsValidClient(i) && IsFakeClient(i))
				{
					if (i == g_InfoBot)
					{
						int count = 0;
						g_InfoBot = -1;
						KickClient(i);
						char szBuffer[64];
						if (g_bMapReplay[0])
							count++;
						if (g_BonusBotCount > 0)
							count++;
						Format(szBuffer, sizeof(szBuffer), "bot_quota %i", count);
						ServerCommand(szBuffer);
					}
				}
		}
	}
	else if (convar == g_hReplayBotPlayerModel)
	{
		char szBuffer[256];
		GetConVarString(g_hReplayBotPlayerModel, szBuffer, 256);
		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (IsValidClient(g_RecordBot))
			SetEntityModel(g_RecordBot, szBuffer);
		if (IsValidClient(g_BonusBot))
			SetEntityModel(g_BonusBot, szBuffer);
		if (IsValidClient(g_WrcpBot))
			SetEntityModel(g_WrcpBot, szBuffer);
	}
	else if (convar == g_hReplayBotArmModel)
	{
		char szBuffer[256];
		GetConVarString(g_hReplayBotArmModel, szBuffer, 256);
		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (IsValidClient(g_RecordBot))
			SetEntPropString(g_RecordBot, Prop_Send, "m_szArmsModel", szBuffer);
		if (IsValidClient(g_BonusBot))
			SetEntPropString(g_RecordBot, Prop_Send, "m_szArmsModel", szBuffer);
		if (IsValidClient(g_WrcpBot))
			SetEntPropString(g_WrcpBot, Prop_Send, "m_szArmsModel", szBuffer);

	}
	else if (convar == g_hPlayerModel)
	{
		char szBuffer[256];
		GetConVarString(g_hPlayerModel, szBuffer, 256);

		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (!GetConVarBool(g_hPlayerSkinChange))
			return;
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_RecordBot)
				SetEntityModel(i, szBuffer);
			else if (IsValidClient(i) && i != g_BonusBot)
				SetEntityModel(i, szBuffer);
			else if (IsValidClient(i) && i != g_WrcpBot)
				SetEntityModel(i, szBuffer);
	}
	else if (convar == g_hArmModel)
	{
		char szBuffer[256];
		GetConVarString(g_hArmModel, szBuffer, 256);

		PrecacheModel(szBuffer, true);
		AddFileToDownloadsTable(szBuffer);
		if (!GetConVarBool(g_hPlayerSkinChange))
			return;
		for (int i = 1; i <= MaxClients; i++)
			if (IsValidClient(i) && i != g_RecordBot)
				SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
			else if (IsValidClient(i) && i != g_BonusBot)
				SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
			else if (IsValidClient(i) && i != g_WrcpBot)
				SetEntPropString(i, Prop_Send, "m_szArmsModel", szBuffer);
	}
	else if (convar == g_hReplayBotColor)
	{
		char color[256];
		Format(color, 256, "%s", newValue[0]);
		GetRGBColor(0, color);
	}
	else if (convar == g_hBonusBotColor)
	{
		char color[256];
		Format(color, 256, "%s", newValue[0]);
		GetRGBColor(1, color);
	}
	else if (convar == g_hzoneStartColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[1]);
	}
	else if (convar == g_hzoneEndColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[2]);
	}
	else if (convar == g_hzoneCheckerColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[10]);
	}
	else if (convar == g_hzoneBonusStartColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[3]);
	}
	else if (convar == g_hzoneBonusEndColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[4]);
	}
	else if (convar == g_hzoneStageColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[5]);
	}
	else if (convar == g_hzoneCheckpointColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[6]);
	}
	else if (convar == g_hzoneSpeedColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[7]);
	}
	else if (convar == g_hzoneTeleToStartColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[8]);
	}
	else if (convar == g_hzoneValidatorColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[9]);
	}
	else if (convar == g_hzoneStopColor)
	{
		char color[24];
		Format(color, 28, "%s", newValue[0]);
		StringRGBtoInt(color, g_iZoneColors[0]);
	}
	else if (convar == g_hZonerFlag) 
	{
		AdminFlag flag;
		bool validFlag;
		validFlag = FindFlagByChar(newValue[0], flag);

		if (!validFlag)
		{
			PrintToServer("SurfTimer | Invalid flag for ck_zoner_flag");
			g_ZonerFlag = ADMFLAG_ROOT;
		}
		else
			g_ZonerFlag = FlagToBit(flag);
	}
	else if (convar == g_hAdminMenuFlag) 
	{
		AdminFlag flag;
		bool validFlag;
		validFlag = FindFlagByChar(newValue[0], flag);

		if (!validFlag)
		{
			PrintToServer("SurfTimer | Invalid flag for ck_adminmenu_flag");
			g_AdminMenuFlag = ADMFLAG_ROOT;
		}
		else
			g_AdminMenuFlag = FlagToBit(flag);
	}
	else if (convar == g_hServerType)
	{
		if (GetConVarInt(g_hServerType) == 1) // Bhop
			ServerCommand("sv_infinite_ammo 1");
		else
			ServerCommand("sv_infinite_ammo 2"); // Surf
	}
	else if (convar == g_hServerID)
		g_iServerID = GetConVarInt(g_hServerID);
	else if (convar == g_hHostName)
	{
		GetConVarString(g_hHostName, g_sServerName, sizeof(g_sServerName));
	}
	else if (convar == g_hSoundPathWR)
	{
		GetConVarString(g_hSoundPathWR, g_szSoundPathWR, sizeof(g_szSoundPathWR));
        char sBuffer[2][PLATFORM_MAX_PATH];
        ExplodeString(g_szSoundPathWR, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
        Format(g_szRelativeSoundPathWR, sizeof(g_szRelativeSoundPathWR), "*%s", sBuffer[1]);
	}
	else if (convar == g_hSoundPathTop)
	{
		GetConVarString(g_hSoundPathTop, g_szSoundPathTop, sizeof(g_szSoundPathTop));
        char sBuffer[2][PLATFORM_MAX_PATH];
        ExplodeString(g_szSoundPathTop, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
        Format(g_szRelativeSoundPathTop, sizeof(g_szRelativeSoundPathTop), "*%s", sBuffer[1]);
	}
	else if (convar == g_hSoundPathPB)
	{
		GetConVarString(g_hSoundPathPB, g_szSoundPathPB, sizeof(g_szSoundPathPB));
        char sBuffer[2][PLATFORM_MAX_PATH];
        ExplodeString(g_szSoundPathPB, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
        Format(g_szRelativeSoundPathPB, sizeof(g_szRelativeSoundPathPB), "*%s", sBuffer[1]);
	}
	else if (convar == g_hSoundPathWRCP)
	{
		GetConVarString(g_hSoundPathWRCP, g_szSoundPathWRCP, sizeof(g_szSoundPathWRCP));
        char sBuffer[2][PLATFORM_MAX_PATH];
        ExplodeString(g_szSoundPathWRCP, "sound/", sBuffer, 2, PLATFORM_MAX_PATH);
        Format(g_szRelativeSoundPathWRCP, sizeof(g_szRelativeSoundPathWRCP), "*%s", sBuffer[1]);
	}
}

public void OnPluginStart()
{
	// Language File
	LoadTranslations("surftimer.phrases");

	CreateConVars();
	CreateCommands();
	CreateHooks();
	CreateCommandListeners();

	db_setupDatabase();

	// exec surftimer.cfg
	AutoExecConfig(true, "surftimer");

	// mic
	g_ownerOffset = FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
	g_ragdolls = FindSendPropInfo("CCSPlayer", "m_hRagdoll");

	// add to admin menu
	Handle tpMenu;
	if (LibraryExists("adminmenu") && ((tpMenu = GetAdminTopMenu()) != null))
		OnAdminMenuReady(tpMenu);

	// button sound hook
	// AddNormalSoundHook(NormalSHook_callback);

	// Botmimic 2
	// https://forums.alliedmods.net/showthread.php?t=180114
	// Optionally setup a hook on CBaseEntity::Teleport to keep track of sudden place changes
	CheatFlag("bot_zombie", false, true);
	CheatFlag("bot_mimic", false, true);
	g_hLoadedRecordsAdditionalTeleport = CreateTrie();
	Handle hGameData = LoadGameConfigFile("sdktools.games");
	if (hGameData == null)
	{
		SetFailState("GameConfigFile sdkhooks.games was not found.");
		return;
	}
	int iOffset = GameConfGetOffset(hGameData, "Teleport");
	CloseHandle(hGameData);
	if (iOffset == -1)
		return;

	if (LibraryExists("dhooks"))
	{
		g_hTeleport = DHookCreate(iOffset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, DHooks_OnTeleport);
		if (g_hTeleport == null)
			return;
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_ObjectPtr);
		DHookAddParam(g_hTeleport, HookParamType_VectorPtr);
		DHookAddParam(g_hTeleport, HookParamType_Bool);
	}

	// Forwards
	g_MapFinishForward = CreateGlobalForward("surftimer_OnMapFinished", ET_Event, Param_Cell, Param_Float, Param_String, Param_Cell, Param_Cell);
	g_MapCheckpointForward = CreateGlobalForward("surftimer_OnCheckpoint", ET_Event, Param_Cell, Param_Float, Param_String, Param_Float, Param_String, Param_Float, Param_String);
	g_BonusFinishForward = CreateGlobalForward("surftimer_OnBonusFinished", ET_Event, Param_Cell, Param_Float, Param_String, Param_Cell, Param_Cell, Param_Cell);
	g_PracticeFinishForward = CreateGlobalForward("surftimer_OnPracticeFinished", ET_Event, Param_Cell, Param_Float, Param_String);

	if (g_bLateLoaded)
	{
		CreateTimer(3.0, LoadPlayerSettings, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	}

	Format(szWHITE, 12, "%c", WHITE);
	Format(szDARKRED, 12, "%c", DARKRED);
	Format(szPURPLE, 12, "%c", PURPLE);
	Format(szGREEN, 12, "%c", GREEN);
	Format(szLIGHTGREEN, 12, "%c", LIGHTGREEN);
	Format(szLIMEGREEN, 12, "%c", LIMEGREEN);
	Format(szRED, 12, "%c", RED);
	Format(szGRAY, 12, "%c", GRAY);
	Format(szYELLOW, 12, "%c", YELLOW);
	Format(szDARKGREY, 12, "%c", DARKGREY);
	Format(szBLUE, 12, "%c", BLUE);
	Format(szDARKBLUE, 12, "%c", DARKBLUE);
	Format(szLIGHTBLUE, 12, "%c", LIGHTBLUE);
	Format(szPINK, 12, "%c", PINK);
	Format(szLIGHTRED, 12, "%c", LIGHTRED);
	Format(szORANGE, 12, "%c", ORANGE);

	// Server Announcements
	g_bHasLatestID = false;
	g_iLastID = 0;

	// https://forums.alliedmods.net/showthread.php?t=300549
	// HookUserMessage(GetUserMessageId("VGUIMenu"), TeamMenuHook, true);
}

public void OnAllPluginsLoaded()
{
	// Check if store is running
	// g_hStore = FindPluginByFile("store.smx");
}

/*======  End of Events  ======*/

public Action ItemFoundMsg(UserMsg msg_id, Handle pb, const players[], any playersNum, any reliable, any init)
{
	return Plugin_Handled;
}
