#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <zombiereloaded>

#define PLUGIN_VERSION	"1.6.2"

KeyValues kv;
ConVar hPlayerClasses;
char sClassPath[PLATFORM_MAX_PATH] = "configs/zr/playerclasses.txt";
bool g_RoundEnd = false;

public Plugin myinfo = 
{
	name = "[ZR] Tools",
	author = "FrozDark",
	description = "Useful tools for Zombie:Reloaded",
	version = PLUGIN_VERSION,
	url = "www.hlmod.ru"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("ZRT_GetClientClassSectionName", Native_GetClientClassSectionName);
	CreateNative("ZRT_GetClientAttributeString", Native_GetClientAttributeString);
	CreateNative("ZRT_GetClientAttributeValue", Native_GetClientAttributeValue);
	CreateNative("ZRT_GetClientAttributeValueFloat", Native_GetClientAttributeValueFloat);
	CreateNative("ZRT_PlayerHasAttribute", Native_PlayerHasAttribute);
	CreateNative("ZRT_IsRoundActive", Native_IsRoundActive);
	
	RegPluginLibrary("zr_tools");
	
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("zr_tools_version", PLUGIN_VERSION, "Zombie:Reloaded tools plugin version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_CHEAT|FCVAR_DONTRECORD);
	
	RegAdminCmd("zr_tools_reload", Command_Reload, ADMFLAG_ROOT);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
}

public void OnAllPluginsLoaded()
{
	if (hPlayerClasses != null)
	{
		hPlayerClasses.RemoveChangeHook(OnClassPathChange);
		delete hPlayerClasses;
	}
	if ((hPlayerClasses = FindConVar("zr_config_path_playerclasses")) == null)
	{
		SetFailState("Zombie:Reloaded is not running on this server");
	}
	hPlayerClasses.AddChangeHook(OnClassPathChange);
}

public void OnClassPathChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	strcopy(sClassPath, sizeof(sClassPath), newValue);
	OnConfigsExecuted();
}

public void OnConfigsExecuted()
{
	if (kv != null)
	{
		delete kv;
	}
	kv = new KeyValues("classes");
	
	char buffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, buffer, sizeof(buffer), "%s", sClassPath);
	
	if (!kv.ImportFromFile(buffer))
	{
		SetFailState("Class data file \"%s\" not found", buffer);
	}
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundEnd = false;
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundEnd = true;
}

public Action Command_Reload(int client, int args)
{
	OnConfigsExecuted();
	return Plugin_Handled;
}

public any Native_IsRoundActive(Handle plugin, int numParams)
{
	return !g_RoundEnd;
}

public any Native_PlayerHasAttribute(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ValidateClient(client);
	
	char attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	char className[64], buffer[64];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	bool result = false;
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				kv.GetString(attrib, buffer, sizeof(buffer), "0");
				
				result = (StrContains("yes|1|true", buffer, false) != -1);
				break;
			}
		} while (kv.GotoNextKey());
	}
	kv.Rewind();
	
	return result;
}

public int Native_GetClientAttributeString(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ValidateClient(client);
	
	char attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	char className[64], buffer[PLATFORM_MAX_PATH];
	buffer[0] = '\0';
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	int bytes;
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				kv.GetString(attrib, buffer, sizeof(buffer), "");
				
				SetNativeString(3, buffer, GetNativeCell(4), true, bytes);
				break;
			}
		} while (kv.GotoNextKey());
	}
	kv.Rewind();
	
	if (!buffer[0])
	{
		GetNativeString(5, buffer, sizeof(buffer));
		SetNativeString(3, buffer, GetNativeCell(4), true, bytes);
	}
	return bytes;
}

public int Native_GetClientAttributeValue(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ValidateClient(client);
	
	char attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	char className[64], buffer[PLATFORM_MAX_PATH];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	int result = -1;
	
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				result = kv.GetNum(attrib, GetNativeCell(3));
				break;
			}
		} while (kv.GotoNextKey());
	}
	kv.Rewind();
	
	return result;
}

public any Native_GetClientAttributeValueFloat(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ValidateClient(client);
	
	char attrib[32];
	GetNativeString(2, attrib, sizeof(attrib));
	
	char className[64], buffer[PLATFORM_MAX_PATH];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	float result = -1.0;
	
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				result = kv.GetFloat(attrib, view_as<float>(GetNativeCell(3)));
				break;
			}
		} while (kv.GotoNextKey());
	}
	kv.Rewind();
	
	return result;
}

public int Native_GetClientClassSectionName(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	ValidateClient(client);
	
	char className[64], buffer[64];
	ZR_GetClassDisplayName(client, className, sizeof(className), ZR_CLASS_CACHE_PLAYER);
	
	int bytes;
	if (kv.GotoFirstSubKey())
	{
		do
		{
			kv.GetString("name", buffer, sizeof(buffer));
			if (StrEqual(buffer, className, false))
			{
				kv.GetSectionName(buffer, sizeof(buffer));
				
				SetNativeString(2, buffer, GetNativeCell(3), true, bytes);
				break;
			}
		} while (kv.GotoNextKey());
	}
	kv.Rewind();
	
	return bytes;
}

void ValidateClient(int client)
{
	if (client < 1 || client > MaxClients)
	{
		ThrowNativeError(SP_ERROR_INDEX, "Client index %i is invalid", client);
		return;
	}
	else if (!IsClientInGame(client))
	{
		ThrowNativeError(SP_ERROR_NOT_FOUND, "Client %i is not in game", client);
		return;
	}
}