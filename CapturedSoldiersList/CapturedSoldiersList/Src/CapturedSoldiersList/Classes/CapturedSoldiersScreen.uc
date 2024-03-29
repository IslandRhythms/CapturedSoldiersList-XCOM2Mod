// This is an Unreal Script
class CapturedSoldiersScreen extends UIScreen implements(IUISortableScreen);

var UIList MemorialList;
var UINavigationHelp NavHelp;
var CapturedSoldiers_ListItem LastHighlighted;

var UIPanel m_kDeceasedSortHeader;

// these are set in UIFlipSortButton
var bool m_bFlipSort;

enum EGMemorialSort_Type
{
	eGM_SortName,
	eGM_SortCampaign,
	eGM_SortMissions,
	eGM_SortDate,
	eGM_SortMissionDied
};

var EGMemorialSort_Type m_eSortType;

var MemorialDetails SaveToPoolDetails;

delegate int SortDelegate(CapturedSoldiers_ListItem A, CapturedSoldiers_ListItem B);

simulated function InitMemorial()
{
	MemorialList = Spawn(class'UIList', self);
	//MemorialList.InitList('ListGlobalMemorial', 96, 96, 1280, 740,, true);
	MemorialList.bIsNavigable = true;
	MemorialList.InitList('listAnchor', , , 961, 780);
	MemorialList.bStickyHighlight = false;
	MemorialList.OnItemClicked = OnDeceasedSelected;
	
	CreateSortHeaders();
	PopulateData();
	SortData();

	MC.FunctionString("SetScreenHeader", "Captured Soldiers List");

	NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	NavHelp.AddBackButton(OnCancel);
}

simulated function CreateSortHeaders()
{
	m_kDeceasedSortHeader = Spawn(class'UIPanel', self);
	m_kDeceasedSortHeader.bIsNavigable = false;
	m_kDeceasedSortHeader.InitPanel('deceasedSort', 'DeceasedSortHeader');
	m_kDeceasedSortHeader.Hide();

	Spawn(class'UIPanel', self).InitPanel('soldierSort', 'SoldierSortHeader').Hide();
	
	Spawn(class'UIPanel', self).InitPanel('personnelSort', 'PersonnelSortHeader').Hide();

	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("nameButton", eGM_SortName, "Name");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("killsButton", eGM_SortCampaign, "Captor");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("missionsButton", eGM_SortMissions, "Missions");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("operationButton", eGM_SortMissionDied, "Missing on");
	Spawn(class'UIFlipSortButton', m_kDeceasedSortHeader).InitFlipSortButton("dateButton", eGM_SortDate, "Date");
	m_kDeceasedSortHeader.Show();
}

simulated function OnCancel()
{
	Movie.Stack.PopFirstInstanceOfClass(class'CapturedSoldiersScreen');

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local TDialogueBoxData DialogData;

	if( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
		
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnCancel();
			break; 
		case class'UIUtilities_Input'.const.FXS_KEY_F:
		case class'UIUtilities_Input'.const.FXS_BUTTON_X:
			`log("F",,'GlobalMemorialScreen');
			DialogData.eType = eDialog_Normal;
			DialogData.strTitle = "Memorial";
			DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;
				
			DialogData.strText = "Respect paid";

			Movie.Pres.UIRaiseDialog( DialogData );
			break;
	}

	return super.OnUnrealCommand(cmd, arg);
}

// Probably needs modification
simulated function PopulateData()
{
	local int i;
	local XComGameState_CapturedSoldiersList List;
	List = XComGameState_CapturedSoldiersList(`XCOMHISTORY.GetSingleGameStateObjectForClass(class 'XComGameState_CapturedSoldiersList', true));

	for(i = 0; i < List.MIAList.Length; i++)
	{
		CapturedSoldiers_ListItem(MemorialList.CreateItem(class'CapturedSoldiers_ListItem')).InitItem(List.MIAList[i]); //.ProcessMouseEvents(OnItemMouseEvent);
	}
	MemorialList.RealizeItems();

	MC.FunctionString("SetEmptyLabel", List.MIAList.Length == 0 ? "No missing soldiers" : "");
}

simulated function ChangeSelection(UIList ContainerList, int ItemIndex)
{
	if (LastHighlighted != none)
		LastHighlighted.SetHighlighted(false);
	LastHighlighted = CapturedSoldiers_ListItem(MemorialList.GetSelectedItem());
	LastHighlighted.SetHighlighted(true);
}

simulated function OnItemMouseEvent(UIPanel ListItem, int cmd)
{
	local int i;
	local CapturedSoldiers_ListItem icon;

	for (i = 0; i < MemorialList.ItemCount; i++)
	{
		icon = CapturedSoldiers_ListItem(MemorialList.GetItem(i));
		if (ListItem == icon)  
		{
			switch (cmd)
			{
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
					OpenMemorialDetail(icon);
					icon.SetHighlighted(false);
					break;
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
					icon.SetHighlighted(true);
					break;
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
				case class'UIUtilities_Input'.const.FXS_L_MOUSE_DRAG_OUT:
					icon.SetHighlighted(false);
					break;

			}
		}
	}
}

simulated function OnDeceasedSelected( UIList kList, int index )
{
	if( !CapturedSoldiers_ListItem(kList.GetItem(index)).IsDisabled )
	{
		OpenMemorialDetail(CapturedSoldiers_ListItem(kList.GetItem(index)));
	}
}


simulated function OpenMemorialDetail(CapturedSoldiers_ListItem icon)
{
	local TDialogueBoxData DialogData;
	local MemorialDetails Detail;
	local String StrDetails;
	local Texture2D StaffPicture;

	Detail = icon.Detail;

	DialogData.eType = eDialog_Normal;
	DialogData.strTitle = Detail.SoldierName@"from"@Detail.CountryName;
	DialogData.strAccept = class'UIDialogueBox'.default.m_strDefaultAcceptLabel;

	StrDetails = "Achieved rank of"@Detail.RankName@"as"@Detail.ClassName;
	StrDetails = StrDetails $ "\nMissions participated:" @ Detail.Missions;
	StrDetails = StrDetails $ "\nEnemies killed:" @ Detail.Kills;
	StrDetails = StrDetails $ "\nDays served in XCOM:" @ Detail.DaysOnAvenger;
	StrDetails = StrDetails $ "\nDays spent in infirmary:" @ Detail.DaysInjured;
	StrDetails = StrDetails $ "\nAttacks made:" @ Detail.AttacksMade;
	StrDetails = StrDetails $ "\nDamage dealt:" @ Detail.DamageDealt;
	StrDetails = StrDetails $ "\nAttacks survived:" @ Detail.AttacksSurvived;
	StrDetails = StrDetails $ "\nLost in" @ Detail.opName @"at"@ Detail.KilledDate;
	StrDetails = StrDetails $ "\nCaptured by" @ Detail.CaptorFullName;
	StrDetails = StrDetails $ "\n\n" $ Detail.Epitaph ;
				
	DialogData.strText = StrDetails;
	
	StaffPicture = `XENGINE.m_kPhotoManager.GetHeadshotTexture(Detail.CampaignIndex, Detail.SoldierID, 512, 512);
	if (StaffPicture != none)
	{
		DialogData.strImagePath = class'UIUtilities_Image'.static.ValidateImagePath(PathName(StaffPicture));
	}

	Movie.Pres.UIRaiseDialog( DialogData );
}
//FlipSort
function bool GetFlipSort()
{
	return m_bFlipSort;
}
function int GetSortType()
{
	return int(m_eSortType);
}
function SetFlipSort(bool bFlip)
{
	m_bFlipSort = bFlip;
}
function SetSortType(int eSortType)
{
	m_eSortType = EGMemorialSort_Type(eSortType);
}

simulated function RefreshData()
{
	SortData();
}

function SortData()
{
	local int i;
	local array<UIPanel> SortButtons;

	switch( m_eSortType )
	{
		case eGM_SortName:
			SortCurrentData(SortByName);
			break;
		case eGM_SortCampaign:
			SortCurrentData(SortByCaptor);
			break;
		case eGM_SortMissions:
			SortCurrentData(SortByMissions);
			break;
		case eGM_SortDate:
			SortCurrentData(SortByDate);
			break;
		case eGM_SortMissionDied:
			SortCurrentData(SortByOp);
			break;
	}

	// Realize sort buttons
	m_kDeceasedSortHeader.GetChildrenOfType(class'UIFlipSortButton', SortButtons);
	for(i = 0; i < SortButtons.Length; ++i)
	{
		UIFlipSortButton(SortButtons[i]).RealizeSortOrder();
	}
}

simulated function SortCurrentData(delegate<SortDelegate> SortFunction)
{
	local array<CapturedSoldiers_ListItem> NewOrder;
	local int i;

	for (i = 0; i < MemorialList.ItemCount; i++)
	{
		NewOrder.AddItem( CapturedSoldiers_ListItem(MemorialList.GetItem(i)) );
	}

	NewOrder.Sort(SortFunction);

	
	for (i = 0; i < NewOrder.Length; i++)
	{
		MemorialList.MoveItemToBottom(NewOrder[i]);
	}
	MemorialList.RealizeItems();
}

simulated function int SortByName(CapturedSoldiers_ListItem A, CapturedSoldiers_ListItem B)
{
	local string FullA, FullB; 

	FullA = A.Detail.SoldierName;
	FullB = B.Detail.SoldierName;

	if( FullA < FullB )
	{
		return m_bFlipSort ? -1 : 1;
	}
	else if( FullA > FullB )
	{
		return m_bFlipSort ? 1 : -1;
	}
	else
	{
		return 0;
	}
}

simulated function int SortByCaptor(CapturedSoldiers_ListItem A, CapturedSoldiers_ListItem B)
{
	local string ValA, ValB;

	ValA = A.Detail.Captor;
	ValB = B.Detail.Captor;

	if (ValA > ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA < ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
}


simulated function int SortByMissions(CapturedSoldiers_ListItem A, CapturedSoldiers_ListItem B)
{
	local int ValA, ValB;

	ValA = A.Detail.Missions;
	ValB = B.Detail.Missions;

	if (ValA > ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA < ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortByDate(CapturedSoldiers_ListItem A, CapturedSoldiers_ListItem B)
{
	local TDateTime ValA, ValB;

	ValA = A.Detail.MIADate;
	ValB = B.Detail.MIADate;

	if (class 'X2StrategyGameRulesetDataStructures'.static.LessThan(ValA, ValB))
		return m_bFlipSort ? -1 : 1;
	else if(class 'X2StrategyGameRulesetDataStructures'.static.LessThan(ValB, ValA))
		return m_bFlipSort ? 1 : -1;
	return 0;
}

simulated function int SortByOp(CapturedSoldiers_ListItem A, CapturedSoldiers_ListItem B)
{
	local string ValA, ValB;

	ValA = A.Detail.opName;
	ValB = B.Detail.opName;
	if (ValA < ValB)
		return m_bFlipSort ? -1 : 1;
	else if( ValA > ValB )
		return m_bFlipSort ? 1 : -1;
	return 0;
}

defaultproperties
{
	MCName          = "theScreen";
	Package = "/ package/gfxSoldierList/SoldierList";
	bConsumeMouseEvents = true;
	m_eSortType = eGM_SortName;
}
