#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\_rank;
#include maps\mp\gametypes\_class;
#include maps\mp\bots\_bot;

init()
{
	level thread onplayerconnect();
        level thread pre_game_unfreeze();
        level thread removeskybar();
        setDvar("sv_enablebounces", "1");
        setDvar("sv_clientSideBullets", 1);
        setDvar("bulletrange", 50000);
        makedvarserverinfo("bulletrange", 50000); 
    	setdvar( "bullet_ricochetBaseChance", 0.95 );
	setdvar( "bullet_penetrationMinFxDist", 1024 );
        setdvar( "bg_surfacePenetration", 9000000 );
	setdvar( "perk_armorPiercing", 900000 );
	setdvar( "sv_clientSideBullets", 1 );
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
        level thread SetupMapElevators();
        level.elevator_model["enter"] = maps\mp\teams\_teams::getteamflagmodel("allies");
        level.elevator_model["exit"] = maps\mp\teams\_teams::getteamflagmodel("axis");
	level thread force_bot_round_respawn(); // Handle bot forced respawns each round
}

force_bot_round_respawn()
{
	level endon("game_ended");

	for(;;)
	{
		// Wait specifically for the new round prematch/play phase to begin
		level waittill_any("prematch_over", "start_play_of_the_match");
		
		wait 0.2; // Let globallogic initialize round state first

		foreach(player in level.players)
		{
			if(isDefined(player) && is_actual_bot(player))
			{
				player thread force_next_round_bot_spawn();
			}
		}
	}
}

force_next_round_bot_spawn()
{
	self endon("disconnect");

	// Reset S&D / Round elimination state so the engine allows the new round spawn
	self.pers["lives"] = 1;
	self.lives = 1;
	self.pers["spawns"] = 0;
	self.alreadyfirstspawn = undefined;
	self.hasspawned = false;

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || self.pers["team"] == "none")
	{
		self.pers["team"] = "axis";
		self.team = "axis";
		self.sessionteam = "axis";
	}

	if(!isDefined(self.pers["class"]))
	{
		self.pers["class"] = "CLASS_CUSTOM1";
		self.class = "CLASS_CUSTOM1";
	}

	// Request official gametype spawn for the new round
	if(isDefined(level.onspawnplayer))
	{
		self [[level.onspawnplayer]](0);
	}
	else if(isDefined(level.spawnplayer))
	{
		self [[level.spawnplayer]]();
	}
	else
	{
		self maps\mp\gametypes\_globallogic_spawn::spawnplayer();
	}

	// Once spawned into the new round, handle moving them to custom position (if enabled)
	self thread watchBotCustomSpawnOnRespawn();
}

force_guaranteed_bot_spawn()
{
	self endon("disconnect");

	// Don't re-spawn if the bot is already alive and playing
	if(isAlive(self) && isDefined(self.sessionstate) && self.sessionstate == "playing")
		return;

	// 1. Force valid team assignment (Opposite of host if possible, default to axis)
	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || self.pers["team"] == "none")
	{
		self.pers["team"] = "axis";
		self.team = "axis";
		self.sessionteam = "axis";
	}

	// 2. Clear Search & Destroy round elimination limits
	self.pers["lives"] = 1;
	self.lives = 1;
	self.pers["spawns"] = 0;
	self.alreadyfirstspawn = undefined;
	self.hasspawned = false;

	// 3. Ensure a valid class is assigned
	if(!isDefined(self.pers["class"]))
	{
		self.pers["class"] = "CLASS_CUSTOM1";
		self.class = "CLASS_CUSTOM1";
	}

	// 4. Force state out of spectator/dead
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	wait 0.05;

	// 5. Invoke the official engine spawn routine
	if(isDefined(level.onspawnplayer))
	{
		self [[level.onspawnplayer]](0);
	}
	else if(isDefined(level.spawnplayer))
	{
		self [[level.spawnplayer]]();
	}
	else
	{
		self maps\mp\gametypes\_globallogic_spawn::spawnplayer();
	}

	self notify("spawned_player");
}

force_bot_spawn_next_round()
{
	self endon("disconnect");

	// Don't re-spawn a bot that is already alive and spawned; this prevents invisible models
	if(isAlive(self) && self.sessionstate == "playing")
		return;

	// Reset S&D round elimination flags so globallogic allows the spawn
	self.pers["lives"] = 1;
	self.lives = 1;
	self.pers["spawns"] = 0;
	self.alreadyfirstspawn = undefined;
	self.hasspawned = false;

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator")
	{
		self.pers["team"] = "axis";
		self.team = "axis";
	}

	if(!isDefined(self.pers["class"]))
	{
		self.pers["class"] = "CLASS_CUSTOM1";
		self.class = "CLASS_CUSTOM1";
	}

	// Request official gametype spawn
	if(isDefined(level.onspawnplayer))
	{
		self [[level.onspawnplayer]](0);
	}
	else
	{
		self maps\mp\gametypes\_globallogic_spawn::spawnplayer();
	}
}

force_sd_bot_spawn()
{
	self endon("disconnect");
	
	if(isAlive(self))
		return;

	self.pers["lives"] = 1;
	self.lives = 1;
	self.alreadyfirstspawn = true;
	self.hasspawned = true;

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator")
	{
		self.pers["team"] = "axis";
		self.team = "axis";
	}

	if(!isDefined(self.pers["class"]))
	{
		self.pers["class"] = "CLASS_CUSTOM1";
		self.class = "CLASS_CUSTOM1";
	}

	// Override session state
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	if(isDefined(level.spawnplayer))
	{
		self [[level.spawnplayer]]();
	}
	else
	{
		self maps\mp\gametypes\_globallogic_spawn::spawnplayer();
	}

	// Trigger spawn event manually to register in script loops
	self notify("spawned_player");
}

safe_bot_respawn()
{
	self endon("disconnect");

	self.pers["lives"] = 1;
	self.lives = 1;
	self.hasspawned = true;
	self.sessionstate = "playing";
	self.spectatorclient = -1;
	
	if(!isDefined(self.pers["class"]))
	{
		self.pers["class"] = "CLASS_CUSTOM1";
		self.class = "CLASS_CUSTOM1";
	}

	if(isDefined(level.onspawnplayer))
	{
		self [[level.onspawnplayer]](0);
	}
	else
	{
		self maps\mp\gametypes\_globallogic_spawn::spawnplayer();
	}
}

respawn_bot_now()
{
	self endon("disconnect");

	// Prevent forcing a spawn on an already-rendered model
	if(isAlive(self) && self.sessionstate == "playing")
		return;

	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;

	if(isDefined(level.spawnPlayer))
	{
		self [[level.spawnPlayer]]();
	}
	else if(isDefined(level.spawnclient))
	{
		self [[level.spawnclient]]();
	}
}

onplayerconnect()
{
	for(;;)
	{
		level waittill("connected", player);
                player thread enable_wallbang();
                self thread watchCustomSpawnOnRespawn();

		if(is_actual_bot(player))
		{
			player thread botzaintwinnin();
		}

		if(is_human_player(player))
		{
			player.pers["isBot"] = undefined;
		}

		player thread onplayerspawned();
	}
}

onplayerspawned()
{
	self endon("disconnect");
	for(;;)
	{
		self waittill("spawned_player");

               self thread button_monitor(); 
               self thread on_player_spawn_cp_stall();
               self thread monitorClass();
               self thread watchCustomSpawnOnRespawn();
               self thread watchForDeath();   
               self thread monitorPositionButtons();

          if(isDefined(self.pers["lb_semtex"]) && self.pers["lb_semtex"])
        {
            self thread lbsemtex();
            self semtex();
        } 

          // Re-thread MW3 Nade persistence if toggled ON
        if(isDefined(self.pers["mw3_nade"]) && self.pers["mw3_nade"])
        {
            self thread watch_mw3_nade_persists();
            self givemw3grenade();
        }        

           if(getDvar("g_gametype") == "sd") {
        level thread autoPlantMonitor();
    } 

		if(is_human_player(self))
		{
			self.pers["isBot"] = undefined;
			if(!isdefined(self.humanpersoninit))
			{
				self.humanpersoninit = 1;
				self thread humanperson();
			}

		}
if(is_actual_bot(self))
		{
			self thread botzaintwinnin();
			self thread watchBotCustomSpawnOnRespawn();
		}
	}
}

botzaintwinnin()
{
	self clearperks();
	self thread halfhealth();
}

humanperson()
{
	self endon("disconnect");
	self endon("death");

	self thread stuffs();
	self thread buildmenu();
	self thread giveRadar();
	self thread menuinput();
	self thread watermark();
}

watermark()
{
    watermark = self createFontString( "hudsmall", 1 );
    watermark setText( "Gigachad" );
    watermark.x = -395;
    watermark.y = -32;
    
    // Run the RGB cycle asynchronously so it doesn't freeze the script execution
    watermark thread watermark_rgb();
    
    return watermark;
}

watermark_rgb()
{
    self endon( "disconnect" );
    self endon( "destroy" );

    for( ;; )
    {
        // Red to Yellow
        for( r = 1; r > 0; r -= 0.05 ) {
            self.color = ( 1, 1 - r, 0 );
            wait 0.05;
        }
        // Yellow to Green
        for( g = 1; g > 0; g -= 0.05 ) {
            self.color = ( g, 1, 0 );
            wait 0.05;
        }
        // Green to Cyan
        for( b = 0; b < 1; b += 0.05 ) {
            self.color = ( 0, 1, b );
            wait 0.05;
        }
        // Cyan to Blue
        for( g = 1; g > 0; g -= 0.05 ) {
            self.color = ( 0, g, 1 );
            wait 0.05;
        }
        // Blue to Magenta
        for( r = 0; r < 1; r += 0.05 ) {
            self.color = ( r, 0, 1 );
            wait 0.05;
        }
        // Magenta to Red
        for( b = 1; b > 0; b -= 0.05 ) {
            self.color = ( 1, 0, b );
            wait 0.05;
        }
    }
}

menuinput()
{
	self endon("disconnect");
	level endon("game_ended");

	self.menuopen = 0;
	self.currentmenu = "Closed";
	self.currentopt = 0;

	for(;;)
	{
		if(self adsbuttonpressed() && self actionslottwobuttonpressed())
		{
			if(!isDefined(self.menuopen) || self.menuopen == 0)
			{
				self open_menu();
			}
			wait(0.2);
		}

		if(isDefined(self.menuopen) && self.menuopen == 1)
		{
			// Scroll down
			if(self actionslottwobuttonpressed())
			{
				self.currentopt++;
				if(self.currentopt >= self.ex[self.currentmenu].size)
					self.currentopt = 0;
				self update_menu();
				wait(0.15);
			}
			// Scroll up
			if(self actionslotOnebuttonpressed())
			{
				self.currentopt--;
				if(self.currentopt < 0)
					self.currentopt = self.ex[self.currentmenu].size - 1;
				self update_menu();
				wait(0.15);
			}
			// Select
			if(self usebuttonpressed())
			{
				func = self.exfunc[self.currentmenu][self.currentopt];
				if(isdefined(func))
				{
					if(isdefined(self.exargues[self.currentmenu][self.currentopt]))
						self thread [[func]](self.exargues[self.currentmenu][self.currentopt]);
					else
						self thread [[func]]();
				}
				wait(0.2);
			}
			// Back / Close
			if(self meleebuttonpressed())
			{
				if(self.currentmenu != "Main Menu")
				{
					// Return to Main Menu if inside a submenu
					self.currentmenu = "Main Menu";
					self.currentopt = 0;
					self update_menu();
				}
				else
				{
					// Close menu if already on Main Menu
					self close_menu();
				}
				wait(0.2);
			}
		}
		wait(0.05);
	}
}

stuffs()
{
	self endon("disconnect");
	self endon("death");
	self endon("stopStuffs");
	for(;;)
	{
		wait(0.05);
		self setperk("specialty_stunprotection");
		self setperk("specialty_disarmexplosive");
		self setperk("specialty_grenadepulldeath");
		self setperk("specialty_immuneemp");
		self setperk("specialty_flashprotection");
		self setperk("specialty_delayexplosive");
		self setperk("specialty_proximityprotection");
		self setperk("specialty_fastmantle");
		self setperk("specialty_fastladderclimb");
		self setperk("specialty_sprintrecovery");
		self setperk("specialty_fastmeleerecovery");
		self setperk("specialty_movefaster");
		self setperk("specialty_fallheight");
		self setperk("specialty_immunecounteruav");
		self setperk("specialty_gpsjammer");
		self setperk("specialty_marksman");
		self setperk("specialty_unlimitedsprint");
		self setperk("specialty_immunemms");
		self setperk("specialty_immunenvthermal");
		self setperk("specialty_immunerangefinder");
		self setperk("specialty_flakjacket");
		self setperk("specialty_noname");
		self setperk("specialty_nottargetedbyairsupport");
		self setperk("specialty_nokillstreakreticle");
		self setperk("specialty_nottargettedbysentry");
		self setperk("specialty_pin_back");
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

buildmenu()
{
	self endon("disconnect");
	self.ex = [];
	self.exfunc = [];
	self.exargues = [];

	// --- MAIN MENU ---
	self addoption("Main Menu", 0, "Host Mods", ::load_submenu, "Host");
	self addoption("Main Menu", 1, "Equipment Options", ::load_submenu, "Equipment/Weapon");
	self addoption("Main Menu", 2, "Extra Mods", ::load_submenu, "Extra");
	self addoption("Main Menu", 3, "Afterhits", ::load_submenu, "Afterhits");
	self addoption("Main Menu", 4, "Afterhits 2", ::load_submenu, "Afterhits 2");
	self addoption("Main Menu", 5, "Afterhits 3", ::load_submenu, "Afterhits 3");
	self addoption("Main Menu", 6, "OOM Teleports", ::load_submenu, "OOM Menu");

	// Load Dynamic Map Teleports
	self setup_oom_menu(); // <-- Calls OOM Setup

	// --- SUBMENU: Host Mods ---
	self addoption("Host", 0, "Add 2 Minutes Time", ::addtime);
	self addoption("Host", 1, "Reset Rounds", ::resetdarounds);
	self addoption("Host", 2, "Toggle Best Maps", ::togglebestmaps);
	self addoption("Host", 3, "Move & Freeze Bot", ::setup_single_bot);
	self addoption("Host", 4, "UAV", ::toggle_uav);
	self addoption("Host", 5, "Spawn Bot", ::spawn_bots_action, 1);
	self addoption("Host", 6, "Bot Spawns Here", ::toggle_bot_custom_spawn);
	self addoption("Host", 7, "You Spawn Here", ::toggle_custom_spawn);
	
	// --- SUBMENU: Equipment Options ---
	self addoption("Equipment/Weapon", 0, "LB Semtex", ::equipselector);
	self addoption("Equipment/Weapon", 1, "Claymore Mala", ::giveclaymoreglitch);
	self addoption("Equipment/Weapon", 2, "Instshoot", ::instashoot);
	self addoption("Equipment/Weapon", 3, "Auto Canswap", ::autocanswap);
	self addoption("Equipment/Weapon", 4, "Class Change Bind", ::toggle_instant_next_class);
	self addoption("Equipment/Weapon", 5, "Blackhat Mala", ::giveblackhatglitch);
	self addoption("Equipment/Weapon", 6, "Unlimited Equipment", ::toggle_unlimited_equipment);
	self addoption("Equipment/Weapon", 7, "MW3 Nade", ::toggle_mw3_grenade);
       
	// --- SUBMENU: Extra Mods ---
	self addoption("Extra", 0, "Mid-Air Prone", ::toggleprone);
	self addoption("Extra", 1, "Gravity", ::gravity);
	self addoption("Extra", 2, "Jump Higher", ::toggle_high_jump);
	self addoption("Extra", 3, "Knife Lunge", ::knifelunge);
	self addoption("Extra", 4, "CarePackage Stall", ::toggle_cp_stall);
	self addoption("Extra", 5, "Alt Swap", ::altswap);

	// --- SUBMENU: Afterhits ---
	self addoption("Afterhits", 0, "Auto Prone", ::autoprone);
	self addoption("Afterhits", 1, "MW2 End Game", ::mw2endgame);
	self addoption("Afterhits", 2, "FHJ-18 AA", ::afterhit, "fhj18_mp");
	self addoption("Afterhits", 3, "R870 MCS Afterhit", ::afterhit, "870mcs_mp");
	self addoption("Afterhits", 4, "M1216 Afterhit", ::afterhit, "srm1216_mp");
	self addoption("Afterhits", 5, "Tac-45 Afterhit", ::afterhit, "fnp45_mp");
	self addoption("Afterhits", 6, "B23R Afterhit", ::afterhit, "beretta93r_mp");
	self addoption("Afterhits", 7, "180 Afterhit", ::oneafter);

	// --- SUBMENU: Afterhits 2 ---
	self addoption("Afterhits 2", 0, "Shield Afterhit", ::afterhit, "riotshield_mp");
	self addoption("Afterhits 2", 1, "Executioner Afterhit", ::afterhit, "judge_dw_mp");
	self addoption("Afterhits 2", 2, "Vector K10 Afterhit", ::afterhit, "vector_mp");
	self addoption("Afterhits 2", 3, "Ballistic Knife Afterhit", ::afterhit, "knife_ballistic_mp");
	self addoption("Afterhits 2", 4, "iPad Afterhit", ::afterhit, "killstreak_remote_turret_mp");
	self addoption("Afterhits 2", 5, "Bomb Afterhit", ::afterhit, "briefcase_bomb_mp");
	self addoption("Afterhits 2", 6, "VTOL Afterhit", ::togglevtolafter);
	self addoption("Afterhits 2", 7, "AGR Afterhit", ::toggleagrafter);
        
	self addoption("Afterhits 3", 0, "Cluster Afterhit", ::toggleclusterafter);
	self addoption("Afterhits 3", 1, "Blackhat", ::afterhit, "pda_hack_mp");
	self addoption("Afterhits 3", 2, "Claymore", ::afterhit, "claymore_mp");
	self addoption("Afterhits 3", 3, "RCXD", ::afterhit, "rcbomb_mp");
}

load_submenu(menu_name)
{
	self.currentmenu = menu_name;
	self.currentopt = 0;
	self update_menu();
}

addoption(menu, option, text, func, arg)
{
	self.ex[menu][option] = text;
	self.exfunc[menu][option] = func;
	if(isdefined(arg))
		self.exargues[menu][option] = arg;
}

open_menu()
{
	self endon("disconnect");	
	self close_menu();

	self.menuopen = 1;
	self.currentmenu = "Main Menu";
	self.currentopt = 0;

	self.title = self createfontstring("console", 1.35);
	self.title setpoint("CENTER", "CENTER", 0, -60);
	self.title settext("Gigachad Menu");
	self.title.glowalpha = 0.8;

	self.background = self drawrectangle("CENTER", "CENTER", 0, 6, 160, 154, (0, 0, 0), 0.6, -5);

	// Start Menu RGB thread for UI updates
	self.menu_rgb_color = (0, 0.75, 1);
	self thread menu_rgb_think();
	self.title thread title_rgb_think(self);

	// Scrollbar using RGB color state
	self.scrollbar = self drawrectangle("CENTER", "CENTER", 0, -35, 160, 16, self.menu_rgb_color, 0.65, -4);

	self.menutext = self createfontstring("console", 1.2);
	self.menutext setpoint("LEFT", "CENTER", -75, -35);

	self.title6 = self createfontstring("console", 1.0);
	self.title6 setpoint("LEFT", "CENTER", -420, 230);
	self.title6 settext("Scroll [{+actionslot 1}] / [{+actionslot 2}] | [{+usereload}] Select / [{+melee}] Close");
	self.title6.hidewheninkillcam = 1;

	self update_menu();
}

menu_rgb_think()
{
	self endon("disconnect");
	self endon("menu_closed");

	for(;;)
	{
		for(r = 1; r > 0; r -= 0.05) {
			self.menu_rgb_color = (1, 1 - r, 0);
			if(isDefined(self.scrollbar)) self.scrollbar.color = self.menu_rgb_color;
			wait 0.05;
		}
		for(g = 1; g > 0; g -= 0.05) {
			self.menu_rgb_color = (g, 1, 0);
			if(isDefined(self.scrollbar)) self.scrollbar.color = self.menu_rgb_color;
			wait 0.05;
		}
		for(b = 0; b < 1; b += 0.05) {
			self.menu_rgb_color = (0, 1, b);
			if(isDefined(self.scrollbar)) self.scrollbar.color = self.menu_rgb_color;
			wait 0.05;
		}
		for(g = 1; g > 0; g -= 0.05) {
			self.menu_rgb_color = (0, g, 1);
			if(isDefined(self.scrollbar)) self.scrollbar.color = self.menu_rgb_color;
			wait 0.05;
		}
		for(r = 0; r < 1; r += 0.05) {
			self.menu_rgb_color = (r, 0, 1);
			if(isDefined(self.scrollbar)) self.scrollbar.color = self.menu_rgb_color;
			wait 0.05;
		}
		for(b = 1; b > 0; b -= 0.05) {
			self.menu_rgb_color = (1, 0, b);
			if(isDefined(self.scrollbar)) self.scrollbar.color = self.menu_rgb_color;
			wait 0.05;
		}
	}
}

title_rgb_think(player)
{
	player endon("disconnect");
	player endon("menu_closed");
	self endon("destroy");

	for(;;)
	{
		if(isDefined(player.menu_rgb_color))
		{
			self.color = player.menu_rgb_color;
			self.glowcolor = player.menu_rgb_color;
		}
		wait 0.05;
	}
}

update_menu()
{
	self endon("disconnect");

	if(!isDefined(self.menuopen) || self.menuopen == 0)
		return;

	// Update Title Text dynamically based on current menu
	if(isDefined(self.title))
		self.title settext(self.currentmenu);

	string = "";
	for(i = 0; i < self.ex[self.currentmenu].size; i++)
	{
		if(i == self.currentopt)
			string = string + "^2> " + self.ex[self.currentmenu][i] + "\n";
		else
			string = string + "  " + self.ex[self.currentmenu][i] + "\n";
	}
	self.menutext settext(string);

	scrollpos = -35 + (self.currentopt * 15);
	self.scrollbar setpoint("CENTER", "CENTER", 0, scrollpos);
}

close_menu()
{
	self.menuopen = 0;
	self.currentmenu = "Closed";
	self.currentopt = 0;
	self notify("menu_closed");

	if(isdefined(self.background)) self.background destroy();
	if(isdefined(self.scrollbar)) self.scrollbar destroy();
	if(isdefined(self.menutext)) self.menutext destroy();
	if(isdefined(self.title)) self.title destroy();
	if(isdefined(self.title6)) self.title6 destroy();
}

drawrectangle(align, relative, x, y, width, height, color, alpha, sort)
{
	hud = newclienthudelem(self);
	hud.elemtype = "icon";
	hud.color = color;
	hud.alpha = alpha;
	hud.sort = sort;
	hud.children = [];
	hud setparent(level.uiparent);
	hud setshader("white", width, height);
	hud setpoint(align, relative, x, y);
	return hud;
}

giveRadar()
{
	self setclientuivisibilityflag("g_compassShowEnemies", 1);
}

addtime()
{
	self iprintlnbold("You added ^52^7 Minutes.");
	time = getgametypesetting("timelimit");
	time = time + 2;
	setgametypesetting("timelimit", time);
	wait(0.03);
}

resetdarounds()
{
	level.resetscores = 1;
	game["roundsWon"]["axis"] = 0;
	game["roundsWon"]["allies"] = 0;
	game["roundsPlayed"] = 0;
	game["teamScores"]["allies"] = 0;
	game["teamScores"]["axis"] = 0;
	maps\mp\gametypes\_globallogic_score::_setteamscore("axis");
	maps\mp\gametypes\_globallogic_score::_setteamscore("allies");
	self iprintlnbold("^5Rounds Reset ^7| ^5Works after the round**");
}

togglebestmaps()
{
	if(!isdefined(self.bestmaps))
	{
		self.bestmaps = 1;
		self iprintlnbold("Map Rotation: ^2Enabled");
		self thread dobestmaps();
	}
	else
	{
		self.bestmaps = undefined;
		self iprintlnbold("Map Rotation: ^1Disabled");
		self notify("stopbestmaps");
	}
}

dobestmaps()
{
	self endon("stopbestmaps");
	self.maps = strtok("mp_carrier,mp_bridge,mp_vertigo,mp_studio,mp_Hydro,mp_nuketown_2020,mp_uplink,mp_hijacked,mp_turbine,mp_socotra,mp_express,mp_raid,mp_village,mp_takeoff,mp_drone,mp_pod,mp_downhill,mp_dockside,mp_nightclub,mp_frostbite", ",");
	self.randmap = randomint(self.maps.size);
	level waittill("final_killcam_done");
	wait(7);
	cmdexec("devmap " + self.maps[self.randmap]);
}

instaend()
{
	exitlevel(0);
}

is_actual_bot(player)
{
	if(!IsDefined(player))
	{
		return false;
	}
	return player is_bot();
}

is_human_player(player)
{
	return !(is_actual_bot(player));
}

monitorClass()
{
   self endon("disconnect");
   for(;;)
   {
        self waittill("changed_class");
        self.pers["class"] = undefined;
        self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
        
        self iPrintlnBold(" ");

        wait 0.01;
    }
}

togglesemtex()
{
    if(!isDefined(self.pers["lb_semtex"])) self.pers["lb_semtex"] = false;
    self.pers["lb_semtex"] = !self.pers["lb_semtex"];

    if(self.pers["lb_semtex"])
    {
        self iprintln("LB Semtex ^4ON");
        self thread lbsemtex();
        self semtex();
    }
    else
    {
        self iprintln("LB Semtex ^0OFF");
        self notify("stopsemtex");
    }
}

lbsemtex()
{
    self endon("disconnect");
    self endon("stopsemtex");

    for(;;)
    {
        // Triggers whenever you change class OR respawn
        self waittill_any("changed_class", "spawned_player");

        if(isDefined(self.pers["lb_semtex"]) && self.pers["lb_semtex"])
        {
            wait 0.1; // Delay lets giveloadout() finish replacing equipment first
            self semtex();
        }
    }
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

instashoot()
{
	if( IsDefined( self.autocanswap ) && self.autocanswap == 1 )
	{

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

    for (;;)
    {
        self waittill( "weapon_change", weapon );
        self setspawnweapon( weapon );
        self shootfastbro();
        wait 0.01;
    }
}

shootfastbro()
{
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "end_instas" );
    self endon( "reload_rechamber" );
    self endon( "sprint" );
    weapon = self getcurrentweapon();

    for (;;)
    {
        if ( !self isreloading() && !self isfiring() && self attackbuttonpressed() )
        {
            self disableweapons();
            wait 0.000001;
            self enableweapons();
            self notify( "end_instas" );
        }

        wait 0.01;
    }
}

giveclaymoreglitch()
{
    self iprintlnbold ("Claymore Mala: ^2Given");
    self giveweapon( "claymore_mp" );
    self switchtoweapon( "claymore_mp" );
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


toggle_instant_next_class()
{
    if(!isDefined(self.auto_next_class)) self.auto_next_class = false;
    self.auto_next_class = !self.auto_next_class;

    if(self.auto_next_class)
    {
        self iPrintLn("Instant Next Class: ^4ON");
        self iPrintLnBold("Press [{+actionslot 2}] ^7to Swap");
        self thread monitor_instant_next_class(); // <-- ADD THIS THREAD
    }
    else
    {
        self iprintln("Instant Next Class: ^0OFF");
        self notify("stop_next_class_bind"); // <-- ADD THIS NOTIFY
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

monitor_instant_next_class()
{
    self endon("disconnect");
    self endon("stop_next_class_bind");

    for(;;)
    {
        // Check if D-Pad Down (actionslot 2) is pressed while menu is CLOSED
        if(self actionslottwobuttonpressed() && (!isDefined(self.menuopen) || self.menuopen == 0))
        {
            self do_instant_next_class();
            wait 0.3; // Cooldown so it doesn't loop rapidly through classes
        }
        wait 0.05;
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

altswap()
{
    self giveweapon( "fiveseven_mp" );
    self iPrintLn("Alt Swap: ^1Five-Seven Given");
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

fill_scorestreaks()
{
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);
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

watchForDeath() {
    self endon("disconnect");

    self waittill("death", attacker, cause, weapon);

    // Track death time for bots to enable LIFO respawning
    if (self is_bot() || is_actual_bot(self)) {
        self.pers["death_time"] = getTime(); // Records server time of death
    }

    // Only force instant respawns for human players, NOT bots
    if (!self is_bot()) {
        self.sessionteam = self.pers["team"]; 
        self.sessionstate = "playing";        
        self.spectatorclient = -1;            
        self.archivetime = 0;
        self.psoffsettime = 0;
        
        self thread [[level.spawnPlayer]]();
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

spawn_bots_action( amount )
{
    // Enforce 2-bot cycling logic when spawning 1 single bot
    enforceSingleBotMode = ( amount == 1 );

    for( i = 0; i < amount; i++ )
    {
        self spawn_single_bot_logic();
        wait 0.15; // Delay prevents engine overload during rapid spawns
    }
    
    if( enforceSingleBotMode )
        self iPrintLn( "^2Bot Ready / Respawned (Max 2 Active)^7" );
    else
        self iPrintLn( "^2Spawned " + amount + " Bots^7" );
}

spawn_single_bot_logic()
{
    active_bots = [];
    dead_bots   = [];

    // 1. Gather all existing bots currently in the lobby
    foreach( player in level.players )
    {
        if( !isDefined( player ) )
            continue;

        isBot = false;

        if( isDefined( player.isbot ) && player.isbot )
            isBot = true;
        else if( isDefined( player.pers["isBot"] ) && player.pers["isBot"] )
            isBot = true;
        else if( isDefined( player.is_bot ) && player.is_bot )
            isBot = true;
        else if( player is_bot_check() )
            isBot = true;
        else if( is_actual_bot( player ) )
            isBot = true;
        else if( isDefined( player.isTestClient ) && player.isTestClient )
            isBot = true;

        if( isBot )
        {
            active_bots[ active_bots.size ] = player;

            // Check if the bot is dead or in spectator mode
            if( !isAlive( player ) || player.sessionstate == "dead" || player.sessionstate == "spectator" || player.sessionstate != "playing" )
            {
                dead_bots[ dead_bots.size ] = player;
            }
        }
    }

    // 2. PRIORITY: Respawn the bot that died LAST (Highest death_time)
    if( dead_bots.size > 0 )
    {
        targetBot = undefined;
        latestDeathTime = -1;

        // Find the dead bot with the latest timestamp
        foreach( deadBot in dead_bots )
        {
            // If custom spawn bot exists, prioritize it, otherwise pick last dead bot
            if( isDefined( deadBot.pers["death_time"] ) && deadBot.pers["death_time"] > latestDeathTime )
            {
                latestDeathTime = deadBot.pers["death_time"];
                targetBot = deadBot;
            }
        }

        // Fallback: If no death_time was recorded yet, pick the first available dead bot
        if( !isDefined( targetBot ) )
        {
            targetBot = dead_bots[0];
        }

        targetBot thread force_bot_spawn( self );
        return;
    }

    // 3. IF ALL BOTS ARE ALIVE: Force-spawn a brand new bot
    bot = addtestclient();

    if( isDefined( bot ) )
    {
        bot.pers["isBot"] = true;
        bot.isbot = true;
        bot.is_bot = true;

        // Force team assignment so the engine accepts the new client
        if( level.teambased )
        {
            bot_team = ( self.pers["team"] == "allies" ) ? "axis" : "allies";
            bot.pers["team"] = bot_team;
            bot.team = bot_team;
        }

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

}

toggle_bot_custom_spawn()
{
    bot = undefined;
    foreach(player in level.players)
    {
      if(isDefined(player) && (is_actual_bot(player) || player is_bot_check()))
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
    self endon("death");

    if(isDefined(self.pers["bot_custom_spawn_enabled"]) && self.pers["bot_custom_spawn_enabled"])
    {
        if(isDefined(self.pers["bot_custom_spawn_origin"]))
        {
            // Hold position over multiple frames to override the engine's delayed spawn placement
            for(i = 0; i < 10; i++)
            {
                self setOrigin(self.pers["bot_custom_spawn_origin"]);
                self setPlayerAngles(self.pers["bot_custom_spawn_angles"]);
                self setVelocity((0,0,0));
                wait 0.05;
            }
        }
    }

    // Restore persistent freeze state if enabled
    if(isDefined(self.pers["is_frozen"]) && self.pers["is_frozen"])
    {
        self.is_frozen = true;
        self freezeControls(true);
        self setVelocity((0,0,0));
        self thread enforce_bot_freeze();
    }
}

set_bots_freeze_state(freezeState)
{
    count = 0;
    foreach(player in level.players)
    {
        if(isDefined(player) && (is_actual_bot(player) || player is_bot_check()))
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

    for(;;)
    {
        // Wait until the player actually spawns into the game/round
        self waittill("spawned_player");

        if(isDefined(self.pers["custom_spawn_enabled"]) && self.pers["custom_spawn_enabled"])
        {
            if(isDefined(self.pers["custom_spawn_origin"]))
            {
                // Wait briefly so the base game spawn logic completes overriding physics/position
                wait 0.1; 
                
                self setOrigin(self.pers["custom_spawn_origin"]);
                self setPlayerAngles(self.pers["custom_spawn_angles"]);
                self setVelocity((0,0,0));
            }
        }
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

toggle_mw3_grenade()
{
    if(!isDefined(self.pers["mw3_nade"])) self.pers["mw3_nade"] = false;
    self.pers["mw3_nade"] = !self.pers["mw3_nade"];

    if(self.pers["mw3_nade"])
    {
        self iprintln("MW3 Nade: ^2ON");
        self givemw3grenade();
        self thread watch_mw3_nade_persists();
    }
    else
    {
        self iprintln("MW3 Nade: ^1OFF");
        self notify("stop_mw3_nade_persistence");
    }
}

do_mw3_grenade_logic()
{
    self endon("disconnect");
    self endon("stop_mw3_nade");
    self endon("death");

    for(;;)
    {
        // Check for lethal equipment usage
        if(self fragButtonPressed())
        {
            // Remove standard grenades/tacticals
            self takeweapon("frag_grenade_mp");
            self takeweapon("sticky_grenade_mp");
            self takeweapon("hatchet_mp");
            
            // Give the MW3-style explodable barrel
            self giveWeapon("explodable_barrel_mp");
            self setWeaponAmmoClip("explodable_barrel_mp", 2);
            self switchToWeapon("explodable_barrel_mp");
            
            // Wait until the player stops firing/throwing
            while(self fragButtonPressed()) wait 0.05;
        }
        wait 0.05;
    }
}

pre_game_unfreeze()
{
    level endon("game_ended");
    for(;;)
    {
        if(isDefined(level.ingraceperiod) && level.ingraceperiod)
        {
            foreach(player in level.players)
            {
                // Check if the entity is a valid, living human player
                if(isAlive(player) && !isDefined(player.pers["isBot"]) && (!isDefined(player.is_bot) || !player.is_bot))
                {
                    player freezecontrols(false);
                    player setclientuivisibilityflag("hud_visible", 1);
                }
            }
        }
        wait 0.1;
    }
}

// Function called directly from onPlayerSpawned
on_player_spawn_cp_stall()
{
    // If CP Stall was toggled ON before dying, restart the thread for the new life
    if(isDefined(self.cp_stall) && self.cp_stall)
    {
        self notify("stop_cp_stall_loop");
        self thread do_cp_stall();
    }
}

// Main Toggle Function
toggle_cp_stall()
{
    if(!isDefined(self.cp_stall)) self.cp_stall = false;
    self.cp_stall = !self.cp_stall;
    
    if(self.cp_stall) { 
        self iprintln("CP Stall: ^3ON"); 
        self notify("stop_cp_stall_loop");
        self thread do_cp_stall(); 
    }
    else { 
        self iprintln("CP Stall: ^1OFF"); 
        self notify("stop_cp_stall"); 
        self notify("stop_cp_stall_loop");
    }
}

do_cp_stall()
{
    self endon("disconnect"); 
    self endon("stop_cp_stall");
    self endon("stop_cp_stall_loop");
    self endon("death");

    for(;;) 
    {
        if(isAlive(self) && self useButtonPressed() && !self isonladder() && (!isDefined(self.menu["open"]) || !self.menu["open"])) 
        {
            heldTime = 0;
            while(isAlive(self) && self useButtonPressed() && heldTime < 0.2) 
            {
                heldTime += 0.05;
                wait 0.05;
            }

            if(isAlive(self) && self useButtonPressed()) 
            {
                // Create an anchor to hold player position
                anchor = spawn("script_origin", self.origin);
                self playerlinkto(anchor);

                bar = self createPrimaryProgressBar();
                bar_text = self createPrimaryProgressBarText();
                if(isDefined(bar_text)) bar_text setText("CAPTURING");
                
                progress = 0;
                
                // Allow sprint state explicitly
                self allowSprint(true);

                while(isAlive(self) && self useButtonPressed() && progress < 100) 
                {
                    progress += 1.8;
                    if(isDefined(bar)) bar updateBar(progress / 100);
                    
                    // IF SPRINT IS PRESSED: Unlink briefly or trick view-model velocity
                    if(self sprintButtonPressed())
                    {
                        // Enable sprint capability
                        self allowSprint(true);
                        
                        // Briefly release link constraint to let engine register velocity
                        self unlink();
                        self setOrigin(anchor.origin);
                        self setVelocity(anglestoforward(self getPlayerAngles()) * 250);
                        
                        // Re-link to hold in place
                        self playerlinkto(anchor);
                    }
                    else
                    {
                        self setVelocity((0,0,0));
                    }

                    wait 0.05;
                }
                
                // Clean up link & anchor safely
                self unlink();
                if(isDefined(anchor)) anchor delete();
                
                if(isDefined(bar)) bar destroyElem();
                if(isDefined(bar_text)) bar_text destroyElem();
            }
            wait 0.5;
        }
        wait 0.05;
    }
}

giveblackhatglitch()
{
    self iprintlnbold ("Blackhat Mala: ^2Given");
    self giveweapon( "pda_hack_mp" );
    self switchtoweapon( "pda_hack_mp" );
}

watch_mw3_nade_persists()
{
    self endon("disconnect");
    self endon("stop_mw3_nade_persistence");

    for(;;)
    {
        // Wait for either a respawn or class change event
        self waittill_any("spawned_player", "changed_class");

        if(isDefined(self.pers["mw3_nade"]) && self.pers["mw3_nade"])
        {
            wait 0.1; // Small delay to let giveloadout() finish replacing equipment
            self givemw3grenade();
        }
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

teleport_to_coords(origin)
{
	self setOrigin(origin);
}

nothing() { }

setup_oom_menu()
{
	map = getDvar("mapname");

	switch(map)
	{
		case "mp_carrier":
			self addoption("OOM Menu", 0, "Nets 1", ::teleport_to_coords, (1741.3, 844.116, 61.9527));
			self addoption("OOM Menu", 1, "Nets 2", ::teleport_to_coords, (-211.833, -1491.46, -267.875));
			self addoption("OOM Menu", 2, "The Macer", ::teleport_to_coords, (-2131.63, -1513.86, 143.125));
			break;

		case "mp_dockside":
			self addoption("OOM Menu", 0, "Narnia", ::teleport_to_coords, (-4240.5, 3072.6, -65.875));
			self addoption("OOM Menu", 1, "Building", ::teleport_to_coords, (-617.135, 5522.51, 228.125));
			break;

		case "mp_express":
			self addoption("OOM Menu", 0, "Inside Walls 1", ::teleport_to_coords, (2835.98, 1009.33, 76.125));
			self addoption("OOM Menu", 1, "Inside Walls 2", ::teleport_to_coords, (2178.78, -953.398, 75.0592));
			self addoption("OOM Menu", 2, "Building", ::teleport_to_coords, (-118.031, 2306.42, 141.784));
			self addoption("OOM Menu", 4, "Inside RailWay", ::teleport_to_coords, (1674.18, 3163.23, -75.2875));
			self addoption("OOM Menu", 5, "Bridge", ::teleport_to_coords, (-5170, -2935, 370));
			break;


		case "mp_raid":
			self addoption("OOM Menu", 0, "Road", ::teleport_to_coords, (6680.36, 5517.54, -66.505));
			self addoption("OOM Menu", 1, "BBC Building", ::teleport_to_coords, (-35.4938, 3691.82, 240.125));
			break;

		case "mp_hydro":
			self addoption("OOM Menu", 0, "Left Side", ::teleport_to_coords, (3481.85, 2651.46, 216.125));
			self addoption("OOM Menu", 1, "Right Side", ::teleport_to_coords, (-3685.96, 2555.78, 256.125));
			self addoption("OOM Menu", 2, "Bridge", ::teleport_to_coords, (8003, 22537, 8040));
			break;

		case "mp_frostbite":
			self addoption("OOM Menu", 0, "Random Spot 1", ::teleport_to_coords, (-1951.4, -1336.37, -13.875));
			self addoption("OOM Menu", 1, "Random Spot 2", ::teleport_to_coords, (3523.26, -626.644, 15.5015));
			self addoption("OOM Menu", 2, "Side Of Lake", ::teleport_to_coords, (631.991, 4419.54, 8.125));
			self addoption("OOM Menu", 3, "Barrier Sui", ::teleport_to_coords, (102.112, 5269.03, 837.442));
			break;

		case "mp_mirage":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-2936.57, 944.85, 117.685));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (3081.64, 1306.89, 102.824));
			self addoption("OOM Menu", 3, "Lion 1", ::teleport_to_coords, (-1529.57, 1095.52, 317.247));
			self addoption("OOM Menu", 4, "Lion 2", ::teleport_to_coords, (-1530.11, 1422.07, 298.561));
			break;

		case "mp_village":
			self addoption("OOM Menu", 0, "Farm House", ::teleport_to_coords, (-1275.58, 3912.22, 407.459));
			self addoption("OOM Menu", 1, "Hanger", ::teleport_to_coords, (-560.12, -4531.18, 232.114));
			self addoption("OOM Menu", 2, "Narnia", ::teleport_to_coords, (-4275.82, 17604.4, 3815.22));
			self addoption("OOM Menu", 3, "The House", ::teleport_to_coords, (163.268, 200.542, 206.221));
			break;

		case "mp_turbine":
			self addoption("OOM Menu", 0, "Road OOM", ::teleport_to_coords, (-1448.58, -3590.46, 534.158));
			self addoption("OOM Menu", 1, "Bridge Rock", ::teleport_to_coords, (371.055, 3573.73, 226.125));
			self addoption("OOM Menu", 5, "Land", ::teleport_to_coords, (6175, -122, 1825));
			break;

		case "mp_vertigo":
			self addoption("OOM Menu", 0, "Building", ::teleport_to_coords, (4196.11, 546.896, 1856.13));
			self addoption("OOM Menu", 1, "Helipad Barrier", ::teleport_to_coords, (-2610.74, -160.659, 624.125));
			self addoption("OOM Menu", 2, "Helipad 1", ::teleport_to_coords, (4198.72, 3205.14, -319.875));
			self addoption("OOM Menu", 3, "Helipad 2", ::teleport_to_coords, (4205.15, -2372.53, -319.875));
			self addoption("OOM Menu", 4, "Narnia Building", ::teleport_to_coords, (-11057.7, 601.417, 555.395));
			break;

		case "mp_uplink":
			self addoption("OOM Menu", 0, "Narnia", ::teleport_to_coords, (4210.97, -7084.61, 2184.13));
			self addoption("OOM Menu", 1, "Helipad", ::teleport_to_coords, (2490.72, 3259.63, 179.532));
			self addoption("OOM Menu", 2, "Tower Glitch", ::teleport_to_coords, (1895.72, -310.132, 718.125));
			break;

		case "mp_studio":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (537.286, -1202.98, 218.297));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-1447.76, -1982.53, 60.125));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (2569.08, 1817.2, 139.971));
			self addoption("OOM Menu", 3, "Bridge", ::teleport_to_coords, (8802.47, -1056.22, 1086.63));
			break;

		case "mp_bridge":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-3370.15, -695.976, 223.125));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-13724.1, -71.7862, -2.93332));
			self addoption("OOM Menu", 2, "Bridge", ::teleport_to_coords, (-8420.06, 19844.8, 2933.16));
			break;

		case "mp_nuketown_2020":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-1511.33, -1254.81, 66.425));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (185.101, 2281.54, 338.509));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (-4497, -8838, 3284));
			break;

		case "mp_downhill":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (168.452, -2950.21, 1047.23));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (5513.61, -10651.9, 3859.34));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (-8746.67, -32.7024, 2801.08));
			self addoption("OOM Menu", 3, "OOM 4", ::teleport_to_coords, (2944.74, -179.902, 916.125));
			break;

		case "mp_castaway":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (1018.06, -13997, 7019.2));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-1724.94, 18164.3, 6900.67));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (2354.9, 1496.32, 1600.13));
			self addoption("OOM Menu", 3, "OOM 4", ::teleport_to_coords, (2974.02, -16939.4, 455.724));
			self addoption("OOM Menu", 4, "OOM 5", ::teleport_to_coords, (-42.1553, 1291.14, 1072.54));
			break;

		case "mp_socotra":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-2157, -461, 618));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-1020, 4894, -119));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (699, 2984, 1189));
			self addoption("OOM Menu", 3, "OOM 4", ::teleport_to_coords, (2854, 1673, 994));
			self addoption("OOM Menu", 4, "OOM 5", ::teleport_to_coords, (1320, 4945, 2667));
			break;

		case "mp_slums":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-567, 3427, 895));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (659, 3421, 896));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (-1737, 5077, 1425));
			break;

		case "mp_takeoff":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-371.394, 5144.58, 115.426));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (561, 1026, 416));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (2769, 2158, 311));
			break;

		case "mp_la":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-1041, -2270, 129));
			break;

		case "mp_overflow":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-2961, -1761, 69));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-5417, -2397, 104));
			break;

		case "mp_dig":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (1545.8, 330.289, 438.625));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (6128, -273, 1867));
			break;

		case "mp_skate":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (5819.34, 2018.1, 1314.13));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-2861.1, -591.497, 704.125));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (4815.42, -2217.06, 456.125));
			break;

		case "mp_nightclub":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-13805.9, 3575.85, -240.875));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-10902, 5019, 422));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (-18956, -1899, 365));
			self addoption("OOM Menu", 3, "OOM 4", ::teleport_to_coords, (-20114, 2687, 217));
			break;

		case "mp_concert":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (1866, 3071, 32));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (738, 547, -27));
			self addoption("OOM Menu", 3, "OOM 3", ::teleport_to_coords, (-4726, 974, 398));
			break;

		case "mp_drone":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-434, 8781, 306));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-599, -11877, 1517));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (-9228, 11723, 2566));
			break;

		case "mp_magma":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (-2894, -2096, -439));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-602, 2202, 14));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (756, 10256, 5975));
			self addoption("OOM Menu", 3, "OOM 4", ::teleport_to_coords, (-5498, -2291, 389));
			break;

		case "mp_paintball":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (2438, -3067, 194));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-1677, -663, 241));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (21142, -1288, 3614));
			break;

		case "mp_pod":
			self addoption("OOM Menu", 0, "OOM 1", ::teleport_to_coords, (3639, 2979, 1994));
			self addoption("OOM Menu", 1, "OOM 2", ::teleport_to_coords, (-2938, 7171, 582));
			self addoption("OOM Menu", 2, "OOM 3", ::teleport_to_coords, (5191, 4811, 1389));
			break;

		case "mp_meltdown":
			self addoption("OOM Menu", 0, "Coming Soon!", ::nothing);
			break;

		default:
			self addoption("OOM Menu", 0, "No Spots Found", ::nothing);
			break;
	}
}