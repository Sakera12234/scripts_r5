//
#if(true)

#if CLIENT || UI 
global function ShPassPanel_LevelInit
#endif

#if(CLIENT)
global function UIToClient_StartBattlePassScene
global function UIToClient_StopBattlePassScene
global function UIToClient_ItemPresentation
global function BattlePassScene_Thread
global function InitBattlePassLights
global function BattlePassLightsOn
global function BattlePassLightsOff
global function ClearBattlePassItem
#endif

#if(UI)
global function InitPassPanel
global function UpdateRewardPanel
global function InitAboutBattlePass1Dialog
global function GetRewardPanel

global function InitPassXPPurchaseDialog
global function InitPassPurchaseMenu

global function GetNumPages

global function TryDisplayBattlePassAwards

global function InitBattlePassRewardButtonRui
#endif


//
//
//
//
//


struct FileStruct_LifetimeLevel
{
	#if(CLIENT)
		bool                       isBattlePassSceneThreadActive = false
		vector                     sceneRefOrigin
		vector                     sceneRefAngles
		entity                     mover
		array<entity>              models
		NestedGladiatorCardHandle& bannerHandle
		var                        topo
		var                        rui
		array<entity>              stationaryLights
		//
		//
		string                     playingPreviewAlias

		var loadscreenPreviewBox = null
	#endif
	table signalDummy
	int   videoChannel = -1

}
FileStruct_LifetimeLevel& fileLevel


#if(UI)
global struct RewardGroup
{
	int                     level
	array<BattlePassReward> rewards
}
struct RewardButtonData
{
	var          button
	var          footer
	int          rewardGroupSubIdx
	RewardGroup& rewardGroup
	int          rewardSubIdx
}
#endif

struct
{
	#if(UI)
		int                                previousPage = -1
		int                                currentPage = -1
		array<RewardGroup>                 currentRewardGroups = []
		string ornull                      currentRewardButtonKey = null
		var                                rewardBarPanel
		array<var>                         rewardButtons
		table<var, RewardButtonData>       rewardButtonToDataMap
		table<string, RewardButtonData>    rewardKeyToRewardButtonDataMap
		array<var>                         rewardFooters
		var                                rewardBarFooter
		bool                               rewardButtonFocusForced

		var nextPageButton
		var prevPageButton

		var invisiblePageLeftTriggerButton
		var invisiblePageRightTriggerButton

		var statusBox
		var purchaseButton

		var levelReqButton
		var premiumReqButton

		var detailBox
		var loadscreenPreviewBox
		var loadscreenPreviewBoxOverlay
	#endif

} file

#if(UI)
const int REWARDS_PER_PAGE = 14
#endif

//
//
//
//
//
#if CLIENT || UI 
void function ShPassPanel_LevelInit()
{
	#if(CLIENT)
		RegisterSignal( "StopBattlePassSceneThread" )
		RegisterButtonPressedCallback( MOUSE_WHEEL_UP, OnMouseWheelUp )
		RegisterButtonPressedCallback( MOUSE_WHEEL_DOWN, OnMouseWheelDown )

		AddCallback_UIScriptReset( void function() {
			fileLevel.loadscreenPreviewBox = null //
		} )
	#endif
}
#endif


#if(UI)
void function InitPassPanel( var panel )
{
	SetPanelTabTitle( panel, "#PASS" )

	AddPanelEventHandler( panel, eUIEvent.PANEL_SHOW, OnPanelShow )
	AddPanelEventHandler( panel, eUIEvent.PANEL_HIDE, OnPanelHide )

	file.purchaseButton = Hud_GetChild( panel, "PurchaseButton" )
	Hud_AddEventHandler( file.purchaseButton, UIE_CLICK, BattlePass_PurchaseButton_OnActivate )

	file.rewardBarPanel = Hud_GetChild( panel, "RewardBarPanel" )

	file.rewardButtons = GetPanelElementsByClassname( file.rewardBarPanel, "RewardButton" )
	foreach ( int rewardButtonIdx, var rewardButton in file.rewardButtons )
	{
		Hud_SetNavUp( rewardButton, file.purchaseButton )
		Hud_AddEventHandler( rewardButton, UIE_GET_FOCUS, BattlePass_RewardButton_OnGetFocus )
		Hud_AddEventHandler( rewardButton, UIE_LOSE_FOCUS, BattlePass_RewardButton_OnLoseFocus )
		Hud_AddEventHandler( rewardButton, UIE_CLICK, BattlePass_RewardButton_OnActivate )
		Hud_AddEventHandler( rewardButton, UIE_CLICKRIGHT, BattlePass_RewardButton_OnAltActivate )
	}

	file.rewardFooters = GetPanelElementsByClassname( file.rewardBarPanel, "RewardFooter" )

	file.rewardBarFooter = Hud_GetChild( panel, "RewardBarFooter" )

	file.nextPageButton = Hud_GetChild( panel, "RewardBarNextButton" )
	file.prevPageButton = Hud_GetChild( panel, "RewardBarPrevButton" )
	var prevPageRui = Hud_GetRui( file.prevPageButton )
	RuiSetBool( prevPageRui, "flipHorizontal", true )

	Hud_AddEventHandler( file.nextPageButton, UIE_CLICK, BattlePass_PageForward )
	Hud_AddEventHandler( file.prevPageButton, UIE_CLICK, BattlePass_PageBackward )
	//
	file.statusBox = Hud_GetChild( panel, "StatusBox" )

	HudElem_SetRuiArg( Hud_GetChild( panel, "AboutButton" ), "buttonText", "#BATTLE_PASS_BUTTON_ABOUT" )
	Hud_AddEventHandler( Hud_GetChild( panel, "AboutButton" ), UIE_CLICK, AdvanceMenuEventHandler( GetMenu( "BattlePassAboutPage1" ) ) )

	file.levelReqButton = Hud_GetChild( panel, "LevelReqButton" )
	file.premiumReqButton = Hud_GetChild( panel, "PremiumReqButton" )

	file.detailBox = Hud_GetChild( panel, "DetailsBox" )
	file.loadscreenPreviewBox = Hud_GetChild( panel, "LoadscreenPreviewBox" )
	file.loadscreenPreviewBoxOverlay = Hud_GetChild( panel, "LoadscreenPreviewBoxOverlay" )

	AddPanelFooterOption( panel, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
	AddPanelFooterOption( panel, LEFT, BUTTON_A, false, "#A_BUTTON_INSPECT", "#A_BUTTON_INSPECT", null, BattlePass_IsFocusedItemInspectable )
	AddPanelFooterOption( panel, LEFT, BUTTON_X, false, "#X_BUTTON_EQUIP", "#X_BUTTON_EQUIP", null, BattlePass_IsFocusedItemEquippable )

	file.invisiblePageLeftTriggerButton = Hud_GetChild( file.rewardBarPanel, "InvisiblePageLeftTriggerButton" )
	Hud_AddEventHandler( file.invisiblePageLeftTriggerButton, UIE_GET_FOCUS, void function( var button ) {
		BattlePass_PageBackward( button )
	} )
	file.invisiblePageRightTriggerButton = Hud_GetChild( file.rewardBarPanel, "InvisiblePageRightTriggerButton" )
	Hud_AddEventHandler( file.invisiblePageRightTriggerButton, UIE_GET_FOCUS, void function( var button ) {
		BattlePass_PageForward( button )
	} )
}


var function GetRewardPanel()
{
	return file.rewardBarPanel
}

string function GetRewardButtonKey( int levelNum, int rewardSubIdx )
{
	return format( "level%d:reward%d", levelNum, rewardSubIdx )
}

void function UpdateRewardPanel( array<RewardGroup> rewardGroups )
{
	int panelMaxWidth = Hud_GetBaseWidth( file.rewardBarPanel )
	printt( panelMaxWidth, Hud_GetBaseWidth( file.rewardBarPanel ), Hud_GetWidth( file.rewardBarPanel ) )

	const int MAX_REWARD_BUTTONS = 15
	const int MAX_REWARD_FOOTERS = 15

	int thinDividers
	int thickDividers
	int numButtons = 0
	foreach ( rewardIdx, rewardGroup in rewardGroups )
	{
		if ( rewardGroup.rewards.len() == 0 )
			continue

		thinDividers += (rewardGroup.rewards.len() - 1)
		if ( rewardIdx < (rewardGroups.len() - 1) )
			thickDividers++
		numButtons += rewardGroup.rewards.len()
	}

	Assert( file.rewardFooters.len() == MAX_REWARD_FOOTERS )

	Assert( file.rewardButtons.len() == MAX_REWARD_BUTTONS )
	file.rewardButtons.sort( SortByScriptId )
	int buttonWidth = Hud_GetWidth( file.rewardButtons[0] )

	foreach ( rewardFooter in file.rewardFooters )
	{
		Hud_Hide( rewardFooter )
		HudElem_SetRuiArg( rewardFooter, "isButtonFocused", false )
	}

	foreach ( rewardButton in file.rewardButtons )
	{
		Hud_Hide( rewardButton )
		Hud_SetSelected( rewardButton, false )
	}

	file.rewardButtonToDataMap.clear()
	file.rewardKeyToRewardButtonDataMap.clear()

	//

	int thinPadding  = ContentScaledXAsInt( 8 )
	int thickPadding = ContentScaledXAsInt( 16 )

	int contentWidth       = (buttonWidth * numButtons) + (thinPadding * thinDividers) + (thickPadding * thickDividers)
	//
	bool hasPremiumPass    = false
	int battlePassLevelIdx = 0

	Hud_SetWidth( file.rewardBarPanel, contentWidth )
	Hud_SetWidth( file.rewardBarFooter, contentWidth )

	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null && GRX_IsInventoryReady()
	if ( hasActiveBattlePass )
	{
		expect ItemFlavor( activeBattlePass )
		hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )
		battlePassLevelIdx = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	}

	array<RewardButtonData> rewardButtonDataList = []

	int offset    = 0
	int buttonIdx = 0
	int footerIdx = 0
	foreach ( int rewardGroupSubIdx, RewardGroup rewardGroup in rewardGroups )
	{
		if ( rewardGroup.rewards.len() == 0 )
			continue

		var rewardFooter = file.rewardFooters[footerIdx]
		Hud_SetX( rewardFooter, offset )
		var footerRui = Hud_GetRui( rewardFooter )
		RuiSetString( footerRui, "levelText", GetBattlePassDisplayLevel( rewardGroup.level, true ) )
		RuiSetInt( footerRui, "level", rewardGroup.level )
		Hud_Show( rewardFooter )

		int footerWidth = 0
		foreach ( int rewardSubIdx, BattlePassReward bpReward in rewardGroup.rewards )
		{
			var rewardButton = file.rewardButtons[buttonIdx]

			RewardButtonData rbd
			rbd.button = rewardButton
			rbd.footer = rewardFooter
			rbd.rewardGroupSubIdx = rewardGroupSubIdx
			rbd.rewardGroup = rewardGroup
			rbd.rewardSubIdx = rewardSubIdx
			file.rewardButtonToDataMap[rewardButton] <- rbd
			file.rewardKeyToRewardButtonDataMap[GetRewardButtonKey( rewardGroup.level, rewardSubIdx )] <- rbd
			rewardButtonDataList.append( rbd )

			Hud_SetX( rewardButton, offset )
			Hud_SetEnabled( rewardButton, hasActiveBattlePass )
			//
			//

			bool isOwned = (!bpReward.isPremium || hasPremiumPass) && bpReward.level <= battlePassLevelIdx
			HudElem_SetRuiArg( rewardButton, "isOwned", isOwned )
			RuiSetBool( footerRui, "isOwned", isOwned )
			HudElem_SetRuiArg( rewardButton, "isPremium", bpReward.isPremium )

			int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
			HudElem_SetRuiArg( rewardButton, "rarity", rarity )
			RuiSetImage( Hud_GetRui( rewardButton ), "buttonImage", GetImageForBattlePassReward( bpReward ) )

			if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
				HudElem_SetRuiArg( rewardButton, "isLootBox", true )

			HudElem_SetRuiArg( rewardButton, "itemCountString", "" )
			if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
				HudElem_SetRuiArg( rewardButton, "itemCountString", string( bpReward.quantity ) )

			HudElem_SetRuiArg( rewardButton, "bpLevel", bpReward.level )
			HudElem_SetRuiArg( rewardButton, "isRewardBar", true )

			offset += buttonWidth
			footerWidth += buttonWidth

			if ( rewardSubIdx < (rewardGroup.rewards.len() - 1) )
			{
				offset += thinPadding
				footerWidth += thinPadding
			}
			else
			{
				offset += thickPadding
			}

			buttonIdx++
		}
		Hud_SetWidth( rewardFooter, footerWidth )
		footerIdx++
	}

	for ( int index = 0; index < buttonIdx; index++ )
	{
		Hud_Show( file.rewardButtons[index] )
	}

	if ( GetFocus() == file.invisiblePageLeftTriggerButton )
		Hud_SetFocused( file.rewardButtons[buttonIdx - 1] )
	else if ( GetFocus() == file.invisiblePageRightTriggerButton )
		Hud_SetFocused( file.rewardButtons[0] )
	else
	{
		int lowestLevelIdx  = 999999
		int highestLevelIdx = -999999
		foreach( RewardButtonData rbd in rewardButtonDataList )
		{
			lowestLevelIdx = minint( rbd.rewardGroup.level, lowestLevelIdx )
			highestLevelIdx = maxint( rbd.rewardGroup.level, highestLevelIdx )
		}

		int desiredLevelIdx = lowestLevelIdx
		if ( hasActiveBattlePass && hasPremiumPass )
		{
			desiredLevelIdx = BattlePass_GetNextLevelWithReward( expect ItemFlavor( activeBattlePass ), battlePassLevelIdx )
			desiredLevelIdx = ClampInt( desiredLevelIdx, lowestLevelIdx, highestLevelIdx )
		}

		string desiredFocusRewardButtonKey = GetRewardButtonKey( desiredLevelIdx, 0 )
		Assert( desiredFocusRewardButtonKey in file.rewardKeyToRewardButtonDataMap, format( "Tried to focus reward button '%s' on page %d'", desiredFocusRewardButtonKey, file.currentPage ) )
		BattlePass_FocusRewardButton( file.rewardKeyToRewardButtonDataMap[desiredFocusRewardButtonKey] )
	}
}

void function BattlePass_PageForward( var button )
{
	EmitUISound( "UI_Menu_BattlePass_LevelTab" )
	BattlePass_SetPage( file.currentPage + 1 )
}


void function BattlePass_PageBackward( var button )
{
	EmitUISound( "UI_Menu_BattlePass_LevelTab" )
	BattlePass_SetPage( file.currentPage - 1 )
}


void function BattlePass_PurchaseButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
	{
		return
	}
	expect ItemFlavor( activeBattlePass )

	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )

	if ( !hasPremiumPass )
		AdvanceMenu( GetMenu( "PassPurchaseMenu" ) )
	else if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) > 0 )
		AdvanceMenu( GetMenu( "PassXPPurchaseDialog" ) )
	else
		return
}


void function BattlePass_RewardButton_OnGetFocus( var button )
{
	Hud_SetNavDown( file.purchaseButton, button )

	RewardButtonData rbd    = file.rewardButtonToDataMap[button]
	//
	BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]

	file.currentRewardButtonKey = GetRewardButtonKey( rbd.rewardGroup.level, rbd.rewardSubIdx )
	bool wasFocusForced = file.rewardButtonFocusForced
	file.rewardButtonFocusForced = false

	Hud_SetNavDown( file.purchaseButton, rbd.button )

	foreach ( var otherButton in file.rewardButtons )
		Hud_SetSelected( otherButton, false )
	Hud_SetSelected( button, true )

	foreach ( var rewardFooter in file.rewardFooters )
		HudElem_SetRuiArg( rewardFooter, "isButtonFocused", false )
	HudElem_SetRuiArg( rbd.footer, "isButtonFocused", true )

	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return
	expect ItemFlavor( activeBattlePass )

	int battlePassLevel = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )

	string itemName = GetBattlePassRewardItemName( reward )
	int rarity      = ItemFlavor_HasQuality( reward.flav ) ? ItemFlavor_GetQuality( reward.flav ) : 0

	string itemDesc   = GetBattlePassRewardItemDesc( reward )
	string headerText = GetBattlePassRewardHeaderText( reward )

	HudElem_SetRuiArg( file.detailBox, "headerText", headerText )
	HudElem_SetRuiArg( file.detailBox, "titleText", itemName )
	HudElem_SetRuiArg( file.detailBox, "descText", itemDesc )
	HudElem_SetRuiArg( file.detailBox, "rarity", rarity )

	HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityBulletText2", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityBulletText3", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText2", "" )
	HudElem_SetRuiArg( file.detailBox, "rarityPercentText3", "" )

	if ( ItemFlavor_GetType( reward.flav ) == eItemType.account_pack )
	{
		if ( rarity == 1 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#LOOT_RARITY_CHANCE_1" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText2", Localize( "#LOOT_RARITY_CHANCE_2" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText3", Localize( "#LOOT_RARITY_CHANCE_3" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", Localize( "#LOOT_RARITY_PERCENT_1" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText2", Localize( "#LOOT_RARITY_PERCENT_2" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText3", Localize( "#LOOT_RARITY_PERCENT_3" ) )
		}
		else if ( rarity == 2 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#LOOT_RARITY_CHANCE_2" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText2", Localize( "#LOOT_RARITY_CHANCE_3" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", Localize( "#LOOT_RARITY_PERCENT_1" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText2", Localize( "#LOOT_RARITY_PERCENT_3" ) )
		}
		else if ( rarity == 3 )
		{
			HudElem_SetRuiArg( file.detailBox, "rarityBulletText1", Localize( "#LOOT_RARITY_CHANCE_3" ) )
			HudElem_SetRuiArg( file.detailBox, "rarityPercentText1", Localize( "#LOOT_RARITY_PERCENT_1" ) )
		}
	}

	HudElem_SetRuiArg( file.levelReqButton, "buttonText", Localize( "#BATTLE_PASS_LEVEL_REQUIRED", reward.level + 1 ) )
	HudElem_SetRuiArg( file.levelReqButton, "meetsRequirement", battlePassLevel >= reward.level )
	HudElem_SetRuiArg( file.levelReqButton, "isPremium", false )

	if ( reward.isPremium && hasPremiumPass )
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_PREMIUM_REWARD" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", true )
	}
	else if ( reward.isPremium && !hasPremiumPass )
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_PREMIUM_REQUIRED" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", false )
	}
	else
	{
		HudElem_SetRuiArg( file.premiumReqButton, "buttonText", "#BATTLE_PASS_FREE_REWARD" )
		HudElem_SetRuiArg( file.premiumReqButton, "meetsRequirement", true )
	}

	HudElem_SetRuiArg( file.premiumReqButton, "isPremium", reward.isPremium )

	bool isLoadScreen = (ItemFlavor_GetType( reward.flav ) == eItemType.loadscreen)
	Hud_SetVisible( file.loadscreenPreviewBox, isLoadScreen )
	Hud_SetVisible( file.loadscreenPreviewBoxOverlay, isLoadScreen )

	bool shouldPlayAudioPreview = !wasFocusForced
	RunClientScript( "UIToClient_ItemPresentation", ItemFlavor_GetGUID( reward.flav ), reward.level, false, file.loadscreenPreviewBox, shouldPlayAudioPreview )

	UpdateFooterOptions() //
}


void function BattlePass_RewardButton_OnLoseFocus( var button )
{
	//
	//

	UpdateFooterOptions() //
}

void function BattlePass_FocusRewardButton( RewardButtonData rbd )
{
	//

	file.currentRewardButtonKey = null
	if ( GetFocus() != rbd.button )
		Hud_SetFocused( rbd.button )
	else
		BattlePass_RewardButton_OnGetFocus( rbd.button )

	HudElem_SetRuiArg( rbd.button, "forceFocusShineMarker", RandomInt( INT_MAX ) )

	//
	//
	//
	//
	//
}

void function BattlePass_RewardButton_OnActivate( var button )
{
	RewardButtonData rbd    = file.rewardButtonToDataMap[button]
	BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]
	if ( ItemFlavor_GetType( reward.flav ) == eItemType.loadscreen )
	{
		LoadscreenPreviewMenu_SetLoadscreenToPreview( reward.flav )
		AdvanceMenu( GetMenu( "LoadscreenPreviewMenu" ) )
	}
	else if ( InspectItemTypePresentationSupported( reward.flav ) && ItemFlavor_GetType( reward.flav ) != eItemType.account_currency )
	{
		SetBattlePassItemPresentationModeActive( reward )
	}
}


void function BattlePass_RewardButton_OnAltActivate( var button )
{
	RewardButtonData rbd    = file.rewardButtonToDataMap[button]
	BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]

	if ( !BattlePass_CanEquipReward( reward ) )
		return

	ItemFlavor item           = reward.flav
	array<LoadoutEntry> entry = GetAppropriateLoadoutSlotsForItemFlavor( item )

	if ( entry.len() == 0 )
		return

	if ( entry.len() == 1 )
	{
		EmitUISound( "UI_Menu_Equip_Generic" )
		RequestSetItemFlavorLoadoutSlot( ToEHI( GetUIPlayer() ), entry[ 0 ], item )
	}
	else
	{
		//
		OpenSelectSlotDialog( entry, item, GetItemFlavorAssociatedCharacter( item ),
					(void function( int index ) : ( entry, item )
			{
				EmitUISound( "UI_Menu_Equip_Generic" )
				//RequestSetItemFlavorLoadoutSlot_WithDuplicatePrevention( ToEHI( GetUIPlayer() ), entry, item, index )
			})
		)
	}
}


bool function BattlePass_IsFocusedItemInspectable()
{
	var focusedPanel = GetFocus()
	if ( focusedPanel in file.rewardButtonToDataMap )
	{
		RewardButtonData rbd    = file.rewardButtonToDataMap[focusedPanel]
		BattlePassReward reward = rbd.rewardGroup.rewards[rbd.rewardSubIdx]
		return (ItemFlavor_GetType( reward.flav ) == eItemType.loadscreen || InspectItemTypePresentationSupported( reward.flav ))
	}
	return false
}


bool function BattlePass_IsFocusedItemEquippable()
{
	var focusedPanel = GetFocus()
	if ( focusedPanel in file.rewardButtonToDataMap )
	{
		RewardButtonData rbd = file.rewardButtonToDataMap[focusedPanel]
		return BattlePass_CanEquipReward( rbd.rewardGroup.rewards[rbd.rewardSubIdx] )
	}
	return false
}


bool function BattlePass_CanEquipReward( BattlePassReward reward )
{
	ItemFlavor item           = reward.flav
	int itemType              = ItemFlavor_GetType( item )
	array<LoadoutEntry> entry = GetAppropriateLoadoutSlotsForItemFlavor( item )

	if ( entry.len() == 0 )
		return false

	return GRX_IsItemOwnedByPlayer_AllowOutOfDateData( item )
}


string function BattlePass_GetShortDescString( BattlePassReward reward )
{
	switch( ItemFlavor_GetType( reward.flav ) )
	{
		case eItemType.weapon_skin:
			ItemFlavor ref = WeaponSkin_GetWeaponFlavor( reward.flav )
			return Localize( "#REWARD_SKIN", Localize( ItemFlavor_GetLongName( ref ) ) )

		case eItemType.character_skin:
			ItemFlavor ref = CharacterSkin_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_SKIN", Localize( ItemFlavor_GetLongName( ref ) ) )

		case eItemType.gladiator_card_stat_tracker:
			ItemFlavor ref = GladiatorCardStatTracker_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_TRACKER", Localize( ItemFlavor_GetLongName( ref ) ) )

		case eItemType.gladiator_card_intro_quip:
			ItemFlavor ref = CharacterIntroQuip_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_QUIP", Localize( ItemFlavor_GetLongName( ref ) ) )

		case eItemType.gladiator_card_kill_quip:
			ItemFlavor ref = CharacterKillQuip_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_QUIP", Localize( ItemFlavor_GetLongName( ref ) ) )

		case eItemType.gladiator_card_frame:
			ItemFlavor ref = GladiatorCardFrame_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_FRAME", Localize( ItemFlavor_GetLongName( ref ) ) )

		case eItemType.gladiator_card_stance:
			ItemFlavor ref = GladiatorCardStance_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_STANCE", Localize( ItemFlavor_GetLongName( ref ) ) )

		case eItemType.gladiator_card_badge:
			return Localize( "#REWARD_BADGE" )

		case eItemType.music_pack:
			return Localize( "#itemtype_music_pack_NAME" )

		case eItemType.loadscreen:
			return Localize( "#itemtype_loadscreen_NAME" )

		case eItemType.skydive_emote:
			ItemFlavor ref = CharacterSkydiveEmote_GetCharacterFlavor( reward.flav )
			return Localize( "#REWARD_SKYDIVE_EMOTE", Localize( ItemFlavor_GetLongName( ref ) ) )
	}

	return ""
}

string function GetBattlePassRewardHeaderText( BattlePassReward reward )
{
	string headerText = BattlePass_GetShortDescString( reward )
	if ( ItemFlavor_HasQuality( reward.flav ) )
	{
		string rarityName = ItemFlavor_GetQualityName( reward.flav )
		if ( headerText == "" )
			headerText = Localize( "#BATTLE_PASS_ITEM_HEADER", Localize( rarityName ) )
		else
			headerText = Localize( "#BATTLE_PASS_ITEM_HEADER_DESC", Localize( rarityName ), headerText )
	}

	return headerText
}


string function GetBattlePassRewardItemName( BattlePassReward reward )
{
	return ItemFlavor_GetLongName( reward.flav )
}


string function GetBattlePassRewardItemDesc( BattlePassReward reward )
{
	string itemDesc = ItemFlavor_GetLongDescription( reward.flav )
	if ( ItemFlavor_GetType( reward.flav ) == eItemType.account_currency )
	{
		if ( reward.flav == GetItemFlavorByAsset( $"settings/itemflav/grx_currency/crafting.rpak" ) )
			itemDesc = GetFormattedValueForCurrency( reward.quantity, GRX_CURRENCY_CRAFTING )
		else
			itemDesc = GetFormattedValueForCurrency( reward.quantity, GRX_CURRENCY_PREMIUM )
	}
	else if ( ItemFlavor_GetType( reward.flav ) == eItemType.xp_boost )
		itemDesc = Localize( itemDesc, int( BATTLEPASS_XP_BOOST_AMOUNT * 100 ) )

	return itemDesc
}


array<RewardGroup> function GetRewardGroupsForPage( int pageNumber )
{
	array<RewardGroup> rewardGroups

	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
		return rewardGroups
	expect ItemFlavor( activeBattlePass )

	int levelOffset    = GetLevelOffsetForPage( activeBattlePass, pageNumber )
	int endLevelOffset = GetNumLevelsForPage( activeBattlePass, pageNumber )
	for ( int levelIdx = levelOffset; levelIdx < endLevelOffset; levelIdx++ )
	{
		RewardGroup rewardGroup
		rewardGroup.level = levelIdx
		rewardGroup.rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		rewardGroups.append( rewardGroup )
	}

	return rewardGroups
}


int function GetLevelOffsetForPage( ItemFlavor activeBattlePass, int pageIdx )
{
	array<int> pageToLevelIdx = [0]
	int rewardCount           = 0
	for ( int levelIdx = 0; levelIdx < GetBattlePassMaxLevelIndex( activeBattlePass ); levelIdx++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		if ( rewardCount + rewards.len() <= REWARDS_PER_PAGE )
		{
			rewardCount += rewards.len()
		}
		else
		{
			pageToLevelIdx.append( levelIdx )
			rewardCount = rewards.len()
		}
	}

	return pageToLevelIdx[pageIdx]
}


int function GetNumPages( ItemFlavor activeBattlePass )
{
	array<int> pageToLevelIdx = [0]
	int rewardCount           = 0
	for ( int levelIdx = 0; levelIdx < GetBattlePassMaxLevelIndex( activeBattlePass ); levelIdx++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		if ( rewardCount + rewards.len() <= REWARDS_PER_PAGE )
		{
			rewardCount += rewards.len()
		}
		else
		{
			pageToLevelIdx.append( levelIdx )
			rewardCount = rewards.len()
		}
	}

	return pageToLevelIdx.len()
}


int function GetNumLevelsForPage( ItemFlavor activeBattlePass, int pageIdx )
{
	int rewardCount = 0
	int levelIdx    = GetLevelOffsetForPage( activeBattlePass, pageIdx )
	for ( ; levelIdx <= GetBattlePassMaxLevelIndex( activeBattlePass ) && rewardCount < REWARDS_PER_PAGE; levelIdx++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		rewardCount += rewards.len()

		if ( rewardCount > REWARDS_PER_PAGE )
			return levelIdx
	}

	return levelIdx
}


array<RewardGroup> function GetEmptyRewardGroups()
{
	array<RewardGroup> rewardGroups
	BattlePassReward emptyReward

	for ( int levelIdx = 0; levelIdx < 10; levelIdx++ )
	{
		RewardGroup rewardGroup
		rewardGroup.level = levelIdx
		rewardGroup.rewards.append( emptyReward )
		if ( levelIdx % 2 )
		{
			rewardGroup.rewards.append( emptyReward )
		}
		rewardGroups.append( rewardGroup )
	}

	return rewardGroups
}

void function BattlePass_UpdatePageOnOpen()
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
	{
		BattlePass_SetPage( 0 )
		return
	}
	expect ItemFlavor( activeBattlePass )
	int currentLevel    = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false ) + 1
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )

	int desiredPageNum                 = -1
	string desiredFocusRewardButtonKey = ""

	if ( uiGlobal.lastMenuNavDirection == MENU_NAV_BACK
			&& file.currentPage != -1 && file.currentRewardButtonKey != null )
	{
		desiredPageNum = file.currentPage
		desiredFocusRewardButtonKey = expect string(file.currentRewardButtonKey)
	}
	else
	{
		if ( hasPremiumPass )
			desiredPageNum = BattlePass_GetPageForLevel( activeBattlePass, currentLevel )
		else
			desiredPageNum = 0
	}

	BattlePass_SetPage( desiredPageNum )
	if ( desiredFocusRewardButtonKey != "" )
	{
		Assert( desiredFocusRewardButtonKey in file.rewardKeyToRewardButtonDataMap, format( "Tried to focus reward button '%s' on page %d'", desiredFocusRewardButtonKey, desiredPageNum ) )
		BattlePass_FocusRewardButton( file.rewardKeyToRewardButtonDataMap[desiredFocusRewardButtonKey] )
	}
}


int function BattlePass_GetPageForLevel( ItemFlavor activeBattlePass, int level )
{
	for ( int pageNum = 0 ; pageNum < GetNumPages( activeBattlePass ) ; pageNum++ )
	{
		int startLevel = GetLevelOffsetForPage( activeBattlePass, pageNum )
		int endLevel   = GetNumLevelsForPage( activeBattlePass, pageNum )
		if ( level >= startLevel && level <= endLevel )
			return pageNum
	}

	return GetNumPages( activeBattlePass )
}


int function BattlePass_GetNextLevelWithReward( ItemFlavor activeBattlePass, int currentLevelIdx )
{
	int maxLevelIdx = GetBattlePassMaxLevelIndex( activeBattlePass )
	maxLevelIdx += 1 //
	for ( int levelIdx = currentLevelIdx; levelIdx <= maxLevelIdx; levelIdx++ )
	{
		array<BattlePassReward> rewards = GetBattlePassLevelRewards( activeBattlePass, levelIdx, GetUIPlayer() )
		if ( rewards.len() > 0 )
			return levelIdx
	}

	return minint( currentLevelIdx, maxLevelIdx )
}


void function BattlePass_SetPage( int pageNumber )
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null )
	{
		file.currentPage = 0
		return
	}

	expect ItemFlavor( activeBattlePass )

	int numPages = GetNumPages( activeBattlePass )
	pageNumber = ClampInt( pageNumber, 0, numPages - 1 )
	file.previousPage = file.currentPage
	file.currentPage = pageNumber

	file.currentRewardGroups = GetRewardGroupsForPage( pageNumber )

	UpdateRewardPanel( file.currentRewardGroups )
	bool prevPageAvailable = (pageNumber > 0)
	bool nextPageButton    = (pageNumber < numPages - 1)
	Hud_SetVisible( file.prevPageButton, prevPageAvailable )
	Hud_SetEnabled( file.invisiblePageLeftTriggerButton, prevPageAvailable )
	Hud_SetVisible( file.nextPageButton, nextPageButton )
	Hud_SetEnabled( file.invisiblePageRightTriggerButton, nextPageButton )

	int startLevel = GetLevelOffsetForPage( activeBattlePass, pageNumber )
	int endLevel   = GetNumLevelsForPage( activeBattlePass, pageNumber )

	HudElem_SetRuiArg( file.rewardBarFooter, "currentPage", pageNumber )
	HudElem_SetRuiArg( file.rewardBarFooter, "levelRangeText", Localize( "#BATTLE_PASS_LEVEL_RANGE", startLevel + 1, endLevel ) )
	HudElem_SetRuiArg( file.rewardBarFooter, "numPages", GetNumPages( activeBattlePass ) )
}
#endif


#if(UI)
void function OnPanelShow( var panel )
{
	UI_SetPresentationType( ePresentationType.BATTLE_PASS )
	//

	RegisterButtonPressedCallback( MOUSE_WHEEL_DOWN, BattlePass_PageForward )
	RegisterButtonPressedCallback( MOUSE_WHEEL_UP, BattlePass_PageBackward )
	RegisterButtonPressedCallback( BUTTON_TRIGGER_LEFT, BattlePass_PageBackward )
	RegisterButtonPressedCallback( BUTTON_TRIGGER_RIGHT, BattlePass_PageForward )

	BattlePass_UpdatePageOnOpen()
	BattlePass_UpdateStatus()
	BattlePass_UpdatePurchaseButton()

	AddCallbackAndCallNow_OnGRXOffersRefreshed( OnGRXStateChanged )
	AddCallbackAndCallNow_OnGRXInventoryStateChanged( OnGRXStateChanged )

	//
}


void function OnPanelHide( var panel )
{
	RunClientScript( "UIToClient_StopBattlePassScene" )

	DeregisterButtonPressedCallback( MOUSE_WHEEL_DOWN, BattlePass_PageForward )
	DeregisterButtonPressedCallback( MOUSE_WHEEL_UP, BattlePass_PageBackward )
	DeregisterButtonPressedCallback( BUTTON_TRIGGER_LEFT, BattlePass_PageBackward )
	DeregisterButtonPressedCallback( BUTTON_TRIGGER_RIGHT, BattlePass_PageForward )

	RemoveCallback_OnGRXOffersRefreshed( OnGRXStateChanged )
	RemoveCallback_OnGRXInventoryStateChanged( OnGRXStateChanged )
}


void function OnGRXStateChanged()
{
	bool ready = GRX_IsInventoryReady() && GRX_AreOffersReady()

	if ( !ready )
		return

	thread TryDisplayBattlePassAwards()
}


void function BattlePass_UpdatePurchaseButton()
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
	{
		Hud_SetEnabled( file.purchaseButton, false )
		Hud_SetVisible( file.purchaseButton, false )
		HudElem_SetRuiArg( file.purchaseButton, "buttonText", "#COMING_SOON" )
		return
	}

	expect ItemFlavor( activeBattlePass )

	Hud_SetEnabled( file.purchaseButton, true )
	Hud_SetVisible( file.purchaseButton, true )
	Hud_SetLocked( file.purchaseButton, false )
	Hud_ClearToolTipData( file.purchaseButton )

	if ( GRX_IsItemOwnedByPlayer( activeBattlePass ) )
	{
		HudElem_SetRuiArg( file.purchaseButton, "buttonText", "#BATTLE_PASS_BUTTON_PURCHASE_XP" )

		if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) == 0 )
		{
			Hud_SetLocked( file.purchaseButton, true )
			ToolTipData toolTipData
			toolTipData.titleText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL"
			toolTipData.descText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL_DESC"
			Hud_SetToolTipData( file.purchaseButton, toolTipData )
		}
	}
	else
	{
		HudElem_SetRuiArg( file.purchaseButton, "buttonText", "#BATTLE_PASS_BUTTON_PURCHASE" )

		if ( GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false ) > 0 )
		{
			ToolTipData toolTipData
			toolTipData.titleText = "#BATTLE_PASS_BUTTON_PURCHASE"
			toolTipData.descText = "#BUTTON_BATTLE_PASS_PURCHASE_DESC"
			Hud_SetToolTipData( file.purchaseButton, toolTipData )
		}
	}
}

void function BattlePass_UpdateStatus()
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null

	if ( !hasActiveBattlePass )
		return

	expect ItemFlavor(activeBattlePass)

	int currentBattlePassXP = GetPlayerBattlePassXPProgress( ToEHI( GetUIPlayer() ), activeBattlePass, false )

	int ending_passLevel = GetBattlePassLevelForXP( activeBattlePass, currentBattlePassXP )
	int ending_passXP    = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel - 1 )

	int ending_nextPassLevelXP
	if ( ending_passLevel > GetBattlePassMaxLevelIndex( activeBattlePass ) )
		ending_nextPassLevelXP = ending_passXP
	else
		ending_nextPassLevelXP = GetTotalXPToCompletePassLevel( activeBattlePass, ending_passLevel )

	int xpToCompleteLevel = ending_nextPassLevelXP - ending_passXP
	int xpForLevel        = currentBattlePassXP - ending_passXP

	Assert( currentBattlePassXP >= ending_passXP )
	Assert( currentBattlePassXP <= ending_nextPassLevelXP )
	float ending_passLevelFrac = GraphCapped( currentBattlePassXP, ending_passXP, ending_nextPassLevelXP, 0.0, 1.0 )

	//
	//
	//
	//
	//

	ItemFlavor currentSeason = GetLatestSeason( GetUnixTimestamp() )
	int seasonEndUnixTime    = CalEvent_GetFinishUnixTime( currentSeason )
	int remainingSeasonTime  = seasonEndUnixTime - GetUnixTimestamp()

	if ( remainingSeasonTime > 0 )
	{
		DisplayTime dt = SecondsToDHMS( remainingSeasonTime )
		HudElem_SetRuiArg( file.statusBox, "timeRemainingText", Localize( "#DAYS_REMAINING", string( dt.days ), string( dt.hours ) ) )
	}
	else
	{
		HudElem_SetRuiArg( file.statusBox, "timeRemainingText", Localize( "#BATTLE_PASS_SEASON_ENDED" ) )
	}

	HudElem_SetRuiArg( file.statusBox, "seasonNameText", ItemFlavor_GetLongName( activeBattlePass ) )
	HudElem_SetRuiArg( file.statusBox, "seasonNumberText", Localize( ItemFlavor_GetShortName( activeBattlePass ) ) )
	HudElem_SetRuiArg( file.statusBox, "smallLogo", GetGlobalSettingsAsset( ItemFlavor_GetAsset( activeBattlePass ), "smallLogo" ), eRuiArgType.IMAGE )
	HudElem_SetRuiArg( file.statusBox, "bannerImage", GetGlobalSettingsAsset( ItemFlavor_GetAsset( activeBattlePass ), "bannerImage" ), eRuiArgType.IMAGE )

	ItemFlavor dummy
	ItemFlavor bpLevelBadge = GetBattlePassProgressBadge( activeBattlePass )

	RuiDestroyNestedIfAlive( Hud_GetRui( file.statusBox ), "currentBadgeHandle" )
	CreateNestedGladiatorCardBadge( Hud_GetRui( file.statusBox ), "currentBadgeHandle", ToEHI( GetUIPlayer() ), bpLevelBadge, 0, dummy, ending_passLevel + 1 )
}
#endif


#if(UI)
struct
{
	var menu
	var rewardPanel
	var header
	var background

	var purchaseButton
	var incButton
	var decButton

	table<var, BattlePassReward> buttonToItem

	int purchaseQuantity = 1

	bool closeOnGetTopLevel = false

} s_passPurchaseXPDialog
#endif


#if(UI)
void function InitPassXPPurchaseDialog( var newMenuArg )
//
{
	var menu = GetMenu( "PassXPPurchaseDialog" )
	s_passPurchaseXPDialog.menu = menu
	s_passPurchaseXPDialog.rewardPanel = Hud_GetChild( menu, "RewardList" )
	s_passPurchaseXPDialog.header = Hud_GetChild( menu, "Header" )
	s_passPurchaseXPDialog.background = Hud_GetChild( menu, "Background" )

	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PassXPPurchaseDialog_OnOpen )

	AddMenuEventHandler( menu, eUIEvent.MENU_GET_TOP_LEVEL, PassXPPurchaseDialog_OnGetTopLevel )

	//

	//

	s_passPurchaseXPDialog.purchaseButton = Hud_GetChild( menu, "PurchaseButton" )
	Hud_AddEventHandler( s_passPurchaseXPDialog.purchaseButton, UIE_CLICK, PassXPPurchaseButton_OnActivate )

	s_passPurchaseXPDialog.incButton = Hud_GetChild( menu, "IncButton" )
	Hud_AddEventHandler( s_passPurchaseXPDialog.incButton, UIE_CLICK, PassXPIncButton_OnActivate )

	s_passPurchaseXPDialog.decButton = Hud_GetChild( menu, "DecButton" )
	Hud_AddEventHandler( s_passPurchaseXPDialog.decButton, UIE_CLICK, PassXPDecButton_OnActivate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
	AddMenuFooterOption( menu, LEFT, BUTTON_A, true, "#A_BUTTON_PURCHASE", "", PassXPPurchaseButton_OnActivate )
	AddMenuFooterOption( menu, LEFT, BUTTON_TRIGGER_RIGHT, true, "", "", PassXPIncButton_OnActivate )
	AddMenuFooterOption( menu, LEFT, BUTTON_TRIGGER_LEFT, true, "", "", PassXPDecButton_OnActivate )
}


void function PassXPPurchaseDialog_OnOpen()
{
	s_passPurchaseXPDialog.purchaseQuantity = 1

	PassXPPurchaseDialog_UpdateRewards()
}


void function PassXPPurchaseDialog_OnGetTopLevel()
{
	if ( s_passPurchaseXPDialog.closeOnGetTopLevel )
	{
		s_passPurchaseXPDialog.closeOnGetTopLevel = false
		CloseActiveMenu()
	}
}


void function PassXPPurchaseDialog_UpdateRewards()
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return
	expect ItemFlavor( activeBattlePass )

	ItemFlavor xpPurchaseFlav              = BattlePass_GetXPPurchaseFlav( activeBattlePass )
	array<GRXScriptOffer> xpPurchaseOffers = GRX_GetItemDedicatedStoreOffers( xpPurchaseFlav, "battlepass" )
	Assert( xpPurchaseOffers.len() == 1 )
	if ( xpPurchaseOffers.len() < 1 )
	{
		Warning( "No offer for xp purchase for '%s'", ItemFlavor_GetHumanReadableRef( activeBattlePass ) )
		return
	}
	GRXScriptOffer xpPurchaseOffer = xpPurchaseOffers[0]
	Assert( xpPurchaseOffer.prices.len() == 1 )
	if ( xpPurchaseOffer.prices.len() < 1 )
		return

	int startingPurchaseLevelIdx = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	int maxPurchasableLevels     = GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass )

	if ( s_passPurchaseXPDialog.purchaseQuantity == maxPurchasableLevels )
	{
		ToolTipData toolTipData
		toolTipData.titleText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL"
		toolTipData.descText = "#BATTLE_PASS_MAX_PURCHASE_LEVEL_DESC"
		Hud_SetToolTipData( s_passPurchaseXPDialog.incButton, toolTipData )
	}
	else
	{
		Hud_ClearToolTipData( s_passPurchaseXPDialog.incButton )
	}

	if ( s_passPurchaseXPDialog.purchaseQuantity == 1 )
	{
		HudElem_SetRuiArg( s_passPurchaseXPDialog.purchaseButton, "quantityText", Localize( "#BATTLE_PASS_PLUS_N_LEVEL", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "titleText", Localize( "#BATTLE_PASS_PURCHASE_LEVEL", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "descText", Localize( "#BATTLE_PASS_PURCHASE_LEVEL_DESC", s_passPurchaseXPDialog.purchaseQuantity, (startingPurchaseLevelIdx + 1) + s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.background, "headerText", "#BATTLE_PASS_YOU_WILL_RECEIVE" )
	}
	else
	{
		HudElem_SetRuiArg( s_passPurchaseXPDialog.purchaseButton, "quantityText", Localize( "#BATTLE_PASS_PLUS_N_LEVELS", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "titleText", Localize( "#BATTLE_PASS_PURCHASE_LEVELS", s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.header, "descText", Localize( "#BATTLE_PASS_PURCHASE_LEVELS_DESC", s_passPurchaseXPDialog.purchaseQuantity, (startingPurchaseLevelIdx + 1) + s_passPurchaseXPDialog.purchaseQuantity ) )
		HudElem_SetRuiArg( s_passPurchaseXPDialog.background, "headerText", "#BATTLE_PASS_YOU_WILL_RECEIVE" )
	}

	HudElem_SetRuiArg( s_passPurchaseXPDialog.purchaseButton, "buttonText", GRX_GetFormattedPrice( xpPurchaseOffer.prices[0], s_passPurchaseXPDialog.purchaseQuantity ) )

	array<BattlePassReward> rewards
	array<BattlePassReward> allRewards
	for ( int index = 1; index <= s_passPurchaseXPDialog.purchaseQuantity; index++ )
	{
		allRewards.extend( GetBattlePassLevelRewards( activeBattlePass, startingPurchaseLevelIdx + index ) )
	}

	foreach ( reward in allRewards )
	{
		rewards.append( reward )
	}

	var scrollPanel = Hud_GetChild( s_passPurchaseXPDialog.rewardPanel, "ScrollPanel" )

	//
	//
	s_passPurchaseXPDialog.buttonToItem.clear()

	int numRewards = rewards.len()

	Hud_InitGridButtonsDetailed( s_passPurchaseXPDialog.rewardPanel, numRewards, 2, minint( numRewards, 5 ) )
	for ( int index = 0; index < numRewards; index++ )
	{
		var button = Hud_GetChild( scrollPanel, "GridButton" + index )
		//
		//

		BattlePassReward bpReward = rewards[index]
		s_passPurchaseXPDialog.buttonToItem[button] <- bpReward

		HudElem_SetRuiArg( button, "isOwned", true )
		HudElem_SetRuiArg( button, "isPremium", bpReward.isPremium )

		int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
		HudElem_SetRuiArg( button, "rarity", rarity )
		RuiSetImage( Hud_GetRui( button ), "buttonImage", GetImageForBattlePassReward( bpReward ) )

		if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
			HudElem_SetRuiArg( button, "isLootBox", true )

		HudElem_SetRuiArg( button, "itemCountString", "" )
		if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
			HudElem_SetRuiArg( button, "itemCountString", string( bpReward.quantity ) )

		ToolTipData toolTip
		toolTip.titleText = GetBattlePassRewardHeaderText( bpReward )
		toolTip.descText = GetBattlePassRewardItemName( bpReward )
		Hud_SetToolTipData( button, toolTip )
	}
}


void function InitBattlePassRewardButtonRui( var rui, BattlePassReward bpReward )
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	bool hasActiveBattlePass           = activeBattlePass != null && GRX_IsInventoryReady()
	bool hasPremiumPass                = false
	int battlePassLevel                = 0
	if ( hasActiveBattlePass )
	{
		expect ItemFlavor( activeBattlePass )
		hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )
		battlePassLevel = GetPlayerBattlePassLevel( GetUIPlayer(), activeBattlePass, false )
	}

	bool isOwned = (!bpReward.isPremium || hasPremiumPass) && bpReward.level <= battlePassLevel
	RuiSetBool( rui, "isOwned", isOwned )
	RuiSetBool( rui, "isPremium", bpReward.isPremium )

	int rarity = ItemFlavor_HasQuality( bpReward.flav ) ? ItemFlavor_GetQuality( bpReward.flav ) : 0
	RuiSetInt( rui, "rarity", rarity )
	RuiSetImage( rui, "buttonImage", GetImageForBattlePassReward( bpReward ) )

	if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_pack )
		RuiSetBool( rui, "isLootBox", true )

	RuiSetString( rui, "itemCountString", "" )
	if ( ItemFlavor_GetType( bpReward.flav ) == eItemType.account_currency )
		RuiSetString( rui, "itemCountString", string( bpReward.quantity ) )
}



void function PassXPPurchaseButton_OnActivate( var something )
{
	if ( Hud_IsLocked( s_passPurchaseXPDialog.purchaseButton ) )
		return

	if ( GetFocus() == s_passPurchaseXPDialog.incButton || GetFocus() == s_passPurchaseXPDialog.decButton )
		return

	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	Assert( activeBattlePass != null )
	expect ItemFlavor( activeBattlePass )

	ItemFlavor purchasedXPFlav = BattlePass_GetXPPurchaseFlav( activeBattlePass )

	//
	if ( !GRX_GetItemPurchasabilityInfo( purchasedXPFlav ).isPurchasableAtAll )
	{
		Warning( "Expected offer for XP purchase for '%s'", ItemFlavor_GetHumanReadableRef( purchasedXPFlav ) )
		return
	}

	if ( IsDialog( GetActiveMenu() ) )
		CloseActiveMenu()

	int quantity = s_passPurchaseXPDialog.purchaseQuantity
	PurchaseDialog( purchasedXPFlav, quantity, false, null, OnBattlePassXPPurchaseResult )
}


void function OnBattlePassXPPurchaseResult( bool wasSuccessful )
{
	if ( wasSuccessful )
		s_passPurchaseXPDialog.closeOnGetTopLevel = true
}


void function PassXPIncButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )

	int maxPurchasableLevels = GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass )
	s_passPurchaseXPDialog.purchaseQuantity = minint( s_passPurchaseXPDialog.purchaseQuantity + 1, maxPurchasableLevels )

	PassXPPurchaseDialog_UpdateRewards()
}


void function PassXPDecButton_OnActivate( var button )
{
	s_passPurchaseXPDialog.purchaseQuantity = maxint( s_passPurchaseXPDialog.purchaseQuantity - 1, 1 )

	PassXPPurchaseDialog_UpdateRewards()
}
#endif

#if(UI)

void function InitAboutBattlePass1Dialog( var newMenuArg )
//
{
	var menu = GetMenu( "BattlePassAboutPage1" )
	SetDialog( menu, true )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, AboutBattlePass1Dialog_OnOpen )
	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function AboutBattlePass1Dialog_OnOpen()
{
	var menu = GetMenu( "BattlePassAboutPage1" )
	var rui  = Hud_GetRui( Hud_GetChild( menu, "InfoPanel" ) )

	RuiSetBool( rui, "grxOfferRestricted", GRX_IsOfferRestricted() )
}

#endif


#if(UI)
void function ShowRewardTable( var button )
{
	//
}
#endif


#if(CLIENT)
void function UIToClient_StartBattlePassScene( var panel )
{
	//
	//
}
#endif


#if(CLIENT)
void function UIToClient_StopBattlePassScene()
{
	//
	Signal( fileLevel.signalDummy, "StopBattlePassSceneThread" )
	ClearBattlePassItem()
}
#endif


#if(CLIENT)
//
//
//
//
//
//
struct CarouselColumnState
{
	int    level = -1
	var    topo
	var    rui
	var    columnClickZonePanel
	entity reward1Model
	var    reward1DetailsPanel
	entity reward2Model
	var    reward2DetailsPanel
	entity light
	float  growSize = 0.0
}


void function BattlePassScene_Thread( var panel )
{
	Signal( fileLevel.signalDummy, "StopBattlePassSceneThread" ) //
	EndSignal( fileLevel.signalDummy, "StopBattlePassSceneThread" )

	fileLevel.isBattlePassSceneThreadActive = true

	entity cam = clGlobal.menuCamera
	//
	//
	//

	float camSceneDist = 100.0
	vector camOrg      = cam.GetOrigin()
	vector camAng      = cam.GetAngles()
	vector camForward  = AnglesToForward( camAng )
	vector camRight    = AnglesToRight( camAng )
	vector camUp       = AnglesToUp( camAng )

	float bgSize       = 10000.0
	vector bgCenterPos = camOrg + 300.0 * camForward - bgSize * 0.5 * camRight + bgSize * 0.5 * camUp
	var bgTopo         = RuiTopology_CreatePlane( bgCenterPos, bgSize * camRight, bgSize * -camUp, false )
	DebugDrawAxis( camOrg + camSceneDist * camForward )
	var bgRui = RuiCreate( $"ui/lobby_battlepass_temp_bg.rpak", bgTopo, RUI_DRAW_WORLD, 10000 )
	RuiSetFloat3( bgRui, "pos", bgCenterPos )
	RuiKeepSortKeyUpdated( bgRui, true, "pos" )

	OnThreadEnd( function() : ( bgTopo, bgRui ) {
		fileLevel.isBattlePassSceneThreadActive = false

		RuiDestroy( bgRui )
		RuiTopology_Destroy( bgTopo )
	} )

	WaitForever()
}
#endif


#if(CLIENT)
void function OnMouseWheelUp( entity unused )
{
	//
}
#endif


#if(CLIENT)
void function OnMouseWheelDown( entity unused )
{
	//
}
#endif

#if(UI)
struct
{
	var menu
	var rewardPanel
	var passPurchaseButton
	var bundlePurchaseButton
	var seasonLogoBox
	var offersBorders

	bool closeOnGetTopLevel = false
} s_passPurchaseMenu

void function InitPassPurchaseMenu( var newMenuArg )
//
{
	var menu = GetMenu( "PassPurchaseMenu" )
	AddMenuEventHandler( menu, eUIEvent.MENU_OPEN, PassPurchaseMenu_OnOpen )
	AddMenuEventHandler( menu, eUIEvent.MENU_GET_TOP_LEVEL, PassPurchaseMenu_OnGetTopLevel )

	s_passPurchaseMenu.menu = menu
	s_passPurchaseMenu.passPurchaseButton = Hud_GetChild( menu, "PassPurchaseButton" )
	s_passPurchaseMenu.bundlePurchaseButton = Hud_GetChild( menu, "BundlePurchaseButton" )
	s_passPurchaseMenu.seasonLogoBox = Hud_GetChild( menu, "SeasonLogo" )
	s_passPurchaseMenu.offersBorders = Hud_GetChild( menu, "OffersBorders" )

	Hud_AddEventHandler( s_passPurchaseMenu.passPurchaseButton, UIE_CLICK, PassPurchaseButton_OnActivate )
	Hud_AddEventHandler( s_passPurchaseMenu.bundlePurchaseButton, UIE_CLICK, BundlePurchaseButton_OnActivate )

	AddMenuFooterOption( menu, LEFT, BUTTON_B, true, "#B_BUTTON_BACK", "#B_BUTTON_BACK" )
}


void function PassPurchaseButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )

	if ( !CanPlayerPurchaseBattlePass( GetUIPlayer(), activeBattlePass ) )
		return

	ItemFlavor purchasePack = BattlePass_GetBasicPurchasePack( activeBattlePass )
	if ( !GRX_GetItemPurchasabilityInfo( purchasePack ).isPurchasableAtAll )
		return
	PurchaseDialog( purchasePack, 1, false, null, OnBattlePassPurchaseResults )
	PurchaseDialog_SetPurchaseOverrideSound( "UI_Menu_BattlePass_Purchase" )
}


void function BundlePurchaseButton_OnActivate( var button )
{
	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )

	if ( !CanPlayerPurchaseBattlePass( GetUIPlayer(), activeBattlePass ) )
		return

	if ( GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) < 25 )
		return

	ItemFlavor purchasePack = BattlePass_GetBundlePurchasePack( activeBattlePass )
	if ( !GRX_GetItemPurchasabilityInfo( purchasePack ).isPurchasableAtAll )
		return
	PurchaseDialog( purchasePack, 1, false, null, OnBattlePassPurchaseResults )
	PurchaseDialog_SetPurchaseOverrideSound( "UI_Menu_BattlePass_Purchase" )
}


void function PassPurchaseMenu_OnOpen()
{
	RunClientScript( "ClearBattlePassItem" )
	UI_SetPresentationType( ePresentationType.BATTLE_PASS )

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return

	expect ItemFlavor( activeBattlePass )
	asset battlePassAsset = ItemFlavor_GetAsset( activeBattlePass )
	bool offerRestricted  = GRX_IsOfferRestricted( GetUIPlayer() )

	HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "seasonName", ItemFlavor_GetLongName( activeBattlePass ) )
	HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "titleText", GetGlobalSettingsString( battlePassAsset, "featureTitle" ) )
	HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "logo", GetGlobalSettingsAsset( battlePassAsset, "largeLogo" ), eRuiArgType.IMAGE )

	HudElem_SetRuiArg( s_passPurchaseMenu.offersBorders, "seasonShortName", ItemFlavor_GetShortName( activeBattlePass ) )

	array<string> bulletText = BattlePass_GetBulletText( activeBattlePass, offerRestricted )
	for ( int i = 0 ; i < 16 ; i++ )
		HudElem_SetRuiArg( s_passPurchaseMenu.seasonLogoBox, "bulletText" + (i + 1), i < bulletText.len() ? bulletText[i] : "" )

	UpdatePassPurchaseButtons()
}


void function PassPurchaseMenu_OnGetTopLevel()
{
	if ( s_passPurchaseMenu.closeOnGetTopLevel )
	{
		s_passPurchaseMenu.closeOnGetTopLevel = false
		CloseActiveMenu()
	}
}


void function UpdatePassPurchaseButtons()
{
	Assert( GRX_IsInventoryReady() )

	ItemFlavor ornull activeBattlePass = GetPlayerActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return
	expect ItemFlavor( activeBattlePass )

	//
	ItemFlavor basicPurchaseFlav = BattlePass_GetBasicPurchasePack( activeBattlePass )
	var basicButton              = Hud_GetRui( s_passPurchaseMenu.passPurchaseButton )
	RuiSetAsset( basicButton, "backgroundImage", ItemFlavor_GetIcon( basicPurchaseFlav ) )
	RuiSetString( basicButton, "offerTitle", ItemFlavor_GetShortName( basicPurchaseFlav ) )
	RuiSetString( basicButton, "offerDesc", ItemFlavor_GetLongDescription( basicPurchaseFlav ) )

	array<GRXScriptOffer> basicPurchaseOffers = GRX_GetItemDedicatedStoreOffers( basicPurchaseFlav, "battlepass" )
	//
	if ( basicPurchaseOffers.len() == 1 )
	{
		GRXScriptOffer basicPurchaseOffer = basicPurchaseOffers[0]
		Assert( basicPurchaseOffer.prices.len() == 1 )
		if ( basicPurchaseOffer.prices.len() == 1 )
		{
			RuiSetString( basicButton, "price", GRX_GetFormattedPrice( basicPurchaseOffer.prices[0] ) )
		}
		else Warning( "Expected 1 price for basic pack offer of '%s'", ItemFlavor_GetHumanReadableRef( activeBattlePass ) )
	}
	else Warning( "Expected 1 offer for basic pack of '%s'", ItemFlavor_GetHumanReadableRef( activeBattlePass ) )


	//
	ItemFlavor bundlePurchaseFlav = BattlePass_GetBundlePurchasePack( activeBattlePass )
	var bundleButton              = Hud_GetRui( s_passPurchaseMenu.bundlePurchaseButton )
	RuiSetAsset( bundleButton, "backgroundImage", ItemFlavor_GetIcon( bundlePurchaseFlav ) )
	RuiSetString( bundleButton, "offerTitle", ItemFlavor_GetShortName( bundlePurchaseFlav ) )
	RuiSetString( bundleButton, "offerDesc", ItemFlavor_GetLongDescription( bundlePurchaseFlav ) )

	array<GRXScriptOffer> bundlePurchaseOffers = GRX_GetItemDedicatedStoreOffers( bundlePurchaseFlav, "battlepass" )
	//
	if ( bundlePurchaseOffers.len() == 1 )
	{
		GRXScriptOffer bundlePurchaseOffer = bundlePurchaseOffers[0]
		Assert( bundlePurchaseOffer.prices.len() == 1 )
		if ( bundlePurchaseOffer.prices.len() == 1 )
		{
			RuiSetString( bundleButton, "price", GRX_GetFormattedPrice( bundlePurchaseOffer.prices[0] ) )
			RuiSetString( bundleButton, "priceBeforeDiscount", GetFormattedValueForCurrency( 4700, GRX_CURRENCY_PREMIUM ) )
		}
		else Warning( "Expected 1 price for bundle pack offer of '%s'", ItemFlavor_GetHumanReadableRef( activeBattlePass ) )
	}
	else Warning( "Expected 1 offer for bundle pack of '%s'", ItemFlavor_GetHumanReadableRef( activeBattlePass ) )

	bool canPurchaseBundle = GetPlayerBattlePassPurchasableLevels( ToEHI( GetUIPlayer() ), activeBattlePass ) >= 25

	Hud_SetLocked( s_passPurchaseMenu.bundlePurchaseButton, !canPurchaseBundle )
	if ( !canPurchaseBundle )
	{
		ToolTipData toolTipData
		toolTipData.titleText = "#BATTLE_PASS_BUNDLE_PROTECT"
		toolTipData.descText = "#BATTLE_PASS_BUNDLE_PROTECT_DESC"
		Hud_SetToolTipData( s_passPurchaseMenu.bundlePurchaseButton, toolTipData )
	}
	else
	{
		Hud_ClearToolTipData( s_passPurchaseMenu.bundlePurchaseButton )
	}
}

void function OnBattlePassPurchaseResults( bool wasSuccessful )
{
	if ( wasSuccessful )
	{
		s_passPurchaseMenu.closeOnGetTopLevel = true
	}
}
#endif //

#if(UI)
bool function TryDisplayBattlePassAwards()
{
	WaitEndFrame()

	bool ready = GRX_IsInventoryReady() && GRX_AreOffersReady()
	if ( !ready )
		return false

	EHI playerEHI                      = ToEHI( GetUIPlayer() )
	ItemFlavor ornull activeBattlePass = GetPlayerLastActiveBattlePass( ToEHI( GetUIPlayer() ) )
	if ( activeBattlePass == null || !GRX_IsInventoryReady() )
		return false

	expect ItemFlavor( activeBattlePass )

	int currentXP       = GetPlayerBattlePassXPProgress( playerEHI, activeBattlePass )
	int lastSeenXP      = GetPlayerBattlePassLastSeenXP( playerEHI, activeBattlePass )
	bool hasPremiumPass = DoesPlayerOwnBattlePass( GetUIPlayer(), activeBattlePass )
	bool hadPremiumPass = GetPlayerBattlePassLastSeenPremium( playerEHI, activeBattlePass )

	if ( currentXP == lastSeenXP && hasPremiumPass == hadPremiumPass )
		return false

	if ( IsDialog( GetActiveMenu() ) )
		return false

	int lastLevel    = GetBattlePassLevelForXP( activeBattlePass, lastSeenXP )+1
	int currentLevel = GetBattlePassLevelForXP( activeBattlePass, currentXP )

	array<BattlePassReward> allAwards
	array<BattlePassReward> freeAwards
	for ( int levelIdx = lastLevel; levelIdx <= currentLevel; levelIdx++ )
	{
		array<BattlePassReward> awardsForLevel = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
		foreach ( award in awardsForLevel )
		{
			if ( award.isPremium )
				continue

			freeAwards.append( award )
		}
	}

	allAwards.extend( freeAwards )

	if ( hasPremiumPass )
	{
		array<BattlePassReward> premiumAwards

		for ( int levelIdx = lastLevel; levelIdx <= currentLevel; levelIdx++ )
		{
			array<BattlePassReward> awardsForLevel = GetBattlePassLevelRewards( activeBattlePass, levelIdx )
			foreach ( award in awardsForLevel )
			{
				if ( !award.isPremium )
					continue

				premiumAwards.append( award )
			}
		}

		allAwards.extend( premiumAwards )
	}

	if ( allAwards.len() == 0 )
		return false

	allAwards.sort( SortByAwardLevel )

	file.currentPage = -1 //

	ShowRewardCeremonyDialog(
		"",
		Localize( "#BATTLE_PASS_REACHED_LEVEL", GetBattlePassDisplayLevel( currentLevel ) ),
		"",
		allAwards,
		true )

	return true
}


int function SortByAwardLevel( BattlePassReward a, BattlePassReward b )
{
	if ( a.level > b.level )
		return 1
	else if ( a.level < b.level )
		return -1

	if ( a.isPremium && !b.isPremium )
		return 1
	else if ( b.isPremium && !a.isPremium )
		return -1

	return 0
}

#endif


#if(CLIENT)
void function UIToClient_ItemPresentation( SettingsAssetGUID itemFlavorGUID, int level, bool showLow, var loadscreenPreviewBox, bool shouldPlayAudioPreview )
{
	entity sceneRef = GetEntByScriptName( "battlepass_ref" )
	fileLevel.sceneRefOrigin = sceneRef.GetOrigin()
	if ( showLow )
		fileLevel.sceneRefOrigin += <0, 0, -8.5>
	fileLevel.sceneRefAngles = sceneRef.GetAngles()

	ShowBattlepassItem( GetItemFlavorByGUID( itemFlavorGUID ), level, loadscreenPreviewBox, shouldPlayAudioPreview )

	//
	//

	//
}


void function ShowBattlepassItem( ItemFlavor item, int level, var loadscreenPreviewBox, bool shouldPlayAudioPreview )
{
	fileLevel.loadscreenPreviewBox = loadscreenPreviewBox //

	ClearBattlePassItem()

	fileLevel.loadscreenPreviewBox = loadscreenPreviewBox

	int itemType = ItemFlavor_GetType( item )

	switch ( itemType )
	{
		case eItemType.account_currency:
		case eItemType.account_currency_bundle:
			ShowBattlePassItem_Currency( item )
			break

		case eItemType.account_pack:
			ShowBattlePassItem_ApexPack( item )
			break

		case eItemType.character_skin:
			ShowBattlePassItem_CharacterSkin( item )
			break

		case eItemType.character_execution:
			ShowBattlePassItem_Execution( item )
			break

		case eItemType.weapon_skin:
			asset video = WeaponSkin_GetVideo( item )
			if ( video != $"" )
				ShowBattlePassItem_WeaponSkinVideo( item, video )
			else
				ShowBattlePassItem_WeaponSkin( item )
			break

		case eItemType.melee_skin:
			ShowBattlePassItem_MeleeSkin( item )
			break

		case eItemType.gladiator_card_stance:
		case eItemType.gladiator_card_frame:
			ShowBattlePassItem_Banner( item )
			break

		case eItemType.gladiator_card_intro_quip:
		case eItemType.gladiator_card_kill_quip:
			ShowBattlePassItem_Quip( item, shouldPlayAudioPreview )
			break

		case eItemType.gladiator_card_stat_tracker:
			ShowBattlePassItem_StatTracker( item )
			break

		case eItemType.xp_boost:
			ShowBattlePassItem_XPBoost( item )
			break

		case eItemType.gladiator_card_badge:
			ShowBattlePassItem_Badge( item, level )
			break

		case eItemType.music_pack:
			ShowBattlePassItem_MusicPack( item, shouldPlayAudioPreview )
			break

		case eItemType.loadscreen:
			ShowBattlePassItem_Loadscreen( item )
			break

		case eItemType.skydive_emote:
			ShowBattlePassItem_SkydiveEmote( item )
			break

		default:
			Warning( "Loot Ceremony reward item type not supported: " + DEV_GetEnumStringSafe( "eItemType", itemType ) )
			ShowBattlePassItem_Unknown( item )
			break
	}
}
#endif //

#if(CLIENT)
const float BATTLEPASS_MODEL_ROTATE_SPEED = 15.0

void function ClearBattlePassItem()
{
	foreach ( model in fileLevel.models )
	{
		if ( IsValid( model ) )
			model.Destroy()
	}

	if ( IsValid( fileLevel.mover ) )
		fileLevel.mover.Destroy()

	CleanupNestedGladiatorCard( fileLevel.bannerHandle )

	if ( fileLevel.rui != null )
		RuiDestroyIfAlive( fileLevel.rui )

	if ( fileLevel.topo != null )
	{
		RuiTopology_Destroy( fileLevel.topo )
		fileLevel.topo = null
	}

	if ( fileLevel.videoChannel != -1 )
	{
		ReleaseVideoChannel( fileLevel.videoChannel )
		fileLevel.videoChannel = -1
	}

	if ( fileLevel.playingPreviewAlias != "" )
		StopSoundOnEntity( GetLocalClientPlayer(), fileLevel.playingPreviewAlias )

	if ( IsValid( fileLevel.loadscreenPreviewBox ) )
	{
		UpdateLoadscreenPreviewMaterial( fileLevel.loadscreenPreviewBox, null, 0 )
		fileLevel.loadscreenPreviewBox = null
	}
}

void function ShowBattlePassItem_ApexPack( ItemFlavor item )
{
	vector origin = fileLevel.sceneRefOrigin + <0, 0, 10.0>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	int rarity      = ItemFlavor_GetQuality( item )
	asset tickAsset = GRXPack_GetTickModel( item )
	string tickSkin = GRXPack_GetTickModelSkin( item )
	entity model    = CreateClientSidePropDynamic( origin, AnglesCompose( angles, <0, 135, 0> ), tickAsset )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( 0.75 )
	model.SetParent( mover )
	model.SetSkin( model.GetSkinIndexByName( tickSkin ) )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_CharacterSkin( ItemFlavor item )
{
	vector origin = fileLevel.sceneRefOrigin + <0, 0, 4.0>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, angles, $"mdl/dev/empty_model.rmdl" )
	CharacterSkin_Apply( model, item )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( 0.75 )
	model.SetParent( mover )

	thread PlayAnim( model, "ACT_MP_MENU_LOOT_CEREMONY_IDLE", mover )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_Execution( ItemFlavor item )
{
	const float BATTLEPASS_EXECUTION_Z_OFFSET = 12.0
	const vector BATTLEPASS_EXECUTION_LOCAL_ANGLES = <0, 15, 0>
	const float BATTLEPASS_EXECUTION_SCALE = 0.8

	//
	ItemFlavor attackerCharacter = CharacterExecution_GetCharacterFlavor( item )
	ItemFlavor characterSkin     = LoadoutSlot_GetItemFlavor( LocalClientEHI(), Loadout_CharacterSkin( attackerCharacter ) )

	asset attackerAnimSeq = CharacterExecution_GetAttackerPreviewAnimSeq( item )
	asset victimAnimSeq   = CharacterExecution_GetVictimPreviewAnimSeq( item )

	//
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_EXECUTION_Z_OFFSET>
	vector angles = AnglesCompose( fileLevel.sceneRefAngles, BATTLEPASS_EXECUTION_LOCAL_ANGLES )

	entity mover         = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	entity attackerModel = CreateClientSidePropDynamic( origin, angles, $"mdl/dev/empty_model.rmdl" )
	entity victimModel   = CreateClientSidePropDynamic( origin, angles, $"mdl/dev/empty_model.rmdl" )

	CharacterSkin_Apply( attackerModel, characterSkin )
	victimModel.SetModel( $"mdl/humans/class/medium/pilot_medium_generic.rmdl" )

	//
	bool attackerHasSequence = attackerModel.Anim_HasSequence( attackerAnimSeq )
	bool victimHasSequence   = victimModel.Anim_HasSequence( victimAnimSeq )

	if ( !attackerHasSequence || !victimHasSequence )
	{
		asset attackerPlayerSettings = CharacterClass_GetSetFile( attackerCharacter )
		string attackerRigWeight     = GetGlobalSettingsString( attackerPlayerSettings, "bodyModelRigWeight" )
		string attackerAnim          = "mp_pt_execution_" + attackerRigWeight + "_attacker_loot"

		attackerModel.Anim_Play( attackerAnim )
		victimModel.Anim_Play( "mp_pt_execution_default_victim_loot" )
		Warning( "Couldn't find menu idles for execution reward: " + DEV_DescItemFlavor( item ) + ". Using fallback anims." )
		if ( !attackerHasSequence )
			Warning( "ATTACKER could not find sequence: " + attackerAnimSeq )
		if ( !victimHasSequence )
			Warning( "VICTIM could not find sequence: " + victimAnimSeq )
	}
	else
	{
		attackerModel.Anim_Play( attackerAnimSeq )
		victimModel.Anim_Play( victimAnimSeq )
	}

	mover.MakeSafeForUIScriptHack()

	attackerModel.MakeSafeForUIScriptHack()
	attackerModel.SetParent( mover )

	victimModel.MakeSafeForUIScriptHack()
	victimModel.SetParent( mover )

	//
	attackerModel.SetModelScale( BATTLEPASS_EXECUTION_SCALE )
	victimModel.SetModelScale( BATTLEPASS_EXECUTION_SCALE )

	int rarity = ItemFlavor_GetQuality( item )
	ModelRarityFlash( attackerModel, rarity )
	ModelRarityFlash( victimModel, rarity )

	fileLevel.mover = mover
	fileLevel.models.append( attackerModel )
	fileLevel.models.append( victimModel )
}


void function ShowBattlePassItem_WeaponSkin( ItemFlavor weapSkin )
{
	const vector BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES = <5, -45, 0>

	vector origin = fileLevel.sceneRefOrigin + <0, 0, 29.0>
	vector angles = fileLevel.sceneRefAngles

	//
	ItemFlavor weaponItem = WeaponSkin_GetWeaponFlavor( weapSkin )

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, AnglesCompose( angles, BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES ), $"mdl/dev/empty_model.rmdl" )
	WeaponCosmetics_Apply( model, weapSkin, null )
	ShowDefaultBodygroupsOnFakeWeapon( model, WeaponItemFlavor_GetClassname( weaponItem ) )
	model.MakeSafeForUIScriptHack()
	model.SetVisibleForLocalPlayer( 0 )
	model.Anim_SetPaused( true )
	model.SetModelScale( WeaponItemFlavor_GetBattlePassScale( weaponItem ) )
	model.SetParent( mover )

	//
	model.SetLocalOrigin( GetAttachmentOriginOffset( model, "MENU_ROTATE", BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES ) )
	model.SetLocalAngles( BATTLEPASS_WEAPON_SKIN_LOCAL_ANGLES )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, ItemFlavor_GetQuality( weapSkin ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_MeleeSkin( ItemFlavor item )
{
	const float MELEE_SKIN_SCALE = 2.6

	vector origin = fileLevel.sceneRefOrigin + <0, 0, 29.0>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	vector extraRotation = MeleeSkin_GetMenuModelRotation( item )
	entity model         = CreateClientSidePropDynamic( origin, AnglesCompose( angles, extraRotation ), MeleeSkin_GetMenuModel( item ) )
	model.MakeSafeForUIScriptHack()
	model.SetVisibleForLocalPlayer( 0 )
	model.Anim_SetPaused( true )
	model.SetModelScale( MELEE_SKIN_SCALE )
	model.SetParent( mover )

	model.SetLocalOrigin( GetAttachmentOriginOffset( model, "MENU_ROTATE", extraRotation ) )
	model.SetLocalAngles( extraRotation )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_Banner( ItemFlavor item )
{
	int itemType = ItemFlavor_GetType( item )
	Assert( itemType == eItemType.gladiator_card_frame || itemType == eItemType.gladiator_card_stance )

	const float BATTLEPASS_BANNER_WIDTH = 528.0
	const float BATTLEPASS_BANNER_HEIGHT = 912.0
	const float BATTLEPASS_BANNER_SCALE = 0.08
	const float BATTLEPASS_BANNER_Z_OFFSET = -4.0

	entity player = GetLocalClientPlayer()
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_BANNER_Z_OFFSET>
	vector angles = AnglesCompose( fileLevel.sceneRefAngles, <0, 180, 0> )

	float width  = BATTLEPASS_BANNER_WIDTH * BATTLEPASS_BANNER_SCALE
	float height = BATTLEPASS_BANNER_HEIGHT * BATTLEPASS_BANNER_SCALE

	var topo = CreateRUITopology_Worldspace( origin + <0, 0, height * 0.5>, angles, width, height )
	var rui  = RuiCreate( $"ui/loot_ceremony_glad_card.rpak", topo, RUI_DRAW_VIEW_MODEL, 0 )

	int gcardPresentation
	if ( itemType == eItemType.gladiator_card_frame )
		gcardPresentation = eGladCardPresentation.FRONT_FRAME_ONLY
	else
		gcardPresentation = eGladCardPresentation.FRONT_STANCE_ONLY

	NestedGladiatorCardHandle nestedGCHandleFront = CreateNestedGladiatorCard( rui, "card", eGladCardDisplaySituation.MENU_LOOT_CEREMONY_ANIMATED, gcardPresentation )
	ChangeNestedGladiatorCardOwner( nestedGCHandleFront, ToEHI( player ) )

	if ( itemType == eItemType.gladiator_card_frame )
	{
		ItemFlavor character = GladiatorCardFrame_GetCharacterFlavor( item )
		SetNestedGladiatorCardOverrideCharacter( nestedGCHandleFront, character )
		SetNestedGladiatorCardOverrideFrame( nestedGCHandleFront, item )
	}
	else
	{
		ItemFlavor character = GladiatorCardStance_GetCharacterFlavor( item )
		SetNestedGladiatorCardOverrideCharacter( nestedGCHandleFront, character )
		SetNestedGladiatorCardOverrideStance( nestedGCHandleFront, item )

		ItemFlavor characterDefaultFrame = GetDefaultItemFlavorForLoadoutSlot( EHI_null, Loadout_GladiatorCardFrame( character ) )
		SetNestedGladiatorCardOverrideFrame( nestedGCHandleFront, characterDefaultFrame ) //
	}

	RuiSetBool( rui, "battlepass", true )
	RuiSetInt( rui, "rarity", ItemFlavor_GetQuality( item ) )

	fileLevel.topo = topo
	fileLevel.rui = rui
	fileLevel.bannerHandle = nestedGCHandleFront
}


void function ShowBattlePassItem_Quip( ItemFlavor item, bool shouldPlayAudioPreview )
{
	int itemType = ItemFlavor_GetType( item )
	Assert( itemType == eItemType.gladiator_card_intro_quip || itemType == eItemType.gladiator_card_kill_quip )

	const float BATTLEPASS_QUIP_WIDTH = 390.0
	const float BATTLEPASS_QUIP_HEIGHT = 208.0
	const float BATTLEPASS_QUIP_SCALE = 0.091
	const float BATTLEPASS_QUIP_Z_OFFSET = 20.5
	const asset BATTLEPASS_QUIP_BG_MODEL = $"mdl/menu/loot_ceremony_quip_bg.rmdl"

	vector origin        = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_QUIP_Z_OFFSET>
	vector angles        = fileLevel.sceneRefAngles
	vector placardAngles = VectorToAngles( AnglesToForward( angles ) * -1 )

	//
	float width  = BATTLEPASS_QUIP_WIDTH * BATTLEPASS_QUIP_SCALE
	float height = BATTLEPASS_QUIP_HEIGHT * BATTLEPASS_QUIP_SCALE

	entity model = CreateClientSidePropDynamic( origin, angles, BATTLEPASS_QUIP_BG_MODEL )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( BATTLEPASS_QUIP_SCALE )

	var topo         = CreateRUITopology_Worldspace( origin + <0, 0, (height * 0.5)>, placardAngles, width, height )
	var rui
	ItemFlavor quipCharacter
	string labelText
	string quipAlias = ""

	if ( itemType == eItemType.gladiator_card_intro_quip )
	{
		//
		rui = RuiCreate( $"ui/loot_reward_intro_quip.rpak", topo, RUI_DRAW_WORLD, 0 )
		quipCharacter = CharacterIntroQuip_GetCharacterFlavor( item )
		labelText = "#LOOT_QUIP_INTRO"
		quipAlias = CharacterIntroQuip_GetVoiceSoundEvent( item )
	}
	else
	{
		//
		rui = RuiCreate( $"ui/loot_reward_kill_quip.rpak", topo, RUI_DRAW_WORLD, 0 )
		quipCharacter = CharacterKillQuip_GetCharacterFlavor( item )
		labelText = "#LOOT_QUIP_KILL"
		quipAlias = CharacterKillQuip_GetVictimVoiceSoundEvent( item )
	}

	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "battlepass", true )
	RuiSetInt( rui, "rarity", ItemFlavor_GetQuality( item ) )
	RuiSetImage( rui, "portraitImage", CharacterClass_GetGalleryPortrait( quipCharacter ) )
	RuiSetString( rui, "quipTypeText", labelText )
	RuiTrackFloat( rui, "level", null, RUI_TRACK_SOUND_METER, 0 )

	fileLevel.models.append( model )
	fileLevel.topo = topo
	fileLevel.rui = rui

	//
	if ( quipAlias != "" && shouldPlayAudioPreview )
	{
		fileLevel.playingPreviewAlias = quipAlias
		EmitSoundOnEntity( GetLocalClientPlayer(), quipAlias )
	}
}


void function ShowBattlePassItem_StatTracker( ItemFlavor item )
{
	const float BATTLEPASS_STAT_TRACKER_WIDTH = 594.0
	const float BATTLEPASS_STAT_TRACKER_HEIGHT = 230.0
	const float BATTLEPASS_STAT_TRACKER_SCALE = 0.06
	const asset BATTLEPASS_STAT_TRACKER_BG_MODEL = $"mdl/menu/loot_ceremony_stat_tracker_bg.rmdl"

	vector origin        = fileLevel.sceneRefOrigin + <0, 0, 23>
	vector angles        = fileLevel.sceneRefAngles
	vector placardAngles = VectorToAngles( AnglesToForward( angles ) * -1 )

	//
	float width  = BATTLEPASS_STAT_TRACKER_WIDTH * BATTLEPASS_STAT_TRACKER_SCALE
	float height = BATTLEPASS_STAT_TRACKER_HEIGHT * BATTLEPASS_STAT_TRACKER_SCALE

	var topo = CreateRUITopology_Worldspace( origin + <0, 0, (height * 0.5)>, placardAngles, width, height )
	var rui  = RuiCreate( $"ui/loot_ceremony_stat_tracker.rpak", topo, RUI_DRAW_WORLD, 0 )

	entity model = CreateClientSidePropDynamic( origin, angles, BATTLEPASS_STAT_TRACKER_BG_MODEL )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( BATTLEPASS_STAT_TRACKER_SCALE )

	ItemFlavor character = GladiatorCardStatTracker_GetCharacterFlavor( item )

	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "battlepass", true )
	UpdateRuiWithStatTrackerData( rui, "tracker", LocalClientEHI(), character, -1, item, null, true )
	RuiSetColorAlpha( rui, "trackerColor0", GladiatorCardStatTracker_GetColor0( item ), 1.0 )
	RuiSetInt( rui, "rarity", ItemFlavor_GetQuality( item ) )

	fileLevel.models.append( model )
	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function ShowBattlePassItem_Badge( ItemFlavor item, int level )
{
	const float BATTLEPASS_BADGE_WIDTH = 670.0
	const float BATTLEPASS_BADGE_HEIGHT = 670.0
	const float BATTLEPASS_BADGE_SCALE = 0.06

	vector origin        = fileLevel.sceneRefOrigin + <0, 0, 30>
	vector angles        = fileLevel.sceneRefAngles
	vector placardAngles = VectorToAngles( AnglesToForward( angles ) * -1 )

	float width  = BATTLEPASS_BADGE_WIDTH * BATTLEPASS_BADGE_SCALE
	float height = BATTLEPASS_BADGE_HEIGHT * BATTLEPASS_BADGE_SCALE

	var topo = CreateRUITopology_Worldspace( origin, placardAngles, width, height )
	var rui  = RuiCreate( $"ui/world_space_badge.rpak", topo, RUI_DRAW_VIEW_MODEL, 0 )
	ItemFlavor dummy
	CreateNestedGladiatorCardBadge( rui, "badge", LocalClientEHI(), item, 0, dummy, level == -1 ? 0 : level + 2 )
	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "battlepass", true )

	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function ShowBattlePassItem_Currency( ItemFlavor item )
{
	int itemType = ItemFlavor_GetType( item )
	Assert( itemType == eItemType.account_currency || itemType == eItemType.account_currency_bundle )

	asset modelAsset = $"mdl/dev/empty_model.rmdl"
	float modelScale = 1.0
	int rarity = 0
	if ( ItemFlavor_HasQuality( item ) )
		rarity = ItemFlavor_GetQuality( item )

	if ( ItemFlavor_GetType( item ) == eItemType.account_currency )
	{
		if ( item == GRX_CURRENCIES[GRX_CURRENCY_CRAFTING] )
		{
			modelAsset = BATTLEPASS_MODEL_CRAFTING_METALS
			modelScale = 1.5
		}
		else
		{
			modelAsset = GRXCurrency_GetPreviewModel( item )
		}
	}
	else
	{
		asset itemAsset = ItemFlavor_GetAsset( item )
		Assert( itemAsset == $"settings/itemflav/currency_bundle/crafting_common.rpak" ||
				itemAsset == $"settings/itemflav/currency_bundle/crafting_rare.rpak" ||
				itemAsset == $"settings/itemflav/currency_bundle/crafting_epic.rpak" ||
				itemAsset == $"settings/itemflav/currency_bundle/crafting_legendary.rpak" )

		switch ( rarity )
		{
			case 0:
				modelAsset = CURRENCY_MODEL_COMMON
				break

			case 1:
				modelAsset = CURRENCY_MODEL_RARE
				break

			case 2:
				modelAsset = CURRENCY_MODEL_EPIC
				break

			case 3:
				modelAsset = CURRENCY_MODEL_LEGENDARY
				break

			default: Assert( false )
		}

		modelScale = 1.5
	}

	vector origin = fileLevel.sceneRefOrigin + <0, 0, 29>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, AnglesCompose( angles, <0, 32, 0> ), modelAsset )
	model.MakeSafeForUIScriptHack()
	if ( modelScale != 1.0 )
		model.SetModelScale( modelScale )
	model.SetParent( mover )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, rarity )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_XPBoost( ItemFlavor item )
{
	vector origin = fileLevel.sceneRefOrigin + <0, 0, 28.0>
	vector angles = fileLevel.sceneRefAngles

	entity mover = CreateClientsideScriptMover( $"mdl/dev/empty_model.rmdl", origin, angles )
	mover.MakeSafeForUIScriptHack()

	entity model = CreateClientSidePropDynamic( origin, AnglesCompose( angles, <0, 32, 0> ), BATTLEPASS_MODEL_BOOST )
	model.MakeSafeForUIScriptHack()
	model.SetParent( mover )

	mover.NonPhysicsRotate( <0, 0, -1>, BATTLEPASS_MODEL_ROTATE_SPEED )

	ModelRarityFlash( model, ItemFlavor_GetQuality( item ) )

	fileLevel.mover = mover
	fileLevel.models.append( model )
}


void function ShowBattlePassItem_WeaponSkinVideo( ItemFlavor item, asset video )
{
	const float BATTLEPASS_UNKNOWN_WIDTH = 800.0
	const float BATTLEPASS_UNKNOWN_HEIGHT = 450.0
	const float BATTLEPASS_UNKNOWN_Z_OFFSET = 28

	//
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_UNKNOWN_Z_OFFSET>
	vector angles = VectorToAngles( AnglesToForward( fileLevel.sceneRefAngles ) * -1 )

	float width  = BATTLEPASS_UNKNOWN_WIDTH / 14.0
	float height = BATTLEPASS_UNKNOWN_HEIGHT / 14.0

	var topo = CreateRUITopology_Worldspace( origin, angles, width, height )
	var rui  = RuiCreate( $"ui/finisher_video.rpak", topo, RUI_DRAW_VIEW_MODEL, 0 )

	fileLevel.videoChannel = ReserveVideoChannel( BattlePassVideoOnFinished )
	RuiSetInt( rui, "channel", fileLevel.videoChannel )
	StartVideoOnChannel( fileLevel.videoChannel, video, true, 0.0 )

	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function ShowBattlePassItem_MusicPack( ItemFlavor item, bool shouldPlayAudioPreview )
{
	int itemType = ItemFlavor_GetType( item )
	Assert( itemType == eItemType.music_pack )

	const float BATTLEPASS_QUIP_WIDTH = 390.0
	const float BATTLEPASS_QUIP_HEIGHT = 208.0
	const float BATTLEPASS_QUIP_SCALE = 0.091
	const float BATTLEPASS_QUIP_Z_OFFSET = 20.5
	const asset BATTLEPASS_QUIP_BG_MODEL = $"mdl/menu/loot_ceremony_quip_bg.rmdl"

	vector origin        = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_QUIP_Z_OFFSET>
	vector angles        = fileLevel.sceneRefAngles
	vector placardAngles = VectorToAngles( AnglesToForward( angles ) * -1 )

	//
	float width  = BATTLEPASS_QUIP_WIDTH * BATTLEPASS_QUIP_SCALE
	float height = BATTLEPASS_QUIP_HEIGHT * BATTLEPASS_QUIP_SCALE

	entity model = CreateClientSidePropDynamic( origin, angles, BATTLEPASS_QUIP_BG_MODEL )
	model.MakeSafeForUIScriptHack()
	model.SetModelScale( BATTLEPASS_QUIP_SCALE )

	var topo = CreateRUITopology_Worldspace( origin + <0, 0, (height * 0.5)>, placardAngles, width, height )
	var rui  = RuiCreate( $"ui/loot_reward_intro_quip.rpak", topo, RUI_DRAW_WORLD, 0 )

	ItemFlavor ornull character = MusicPack_GetCharacterOrNull( item )
	string previewAlias         = MusicPack_GetPreviewMusic( item )

	RuiSetBool( rui, "isVisible", true )
	RuiSetBool( rui, "battlepass", true )
	RuiSetInt( rui, "rarity", ItemFlavor_GetQuality( item ) )
	RuiSetImage( rui, "portraitImage", CharacterClass_GetGalleryPortrait( expect ItemFlavor( character ) ) )
	RuiSetString( rui, "quipTypeText", "#MUSIC_PACK" )
	RuiTrackFloat( rui, "level", null, RUI_TRACK_SOUND_METER, 0 )

	fileLevel.models.append( model )
	fileLevel.topo = topo
	fileLevel.rui = rui

	//
	if ( previewAlias != "" && shouldPlayAudioPreview )
	{
		fileLevel.playingPreviewAlias = previewAlias
		EmitSoundOnEntity( GetLocalClientPlayer(), previewAlias )
	}
}


void function ShowBattlePassItem_Loadscreen( ItemFlavor item )
{
	UpdateLoadscreenPreviewMaterial( fileLevel.loadscreenPreviewBox, null, ItemFlavor_GetGUID( item ) )
}


void function ShowBattlePassItem_SkydiveEmote( ItemFlavor item )
{
	const float BATTLEPASS_UNKNOWN_WIDTH = 800.0
	const float BATTLEPASS_UNKNOWN_HEIGHT = 450.0
	const float BATTLEPASS_UNKNOWN_Z_OFFSET = 28

	//
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_UNKNOWN_Z_OFFSET>
	vector angles = VectorToAngles( AnglesToForward( fileLevel.sceneRefAngles ) * -1 )

	float width  = BATTLEPASS_UNKNOWN_WIDTH / 14.0
	float height = BATTLEPASS_UNKNOWN_HEIGHT / 14.0

	var topo = CreateRUITopology_Worldspace( origin, angles, width, height )
	var rui  = RuiCreate( $"ui/finisher_video.rpak", topo, RUI_DRAW_VIEW_MODEL, 0 )

	fileLevel.videoChannel = ReserveVideoChannel( BattlePassVideoOnFinished )
	RuiSetInt( rui, "channel", fileLevel.videoChannel )
	StartVideoOnChannel( fileLevel.videoChannel, CharacterSkydiveEmote_GetVideo( item ), true, 0.0 )

	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function ShowBattlePassItem_Unknown( ItemFlavor item )
{
	const float BATTLEPASS_UNKNOWN_WIDTH = 450.0
	const float BATTLEPASS_UNKNOWN_HEIGHT = 200.0
	const float BATTLEPASS_UNKNOWN_Z_OFFSET = 25

	//
	vector origin = fileLevel.sceneRefOrigin + <0, 0, BATTLEPASS_UNKNOWN_Z_OFFSET>
	vector angles = VectorToAngles( AnglesToForward( fileLevel.sceneRefAngles ) * -1 )

	float width  = BATTLEPASS_UNKNOWN_WIDTH / 16.0
	float height = BATTLEPASS_UNKNOWN_HEIGHT / 16.0

	var topo = CreateRUITopology_Worldspace( origin, angles, width, height )
	var rui  = RuiCreate( $"ui/loot_reward_temp.rpak", topo, RUI_DRAW_WORLD, 0 )

	RuiSetString( rui, "bodyText", Localize( ItemFlavor_GetLongName( item ) ) )

	fileLevel.topo = topo
	fileLevel.rui = rui
}


void function BattlePassVideoOnFinished( int channel )
{
}


/*















*/


void function InitBattlePassLights()
{
	fileLevel.stationaryLights = GetEntArrayByScriptName( "battlepass_stationary_light" )

	//
	/*




*/
}


void function BattlePassLightsOn()
{
	foreach    ( light in fileLevel.stationaryLights )
		light.SetTweakLightUpdateShadowsEveryFrame( true )

	//

	/*








































*/
}

void function BattlePassLightsOff()
{
	foreach    ( light in fileLevel.stationaryLights )
		light.SetTweakLightUpdateShadowsEveryFrame( false )

	//

	/*







*/
}


void function ModelRarityFlash( entity model, int rarity )
{
	vector color = GetFXRarityColorForUnlockable( rarity ) / 255

	float fillIntensityScalar    = 10.0
	float outlineIntensityScalar = 300.0
	float fadeInTime             = 0.01
	float fadeOutTime            = 0.3
	float lifeTime               = 0.1

	thread ModelAndChildrenRarityFlash( model, color, fillIntensityScalar, outlineIntensityScalar, fadeInTime, fadeOutTime, lifeTime )
}


void function ModelAndChildrenRarityFlash( entity model, vector color, float fillIntensityScalar, float outlineIntensityScalar, float fadeInTime, float fadeOutTime, float lifeTime )
{
	WaitFrame()

	if ( !IsValid( model ) )
		return

//	foreach ( ent in GetEntityAndItsChildren( model ) )
	//	BattlePassModelHighlightBloom( ent, color, fillIntensityScalar, outlineIntensityScalar, fadeInTime, fadeOutTime, lifeTime )
}

void function BattlePassModelHighlightBloom( entity model, vector color, float fillIntensityScalar, float outlineIntensityScalar, float fadeInTime, float fadeOutTime, float lifeTime )
{
	const float HIGHLIGHT_RADIUS = 2

	model.Highlight_ResetFlags()
	model.Highlight_SetVisibilityType( HIGHLIGHT_VIS_ALWAYS )
	model.Highlight_SetCurrentContext( HIGHLIGHT_CONTEXT_NEUTRAL )
	int highlightId = model.Highlight_GetState( HIGHLIGHT_CONTEXT_NEUTRAL )
	model.Highlight_SetFunctions( HIGHLIGHT_CONTEXT_NEUTRAL, HIGHLIGHT_FILL_MENU_MODEL_REVEAL, true, HIGHLIGHT_OUTLINE_MENU_MODEL_REVEAL, HIGHLIGHT_RADIUS, highlightId, false )
	model.Highlight_SetParam( HIGHLIGHT_CONTEXT_NEUTRAL, 0, color )
	model.Highlight_SetParam( HIGHLIGHT_CONTEXT_NEUTRAL, 1, <fillIntensityScalar, outlineIntensityScalar, 0> )

	model.Highlight_SetFadeInTime( fadeInTime )
	model.Highlight_SetFadeOutTime( fadeOutTime )
	model.Highlight_StartOn()

	model.Highlight_SetLifeTime( lifeTime )
}
#endif //

#endif