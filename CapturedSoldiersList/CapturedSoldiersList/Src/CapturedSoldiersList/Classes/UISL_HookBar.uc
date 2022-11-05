// This is an Unreal Script


class UISL_HookBar extends UIScreenListener;

event OnInit(UIScreen Screen)
{
	// UIFacility_BarMemorial
	// UIBarMemorial_Details
	local UIFacility_BarMemorial LastScreen;
	local UIButton MemorialButton;
	if (UIFacility_BarMemorial(Screen) == none)
		return;

	LastScreen = UIFacility_BarMemorial(Screen);
	MemorialButton = LastScreen.Spawn(class'UIButton', LastScreen);
	MemorialButton.bAnimateOnInit = false;
	MemorialButton.InitButton('GlobalMemorialButton', "Open MIA List", OpenMemorial, eUIButtonStyle_NONE);
	// MemorialButton.AnchorBottomCenter();
	MemorialButton.SetPosition(100, 880);
	// MemorialButton.SetPosition(0, 0 - 36);
	// LastScreen.SetTimer(0.2f, false, nameof(AddHelp), self);
}

simulated function UIFacility_BarMemorial GetBar()
{
	local int Index;
	local UIScreenStack Stack;
	Stack = `SCREENSTACK;
	for( Index = 0; Index < Stack.Screens.Length;  ++Index)
	{
		if( UIFacility_BarMemorial(Stack.Screens[Index]) != none )
			return UIFacility_BarMemorial(Stack.Screens[Index]);
	}
	return none; 
}

simulated function AddHelp()
{
	local UIFacility_BarMemorial Screen;
	local UIButton MemorialButton;

	Screen = GetBar();

	if (Screen != none)
	{
		if(Screen.GetChildByName('GlobalMemorialButton', false) == none && `SCREENSTACK.IsTopScreen(Screen))
		{
			//Screen.NavHelp.AddCenterHelp( "Open memorial",, 
			//							OpenMemorial,, 
			//							"Views all soldiers that died in service");
			MemorialButton = Screen.Spawn(class'UIButton', Screen);
			MemorialButton.bAnimateOnInit = false;
			MemorialButton.InitButton('GlobalMemorialButton', "Open MIA List", OpenMemorial, eUIButtonStyle_NONE);
			// MemorialButton.AnchorBottomCenter().SetPosition(0, 0 - 36);
			MemorialButton.SetPosition(100, 880);
			MemorialButton.AnimateIn(0);
			`log("Memorial button successfully added",, 'MemorialUISL');
		}
		`log("Refreshing memorial button...",, 'MemorialUISL');
		Screen.SetTimer(1.0f, false, nameof(AddHelp), self);
	}
	Screen.NavHelp.Show();
}

simulated function OpenMemorial(UIButton ButtonClicked)
{
	local UIFacility_BarMemorial LastScreen;

	LastScreen = GetBar();

	if(LastScreen != none && LastScreen.PC.Pres.ScreenStack.IsNotInStack(class'CapturedSoldiersScreen'))
		CapturedSoldiersScreen(LastScreen.PC.Pres.ScreenStack.Push(LastScreen.PC.Pres.Spawn( class'CapturedSoldiersScreen', LastScreen.PC.Pres))).InitMemorial();
}

defaultproperties
{
	//ScreenClass=class'UICharacterPool';
}
