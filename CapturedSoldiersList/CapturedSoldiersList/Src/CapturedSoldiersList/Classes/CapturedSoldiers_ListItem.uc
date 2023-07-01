// This is an Unreal Script
class CapturedSoldiers_ListItem extends UIPersonnel_ListItem dependson(XComGameState_CapturedSoldiersList);

var MemorialDetails Detail;

var UIBGBox BorderBox;

simulated function CapturedSoldiers_ListItem InitItem(MemorialDetails mDetail)
{
	InitPanel();
	//SetSize(1280, 48);
	Detail = mDetail;

	//Spawn(class'UIBGBox', self).InitBG(,,, 1280, 48).SetBGColor("0x333333");

	//Spawn(class'UIScrollingText', self).InitScrollingText(,"Campaign"@Detail.CampaignIndex, 300, 5, 5, true);
	
	//Spawn(class'UIScrollingText', self).InitScrollingText(,Detail.SoldierName, 400, 315, 5, true);
	
	//Spawn(class'UIScrollingText', self).InitScrollingText(,Detail.MissionDied, 300, 725, 5);

	//Spawn(class'UIScrollingText', self).InitScrollingText(,Detail.KilledDate, 240, 1035, 5);

	//BorderBox = Spawn(class'UIBGBox', self).InitBG(,,, 1280, 48).SetOutline(true, "0x000000");

	AS_UpdateDataSoldier(Detail.SoldierName,
						Detail.Captor,
						Detail.Missions,
						Detail.opName,
						Detail.KilledDate);

	return self;
}

simulated function SetHighlighted(bool IsHighlighted)
{
	if (IsHighlighted)
		BorderBox.SetOutline(true, "0x00ffff");
	else
		BorderBox.SetOutline(true, "0x000000");

}

simulated function AS_UpdateDataSoldier(string UnitName,
								 string Captor, 
								 int UnitMissions, 
								 string UnitLastOp, 
								 string UnitDateOfDeath)
{
	MC.BeginFunctionOp("UpdateData");
	MC.QueueString(UnitName);
	MC.QueueString(Captor);
	MC.QueueNumber(UnitMissions);
	MC.QueueString(UnitLastOp);
	MC.QueueString(UnitDateOfDeath);
	MC.EndOp();
}

defaultproperties
{
	LibID = "DeceasedListItem";
	height = 40;
}

