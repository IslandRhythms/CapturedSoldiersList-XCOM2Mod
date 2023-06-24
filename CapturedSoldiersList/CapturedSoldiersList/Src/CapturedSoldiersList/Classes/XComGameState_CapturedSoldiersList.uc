// This is an Unreal Script
class XComGameState_CapturedSoldiersList extends XComGameState_BaseObject config(Memorial);


struct MemorialDetails {
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
}

var array<MemorialDetails> MIAList;

function UpdateMIAList() {
	local XComGameState_Analytics Analytics;
	local StateObjectReference UnitReference, UnitRef;
	local int Hours, Days;
	local XComGameState_Unit Unit, CapturedUnit;
	local XComGameStateHistory History;
	local XComGameState_BattleData BattleData;
	local XComGameState_AdventChosen ChosenState;
	local String Captor;
	local MemorialDetails Detail;
	History = `XCOMHISTORY;
	BattleData = XComGameState_BattleData(History.GetSingleGameStateObjectForClass(class 'XComGameState_BattleData'));
	ChosenState = XComGameState_AdventChosen(History.GetGameStateForObjectID(BattleData.ChosenRef.ObjectID));

	foreach `XCOMHQ.Squad(UnitRef)
	{
		Unit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(UnitRef.ObjectID));
		if (Unit.bCaptured && Unit.IsAlive())
		{
			// this only speeds up cases where the chosen wasn't on the previous mission. Still need to handle cases where they were on the mission.
			if (BattleData.ChosenRef.ObjectID == 0) {
				Detail.Captor = "Advent";
				Detail.CaptorFullName = Captor;
			} else {
				for(i = 0; i < ChosenState.CapturedSoldiers.Length; i++)
				{
					CapturedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenState.CapturedSoldiers[i].ObjectID));
					DupeUnit = CapturedUnit.GetReference();
					if (DupeUnit.ObjectID == UnitRef.ObjectID) {
						Captor = string(ChosenState.GetMyTemplateName());
						Detail.Captor = Split(Captor, "_", true);
						Detail.CaptorFullName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
						Detai.opName = BattleData.m_strOpName;
						Detail.MIADate = BattleData.LocalTime;
					}
				}
				if (Captor == "") {
					Detail.Captor = "Advent";
					Detail.CaptorFullName = Captor;
					class 'CapturedSoldiersManager'.static.RegisterDead(Unit, BattleData.m_strOpName, BattleData.LocalTime, CampaignIndex, Captor, CaptorFullName);
				}
				Captor = ""; // so the if statement can keep executing
			}
		}
	}

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
	MIAList.AddItem(Detail);
}
