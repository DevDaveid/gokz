static bool timerRunning[MAXPLAYERS + 1];
static float currentTime[MAXPLAYERS + 1];
static int currentCourse[MAXPLAYERS + 1];
static bool hasStartedTimerThisMap[MAXPLAYERS + 1];
static bool hasEndedTimerThisMap[MAXPLAYERS + 1];
static float lastTimerEndTime[MAXPLAYERS + 1];
static float lastStartSoundTime[MAXPLAYERS + 1];
static float lastFalseEndSoundTime[MAXPLAYERS + 1];



// =====[ PUBLIC ]=====

bool GetTimerRunning(int client)
{
	return timerRunning[client];
}

float GetCurrentTime(int client)
{
	return currentTime[client];
}

float SetCurrentTime(int client, float time)
{
	currentTime[client] = time;
}

int GetCurrentCourse(int client)
{
	return currentCourse[client];
}

bool GetHasStartedTimerThisMap(int client)
{
	return hasStartedTimerThisMap[client];
}

bool GetHasEndedTimerThisMap(int client)
{
	return hasEndedTimerThisMap[client];
}

int GetCurrentTimeType(int client)
{
	if (GetTeleportCount(client) == 0)
	{
		return TimeType_Pro;
	}
	return TimeType_Nub;
}

bool TimerStart(int client, int course, bool allowMidair = false)
{
	if (!IsPlayerAlive(client)
		 || (!Movement_GetOnGround(client) || JustLanded(client)) && !allowMidair
		 || !IsPlayerValidMoveType(client)
		 || JustStartedTimer(client))
	{
		return false;
	}
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTimerStart(client, course, result);
	if (result != Plugin_Continue)
	{
		return false;
	}
	
	// Start Timer
	currentTime[client] = 0.0;
	timerRunning[client] = true;
	currentCourse[client] = course;
	hasStartedTimerThisMap[client] = true;
	PlayTimerStartSound(client);
	
	// Call Post Forward
	Call_GOKZ_OnTimerStart_Post(client, course);
	
	return true;
}

bool TimerEnd(int client, int course)
{
	if (!IsPlayerAlive(client))
	{
		return false;
	}
	
	if (!timerRunning[client] || course != currentCourse[client])
	{
		PlayTimerFalseEndSound(client);
		return false;
	}
	
	float time = GetCurrentTime(client);
	int teleportsUsed = GetTeleportCount(client);
	
	// Call Pre Forward
	Action result;
	Call_GOKZ_OnTimerEnd(client, course, time, teleportsUsed, result);
	if (result != Plugin_Continue)
	{
		return false;
	}
	
	// End Timer
	timerRunning[client] = false;
	hasEndedTimerThisMap[client] = true;
	lastTimerEndTime[client] = GetGameTime();
	PlayTimerEndSound(client);
	
	if (!IsFakeClient(client))
	{
		// Print end timer message
		Call_GOKZ_OnTimerEndMessage(client, course, time, teleportsUsed, result);
		if (result == Plugin_Continue)
		{
			PrintEndTimeString(client);
		}
	}
	
	// Call Post Forward
	Call_GOKZ_OnTimerEnd_Post(client, course, time, teleportsUsed);
	
	return true;
}

bool TimerStop(int client, bool playSound = true)
{
	if (!timerRunning[client])
	{
		return false;
	}
	
	timerRunning[client] = false;
	if (playSound)
	{
		PlayTimerStopSound(client);
	}
	
	Call_GOKZ_OnTimerStopped(client);
	
	return true;
}

void TimerStopAll(bool playSound = true)
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsValidClient(client))
		{
			TimerStop(client, playSound);
		}
	}
}



// =====[ EVENTS ]=====

void OnClientPutInServer_Timer(int client)
{
	timerRunning[client] = false;
	hasStartedTimerThisMap[client] = false;
	hasEndedTimerThisMap[client] = false;
	currentTime[client] = 0.0;
	lastTimerEndTime[client] = 0.0;
	lastStartSoundTime[client] = 0.0;
	lastFalseEndSoundTime[client] = 0.0;
}

void OnPlayerRunCmdPost_Timer(int client)
{
	if (IsPlayerAlive(client) && GetTimerRunning(client) && !GetPaused(client))
	{
		currentTime[client] += GetTickInterval();
	}
}

void OnChangeMovetype_Timer(int client, MoveType newMovetype)
{
	if (!IsValidMovetype(newMovetype))
	{
		if (TimerStop(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Timer Stopped (Noclipped)");
		}
	}
}

void OnTeleportToStart_Timer(int client, bool customPos)
{
	if (GetCurrentMapPrefix() == MapPrefix_KZPro)
	{
		TimerStop(client, false);
	}
	if (GOKZ_GetCoreOption(client, Option_AutoRestart) == AutoRestart_Enabled
		 && !customPos && GetHasStartedTimerThisMap(client))
	{
		TimerStart(client, GetCurrentCourse(client), true);
	}
}

void OnClientDisconnect_Timer(int client)
{
	TimerStop(client);
}

void OnPlayerDeath_Timer(int client)
{
	TimerStop(client);
}

void OnOptionChanged_Timer(int client, Option option)
{
	if (option == Option_Mode)
	{
		if (TimerStop(client))
		{
			GOKZ_PrintToChat(client, true, "%t", "Timer Stopped (Changed Mode)");
		}
	}
}

void OnRoundStart_Timer()
{
	TimerStopAll();
}



// =====[ PRIVATE ]=====

static bool IsPlayerValidMoveType(int client)
{
	return IsValidMovetype(Movement_GetMovetype(client));
}

static bool IsValidMovetype(MoveType movetype)
{
	return movetype == MOVETYPE_WALK
	 || movetype == MOVETYPE_LADDER
	 || movetype == MOVETYPE_NONE;
}

static bool JustLanded(int client)
{
	return !gB_OldOnGround[client]
	 || GetGameTickCount() - Movement_GetLandingTick(client) <= GOKZ_TIMER_START_GROUND_TICKS;
}

static bool JustStartedTimer(int client)
{
	return timerRunning[client] && GetCurrentTime(client) < EPSILON;
}

static bool JustEndedTimer(int client)
{
	return GetHasEndedTimerThisMap(client)
	 && (GetGameTime() - lastTimerEndTime[client]) < 1.0;
}

static void PlayTimerStartSound(int client)
{
	if (!JustHeardStartSound(client))
	{
		EmitSoundToClient(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
		EmitSoundToClientSpectators(client, gC_ModeStartSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
		lastStartSoundTime[client] = GetGameTime();
	}
}

static bool JustHeardStartSound(int client)
{
	return (GetGameTime() - lastStartSoundTime[client]) < GOKZ_TIMER_SOUND_COOLDOWN;
}

static void PlayTimerEndSound(int client)
{
	EmitSoundToClient(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
	EmitSoundToClientSpectators(client, gC_ModeEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
}

static void PlayTimerFalseEndSound(int client)
{
	if (!JustEndedTimer(client) && !JustHeardFalseEndSound(client))
	{
		EmitSoundToClient(client, gC_ModeFalseEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
		EmitSoundToClientSpectators(client, gC_ModeFalseEndSounds[GOKZ_GetCoreOption(client, Option_Mode)]);
		lastFalseEndSoundTime[client] = GetGameTime();
	}
}

static bool JustHeardFalseEndSound(int client)
{
	return (GetGameTime() - lastFalseEndSoundTime[client]) < GOKZ_TIMER_SOUND_COOLDOWN;
}

static void PlayTimerStopSound(int client)
{
	EmitSoundToClient(client, GOKZ_SOUND_TIMER_STOP);
	EmitSoundToClientSpectators(client, GOKZ_SOUND_TIMER_STOP);
}

static void PrintEndTimeString(int client)
{
	if (GetCurrentCourse(client) == 0)
	{
		switch (GetCurrentTimeType(client))
		{
			case TimeType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Map (NUB)", 
					client, 
					GOKZ_FormatTime(GetCurrentTime(client)), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Map (PRO)", 
					client, 
					GOKZ_FormatTime(GetCurrentTime(client)), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
		}
	}
	else
	{
		switch (GetCurrentTimeType(client))
		{
			case TimeType_Nub:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Bonus (NUB)", 
					client, 
					currentCourse[client], 
					GOKZ_FormatTime(GetCurrentTime(client)), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
			case TimeType_Pro:
			{
				GOKZ_PrintToChatAll(true, "%t", "Beat Bonus (PRO)", 
					client, 
					currentCourse[client], 
					GOKZ_FormatTime(GetCurrentTime(client)), 
					gC_ModeNamesShort[GOKZ_GetCoreOption(client, Option_Mode)]);
			}
		}
	}
} 