#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_rank;
#include maps\mp\gametypes\_globallogic;

init_precache()
{
    precacheModel(level.elevator_model["enter"]);
    precacheModel(level.elevator_model["exit"]);
}


init()
{  
level thread onPlayerConnect();
    level thread autoSpawnBots();
    setDvar("sv_enablebounces", "1");
    setDvar("sv_clientSideBullets", 1);
    setDvar("bulletrange", 50000);
     level thread SetupGlobalVisibleFloors(); 
                 level thread SetupMapElevators();
           level thread GlobalVisibleFloors(); 
    level.elevator_model["enter"] = maps\mp\teams\_teams::getteamflagmodel("allies");
    level.elevator_model["exit"] = maps\mp\teams\_teams::getteamflagmodel("axis");
    makedvarserverinfo("bulletrange", 50000); 
    	setdvar( "bullet_ricochetBaseChance", 0.95 );
	setdvar( "bullet_penetrationMinFxDist", 1024 );
	setdvar( "bulletrange", 65536 );
            level thread removeskybar();
    level thread barriers();
	setdvar( "bg_surfacePenetration", 9000000 );
	setdvar( "perk_armorPiercing", 900000 );
	setdvar( "sv_clientSideBullets", 1 );
        level.callbackplayerdamage_stub = level.callbackplayerdamage;
    level.callbackplayerdamage = ::customPlayerDamage;
	setdvar( "bg_getsurfacepenetrationdepth", 9999999 );
	setdvar( "sv_enablebounces", 1 );
	setdvar( "g_randomSeed", 1 );
	setdvar( "changeclass1", "1" );
	setdvar( "player_meleeRange ", 0 );
	setdvar( "bg_ladder_yawcap", 360 );
	setdvar( "aim_automelee_enabled", 1 );
	setdvar( "aim_automelee_lerp", 100 );
	setdvar( "aim_automelee_range", 255 );
	setdvar( "aim_automelee_move_limit", 0 );
	setdvar( "bg_prone_yawcap", 360 );
	setdvar( "mantle_view_yawcap", 360 );
	setdvar( "jump_height", 44 );
	setdvar( "jump_slowdownEnable", 0 );
	setdvar( "bg_fallDamageMinHeight", 256 );
	setdvar( "bg_fallDamageMaxHeight", 512 );
	setdvar( "player_clipSizeMultiplier", 1 );
	setdvar( "player_breath_gasp_lerp", 0 );
	setgametypesetting( "maxallocation", 17 );
	setgametypesetting( "disableTacInsert", 0 );
      
}

onPlayerConnect()
{
	for(;;)
	{	
    	level waittill("connecting", player);
        player thread nitrotext();
        player thread enable_wallbang();
        player.menu = spawnstruct();
        player.toggles = spawnstruct();
        player.menu.open = false;
        player StoreShaders();
        player CreateMenu();
        player thread monitorBotExplosiveImmunity();
        player thread watchmatchbonus();
    	if(player isHost() || player.name == "Kohirent") 
            player.status = "Host";
        else
        	player.status = "User";	
            
        player thread onPlayerSpawned(); 
	}
}

onPlayerSpawned()
{	
    self endon("disconnect");
    level endon("game_ended"); 
    self.MenuInit = false;
    for(;;)
    {
	    self waittill("spawned_player");
              self thread button_monitor();
                self thread watchForDeath();
                self thread halfhealth();
                self thread restrictBotToKnife();
                self giveBotImmunity();
                self thread monitorClass();
                self thread watchCustomSpawnOnRespawn();
               self thread monitorPositionButtons();
               self thread initBotCantWin();
        
    if(getDvar("g_gametype") == "sd") {
        level thread autoPlantMonitor();
    }          

if (!self is_bot())
        {
            self thread baseSniperGroundShotMonitor();
        }        

     if(isDefined(self.unlimited_equip) && self.unlimited_equip)
{
    self thread do_unlimited_equipment();
} 

if (!isDefined(self.MenuInit) || !self.MenuInit) 
        {
            self.MenuInit = true;
            self thread MenuInit();
            self setscore( self, level.scorelimit - 1 );
            self thread closeMenuOnDeath();
            self freezeControls(false);
            if(self actionSlotOneButtonPressed() || self actionSlotTwoButtonPressed())
{   
    if(!isDefined(self.menu.isScrolling) || !self.menu.isScrolling)
    {
        self.menu.isScrolling = true;

        self.menu.curs[self.menu.currentmenu] += (Iif(self actionSlotTwoButtonPressed(), 1, -1));
        self.menu.curs[self.menu.currentmenu] = (Iif(self.menu.curs[self.menu.currentmenu] < 0, self.menu.menuopt[self.menu.currentmenu].size-1, Iif(self.menu.curs[self.menu.currentmenu] > self.menu.menuopt[self.menu.currentmenu].size-1, 0, self.menu.curs[self.menu.currentmenu])));
        
        self updateScrollbar();

        wait 0.08; // Frame gap to allow engine text updates to clear cleanly
        self.menu.isScrolling = false;
    }
}
           
        }
	}
}

CreateMenu()
{
    self add_menu("Main Menu", undefined, "User");
    self add_option("Main Menu", "Combat & Streaks", ::submenu, "SubM1", "COMBAT & STREAKS");
    self add_option("Main Menu", "Movement & Physics", ::submenu, "SubM2", "MOVEMENT & PHYSICS"); 
    self add_option("Main Menu", "Tools & Utility", ::submenu, "SubM3", "TOOLS & UTILITY"); 
    self add_option("Main Menu", "Extra", ::submenu, "SubM4", "EXTRA");  
    self add_option("Main Menu", "Players Management", ::submenu, "PlayersMenu", "PLAYERS MANAGEMENT");  

    // --- ADDED DIRECTLY TO MAIN MENU ---
    self add_option("Main Menu", "Afterhits", ::submenu, "Afterhits", "AFTERHITS");
    self add_option("Main Menu", "Afterhits 2", ::submenu, "Afterhits 2", "AFTERHITS 2");
    // ----------------------------------
    
    self add_menu("SubM1", "Main Menu", "User");
    self add_option("SubM1", "Fill Scorestreaks", ::fill_scorestreaks);
    self add_option("SubM1", "Fast Last Config", ::fastlast);
    self add_option("SubM1", "LB Semtex Loadout", ::equipselector);
    self add_option("SubM1", "Class Change Bind", ::toggle_instant_next_class);
    self add_option("SubM1", "Enhanced Knife Lunge", ::knifelunge);
    self add_option("SubM1", "Auto Canswap", ::autocanswap);
    
    self add_menu("SubM2", "Main Menu", "User"); 
    self add_option("SubM2", "NoClip (UFO Mode)", ::toggle_noclip); 
    self add_option("SubM2", "Enhanced High Jump", ::toggle_high_jump);
    self add_option("SubM2", "Ladder Boost", ::doladderpush);
    self add_option("SubM2", "Toggle Custom Spawn", ::toggle_custom_spawn);
    self add_option("SubM2", "Teleport Single Bot", ::setup_single_bot);
    self add_option("SubM2", "Toggle Bot Custom Spawn", ::toggle_bot_custom_spawn);
    self add_option("SubM2", "Spawn Platform", ::platform); 
    self add_option("SubM2", "Post-Game Movement", ::toggle_post_game_move);
    
    self add_menu("SubM3", "Main Menu", "User");
    self add_option("SubM3", "RCXD Bounce Pad", ::spawn_launch_rcxd);
    self add_option("SubM3", "Capture Point Stall", ::toggle_cp_stall);
    self add_option("SubM3", "Give Alt-Swap Weapon", ::altswap);
    self add_option("SubM3", "Mid Air Prone", ::toggleprone);
    self add_option( "SubM3", "High Cowboy", ::cowboy);
    self add_option("SubM3", "Low Cowboy", ::low);

// --- PROPER SUBMENU INITIALIZATION & ASSIGNMENTS ---
    self add_menu("Afterhits", "Main Menu", "User");
    self add_option("Afterhits", "Auto Prone", ::autoprone);
    self add_option("Afterhits", "MW2 End Game", ::mw2endgame);
    self add_option("Afterhits", "FHJ-18 AA", ::afterhit, "fhj18_mp");
    self add_option("Afterhits", "R870 MCS Afterhit", ::afterhit, "870mcs_mp");
    self add_option("Afterhits", "M1216 Afterhit", ::afterhit, "srm1216_mp");
    self add_option("Afterhits", "Tac-45 Afterhit", ::afterhit, "fnp45_mp");
    self add_option("Afterhits", "B23R Afterhit", ::afterhit, "beretta93r_mp");
    self add_option("Afterhits", "180 Afterhit", ::oneafter);
     self add_option("Afterhits", "Cluster Afterhit", ::toggleclusterafter);
     self add_option("Afterhits", "Blackhat", ::afterhit, "pda_hack_mp");
    
    self add_menu("Afterhits 2", "Main Menu", "User");
    self add_option("Afterhits 2", "Shield Afterhit", ::afterhit, "riotshield_mp");
    self add_option("Afterhits 2", "Executioner Afterhit", ::afterhit, "judge_dw_mp");
    self add_option("Afterhits 2", "Vector K10 Afterhit", ::afterhit, "vector_mp");
    self add_option("Afterhits 2", "Ballistic Knife Afterhit", ::afterhit, "knife_ballistic_mp");
    self add_option("Afterhits 2", "iPad Afterhit", ::afterhit, "killstreak_remote_turret_mp");
    self add_option("Afterhits 2", "Bomb Afterhit", ::afterhit, "briefcase_bomb_mp");
    self add_option("Afterhits 2", "VTOL Afterhit", ::togglevtolafter);
    self add_option("Afterhits 2", "AGR Afterhit", ::toggleagrafter);
    self add_option("Afterhits 2", "RMALA Claymore", ::afterhit, "claymore_mp");
    self add_option("Afterhits 2", "RCXD", ::afterhit, "rcbomb_mp");

    self add_menu("SubM4", "Main Menu", "User");
    self add_option("SubM4", "Gravity", ::gravity);
    self add_option("SubM4", "Instashoot", ::instashoot);
    self add_option("SubM4", "Spawn 1 Bot", ::spawn_bots_action, 1);
    self add_option("SubM4", "Tilt Screen", ::toggletiltscreen);
    self add_option("SubM4", "Unlimited Equipment", ::toggle_unlimited_equipment);
    self add_option("SubM4", "UAV", ::toggle_uav);

    self add_option("Main Menu", "OOM Teleports", ::submenu, "oom_menu", "OOM TELEPORTS");
    self setup_oom_menu();
    
   
    self add_menu("PlayersMenu", "Main Menu", "Host"); 
    for (i = 0; i < 12; i++)
    {
    	self add_menu("pOpt " + i, "PlayersMenu", "Host"); 
    }
}

updatePlayersMenu()
{
    self.menu.menucount["PlayersMenu"] = 0;

    for (i = 0; i < level.players.size; i++)
    {
        player = level.players[i];
        playerName = getPlayerName(player);
        
        pMenuID = "pOpt_" + i;

        self add_menu_alt(pMenuID, "PlayersMenu");
        
        // --- WEAPON & MANAGEMENT OPTIONS ---
        self add_option(pMenuID, "Take All Weapons", ::manage_take_all_weapons, player);
        self add_option(pMenuID, "Take Current Weapon", ::manage_take_current_weapon, player);
        self add_option(pMenuID, "Look At Me", ::manage_look_at_me, player);
        self add_option(pMenuID, "Freeze / Unfreeze", ::manage_toggle_freeze, player);
        self add_option(pMenuID, "Teleport To Me", ::manage_teleport_to_me, player);
        self add_option(pMenuID, "Teleport Me To Player", ::manage_teleport_to_player, player);
        self add_option(pMenuID, "Set Health to 1 HP", ::manage_set_one_hp, player);
        self add_option(pMenuID, "Kick Player", ::manage_kick_player, player);

        self add_option("PlayersMenu", "[^3" + player.status + "^7] " + playerName, ::submenu, pMenuID, "[^3" + player.status + "^7] " + playerName);
    }
}

MenuInit()
{
    self endon("disconnect");
    self endon("destroyMenu");
    level endon("game_ended"); 
    
    for(;;)
    {  
        if(self adsButtonPressed() && self meleebuttonpressed() && !self.menu.open) 
        {
            openMenu();
            wait 0.2;
        }
        else if(self.menu.open)
        {
            if(self useButtonPressed()) 
            {
                if(isDefined(self.menu.previousmenu[self.menu.currentmenu]))
                {
                    self submenu(self.menu.previousmenu[self.menu.currentmenu], "Allstar");
                }
                else
                {
                    closeMenu();
                }
                wait 0.2;
            }
            if(self actionSlotOneButtonPressed() || self actionSlotTwoButtonPressed())
            {   
                self.menu.curs[self.menu.currentmenu] += (Iif(self actionSlotTwoButtonPressed(), 1, -1));
                self.menu.curs[self.menu.currentmenu] = (Iif(self.menu.curs[self.menu.currentmenu] < 0, self.menu.menuopt[self.menu.currentmenu].size-1, Iif(self.menu.curs[self.menu.currentmenu] > self.menu.menuopt[self.menu.currentmenu].size-1, 0, self.menu.curs[self.menu.currentmenu])));
                
                self updateScrollbar();
                wait 0.15;
            }
            if(self jumpButtonPressed())
            {
                self thread [[self.menu.menufunc[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]]]](self.menu.menuinput[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]], self.menu.menuinput1[self.menu.currentmenu][self.menu.curs[self.menu.currentmenu]]);
                wait 0.2;
            }
        }
        wait 0.05;
    }
}

updateScrollbar()
{
    self.menu.scroller fadeOverTime(0.15);
    self.menu.scroller.alpha = 0.9;
    self.menu.scroller moveOverTime(0.1);
    
    currentMenu = self.menu.currentmenu;
    if(self.menu.curs[currentMenu] >= self.menu.menuopt[currentMenu].size)
        self.menu.curs[currentMenu] = self.menu.menuopt[currentMenu].size - 1;
    if(self.menu.curs[currentMenu] < 0)
        self.menu.curs[currentMenu] = 0;

    // Perfectly matches the individual item line positioning calculation
    self.menu.scroller.y = 106 + (self.menu.curs[currentMenu] * 18); 
}

submenu(input, title)
{
    if (verificationToNum(self.status) >= verificationToNum(self.menu.status[input]))
    {
        if(isDefined(self.menu.options)) self.menu.options destroy();
        
        self.CurMenu = input;
        self.menu.currentmenu = input; // Ensure currentmenu is updated simultaneously

        if (input == "Main Menu")
        {
            self thread StoreText(input, "MAIN MENU");
        }
        else if (input == "PlayersMenu")
        {
            self updatePlayersMenu();
            self thread StoreText(input, "PLAYERS MANAGEMENT");
        }
        else
        {
            self thread StoreText(input, title);
        }
		
        if(isDefined(self.menu.title)) self.menu.title destroy();
        self.menu.title = drawText(title, "objective", 1.4, 60, 82, (1, 1, 1), 0, (0.2, 0.2, 0.2), 0.8, 3);
        self.menu.title FadeOverTime(0.2);
        self.menu.title.alpha = 1;
        
        // Ensure scroller/cursor position indexes cleanly fallback safely
        if(!isDefined(self.menu.curs[input]))
            self.menu.curs[input] = 0;
            
        self.menu.scrollerpos[input] = self.menu.curs[input];
        self updateScrollbar();
    } 
}

add_menu_alt(Menu, prevmenu)
{
    self.menu.getmenu[Menu] = Menu;
    self.menu.menucount[Menu] = 0;
    self.menu.previousmenu[Menu] = prevmenu;
}

add_menu(Menu, prevmenu, status)
{
    self.menu.status[Menu] = status;
    self.menu.getmenu[Menu] = Menu;
    self.menu.scrollerpos[Menu] = 0;
    self.menu.curs[Menu] = 0;
    self.menu.menucount[Menu] = 0;
    self.menu.previousmenu[Menu] = prevmenu;
}

add_option(Menu, Text, Func, arg1, arg2)
{
    Menu = self.menu.getmenu[Menu];
    Num = self.menu.menucount[Menu];
    self.menu.menuopt[Menu][Num] = Text;
    self.menu.menufunc[Menu][Num] = Func;
    self.menu.menuinput[Menu][Num] = arg1;
    self.menu.menuinput1[Menu][Num] = arg2;
    self.menu.menucount[Menu] += 1;
}

openMenu()
{
    self freezeControls(false);
    self StoreText("Main Menu", "MAIN MENU");
	
    if(isDefined(self.menu.title)) self.menu.title destroy();
    self.menu.title = drawText("ALL-STAR", "objective", 1.4, 60, 82, (1, 1, 1), 0, (0.2, 0.2, 0.2), 0.8, 3); 
    self.menu.title FadeOverTime(0.2);
    self.menu.title.alpha = 1;
    
    self.menu.background FadeOverTime(0.2);
    self.menu.background.alpha = 0.82;

    self.menu.border FadeOverTime(0.2);
    self.menu.border.alpha = 0.95;

    self.menu.line FadeOverTime(0.2);
    self.menu.line.alpha = 0.9;

    self updateScrollbar();
    self.menu.open = true;
    
    // Start dynamic live RGB thread loop for accents
    self thread start_rgb_theme();
}

closeMenu()
{
    self notify("stop_rgb");

    if(isDefined(self.menu.title)) 
        self.menu.title.alpha = 0;
    
    if(isDefined(self.menu.options)) 
    {
        for(i = 0; i < self.menu.options.size; i++)
        {
            if(isDefined(self.menu.options[i])) 
                self.menu.options[i].alpha = 0;
        }
    }
    
    if(isDefined(self.menu.background)) 
        self.menu.background.alpha = 0;

    if(isDefined(self.menu.border)) 
        self.menu.border.alpha = 0;

    if(isDefined(self.menu.line)) 
        self.menu.line.alpha = 0;

    if(isDefined(self.menu.scroller)) 
        self.menu.scroller.alpha = 0;    

    self.menu.open = false;
}

destroyMenu(player)
{
    player.MenuInit = false;
    player closeMenu();
    wait 0.3;

    if(isDefined(player.menu.options))
    {
        for(i = 0; i < player.menu.options.size; i++)
        {
            if(isDefined(player.menu.options[i])) 
                player.menu.options[i] destroy();
        }
    }
    
    if(isDefined(player.menu.background)) player.menu.background destroy();
    if(isDefined(player.menu.border)) player.menu.border destroy();
    if(isDefined(player.menu.line)) player.menu.line destroy();
    if(isDefined(player.menu.scroller)) player.menu.scroller destroy();
    if(isDefined(player.menu.title)) player.menu.title destroy();
    player notify("destroyMenu");
}

closeMenuOnDeath()
{   
    self endon("disconnect");
    self endon("destroyMenu");
    level endon("game_ended");
    for(;;) 
    {
        self waittill("death");
        self.menu.closeondeath = true;
        closeMenu();
        self.menu.closeondeath = false;
    }
}

StoreShaders() 
{
    self.menu.border = self drawShader("white", 48, 76, 204, 220, (1, 0, 0), 0, -2);      
    self.menu.background = self drawShader("white", 50, 78, 200, 216, (0.04, 0.04, 0.06), 0, -1); 
    self.menu.line = self drawShader("white", 50, 102, 200, 2, (1, 0, 0), 0, 0);             
    self.menu.scroller = self drawShader("white", 50, -500, 200, 16, (1, 0, 0), 0, 1);       
    
    self.menu.title = self createFontString("objective", 1.4);
    self.menu.title.x = 60;
    self.menu.title.y = 82;
    self.menu.title.alpha = 0;
    self.menu.title.sort = 3;

    self.menu.options = [];
    for(i = 0; i < 12; i++)
    {
        hud = self createFontString("objective", 1.25);
        hud.x = 60;
        hud.y = 108 + (i * 18);
        hud.color = (0.9, 0.9, 0.95);
        hud.alpha = 0;
        hud.glowColor = (0, 0, 0);
        hud.glowAlpha = 0;
        hud.sort = 2;
        
        self.menu.options[i] = hud;
    }
}

start_rgb_theme()
{
    self endon("disconnect");
    self endon("stop_rgb");
    level endon("game_ended");

    // Smooth continuous RGB shifting loop
    hue = 0;
    for(;;)
    {
        rgb = hsv_to_rgb(hue, 1, 1);

        if(isDefined(self.menu.border))
            self.menu.border.color = rgb;
        if(isDefined(self.menu.line))
            self.menu.line.color = rgb;
        if(isDefined(self.menu.scroller))
            self.menu.scroller.color = rgb;
        if(isDefined(self.menu.title))
            self.menu.title.glowColor = rgb;

        hue += 3;
        if(hue >= 360)
            hue = 0;

        wait 0.05;
    }
}

hsv_to_rgb(h, s, v)
{
    c = v * s;
    x = c * (1 - abs((int(h / 60) % 2) + (h / 60 - int(h / 60)) - 1));
    m = v - c;

    r = 0;
    g = 0;
    b = 0;

    if(h >= 0 && h < 60)      { r = c; g = x; b = 0; }
    else if(h >= 60 && h < 120)  { r = x; g = c; b = 0; }
    else if(h >= 120 && h < 180) { r = 0; g = c; b = x; }
    else if(h >= 180 && h < 240) { r = 0; g = x; b = c; }
    else if(h >= 240 && h < 300) { r = x; g = 0; b = c; }
    else if(h >= 300 && h < 360) { r = c; g = 0; b = x; }

    return (r + m, g + m, b + m);
}

StoreText(menu, title)
{
    self.menu.currentmenu = menu;
    
    if(isDefined(self.menu.title))
    {
        self.menu.title setTextUnlimited(title);
        self.menu.title FadeOverTime(0.2);
        self.menu.title.alpha = 1;
    }

    for(i = 0; i < 12; i++)
    {
        if(i < self.menu.menuopt[menu].size)
        {
            // Replaces standard setText to bypass configstrings and show text properly
            self.menu.options[i] setTextUnlimited(self.menu.menuopt[menu][i]);
            self.menu.options[i] FadeOverTime(0.2);
            self.menu.options[i].alpha = 1;
        }
        else
        {
            self.menu.options[i].alpha = 0;
        }
    }
}

getPlayerName(player)
{
    playerName = getSubStr(player.name, 0, player.name.size);
    for(i=0; i < playerName.size; i++)
    {
        if(playerName[i] == "]")
            break;
    }
    if(playerName.size != i)
        playerName = getSubStr(playerName, i + 1, playerName.size);
    return playerName;
}

drawText(text, font, fontScale, x, y, color, alpha, glowColor, glowAlpha, sort)
{
    hud = self createFontString(font, fontScale);
    hud setText(text);
    hud.x = x;
    hud.y = y;
    hud.color = color;
    hud.alpha = alpha;
    hud.glowColor = glowColor;
    hud.glowAlpha = glowAlpha;
    hud.sort = sort;
    return hud;
}

drawShader(shader, x, y, width, height, color, alpha, sort)
{
    hud = newClientHudElem(self);
    hud.elemtype = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setParent(level.uiParent);
    hud setShader(shader, width, height);
    hud.x = x;
    hud.y = y;
    return hud;
}

verificationToNum(status)
{
    if (status == "Host")
        return 2;
    if (status == "User")
        return 1;
    else
        return 0;
} 

Iif(bool, rTrue, rFalse)
{
    if(bool)
        return rTrue;
    else
        return rFalse;
}

fill_scorestreaks()
{
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);
}

fastlast()
{
    // Verify player entity exists
    if ( !isDefined( self ) )
        return;

    // Number of kills/points to remove
    killsToRemove = 2;

    // Standard score value per kill (50 for MW2 FFA, 100 for BO1/BO2)
    scorePerKill = 100; 
    scoreDeduction = killsToRemove * scorePerKill;

    // 1. Deduct Kills
    if ( isDefined( self.pers["kills"] ) && self.pers["kills"] >= killsToRemove )
        self.pers["kills"] -= killsToRemove;
    else
        self.pers["kills"] = 0;

    self.kills = self.pers["kills"];

    // 2. Deduct Score
    if ( isDefined( self.pers["score"] ) && self.pers["score"] >= scoreDeduction )
        self.pers["score"] -= scoreDeduction;
    else
        self.pers["score"] = 0;

    self.score = self.pers["score"];

    // 3. Update custom trickshot menu variables (if used by your menu)
    if ( isDefined( self.pointstowin ) && self.pointstowin >= killsToRemove )
        self.pointstowin -= killsToRemove;
    else if ( isDefined( self.pointstowin ) )
        self.pointstowin = 0;

    if ( isDefined( self.pers["pointstowin"] ) && self.pers["pointstowin"] >= killsToRemove )
        self.pers["pointstowin"] -= killsToRemove;
    else if ( isDefined( self.pers["pointstowin"] ) )
        self.pers["pointstowin"] = 0;


    // 4. Update Team Score (for team-based gametypes like TDM/Search)
    if ( isDefined( level.teamBased ) && level.teamBased && isDefined( self.pers["team"] ) )
    {
        currentTeamScore = getTeamScore( self.pers["team"] );
        if ( currentTeamScore >= scoreDeduction )
            _setTeamScore( self.pers["team"], currentTeamScore - scoreDeduction );
        else
            _setTeamScore( self.pers["team"], 0 );
    }

    // On-screen notification so you know the script executed successfully
    self iPrintLnBold( "^1-[ " + killsToRemove + " Kills / Points Subtracted ]^7" );
    self iPrintLn( "^1Fast Last Activated:^7 Score: " + self.score + " | Kills: " + self.kills );
}

togglesemtex()
{
	if( self.semtex == 0 )
	{
		self.semtex = 1;
		self iprintln( "Lb Semtex ^4ON" );
		self thread lbsemtex();
		wait 0.05;
		self thread semtex();
	}
	else
	{
		if( self.semtex == 1 )
		{
			self.semtex = 0;
			self iprintln( "Lb Semtex ^0OFF" );
			self notify( "stopsemtex" );
		}
	}

}

lbsemtex()
{
	self endon( "stopsemtex" );
	for(;;)
	{
	self waittill( "changed_class" );
	wait 0.05;
	self thread semtex();
	}
	wait 0.5;

}

semtex()
{
	if( !(self hasweapon( "sticky_grenade_mp" )) )
	{
		self takeweapon( "concussion_grenade_mp" );
		self takeweapon( "willy_pete_mp" );
		self takeweapon( "sensor_grenade_mp" );
		self takeweapon( "emp_grenade_mp" );
		self takeweapon( "proximity_grenade_aoe_mp" );
		self takeweapon( "proximity_grenade_mp" );
		self takeweapon( "pda_hack_mp" );
		self takeweapon( "flash_grenade_mp" );
		self takeweapon( "trophy_system_mp" );
		self takeweapon( "tactical_insertion_mp" );
		self giveweapon( "sticky_grenade_mp" );
		self setweaponammoclip( "sticky_grenade_mp", 2 );
	}

}





equipselector()
{
	if( self.equip == 0 )
	{
		self togglesemtex();
	}
	else
	{
		if( self.equip == 1 )
		{
			self givemw3grenade();
		}
	}

}




givemw3grenade()
{
	if( self hasweapon( "tactical_insertion_mp" ) || self hasweapon( "trophy_system_mp" ) || self hasweapon( "flash_grenade_mp" ) || self hasweapon( "pda_hack_mp" ) || self hasweapon( "proximity_grenade_mp" ) || self hasweapon( "proximity_grenade_aoe_mp" ) || self hasweapon( "emp_grenade_mp" ) || self hasweapon( "sensor_grenade_mp" ) || self hasweapon( "willy_pete_mp" ) || self hasweapon( "concussion_grenade_mp" ) )
	{
		self takeweapon( "frag_grenade_mp" );
		self takeweapon( "sticky_grenade_mp" );
		self takeweapon( "hatchet_mp" );
		self takeweapon( "bouncingbetty_mp" );
		self takeweapon( "satchel_charge_mp" );
		self takeweapon( "claymore_mp" );
		self giveweapon( "explodable_barrel_mp" );
		self setweaponammoclip( "explodable_barrel_mp", 2 );
	}
	else
	{
		self takeweapon( "frag_grenade_mp" );
	}
	self takeweapon( "hatchet_mp" );
	self takeweapon( "bouncingbetty_mp" );
	self takeweapon( "satchel_charge_mp" );
	self takeweapon( "claymore_mp" );
	self giveweapon( "explodable_barrel_mp" );
	self setweaponammoclip( "explodable_barrel_mp", 2 );

}

toggle_instant_next_class()
{
    if(!isDefined(self.auto_next_class)) self.auto_next_class = false;
    self.auto_next_class = !self.auto_next_class;

    if(self.auto_next_class)
    {
        self iPrintLn("Instant Next Class: ^4ON");
        self iPrintLnBold("Press [{+actionslot 2}] ^7to Swap");
    }
    else
    {
        self iPrintLn("Instant Next Class: ^0OFF");
    }
}

do_instant_next_class()
{
    // Define the classes in order (standard BO2 class names)
    classes = array("CLASS_CUSTOM1", "CLASS_CUSTOM2", "CLASS_CUSTOM3", "CLASS_CUSTOM4", "CLASS_CUSTOM5");

    currentClass = self.pers["class"];
    nextIndex = 0;

    // Find our current class index and move to the next
    for(i = 0; i < classes.size; i++)
    {
        if(currentClass == classes[i])
        {
            nextIndex = i + 1;
            break;
        }
    }

    // Loop back to the first class if we are at the end
    if(nextIndex >= classes.size) nextIndex = 0;

    self.pers["class"] = classes[nextIndex];
    
    // Instantly give the new loadout 
    self maps\mp\gametypes\_class::giveloadout(self.pers["team"], self.pers["class"]);
}

knifelunge()
{
	if( self.lunge == 0 )
	{
		self.lunge = 1;
		self iprintln( "Easier Lunges [^2ON^7]" );
		self iprintlnbold( "Look at a ^1Bot^7 and then knife" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 100 );
		setdvar( "aim_automelee_range", 250 );
		setdvar( "aim_automelee_move_limit", 0 );
	}
	else
	{
		self.lunge = 0;
		self iprintln( "Knife Lunges [^1OFF^7]" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 40 );
		setdvar( "aim_automelee_range", 100 );
		setdvar( "aim_automelee_move_limit", 0.1 );
		self notify( "stop_knfelunge" );
	}

}

autocanswap()
{
	if( !(IsDefined( self.autocanswap )) )
	{
		self.autocanswap = 1;
		self iprintln( "Auto Canswap: ^4On" );
		self thread doautocanswap();
	}
	else
	{
		self.autocanswap = undefined;
		self iprintln( "Auto Canswap: ^0Off" );
		self notify( "stop_cswap" );
	}

}

doautocanswap()
{
	self endon( "disconnect" );
	self endon( "stop_cswap" );
	for(;;)
	{
	self waittill( "weapon_change", weapon );
	self seteverhadweaponall( 0 );
	}
	wait 0.1;

}

toggle_noclip()
{
	self notify( "StopNoClip" );
	if( !(IsDefined( self.noclip )) )
	{
		self.noclip = 0;
	}
	self.noclip = !(self.noclip);
	if( self.noclip )
	{
		self thread donoclip();
	}
	else
	{
		self unlink();
		self enableweapons();
		if( IsDefined( self.noclipentity ) )
		{
			self.noclipentity delete();
			self.noclipentity = undefined;
		}
	}
	if( self.noclip )
	{
	}
	else
	{
	}
	self iprintln( "^1ON", "^7NoClip" );

}

donoclip()
{
	self notify( "StopNoClip" );
	if( IsDefined( self.noclipentity ) )
	{
		self.noclipentity delete();
		self.noclipentity = undefined;
	}
	self endon( "StopNoClip" );
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "game_ended" );
	
	self.noclipentity = spawn( "script_origin", self.origin, 1 );
	self.noclipentity.angles = self.angles;
	self playerlinkto( self.originobj, undefined );
	
	noclipfly = 0;
	self iprintln( "Press [{+smoke}] To ^2Enable^7 NoClip." );
	self iprintln( "Press [{+gostand}] To Move Fast." );
	self iprintln( "Press [{+stance}] To ^1Disable^7 NoClip." );
	
	while( self.noclip && IsDefined( self.noclip ) )
	{
		// 1. Check if we need to initialize noclip link
		if (!noclipfly)
		{
			self disableweapons();
			self playerlinkto( self.noclipentity );
			noclipfly = 1;
		}
		else
		{
			// 2. Check for exit FIRST so it always registers instantly
			if (self stancebuttonpressed())
			{
				self unlink();
				self enableweapons();
				noclipfly = 0;
				// Optional: if you want turning off noclip to also toggle off self.noclip loop flag:
				self.noclip = 0; 
				break;
			}
			
			// 3. Check for movement inputs
			if (self secondaryoffhandbuttonpressed())
			{
				self.noclipentity moveto( self.origin + ( anglestoforward( self getplayerangles() ) * 30 ), 0.01 );
			}
			else if (self jumpbuttonpressed())
			{
				self.noclipentity moveto( self.origin + ( anglestoforward( self getplayerangles() ) * 170 ), 0.01 );
			}
		}
		wait 0.01;
	}
}

vector_scale( vec, scale )
{
    return ( vec[0] * scale, vec[1] * scale, vec[2] * scale );
}

toggle_high_jump()
{
    if(!isDefined(self.high_jump)) self.high_jump = false;
    self.high_jump = !self.high_jump;

    if(self.high_jump)
    {
        self setClientDvar("jump_height", 80);
        self iPrintLn("Jump Higher: ^4ON");
    }
    else
    {
        self setClientDvar("jump_height", 44);
        self iPrintLn("Jump Higher: ^0OFF");
    }
}

doladderpush()
{
	if(self.doladderpush == 0)
	{
		self.doladderpush = 1;
		setdvar("jump_ladderPushVel", 998);
		setdvar("bg_ladder_yawcap", 360);
		self iprintln("[^4ON^7]");
	}
	else
	{
		self.doladderpush = 0;
		setdvar("jump_ladderPushVel", 128);
		self iprintln("[^0OFF^7]");
	}
}

setup_single_bot()
{
    start = self getEye(); 
    end = start + (anglestoforward(self getplayerangles()) * 10000);
    trace = bulletTrace(start, end, false, self);
    targetPos = trace["position"];

    bestBot = undefined; 
    shortestDist = 999999;

    foreach(player in level.players) {
        if((isDefined(player.pers["isBot"]) || player is_bot_check()) && isAlive(player)) {
            dist = distance(player.origin, targetPos);
            if(dist < shortestDist) { 
                shortestDist = dist; 
                bestBot = player;
            }
        }
    }

    if(isDefined(bestBot)) {
        bestBot setOrigin(targetPos);
        bestBot setPlayerAngles(vectortoangles(self.origin - bestBot.origin));
        bestBot setVelocity((0,0,0));

        // LOCK FREEZE STATE INSTANTLY
        bestBot.is_frozen = true;
        bestBot freezeControls(true);
        bestBot thread enforce_bot_freeze();

        self iPrintLn("^2Bot Teleported & Frozen^7");
    }
}

is_bot_check()
{
    if(IsDefined(self.isbot) && self.isbot)
        return true;
    if(isDefined(self.sessionstate) && self.sessionstate == "spectator")
        return false;
    
    // Fallback check matching typical Plutonium/T6 bot properties
    return (isDefined(self.name) && (isSubStr(self.name, "Bot") || self.pers["team"] == "axis" || self.pers["team"] == "allies")) && !isPlayer(self); // handles standard entity checks if necessary
}

platform()
{
        // Check if a platform already exists and delete it to prevent stacking
    if(isDefined(self.custom_platform)) 
        self.custom_platform delete();

    // Spawn the platform at the player's current feet position (self.origin)
    // We subtract a small amount from the Z-axis (-5) to ensure you are standing 'on' it
    spawnPos = (self.origin[0], self.origin[1], self.origin[2] - 5);

    self.custom_platform = spawn("script_model", spawnPos);
    
    // Use the supply drop model already precached in your script [cite: 204, 362]
    self.custom_platform setModel("t6_wpn_supply_drop_trap");
    
    // Align the platform with your current facing direction [cite: 362]
    self.custom_platform.angles = (0, self.angles[1], 0);
    
    // Set contents to 1 to ensure it has physical collision [cite: 362]
    self.custom_platform setContents(1);
}

toggle_post_game_move()
{
    if(!isDefined(self.post_game_move)) self.post_game_move = false;
    self.post_game_move = !self.post_game_move;

    if(self.post_game_move) { 
        self iprintln("Post-Game Move: ^4ON");
        self thread do_post_game_move_logic();
    }
    else { 
        self iprintln("Post-Game Move: ^0OFF");
        self notify("stop_post_game_move");
    }
}

do_post_game_move_logic()
{
    self endon("disconnect");
    self endon("stop_post_game_move");

    // Wait for the match to conclude [cite: 385]
    level waittill("game_ended");

    for(;;) 
    { 
        // Forcefully unfreeze the player so they can move during the killcam/scoreboard 
        self freezeControls(false);
        
        // Ensure HUD remains visible during the transition 
        self setClientUiVisibilityFlag("hud_visible", 0);
        
        wait 0.05; 
    }
}

spawn_launch_rcxd()
{
    if(!isDefined(self.rcxd_array)) self.rcxd_array = [];
    
    // CHANGED: Use player's origin (feet) instead of bulletTrace
    spawnPos = self.origin; 
    
    if(self.rcxd_array.size >= 1) {
        self.rcxd_array[0] delete();
        for(i = 0; i < self.rcxd_array.size - 1; i++) self.rcxd_array[i] = self.rcxd_array[i+1];
        self.rcxd_array[self.rcxd_array.size - 1] = undefined;
        newArray = [];
        foreach(item in self.rcxd_array) if(isDefined(item)) newArray[newArray.size] = item;
        self.rcxd_array = newArray;
    }
    
    new_rcxd = spawn("script_model", spawnPos);
    new_rcxd setModel("veh_t6_drone_rcxd_alt");
    new_rcxd setContents(1);
    self.rcxd_array[self.rcxd_array.size] = new_rcxd;
    self thread rcxd_bounce_logic(new_rcxd);
}

rcxd_bounce_logic(rcxd)
{
    self endon("disconnect"); 
    // Removed self endon("death"); so it survives respawn
    rcxd endon("death");
    for(;;) 
    { 
        if(isDefined(self) && isAlive(self) && distance(self.origin, rcxd.origin) < 120) 
        {
            forward = anglesToForward(self getPlayerAngles());
            self setVelocity(self getVelocity() + (forward[0] * 1100, forward[1] * 1100, 1200)); 
            wait 1.0;
        }
        wait 0.05; 
    }
}

toggle_cp_stall()
{
    if(!isDefined(self.cp_stall)) self.cp_stall = false;
    self.cp_stall = !self.cp_stall;
    if(self.cp_stall) { // [cite: 100]
        self iprintln("CP Stall: ^3ON"); 
        self thread do_cp_stall(); // [cite: 101]
    }
    else { 
        self iprintln("CP Stall: ^1OFF"); 
        self notify("stop_cp_stall"); // [cite: 102]
    }
}

do_cp_stall()
{
    self endon("disconnect"); self endon("stop_cp_stall"); self endon("death");
    for(;;) {
        // Only trigger if the button is held for at least 0.2 seconds
        if(self useButtonPressed() && !self isonladder() && !self.menu["open"]) {
            
            heldTime = 0;
            while(self useButtonPressed() && heldTime < 0.2) {
                heldTime += 0.05;
                wait 0.05;
            }

            // If still held after the delay, start the stall
            if(self useButtonPressed()) {
                bar = self createPrimaryProgressBar();
                bar_text = self createPrimaryProgressBarText();
                bar_text setText("CAPTURING");
                stallPos = self.origin;
                progress = 0;
                
                while(self useButtonPressed() && progress < 100) {
                    progress += 1.8;
                    bar updateBar(progress / 100);
                    self setOrigin(stallPos);
                    self setVelocity((0,0,0));
                    wait 0.05;
                }
                bar destroyElem();
                bar_text destroyElem();
            }
            wait 0.5;
        }
        wait 0.05;
    }
}

altswap()
{
    self giveweapon( "fiveseven_mp" );
    self iPrintLn("Alt Swap: ^1Five-Seven Given");
}

toggleprone()
{
	if( self.forceprone != 1 )
	{
		self.forceprone = 1;
		self iprintln( "Mid-Air Prone: [^2ON^7]" );
		self thread forceprone();
	}
	else
	{
		self.forceprone = 0;
		self iprintln( "Mid-Air Prone: [^1OFF^7]" );
		self notify( "stopProne" );
	}

}

forceprone()
{
	self endon( "stopProne" );
	for(;;)
	{
	if( self stancebuttonpressed() )
	{
		wait 0.1;
		self setstance( "prone" );
	}
	waitframe();
	}

}

waitframe()
{
	wait 0.05;

}

cowboy()
{
    self endon( "disconnect" );

    if ( !IsDefined( self.cowboybind ) )
        self.cowboybind = 0;

    if ( self.cowboybind == 0 )
    {
        self.cowboybind = 1;
        self iprintln( "Cowboy: [^2ON]" );
        
        // Instantly apply the cowboy effect when turned on
        self.doingcowboy = 1;
        self setclientdvar( "cg_gun_z", "8" );
    }
    else
    {
        self.cowboybind = 0;
        self iprintln( "Cowboy: [^1OFF]" );
        
        // Revert the effect when turned off
        self.doingcowboy = 0;
        self setclientdvar( "cg_gun_z", "0" );
    }
}

cowboy_monitor()
{
    self endon( "disconnect" );
    self endon( "stop_cowboy" );

    for ( ;; )
    {
        // Keep checking if the feature is active and handle any continuous background logic here
        if ( IsDefined( self.cowboybind ) && self.cowboybind == 1 )
        {
            // Optional: Ensure dvar stays forced if something else resets it
            if ( GetDvarInt( "cg_gun_z" ) != 8 )
            {
                self setclientdvar( "cg_gun_z", "8" );
            }
        }
        
        wait 0.05;
    }
}

button_monitor()
{
    self endon("disconnect");
    self endon("death");
    
    for(;;) 
    {
        // 1. Instant Next Class
        if(isDefined(self.auto_next_class) && self.auto_next_class && self actionSlotTwoButtonPressed() && !self adsbuttonpressed())
        {
            self thread do_instant_next_class();
            while(self actionSlotTwoButtonPressed()) wait 0.05; 
        }       

        // 2. Prone + ActionSlot 2: Drop Weapon
        if(self getStance() == "prone" && self actionSlotTwoButtonPressed())
        {
            self thread drop_current_weapon();
            while(self actionSlotTwoButtonPressed()) wait 0.05;
        }
          
        // 3. Crouch + ActionSlot 3: Toggle One Bullet
        if(self getStance() == "crouch" && self actionSlotThreeButtonPressed())
        {
            self thread toggle_one_bullet();
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }   

        // 4. Prone + ActionSlot 1: Fill Streaks
        if(self getStance() == "prone" && self actionSlotOneButtonPressed())
        {
            self thread fill_scorestreaks();
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }

        // 5. Prone + Aim + Left D-Pad: Unfreeze Bots
        if(self getStance() == "prone" && self adsbuttonpressed() && self actionSlotThreeButtonPressed())
        {
            self thread set_bots_freeze_state(false);
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }
        // 6. Prone + Left D-Pad: Freeze Bots (Only if NOT aiming)
        else if(self getStance() == "prone" && !self adsbuttonpressed() && self actionSlotThreeButtonPressed())
        {
            self thread set_bots_freeze_state(true);
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }

        wait 0.05;
    }
}

drop_current_weapon() 
{ 
    weapon = self getcurrentweapon();
    if(weapon != "none") 
        self dropitem(weapon);
}

toggle_one_bullet()
{
    self.one_bullet = true;
    self.one_bullet_weapon = self getCurrentWeapon();
    
    self thread closeMenu(); // Fixed function name to match your closeMenu() definition
    self thread do_one_bullet_logic();
}

do_one_bullet_logic()
{
    self endon("disconnect"); 
    self endon("stop_one_bullet"); 
    self endon("death");
    
    for(;;) 
    {
        currentWeapon = self getCurrentWeapon(); 
        if(currentWeapon == self.one_bullet_weapon && self isReloading()) {
            while(self isReloading()) wait 0.05;
            self.one_bullet = false; 
            self notify("stop_one_bullet"); 
            break;
        } 
        if(currentWeapon == self.one_bullet_weapon && !self attackButtonPressed()) {
            if(self getWeaponAmmoClip(currentWeapon) > 1) 
                self setWeaponAmmoClip(currentWeapon, 1); 
        } 
        wait 0.05;
    }
}

monitorPositionButtons()
{
    self endon("disconnect");
    self endon("death");
    for(;;)
    {
        // Add this check to skip logic if the menu is open
        if(!self.menu["open"])
        {
            // SAVE: Crouch + Up D-Pad
            if(self getStance() == "crouch" && self actionSlotTwoButtonPressed())
            {
                self.pers["saved_origin"] = self.origin; 
                self.pers["saved_angles"] = self getPlayerAngles(); 
                while(self actionSlotTwoButtonPressed()) wait 0.05; 
            }

// Update the LOAD logic in monitorPositionButtons
if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
{
    if(isDefined(self.pers["saved_origin"]))
    {
        self setOrigin(self.pers["saved_origin"]); 
        self setPlayerAngles(self.pers["saved_angles"]);
        
        // Reset velocity to stop existing momentum
        self setVelocity((0,0,0));
        
        // Explicitly re-set jump height
        if(isDefined(self.high_jump) && self.high_jump)
            self setClientDvar("jump_height", 80);
        else
            self setClientDvar("jump_height", 44);
    }
    while(self actionSlotOneButtonPressed()) wait 0.05; 
}
        }
        wait 0.05; 
    }
}

nitrotext()
{
    self endon( "disconnect" );
    self endon( "game_ended" );
    
    if( !(IsDefined( self.nitrotext )) )
    {
        self.nitrotext = true; // Set this so it doesn't loop create multiple elements
        self.title4 = createfontstring( "console", 1 );
        self.title4 setpoint( "LEFT", "CENTER", -420, 230 );
        self.title4 settext( "Press [{+speed_throw}] & [{+melee}] to open ALL-STAR" );
        
        // Start the RGB color-changing thread
        self thread nitrotext_rgb_loop();
    }
}

nitrotext_rgb_loop()
{
    self endon( "disconnect" );
    self endon( "game_ended" );

    // Ensure the text element exists before looping
    if ( !IsDefined( self.title4 ) )
        return;

    // Infinite loop shifting through RGB values smoothly
    while( IsDefined( self.title4 ) )
    {
        // Red to Yellow
        self.title4 fadeOverTime( 1 );
        self.title4.color = (1, 0, 0);
        wait 1;

        // Yellow to Green
        self.title4 fadeOverTime( 1 );
        self.title4.color = (0, 1, 0);
        wait 1;

        // Green to Cyan
        self.title4 fadeOverTime( 1 );
        self.title4.color = (0, 1, 1);
        wait 1;

        // Cyan to Blue
        self.title4 fadeOverTime( 1 );
        self.title4.color = (0, 0, 1);
        wait 1;

        // Blue to Pink/Purple
        self.title4 fadeOverTime( 1 );
        self.title4.color = (1, 0, 1);
        wait 1;

        // Pink back to Red
        self.title4 fadeOverTime( 1 );
        self.title4.color = (1, 0, 0);
        wait 1;
    }
}

low()
{
	self endon( "disconnect" );
	
	// Initialize state tracking if it doesn't exist
	if( !IsDefined( self.doingcowboy ) )
	{
		self.doingcowboy = 0;
	}

	// Toggle the state
	if( self.doingcowboy == 0 )
	{
		self.doingcowboy = 1;
		self setclientdvar( "cg_gun_z", "-8" );
		self iprintln( "Low Cowboy: [^2ON]" );
		
		// Start a monitoring thread while active
		self thread cowboy2_monitor();
	}
	else
	{
		self.doingcowboy = 0;
		self setclientdvar( "cg_gun_z", "0" );
		self iprintln( "Low Cowboy: [^1OFF]" );
		
		// Notify to stop the monitoring loop
		self notify( "stopLow" );
	}
}

cowboy2_monitor()
{
	self endon( "disconnect" );
	self endon( "stopLow" );

	while( self.doingcowboy == 1 )
	{
		// Put any persistent loop code here if needed, 
		// otherwise just keep the thread alive while toggled on.
		wait 0.1;
	}
}

autoprone()
{
	if( self.autoprone == 0 )
	{
		self iprintln( "Afterhit: ^2Set" );
		self.autoprone = 1;
		level waittill( "game_ended" );
		self thread laydown1();
	}
	else
	{
		self iprintln( "Afterhit: ^1OFF" );
		self notify( "notprone" );
		self.autoprone = 0;
	}

}

laydown1()
{
	self endon( "notprone" );
	self endon( "disconnect" );
	self setstance( "prone" );
	wait 0.5;
	self setstance( "prone" );
	wait 0.5;
	self setstance( "prone" );
	wait 0.5;
	self setstance( "prone" );
	wait 0.5;
	self setstance( "prone" );
	wait 0.5;
	self setstance( "prone" );
	wait 0.5;

}

togglevtolafter()
{
	if( !(self.vtolafterhitlol) )
	{
		self iprintln( "Afterhit: [^2ON^7]" );
		self thread vtolafterhitlol();
		self.vtolafterhitlol = 1;
	}
	else
	{
		if( self.vtolafterhitlol )
		{
			self iprintln( "Afterhit: [^1OFF^7]" );
			self notify( "vtolafter" );
			self.vtolafterhitlol = 0;
		}
	}

}

vtolafterhitlol()
{
	self endon( "disconnect" );
	self endon( "vtolafter" );
	level endon( "final_killcam_done" );
	level waittill( "game_ended" );
	if( self.vtolvision )
	{
		self thread vtolvision();
	}

}

vtolvision( enable )
{
	self endon( "disconnect" );
	self endon( "vtolstop" );
	if( enable )
	{
		self setclientflag( 3 );
	}
	else
	{
		self clearclientflag( 3 );
	}

}

mw2endgame()
{
	if( self.pers[ "mw2aft"] == 0 )
	{
		self iprintln( "Afterhit: [^2ON]" );
		self.pers["mw2aft"] = 1;
		level waittill( "game_ended" );
		self freezecontrols( 0 );
		wait 2;
		self freezecontrols( 1 );
	}
	else
	{
		self iprintln( "Afterhit: [^1OFF]" );
		self.pers["mw2aft"] = 0;
	}

}

toggleclusterafter()
{
	if( !(self.clusterafterhit) )
	{
		self iprintln( "Afterhit: [^2ON^7]" );
		self thread clusterafterhit();
		self.clusterafterhit = 1;
	}
	else
	{
		if( self.clusterafterhit )
		{
			self iprintln( "Afterhit: [^1OFF^7]" );
			self notify( "clusterafter" );
			self.clusterafterhit = 0;
		}
	}

}

clusterafterhit()
{
	self endon( "disconnect" );
	self endon( "clusterafter" );
	level endon( "final_killcam_done" );
	level waittill( "game_ended" );
	if( self.clustvision )
	{
		self thread clustvision();
	}

}

toggleagrafter()
{
	if( !(self.agrvisionafterhit) )
	{
		self iprintln( "Afterhit: [^2ON^7]" );
		self thread agrvisionafterhit();
		self.agrvisionafterhit = 1;
	}
	else
	{
		if( self.agrvisionafterhit )
		{
			self iprintln( "Afterhit: [^1OFF^7]" );
			self notify( "agrafter" );
			self.agrvisionafterhit = 0;
		}
	}

}

agrvisionafterhit()
{
	self endon( "disconnect" );
	self endon( "agrafter" );
	level endon( "final_killcam_done" );
	level waittill( "game_ended" );
	if( self.agrvision )
	{
		self thread agrvision();
	}

}

oneafterhit()
{
	self endon( "disconnect" );
	self endon( "angleafter" );
	level endon( "final_killcam_done" );
	level waittill( "game_ended" );
	if( self.oneafterhit )
	{
		self setplayerangles( self.angles + ( 0, -180, 0 ) );
	}
	else
	{
		self setplayerangles( self.angles + ( 0, 0, 0 ) );
	}

}

oneafter()
{
	if( !(self.oneafterhit) )
	{
		self iprintln( "Afterhit: [^2ON^7]" );
		self thread oneafterhit();
		self.oneafterhit = 1;
	}
	else
	{
		if( self.oneafterhit )
		{
			self iprintln( "Afterhit: [^1OFF^7]" );
			self notify( "angleafter" );
			self.oneafterhit = 0;
		}
	}

}

clustvision( enable )
{
	self endon( "disconnect" );
	self endon( "cluststop" );
	if( enable )
	{
		self setclientflag( 2 );
	}
	else
	{
		self clearclientflag( 2 );
	}

}

agrvision( enable )
{
	self endon( "disconnect" );
	self endon( "agrstop" );
	if( enable )
	{
		self setclientflag( 1 );
	}
	else
	{
		self clearclientflag( 1 );
	}

}

afterhit( gun )
{
	self endon( "disconnect" );
	if( self.afterhit == 0 )
	{
		self iprintln( "Afterhit: ^2Set" );
		self thread doafterhit( gun );
		self.afterhit = 1;
	}
	else
	{
		self iprintln( "Afterhit: ^1Unset" );
		self.afterhit = 0;
		keepweapon = "";
		self notify( "afterhit" );
	}

}

doafterhit( gun )
{
	self endon( "afterhit" );
	level waittill( "game_ended" );
	keepweapon = self getcurrentweapon();
	self freezecontrols( 0 );
	self giveweapon( gun );
	self takeweapon( keepweapon );
	self switchtoweapon( gun );
	wait 0.001;
	self freezecontrols( 1 );

}

gravity()
{
    // Initialize the state variable if it doesn't exist yet
    if(!isDefined(self.grav_level))
        self.grav_level = 0;

    // Cycle through 4 different levels (0 to 3)
    self.grav_level = (self.grav_level + 1) % 4;

    switch(self.grav_level)
    {
        case 0:
            setDvar("bg_gravity", "800");
            self iPrintln("Gravity: ^1NORMAL (^2800^1)");
            break;
        case 1:
            setDvar("bg_gravity", "300");
            self iPrintln("Gravity: ^3LOW (^2300^3)");
            break;
        case 2:
            setDvar("bg_gravity", "200");
            self iPrintln("Gravity: ^5MOON (^2200^5)");
            break;
        case 3:
            setDvar("bg_gravity", "100");
            self iPrintln("Gravity: ^6ZERO-G (^2100^6)");
            break;
    }
}

instashoot()
{
	if( IsDefined( self.autocanswap ) && self.autocanswap == 1 )
	{
		self iprintln( "^1Disable Auto Canswap before enabling Instashoots." );
	}
	if( !(IsDefined( self.pers[ "insta"] )) )
	{
		self.pers["insta"] = 1;
		self thread instantlyshot();
		self iprintln( "Instant Shoot: [^2ON]" );
	}
	else
	{
		self.pers["insta"] = undefined;
		self notify( "stop_instashoots" );
		self iprintln( "Instant Shoot: [^1OFF]" );
	}

}

instantlyshot()
{
	self endon( "disconnect" );
	self endon( "stop_instashoots" );
	for(;;)
	{
	self waittill( "weapon_change", weapon );
	check = getweaponclass( weapon );
	if( check == "weapon_sniper" )
	{
		self disableweapons();
		wait 0.01;
		self enableweapons();
	}
	wait 0.01;
	}

}

setscore( player, kills )
{
	// Skip if the player is a bot or not defined
	if ( !isDefined( player ) || ( isDefined( player.pers["isBot"] ) && player.pers["isBot"] ) || player isTestClient() )
	{
		return;
	}

	if( kills < 0 )
	{
		kills = 0;
	}

	player.pointstowin = kills;
	player.pers["pointstowin"] = player.pointstowin;
	player.score *= 100;
	player.pers["score"] = player.score;
	player.kills = kills;
	player.deaths *= 2;
	player.headshots *= 2;
	player.pers["kills"] = player.kills;
	player.pers["deaths"] = player.deaths;
	player.pers["headshots"] = player.headshots;
}

// Main entry point to thread the logic onto a player
initBotCantWin()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    // Ensure this thread only runs if the player is actually a bot
    if ( !self isBotPlayer() )
    {
        return;
    }

    self thread botcantwin();
}

// Function to keep the bot's score below the winning threshold
botcantwin()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for(;;)
    {
        wait 0.01;

        if ( isDefined( level.scorelimit ) && level.scorelimit > 0 )
        {
            // Check if they are 1 point away from winning (or already over)
            if ( self.score >= ( level.scorelimit - 1 ) || ( isDefined( self.pers["pointstowin"] ) && self.pers["pointstowin"] >= ( level.scorelimit - 1 ) ) )
            {
                // Wipes visual/internal scores
                self.score = 0;
                self.pers["score"] = 0;
                self.pointstowin = 0;
                self.pers["pointstowin"] = 0;

                // Clears kills, deaths, headshots
                self.kills = 0;
                self.pers["kills"] = 0;
                self.deaths = 0;
                self.pers["deaths"] = 0;
                self.headshots = 0;
                self.pers["headshots"] = 0;

                // Updates the scoreboard UI immediately
                if ( isDefined( self.scoreProvider ) )
                    self.scoreProvider = 0;
            }
        }
    }
}

// Helper function to check if the entity is a bot across different CoD titles
isBotPlayer()
{
    if ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] )
        return true;
        
    if ( isDefined( self.isbot ) && self.isbot )
        return true;
        
if ( self isTestClient() )
    return true;

    return false;
}

spawn_bots_action( amount )
{
    // Enforce 2-bot cycling logic when spawning 1 single bot
    enforceSingleBotMode = ( amount == 1 );

    for( i = 0; i < amount; i++ )
    {
        self spawn_single_bot_logic( enforceSingleBotMode );
        wait 0.15; // Delay prevents engine overload during rapid spawns
    }
    
    if( enforceSingleBotMode )
        self iPrintLn( "^2Bot Ready / Respawned (Max 2 Active)^7" );
    else
        self iPrintLn( "^2Spawned " + amount + " Bots^7" );
}

spawn_single_bot_logic( enforceSingleBotMode )
{
    if( !isDefined( enforceSingleBotMode ) )
        enforceSingleBotMode = false;

    if( enforceSingleBotMode )
    {
        active_bots = [];
        dead_bot = undefined;

        foreach( player in level.players )
        {
            if( isDefined( player ) && ( player isBotPlayer() || player is_bot_check() ) )
            {
                active_bots[ active_bots.size ] = player;
                
                // Track if one of the existing bots is currently dead/spectating
                if( !isAlive( player ) || player.sessionstate != "playing" )
                {
                    dead_bot = player;
                }
            }
        }

        // If 2 bots are already in the game, recycle/respawn one of them instead of adding a 3rd
        if( active_bots.size >= 2 )
        {
            // Prefer respawning the dead bot if one exists; otherwise reuse the first bot
            targetBot = isDefined( dead_bot ) ? dead_bot : active_bots[0];
            
            targetBot thread force_bot_spawn( self );
            return;
        }
    }

    // If there are less than 2 bots (or auto-spawning 17 for FFA/TDM), spawn a new test client
    bot = addtestclient();
    
    if( isDefined( bot ) )
    {
        bot.pers["isBot"] = true;
        bot.isbot = true;
        
        bot thread force_bot_spawn( self );
    }
}

force_bot_spawn( hostPlayer )
{
    self endon( "disconnect" );
    
    // Assign Bot to the opposite team of the host
    if( hostPlayer.pers["team"] == "allies" )
        botTeam = "axis";
    else
        botTeam = "allies";
        
    self.pers["team"] = botTeam;
    self.team = botTeam;
    self.sessionteam = botTeam;
    self.pers["class"] = "CLASS_CUSTOM1";
    self.class = "CLASS_CUSTOM1";

    wait 0.05;

    // SnD Mid-Round Bypass: Force session state out of spectator/dead
    self.sessionstate = "playing";
    self.spectatorclient = -1;
    self.killcamentity = -1;
    self.archivetime = 0;
    self.psoffsettime = 0;
    
// Force immediate spawn logic
    if ( isDefined( level.spawnPlayer ) )
        self [[ level.spawnPlayer ]]();
    else
        self [[ level.spawnClient ]]();

    // Trigger Bot Custom Spawn Teleport
    self thread watchBotCustomSpawnOnRespawn();
}

toggle_unlimited_equipment()
{
    if(!isDefined(self.unlimited_equip)) self.unlimited_equip = false;
    self.unlimited_equip = !self.unlimited_equip;

    if(self.unlimited_equip)
    {
        self iPrintLn("Unlimited Equipment: ^3ON");
        self thread do_unlimited_equipment();
    }
    else
    {
        self iPrintLn("Unlimited Equipment: ^1OFF");
        self notify("stop_unlimited_equip");
    }
}

do_unlimited_equipment()
{
    self endon("disconnect");
    self endon("stop_unlimited_equip");
    
    for(;;)
    {
        // Get current lethal and tactical equipment
        lethal = self getcurrentoffhand();
        
        if(isDefined(lethal) && lethal != "none")
        {
            // Set ammo to 2 (standard max for most equipment) 
            self setweaponammoclip(lethal, 2);
        }
        wait 0.1;
    }
}

doUAV()
{
    self setclientuivisibilityflag("g_compassShowEnemies", 1); // [cite: 76]
}

toggle_uav()
{
    if(!isDefined(self.uav_always_on)) self.uav_always_on = false;
    self.uav_always_on = !self.uav_always_on;
    if(self.uav_always_on) // [cite: 77]
    {
        self setclientuivisibilityflag("g_compassShowEnemies", 1);
        self iPrintLn("UAV: ^3ON"); // [cite: 78]
    }
    else
    {
        self setclientuivisibilityflag("g_compassShowEnemies", 0); // [cite: 79]
        self iPrintLn("UAV: ^1OFF");
    }
}

toggleTiltScreen()
{
    if(!isDefined(self.pers["tilt_screen"]))
        self.pers["tilt_screen"] = false;

    self.pers["tilt_screen"] = !self.pers["tilt_screen"];
    
    if(self.pers["tilt_screen"])
        self iPrintLn("Tilt Screen: ^2ON");
    else
        self iPrintLn("Tilt Screen: ^1OFF");

    self notify("stop_tilt_screen");

    if (self.pers["tilt_screen"])
    {
        self thread tiltScreenLoop();
    }
    else
    {
        angles = self getPlayerAngles();
        self setPlayerAngles((angles[0], angles[1], 0));
    }
}

tiltScreenLoop()
{
    self endon("disconnect");
    self endon("death");
    self endon("stop_tilt_screen");

    while (self.pers["tilt_screen"])
    {
        angles = self getPlayerAngles();
        // Roll angle set to 20 degrees
        self setPlayerAngles((angles[0], angles[1], 20));
        wait 0.05;
    }
}

enable_wallbang() 
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("weapon_fired", gun);

        // valid weapon
        if (!is_allowed_weapon(gun)) { continue; }

        // ignore bots
        if (isdefined(self.pers["isbot"]) && self.pers["isbot"]) { continue; }

        fwd_direction = anglestoforward(self getplayerangles());
        eye_position = self geteye();
        trace_points = [];
        trace_points[0] = bullettrace(eye_position, eye_position + vector_multiply(fwd_direction, 1000000), false, self)["position"];

        step = 1;
        while (step < 25)
        {
            last_pos = trace_points[step - 1];
            trace_result = bullettrace(last_pos, last_pos + vector_multiply(fwd_direction, 1000000), true, self);
            trace_points[step] = trace_result["position"];

            while (distance(trace_points[step - 1], trace_points[step]) < 1) 
            {
                trace_points[step] += vector_multiply(fwd_direction, 0.25);
            }

            if (trace_points[step] != trace_points[step - 1]) 
            {
                magicbullet(self getcurrentweapon(), trace_points[step], vector_multiply(fwd_direction, 1000000), self);
            }

            step++;
        }
        wait 0.05;
    }
}

is_allowed_weapon(gun) 
{
    if (!isdefined(gun)) {
        return false;
    }

    weapon_type = getweaponclass(gun);
    
    // Check for specific overrides first
    if (gun == "hatchet_mp" || issubstr(gun, "saritch") || issubstr(gun, "sa58_")) {
        return true;
    }

    // Check for standard game weapon classes
    if (weapon_type == "weapon_sniper" || 
        weapon_type == "weapon_assault" || 
        weapon_type == "weapon_smg") {
        return true;
    }

    return false;
}

is_sniper_weapon(gun) 
{
	if (!(isdefined(gun))) {
		return false;
	}

	weapon_type = getweaponclass(gun);
	if (gun == "hatchet_mp" || issubstr(gun, "saritch") || issubstr(gun, "sa58_") || weapon_type == "weapon_sniper") {
		return true;
	}

	return false;
}

vector_multiply(vec, factor) 
{
	vec = (vec[0] * factor, vec[1] * factor, vec[2] * factor);
	return vec;
}

autoPlantMonitor() {
    level endon("game_ended");
    level endon("bomb_planted");

    for(;;) {
        timeLeft = maps\mp\gametypes\_globallogic_utils::getTimeRemaining() / 1000;

        if (timeLeft <= 1.5 && timeLeft > 0) {
            foreach(player in level.players) {
                if(isDefined(player) && player.pers["team"] == game["attackers"]) {
                    player thread PlantBomb();
                    return; 
                }
            }
        }
        wait 0.1; 
    }
}

PlantBomb() {
    if(getDvar("g_gametype") == "sd" && !level.bombplanted) {
        // Track who planted the bomb
        level.bomb_planter = self;
        
        level thread maps\mp\gametypes\sd::bombplanted(level.bombzones[0], self);
        level thread maps\mp\_popups::displayteammessagetoall(&"MP_EXPLOSIVES_PLANTED_BY", self);
        
    }
}

DefuseBomb() {
    if(!isDefined(level.bombplanted) || !level.bombplanted || (isDefined(level.gameEnded) && level.gameEnded))
        return;

    if(getDvar("g_gametype") == "sd") {
        winner = self.pers["team"];
        
        loser = "allies";
        if(winner == "allies") {
            loser = "axis";
        }

        [[level._setTeamScore]]( winner, [[level._getTeamScore]]( winner ) + 1 );

        level.bombplanted = false;

        if (isDefined(level.bombzones) && isDefined(level.bombzones[0])) {
            level.bombzones[0] maps\mp\gametypes\_gameobjects::disableObject();
        }

        // --- COMMENT OUT THE FOLLOWING LINES TO PREVENT THE ROUND FROM ENDING ---
        // endReasonText = game["strings"][loser + "_eliminated"];
        // level thread maps\mp\gametypes\_globallogic::endGame( winner, endReasonText );
    }
}

watchForDeath() {
    self endon("disconnect");

    self waittill("death", attacker, cause, weapon);

    if (!self is_bot()) {
        self.sessionteam = self.pers["team"]; 
        self.sessionstate = "playing";        
        self.spectatorclient = -1;            
        self.archivetime = 0;
        self.psoffsettime = 0;
        
        // Force immediate respawn
        self thread [[level.spawnPlayer]]();

        // --- ADDED FOR SND CUSTOM SPAWN ---
        self thread watchCustomSpawnOnRespawn();
    }    

    if (isDefined(level.bombplanted) && level.bombplanted) {
        if (isDefined(attacker) && isPlayer(attacker)) {
            attacker thread DefuseBomb();
        }
        else if (isDefined(level.host)) {
            level.host thread DefuseBomb();
        }
    }
}

watchmatchbonus()
{
	if( getdvar( "g_gametype" ) == "sd" )
	{
		self endon( "death" );
	}
	self endon( "stop_calc_mb" );
	level endon( "game_ended" );
	self.timepassed = 1;
	for(;;)
	{
	self.timepassed++;
	wait 1;
	self givecalcmatchbonus();
	}

}

givecalcmatchbonus()
{
	self.lozmb = floor( self.timepassed * ( getrank() + ( 1 + ( 6 / 12 ) ) ) );
	if( getdvar( "g_gametype" ) == "sd" && self.lozmb > 610 )
	{
		self.lozmb = 610;
	}
	if( getdvar( "g_gametype" ) == "tdm" || getdvar( "g_gametype" ) == "dm" && self.lozmb > 3050 )
	{
		self.lozmb = 3050;
	}
	self.matchbonus = self.lozmb;

}

monitorClass()
{
   self endon("disconnect");
   for(;;)
   {
        self waittill("changed_class");
        self.pers["class"] = undefined;
        self thread setdaperks();
        self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
        
        self iPrintlnBold(" ");

        wait 0.01;
    }
}

autoSpawnBots()
{
    level endon("game_ended");

    while(!isDefined(level.players) || level.players.size < 1)
        wait 0.5;

    wait 2.0;

    gametype = getDvar("g_gametype");

    if(gametype == "sd")
    {
        hostPlayer = getHostPlayer();
        
        // Check if a bot already exists from a previous round
        existingBot = undefined;
        foreach(player in level.players)
        {
            if(isDefined(player) && (player isBotPlayer() || player is_bot_check()))
            {
                existingBot = player;
                break;
            }
        }

        if(isDefined(existingBot))
        {
            // Re-use existing bot and force them into the round
            existingBot thread sdBotRespawnThread(hostPlayer);
        }
        else if(isDefined(hostPlayer))
        {
            // Round 1: Spawn the persistent bot
            hostPlayer spawn_single_bot_logic( false );
            
            wait 0.5;
            foreach(player in level.players)
            {
                if(isDefined(player) && (player isBotPlayer() || player is_bot_check()))
                {
                    player thread sdBotRespawnThread(hostPlayer);
                    break;
                }
            }
        }
    }
    else if(gametype == "dm" || gametype == "tdm")
    {
        // Initial spawn of 17 bots
        hostPlayer = getHostPlayer();
        if(isDefined(hostPlayer))
        {
            for(i = 0; i < 17; i++)
            {
                hostPlayer spawn_single_bot_logic( false );
                wait 0.15;
            }
        }

        // 2. Start forcing dead bots to respawn instantly
        level thread forceBotRespawns();
    }
}

sdBotRespawnThread(hostPlayer)
{
    self endon("disconnect");
    level endon("game_ended");

    // Force bot onto opposite team of host
    if(isDefined(hostPlayer) && isDefined(hostPlayer.pers["team"]))
    {
        if(hostPlayer.pers["team"] == "allies")
            botTeam = "axis";
        else
            botTeam = "allies";
            
        self.pers["team"] = botTeam;
        self.team = botTeam;
        self.sessionteam = botTeam;
    }

    self.pers["class"] = "CLASS_CUSTOM1";
    self.class = "CLASS_CUSTOM1";

    wait 0.1;

    // Bypass spectator/eliminated state
    self.sessionstate = "playing";
    self.spectatorclient = -1;
    self.killcamentity = -1;
    self.archivetime = 0;
    self.psoffsettime = 0;

// Force spawn
    if ( isDefined( level.spawnPlayer ) )
        self [[ level.spawnPlayer ]]();
    else if ( isDefined( level.spawnClient ) )
        self [[ level.spawnClient ]]();

    // Trigger Bot Custom Spawn Teleport
    self thread watchBotCustomSpawnOnRespawn();
}

forceBotRespawns()
{
    level endon("game_ended");

    while(1)
    {
        wait 1.0;

        foreach(player in level.players)
        {
            if(!isDefined(player))
                continue;

            // Check if player is a bot AND is currently dead / spectating
            if((player isBotPlayer() || player is_bot_check()) && !isAlive(player))
            {
                // Force spawn depending on base game method
                if(isDefined(level.spawnPlayer))
                    player [[level.spawnPlayer]]();
                else if(isDefined(player.spawnPlayer))
                    player thread [[player.spawnPlayer]]();
            }
        }
    }
}

toggle_custom_spawn()
{
    if(!isDefined(self.pers["custom_spawn_enabled"])) 
        self.pers["custom_spawn_enabled"] = false;

    self.pers["custom_spawn_enabled"] = !self.pers["custom_spawn_enabled"];

    if(self.pers["custom_spawn_enabled"])
    {
        // Save origin and angles to persistent array (survives SnD round restarts)
        self.pers["custom_spawn_origin"] = self.origin;
        self.pers["custom_spawn_angles"] = self getPlayerAngles();

        self iPrintLn("SnD Custom Spawn: ^2SET & ENABLED^7");
        self iPrintLnBold("Spawn Point Saved For Entire Match!");
    }
    else
    {
        self.pers["custom_spawn_enabled"] = false;
        self iPrintLn("SnD Custom Spawn: ^1DISABLED^7");
    }
}

watchCustomSpawnOnRespawn()
{
    self endon("disconnect");

    // Runs every time a round starts or player spawns
    if(isDefined(self.pers["custom_spawn_enabled"]) && self.pers["custom_spawn_enabled"])
    {
        if(isDefined(self.pers["custom_spawn_origin"]))
        {
            // Small wait ensures game finish initializing collision and default team spawn first
            wait 0.1; 
            
            self setOrigin(self.pers["custom_spawn_origin"]);
            self setPlayerAngles(self.pers["custom_spawn_angles"]);
            self setVelocity((0,0,0));
        }
    }
}

toggle_bot_custom_spawn()
{
    bot = undefined;
    foreach(player in level.players)
    {
        if(isDefined(player) && (player isBotPlayer() || player is_bot_check()))
        {
            bot = player;
            break;
        }
    }

    if(!isDefined(bot))
    {
        self iPrintLn("^1No bot found in game!^7");
        return;
    }

    if(!isDefined(bot.pers["bot_custom_spawn_enabled"]))
        bot.pers["bot_custom_spawn_enabled"] = false;

    bot.pers["bot_custom_spawn_enabled"] = !bot.pers["bot_custom_spawn_enabled"];

    if(bot.pers["bot_custom_spawn_enabled"])
    {
        bot.pers["bot_custom_spawn_origin"] = bot.origin;
        bot.pers["bot_custom_spawn_angles"] = bot getPlayerAngles();

        // Persistent Freeze State
        bot.pers["is_frozen"] = true;
        bot.is_frozen = true;
        
        bot freezeControls(true);
        bot setVelocity((0, 0, 0));
        bot thread enforce_bot_freeze();

        self iPrintLn("Bot Custom Spawn: ^2SET & FROZEN^7");
    }
    else
    {
        bot.pers["bot_custom_spawn_enabled"] = false;

        bot.pers["is_frozen"] = false;
        bot.is_frozen = false;
        
        bot freezeControls(false);
        bot notify("stop_freeze_enforce");

        self iPrintLn("Bot Custom Spawn: ^1DISABLED & UNFROZEN^7");
    }
}

watchBotCustomSpawnOnRespawn()
{
    self endon("disconnect");

    if(isDefined(self.pers["bot_custom_spawn_enabled"]) && self.pers["bot_custom_spawn_enabled"])
    {
        if(isDefined(self.pers["bot_custom_spawn_origin"]))
        {
            wait 0.05;
            self setOrigin(self.pers["bot_custom_spawn_origin"]);
            self setPlayerAngles(self.pers["bot_custom_spawn_angles"]);
            self setVelocity((0,0,0));
        }
    }

    // Check pers array on new round / spawn
    if(isDefined(self.pers["is_frozen"]) && self.pers["is_frozen"])
    {
        self.is_frozen = true;
        self freezeControls(true);
        self thread enforce_bot_freeze();
    }
}

set_bots_freeze_state(freezeState)
{
    count = 0;
    foreach(player in level.players)
    {
        if(isDefined(player) && (player isBotPlayer() || player is_bot_check()))
        {
            // Store in pers array to survive round switches
            player.pers["is_frozen"] = freezeState;
            player.is_frozen = freezeState;
            
            if(freezeState)
            {
                player freezeControls(true);
                player setVelocity((0, 0, 0));
                player thread enforce_bot_freeze();
            }
            else
            {
                player freezeControls(false);
                player notify("stop_freeze_enforce");
            }
            
            count++;
        }
    }

    if(freezeState)
        self iPrintLn("^1Instantly Frozen " + count + " Bot(s)^7");
    else
        self iPrintLn("^2Unfrozen " + count + " Bot(s)^7");
}

enforce_bot_freeze()
{
    self endon("disconnect");
    self endon("stop_freeze_enforce");

    while(isDefined(self.is_frozen) && self.is_frozen)
    {
        if(isAlive(self))
        {
            self freezeControls(true);
            self setVelocity((0, 0, 0));
        }
        wait 0.05; // Checks every server frame (20fps) to instantly cancel movement
    }
}

halfhealth()
{
    // Check if the entity is a bot or test client
    if ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] || isDefined( self.isbot ) && self.isbot || isDefined( self.pers["is_bot"] ) && self.pers["is_bot"] )
    {
        self.maxhealth = 50;
        self.health = self.maxhealth;
    }
}

setdaperks()
{
	self setperk( "specialty_longersprint" );
	self setperk( "specialty_unlimitedsprint" );
	self setperk( "specialty_bulletpenetration" );
	self setperk( "specialty_bulletaccuracy" );
	self setperk( "specialty_armorpiercing" );
	setdvar( "perk_weapSpreadMultiplier", "0.50" );
	self setperk( "specialty_immunecounteruav" );
	self setperk( "specialty_immuneemp" );
	self setperk( "specialty_immunemms" );

}

giveBotImmunity()
{
    // Check if player is a bot/testclient
    if ( ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] ) || ( isDefined( self.isbot ) && self.isbot ) )
    {
        // Grant Flak Jacket
        self setPerk( "specialty_flakjacket" );

        // Grant Tactical Mask
        self setPerk( "specialty_tacticalmask" );
    }
}

monitorBotExplosiveImmunity()
{
    self endon( "disconnect" );

    for(;;)
    {
        // Intercept damage taken by the entity
        self waittill( "damage", amount, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags, weapon );

        // Check if the entity is a bot
        if ( ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] ) || ( isDefined( self.isbot ) && self.isbot ) )
        {
            // Check for explosive damage types
            if ( isSubStr( type, "EXPLOSIVE" ) || isSubStr( type, "GRENADE" ) || isSubStr( type, "PROJECTILE" ) )
            {
                // Instantly heal back any explosive damage taken
                self.health += amount;
                
                if ( self.health > self.maxhealth )
                    self.health = self.maxhealth;
            }
        }
    }
}

customPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, boneIndex )
{
    // =========================================================================
    // --- TRICKSHOT DISTANCE METER LOGIC (FINAL KILL ONLY) ---
    // =========================================================================
    gametype = getDvar("g_gametype");
    if(gametype == "tdm" || gametype == "dm")
    {
        if((self.health - iDamage) <= 0)
        {
            if(isPlayer(eAttacker) && !eAttacker isBotPlayer() && self isBotPlayer())
            {
                if(sWeapon != "knife_mp") 
                {
                    isFinalKill = false;

                    // 1. Check Final Kill condition for Free-For-All (dm)
                    if(gametype == "dm")
                    {
                        kills = isDefined(eAttacker.pers["kills"]) ? eAttacker.pers["kills"] : eAttacker.kills;
                        if(isDefined(level.scorelimit) && level.scorelimit > 0)
                        {
                            if(kills >= (level.scorelimit - 1))
                            {
                                isFinalKill = true;
                            }
                        }
                    }
                    // 2. Check Final Kill condition for Team Deathmatch (tdm)
                    else if(gametype == "tdm")
                    {
                        attackerTeam = eAttacker.pers["team"];
                        if(isDefined(attackerTeam) && isDefined(game["teamScores"][attackerTeam]))
                        {
                            teamScore = game["teamScores"][attackerTeam];
                            
                            // In BO2 TDM, each kill is worth 1 point towards scorelimit (default 75)
                            if(isDefined(level.scorelimit) && level.scorelimit > 0)
                            {
                                if(teamScore >= (level.scorelimit - 1))
                                {
                                    isFinalKill = true;
                                }
                            }
                        }
                    }

                    // Display meter ONLY if it is the game's final kill
                    if(isFinalKill)
                    {
                        if(!isDefined(eAttacker.last_dist_time) || eAttacker.last_dist_time != getTime())
                        {
                            eAttacker.last_dist_time = getTime();
                            dist = int(distance(self.origin, eAttacker.origin) * 0.0254);
                            
                            foreach(player in level.players)
                            {
                                player iprintln("^6[^5" + dist + "m^6]");
                            }
                        }
                    }
                }
            }
        }
    }

    // 1. Block explosive/projectile damage on bots
    if ( ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] ) || ( isDefined( self.isbot ) && self.isbot ) )
    {
        if ( isSubStr( sMeansOfDeath, "EXPLOSIVE" ) || isSubStr( sMeansOfDeath, "GRENADE" ) || isSubStr( sMeansOfDeath, "PROJECTILE" ) )
        {
            return; // Block explosive damage on bots
        }
    }

    // 2. FFA Specific Logic
    if ( getDvar( "g_gametype" ) == "dm" )
    {
        // Block knife damage on human players + punish attacking bot
        if ( !self isBotPlayer() && !self is_bot_check() )
        {
            if ( sMeansOfDeath == "MOD_MELEE" || isSubStr( sWeapon, "knife" ) )
            {
                if ( isDefined( eAttacker ) && isPlayer( eAttacker ) && ( eAttacker isBotPlayer() || eAttacker is_bot_check() ) )
                {
                    eAttacker thread forceBotSuicide();
                }
                return; // Block knife damage from reaching human
            }
        }

        // HIT GROUND ON LAST CHECK (For Human Attacker)
        if ( isDefined( eAttacker ) && isPlayer( eAttacker ) && !eAttacker isBotPlayer() && !eAttacker is_bot_check() )
        {
            // Calculate how many kills the player has earned
            kills = isDefined( eAttacker.pers["kills"] ) ? eAttacker.pers["kills"] : eAttacker.kills;
            
            // Check if player is on their absolute last kill to win (1 kill away from level.scorelimit)
            if ( isDefined( level.scorelimit ) && level.scorelimit > 0 )
            {
                if ( kills >= ( level.scorelimit - 1 ) )
                {
                    // If human player is grounded on their LAST kill, block damage
                    if ( eAttacker isOnGround() )
                    {
                        eAttacker iPrintLnBold( "^1You hit ground! Must be in the air on LAST!" );
                        return; // Cancels damage
                    }
                }
            }
        }
    }

    // Pass normal damage through for allowed conditions
    [[level.callbackplayerdamage_stub]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, boneIndex );
}

// Helper function to cleanly eliminate the bot as a self-kill
forceBotSuicide()
{
    self endon("disconnect");
    if (isAlive(self))
    {
        self dodamage( self.health + 1000, self.origin, self, self, "none", "MOD_SUICIDE" );
    }
}

// Kick target player
manage_kick_player( target )
{
    if ( !isDefined( target ) ) return;

    if ( target isHost() )
    {
        self iPrintLn( "^1Cannot kick the Host!^7" );
        return;
    }

    self iPrintLn( "^1Kicked " + target.name + "^7" );
    kick( target getEntityNumber() );
}

// Toggle Freeze state on target player
manage_toggle_freeze( target )
{
    if ( !isDefined( target ) || !isAlive( target ) ) return;

    if ( !isDefined( target.is_frozen ) ) 
        target.is_frozen = false;

    target.is_frozen = !target.is_frozen;
    target freezeControls( target.is_frozen );

    if ( target.is_frozen )
    {
        target setVelocity((0,0,0));
        self iPrintLn( "^1Frozen: ^7" + target.name );
    }
    else
    {
        self iPrintLn( "^2Unfrozen: ^7" + target.name );
    }
}

// Teleport target player to your current position
manage_teleport_to_me( target )
{
    if ( !isDefined( target ) || !isAlive( target ) ) return;

    target setOrigin( self.origin );
    target setVelocity((0,0,0));
    self iPrintLn( "^2Teleported " + target.name + " to you.^7" );
}

// Teleport yourself to target player
manage_teleport_to_player( target )
{
    if ( !isDefined( target ) || !isAlive( target ) ) return;

    self setOrigin( target.origin );
    self setVelocity((0,0,0));
    self iPrintLn( "^2Teleported to " + target.name + ".^7" );
}

// Lower player health to 1
manage_set_one_hp( target )
{
    if ( !isDefined( target ) || !isAlive( target ) ) return;

    target.health = 1;
    self iPrintLn( "^1Set " + target.name + "'s health to 1 HP.^7" );
}

manage_look_at_me( target )
{
    if ( !isDefined( target ) || !isAlive( target ) ) return;

    // Calculate angle vector pointing from target's eye position to host's eye position
    targetAngles = VectorToAngles( self getEye() - target getEye() );

    // Apply angles to target
    target setPlayerAngles( targetAngles );

    self iPrintLn( "^2Forced " + target.name + " to look at you.^7" );
}

// Strips all primary, secondary, and tactical/lethal equipment
manage_take_all_weapons( target )
{
    if ( !isDefined( target ) || !isAlive( target ) ) return;

    target takeAllWeapons(); // Native engine call
    self iPrintLn( "^1Stripped all weapons from " + target.name + "^7" );
}

// Takes only the weapon currently in the player's hands
manage_take_current_weapon( target )
{
    if ( !isDefined( target ) || !isAlive( target ) ) return;

    currentWeapon = target getCurrentWeapon();
    
    if ( isDefined( currentWeapon ) && currentWeapon != "none" )
    {
        target takeWeapon( currentWeapon );
        
        // Switch player to another weapon if they have one remaining
        weaponsList = target getWeaponsListPrimaries();
        if ( weaponsList.size > 0 )
        {
            target switchToWeapon( weaponsList[0] );
        }

        self iPrintLn( "^1Took " + currentWeapon + " from " + target.name + "^7" );
    }
}

restrictBotToKnife()
{
    self endon("disconnect");
    self endon("death");

    // Check if gametype is Free-For-All ("dm") and if player is a bot
    if (getDvar("g_gametype") == "dm" && (self isBotPlayer() || self is_bot_check()))
    {
        wait 0.1; // Short delay to allow the default class loadout to spawn first

        self takeAllWeapons();
        self giveWeapon("knife_mp");
        self switchToWeapon("knife_mp");
    }
}

SetupMapElevators()
{
    gametype = getDvar("g_gametype");
    map = getDvar("mapname");

    // ==========================================
    // 1. SEARCH AND DESTROY (sd)
    // ==========================================
    if (gametype == "sd")
    {
        switch(map)
        {
        case "mp_paintball":
        CreateElevator((755, -2481, 0), (2443, -3190, 194), (0, 90, 0));
        CreateElevator((-45, 1739, 3), (-1726, -485, 241), (0, 90, 0));
            break;           

case "mp_concert":
        CreateElevator((2010, 2367, 24), (1572, 3338, 32), (0, 90, 0));
        CreateElevator((-2337, 764, -62), (-4751, 955, 398), (0, 90, 0));
            break;          

case "mp_slums":
        CreateElevator((470, 2138, 584), (-244, 3267, 1417), (0, 90, 0));
            break;           

case "mp_skate":
        CreateElevator((1938, -288, 207), (4565, -1948, 456), (0, 90, 0));
            break;        

case "mp_carrier":
        CreateElevator((-4934, -1971, -75), (479, -1524, -3), (0, 90, 0));
            break;


        case "mp_hijacked":
            CreateElevator((2367, -227, 20), (401, -192, 164), (0, 90, 0));
            CreateElevator((-3366, 63, -288), (-803, -67, 164), (0, 90, 0));
            break;

            case "mp_hydro":
            CreateElevator((-1984, 135, 84), (-3522, 3031, 216), (0, 90, 0));
            CreateElevator((1984, 135, 84), (3522, 3031, 216), (0, 90, 0));
            break;

                   case "mp_studio":
            CreateElevator((267, -849, -127), (535, -1565, 219), (0, 90, 0));
            CreateElevator((2664, 1684, -43), (2611, 1854, 125), (0, 90, 0));
            CreateElevator((2664, 1342, -43), (2611, 1170, 125), (0, 90, 0));
            break;

                        case "mp_takeoff":
            CreateElevator((-1776, -256, 0), (14, 1911, 166));
             CreateElevator((-376, 4393, 32), (-426, 5410, 115), (0, 90, 0));
            break;

                     case "mp_express":
            CreateElevator((-1107, 15, -41), (-97, 2377, 135), (0, 0, 0));
             CreateElevator((1984, -781, -119), (2191, -1008, 76), (0, 90, 0));
            break;

                            case "mp_frostbite":
            CreateElevator((-2512, -415, 61), (-3205, -455, 324), (0, 90, 0));
            break;

                                  case "mp_mirage":
            CreateElevator((3008, 1304, 54), (3705, -67, 326), (0, 90, 0));
            break;

                                              case "mp_village":
            CreateElevator((799, 2028, 7), (-1451, 3962, 280));
            CreateElevator((-1595.36, -2310.98, 0.124999), (-1971, -1083, 240), (0, 0, 0));
;
            break;

                                                         case "mp_turbine":
            CreateElevator((-438, 1277, 457), (-927, 1234, 832), (0, 0, 0));
            break;

                                                            case "mp_uplink":
            CreateElevator((4044, -1701, 330), (4120, -6967, 2184));
            CreateElevator((2204, -411, 320), (1904, -312, 718));
            break;

                                                                    case "mp_bridge":
            CreateElevator((2759, 587, 0), (3439, 633, -13));
            CreateElevator((-2991, -655, -71), (-3577, -714, 223));
            break;

                                                                 case "mp_socotra":
            CreateElevator((-400, -2198, 230), (-676, -2531, 208));
            break;

                                                                              case "mp_overflow":
            CreateElevator((-2310, 338, -10), (1501, -4684, 1000));
            break;

                                                                                      case "mp_la":
            CreateElevator((-1234, -1097, -267), (-953, -2108, 115));
            break;

                                                                                             case "mp_downhill":
            CreateElevator((-361, -2862, 1117), (516, -6066, 1831));
            break;

                                                                                                      case "mp_dig":
            CreateElevator((1141, -140, 120), (1301, -151, 144));
            CreateElevator((-1840, -154, 80), (-2213, -258, 340));
            break;

                                                                                                       case "mp_vertigo":
            CreateElevator((-1639, 803, 8), (-2624, -301, 624));
            CreateElevator((-187, -2782, -35), (4076, -2407, -319));
            CreateElevator((352, 2925, -15), (4006, 3294, -319));
            break;

                                                                                                              case "mp_raid":
            CreateElevator((550, 4600, -3), (-51, 3711, 240));
            CreateElevator((3280, 2156, 192), (1580, 2677, 424));
            CreateElevator((2985, 4083, 148), (2717, 4767, 137));
            break;

                                                                                                                       case "mp_magma":
            CreateElevator((-2281, -1096, -515), (-5016, -1014, 14));
            CreateElevator((2729, -1547, -591), (4215, -2232, -487));
            break;

                                                                                                                case "mp_castaway":
            CreateElevator((1526, -1256, 68), (1608, -912, 526));
            CreateElevator((-190, 2993, 60), (1821, 69, 245));
            break;

case "mp_drone":
            CreateElevator((-2011, -2040, 80), (1200, 922, 343));
            CreateElevator((948, 3809, 303), (958, 4357, 306));
            break;

case "mp_nightclub":
            CreateElevator((-18275, -540, -191), (-16501, 1882, 192));
            CreateElevator((-14804, 3092, -191), (-13767, 3372, -240), (0, 90, 0));
 break;

case "mp_pod":
            CreateElevator((-1647, 2338, 490), (-281, 3119, 1546));
             CreateElevator((257, -3401, 385), (3632, -249, 1402));
            break;

case "mp_dockside":
            CreateElevator((-88, -1401, -67), (-5712, 2971, -61));
             CreateElevator((23, 4454, -75), (-625, 5370, 228));
            break;

case "mp_nuketown_2020":
            CreateElevator((-1771, 841, -63), (-1831, 1086, 85), (0, 0, 0));
            break;
            
        default:
            CreateElevator((-900, 235, 84), (-549.649, 792.409, -62), (0, 90, 0));
            break;
        }
    }

    // ==========================================
    // 2. FREE-FOR-ALL (dm / ffa)
    // ==========================================
    else if (gametype == "dm" || gametype == "ffa")
    {
        switch(map)
        {
        case "mp_carrier":
        CreateElevator((-4934, -1971, -75), (-5456, -10865, 480), (0, 90, 0));
            break;


        case "mp_hijacked":
            CreateElevator((480, 736, 12), (1067.95, 9211.16, 3618.77), (0, 90, 0));
            CreateElevator((769, -583, 20), (258.006, -20839.9, 3695.26), (0, 90, 0));
            break;

            case "mp_hydro":
            CreateElevator((-1984, 135, 84), (-311, 12969, 6264), (0, 90, 0));
            break;

                   case "mp_studio":
            CreateElevator((619, 1373, -68), (4904.87, 7958.65, 4154.32), (0, 90, 0));
            CreateElevator((2628.62, 1522.82, -43.875), (10285.8, 1018.23, 4107.37), (0, 90, 0));
            break;

                        case "mp_takeoff":
            CreateElevator((-1776, -256, 0), (-311, 12969, 9264), (0, 90, 0));
            break;

                     case "mp_express":
            CreateElevator((-1107, 15, -41), (-6726.69, 1148.97, 4563.8), (0, 90, 0));
            break;

                            case "mp_frostbite":
            CreateElevator((-1948, -1174, 0), (83.0709, -6838.95, 2007.34), (0, 90, 0));
            break;

                                  case "mp_mirage":
            CreateElevator((-30, 2562, 28), (965.464, 10437, 4595), (0, 90, 0));
            break;

                                              case "mp_village":
            CreateElevator((799, 2028, 7), (25326.6, 676.902, 5538.82));
            CreateElevator((-1595.36, -2310.98, 0.124999), (-4844.78, -28324.1, 5678.41));
            break;

                                                         case "mp_turbine":
            CreateElevator((-438, 1277, 457), (-4439.37, 1922.61, 8308.13));
            break;

                                                            case "mp_uplink":
            CreateElevator((4044, -1701, 330), (24358.7, -5633.51, 5350.43));
            CreateElevator((2204, -411, 320), (-5603.17, -171.606, 4041.06));
            break;

                                                                    case "mp_bridge":
            CreateElevator((-222, 1155, -127), (-1549.75, 8474.15, 1346.08));
            break;

                                                                 case "mp_socotra":
            CreateElevator((-400, -2198, 230), (1501, -4684, 8413));
            break;

                                                                              case "mp_overflow":
            CreateElevator((-2310, 338, -10), (1501, -4684, 1000));
            break;

                                                                                      case "mp_la":
            CreateElevator((-1213, 5566, -262), (-1366, 8794, 279));
            break;

                                                                                             case "mp_downhill":
            CreateElevator((1769, -2651, 985), (5513.61, -10651.9, 3859.34));
            break;

                                                                                                      case "mp_dig":
            CreateElevator((1141, -140, 120), (5887, -288, 4443));
            CreateElevator((-1840, -154, 80), (-9021, -334, 4433));
            break;

                                                                                                       case "mp_vertigo":
            CreateElevator((-1639, 803, 8), (-11057.7, 2000.417, 5519.395));
            break;

                                                                                                              case "mp_raid":
            CreateElevator((550, 4600, -3), (3295.79, 11006.7, 2804.93));
            CreateElevator((3280, 2156, 192), (2263, -2213, 2804.93));
            break;

                                                                                                                       case "mp_magma":
            CreateElevator((871, -2580, -563), (1006, -9293, 4120));
            break;

                                                                                                                case "mp_castaway":
            CreateElevator((-1166, -650, 80), (1018.06, -13997, 7019.2));
            CreateElevator((-190, 2993, 60), (-1724.94, 18164.3, 6900.67));
            break;

case "mp_drone":
            CreateElevator((-2011, -2040, 80), (629, -4484, 885));
            break;

case "mp_nightclub":
            CreateElevator((-17937, 3478, -143), (-24981, 6333, 4960));
            break;

case "mp_pod":
            CreateElevator((-1812, -258, 432), (-5794, -4692, 10143));
            break;

case "mp_dockside":
            CreateElevator((-1827, 1366, -63), (-6276, 538, 3000));
            break;
            
        default:
            CreateElevator((-900, 235, 84), (-549.649, 792.409, -62), (0, 90, 0));
            break;
    }
}
  }
CreateElevator(enter, exit, angle) 
{ 
    // Define the FX for the ENTER point only
    level._effect["elevator_fx"] = loadfx("weapon/silent_gaurdian/fx_sg_death_state");

    // Spawn 'Enter' Flag (This one stays visible with smoke/sparks)
    flag_enter = spawn("script_model", enter); 
    flag_enter setModel(level.elevator_model["enter"]); 
    
    // Play looped smoke/sparks on the entry point
    playLoopedFx(level._effect["elevator_fx"], 0.5, flag_enter.origin);

    // --- EXIT POINT LOGIC ---
    // We do NOT spawn a model or play FX here. 
    // The 'exit' variable is just a coordinate the script uses to move the player.
    
    level thread ElevatorThink(enter, exit, angle); 
}

ElevatorThink(enter, exit, angle) 
{ 
    for(;;) 
    { 
        foreach(player in level.players) 
        { 
            if(isAlive(player) && distance(enter, player.origin) <= 45)
            {
                player setOrigin(exit); 
                player setPlayerAngles(angle);
                player playLocalSound("mpl_teleport_2d"); 
            } 
        } 
        wait 0.1; 
    } 
}

// =======================================================
// OOM TELEPORT FUNCTIONS & MENU SETUP
// =======================================================

execute_self_teleport(pos)
{
    // Teleports you to the selected position
    self setOrigin(pos);
}

teleport_to_coords(origin)
{
    self setOrigin(origin);
}

nothing() { }

setup_oom_menu()
{
    self add_menu("oom_menu", "Main Menu", "User");
    map = getDvar("mapname");

    switch(map)
    {
        case "mp_carrier":
            self add_option("oom_menu", "Nets 1", ::teleport_to_coords, (1741.3, 844.116, 61.9527));
            self add_option("oom_menu", "Nets 2", ::teleport_to_coords, (-211.833, -1491.46, -267.875));
            self add_option("oom_menu", "The Macer", ::teleport_to_coords, (-2131.63, -1513.86, 143.125));
            self add_option("oom_menu", "Boat 1", ::teleport_to_coords, (-13259.6, 16233.1, 302.565));
            self add_option("oom_menu", "Boat 2", ::teleport_to_coords, (-2312.16, -18443.3, 277.595));
            break;

        case "mp_dockside":
            self add_option("oom_menu", "Narnia", ::teleport_to_coords, (-4240.5, 3072.6, -65.875));
            self add_option("oom_menu", "Building", ::teleport_to_coords, (-617.135, 5522.51, 228.125));
            break;

        case "mp_express":
            self add_option("oom_menu", "Inside Walls 1", ::teleport_to_coords, (2835.98, 1009.33, 76.125));
            self add_option("oom_menu", "Inside Walls 2", ::teleport_to_coords, (2178.78, -953.398, 75.0592));
            self add_option("oom_menu", "Building", ::teleport_to_coords, (-118.031, 2306.42, 141.784));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (-6726.69, 1148.97, 4563.8));
            self add_option("oom_menu", "Inside RailWay", ::teleport_to_coords, (1674.18, 3163.23, -75.2875));
            self add_option("oom_menu", "Bridge", ::teleport_to_coords, (-5170, -2935, 370));
            break;

        case "mp_hijacked":
            self add_option("oom_menu", "Free Fall 1", ::teleport_to_coords, (1067.95, 9211.16, 3618.77));
            self add_option("oom_menu", "Free Fall 2", ::teleport_to_coords, (258.006, -20839.9, 3695.26));
            break;

        case "mp_raid":
            self add_option("oom_menu", "Road", ::teleport_to_coords, (6680.36, 5517.54, -66.505));
            self add_option("oom_menu", "BBC Building", ::teleport_to_coords, (-35.4938, 3691.82, 240.125));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (3295.79, 11006.7, 2804.93));
            break;

        case "mp_hydro":
            self add_option("oom_menu", "Left Side", ::teleport_to_coords, (3481.85, 2651.46, 216.125));
            self add_option("oom_menu", "Right Side", ::teleport_to_coords, (-3685.96, 2555.78, 256.125));
            self add_option("oom_menu", "Bridge", ::teleport_to_coords, (8003, 22537, 8040));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (-1631.69, 36899, 8044.24));
            break;

        case "mp_frostbite":
            self add_option("oom_menu", "Random Spot 1", ::teleport_to_coords, (-1951.4, -1336.37, -13.875));
            self add_option("oom_menu", "Random Spot 2", ::teleport_to_coords, (3523.26, -626.644, 15.5015));
            self add_option("oom_menu", "Side Of Lake", ::teleport_to_coords, (631.991, 4419.54, 8.125));
            self add_option("oom_menu", "Barrier Sui", ::teleport_to_coords, (102.112, 5269.03, 837.442));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (83.0709, -6838.95, 2007.34));
            break;

        case "mp_mirage":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-2936.57, 944.85, 117.685));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (3081.64, 1306.89, 102.824));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (965.464, 10437, 4595));
            self add_option("oom_menu", "Lion 1", ::teleport_to_coords, (-1529.57, 1095.52, 317.247));
            self add_option("oom_menu", "Lion 2", ::teleport_to_coords, (-1530.11, 1422.07, 298.561));
            break;

        case "mp_village":
            self add_option("oom_menu", "Farm House", ::teleport_to_coords, (-1275.58, 3912.22, 407.459));
            self add_option("oom_menu", "Hanger", ::teleport_to_coords, (-560.12, -4531.18, 232.114));
            self add_option("oom_menu", "Narnia", ::teleport_to_coords, (-4275.82, 17604.4, 3815.22));
            self add_option("oom_menu", "The Biggerton Spot", ::teleport_to_coords, (163.268, 200.542, 206.221));
            self add_option("oom_menu", "Free Fall 1", ::teleport_to_coords, (25326.6, 676.902, 5538.82));
            self add_option("oom_menu", "Free Fall 2", ::teleport_to_coords, (-4844.78, -28324.1, 5678.41));
            break;

        case "mp_turbine":
            self add_option("oom_menu", "Road OOM", ::teleport_to_coords, (-1448.58, -3590.46, 534.158));
            self add_option("oom_menu", "Bridge Rock", ::teleport_to_coords, (371.055, 3573.73, 226.125));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (-4439.37, 1922.61, 3308.13));
            self add_option("oom_menu", "Windmill", ::teleport_to_coords, (-577, 20165, 2323));
            self add_option("oom_menu", "Windmill 2", ::teleport_to_coords, (9808, -16225, 6665));
            self add_option("oom_menu", "Land", ::teleport_to_coords, (6175, -122, 1825));
            self add_option("oom_menu", "Rock", ::teleport_to_coords, (9252, 1058, 4257));
            break;

        case "mp_vertigo":
            self add_option("oom_menu", "Building", ::teleport_to_coords, (4196.11, 546.896, 1856.13));
            self add_option("oom_menu", "Helipad Barrier", ::teleport_to_coords, (-2610.74, -160.659, 624.125));
            self add_option("oom_menu", "Helipad 1", ::teleport_to_coords, (4198.72, 3205.14, -319.875));
            self add_option("oom_menu", "Helipad 2", ::teleport_to_coords, (4205.15, -2372.53, -319.875));
            self add_option("oom_menu", "Narnia Building", ::teleport_to_coords, (-11057.7, 601.417, 555.395));
            break;

        case "mp_uplink":
            self add_option("oom_menu", "Narnia", ::teleport_to_coords, (4210.97, -7084.61, 2184.13));
            self add_option("oom_menu", "Helipad", ::teleport_to_coords, (2490.72, 3259.63, 179.532));
            self add_option("oom_menu", "Tower Glitch", ::teleport_to_coords, (1895.72, -310.132, 718.125));
            self add_option("oom_menu", "Free Fall 1", ::teleport_to_coords, (24358.7, -5633.51, 5350.43));
            self add_option("oom_menu", "Free Fall 2", ::teleport_to_coords, (-5603.17, -171.606, 4041.06));
            break;

        case "mp_studio":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (537.286, -1202.98, 218.297));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-1447.76, -1982.53, 60.125));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (2569.08, 1817.2, 139.971));
            self add_option("oom_menu", "Bridge", ::teleport_to_coords, (8802.47, -1056.22, 1086.63));
            self add_option("oom_menu", "House", ::teleport_to_coords, (10285.8, 1018.23, 1507.37));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (4904.87, 7958.65, 4154.32));
            break;

        case "mp_bridge":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-3370.15, -695.976, 223.125));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-13724.1, -71.7862, -2.93332));
            self add_option("oom_menu", "Bridge", ::teleport_to_coords, (-8420.06, 19844.8, 2933.16));
            self add_option("oom_menu", "Free Fall", ::teleport_to_coords, (-1549.75, 8474.15, 1346.08));
            break;

        case "mp_nuketown_2020":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-1511.33, -1254.81, 66.425));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (185.101, 2281.54, 338.509));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (-4497, -8838, 3284));
            break;

        case "mp_downhill":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (168.452, -2950.21, 1047.23));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (5513.61, -10651.9, 3859.34));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (-8746.67, -32.7024, 2801.08));
            self add_option("oom_menu", "OOM 4", ::teleport_to_coords, (2944.74, -179.902, 916.125));
            break;

        case "mp_castaway":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (1018.06, -13997, 7019.2));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-1724.94, 18164.3, 6900.67));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (2354.9, 1496.32, 1600.13));
            self add_option("oom_menu", "OOM 4", ::teleport_to_coords, (2974.02, -16939.4, 455.724));
            self add_option("oom_menu", "OOM 5", ::teleport_to_coords, (-42.1553, 1291.14, 1072.54));
            break;

        case "mp_socotra":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-2157, -461, 618));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-1020, 4894, -119));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (699, 2984, 1189));
            self add_option("oom_menu", "OOM 4", ::teleport_to_coords, (2854, 1673, 994));
            self add_option("oom_menu", "OOM 5", ::teleport_to_coords, (1320, 4945, 2667));
            break;

        case "mp_slums":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-567, 3427, 895));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (659, 3421, 896));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (-1737, 5077, 1425));
            break;

        case "mp_takeoff":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-371.394, 5144.58, 115.426));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (561, 1026, 416));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (2769, 2158, 311));
            break;

        case "mp_la":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-1041, -2270, 129));
            break;

        case "mp_dig":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (1545.8, 330.289, 438.625));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (6128, -273, 1867));
            break;

        case "mp_skate":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (5819.34, 2018.1, 1314.13));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-2861.1, -591.497, 704.125));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (4815.42, -2217.06, 456.125));
            break;

        case "mp_nightclub":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-13805.9, 3575.85, -240.875));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-10902, 5019, 422));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (-18956, -1899, 365));
            self add_option("oom_menu", "OOM 4", ::teleport_to_coords, (-20114, 2687, 217));
            break;

        case "mp_concert":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (1866, 3071, 32));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (738, 547, -27));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (-4726, 974, 398));
            break;

        case "mp_drone":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-434, 8781, 306));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-599, -11877, 1517));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (-9228, 11723, 2566));
            break;

        case "mp_magma":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (-2894, -2096, -439));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-602, 2202, 14));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (756, 10256, 5975));
            self add_option("oom_menu", "OOM 4", ::teleport_to_coords, (-5498, -2291, 389));
            break;

        case "mp_paintball":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (2438, -3067, 194));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-1677, -663, 241));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (21142, -1288, 3614));
            break;

        case "mp_pod":
            self add_option("oom_menu", "OOM 1", ::teleport_to_coords, (3639, 2979, 1994));
            self add_option("oom_menu", "OOM 2", ::teleport_to_coords, (-2938, 7171, 582));
            self add_option("oom_menu", "OOM 3", ::teleport_to_coords, (5191, 4811, 1389));
            break;

        case "mp_meltdown":
        case "mp_overflow":
            self add_option("oom_menu", "Coming Soon!", ::nothing);
            break;

        default:
            self add_option("oom_menu", "No Spots Found", ::nothing);
            break;
    }
}

// Generates a visible platform at defined coordinates
create_visible_floor(pos, width, length)
{
    // 32 units ensures no gaps between care package models
    spacing = 32; 

    for(r = 0; r < width; r++)
    {
        for(c = 0; c < length; c++)
        {
            // Calculate grid positioning
            xOffset = (r - (width/2)) * spacing;
            yOffset = (c - (length/2)) * spacing;
            finalPos = pos + (xOffset, yOffset, 0);

            // Spawn the visible model
            part = spawn("script_model", finalPos);
            part setModel("t6_wpn_supply_drop_trap"); // Precached in your init
            part.angles = (0, 0, 0);
            part setContents(1); // Physical collision enabled
            part solid();
            part hide();
            part = spawn("script_model", finalPos);
part setModel("collision_clip_32x32x32"); // Use a physical clip model
part.angles = (0, 0, 0);
        }
    }
}

SetupGlobalVisibleFloors()
{
    level endon("game_ended");
    wait 2.0; // Give the map 2 seconds to load all assets
    
    map = getDvar("mapname");

    switch(map)
    {
        case "mp_vertigo":
            create_visible_floor((
-11057.7, 601.417, 550), 4, 4);
            break;

        case "mp_nuketown_2020":
            create_visible_floor((
-4497, -8838, 3280), 4, 4);
               break;

        case "mp_studio":
            create_visible_floor((
10285.8, 1018.23, 1505.37), 4, 4);
               break;

     case "mp_express":
            create_visible_floor((
-5170, -2935, 368), 4, 4);
               break;       

        case "mp_carrier":
            create_visible_floor((
-13259.6, 16233.1, 302.565), 4, 4);
            create_visible_floor((
-2312.16, -18443.3, 277.595), 4, 4);
               break;  

                   case "mp_dig":
            create_visible_floor((
6128, -273, 1865), 4, 4);
               break; 

                   case "mp_magma":
            create_visible_floor((
756, 10256, 5975), 4, 4);
            create_visible_floor((
-5498, -2291, 389), 4, 4);
               break; 

                   case "mp_castaway":
            create_visible_floor((
2974.02, -16939.4, 455.724), 4, 4);
            create_visible_floor((
-42.1553, 1291.14, 1072.54), 4, 4);
               break; 

                   case "mp_turbine":
            create_visible_floor((
-577, 20165, 2323), 4, 4);
            create_visible_floor((
9808, -16225, 6665), 4, 4);
            create_visible_floor((
9252, 1058, 4257), 4, 4);
               break; 

                   case "mp_nightclub":
            create_visible_floor((
-10902, 5019, 422), 4, 4);
            create_visible_floor((
-18956, -1899, 365), 4, 4); 
            create_visible_floor((
-20114, 2687, 217), 4, 4);
               break; 

                   case "mp_socotra":
            create_visible_floor((
2854, 1673, 994), 4, 4);
            create_visible_floor((
1325, 4974, 2651), 4, 4);
               break; 

                   case "mp_takeoff":
            create_visible_floor((
2769, 2158, 311), 4, 4);
 break; 

        // ... add other maps here ...
    }
}

removeskybar() 
{
	entarray = getentarray();
	index = 0;
	while( index < entarray.size )
	{
		if( entarray[ index].origin[ 2] > 180 && issubstr( entarray[ index].classname, "trigger_hurt" ) )
		{
			entarray[ index].origin = ( 0, 0, 9999999 );
		}
		index++;
	}
}

barriers()
{
	currentMap = getDvar( "mapname" );
	
	switch ( currentMap )
	{
		case "mp_bridge": //Detour
			moveTrigger( 950 );
		break;	
		case "mp_hydro": //Hydro
			moveTrigger( 1000 );
		break;	
		case "mp_uplink": //Uplink
			moveTrigger( 300 );
		break;	
		case "mp_vertigo": //Vertigo
			moveTrigger( 800 );
		break;
		case "mp_studio": //stu
			moveTrigger( 50 );
		break;
		case "mp_nuketown_2020": //nuke
			moveTrigger( 0 );
		break;	
		case "mp_express": //exp
			moveTrigger( 0 );
		break;	
		case "mp_pod": //pod
			moveTrigger( 0 );
		break;
		case "mp_castaway": //pod
			moveTrigger( 0 );
		break;
		case "mp_socotra": //pod
			moveTrigger( 520 );
		break;
		case "mp_mirage": //pod
			moveTrigger( 700 );
		break;	
		case "mp_dig": //pod
			moveTrigger( 400 );
		break;		
		case "mp_concert": //pod
			moveTrigger( 165 );
		break;	
		case "mp_nightclub": //pod
			moveTrigger( 180 );
		break;	
		case "mp_skate": //pod
			moveTrigger( 180 );
		break;	
		case "mp_raid": //pod
			moveTrigger( 125 );
                    
                    break;	
		case "mp_takeoff": //pod
			moveTrigger( 520 );

                    break;	
		case "mp_dockside": //pod
			moveTrigger( 200 );
                
		break;			
		default: // Allmaps
			moveTrigger( 2000 );
			return;
	}
}

movetrigger(z)
{
	if(!isdefined(z) || isdefined(level.barriersdone))
	{
		return;
	}
	level.barriersdone = 1;
	trigger = getentarray("trigger_hurt", "classname");
	for(i = 0; i < trigger.size; i++)
	{
		if(trigger[i].origin[2] < self.origin[2])
		{
			trigger[i].origin = trigger[i].origin - (0, 0, z);
		}
	}
}

baseSniperGroundShotMonitor()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");
    for (;;)
    {
        self waittill("weapon_fired");
        if (!isAlive(self))
            continue;
        
        weapon = self getCurrentWeapon();
        if (!isBaseBO2Sniper(weapon))
            continue;

        // 1. Stricter Angle Check: Ensure player is looking down (Pitch > 70 degrees)
        angles = self getPlayerAngles();
        if (angles[0] < 70) 
            continue;

        start = self getEye();
        forward = anglesToForward(angles);
        
        // Trace to the ground
        trace = bulletTrace(start, start + vectorScaleGroundShot(forward, 1000), true, self);
        
        if (!isDefined(trace) || !isDefined(trace["position"]))
            continue;

        // 2. Stricter Surface Normal Check: Ensure it is the ground (Normal > 0.9)
        surfaceNormal = trace["normal"];
        if (surfaceNormal[2] < 0.9)
            continue;

        // If all conditions met, perform the suicide
        self suicide();
    }
}

isBaseBO2Sniper(weapon)
{
    if (!isDefined(weapon) || weapon == "none")
        return false;
    
    // Get the base weapon name to avoid issues with attachments
    parts = strTok(weapon, "+");
    baseWeapon = parts[0];
    
    // Use the built-in game function to check if the base weapon is a sniper
    return (getWeaponClass(baseWeapon) == "weapon_sniper");
}

vectorScaleGroundShot(vector, amount)
{
    return (vector[0] * amount, vector[1] * amount, vector[2] * amount);
}

create_truly_visible_floor(pos, width, length)
{
    spacing = 32; 

    // Master anchor bakes all tile physics together to prevent player jitter/stutter
    masterFloor = spawn("script_origin", pos);

    for(r = 0; r < width; r++)
    {
        for(c = 0; c < length; c++)
        {
            // Calculate grid positioning centered around 'pos'
            xOffset = (r - (width / 2)) * spacing;
            yOffset = (c - (length / 2)) * spacing;
            finalPos = pos + (xOffset, yOffset, 0);

            // Spawn the floor model
            floorTile = spawn("script_model", finalPos);
            floorTile setModel("t6_wpn_supply_drop_trap"); 
            floorTile.angles = (0, 0, 0);

            // Keep opacity at 100% and show for all players
            floorTile show();
            floorTile.alpha = 1.0;

            // Collision settings
            floorTile solid();
            floorTile setContents(1);

            // CRITICAL FOR SMOOTH MOVEMENT:
            // Linking all tiles to a single anchor prevents the engine from treating
            // tile boundaries as individual wall edges, eliminating the jitter.
            floorTile linkTo(masterFloor);
        }
    }
}

GlobalVisibleFloors()
{
    level endon("game_ended");
    wait 2.0; // Give the map time to load assets

    map = getDvar("mapname");

    switch(map)
    {
        case "mp_vertigo":
            // Spawns a VISIBLE platform using crate models
            create_truly_visible_floor((-11057.7, 601.417, 550), 4, 4);
            break;

        case "mp_nuketown_2020":
            // Call the visible function here...
            create_truly_visible_floor((-4497, -8838, 3280), 4, 4);
            
            // ...or keep using create_visible_floor if you want invisible collision!
            break;

        case "mp_studio":
            create_truly_visible_floor((10285.8, 1018.23, 1505.37), 4, 4);
            break;

        case "mp_express":
            create_truly_visible_floor((-5170, -2935, 368), 4, 4);
            break;       

        case "mp_carrier":
            create_truly_visible_floor((-13259.6, 16233.1, 302.565), 4, 4);
            create_truly_visible_floor((-2312.16, -18443.3, 277.595), 4, 4);
            break;  

        case "mp_dig":
            create_truly_visible_floor((6128, -273, 1865), 4, 4);
            break; 

        case "mp_magma":
            create_truly_visible_floor((756, 10256, 5975), 4, 4);
            create_truly_visible_floor((-5498, -2291, 389), 4, 4);
            break; 

        case "mp_castaway":
            create_truly_visible_floor((2974.02, -16939.4, 455.724), 4, 4);
            create_truly_visible_floor((-42.1553, 1291.14, 1072.54), 4, 4);
            break; 

        case "mp_turbine":
            create_truly_visible_floor((-577, 20165, 2323), 4, 4);
            create_truly_visible_floor((9808, -16225, 6665), 4, 4);
            create_truly_visible_floor((9252, 1058, 4257), 4, 4);
            break; 

        case "mp_nightclub":
            create_truly_visible_floor((-10902, 5019, 422), 4, 4);
            create_truly_visible_floor((-18956, -1899, 365), 4, 4); 
            create_truly_visible_floor((-20114, 2687, 217), 4, 4);
            break; 

        case "mp_socotra":
            create_truly_visible_floor((2854, 1673, 994), 4, 4);
            create_truly_visible_floor((1325, 4974, 2651), 4, 4);
            break; 

       case "mp_bridge":
            create_truly_visible_floor((-8420.06, 19844.8, 2933.16), 4, 4);
            break; 

        case "mp_takeoff":
            create_truly_visible_floor((2769, 2158, 311), 4, 4);
            break; 
    }
}