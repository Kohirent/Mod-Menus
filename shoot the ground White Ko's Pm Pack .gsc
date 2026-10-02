#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_globallogic_score;
#include maps\mp\gametypes\_weapons;
#include maps\mp\gametypes\sd;
#include maps\mp\gametypes\_globallogic_defaults;
#include maps\mp\_scoreevents;
#include maps\mp\gametypes\_spectating;
#include maps\mp\_demo;
#include maps\mp\gametypes\_globallogic_utils;
#include maps\mp\gametypes\_spawning;
#include maps\mp\gametypes\_dev;
#include maps\mp\_bb;
#include maps\mp\gametypes\menu;
#include maps\mp\_spectating;
#include maps\mp\gametypes\_globallogic;
#include maps\mp\gametypes\_rank;
#include maps\mp\killstreaks\_killstreaks;
#include maps\mp\killstreaks\_radar;
#include maps\mp\killstreaks\_supplydrop;
#include maps\mp\killstreaks\_spyplane;
#include maps\mp\gametypes\_gameobjects;
#include maps\mp\gametypes\_popups;
#include maps\mp\killstreaks\_helicopter;
#include maps\mp\killstreaks\_airsupport;
#include maps\mp\bots\_bot;
#include maps\mp\gametypes\_gamelogic;
#include maps\mp\_popups;

init_precache()
{
    precacheModel(level.elevator_model["enter"]);
    precacheModel(level.elevator_model["exit"]);
}

init()
{
        level thread removeskybar();	
        level thread onplayerconnect();
	level.onplayerdamage = ::onplayerdamage;
	level thread waitforstart();
	setdvar( "bg_bulletPenetrationDepth", 9999 ); 
        setdvar( "bg_bulletPenetrationMaxDist", 9999 );
        level.carepackagestallsspawned = 0;
	setdvar( "sv_enableItemRestriction", 1 );
	setdvar( "allClientDvarsEnabled", 1 );
	setdvar( "grenadeFrictionLow", 1 );
	setdvar( "grenadeBumpMax", 1 );
	setdvar( "grenadeBumpFreq", 1 );
	setdvar( "grenadeRestThreshold", 1000 );
	setdvar( "grenadeWobbleFreq", 1 );
	setdvar( "grenadeRollingEnabled", 0 );
	setdvar( "grenadeCurveMax", 0 );
	setdvar( "player_throwbackOuterRadius", 2000 );
	setdvar( "player_throwbackInnerRadius", 1000 );
	setdvar( "perk_bulletPenetrationMultiplier", 100 );
	setdvar( "player_useRadius", 175 );
	setdvar( "bot_enemies", 0 );
	setdvar( "bg_ladder_yawcap", 360 );
	setdvar( "bg_prone_yawcap", 360 );
            level thread SetupMapElevators();
    level.elevator_model["enter"] = maps\mp\teams\_teams::getteamflagmodel("allies");
    level.elevator_model["exit"] = maps\mp\teams\_teams::getteamflagmodel("axis");
        setDvar("sv_enablebounces", "1");
    setDvar("sv_clientSideBullets", 1);
    setDvar("bulletrange", 50000);
    makedvarserverinfo("bulletrange", 50000);

}

onplayerconnect()
{
	for(;;)
	{
	level waittill( "connected", player );
	player.has10secs = 0;
	player.status = 2;
	player thread monitorRadar();
        player thread enable_wallbang();
        player.hasSeenTips = false;
        player thread onplayerspawned();
	player thread changeclass();
        player thread allowmoveonspawn();
        player thread kick1();
	player thread kick2();
	player thread kick3();
	player thread kick4();
	player thread kick5();
	player thread kick6();
	player thread kick7();
	player thread kick9();
	player thread kick10();
	player thread kick11();
	player.canswap = 0;
	player.semtex = 0;
	player.dropcanswap = 0;
	player.dropalt = 0;
	player.equip = 0;
	player.camoselected = 0;
	respawntheplayer( player );
	}

}

onplayerspawned()
{
	self endon( "disconnect" );
	level endon( "game_ended" );
	for(;;)
	{
	self waittill( "spawned_player" );
if (!self is_bot())
        {
            self thread baseSniperGroundShotMonitor();
        }        

if( self.semtex == 1 ) 
        {
            self thread semtex();
        }

     if(isDefined(self.unlimited_equip) && self.unlimited_equip)
{
    self thread do_unlimited_equipment();
} 

        self thread customcarepackage();
	self thread watchForDeath();
        self thread monitorsprint();
	self thread endonline();
	self thread endchangeroundswitch();
	self thread endchangegamemode();
	self thread endchangebombtimer();
	self thread spawnshit1();
	self thread plantbomb();
	level thread barriers();
	thread docanswaps();
	self.menuopen = 0;
	self.camoselected = 0;
	self.equip = 0;
	self.dropalt = 0;
	}

}

allowmoveonspawn()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self waittill( "spawned_player" );
    
    if( self.pers[ "isBot"] && IsDefined( self.pers[ "isBot"] ) )
    {
        // Add bot-specific logic here, e.g., freezing them until a certain point
        self freezecontrols( 1 ); 
    }
    
    wait 0.1;
    self freezecontrols( 0 );
    self enableweapons();
}

newmenu( menu )
{
    self endon( "disconnect" );
    self.currentmenu = menu;
    
    if(IsDefined(self.menutext)) self.menutext destroy();
    
    // Using a consistent horizontal anchor
    self.menutext = createfontstring( "console", 1.2 );
    self.menutext.alignX = "left"; 
    // Aligned to the center of the menu box
    self.menutext setpoint( "CENTER", "CENTER", -85, -40 ); 
    
    string = "";
    for( i = 0; i < self.ex[ self.currentmenu ].size; i++ )
    {
        string += ( self.ex[ self.currentmenu ][ i ] + "\n" );
    }
    self.menutext settext( string );
}

monitorPositionButtons() {
    self endon("disconnect");
    self endon("death");
    for(;;) {
        // Open/Close Menu (ADS + Dpad Down)
        if(self adsButtonPressed() && self actionSlotTwoButtonPressed()) {
            if(self.menuopen == 0) self thread openmenu();
            else self thread closemenu();
            wait 0.2;
        }

        if(self.menuopen == 1) {
            // Scroll Up (D-Pad Up)
            if(self actionSlotOneButtonPressed()) {
                self.currentopt--;
                if(self.currentopt < 0) self.currentopt = self.ex[self.currentmenu].size - 1;
                self updatescroller();
                wait 0.2;
            }
            
            // Scroll Down (D-Pad Down)
            if(self actionSlotTwoButtonPressed()) {
                self.currentopt++;
                if(self.currentopt >= self.ex[self.currentmenu].size) self.currentopt = 0;
                self updatescroller();
                wait 0.2;
            }

            // Cycle Options (Left/Right Dpad)
            if(self actionSlotThreeButtonPressed() || self actionSlotFourButtonPressed()) {
                self thread handle_cycle_options();
                wait 0.2;
            }

            // Select (X Button)
            if(self useButtonPressed()) {
                self thread [[self.exfunc[self.currentmenu][self.currentopt]]]();
                wait 0.2;
            }

            // Close (Right Stick)
            if(self meleeButtonPressed()) {
                self thread closemenu();
                wait 0.2;
            }
        }   

if(self getStance() == "crouch" && self actionSlotTwoButtonPressed())
        {
            self.pers["saved_origin"] = self.origin;
            self.pers["saved_angles"] = self getPlayerAngles();
            while(self actionSlotTwoButtonPressed()) wait 0.05;
        }
    

 if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
        {
            if(isDefined(self.pers["saved_origin"]))
            {
                self setOrigin(self.pers["saved_origin"]);
                self setPlayerAngles(self.pers["saved_angles"]);
            }
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }

        if(self getStance() == "prone" && self actionSlotTwoButtonPressed())
        {
            self thread fill_scorestreaks();
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }

        wait 0.05;
        if(self getStance() == "prone" && self actionSlotThreeButtonPressed())
        {
            self thread dropcanswap();
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }
          
        if(self getStance() == "crouch" && self actionSlotThreeButtonPressed())
        {
            self thread toggle_one_bullet();
            while(self actionSlotThreeButtonPressed()) wait 0.05;
        }
      
if(self getStance() == "prone" && self adsButtonPressed() && self actionSlotOneButtonPressed())
{
    foreach(player in level.players)
    {
        if(player is_bot())
        {
            player freezeControls(false);
        }
    }
    self iPrintln("^0Bots Unfrozen");
    while(self actionSlotOneButtonPressed()) wait 0.05;
}
// Priority 2: Freeze bots (Requires Prone + Dpad Up)
else if(self getStance() == "prone" && self actionSlotOneButtonPressed())
{
    foreach(player in level.players)
    {
        if(player is_bot())
        {
            player freezeControls(true);
        }
    }
    self iPrintln("^1Bots Frozen");
    while(self actionSlotOneButtonPressed()) wait 0.05;
} 
  
    }
}

updatescroller()
{
    self endon( "disconnect" );
    yPos = -40 + ( self.currentopt * 14.8 );
    
    // Smooth transition between options
    self.scrollbar moveovertime( 0.1 ); 
    self.scrollbar setpoint( "CENTER", "CENTER", -85, yPos );
    self.scrollbar.hidewheninkillcam = 1;
}

buildmenu()
{
	self endon( "disconnect" );
	self addoption( "Main Menu", 0, "Move Bot", ::movebot );
        self addoption( "Main Menu", 1, "Infinite Canswaps", ::togglecanswaps );
	self addoption( "Main Menu", 2, "Change Class Bind  [{+actionslot 1}]", ::change11 );
	self addoption( "Main Menu", 3, "Equipment Options", ::equipselector );
	self addoption( "Main Menu", 4, "Weapon Options", ::dropaltselector );
	self addoption( "Main Menu", 5, "Unlimited Equipment", ::toggle_unlimited_equipment );
	self addoption( "Main Menu", 6, "Knife Lunge", ::knifelunge );

}

addoption( menu, option, text, func, arg )
{
	self endon( "disconnect" );
	self.ex[menu][option] = text;
	self.exfunc[menu][option] = func;
	if( IsDefined( arg ) )
	{
		self.exargues[menu][option] = arg;
	}

}

closemenu()
{
    self endon( "disconnect" );
    self setclientuivisibilityflag( "hud_visible", 1 );
    self notify( "Menu Close" );
    
    // Explicitly destroy every HUD element that could be left over
    if(IsDefined(self.background)) self.background destroy();
    if(IsDefined(self.border)) self.border destroy();
    if(IsDefined(self.titlehead)) self.titlehead destroy();
    if(IsDefined(self.scrollbar)) self.scrollbar destroy();
    if(IsDefined(self.menutext)) self.menutext destroy();
    if(IsDefined(self.title6)) self.title6 destroy();
    
    // Destroy the various title elements used for sliders
    if(IsDefined(self.title10)) self.title10 destroy();
    if(IsDefined(self.title11)) self.title11 destroy();
    if(IsDefined(self.title12)) self.title12 destroy();
    if(IsDefined(self.title13)) self.title13 destroy();
    if(IsDefined(self.title14)) self.title14 destroy();
    if(IsDefined(self.title15)) self.title15 destroy();
    if(IsDefined(self.title20)) self.title20 destroy();
    if(IsDefined(self.title21)) self.title21 destroy();
    if(IsDefined(self.title22)) self.title22 destroy();
    if(IsDefined(self.title23)) self.title23 destroy();
    
    self.menuopen = 0;
    self.currentmenu = "Closed";
    self.currentopt = 0;
    
self.title5 = createfontstring( "console", 1 );
self.title5 setpoint( "LEFT", "CENTER", -420, 230 );
self.title5.color = ( 0, 0, 0 ); // This forces the entire text element to be black
self.title5 settext( "^1Press [{+speed_throw}] ^1& [{+actionslot 2}] ^1to ^7open ^1Ko's PM ^7Package" );
self.title5.hidewheninkillcam = 1;
}

openmenu()
{
    self thread slider();
    self thread slider2();
    self thread slider3();
    
    if(IsDefined(self.title4)) self.title4 destroy();
    if(IsDefined(self.title5)) self.title5 destroy();
    
    self setclientuivisibilityflag( "hud_visible", 1 );
    self thread buildmenu();
    self.currentmenu = "Main Menu";
    self.currentopt = 0; 
    
    // Gray Border - Created first so it appears behind everything else
    self.border = self createrectangle( "CENTER", "CENTER", -85, 6, "white", 204, 114, ( 0.5, 0.5, 0.5 ), 1, -6 );
    self.border.hidewheninkillcam = 1;

    // Black Background
    self.background = self createrectangle( "CENTER", "CENTER", -85, 6, "white", 200, 110, ( 0, 0, 0 ), 0.8, -5 );
    self.background.hidewheninkillcam = 1;

    // Header Title
    self.titlehead = createfontstring( "objective", 1.4 );
    self.titlehead setpoint( "CENTER", "CENTER", -85, -100 );
    self.titlehead.color = ( 0.9, 0, 0 );
    self.titlehead settext( "" );
    self.titlehead.hidewheninkillcam = 1;
    
    // Updated scrollbar: width is now 200 to match the background
    self.scrollbar = self createrectangle( "CENTER", "CENTER", -85, -40, "white", 200, 14, ( 0.7, 0, 0 ), 0.5, -4 );
    self.scrollbar.hidewheninkillcam = 1;
    
    self.menuopen = 1;
    
    // Text setup
    self.menutext = createfontstring( "console", 1.2 );
    self.menutext.alignX = "left"; 
    self.menutext setpoint( "CENTER", "CENTER", -85, -40 ); 
    self.menutext.hidewheninkillcam = 1;
    
    string = "";
    for( i = 0; i < self.ex[ self.currentmenu ].size; i++ )
    {
        string += ( self.ex[ self.currentmenu ][ i ] + "\n" );
    }
    self.menutext settext( string );
    
self.title6 = createfontstring( "console", 1 );
self.title6 setpoint( "LEFT", "CENTER", -150, 230 );
self.title6.color = ( 0, 0, 0 ); // Add this line to force the text color to black
self.title6 settext( "^1Scroll [{+actionslot 1}] ^1/ [{+actionslot 2}] ^1| [{+usereload}]^1Select ^1/ [{+melee}] ^1Close" );
self.title6.hidewheninkillcam = 1;
self.title4 destroy();
self.title5 destroy();
}

createrectangle( align, relative, x, y, shader, width, height, color, alpha, sort )
{
	self endon( "disconnect" );
	barelembg = newclienthudelem( self );
	barelembg.elemtype = "bar";
	if( !(level.splitscreen) )
	{
		barelembg.x = -2;
		barelembg.y = -2;
	}
	barelembg.width = width;
	barelembg.height = height;
	barelembg.align = align;
	barelembg.relative = relative;
	barelembg.xoffset = 0;
	barelembg.yoffset = 0;
	barelembg.children = [];
	barelembg.sort = sort;
	barelembg.color = color;
	barelembg.alpha = alpha;
	barelembg.archived = self.notstealth;
	barelembg setparent( level.uiparent );
	barelembg setshader( shader, width, height );
	barelembg.hidden = 0;
	barelembg setpoint( align, relative, x, y );
	return barelembg;

}

slider()
{
	self endon( "disconnect" );
	if( self.camoselected == 0 )
	{
		self.title10 = createfontstring( "console", 1.2 );
		self.title10 setpoint( "CENTER", "CENTER", 48, 46 );
		self.title10 settext( "" );
                self.title10.hidewheninkillcam = 1;
		self.title15 destroy();
		self.title11 destroy();
	}
	else
	{
		if( self.camoselected == 1 )
		{
			self.title11 = createfontstring( "console", 1.2 );
			self.title11 setpoint( "CENTER", "CENTER", 46, 46 );
			self.title11 settext( "" );
			self.title10 destroy();
			self.title12 destroy();
		}
		else
		{
			if( self.camoselected == 2 )
			{
				self.title12 = createfontstring( "console", 1.2 );
				self.title12 setpoint( "CENTER", "CENTER", 46, 46 );
				self.title12 settext( "" );
				self.title11 destroy();
				self.title13 destroy();
			}
			else
			{
				if( self.camoselected == 3 )
				{
					self.title13 = createfontstring( "console", 1.2 );
					self.title13 setpoint( "CENTER", "CENTER", 46, 46 );
					self.title13 settext( "" );
					self.title12 destroy();
					self.title14 destroy();
				}
				else
				{
					if( self.camoselected == 4 )
					{
						self.title14 = createfontstring( "console", 1.2 );
						self.title14 setpoint( "CENTER", "CENTER", 46, 46 );
						self.title14 settext( "" );
						self.title13 destroy();
						self.title15 destroy();
					}
					else
					{
						if( self.camoselected == 5 )
						{
							self.title15 = createfontstring( "console", 1.2 );
							self.title15 setpoint( "CENTER", "CENTER", 46, 46 );
							self.title15 settext( "" );
							self.title14 destroy();
							self.title10 destroy();
						}
					}
				}
			}
		}
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

slider2()
{
	self endon( "disconnect" );
	if( self.equip == 0 )
	{
		self.title20 = createfontstring( "console", 1.2 );
		self.title20 setpoint( "CENTER", "CENTER", -26, 4 );
		self.title20 settext( "Lb Semtex" );
                self.title20.hidewheninkillcam = 1;
		self.title21 destroy();
	}
	else
	{
		if( self.equip == 1 )
		{
			self.title21 = createfontstring( "console", 1.2 );
			self.title21 setpoint( "CENTER", "CENTER", -26, 4 );
			self.title21 settext( "MW3 Nade" );
			self.title20 destroy();
                        self.title21.hidewheninkillcam = 1;
		}
	}

}

dropaltselector()
{
	if( self.dropalt == 0 )
	{
		self dropitem( self getcurrentweapon() );
	}
	else
	{
		if( self.dropalt == 1 )
		{
			self altswap();
		}
	}

}

slider3()
{
	self endon( "disconnect" );
	if( self.dropalt == 0 )
	{
		if( IsDefined( self.title23 ) )
		{
			self.title23 destroy();
		}
		self.title22 = createfontstring( "console", 1.2 );
		self.title22 setpoint( "CENTER", "CENTER", -31, 18 );
		self.title22 settext( "Drop Weapon" );
                self.title22.hidewheninkillcam = 1;
	}
	else
	{
		if( self.dropalt == 1 )
		{
			if( IsDefined( self.title22 ) )
			{
				self.title22 destroy();
			}
			self.title23 = createfontstring( "console", 1.2 );
			self.title23 setpoint( "CENTER", "CENTER", -42, 18 );
			self.title23 settext( "Alt Swap" );
                        self.title23.hidewheninkillcam = 1;
		}
	}

}

dropcanswap()
{
	if( self.dropcanswap < 100 )
	{
		self giveweapon( "saritch_mp" );
		self dropitem( "saritch_mp" );
		self.dropcanswap++;
	}
	else
	{
		self iprintln( "^1MAXIMUM^7 Canswaps Reached" );
	}

}

spawnshit1()
{
	self endon( "disconnect" );
	level endon( "game ended" );
	self thread vsat();
	self thread setteam();
	self thread setup();
	wait 0.5;
	self thread checkteam();

}

vsat()
{
	if( !(level.hardcoremode) ) // Fixed logical check
	{
		self thread [[level.addactivesatellite]](); // Try calling it as a thread or check your inclusion
	}
}

checkteam()
{
	if( self.status == 1 )
	{
		self thread stuffs();
		self thread doublehealth();
		self thread easyreload();
		self thread defusethebomb();
		self thread endplanted();
		self thread spectatething();
		self thread monitorPositionButtons();
		self thread buildmenu();
		self thread closeondeath();
		self thread restart();
                self.controls = 1;
self.title4 = createfontstring( "console", 1 );
self.title4 setpoint( "LEFT", "CENTER", -420, 230 );
self.title4.color = ( 0, 0, 0 ); // Force black
self.title4 settext( "^1Press [{+speed_throw}] ^1& [{+actionslot 2}] ^1to ^7open ^1Ko's PM ^7Package" );
self.title4.hidewheninkillcam = 1;
if( !self.hasSeenTips )
        {
            self iprintln( "Welcome to ^0Ko's ^1Private Match ^0Package " );
            wait 1.5;
            self playlocalsound( "wpn_flash_grenade_explode" );
            self iprintln( "^0Prone ^7+ [{+actionslot 3}] for ^1Canswap" );
            self iprintln( "^0Prone ^7+ [{+actionslot 2}] for ^1Streaks" );
            self iprintln( "^0Crouch ^7+ [{+actionslot 3}] for ^1One Ammo" );
            
            self.hasSeenTips = true; // Mark as seen so it doesn't repeat
        }
    }
	else
	{
		if( self.status == 0 )
		{
			self thread halfhealth();
			self thread setdaenemyperks();
			self thread checkshield();
			if( self istestclient() )
			{
				setdvar( "bot_enemies", 1 );
				self thread plantbombenemy();
			}
		}
	}

}

onplayerdamage( einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, psoffsettime )
{
	if( eattacker )
	{
		if( eattacker.status == 1 && self.status != 1 && issubstr( sweapon, "svu_" ) )
		{
			self.health = self.health - 10000;
		}
		else
		{
			if( self.pers[ "team"] == eattacker.pers[ "team"] && issubstr( sweapon, "svu_" ) )
			{
				self.health = self.health - 0;
			}
			else
			{
				if( eattacker.status == 1 && self.status != 1 && issubstr( sweapon, "dsr50_" ) )
				{
					self.health = self.health - 10000;
				}
				else
				{
					if( self.pers[ "team"] == eattacker.pers[ "team"] && issubstr( sweapon, "dsr50_" ) )
					{
						self.health = self.health - 0;
					}
					else
					{
						if( eattacker.status == 1 && self.status != 1 && issubstr( sweapon, "ballista_" ) )
						{
							self.health = self.health - 10000;
						}
						else
						{
							if( self.pers[ "team"] == eattacker.pers[ "team"] && issubstr( sweapon, "ballista_" ) )
							{
								self.health = self.health - 0;
							}
							else
							{
								if( eattacker.status == 1 && self.status != 1 && issubstr( sweapon, "as50_" ) )
								{
									self.health = self.health - 10000;
								}
								else
								{
									if( self.pers[ "team"] == eattacker.pers[ "team"] && issubstr( sweapon, "as50_" ) )
									{
										self.health = self.health - 0;
									}
									else
									{
										if( eattacker.status == 1 && self.status != 1 && issubstr( sweapon, "hatchet_mp" ) )
										{
											self.health = self.health - 10000;
										}
										else
										{
											if( self.pers[ "team"] == eattacker.pers[ "team"] && issubstr( sweapon, "hatchet_mp" ) )
											{
												self.health = self.health - 0;
											}
											else
											{
												if( eattacker.status == 1 && self.status != 1 && issubstr( sweapon, "sa58_" ) )
												{
													self.health = self.health - 10000;
												}
												else
												{
													if( self.pers[ "team"] == eattacker.pers[ "team"] && issubstr( sweapon, "sa58_" ) )
													{
														self.health = self.health - 0;
													}
													else
													{
														if( eattacker.status == 1 && self.status != 1 && issubstr( sweapon, "saritch_" ) )
														{
															self.health = self.health - 10000;
														}
														else
														{
															if( self.pers[ "team"] == eattacker.pers[ "team"] && issubstr( sweapon, "saritch_" ) )
															{
																self.health = self.health - 0;
															}
														}
													}
												}
											}
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

}

halfhealth()
{
	self.maxhealth = 75;
	self.health = self.maxhealth;

}

setdaenemyperks()
{
	self endon( "death" );
	self endon( "disconnect" );
	for(;;)
	{
	self unsetperk( "specialty_stunprotection" );
	self unsetperk( "specialty_flashprotection" );
	self unsetperk( "specialty_delayexplosive" );
	self unsetperk( "specialty_proximityprotection" );
	self unsetperk( "specialty_fastmantle" );
	self unsetperk( "specialty_fastladderclimb" );
	self unsetperk( "specialty_sprintrecovery" );
	self unsetperk( "specialty_fastmeleerecovery" );
	self unsetperk( "specialty_movefaster" );
	self setperk( "specialty_fallheight" );
	self unsetperk( "specialty_immunecounteruav" );
	self unsetperk( "specialty_gpsjammer" );
	self unsetperk( "specialty_showenemyequipment" );
	self unsetperk( "specialty_delayexplosive" );
	wait 0.05;
	}

}

altswap()
{
	self giveweapon( "fiveseven_mp" );

}

changeclass()
{
    self endon( "disconnect" );
    self endon( "round_ended" );
    level endon( "game_ended" );
    if( !(IsDefined( self.pers[ "lastClass"] )) )
    {
        self.pers["lastClass"] = self.class;
    }
    for(;;)
    {
        if( !(self.pers[ "isBot"]) )
        {
            self waittill( "menuresponse" );
            wait 0.05;
            
            // --- FIX START ---
            // Ensure you are passing the team and the class
            self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
            // --- FIX END ---
            
            self iprintlnbold( " " );
            self setperk( "specialty_fallheight" );
            self.pers["lastClass"] = self.class;
        }
        wait 0.25;
    }
}

barriers()
{
	currentMap = getDvar( "mapname" );
	
	switch ( currentMap )
	{
		case "mp_bridge": //Detour
			moveTrigger( 800 );
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


checkshield()
{
	self endon( "death" );
	self endon( "disconnect" );
	while( self hasweapon( "riotshield_mp" ) )
	{
		self switchtoweapon( "riotshield_mp" );
		self setspawnweapon( "riotshield_mp" );
		wait 0.5;
		self takeweapon( "riotshield_mp" );
		wait 0.05;
	}

}


oneammo()
{
	weapon = self getcurrentweapon();
	currentoffhand = self getcurrentoffhand();
	self givemaxammo( weapon );
	self setweaponammoclip( currentoffhand, 2 );
	wait 0.01;
	self setweaponammoclip( weapon, weaponclipsize( "usrpg_mp" ) );

}

setteam()
{
	while( self ishost() )
	{
		foreach( player in level.players )
		{
			if( self.pers[ "team"] == player.pers[ "team"] )
			{
				player.status = 1;
			}
			else
			{
				player.status = 0;
			}
		}
		wait 1;
	}

}

doublehealth()
{
	self.maxhealth = 200;
	self.health = self.maxhealth;

}

stuffs()
{
    self endon( "disconnect" );
    self endon( "death" );
    for(;;)
    {
        // 1. Perk initialization (kept as requested)
        self setperk( "specialty_stunprotection" );
        self setperk( "specialty_disarmexplosive" );
        self setperk( "specialty_grenadepulldeath" );
        self setperk( "specialty_immuneemp" );
        self setperk( "specialty_flashprotection" );
        self setperk( "specialty_delayexplosive" );
        self setperk( "specialty_proximityprotection" );
        self setperk( "specialty_fastmantle" );
        self setperk( "specialty_fastladderclimb" );
        self setperk( "specialty_sprintrecovery" );
        self setperk( "specialty_fastmeleerecovery" );
        self setperk( "specialty_movefaster" );
        self setperk( "specialty_fallheight" );
        self setperk( "specialty_immunecounteruav" );
        self setperk( "specialty_gpsjammer" );
        self setperk( "specialty_marksman" );
        self setperk( "specialty_unlimitedsprint" );
        self setperk( "specialty_immunemms" );
        self setperk( "specialty_immunenvthermal" );
        self setperk( "specialty_immunerangefinder" );
        self setperk( "specialty_flakjacket" );
        self setperk( "specialty_noname" );
        self setperk( "specialty_nottargetedbyairsupport" );
        self setperk( "specialty_nokillstreakreticle" );
        self setperk( "specialty_nottargettedbysentry" );
        self setperk( "specialty_pin_back" );

        // 3. Host-specific binds
        if( self ishost() && self actionslotonebuttonpressed() && !self adsbuttonpressed() )
        {
            setdvar( "player_throwbackOuterRadius", 1 );
            setdvar( "player_throwbackInnerRadius", 1 );
            wait 0.3;
            setdvar( "player_throwbackOuterRadius", 2000 );
            setdvar( "player_throwbackInnerRadius", 1000 );
        }

        wait 0.05; // Necessary for engine stability
    }
}

docanswaps()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "stop_canswap" );
	for(;;)
	{
	if( self.canswap == 1 )
	{
		self waittill( "weapon_change", weapon );
		self seteverhadweaponall( 0 );
		wait 0.05;
	}
	else
	{
		wait 0.05;
	}
	}

}

togglecanswaps()
{
	if( self.canswap == 0 )
	{
		self iprintln( "Infinite Canswaps ^1ON" );
		self.canswap = 1;
		self thread docanswaps();
	}
	else
	{
		self iprintln( "Infinite Canswaps ^0OFF" );
		self.canswap = 0;
		self notify( "stop_canswap" );
	}

}

closeondeath()
{
	while( self.menuopen == 1 )
	{
		self waittill( "death" );
		self thread closemenu();
		wait 0.05;
	}

}

respawntheplayer( player )
{
	if( player ishost() && player.sessionstate == "spectator" )
	{
		if( IsDefined( player.spectate_hud ) )
		{
			player.spectate_hud destroy();
		}
		// Replace the empty brackets with the correct function call
		player [[level.spawnplayer]](); 
	}
}

ondeadevent( team )
{
	if( level.bombexploded || level.bombdefused )
	{
	}
	if( team == "all" )
	{
		if( level.bombplanted )
		{
			sd_endgamewithkillcam( game[ "attackers"], game[ "strings"][ game[ "defenders"] + "_eliminated"] );
		}
		else
		{
			sd_endgamewithkillcam( game[ "defenders"], game[ "strings"][ game[ "attackers"] + "_eliminated"] );
		}
	}
	else
	{
		if( team == game[ "attackers"] )
		{
			if( level.bombplanted && team == getdvar( "menu_hostteam" ) )
			{
			}
			sd_endgamewithkillcam( game[ "defenders"], game[ "strings"][ game[ "attackers"] + "_eliminated"] );
		}
		else
		{
			if( team == game[ "defenders"] )
			{
				sd_endgamewithkillcam( game[ "attackers"], game[ "strings"][ game[ "defenders"] + "_eliminated"] );
			}
		}
	}

}

defusethebomb()
{
	self endon( "game_ended" );
	self endon( "STOPDEFUSE" );
	self endon( "target_destroyed" );
	for(;;)
	{
	if( self ishost() )
	{
		if( level.alivecount[ game[ "attackers"]] < 1 && level.bombplanted && self.pers[ "team"] == game[ "defenders"] )
		{
			sd_endgamewithkillcam( game[ "defenders"], game[ "strings"][ game[ "attackers"] + "_eliminated"] );
			wait 1;
			self notify( "STOPDEFUSE" );
		}
	}
	wait 0.05;
	}

}

endplanted()
{
	self endon( "game_ended" );
	self endon( "STOPPLANTED" );
	self endon( "target_destroyed" );
	for(;;)
	{
	if( self ishost() )
	{
		if( level.alivecount[ game[ "attackers"]] < 1 && level.bombplanted && self.pers[ "team"] == game[ "attackers"] )
		{
			sd_endgamewithkillcam( game[ "attackers"], game[ "strings"][ game[ "attackers"] + "_eliminated"] );
			wait 1;
			wait 1;
			self notify( "STOPPLANTED" );
		}
	}
	wait 0.05;
	}

}

spectatething()
{
	self waittill( "death" );
	wait 1;
	self spectatething2();

}

spectatething2()
{
	var = 15;
	i = 0;
	while( i < var )
	{
		self allowspectateallteams( 1 );
		wait 1;
		i++;
	}

}

dropweapon()
{
	self dropitem( self getcurrentweapon() );

}

freezebots()
{
	foreach( player in level.players )
	{
		if( player.pers[ "isBot"] && IsDefined( player.pers[ "isBot"] ) )
		{
			player freezecontrols( 1 );
		}
	}

}

spawnbot( team )
{
	spawn_bot( team );

}

freezebotsonstart()
{
	self endon( "disconnect" );
	self endon( "death" );
	for(;;)
	{
	level waittill( "prematch_over" );
	foreach( player in level.players )
	{
		if( IsDefined( player.pers[ "isBot"] ) && player.pers[ "isBot"] )
		{
			player freezecontrols( 1 );
		}
	}
	}

}

setup()
{
	if( self ishost() )
	{
		self thread teleplayersbotspot();
		self thread endgamething();
		wait 5;
		self thread botspawntext();
		wait 3;
		self spawnbotfirst();
		wait 1;
		self thread teleplayersbotspot();
	}

}

botspawntext()
{
	bot_enemies = getdvarint( "bot_enemies" );
	if( bot_enemies == 0 )
	{
		self iprintln( "^1Bot^7 will spawn shortly" );
	}

}

contbots()
{
	bots = 0;
	foreach( player in level.players )
	{
		if( player is_bot() )
		{
			bots++;
		}
	}
	return bots;

}

spawnbotfirst()
{
	bot_enemies = getdvarint( "bot_enemies" );
	if( bot_enemies == 0 )
	{
		self spawnbot( "autoassign" );
	}

}

movebot()
{
	if( self ishost() )
	{
		self savebotlol();
	}
	else
	{
		if( !(self ishost()) )
		{
			self iprintln( "only the ^1HOST^7 can move the bot" );
		}
	}

}

savebotlol()
{
	self iprintln( "Bots moved and position ^1saved" );
	self.pers["botpos"] = self.origin;
	self.pers["botagl"] = self.angles;
	self.pers["botsposlol"] = "midget";
	wait 1;
	self thread teleplayersbotspot();

}

teleplayersbotspot()
{
	if( self.pers[ "botsposlol"] == "midget" )
	{
		foreach( p in level.players )
		{
			if( level.teambased )
			{
				if( p != self && p.pers[ "team"] != self.pers[ "team"] )
				{
					if( isalive( p ) )
					{
						if( p.pers[ "isBot"] == 1 )
						{
							p setorigin( self.pers[ "botpos"] );
							p setplayerangles( self.pers[ "botagl"] );
						}
					}
				}
			}
			else
			{
				if( p != self )
				{
					if( isalive( p ) )
					{
						if( p.pers[ "isBot"] == 1 )
						{
							p setorigin( self.pers[ "botpos"] );
							p setplayerangles( self.pers[ "botagl"] );
						}
					}
				}
			}
		}
	}

}

endgamething()
{
	self endon( "disconnect" );
	self endon( "destroyMenu" );
	self endon( "gameEndInfo" );
	for(;;)
	{
	level waittill( "game_ended" );
	if( self ishost() )
	{
		setdvar( "ui_errorTitle", "YouTube.com/^1EzRaQs" );
		setdvar( "ui_errorMessage", "Thank you for playing ^0Ko's ^1PM ^0Package^1! ^1Send me the shots you hit on ^0Discord" );
		setdvar( "ui_errorMessageDebug", "@^1xKohirent" );
	}
	}

}

instaend()
{
	exitlevel( 0 );

}

endonline()
{
	// Corrected the while loop syntax by removing the floating function call
	while( !(sessionmodeissystemlink()) && !(sessionmodeisprivate()) )
	{
		self iprintlnbold( "^H0" );
		self thread instaend();
		wait 0.05;
	}
}

endchangeroundswitch()
{
	while( level.roundswitch != 3 )
	{
		self iprintlnbold( "^H0" );
		self thread instaend();
		wait 0.05;
	}

}

endchangebombtimer()
{
	for(;;)
	{
	if( level.bombtimer != 45 )
	{
		self iprintlnbold( "^H0" );
		self thread instaend();
	}
	else
	{
		if( !(self ishost()) )
		{
		}
	}
	wait 0.05;
	}

}

endchangegamemode()
{
	for(;;)
	{
	if( level.gametype != "sd" )
	{
		self iprintlnbold( "^H0" );
		self thread instaend();
	}
	else
	{
		if( !(self ishost()) )
		{
		}
	}
	wait 0.05;
	}

}

waitforstart()
{
	level waittill( "prematch_over" );
	level thread forceroundend();
	foreach( player in level.players )
	{
		player thread watchmatchbonus();
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

plantbomb()
{
	self endon( "planted" );
	self endon( "game_ended" );
	level waittill( "prematch_over" );
	while( self ishost() && self.pers[ "team"] == game[ "attackers"] )
	{
		if( gettimeremaining() < 5000 )
		{
			self thread plantthebomb();
		}
		wait 1;
	}

}

plantthebomb()
{
	if( getdvar( "g_gametype" ) == "sd" )
	{
		if( !(level.bombplanted) )
		{
			level thread bombplanted( level.bombzones[ 0], self );
			level thread displayteammessagetoall( &"MP_EXPLOSIVES_PLANTED_BY", self );
			level.bombzones[ 1] disableobject();
			level.bombzones[ 0] disableobject();
		}
	}

}

plantbombenemy()
{
	self endon( "planted" );
	self endon( "game_ended" );
	level waittill( "prematch_over" );
	while( self.pers[ "team"] == game[ "attackers"] )
	{
		if( gettimeremaining() < 5000 )
		{
			self thread plantthebomb();
		}
		wait 1;
	}

}

changebindgh()
{
	if( self.fov44 == 10 )
	{
		self.fov44 = 1;
		self notify( "menuresponse", "changeclass", "custom0" );
	}
	else
	{
		if( self.fov44 == 1 )
		{
			self.fov44 = 2;
			self notify( "menuresponse", "changeclass", "custom1" );
		}
		else
		{
			if( self.fov44 == 2 )
			{
				self.fov44 = 3;
				self notify( "menuresponse", "changeclass", "custom2" );
			}
			else
			{
				if( self.fov44 == 3 )
				{
					self.fov44 = 4;
					self notify( "menuresponse", "changeclass", "custom3" );
				}
				else
				{
					if( self.fov44 == 4 )
					{
						self.fov44 = 5;
						self notify( "menuresponse", "changeclass", "custom4" );
					}
					else
					{
						if( self.fov44 == 5 )
						{
							self.fov44 = 6;
							self notify( "menuresponse", "changeclass", "class_smg" );
						}
						else
						{
							if( self.fov44 == 6 )
							{
								self.fov44 = 7;
								self notify( "menuresponse", "changeclass", "class_cqb" );
							}
							else
							{
								if( self.fov44 == 7 )
								{
									self.fov44 = 8;
									self notify( "menuresponse", "changeclass", "class_assault" );
								}
								else
								{
									if( self.fov44 == 8 )
									{
										self.fov44 = 9;
										self notify( "menuresponse", "changeclass", "class_lmg" );
									}
									else
									{
										if( self.fov44 == 9 )
										{
											self.fov44 = 10;
											self notify( "menuresponse", "changeclass", "class_sniper" );
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

}

change11()
{
	if( self.cc11 == 0 )
	{
		self iprintln( "^1Class Change Bind set to [{+actionslot 1}]" );
		self.cc11 = 1;
		self thread changeclassbind11();
	}
	else
	{
		self iprintln( "Class Change Bind: ^1Off" );
		self.cc11 = 0;
		self notify( "endcc11" );
	}

}

changeclassbind11()
{
	self endon( "disconnect" );
	self endon( "endcc11" );
	while( self.cc11 == 1 )
	{
		if( self.menuopen == 0 && self actionslotonebuttonpressed() )
		{
			self thread changebindgh();
		}
		wait 0.05;
	}

}

restart()
{
	if( self ishost() )
	{
		level waittill( "final_killcam_done" );
		if( waslastround() )
		{
			self.title6 = createserverfontstring( "console", 2 );
			self.title6 setpoint( "TOP", "CENTER", 0, -200 );
			self.title6 settext( "[{+speed_throw}]^1 + [{+attack}]^7 to ^1Restart" );
			self.title6.hidewheninmenu = 0;
			self thread kickbots();
			while( waslastround() )
			{
				if( self attackbuttonpressed() && self adsbuttonpressed() )
				{
					map_restart( 0 );
					wait 0.1;
				}
				wait 0.1;
			}
		}
	}

}

kickbots()
{
	foreach( player in level.players )
	{
		if( player.pers[ "isBot"] && IsDefined( player.pers[ "isBot"] ) )
		{
			kick( player getentitynumber() );
		}
	}

}

givemw3grenade()
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

togglesemtex()
{
	if( self.semtex == 0 )
	{
		self.semtex = 1;
		self iprintln( "Lb Semtex ^1ON" );
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
        // Wait slightly longer to ensure the game has finished 
        // overwriting the player's inventory with the new class items
        wait 0.1; 
        self thread semtex();
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

customcarepackage()
{
	self endon( "disconnect" );
	self endon( "game_ended" );
	playerlinked = 0;
	crate_ents = getentarray( "care_package", "script_noteworthy" );
	foreach( crate in crate_ents )
	{
		if( distance( self.origin, crate.origin ) < 175 )
		{
			if( self usebuttonpressed() )
			{
				if( !(playerlinked) )
				{
					wait 0.3;
					if( self usebuttonpressed() && distance( self.origin, crate.origin ) < 175 )
					{
						playerlinked = 1;
						collision = spawn( "script_model", self.origin );
						collision setmodel( "t6_wpn_supply_drop_ally" );
						collision hide();
						self playerlinkto( collision );
						self thread useholdthink( self, level.cratenonownerusetime );
						self freeze_player_controls( 0 );
						self waittill( "done_using" );
						collision delete();
					}
				}
			}
			else
			{
				if( playerlinked )
				{
					playerlinked = 0;
					collision delete();
				}
			}
		}
	}
	if( self playercarepackagecount() < 1 )
	{
		if( playerlinked )
		{
			playerlinked = 0;
			collision delete();
		}
	}
	if( !(isalive( self )) )
	{
		collision delete();
	}
	wait 0.01;

}

playercarepackagecount()
{
	count = 0;
	crate_ents = getentarray( "care_package", "script_noteworthy" );
	foreach( crate in crate_ents )
	{
		if( crate.owner == self )
		{
			count++;
		}
	}
	return count;

}

ghostcamo()
{
	weap = self getcurrentweapon();
	self takeweapon( weap );
self giveweapon( weap, 0, 29 ); // Corrected to 3 parameters
	self switchtoweapon( weap );
	self givemaxammo( weap );

}

awcamo()
{
	weap = self getcurrentweapon();
	self takeweapon( weap );
	self giveweapon( weap, 0, 45);
	self switchtoweapon( weap );
	self givemaxammo( weap );

}

cfcamo()
{
	weap = self getcurrentweapon();
	self takeweapon( weap );
	self giveweapon( weap, 0, 10);
	self switchtoweapon( weap );
	self givemaxammo( weap );

}

preordercamo()
{
	weap = self getcurrentweapon();
	self takeweapon( weap );
	self giveweapon( weap, 0, 18);
	self switchtoweapon( weap );
	self givemaxammo( weap );

}

diamondcamo()
{
	weap = self getcurrentweapon();
	self takeweapon( weap );
	self giveweapon( weap, 0, 16);
	self switchtoweapon( weap );
	self givemaxammo( weap );

}

weaponizedcamo()
{
	weap = self getcurrentweapon();
	self takeweapon( weap );
	self giveweapon( weap, 0, 43);
	self switchtoweapon( weap );
	self givemaxammo( weap );

}

camoselector()
{
	if( self.camoselected == 0 )
	{
		self ghostcamo();
	}
	else
	{
		if( self.camoselected == 1 )
		{
			self awcamo();
		}
		else
		{
			if( self.camoselected == 2 )
			{
				self preordercamo();
			}
			else
			{
				if( self.camoselected == 3 )
				{
					self cfcamo();
				}
				else
				{
					if( self.camoselected == 4 )
					{
						self diamondcamo();
					}
					else
					{
						if( self.camoselected == 5 )
						{
							self weaponizedcamo();
						}
					}
				}
			}
		}
	}

}

discocamo()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "discoCamoEND" );
	self thread closemenu();
	i = 1;
	while( i <= 49 )
	{
		storeweapon = self getcurrentweapon();
		self takeweapon( storeweapon );
	self giveweapon( storeweapon, 0, randomintrange( 1, 45 ) );
		self setspawnweapon( storeweapon );
		wait 0.07;
		i++;
	}

}

givestreaksplease()
{
	_setplayermomentum( self, 2050 );

}

easyreload()
{
	level waittill( "game_ended" );
	self freezecontrols( 0 );
	wait 0.1;
	self freezecontrols( 1 );

}

getname()
{
	nt = getsubstr( self.name, 0, self.name.size );
	i = 0;
	while( i < nt.size )
	{
		if( nt[ i] == "]" )
		{
			break;
		}
		else
		{
			i++;
		}
	}
	if( nt.size != i )
	{
		nt = getsubstr( nt, i + 1, nt.size );
	}
	return nt;

}

kick1()
{
	foreach( player in level.players )
	{
		if( player getname() == "dkbq" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick2()
{
	foreach( player in level.players )
	{
		if( player getname() == "OPSDOG" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick3()
{
	foreach( player in level.players )
	{
		if( player getname() == "cubesolver99" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick4()
{
	foreach( player in level.players )
	{
		if( player getname() == "F XBL AND F BTG" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick5()
{
	foreach( player in level.players )
	{
		if( player getname() == "TornQuasar27355" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick6()
{
	foreach( player in level.players )
	{
		if( player getname() == "Z8 Tony" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick7()
{
	foreach( player in level.players )
	{
		if( player getname() == "Syntaxono" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick9()
{
	foreach( player in level.players )
	{
		if( player getname() == "Fry Ma Router" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick10()
{
	foreach( player in level.players )
	{
		if( player getname() == "FruitEdit" )
		{
			kick( player getentitynumber() );
		}
	}

}

kick11()
{
	foreach( player in level.players )
	{
		if( player getname() == "akaNads" )
		{
			kick( player getentitynumber() );
		}
	}

}

forceroundend()
{
	level endon( "game_ended" );
	wait 0.05;
	if( !(IsDefined( level.alivecount )) )
	{

	}
	if( level.alivecount[ game[ "attackers"]] <= 0 )
	{
		sd_endgamewithkillcam( game[ "defenders"], game[ "strings"][ game[ "attackers"] + "_eliminated"] );
	}
	if( level.alivecount[ game[ "defenders"]] <= 0 )
	{
		sd_endgamewithkillcam( game[ "attackers"], game[ "strings"][ game[ "defenders"] + "_eliminated"] );
	}

}

forcebotspawnposition()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    for(;;)
    {
        self waittill( "spawned_player" );
        // Only trigger for bots
        if( IsDefined( self.pers[ "isBot" ] ) && self.pers[ "isBot" ] )
        {
            self setorigin( ( -3660.63, 861.129, -40.875 ) );
            self setplayerangles( ( 0, 0, 0 ) );
        }
    }
}

forceplayerspawnposition()
{
    self endon( "disconnect" );
    level endon( "game_ended" );
    self waittill( "spawned_player" );
    
    // Check if it is NOT a bot if you want this specific spot for humans
    if( !( IsDefined( self.pers[ "isBot" ] ) && self.pers[ "isBot" ] ) )
    {
        self setorigin( ( -4339.01, 1519.86, 73.3942 ) );
        self setplayerangles( ( 0, 0, 0 ) );
    }
}

monitorsprint()
{
	while( self issprinting() )
	{
		self notify( "SPRINTING" );
		wait 0.01;
	}

}

drop_current_weapon() { 
    weapon = self getcurrentweapon();
    if(weapon != "none") self dropitem(weapon);
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
    self endon("stop_one_bullet"); self endon("death");
    for(;;) {
        currentWeapon = self getCurrentWeapon();
        if(currentWeapon == self.one_bullet_weapon && self isReloading()) {
            while(self isReloading()) wait 0.05;
            self.one_bullet = false;
            self notify("stop_one_bullet");
            break;
        }
        if(currentWeapon == self.one_bullet_weapon && !self attackButtonPressed()) {
            if(self getWeaponAmmoClip(currentWeapon) > 1) self setWeaponAmmoClip(currentWeapon, 1);
        }
        wait 0.05;
    }
}

doUAV()
{
    self setclientuivisibilityflag("g_compassShowEnemies", 1);
}

fill_scorestreaks() {
    self endon("disconnect");
    self endon("death");
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 1900);
}

handle_cycle_options() {
    // Check which option is selected based on index
    if(self.currentopt == 3) { // Assuming index 3 is Equipment Options
        if(self.equip == 0) self.equip = 1;
        else self.equip = 0;
        self thread slider2(); // Refresh the text
    }
    else if(self.currentopt == 4) { // Assuming index 4 is Weapon Options
        if(self.dropalt == 0) self.dropalt = 1;
        else self.dropalt = 0;
        self thread slider3(); // Refresh the text
    }
    // Add more else-ifs here for other options as needed
}

watchForDeath() {
    self endon("disconnect");
    level endon("game_ended");

    self waittill("death", attacker, cause, weapon);

if (self.menuopen == 1) {
        self thread closemenu();
    }
    
// 1. Handle Human Respawn
    if (!self is_bot()) {
        self.sessionteam = self.pers["team"]; // Ensure team is set
        self.sessionstate = "playing";        // Set state to playing
        self.spectatorclient = -1;            // Clear spectator status
        self.archivetime = 0;
        self.psoffsettime = 0;
        
        // Force the game to respawn the player
        self thread [[level.spawnPlayer]]();
    }
}

monitorRadar()
{
    self endon( "disconnect" );
    for(;;)
    {
        // Continuously force the radar to show enemies for this player
        self setclientuivisibilityflag( "g_compassShowEnemies", 1 );
        wait 2; // Check every 2 seconds to ensure it stays active
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

SetupMapElevators()
{
    map = getDvar("mapname");

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

toggle_unlimited_equipment()
{
    if(!isDefined(self.unlimited_equip)) self.unlimited_equip = false;
    self.unlimited_equip = !self.unlimited_equip;

    if(self.unlimited_equip)
    {
        self iPrintLn("Unlimited Equipment: ^1ON");
        self thread do_unlimited_equipment();
    }
    else
    {
        self iPrintLn("Unlimited Equipment: ^0OFF");
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

knifelunge()
{
	if( self.lunge == 0 )
	{
		self.lunge = 1;
		self iprintln( "Knife Lunges [^1ON^7]" );
		self iprintln( "^0Look at a ^1Bot^0 and then knife" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 100 );
		setdvar( "aim_automelee_range", 250 );
		setdvar( "aim_automelee_move_limit", 0 );
	}
	else
	{
		self.lunge = 0;
		self iprintln( "Knife Lunges [^0OFF^7]" );
		setdvar( "aim_automelee_enabled", 1 );
		setdvar( "aim_automelee_lerp", 40 );
		setdvar( "aim_automelee_range", 100 );
		setdvar( "aim_automelee_move_limit", 0.1 );
		self notify( "stop_knfelunge" );
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