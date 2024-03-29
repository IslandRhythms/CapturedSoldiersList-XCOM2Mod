// This is an Unreal Script
class XComGameState_CapturedSoldiersList extends XComGameState_BaseObject config(Memorial);


struct MemorialDetails {
	var int CampaignIndex;
	var string opName;
	var int SoldierID;
// Exposed Values
	var String SoldierName;
	var String Captor;
	var String CaptorFullName;
	var int Missions;
	var int Kills;
	var int DaysOnAvenger;
	var int DaysInjured;
	var int AttacksMade;
	var int DamageDealt;
	var int AttacksSurvived;
	var TDateTime MIADate;
	var String MissionDied;
	var String KilledDate;
	var String CauseOfDeath;
	var String Epitaph;

	var string CountryName;
	var string RankName;
	var string ClassName;

	var string FirstName;
	var string LastName;
	var string NickName;
	var name CountryTemplateName;
};

var array<MemorialDetails> MIAList;
var config array<MemorialDetails> PrintList;

function UpdateMIAList() {
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local int CampaignIndex;
	local XComGameState_Analytics Analytics;
	local StateObjectReference UnitReference, UnitRef, DupeUnit;
	local int Hours, Days, i, exists;
	local XComGameState_Unit Unit, CapturedUnit;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_AdventChosen ChosenState;
	local String Captor;
	local MemorialDetails Detail;
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class 'XComGameState_BattleData'));
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));
	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	CampaignIndex = CampaignSettingsStateObject.GameIndex;
	Detail.CampaignIndex = CampaignIndex;
	// clean up the list if able
	for (i = 0; i < BattleData.RewardUnitOriginals.Length; i++) {
		`LOG("ID of the unit in the array"@BattleData.RewardUnitOriginals[i].ObjectID);
		Unit = XComGameState_Unit(History.GetGameStateForObjectID(BattleData.RewardUnitOriginals[i].ObjectID));
		if (Unit.bCaptured) {
			continue;
		}
		exists = MIAList.Find('SoldierID', BattleData.RewardUnitOriginals[i].ObjectID);
		`LOG("Does a unit with that objectID exist?"@exists);
		if (exists != -1) {
			MIAList.Remove(exists, 1);
		}
	}
	`LOG("Total number of troops deployed on the mission"@`XCOMHQ.Squad.Length);
	foreach `XCOMHQ.Squad(UnitRef)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (Unit.bCaptured && Unit.IsAlive())
		{
			// this only speeds up cases where the chosen wasn't on the previous mission. Still need to handle cases where they were on the mission.
			if (BattleData.ChosenRef.ObjectID == 0) {
				Detail.Captor = "Advent";
				Detail.CaptorFullName = Detail.Captor;
			} else {
				for(i = 0; i < ChosenState.CapturedSoldiers.Length; i++)
				{
					CapturedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenState.CapturedSoldiers[i].ObjectID));
					DupeUnit = CapturedUnit.GetReference();
					if (DupeUnit.ObjectID == UnitRef.ObjectID) {
						Captor = string(ChosenState.GetMyTemplateName());
						Detail.Captor = Split(Captor, "_", true);
						Detail.CaptorFullName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
					}
				}
				if (Captor == "") {
					Detail.Captor = "Advent";
					Detail.CaptorFullName = Captor;
				}
				Captor = ""; // so the if statement can keep executing
			} // top level if unit is captured
			Detail.opName = BattleData.m_strOpName;
			Detail.MIADate = BattleData.LocalTime;
			Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
			UnitReference = Unit.GetReference();

			Detail.Missions = Unit.GetNumMissions();
			Detail.Kills = Unit.GetNumKills();

			Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_SERVICE_LENGTH", UnitReference );
			Days = int(Hours / 24.0f);
			Detail.DaysOnAvenger = Days;

			Detail.CauseOfDeath = Unit.m_strCauseOfDeath;

			Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_HEALING", UnitReference );
			Days = int( Hours / 24.0f );
			Detail.DaysInjured = Days;

			Detail.AttacksMade = Analytics.GetUnitFloatValue( "ACC_UNIT_SUCCESSFUL_ATTACKS", UnitReference );

			Detail.DamageDealt = Analytics.GetUnitFloatValue( "ACC_UNIT_DEALT_DAMAGE", UnitReference );

			Detail.AttacksSurvived = Analytics.GetUnitFloatValue( "ACC_UNIT_ABILITIES_RECIEVED", UnitReference );

			// Detail.MissionDied = Detail.opName;
			Detail.KilledDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Detail.MIADate, true);

			Detail.Epitaph = Unit.m_strEpitaph;

			Detail.CountryName = Unit.GetCountryTemplate().DisplayName;
			Detail.ClassName = Unit.GetSoldierClassTemplate().DisplayName;
			Detail.RankName = class'X2ExperienceConfig'.static.GetRankName(Unit.GetSoldierRank(), Unit.GetSoldierClassTemplateName());
			Detail.SoldierName = Unit.GetName( eNameType_FullNick );
			Detail.SoldierID = UnitReference.ObjectID;

			Detail.Firstname = Unit.GetFirstName();
			Detail.LastName = Unit.GetLastName();
			Detail.NickName = Unit.GetNickName(true);
			Detail.CountryTemplateName = Unit.GetCountry();
			MIAList.AddItem(Detail);
		}
	
	}


}

function addUnitToList(XComGameState_Unit Troop, TDateTime MissingDate) {
	local int i, CampaignIndex, Hours, Days;
	local XComGameState_Analytics Analytics;
	local XComGameState_Unit CapturedUnit;
	local XComGameState_AdventChosen ChosenState;
	local StateObjectReference UnitRef, DupeUnit, UnitReference;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local String Captor;
	local XComGameStateHistory History;
	local MemorialDetails Detail;
	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	CampaignIndex = CampaignSettingsStateObject.GameIndex;
	Detail.CampaignIndex = CampaignIndex;
	History = `XCOMHISTORY;
	// Search for the captured unit
	foreach History.IterateByClassType(class 'XComGameState_AdventChosen', ChosenState) {
		for(i = 0; i < ChosenState.CapturedSoldiers.Length; i++)
		{
			CapturedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenState.CapturedSoldiers[i].ObjectID));
			DupeUnit = CapturedUnit.GetReference();
			UnitRef = Troop.GetReference();
			if (DupeUnit.ObjectID == UnitRef.ObjectID) {
				Detail.CaptorFullName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
				Captor = string(ChosenState.GetMyTemplateName());
				Detail.Captor = Split(Captor, "_", true);
			}
			if (Captor == "") {
				Detail.Captor = "Advent";
				Detail.CaptorFullName = Detail.Captor;
			}
		}
	}
	Detail.opName = "Covert Action";
	Detail.MIADate = MissingDate;
	Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
	UnitReference = Troop.GetReference();

	Detail.Missions = Troop.GetNumMissions();
	Detail.Kills = Troop.GetNumKills();

	Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_SERVICE_LENGTH", UnitReference );
	Days = int(Hours / 24.0f);
	Detail.DaysOnAvenger = Days;

	Detail.CauseOfDeath = Troop.m_strCauseOfDeath;

	Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_HEALING", UnitReference );
	Days = int( Hours / 24.0f );
	Detail.DaysInjured = Days;

	Detail.AttacksMade = Analytics.GetUnitFloatValue( "ACC_UNIT_SUCCESSFUL_ATTACKS", UnitReference );

	Detail.DamageDealt = Analytics.GetUnitFloatValue( "ACC_UNIT_DEALT_DAMAGE", UnitReference );

	Detail.AttacksSurvived = Analytics.GetUnitFloatValue( "ACC_UNIT_ABILITIES_RECIEVED", UnitReference );

	// Detail.MissionDied = Detail.opName;
	Detail.KilledDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Detail.MIADate, true);

	Detail.Epitaph = Troop.m_strEpitaph;

	Detail.CountryName = Troop.GetCountryTemplate().DisplayName;
	Detail.ClassName = Troop.GetSoldierClassTemplate().DisplayName;
	Detail.RankName = class'X2ExperienceConfig'.static.GetRankName(Troop.GetSoldierRank(), Troop.GetSoldierClassTemplateName());
	Detail.SoldierName = Troop.GetName( eNameType_FullNick );
	Detail.SoldierID = UnitReference.ObjectID;

	Detail.Firstname = Troop.GetFirstName();
	Detail.LastName = Troop.GetLastName();
	Detail.NickName = Troop.GetNickName(true);
	Detail.CountryTemplateName = Troop.GetCountry();
	MIAList.AddItem(Detail);
}

function getCapturedSoldiers() {
	local XComGameState_Unit Unit;
	local StateObjectReference UnitReference;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local XComGameState_Analytics Analytics;
	local int CampaignIndex;
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen ChosenState;
	local XComGameStateHistory History;
	local int i, Hours, Days;
	local String Captor, CaptorFullName;
	local MemorialDetails Detail;
	CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
	CampaignIndex = CampaignSettingsStateObject.GameIndex;
	Detail.CampaignIndex = CampaignIndex;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));


	for(i = 0; i < AlienHQ.CapturedSoldiers.Length; i++)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(AlienHQ.CapturedSoldiers[i].ObjectID));
		Captor = "Advent";
		CaptorFullName = Captor;
		Detail.Captor = Captor;
		Detail.CaptorFullName = Captor;
		Detail.MIADate = Unit.m_RecruitDate; // Since we can't get the battle data after the fact, just use the recruit date.
		Detail.opName = "Log Operation"; // Same logic as above, just indicate had to use the log to get this troop.
		Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
		UnitReference = Unit.GetReference();

		Detail.Missions = Unit.GetNumMissions();
		Detail.Kills = Unit.GetNumKills();

		Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_SERVICE_LENGTH", UnitReference );
		Days = int(Hours / 24.0f);
		Detail.DaysOnAvenger = Days;

		Detail.CauseOfDeath = Unit.m_strCauseOfDeath;

		Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_HEALING", UnitReference );
		Days = int( Hours / 24.0f );
		Detail.DaysInjured = Days;

		Detail.AttacksMade = Analytics.GetUnitFloatValue( "ACC_UNIT_SUCCESSFUL_ATTACKS", UnitReference );

		Detail.DamageDealt = Analytics.GetUnitFloatValue( "ACC_UNIT_DEALT_DAMAGE", UnitReference );

		Detail.AttacksSurvived = Analytics.GetUnitFloatValue( "ACC_UNIT_ABILITIES_RECIEVED", UnitReference );

		// Detail.MissionDied = Detail.opName;
		Detail.KilledDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Detail.MIADate, true);

		Detail.Epitaph = Unit.m_strEpitaph;

		Detail.CountryName = Unit.GetCountryTemplate().DisplayName;
		Detail.ClassName = Unit.GetSoldierClassTemplate().DisplayName;
		Detail.RankName = class'X2ExperienceConfig'.static.GetRankName(Unit.GetSoldierRank(), Unit.GetSoldierClassTemplateName());
		Detail.SoldierName = Unit.GetName( eNameType_FullNick );
		Detail.SoldierID = UnitReference.ObjectID;

		Detail.Firstname = Unit.GetFirstName();
		Detail.LastName = Unit.GetLastName();
		Detail.NickName = Unit.GetNickName(true);
		Detail.CountryTemplateName = Unit.GetCountry();
		MIAList.AddItem(Detail);
	}
	foreach History.IterateByClassType(class 'XComGameState_AdventChosen', ChosenState) {
		for(i = 0; i < ChosenState.CapturedSoldiers.Length; i++)
		{
			Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenState.CapturedSoldiers[i].ObjectID));
			CaptorFullName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
			Detail.CaptorFullName = CaptorFullName;
			Captor = string(ChosenState.GetMyTemplateName());
			Captor = Split(Captor, "_", true);
			Detail.Captor = Captor;
			Detail.MIADate = Unit.m_RecruitDate; // Since we can't get the battle data after the fact, just use the recruit date.
			Detail.opName = "Log Operation"; // Same logic as above, just indicate had to use the log to get this troop.
			Analytics = XComGameState_Analytics(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_Analytics'));
			UnitReference = Unit.GetReference();

			Detail.Missions = Unit.GetNumMissions();
			Detail.Kills = Unit.GetNumKills();

			Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_SERVICE_LENGTH", UnitReference );
			Days = int(Hours / 24.0f);
			Detail.DaysOnAvenger = Days;

			Detail.CauseOfDeath = Unit.m_strCauseOfDeath;

			Hours = Analytics.GetUnitFloatValue( "ACC_UNIT_HEALING", UnitReference );
			Days = int( Hours / 24.0f );
			Detail.DaysInjured = Days;

			Detail.AttacksMade = Analytics.GetUnitFloatValue( "ACC_UNIT_SUCCESSFUL_ATTACKS", UnitReference );

			Detail.DamageDealt = Analytics.GetUnitFloatValue( "ACC_UNIT_DEALT_DAMAGE", UnitReference );

			Detail.AttacksSurvived = Analytics.GetUnitFloatValue( "ACC_UNIT_ABILITIES_RECIEVED", UnitReference );

			// Detail.MissionDied = Detail.opName;
			Detail.KilledDate = class'X2StrategyGameRulesetDataStructures'.static.GetDateString(Detail.MIADate, true);

			Detail.Epitaph = Unit.m_strEpitaph;

			Detail.CountryName = Unit.GetCountryTemplate().DisplayName;
			Detail.ClassName = Unit.GetSoldierClassTemplate().DisplayName;
			Detail.RankName = class'X2ExperienceConfig'.static.GetRankName(Unit.GetSoldierRank(), Unit.GetSoldierClassTemplateName());
			Detail.SoldierName = Unit.GetName( eNameType_FullNick );
			Detail.SoldierID = UnitReference.ObjectID;

			Detail.Firstname = Unit.GetFirstName();
			Detail.LastName = Unit.GetLastName();
			Detail.NickName = Unit.GetNickName(true);
			Detail.CountryTemplateName = Unit.GetCountry();
			MIAList.AddItem(Detail);
		}
	}

	
}

// only use this for testing

function wipeList() {
	MIAList.Length = 0;
}

function exportList() {
	local int i;
	for (i = 0; i < MIAList.Length; i++) {
		PrintList.AddItem(MIAList[i]);
	}
	SaveConfig();
}
