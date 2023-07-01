class X2EventListener_Template extends X2EventListener ;

//add the listener
static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;

	Templates.AddItem(CapturedSoldiersList_CreateListener_CovertActionCompleted());

	return Templates;
}

//create the listener
static function X2EventListenerTemplate CapturedSoldiersList_CreateListener_CovertActionCompleted()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'CapturedSoldiersList_CovertActionCompleted');

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
	local int i;
	local XComGameState_Unit Unit;
	local XComGameState_CapturedSoldiersList List;

    CovAct = XComGameState_CovertAction(EventSource);
	// `log("++++++++++++++++++++++++++++++++++++++++");
	// `log("Covert Action Completed Listener");
	// Possible value for what the covert action was: string(CovAct.m_TemplateName);
    if (CovAct != none)
    {
        //do stuff
		for (i = 0; i < CovAct.StaffSlots.Length; i++) {
			SlotState = CovAct.GetStaffSlot(i);
			Unit = SlotState.GetAssignedStaff();
			if (Unit.bCaptured && Unit.IsSoldier() && Unit.IsAlive()) {
				// `log("Unit was captured" @ Unit.GetFullName());
				List.addUnitToList(Unit, CovAct.EndDateTime);
			}
		
		}
	}

	return ELR_NoInterrupt;
}
