global function InitAllChallengesMenu

const int MAX_CHALLENGE_CATEGORIES_PER_PAGE = 10
const int MAX_CHALLENGE_PER_PAGE = 9

struct
{
	var                            menu
	var                            decorationRui
	var                            titleRui
	var                            largeGroupButton0
	var                            largeGroupButton1
	var                            largeGroupButton2
	var                            groupListPanel
	var                            pinnedChallengeButton
	var                            challengesListPanel
	table<var, ChallengeGroupData> buttonGroupMap
	ChallengeGroupData ornull      activeGroup = null
} file

void function InitAllChallengesMenu( var newMenuArg )
//
{
	var menu = GetMenu( "AllChallengesMenu" )
	file.menu = menu

	file.decorationRui = Hud_GetRui( Hud_GetChild( menu, "Decoration" ) )
	file.titleRui = Hud_GetRui( Hud_GetChild( menu, "Title" ) )
	file.groupListPanel = Hud_GetChild( menu, "CategoryList" )
	file.pinnedChallengeButton = Hud_GetChild( menu, "PinnedChallenge" )
	file.challengesListPanel = Hud_GetChild( menu, "ChallengesList" )
	file.largeGroupButton0 = Hud_GetChild( menu, "CategoryLargeButton0" )
	file.largeGroupButton1 = Hud_GetChild( menu, "CategoryLargeButton1" )
	file.largeGroupButton2 = Hud_GetChild( menu, "CategoryLargeButton2" )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, AllChallengesMenu_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_SHOW, AllChallengesMenu_OnShow )
	AddMenuEventHandler( menu, eUIEvent.MENU_CLOSE, AllChallengesMenu_OnClose )
	AddMenuEventHandler( menu, eUIEvent.MENU_NAVIGATE_BACK, AllChallengesMenu_OnNavigateBack )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_SELECT", "" )
}


void function AllChallengesMenu_OnOpen()
{
	RuiSetGameTime( file.decorationRui, "initTime", Time() )
	RuiSetString( file.titleRui, "title", Localize( "#CHALLENGE_FULL_MENU_TITLE" ).toupper() )
}


void function AllChallengesMenu_OnShow()
{
	UI_SetPresentationType( ePresentationType.CHARACTER_CARD )

	AllChallengesMenu_UpdateCategories( true )
}


void function AllChallengesMenu_OnClose()
{
	AllChallengesMenu_UpdateCategories( false )
	AllChallengesMenu_UpdateActiveGroup()
}


void function AllChallengesMenu_OnNavigateBack()
{
	Assert( GetActiveMenu() == file.menu )
	CloseActiveMenu()
}


void function AllChallengesMenu_UpdateCategories( bool isShown )
{
}


void function GroupButton_OnClick( var button )
{
	//

	Assert( button in file.buttonGroupMap )
	file.activeGroup = file.buttonGroupMap[ button ]
	AllChallengesMenu_UpdateActiveGroup()
	Hud_SetNew( button, false )
}


void function AllChallengesMenu_UpdateActiveGroup()
{
}

void function AllChallengesMenu_UpdateDpadNav()
{

}

void function PutChallengeOnFullChallengeWidget( var button, ItemFlavor challenge, bool useAltColor )
{
}
