class X2EventListener_Template extends X2EventListener ;

//add the listener
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CreateListener_CovertActionCompleted());

	return Templates;
}

//create the listener
static function X2EventListenerTemplate CreateListener_CovertActionCompleted()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'CovertActionCompleted');

	Template.RegisterInTactical = false;	//listen during missions
	Template.RegisterInStrategy = true;		//listen during avenger

	//set to listen for event, do a thing, at this time
	Template.AddCHEvent('CovertActionCompleted', CheckForCapturedSoldiers, ELD_OnStateSubmitted);

	return Template;
}

//what does the listener do when it hears a call?
static function EventListenerReturn CheckForCapturedSoldiers(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
    local XComGameState_CovertAction CovAct;
	local XComGameState_StaffSlot SlotState;
	local int i, CampaignIndex;
	local XComGameState_Unit Unit, CapturedUnit;
	local XComGameState_AdventChosen ChosenState;
	local StateObjectReference UnitRef, DupeUnit;
	local XComGameState_CampaignSettings CampaignSettingsStateObject;
	local String Captor, CaptorFullName;
	local XComGameStateHistory History;

    CovAct = XComGameState_CovertAction(EventSource);
	`log("++++++++++++++++++++++++++++++++++++++++");
	`log("Covert Action Completed Listener");
    if (CovAct != none)
    {
		CampaignSettingsStateObject = XComGameState_CampaignSettings(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_CampaignSettings', true));
		CampaignIndex = CampaignSettingsStateObject.GameIndex;
		History = `XCOMHISTORY;
		ChosenState = XComGameState_AdventChosen(History.GetSingleGameStateObjectForClass(class'XComGameState_AdventChosen'));

        //do stuff
		for (i = 0; i < CovAct.StaffSlots.Length; i++) {
			SlotState = CovAct.GetStaffSlot(i);
			Unit = SlotState.GetAssignedStaff();
			if (Unit.bCaptured && Unit.IsSoldier() && Unit.IsAlive()) {
				`log("Unit was captured" @ Unit.GetFullName());
				for(i = 0; i < ChosenState.CapturedSoldiers.Length; i++)
				{
					CapturedUnit = XComGameState_Unit(`XCOMHISTORY.GetGameStateForObjectID(ChosenState.CapturedSoldiers[i].ObjectID));
					DupeUnit = CapturedUnit.GetReference();
					UnitRef = Unit.GetReference();
					if (DupeUnit.ObjectID == UnitRef.ObjectID) {
						CaptorFullName = ChosenState.FirstName $ " " $ ChosenState.NickName $ " " $ ChosenState.LastName;
						Captor = string(ChosenState.GetMyTemplateName());
						Captor = Split(Captor, "_", true);
						class 'CapturedSoldiersManager'.static.RegisterDead(Unit, "Covert Action", CovAct.EndDateTime, CampaignIndex, Captor, CaptorFullName);
					}
				}
			if (Captor == "") {
				Captor = "Advent";
				CaptorFullName = Captor;
				class 'CapturedSoldiersManager'.static.RegisterDead(Unit, "Covert Action", CovAct.EndDateTime, CampaignIndex, Captor, CaptorFullName);
			}
			Captor = ""; // so the if statement can keep executing
			} else {
				`log("Unit was not captured" @ Unit.GetFullName());
			}
		}
		
    }

	return ELR_NoInterrupt;
}
