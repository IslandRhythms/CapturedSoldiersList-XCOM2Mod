//---------------------------------------------------------------------------------------
//  FILE:   XComDownloadableContentInfo_CapturedSoldiersList.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_CapturedSoldiersList extends X2DownloadableContentInfo;


// Called in Strategy layer. Sends recruitables into the Gulag
exec function SendRecruitablesToGulag()
{
	local XComGameState_HeadquartersResistance ResistHQ;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen ChosenState;
	local XComGameStateHistory History;
	local int i;

	//Grab both Resistance HQ and Alien HQ
	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ResistHQ = XComGameState_HeadquartersResistance(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersResistance'));
	ChosenState = XComGameState_AdventChosen(History.GetSingleGameStateObjectForClass(class'XComGameState_AdventChosen'));

	//Send everyone to Gulag or Chosen Fun House to be tickled to death
	for(i = 0; i < ResistHQ.Recruits.Length; i++)
	{
		if (`SYNC_RAND_STATIC(100) < 50)
		{
			AlienHQ.CapturedSoldiers.AddItem(ResistHQ.Recruits[i]);
		}
		else
		{
			ChosenState.bCapturedSoldier = true;
			ChosenState.CapturedSoldiers.AddItem(ResistHQ.Recruits[i]);
			ChosenState.TotalCapturedSoldiers++;
		}
		//Remove from ResistanceHQ
		ResistHQ.Recruits.Remove(i, 1);
	}
}

exec function populateCapturedSoldiersList() 
{
	local XComGameState_Unit Unit;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local int CampaignIndex;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen ChosenState;
	local XComGameStateHistory History;
	local int i;
	local XComGameState_BattleData BattleData;
	local String Captor, CaptorFullName;
	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	CampaignIndex = CampaignSettingsStateObject.GameIndex;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ChosenState = XComGameState_AdventChosen(History.GetSingleGameStateObjectForClass(class'XComGameState_AdventChosen'));
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class 'XComGameState_BattleData'));

	for(i = 0; i < AlienHQ.CapturedSoldiers.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AlienHQ.CapturedSoldiers[i].ObjectID));
		Captor = "Advent";
		CaptorFullName = Captor;
		class 'CapturedSoldiersManager'.static.RegisterDead(Unit, BattleData.m_strOpName, BattleData.LocalTime, CampaignIndex, Captor, "Advent");
	}

	for(i = 0; i < ChosenState.CapturedSoldiers.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenState.CapturedSoldiers[i].ObjectID));
		CaptorFullName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
		Captor = string(ChosenState.GetMyTemplateName());
		Captor = Split(Captor, "_", true);
		class 'CapturedSoldiersManager'.static.RegisterDead(Unit, BattleData.m_strOpName, BattleData.LocalTime, CampaignIndex, Captor, CaptorFullName);
	}

}

exec function clearList() {
	class 'CapturedSoldiersManager'.static.WipeList();
	`log("List Wiped");
}

exec function clearCapturedSoldiersListDB() {
	class 'CapturedSoldiersManager'.static.WipeCapturedSoldiersListDB();
	`log("DB wiped");
}

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{
	CheckUpdateOrCreateNewGameState();

}



/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{
	CheckUpdateOrCreateNewGameState();
}

static final function CheckUpdateOrCreateNewGameState() {
	local XComGameState_CapturedSoldiersList List;
    local XComGameState NewGameState;
    local XComGameStateHistory History;

    History = `XCOMHISTORY;
    List = XComGameState_CapturedSoldiersList(History.GetSingleGameStateObjectForClass(class 'XComGameState_CapturedSoldiersList', true));

    NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Check, create or Update Captured Soldiers List");

    if (List == none)
    {
        List = XComGameState_CapturedSoldiersList(NewGameState.CreateNewStateObject(class'XComGameState_CapturedSoldiersList'));
    }
    else
    {
        List = XComGameState_CapturedSoldiersList(NewGameState.ModifyStateObject(List.Class, List.ObjectID));
    }

    List.UpdateMIAList();

    `GAMERULES.SubmitGameState(NewGameState);
}
