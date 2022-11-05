// This is an Unreal Script
class CapturedSoldiersManager extends Object config(Memorial);

struct MemorialDetails
{
// Data to compare
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

	var TAppearance Customization;
	var bool HasCustomization;

	var string FirstName;
	var string LastName;
	var string NickName;
	var name CountryTemplateName;
};

var config array<MemorialDetails> DeadSoldiers;
var config array<MemorialDetails> AllSoldiers;

simulated static function UpdateDeadDetail(XComGameState_Unit Unit, out MemorialDetails Detail)
{
	local XComGameState_Analytics Analytics;
	local StateObjectReference UnitReference;
	local int Hours, Days;
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

	Detail.Customization = Unit.kAppearance;
	Detail.Firstname = Unit.GetFirstName();
	Detail.LastName = Unit.GetLastName();
	Detail.NickName = Unit.GetNickName(true);
	Detail.CountryTemplateName = Unit.GetCountry();
	Detail.HasCustomization = true;
}


// DeadSoldiers is an array
simulated static function RegisterDead(XComGameState_Unit Unit, String opName, TDateTime MIADate, int CampaignIndex, String Captor, String CaptorFullName)
{
	local MemorialDetails NewDeadDetail;
	// we are here because a soldier has been captured. Create an entry.
	NewDeadDetail.MIADate = MIADate;
	NewDeadDetail.Captor = Captor;
	NewDeadDetail.CaptorFullName = CaptorFullName;
	NewDeadDetail.CampaignIndex = CampaignIndex;
	UpdateDeadDetail(Unit, NewDeadDetail);
	NewDeadDetail.opName = opName;
	default.DeadSoldiers.AddItem(NewDeadDetail);
	default.AllSoldiers.AddItem(NewDeadDetail);
	StaticSaveConfig();
}

simulated static function UpdateList(int CampaignIndex) {
	local int Index;
	local MemorialDetails DeadDetail;
	// removes entries from the array that are in the correct campaign
	for (Index = 0; Index < default.DeadSoldiers.Length; Index++)
	{
		DeadDetail = default.DeadSoldiers[Index];
		// This is checking if current units on the list should still be there.
		if (!SoldierIsCaptured(DeadDetail.SoldierID) && CampaignIndex == DeadDetail.CampaignIndex)
		{
			default.DeadSoldiers.Remove(Index, 1);
			Index--;
		}
	}

	// remove entries from the array, regardless of the campaign.
	for (Index = 0; Index < default.AllSoldiers.Length; Index++) {
		DeadDetail = default.AllSoldiers[Index];
		if (!SoldierIsCaptured(DeadDetail.SoldierID) && CampaignIndex == DeadDetail.CampaignIndex) {
			default.AllSoldiers.Remove(Index, 1);
			Index--;
		}
	}
	StaticSaveConfig();

}

simulated static function WipeList() {
	default.DeadSoldiers.Length = 0;
	StaticSaveConfig();
}

simulated static function WipeCapturedSoldiersListDB() {
	default.AllSoldiers.Length = 0;
	StaticSaveConfig();
}

simulated static function RebuildList(int CampaignIndex) {
	local int Index, i;
	local MemorialDetails DeadDetail, DupeDetail;
	local bool found;
	// Go through the "database" of captured soldiers across all campaigns and create the correct list for the current campaign.
	for (Index = 0; Index < default.AllSoldiers.Length; Index++)
	{
		found = false;
		DeadDetail = default.AllSoldiers[Index];
		// if the current campaign index mathes this array entry
		if (CampaignIndex == DeadDetail.CampaignIndex)
		{
			// go through the local list and see if the unit is already in there
			for (i = 0; i < default.DeadSoldiers.Length; i++) {
				DupeDetail = default.DeadSoldiers[i];
				if (DupeDetail.SoldierID == DeadDetail.SoldierID) {
					found = true;
					break;
				}
			}
			// if they are not in there, put them in.
			if (!found) {
				default.DeadSoldiers.AddItem(DeadDetail);
			}
		}
	}
	StaticSaveConfig();
	
}

simulated static function bool SoldierIsCaptured(int UnitID) {
	local XComGameState_HeadquartersAlien AlienHQ;
	local XComGameState_AdventChosen ChosenState;
	local XComGameStateHistory History;
	local StateObjectReference Entry;

	History = `XCOMHISTORY;
	AlienHQ = XComGameState_HeadquartersAlien(History.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersAlien'));
	ChosenState = XComGameState_AdventChosen(History.GetSingleGameStateObjectForClass(class'XComGameState_AdventChosen'));

	foreach AlienHQ.CapturedSoldiers(Entry) {
		if (Entry.ObjectID == UnitID) {
			return true;
		}
	}

	foreach ChosenState.CapturedSoldiers(Entry) {
		if (Entry.ObjectID == UnitID) {
			return true;
		}
	}

	return false;

}

