/*
	Displays information using hint text.
	
	This is manually refreshed whenever player has taken off so that they see
	their pre-speed as soon as possible, improving responsiveness.
*/



// =====[ PUBLIC ]=====

bool IsDrawingInfoPanel(int client)
{
	KZPlayer player = KZPlayer(client);
	return player.infoPanel != InfoPanel_Disabled
	 && !NothingEnabledInInfoPanel(player);
}



// =====[ EVENTS ]=====

void OnPlayerRunCmdPost_InfoPanel(int client, int cmdnum)
{
	if (cmdnum % 12 == 0 || Movement_GetTakeoffCmdNum(client) == cmdnum - 1)
	{
		UpdateInfoPanel(client);
	}
}



// =====[ PRIVATE ]=====

static void UpdateInfoPanel(int client)
{
	KZPlayer player = KZPlayer(client);
	
	if (player.fake || !IsDrawingInfoPanel(player.id))
	{
		return;
	}
	
	if (player.alive)
	{
		PrintHintText(player.id, "%s", GetInfoPanel(player, player));
	}
	else
	{
		KZPlayer targetPlayer = KZPlayer(player.observerTarget);
		if (targetPlayer.id != -1 && !targetPlayer.fake)
		{
			PrintHintText(player.id, "%s", GetInfoPanel(player, targetPlayer));
		}
	}
}

static bool NothingEnabledInInfoPanel(KZPlayer player)
{
	bool noTimerText = player.timerText != TimerText_InfoPanel;
	bool noSpeedText = player.speedText != SpeedText_InfoPanel || player.paused;
	bool noKeys = player.showKeys == ShowKeys_Disabled
	 || player.showKeys == ShowKeys_Spectating && player.alive;
	return noTimerText && noSpeedText && noKeys;
}

static char[] GetInfoPanel(KZPlayer player, KZPlayer targetPlayer)
{
	char infoPanelText[320];
	FormatEx(infoPanelText, sizeof(infoPanelText), 
		"<font color='#626262'>%s%s%s", 
		GetTimeString(player, targetPlayer), 
		GetSpeedString(player, targetPlayer), 
		GetKeysString(player, targetPlayer));
	return infoPanelText;
}

static char[] GetTimeString(KZPlayer player, KZPlayer targetPlayer)
{
	char timeString[128];
	if (player.timerText != TimerText_InfoPanel)
	{
		timeString = "";
	}
	else if (targetPlayer.timerRunning)
	{
		switch (targetPlayer.timeType)
		{
			case TimeType_Nub:
			{
				FormatEx(timeString, sizeof(timeString), 
					"%T: <font color='#ead18a'>%s</font> %s\n", 
					"Info Panel Text - Time", player.id, 
					GOKZ_FormatTime(targetPlayer.time, false), 
					GetPausedString(player, targetPlayer));
			}
			case TimeType_Pro:
			{
				FormatEx(timeString, sizeof(timeString), 
					"%T: <font color='#b5d4ee'>%s</font> %s\n", 
					"Info Panel Text - Time", player.id, 
					GOKZ_FormatTime(targetPlayer.time, false), 
					GetPausedString(player, targetPlayer));
			}
		}
	}
	else
	{
		FormatEx(timeString, sizeof(timeString), 
			"%T: <font color='#ea4141'>%T</font> %s\n", 
			"Info Panel Text - Time", player.id, 
			"Info Panel Text - Stopped", player.id, 
			GetPausedString(player, targetPlayer));
	}
	return timeString;
}

static char[] GetPausedString(KZPlayer player, KZPlayer targetPlayer)
{
	char pausedString[64];
	if (targetPlayer.paused)
	{
		FormatEx(pausedString, sizeof(pausedString), 
			"(<font color='#ffffff'>%T</font>)", 
			"Info Panel Text - PAUSED", player.id);
	}
	else
	{
		pausedString = "";
	}
	return pausedString;
}

static char[] GetSpeedString(KZPlayer player, KZPlayer targetPlayer)
{
	char speedString[128];
	if (player.speedText != SpeedText_InfoPanel || targetPlayer.paused)
	{
		speedString = "";
	}
	else
	{
		if (targetPlayer.onGround || targetPlayer.onLadder || targetPlayer.noclipping)
		{
			FormatEx(speedString, sizeof(speedString), 
				"%T: <font color='#ffffff'>%.0f</font> u/s\n", 
				"Info Panel Text - Speed", player.id, 
				RoundFloat(targetPlayer.speed * 10) / 10.0);
		}
		else
		{
			FormatEx(speedString, sizeof(speedString), 
				"%T: <font color='#ffffff'>%.0f</font> %s\n", 
				"Info Panel Text - Speed", player.id, 
				RoundFloat(targetPlayer.speed * 10) / 10.0, 
				GetTakeoffString(targetPlayer));
		}
	}
	return speedString;
}

static char[] GetTakeoffString(KZPlayer targetPlayer)
{
	char takeoffString[64];
	if (targetPlayer.gokzHitPerf)
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#40ff40'>%.0f</font>)", 
			RoundFloat(targetPlayer.gokzTakeoffSpeed * 10) / 10.0);
	}
	else
	{
		FormatEx(takeoffString, sizeof(takeoffString), 
			"(<font color='#ffffff'>%.0f</font>)", 
			RoundFloat(targetPlayer.gokzTakeoffSpeed * 10) / 10.0);
	}
	return takeoffString;
}

static char[] GetKeysString(KZPlayer player, KZPlayer targetPlayer)
{
	char keysString[64];
	if (player.showKeys == ShowKeys_Disabled)
	{
		keysString = "";
	}
	else if (player.showKeys == ShowKeys_Spectating && player.alive)
	{
		keysString = "";
	}
	else
	{
		int buttons = targetPlayer.buttons;
		FormatEx(keysString, sizeof(keysString), 
			"%T: <font color='#ffffff'>%c %c %c %c %c %c</font>\n", 
			"Info Panel Text - Keys", player.id, 
			buttons & IN_MOVELEFT ? 'A' : '_', 
			buttons & IN_FORWARD ? 'W' : '_', 
			buttons & IN_BACK ? 'S' : '_', 
			buttons & IN_MOVERIGHT ? 'D' : '_', 
			buttons & IN_DUCK ? 'C' : '_', 
			buttons & IN_JUMP ? 'J' : '_');
	}
	return keysString;
} 