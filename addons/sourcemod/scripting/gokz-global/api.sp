static GlobalForward H_OnNewTopTime;
static GlobalForward H_OnPointsUpdated;



// =====[ FORWARDS ]=====

void CreateGlobalForwards()
{
	H_OnNewTopTime = new GlobalForward("GOKZ_GL_OnNewTopTime", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Float);
	H_OnPointsUpdated = new GlobalForward("GOKZ_GL_OnPointsUpdated", ET_Ignore, Param_Cell, Param_Cell);
}

void Call_OnNewTopTime(int client, int course, int mode, int timeType, int rank, int rankOverall, float time)
{
	Call_StartForward(H_OnNewTopTime);
	Call_PushCell(client);
	Call_PushCell(course);
	Call_PushCell(mode);
	Call_PushCell(timeType);
	Call_PushCell(rank);
	Call_PushCell(rankOverall);
	Call_PushFloat(time);
	Call_Finish();
}

void Call_OnPointsUpdated(int client, int mode)
{
	Call_StartForward(H_OnPointsUpdated);
	Call_PushCell(client);
	Call_PushCell(mode);
	Call_Finish();
}



// =====[ NATIVES ]=====

void CreateNatives()
{
	CreateNative("GOKZ_GL_PrintRecords", Native_PrintRecords);
	CreateNative("GOKZ_GL_DisplayMapTopMenu", Native_DisplayMapTopMenu);
	CreateNative("GOKZ_GL_GetPoints", Native_GetPoints);
	CreateNative("GOKZ_GL_GetMapPoints", Native_GetMapPoints);
	CreateNative("GOKZ_GL_GetRankPoints", Native_GetRankPoints);
	CreateNative("GOKZ_GL_GetFinishes", Native_GetFinishes);
	CreateNative("GOKZ_GL_UpdatePoints", Native_UpdatePoints);
}

public int Native_PrintRecords(Handle plugin, int numParams)
{
	char map[33], steamid[32];
	GetNativeString(2, map, sizeof(map));
	GetNativeString(5, steamid, sizeof(steamid));
	
	if (StrEqual(map, ""))
	{
		PrintRecords(GetNativeCell(1), gC_CurrentMap, GetNativeCell(3), GetNativeCell(4), steamid);
	}
	else
	{
		PrintRecords(GetNativeCell(1), map, GetNativeCell(3), GetNativeCell(4), steamid);
	}
}

public int Native_DisplayMapTopMenu(Handle plugin, int numParams)
{
	char pluginName[32];
	GetPluginFilename(plugin, pluginName, sizeof(pluginName));
	bool localRanksCall = StrEqual(pluginName, "gokz-localranks.smx", false);
	
	char map[33];
	GetNativeString(2, map, sizeof(map));
	
	if (StrEqual(map, ""))
	{
		DisplayMapTopSubmenu(GetNativeCell(1), gC_CurrentMap, GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), localRanksCall);
	}
	else
	{
		DisplayMapTopSubmenu(GetNativeCell(1), map, GetNativeCell(3), GetNativeCell(4), GetNativeCell(5), localRanksCall);
	}
}

public int Native_GetPoints(Handle plugin, int numParams)
{
	return GetPoints(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public int Native_GetMapPoints(Handle plugin, int numParams)
{
	return GetMapPoints(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public int Native_GetRankPoints(Handle plugin, int numParams)
{
	return GetRankPoints(GetNativeCell(1), GetNativeCell(2));
}

public int Native_GetFinishes(Handle plugin, int numParams)
{
	return GetFinishes(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

public int Native_UpdatePoints(Handle plugin, int numParams)
{
	UpdatePoints(GetNativeCell(1), GetNativeCell(2));
}
