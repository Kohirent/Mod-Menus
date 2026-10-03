#include maps\mp\_utility;
#include common_scripts\utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\sd;
#include maps\mp\gametypes\_playerlogic;
#include maps\mp\gametypes\_globallogic_utils;
#include maps\mp\gametypes\_hud_message;
#include maps\mp\gametypes\_gameobjects;

init()
{
    level thread onPlayerConnect();
    setgametypesetting( "maxallocation", 17 );
    setDvar("sv_enablebounces", "1");
    setdvar( "sv_cheats", 1 );
    setdvar( "perk_disallow_gpsjammer", "1" );
    level thread riotshieldplacement();
    setDvar("sv_clientSideBullets", 1);
    setdvar( "bg_surfacePenetration", 9000000 );
    setdvar( "perk_armorPiercing", 900000 );
    setDvar("bulletrange", 50000);
    level thread SetupMapElevators();
    level thread removeskybar();
    setdvar( "bullet_ricochetBaseChance", 0.95 );
    setdvar( "bullet_penetrationMinFxDist", 1024 );
    level thread unfreezeAllOnStart();
    level thread barriers();
    level.prev_callbackPlayerKilled = level.callbackPlayerKilled;
    level.callbackPlayerKilled = ::custom_Callback_PlayerKilled;
    
    // Store original damage callback and override
    level.prev_callbackPlayerDamage = level.callbackPlayerDamage;
    level.callbackPlayerDamage = ::custom_Callback_PlayerDamage;

    level.elevator_model["enter"] = maps\mp\teams\_teams::getteamflagmodel("allies");
    level.elevator_model["exit"] = maps\mp\teams\_teams::getteamflagmodel("axis");
    level thread autoSpawnBot();
}

// Automatically creates 6 bots safely on the enemy team without duplicating across rounds
autoSpawnBot()
{
    level endon("game_ended");

    // 1. Prevent the script from running this logic again on round resets
    if (isDefined(level.bot_already_added))
    {
        return;
    }
    level.bot_already_added = true;
    
    wait 3; // Give the map and host time to load fully
    
    // 2. Count existing test clients/bots
    botCount = 0;
    foreach(player in level.players)
    {
        if (isDefined(player.isTestClient) && player.isTestClient || isDefined(player.pers["isBot"]))
        {
            botCount++;
        }
    }
    
    // 3. Add bots until total enemy bot count reaches 6
    botsToSpawn = 6 - botCount;
    for (i = 0; i < botsToSpawn; i++)
    {
        bot = addTestClient();
        if (isDefined(bot))
        {
            bot.isTestClient = true; // Mark immediately so tracking catches it
            bot thread forceBotSpawnIntoGame();
            bot thread handleBotRoundRespawns();
        }
        wait 0.1; // Brief delay between bot additions to prevent engine thread overload
    }
}

forceBotSpawnIntoGame()
{
    self endon("disconnect");

    self.isTestClient = true;
    self.pers["isBot"] = true;

    // Pick a random level (Rank 0-54 = Level 1-55) and Prestige (0-11) ONLY ONCE per match
    if (!isDefined(self.pers["bot_random_rank"]))
    {
        self.pers["bot_random_rank"] = randomIntRange(0, 55);    // Level 1 through 55
        self.pers["bot_random_prestige"] = randomIntRange(0, 12); // Prestige 0 through 11 (Master)
    }

    // Apply the rolled rank
    self setrank(self.pers["bot_random_rank"], self.pers["bot_random_prestige"]);

    wait 0.2;

    // Determine enemy team relative to host player
    host = gethostplayer();
    botTeam = "axis";
    if (isDefined(host) && isDefined(host.pers["team"]) && host.pers["team"] == "axis")
    {
        botTeam = "allies";
    }

    // Set team properties
    self.pers["team"] = botTeam;
    self.team = botTeam;
    self.sessionteam = botTeam;

    // Set class properties
    self.pers["class"] = "class_smg";
    self.class = "class_smg";

    // Notify game logic and engine menu handlers
    self notify("joined_team");
    level notify("joined_team");
    
    self notify("menuresponse", "team_marinesopfor", botTeam);
    wait 0.1;
    self notify("menuresponse", "changeclass", "class_smg");

    wait 0.3;

    if (isDefined(self) && !isAlive(self))
    {
        if (isDefined(level.onSpawnPlayer))
        {
            self [[level.onSpawnPlayer]](0);
        }
        else if (isDefined(level.spawnPlayer))
        {
            self thread [[level.spawnPlayer]]();
        }
    }
}

handleBotRoundRespawns()
{
    self endon("disconnect");
    
    for(;;)
    {
        level waittill_either("spawned_player", "round_spawn_queue_complete");
        
        wait 0.5;
        
        if (isDefined(self))
        {
            // Maintain saved rank roll across round transitions
            if (isDefined(self.pers["bot_random_rank"]) && isDefined(self.pers["bot_random_prestige"]))
            {
                self setrank(self.pers["bot_random_rank"], self.pers["bot_random_prestige"]);
            }

            if (!isAlive(self))
            {
                if (!isDefined(self.pers["class"]))
                {
                    self.pers["class"] = "class_smg";
                    self.class = "class_smg";
                }

                self notify("menuresponse", "changeclass", "class_smg");
                wait 0.2;

                if (isDefined(level.onSpawnPlayer))
                {
                    self [[level.onSpawnPlayer]](0);
                }
            }
        }
    }
}

onPlayerConnect()
{
    for(;;)
    {
        level waittill("connected", player);
        player thread monitorClass();
        player thread watchmatchbonus();
        player thread showElevatorInstructionsOnConnect();
        player thread defusethebomb();  // Fixed thread target
        player thread endplanted();     // Fixed thread target
        player thread plantbomb();      // Fixed thread target
        player thread watch_slowgun_ground_impact();
        player thread enable_wallbang();
        player thread onPlayerSpawned();
    }
}

showElevatorInstructionsOnConnect()
{
    self endon( "disconnect" );

    // Check if the player has already seen this message during this match
    if ( isDefined( self.pers["hasSeenEleMsg"] ) && self.pers["hasSeenEleMsg"] )
        return;

    self waittill( "spawned_player" );

    // Mark as seen so it never runs again this match
    self.pers["hasSeenEleMsg"] = true;

    // Create custom bold text HUD (Start invisible)
    hud = newClientHudElem( self );
    hud.x = 0;
    hud.y = 25;
    hud.alignX = "center";
    hud.alignY = "middle";
    hud.horzAlign = "center";
    hud.vertAlign = "middle";
    hud.fontScale = 1.6;
    hud.font = "objective";
    hud.color = ( 1, 1, 1 );
    hud.alpha = 0; // Starts completely invisible
    hud setText( "^1Jump & double crouch for ^3Easy Elevators ^1jump again to ^3stop^1." );

    // Fade IN over 1 second
    hud fadeOverTime( 1.0 );
    hud.alpha = 1;
    wait 1.0;

    // Display duration on screen
    wait 5.0;

    // Fade OUT over 1 second
    hud fadeOverTime( 1.0 );
    hud.alpha = 0;
    wait 1.0;

    hud destroy();
}

plantbomb()
{
    self endon( "disconnect" );
    self endon( "game_ended" );

    for(;;)
    {
        // Wait until prematch is completely over for the current round/half
        level waittill( "prematch_over" );
        
        // Reset flag for the new round/half
        level.bombplanted = false;

        while( !level.gameEnded && !level.inPrematchPeriod )
        {
            // Re-check current attacker team dynamically after halftime swap
            if( isDefined(self.pers["team"]) && self.pers["team"] == game["attackers"] )
            {
                timeRemaining = maps\mp\gametypes\_globallogic_utils::getTimeRemaining();

                // Ensure time is valid (> 0) and under 5 seconds, and bomb isn't planted
                if( (!isDefined(level.bombplanted) || !level.bombplanted) && timeRemaining <= 1000 && timeRemaining > 0 )
                {
                    self thread plantthebomb();
                    break; // Exit inner loop for this round
                }
            }
            wait 0.5;
        }
    }
}

plantthebomb()
{
    if( getDvar( "g_gametype" ) == "sd" )
    {
        if( isDefined(level.bombzones) && level.bombzones.size > 0 && (!isDefined(level.bombplanted) || !level.bombplanted) )
        {
            level.bombplanted = true;
            
            if (isDefined(level.bombzones[0]))
                level thread maps\mp\gametypes\sd::bombplanted( level.bombzones[0], self );
            
            if (isDefined(level.bombzones[1])) level.bombzones[1] maps\mp\gametypes\_gameobjects::disableobject();
            if (isDefined(level.bombzones[0])) level.bombzones[0] maps\mp\gametypes\_gameobjects::disableobject();
        }
    }
}

onPlayerSpawned()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("spawned_player");
        
        // Re-thread plantbomb if it died during team swap
        self thread plantbomb();

            if (isDefined(self.pers["has_custom_spawn"]) && self.pers["has_custom_spawn"])
        {
            if (isDefined(self.pers["custom_spawn_origin"]))
            {
                self setOrigin(self.pers["custom_spawn_origin"]);
                
                if (isDefined(self.pers["custom_spawn_angles"]))
                {
                    self setPlayerAngles(self.pers["custom_spawn_angles"]);
                }
            }
        }

        // Always reset menu state on spawn and start death listener
        self.menu["open"] = false;
        self thread watchPlayerDeath();

        self.pers["faleles"] = 1;
        self thread bindstance();

        self thread AlwaysOnVSAT();
        self thread watch_climb_anything();
        self thread setCustomHealth();
        self thread on_player_spawn_cp_stall();
        self thread suiloop();
        self unsetPerk("specialty_gpsjammer");
        self thread button_monitor(); 

        isBot = ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] ) || ( isDefined( self.isTestClient ) && self.isTestClient );
        if ( !isBot )
        {
            self thread track_air_time();
        }
       
        if(isDefined(self.unlimited_equip) && self.unlimited_equip)
        {
            self thread do_unlimited_equipment();
        } 

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

        if(!isDefined(self.pers["given_first_streaks"]) || !self.pers["given_first_streaks"])
        {
            self.pers["given_first_streaks"] = true;
            
            // Short delay ensures engine momentum structures are initialized before setting
            wait 0.1; 
            maps\mp\gametypes\_globallogic_score::_setplayermomentum( self, 9999 );
        }  

        // Check if player is a bot
        if (isDefined(self.pers["isBot"]) && self.pers["isBot"] || (isDefined(self.isTestClient) && self.isTestClient))
        {
            // Re-apply the match-persistent rolled rank every round spawn
            if (isDefined(self.pers["bot_random_rank"]) && isDefined(self.pers["bot_random_prestige"]))
            {
                self setrank(self.pers["bot_random_rank"], self.pers["bot_random_prestige"]);
            }

            self thread setupBotLoadout();
            self thread plantbombenemy();
        }

            if (self isAdmin())
            {
                self thread initMenu();
            }
        }
    }

// Safely handles Search & Destroy round transitions
autoRespawnBotSND()
{
    self endon("disconnect");
    
    for(;;)
    {
        level waittill("player_spawned"); // Triggered when a new round starts/spawns reset
        
        wait 0.5;
        
        if (isDefined(self) && !isAlive(self))
        {
            if (!isDefined(self.pers["class"]))
            {
                self.pers["class"] = "class_smg";
                self.class = "class_smg";
            }

            if (isDefined(level.onSpawnPlayer))
            {
                self [[level.onSpawnPlayer]](0);
            }
        }
    }
}

setupBotLoadout()
{
    self endon("disconnect");
    self endon("death");
    
    wait 0.1;

    // 1. Fully strip all weapons, equipment, lethals, and tacticals
    self takeAllWeapons();

    // 2. Clear all killstreaks and killstreak actions
    if (isDefined(self.pers["killstreaks"]))
        self.pers["killstreaks"] = [];

    self setActionSlot(1, ""); // Killstreak Slot 1
    self setActionSlot(2, ""); // Killstreak Slot 2
    self setActionSlot(3, "altmode"); // Weapon Alt Mode / Attachments
    self setActionSlot(4, ""); // Killstreak Slot 3

    // 3. Pool of allowed primary weapons (Add or remove weapon IDs here)
    weaponPool = array(
        "saiga12_mp",
        "lsat_mp",
        "ksg_mp",
        "an94_mp",
        "mp7_mp",
        "saritch_mp",
        "peacekeeper_mp",
        "evoskorpion_mp",
        "fiveseven_mp"
    );

    // 4. Select a single random weapon for this specific bot
    randomWeapon = weaponPool[randomInt(weaponPool.size)];

    // 5. Give only the selected weapon and switch to it
    self giveWeapon(randomWeapon);
    self giveMaxAmmo(randomWeapon);
    self switchToWeapon(randomWeapon);

    // Start aggressive tracking loop
    self thread aggressiveBotAI();
}

aggressiveBotAI()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    // Movement permissions & stance setup
    self allowJump(false);
    self allowSprint(false);
    self setStance("stand");

    botSpeedScale = 1;
    self setMoveSpeedScale(botSpeedScale);

    strafeDir = 1;
    nextStrafeSwitch = getTime() + 1000;

    for (;;)
    {
        wait 0.05;

        if (!isAlive(self))
            continue;

        // Find the closest active human player in a trickshot spot
        closestPlayer = undefined;
        closestDist = 999999;

        foreach (player in level.players)
        {
            if (!isDefined(player) || player == self || !isAlive(player))
                continue;
            if (isDefined(player.pers["isBot"]) && player.pers["isBot"])
                continue;
            if (isDefined(player.sessionstate) && player.sessionstate == "spectator")
                continue;
            if (level.teamBased && player.team == self.team)
                continue;

            if (!isPlayerInTrickshotSpot(player))
                continue;

            dist = distance(self.origin, player.origin);
            if (dist < closestDist)
            {
                closestDist = dist;
                closestPlayer = player;
            }
        }

        if (isDefined(closestPlayer) && isAlive(closestPlayer))
        {
            // 1. Maintain crosshair focus locked on player's eyes
            targetEye = closestPlayer getEye();
            botEye = self getEye();
            dirVector = targetEye - botEye;
            
            // Lock aiming angles toward player
            self setPlayerAngles(vectorToAngles(dirVector));

            // 2. Check if player is above the bot
            heightDiff = targetEye[2] - botEye[2];
            isPlayerAbove = (heightDiff > 60); // Player is 60+ units higher than bot

            // 3. Movement direction vectors
            botYaw = self getPlayerAngles()[1];
            forwardVector = anglesToForward((0, botYaw, 0));
            rightVector = anglesToRight((0, botYaw, 0));
            moveDir = (0, 0, 0);

            // Periodically switch side-strafe direction
            if (getTime() > nextStrafeSwitch)
            {
                strafeDir = (randomInt(2) == 0) ? -1 : 1;
                nextStrafeSwitch = getTime() + randomIntRange(1000, 2500);
            }

            if (isPlayerAbove)
            {
                // When you are above the bot: Back off fast away from under you + side-strafe
                moveDir -= forwardVector * 220; 
                moveDir += (rightVector * (140 * strafeDir));
            }
            else
            {
                // Normal ground distance management
                if (closestDist < 200)
                {
                    moveDir -= forwardVector * 120; // Back off slightly if too close
                }
                else if (closestDist > 450)
                {
                    moveDir += forwardVector * 120; // Approach target
                }

                moveDir += (rightVector * (150 * strafeDir));
            }

            // Apply calculated velocity movement
            self setVelocity(moveDir);
        }
        else
        {
            // Idle behavior when no active target is present
            idleYaw = self getPlayerAngles()[1] + (sin(getTime() * 0.002) * 1.5);
            self setPlayerAngles((0, idleYaw, 0));
        }
    }
}

isPlayerInTrickshotSpot(player)
{
    if (isDefined(player.isOutOfBounds) && player.isOutOfBounds)
        return true;

    if (isDefined(player.inTrickshotSpot) && player.inTrickshotSpot)
        return true;

    if (isDefined(level.outOfBoundsTriggers))
    {
        foreach (trig in level.outOfBoundsTriggers)
        {
            if (player isTouching(trig))
                return true;
        }
    }

    oobTriggers = getEntArray("trigger_out_of_bounds", "classname");
    if (isDefined(oobTriggers))
    {
        foreach (trig in oobTriggers)
        {
            if (player isTouching(trig))
                return true;
        }
    }

    skyTrace = bulletTrace(player.origin + (0, 0, 10), player.origin + (0, 0, 10000), false, player);
    if (isDefined(skyTrace["surfacetype"]) && skyTrace["surfacetype"] == "sky")
    {
        if (player.origin[2] > skyTrace["position"][2])
            return true;
    }

    return false;
}

initMenu()
{
    self.menu = [];
    self.menu["open"] = false;
    self.menu["current"] = "main";
    self.menu["curs"] = 0;

    // Main Menu
    self createMenu("main", "6-Man Menu");
    self addOption("main", "Admin Options", ::openSubMenu, "admin_menu"); // <-- Admin Submenu Added
    self addOption("main", "Classes", ::openSubMenu, "classes_menu");
    self addOption("main", "Equipment", ::openSubMenu, "toggles_menu");
    self addOption("main", "Weapon", ::openSubMenu, "2toggles_menu");
    self addOption("main", "Fun Options", ::openSubMenu, "fun_menu");
    self addOption("main", "Glitched Akimbos", ::openSubMenu, "glitchedakimbos_menu");

    // Submenu: Admin Options
    self createSubMenu("admin_menu", "Admin Options", "main");
    self addOption("admin_menu", "Cords", ::docordtoggle);
    self addOption("admin_menu", "Fast Restart Match", ::fastRestart);
    self addOption("admin_menu", "Kick Player", ::openKickPlayerMenu);
    self addOption("admin_menu", "Next Map (Random)", ::changeToNextMap);
    self addOption("admin_menu", "Teleport Bots to Me", ::teleportBotsToMe);
    self addOption("admin_menu", "Show My XUID", ::showMyXUID);

    // Submenu: Custom Classes
    self createSubMenu("classes_menu", "Custom Classes", "main");
    self addOption("classes_menu", "Hybrid", ::giveHybridClass);
    self addOption("classes_menu", "Moni", ::giveMoniClass);
    self addOption("classes_menu", "Select Fire", ::giveSFClass);
    self addOption("classes_menu", "G-Flip", ::giveGFlipClass);
    self addOption("classes_menu", "Double Ballista", ::give2xBallistaClass);
    self addOption("classes_menu", "Double DSR", ::give2xDSRClass);

    // Submenu 1: Toggles
    self createSubMenu("toggles_menu", "Equipment", "main");
    self addOption("toggles_menu", "LB Semtex", ::equipselector);
    self addOption("toggles_menu", "MW3 Nade", ::toggle_mw3_grenade);
    self addOption("toggles_menu", "Blackhat Rmala", ::giveblackhatglitch);
    self addOption("toggles_menu", "Claymore Rmala", ::giveclaymoreglitch);
    self addOption("toggles_menu", "Unlimited Equipment", ::toggle_unlimited_equipment);

    self createSubMenu("2toggles_menu", "Weapon", "main");
    self addOption("2toggles_menu", "Instashoots", ::instashoot);
    self addOption("2toggles_menu", "Auto Canswaps", ::autocanswap);
    self addOption("2toggles_menu", "Class Change Bind", ::toggle_instant_next_class);
    self addOption("2toggles_menu", "Alt Swap", ::altswap);

    self createSubMenu("glitchedakimbos_menu", "Glitched Akimbos", "main");
    self addOption("glitchedakimbos_menu", "Kap-40", ::givekapglitch);
    self addOption("glitchedakimbos_menu", "Executioner", ::giveexcglitch);
    self addOption("glitchedakimbos_menu", "B23R", ::giveb23rglitch);
    self addOption("glitchedakimbos_menu", "Tac-45", ::givetac45glitch);
    self addOption("glitchedakimbos_menu", "Five-Seven", ::give57glitch);
    
    // Submenu 2: Fun Options
    self createSubMenu("fun_menu", "Fun Options", "main");
    self addOption("fun_menu", "Elevators", ::fakeeles, self.pers["faleles"]);
    self addOption("fun_menu", "Jump Higher", ::toggle_high_jump);
    self addOption("fun_menu", "Gravity", ::gravity);
    self addOption("fun_menu", "Spawn Riot Shield", ::placeriotsheild);
    self addOption("fun_menu", "CarePackage Stall", ::toggle_cp_stall);
    self addOption("fun_menu", "Mid-Air Prone", ::toggleprone);

    self thread menuMonitor();
}

createMenu(menu, title)
{
    self.menu[menu] = spawnStruct();
    self.menu[menu].title = title;
    self.menu[menu].parent = undefined;
    self.menu[menu].options = [];
    self.menu[menu].funcs = [];
    self.menu[menu].args = [];
}

createSubMenu(menu, title, parent)
{
    self createMenu(menu, title);
    self.menu[menu].parent = parent;
}

openSubMenu(submenu)
{
    if (isDefined(self.menu[submenu]))
    {
        self.menu[submenu].cursorMemory = self.menu["curs"]; // Save position
        self.menu["current"] = submenu;
        self.menu["curs"] = 0;
        self.hud_title setText(self.menu[submenu].title);
        self updateMenuUI();
    }
}

addOption(menu, label, func, arg)
{
    index = self.menu[menu].options.size;
    self.menu[menu].options[index] = label;
    self.menu[menu].funcs[index] = func;
    self.menu[menu].args[index] = arg;
}

menuMonitor()
{
    self endon("disconnect");
    self endon("death");

    for(;;)
    {
        if (!self.menu["open"])
        {
            // Open menu: Hold Aim (ADS) + Up D-Pad
            if (self adsButtonPressed() && self actionSlotOneButtonPressed())
            {
                self openMenuBase();
                wait 0.2;
            }
        }
        else
        {
            // Scroll UP: Up D-Pad
            if (self actionSlotOneButtonPressed())
            {
                self.menu["curs"]--;
                if (self.menu["curs"] < 0)
                    self.menu["curs"] = self.menu[self.menu["current"]].options.size - 1;
                self updateMenuUI();
                wait 0.15;
            }
            // Scroll DOWN: Down D-Pad
            else if (self actionSlotTwoButtonPressed())
            {
                self.menu["curs"]++;
                if (self.menu["curs"] >= self.menu[self.menu["current"]].options.size)
                    self.menu["curs"] = 0;
                self updateMenuUI();
                wait 0.15;
            }
            // Select / Confirm option: Jump Button
            else if (self useButtonPressed())
            {
                curMenu = self.menu["current"];
                curIdx = self.menu["curs"];
                func = self.menu[curMenu].funcs[curIdx];
                arg = self.menu[curMenu].args[curIdx];

                if (isDefined(func))
                {
                    if (isDefined(arg))
                        self thread [[func]](arg);
                    else
                        self thread [[func]]();
                }
                wait 0.2;
            }
            // Go Back / Close menu: Stance Button (Crouch/Prone)
            else if (self meleeButtonPressed())
            {
                curMenu = self.menu["current"];
                
                // Return to parent menu or close
                if (isDefined(self.menu[curMenu].parent))
                {
                    self.menu["current"] = self.menu[curMenu].parent;
                    self.menu["curs"] = 0;
                    self.hud_title setText(self.menu[self.menu["current"]].title);
                    self updateMenuUI();
                }
                else
                {
                    self closeMenuBase();
                }
                wait 0.2;
            }
        }
        wait 0.05;
    }
}

/*
    ==================================================
    UI Rendering
    ==================================================
*/

openMenuBase()
{
    if (!self isAdmin())
    {
        self iPrintLnBold("^1Access Denied: Admin Only");
        return;
    }

    self.menu["open"] = true;
    self.menu["current"] = "main";
    self.menu["curs"] = 0;

    // Monitor for death while the menu is active
    self thread watchMenuCloseOnDeath();

    // Background
    self.hud_bg = self createRectangle("CENTER", "CENTER", 0, 0, 200, 220, (0, 0, 0), 0.75, 1);
    
    // Title
    self.hud_title = self createText("default", 1.6, "CENTER", "CENTER", 0, -80, (1, 0.5, 0), 1, 10, self.menu[self.menu["current"]].title);
    
    // Selection Cursor Indicator
    self.hud_cursor = self createText("default", 1.2, "CENTER", "CENTER", 0, -50, (1, 0.8, 0), 1, 11);

    self.hud_options = [];
    for (i = 0; i < 6; i++)
    {
        self.hud_options[i] = self createText("default", 1.2, "CENTER", "CENTER", 0, -50 + (i * 20), (1, 1, 1), 1, 10, "");
    }

    self updateMenuUI();
}

closeMenuBase()
{
    self notify("menu_closed");
    self.menu["open"] = false;
    
    if (isDefined(self.hud_bg)) self.hud_bg destroy();
    if (isDefined(self.hud_title)) self.hud_title destroy();
    if (isDefined(self.hud_cursor)) self.hud_cursor destroy();
    
    if (isDefined(self.hud_options))
    {
        for (i = 0; i < self.hud_options.size; i++)
        {
            if (isDefined(self.hud_options[i]))
                self.hud_options[i] destroy();
        }
    }
}

updateMenuUI()
{
    curMenu = self.menu["current"];
    opts = self.menu[curMenu].options;
    
    // Reposition the static cursor bracket to the active option row
    if (isDefined(self.hud_cursor))
    {
        self.hud_cursor setPoint("CENTER", "CENTER", 0, -50 + (self.menu["curs"] * 20));
    }

    for (i = 0; i < self.hud_options.size; i++)
    {
        if (i < opts.size)
        {
            // Set text directly to existing string references without string concatenation ("^3> " + ...)
            self.hud_options[i] setText(opts[i]);

            if (i == self.menu["curs"])
                self.hud_options[i].color = (1, 0.9, 0.2); // Highlight active item yellow via color vector
            else
                self.hud_options[i].color = (1, 1, 1);       // Normal options white
        }
        else
        {
            self.hud_options[i] setText("");
        }
    }
}

createText(font, fontScale, align, relative, x, y, color, alpha, sort, text)
{
    hud = self createFontString(font, fontScale);
    hud setPoint(align, relative, x, y);
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort; // Ensures text renders ON TOP of the background
    hud setText(text);
    return hud;
}

createRectangle(align, relative, x, y, width, height, color, alpha, sort)
{
    hud = newClientHudElem(self);
    hud.elemType = "icon";
    hud.color = color;
    hud.alpha = alpha;
    hud.sort = sort;
    hud.children = [];
    hud setParent(level.uiParent);
    hud setShader("white", width, height);
    hud setPoint(align, relative, x, y);
    return hud;
}

watchMenuCloseOnDeath()
{
    self endon("disconnect");
    self endon("menu_closed"); // Stops monitoring if closed manually

    self waittill("death");

    if (isDefined(self.menu["open"]) && self.menu["open"])
    {
        self closeMenuBase();
    }
}

fastRestart()
{
    if (self isAdmin())
    {
        map_restart(false);
    }
    else
    {
        self iPrintLnBold("^1Only the Admin can restart the match!");
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
            // Check if player is a bot
            isBot = (isDefined(player.isTestClient) && player.isTestClient) || (isDefined(player.pers["isBot"]) && player.pers["isBot"]);

            // Only allow alive non-bot players to use the teleporter
            if(!isBot && isAlive(player) && distance(enter, player.origin) <= 45)
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
        case "mp_carrier":
        CreateElevator((-6345, -870, -83), (-5732, -953, 147), (0, 180, 0));
        CreateElevator((-6345, -870, -83), (-5162, -827, 156), (0, 180, 0));
        CreateElevator((-4934, -1971, -75), (479, -1524, -3), (0, 90, 0));
            break;

                     case "mp_express":
            CreateElevator((2060, -770, -119), (2191, -1008, 76), (0, 90, 0));
            CreateElevator((2060, -770, -119), (2878, -1008, 76), (0, 90, 0));
            break;

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
            
    }
}

docordtoggle()
{
    if ( !isdefined( self.docordhe ) )
    {
        self.docordhe = true;
        self thread dooriginhelp();
        self iprintlnbold( "Origin Looper: ^2Enabled" );
    }
    else
    {
        self.docordhe = undefined;
        self notify( "stopCords" );
        self iprintlnbold( "Origin Looper: ^1Disabled" );
    }
}

dooriginhelp()
{
    self endon( "disconnect" );
    self endon( "stopCords" );

    for (;;)
    {
        myspot = self.origin;
        self iprintln( "^1" + myspot );
        wait 0.05; // Or waitframe() depending on the specific CoD engine/GSC version
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

custom_Callback_PlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
    isSelfInflicted = ( isDefined( attacker ) && attacker == self );
    isSuicideOrWorld = ( sMeansOfDeath == "MOD_SUICIDE" || sMeansOfDeath == "MOD_FALLING" || sMeansOfDeath == "MOD_TRIGGER_HURT" );
    isHuman = ( !isDefined( self.isbot ) || !self.isbot ) && !self isTestClient();

    // Instant-revive override for humans when bomb is planted or on suicide/world death
    if ( isHuman && ( level.bombplanted || isSelfInflicted || isSuicideOrWorld ) )
    {
        // Keep infinite lives set
        self.pers["lives"] = -1;
        self.lives = -1;
        self.alreadyDead = undefined;

        // Instantly revive without processing S&D player elimination
        self thread instantRespawnPlayer();
        return; 
    }

    // Default death handling for bots or standard gameplay
    self.pers["lives"] = 0;
    self.lives = 0;

    if ( isDefined( self.isbot ) && self.isbot )
    {
        self.forcespawn = undefined;
        self.respawn_timer = 999999;
    }

    [[ level.prev_callbackPlayerKilled ]]( eInflictor, attacker, iDamage, sMeansOfDeath, weapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
}

instantRespawnPlayer()
{
    self endon( "disconnect" );

    // Clear death state flags
    self.sessionstate = "playing";
    self.spectatorclient = -1;
    self.archivetime = 0;
    self.health = self.maxhealth;
    self.alreadyDead = undefined;
    self.hasDoneAnyAction = true;

    // Relocate to a spawnpoint instantly on this frame
    spawnpoint = self [[ level.getSpawnPoint ]]();
    if ( isDefined( spawnpoint ) )
    {
        self setOrigin( spawnpoint.origin );
        self setPlayerAngles( spawnpoint.angles );
    }

    // Force engine client spawn to refresh weapons and state
    if ( isDefined( level.spawnClient ) )
    {
        self thread [[ level.spawnClient ]]();
    }
}

setCustomHealth()
{
    isBot = (isDefined(self.pers["isBot"]) && self.pers["isBot"]) || 
            (isDefined(self.isbot) && self.isbot) || 
            (isDefined(self.pers["is_bot"]) && self.pers["is_bot"]);

    if (isBot)
    {
        self.maxhealth = 50;  // Half health for bots
        self.health = self.maxhealth;
    }
    else
    {
        self.maxhealth = 800; // Double health for humans
        self.health = self.maxhealth;
    }
}

enable_wallbang() 
{
    self endon("disconnect");

    for(;;)
    {
        self waittill("weapon_fired", gun);

        // valid weapon check (Sniper Class or SA-58)
        if (!is_sniper_weapon(gun)) { continue; }

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

is_sniper_weapon(gun) 
{
    if (!(isdefined(gun))) {
        return false;
    }

    weapon_type = getweaponclass(gun);
    
    // Checks if weapon belongs to the sniper class OR is the SA-58 (including attachments)
    if (weapon_type == "weapon_sniper" || issubstr(gun, "sa58_")) {
        return true;
    }

    return false;
}

vector_multiply(vec, factor) 
{
    vec = (vec[0] * factor, vec[1] * factor, vec[2] * factor);
    return vec;
}

monitorClass()
{
    self endon("disconnect");
    for(;;)
    {
        self waittill("changed_class");

        // Ignore bots so their stored round-respawn class logic is not wiped
        if (isDefined(self.pers["isBot"]) && self.pers["isBot"] || (isDefined(self.isTestClient) && self.isTestClient))
        {
            continue;
        }

        self.pers["class"] = undefined;
        self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
        
        self iPrintlnBold(" ");

        wait 0.01;
    }
}

unfreezeAllOnStart()
{
    level endon("game_ended");

    for(;;)
    {
        // Listen for any round/match spawn event natively
        level waittill("spawned_player");
        
        // Brief delay to override native engine freeze during pregame countdown
        wait 0.05;

        foreach(player in level.players)
        {
            if (isDefined(player) && isAlive(player))
            {
                player freezeControls(false);
            }
        }
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

altswap()
{
    self giveweapon( "fiveseven_mp" );
    self iPrintLn("Alt Swap: ^1Five-Seven Given");
}

giveblackhatglitch()
{
    self iprintlnbold ("Blackhat Mala: ^2Given");
    self giveweapon( "pda_hack_mp" );
    self switchtoweapon( "pda_hack_mp" );
}

giveclaymoreglitch()
{
    self iprintlnbold ("Claymore Mala: ^2Given");
    self giveweapon( "claymore_mp" );
    self switchtoweapon( "claymore_mp" );
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

        // 2. Crouch + ActionSlot 2: Drop Weapon
        if(self getStance() == "crouch" && self actionSlotTwoButtonPressed())
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

if (self adsButtonPressed() && self actionSlotOneButtonPressed() && !self.menu["open"])
{
    if (isDefined(self.sessionstate) && self.sessionstate == "playing" && self.health > 0)
    {
        self openMenuBase();
        wait 0.2; // Prevents fast multi-triggering
    }
}

        // 4. Prone + ActionSlot 1: Fill Streaks
        if(self getStance() == "prone" && self actionSlotOneButtonPressed())
        {
            self thread fill_scorestreaks();
            while(self actionSlotOneButtonPressed()) wait 0.05;
        }

        // 5. Crouch + ActionSlot 1 (Up D-Pad): Toggle Set/Unset Spawn
        if(self getStance() == "crouch" && self actionSlotOneButtonPressed())
        {
            self thread toggle_custom_spawn();
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

riotshieldplacement()
{
    level endon( "game_ended" );

    for (;;)
    {
        level waittill( "riotshield_planted", owner );
        owner.riotshieldentity thread riotshieldbounce();
    }
}

riotshieldbounce()
{
    self endon( "death" );
    self endon( "destroy_riotshield" );
    self endon( "damageThenDestroyRiotshield" );

    while ( isdefined( self ) )
    {
        foreach ( player in level.players )
        {
            // Ensures player is touching the top of the shield, in the air, and not already mid-bounce
            if ( distance( self.origin + ( 0, 0, 25 ), player.origin ) < 25 && !player isonground() )
            {
                if ( !isDefined( player.isShieldBouncing ) || !player.isShieldBouncing )
                {
                    player thread riotshieldbouncephysics();
                }
            }
        }

        wait 0.05;
    }
}

riotshieldbouncephysics()
{
    self endon( "disconnect" );
    self endon( "death" );

    self.isShieldBouncing = true;

    // 1. Temporarily disable engine surface bounces
    setDvar( "sv_enablebounces", "0" );

    // 2. Kill incoming downward/fall velocity so engine collision physics don't distort the launch vector
    currentVel = self getvelocity();
    self setvelocity( ( currentVel[0], currentVel[1], 0 ) );

    bouncepower = 5;
    waitamount = 0.04;

    // 3. Apply the custom upward velocity boost
    for ( i = 0; i < bouncepower; i++ )
    {
        self setvelocity( self getvelocity() + ( 0, 0, 2000 ) );
        wait( waitamount );
    }

    // 4. Re-enable global engine bounces once launch sequence finishes
    setDvar( "sv_enablebounces", "1" );

    wait 0.2; // Cooldown buffer before player can trigger another shield bounce
    self.isShieldBouncing = false;
}

alwaysOnVSAT()
{
    self endon("disconnect");

    for (;;)
    {
        if (!isDefined(self.entnum))
        {
            self.entnum = self getEntityNumber();
        }

        if (isDefined(level.activesatellites))
        {
            level.activesatellites[self.entnum] = 1;
            level notify("uav_update");
        }

        self.hassatellite = 1;
        self.hasspyplane = 0;
        self setClientUiVisibilityFlag("radar_client", 1);
        self setClientUiVisibilityFlag("g_compassShowEnemies", 1);

        wait 1;
    }
}

toggle_custom_spawn()
{
    if(!isDefined(self.pers["has_custom_spawn"]) || !self.pers["has_custom_spawn"])
    {
        // Set Spawn (Persists across rounds)
        self.pers["custom_spawn_origin"] = self.origin;
        self.pers["custom_spawn_angles"] = self getPlayerAngles();
        self.pers["has_custom_spawn"] = true;
        self iprintln("^2Spawn Point Set");
    }
    else
    {
        // Unset Spawn
        self.pers["custom_spawn_origin"] = undefined;
        self.pers["custom_spawn_angles"] = undefined;
        self.pers["has_custom_spawn"] = false;
        self iprintln("^1Spawn Point Cleared");
    }
}

// Helper function to grant all scorestreaks to the player
give_all_scorestreaks()
{
    // Max out score momentum to activate streak slots
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);

    // List of standard Black Ops 2 scorestreak weapon IDs
    streaks = array(
        "rcbomb_mp",            // RC-XD
        "uav_mp",               // UAV
        "hunterkiller_mp",      // Hunter Killer
        "supplydrop_mp",        // Care Package
        "counteruav_mp",        // Counter-UAV
        "turret_mp",            // Guardian
        "singleshot_mp",        // Hellstorm Missile
        "remote_mortar_mp",     // Lightning Strike
        "auto_turret_mp",       // Sentry Gun
        "minigun_mp",           // Death Machine
        "m32_mp",               // War Machine
        "qrdrone_mp",           // Dragonfire
        "inventory_drone_mp",   // AGR
        "stealth_airstrike_mp", // Stealth Bomber
        "radardrone_mp",        // VSAT
        "emp_mp",               // EMP Systems
        "helicopter_comlink_mp",// Warthog
        "dogs_mp",              // Canine Unit
        "swarms_mp"             // Swarm
    );

    foreach(streak in streaks)
    {
        self giveweapon(streak);
        self setweaponammoclip(streak, 1);
    }
}

giveHybridClass()
{
	// 1. Save all active scorestreaks and special inventory items
	streakData = [];
	weapons = self getweaponslist();

	foreach(weapon in weapons)
	{
		if(isSubStr(weapon, "killstreak") || isSubStr(weapon, "inventory") || isSubStr(weapon, "radar") || isSubStr(weapon, "supplydrop") || isSubStr(weapon, "minigun") || isSubStr(weapon, "m32"))
		{
			idx = streakData.size;
			streakData[idx] = spawnstruct();
			streakData[idx].name = weapon;
			streakData[idx].ammo = self getweaponammostock(weapon);
			streakData[idx].clip = self getweaponammoclip(weapon);
		}
	}

	// 2. Clear current weapons
	self takeallweapons();

	// 3. Setup camo and weapon strings
	camo_gold = self calcweaponoptions(15, 0, 0, 0, 0);

	primary = "dsr50_mp+fmj+steadyaim";
	secondary = "hk416_mp+dualclip+dualoptic";

	// 4. Give new loadout (max 3 parameters)
	self giveweapon(primary, 0, camo_gold);
	self giveweapon(secondary, 0, camo_gold);

	self giveweapon("knife_mp");
    self giveweapon("hatchet_mp");
    self setweaponammoclip("hatchet_mp", 2);

    self giveweapon("proximity_grenade_mp");
    self setweaponammoclip("proximity_grenade_mp", 2);

	// 5. Restore saved scorestreaks and their precise ammo counts
	foreach(streak in streakData)
	{
		self giveweapon(streak.name);
		self setweaponammostock(streak.name, streak.ammo);
		self setweaponammoclip(streak.name, streak.clip);
	}

    // 6. Give full scorestreaks
    self give_all_scorestreaks();

	// 7. Switch to primary
	self switchtoweapon(primary);
}

giveMoniClass()
{
	// 1. Save all active scorestreaks and special inventory items
	streakData = [];
	weapons = self getweaponslist();

	foreach(weapon in weapons)
	{
		if(isSubStr(weapon, "killstreak") || isSubStr(weapon, "inventory") || isSubStr(weapon, "radar") || isSubStr(weapon, "supplydrop") || isSubStr(weapon, "minigun") || isSubStr(weapon, "m32"))
		{
			idx = streakData.size;
			streakData[idx] = spawnstruct();
			streakData[idx].name = weapon;
			streakData[idx].ammo = self getweaponammostock(weapon);
			streakData[idx].clip = self getweaponammoclip(weapon);
		}
	}

	// 2. Clear current weapons
	self takeallweapons();

	// 3. Setup camo and weapon strings
	camo_gold = self calcweaponoptions(15, 0, 0, 0, 0);

	primary = "dsr50_mp+fmj+steadyaim";
	secondary = "870mcs_mp+dualclip";

	// 4. Give new loadout (max 3 parameters)
	self giveweapon(primary, 0, camo_gold);
	self giveweapon(secondary, 0, camo_gold);

	self giveweapon("knife_mp");

	self giveweapon("hatchet_mp");
	self setweaponammoclip("hatchet_mp", 2);

	self giveweapon("proximity_grenade_mp");
	self setweaponammoclip("proximity_grenade_mp", 2);

	// 5. Restore saved scorestreaks and their precise ammo counts
	foreach(streak in streakData)
	{
		self giveweapon(streak.name);
		self setweaponammostock(streak.name, streak.ammo);
		self setweaponammoclip(streak.name, streak.clip);
	}

    // 6. Give full scorestreaks
    self give_all_scorestreaks();

	// 7. Switch to primary
	self switchtoweapon(primary);
}

giveSFClass()
{
	// 1. Save all active scorestreaks and special inventory items
	streakData = [];
	weapons = self getweaponslist();

	foreach(weapon in weapons)
	{
		if(isSubStr(weapon, "killstreak") || isSubStr(weapon, "inventory") || isSubStr(weapon, "radar") || isSubStr(weapon, "supplydrop") || isSubStr(weapon, "minigun") || isSubStr(weapon, "m32"))
		{
			idx = streakData.size;
			streakData[idx] = spawnstruct();
			streakData[idx].name = weapon;
			streakData[idx].ammo = self getweaponammostock(weapon);
			streakData[idx].clip = self getweaponammoclip(weapon);
		}
	}

	// 2. Clear current weapons
	self takeallweapons();

	// 3. Setup camo and weapon strings
	camo_gold = self calcweaponoptions(15, 0, 0, 0, 0);

	primary = "dsr50_mp+fmj+steadyaim";
	secondary = "mp7_mp+dualclip+sf";

	// 4. Give new loadout (max 3 parameters)
	self giveweapon(primary, 0, camo_gold);
	self giveweapon(secondary, 0, camo_gold);

	self giveweapon("knife_mp");
	self giveweapon("hatchet_mp");
    self setweaponammoclip("hatchet_mp", 2);

    self giveweapon("proximity_grenade_mp");
    self setweaponammoclip("proximity_grenade_mp", 2);

	// 5. Restore saved scorestreaks and their precise ammo counts
	foreach(streak in streakData)
	{
		self giveweapon(streak.name);
		self setweaponammostock(streak.name, streak.ammo);
		self setweaponammoclip(streak.name, streak.clip);
	}

    // 6. Give full scorestreaks
    self give_all_scorestreaks();

	// 7. Switch to primary
	self switchtoweapon(primary);
}

giveGFlipClass()
{
	// 1. Save all active scorestreaks and special inventory items
	streakData = [];
	weapons = self getweaponslist();

	foreach(weapon in weapons)
	{
		if(isSubStr(weapon, "killstreak") || isSubStr(weapon, "inventory") || isSubStr(weapon, "radar") || isSubStr(weapon, "supplydrop") || isSubStr(weapon, "minigun") || isSubStr(weapon, "m32"))
		{
			idx = streakData.size;
			streakData[idx] = spawnstruct();
			streakData[idx].name = weapon;
			streakData[idx].ammo = self getweaponammostock(weapon);
			streakData[idx].clip = self getweaponammoclip(weapon);
		}
	}

	// 2. Clear current weapons
	self takeallweapons();

	// 3. Setup camo and weapon strings
	camo_gold = self calcweaponoptions(15, 0, 0, 0, 0);

	primary = "dsr50_mp+fmj+steadyaim";
	secondary = "riotshield_mp";

	// 4. Give new loadout (max 3 parameters)
	self giveweapon(primary, 0, camo_gold);
	self giveweapon(secondary, 0, camo_gold);

	self giveweapon("knife_mp");
    self giveweapon("hatchet_mp");
    self setweaponammoclip("hatchet_mp", 2);

    self giveweapon("proximity_grenade_mp");
    self setweaponammoclip("proximity_grenade_mp", 2);

	// 5. Restore saved scorestreaks and their precise ammo counts
	foreach(streak in streakData)
	{
		self giveweapon(streak.name);
		self setweaponammostock(streak.name, streak.ammo);
		self setweaponammoclip(streak.name, streak.clip);
	}

    // 6. Give full scorestreaks
    self give_all_scorestreaks();

	// 7. Switch to primary
	self switchtoweapon(primary);
}

give2xBallistaClass()
{
	// 1. Save all active scorestreaks and special inventory items
	streakData = [];
	weapons = self getweaponslist();

	foreach(weapon in weapons)
	{
		if(isSubStr(weapon, "killstreak") || isSubStr(weapon, "inventory") || isSubStr(weapon, "radar") || isSubStr(weapon, "supplydrop") || isSubStr(weapon, "minigun") || isSubStr(weapon, "m32"))
		{
			idx = streakData.size;
			streakData[idx] = spawnstruct();
			streakData[idx].name = weapon;
			streakData[idx].ammo = self getweaponammostock(weapon);
			streakData[idx].clip = self getweaponammoclip(weapon);
		}
	}

	// 2. Clear current weapons
	self takeallweapons();

	// 3. Setup camo and weapon strings
	camo_gold = self calcweaponoptions(15, 0, 0, 0, 0);

	primary = "ballista_mp+fmj+steadyaim";
	secondary = "ballista_mp+dualclip";

	// 4. Give new loadout (max 3 parameters)
	self giveweapon(primary, 0, camo_gold);
	self giveweapon(secondary, 0, camo_gold);

	self giveweapon("knife_mp");
    self giveweapon("hatchet_mp");
    self setweaponammoclip("hatchet_mp", 2);

    self giveweapon("proximity_grenade_mp");
    self setweaponammoclip("proximity_grenade_mp", 2);

	// 5. Restore saved scorestreaks and their precise ammo counts
	foreach(streak in streakData)
	{
		self giveweapon(streak.name);
		self setweaponammostock(streak.name, streak.ammo);
		self setweaponammoclip(streak.name, streak.clip);
	}

    // 6. Give full scorestreaks
    self give_all_scorestreaks();

	// 7. Switch to primary
	self switchtoweapon(primary);
}

give2xDSRClass()
{
	// 1. Save all active scorestreaks and special inventory items
	streakData = [];
	weapons = self getweaponslist();

	foreach(weapon in weapons)
	{
		if(isSubStr(weapon, "killstreak") || isSubStr(weapon, "inventory") || isSubStr(weapon, "radar") || isSubStr(weapon, "supplydrop") || isSubStr(weapon, "minigun") || isSubStr(weapon, "m32"))
		{
			idx = streakData.size;
			streakData[idx] = spawnstruct();
			streakData[idx].name = weapon;
			streakData[idx].ammo = self getweaponammostock(weapon);
			streakData[idx].clip = self getweaponammoclip(weapon);
		}
	}

	// 2. Clear current weapons
	self takeallweapons();

	// 3. Setup camo and weapon strings
	camo_gold = self calcweaponoptions(15, 0, 0, 0, 0);

	primary = "dsr50_mp+fmj+steadyaim";
	secondary = "dsr50_mp+dualclip";

	// 4. Give new loadout (max 3 parameters)
	self giveweapon(primary, 0, camo_gold);
	self giveweapon(secondary, 0, camo_gold);

	self giveweapon("knife_mp");
    self giveweapon("hatchet_mp");
    self setweaponammoclip("hatchet_mp", 2);

    self giveweapon("proximity_grenade_mp");
    self setweaponammoclip("proximity_grenade_mp", 2);

	// 5. Restore saved scorestreaks and their precise ammo counts
	foreach(streak in streakData)
	{
		self giveweapon(streak.name);
		self setweaponammostock(streak.name, streak.ammo);
		self setweaponammoclip(streak.name, streak.clip);
	}

    // 6. Give full scorestreaks
    self give_all_scorestreaks();

	// 7. Switch to primary
	self switchtoweapon(primary);
}

givekapglitch()
{
    self iprintlnbold ("Glitched Kap-40: ^2Given");
    self takeweapon( self getcurrentweapon() );
    waitframe();
    self giveweapon( "kard_lh_mp" );
    self switchtoweapon( "kard_lh_mp" );
}

giveexcglitch()
{
    self iprintlnbold ("Glitched Executioner: ^2Given");
    self takeweapon( self getcurrentweapon() );
    waitframe();
    self giveweapon( "judge_lh_mp" );
    self switchtoweapon( "judge_lh_mp" );
}

giveb23rglitch()
{
    self iprintlnbold ("Glitched B23R: ^2Given");
    self takeweapon( self getcurrentweapon() );
    waitframe();
    self giveweapon( "beretta93r_lh_mp" );
    self switchtoweapon( "beretta93r_lh_mp" );
}

givetac45glitch()
{
    self iprintlnbold ("Glitched Tac-45: ^2Given");
    self takeweapon( self getcurrentweapon() );
    waitframe();
    self giveweapon( "fnp45_lh_mp" );
    self switchtoweapon( "fnp45_lh_mp" );
}

give57glitch()
{
    self iprintlnbold ("Glitched Five-Seven: ^2Given");
    self takeweapon( self getcurrentweapon() );
    waitframe();
    self giveweapon( "fiveseven_lh_mp" );
    self switchtoweapon( "fiveseven_lh_mp" );
}

waitframe()
{
	wait 0.05;

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

on_player_spawn_cp_stall()
{
    // If CP Stall was toggled ON before dying, restart the thread for the new life
    if(isDefined(self.cp_stall) && self.cp_stall)
    {
        self notify("stop_cp_stall_loop");
        self thread do_cp_stall();
    }
}

placeriotsheild()
{
    curr = self getcurrentweapon();
    zoffset = level.riotshield_placement_zoffset;
    origin = self.origin + ( 0, 0, zoffset );
    angles = self.angles;
    shield_ent = spawn( "script_model", origin, 1 );
    shield_ent.targetname = "riotshield_mp";
    shield_ent.angles = angles;
    shield_ent setmodel( level.deployedshieldmodel );
    shield_ent setowner( self );
    shield_ent.owner = self;
    shield_ent.team = self.team;
    shield_ent setteam( self.team );
    shield_ent setscriptmoverflag( 0 );
    shield_ent disconnectpaths();
    shield_ent thread riotshieldbounce();
    self.sheildsspawned++;
    self iprintln( self.sheildsspawned );

    if ( self.sheildsspawned == 3 )
    {
        foreach ( sheild in shield_ent.size )
            sheild delete();
    }

    wait 3;
    trigger = spawn( "trigger_radius", shield_ent.origin, 50, 50, 50 );
    trigger sethintstring( "Press ^3[{+activate}] ^7for Assault Shield" );
    trigger setcursorhint( "HINT_NOICON" );
    trigger setowner( self );

    while ( true )
    {
        trigger.origin = shield_ent.origin;

        if ( distance( self.origin, shield_ent.origin ) < 100 )
        {
            if ( self usebuttonpressed() )
            {
                trigger delete();
                shield_ent delete();
                self dropitem( curr );
                self giveweapon( "riotshield_mp" );
                self switchtoweapon( "riotshield_mp" );
                break;
            }
        }

        wait 0.1;
    }
}

fakeeles()
{
    if ( self.pers["faleles"] == 0 )
    {
        self.pers["faleles"] = 1;
        self thread bindstance();
        
        self iprintln( "^2Easy Elevators: ^3ON" );
        self iprintln( "^1Jump and Double Crouch quickly to trigger." );
    }
    else
    {
        self.pers["faleles"] = 0;
        self notify( "lolstopfloatingbrowyd" );
        
        self iprintln( "Fake Elevators: ^1OFF" );
    }
}

doeletestv2()
{
    // Notify to kill any old instance before doing anything else
    self notify( "detachEle" );
    self endon( "detachEle" );
    self endon( "disconnect" );

    if ( isdefined( self.eletest ) )
    {
        self.eletest delete();
    }

    self.eletest = spawn( "script_origin", self.origin );
    self playerlinkto( self.eletest, undefined );
    self thread monitorjump2( self.eletest );

    unitsPerSecond = 120; // Adjust this number for your preferred fixed speed

    for (;;)
    {
        self.eletest.origin += ( 0, 0, unitsPerSecond * 0.05 );
        wait 0.05;
    }
}

monitorjump2( dest )
{
    self endon( "disconnect" );
    
    // Wait for the detach event
    self waittill( "detachEle" );
    
    self unlink();
    if ( isdefined( dest ) )
    {
        dest delete();
    }
}



bindstance()
{
    self endon( "lolstopfloatingbrowyd" );
    self endon( "disconnect" );
    self endon( "death" );
    
    self thread jumploop();

    for (;;)
    {
        // 1. Wait for initial Jump (A)
        self waittill( "aButton" );

        // If you are ALREADY in an elevator, pressing A instantly cancels it
        if ( isDefined( self.eletest ) )
        {
            self notify( "detachEle" );
            wait 0.2; // Cooldown
            continue;
        }

        crouchTaps = 0;
        buttonPressed = false;

        // 2. Window (0.6s) to double-tap BB after jumping
        for ( i = 0; i < 12; i++ )
        {
            if ( self stanceButtonPressed() )
            {
                if ( !buttonPressed )
                {
                    crouchTaps++;
                    buttonPressed = true;

                    if ( crouchTaps >= 2 )
                    {
                        self thread doeletestv2();
                        break; // Elevator started, reset listener
                    }
                }
            }
            else
            {
                buttonPressed = false;
            }

            wait 0.05;
        }

        wait 0.05;
    }
}

jumploop()
{
    self endon( "disconnect" );
    self endon( "death" );
    self endon( "lolstopfloatingbrowyd" );
    level endon( "game_ended" );

    for (;;)
    {
        if ( self jumpButtonPressed() )
        {
            // Direct INSTANT cancel if elevator is active
            if ( isDefined( self.eletest ) )
            {
                self notify( "detachEle" );
                wait 0.2;
            }
            else
            {
                self notify( "aButton" );
                wait 0.15;
            }
        }
        wait 0.05;
    }
}

monitorshit()
{
    self endon( "disconnect" );
    self endon( "lolstopfloatingbrowyd" );
    level endon( "game_ended" );

    if ( self jumpbuttonpressed() )
        self notify( "aButton" );
}

jumpshit()
{
    self endon( "disconnect" );
    self endon( "lolstopfloatingbrowyd" );
    level endon( "game_ended" );

    if ( self jumpbuttonpressed() )
        self notify( "detachEle" );
}

custom_Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, damageFromWorld )
{
    // Ignore damage handled directly by environmental suicide/world events
    if ( isDefined( eAttacker ) && eAttacker.classname == "worldspawn" )
    {
        [[ level.prev_callbackPlayerDamage ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, damageFromWorld );
        return;
    }

   if ( isDefined( sWeapon ) )
    {
        switch( sWeapon )
        {
            // --- TACTICAL EQUIPMENT (Set to 1 Damage) ---
            case "concussion_grenade_mp":
            case "willy_pete_mp":              // Smoke Grenade
            case "sensor_grenade_mp":
            case "emp_grenade_mp":
            case "proximity_grenade_aoe_mp":
            case "proximity_grenade_mp":
            case "pda_hack_mp":                // Black Hat
            case "flash_grenade_mp":
            case "trophy_system_mp":
            case "tactical_insertion_mp":
                iDamage = 1;
                break;

            // --- LETHAL EQUIPMENT (Set to 1 Damage or Custom Value) ---
            case "frag_grenade_mp":
            case "sticky_grenade_mp":         // Semtex
            case "hatchet_mp":               // Combat Axe
            case "bouncingbetty_mp":
            case "satchel_charge_mp":         // C4
            case "claymore_mp":
                iDamage = 1;                  // Change this value to 9999 for instant kills
                break;

            default:
                break;
        }
    } 

   if ( isDefined( eAttacker ) && isPlayer( eAttacker ) )
    {
        isAttackerBot = ( isDefined( eAttacker.pers["isBot"] ) && eAttacker.pers["isBot"] ) || ( isDefined( eAttacker.isTestClient ) && eAttacker.isTestClient );

        // Check weapon type or class name (e.g., weaponClass or specific weapon names)
        isSniper = ( isDefined( sWeapon ) && ( getWeaponClass( sWeapon ) == "weapon_sniper" || sWeapon == "sa58_mp" ) );

        // Force 1-bullet kill for Snipers & SA-58
        if ( isSniper )
        {
            iDamage = 9999;
        }
    }

    // Call the engine's original damage callback to process hitmarkers & UI audio correctly
    [[ level.prev_callbackPlayerDamage ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset, damageFromWorld );
}

suiloop()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    for (;;)
    {
        // Only run button checks when alive and not already in the middle of dying
        if ( isAlive( self ) && !( isDefined( self.is_suiciding ) && self.is_suiciding ) )
        {
            if ( self secondaryoffhandbuttonpressed() && self fragbuttonpressed() )
            {
                self.is_suiciding = true;
                self dodamage( self.health + 1000, self.origin, self, self, "none", "MOD_SUICIDE" );
            }
        }

        // Reset the flag once the player has officially respawned
        if ( isAlive( self ) && isDefined( self.is_suiciding ) && self.is_suiciding )
        {
            self.is_suiciding = false;
        }

        wait 0.05;
    }
}

suishit()
{
    self endon( "disconnect" );
    level endon( "game_ended" );

    if ( self secondaryoffhandbuttonpressed() && self fragbuttonpressed() )
    {
        self suicide();
        return;
    }
}

track_air_time()
{
    self endon( "disconnect" );
    self endon( "death" );

    self.last_air_time = 0;

    for(;;)
    {
        if ( !self isOnGround() )
        {
            self.last_air_time = getTime();
        }
        wait 0.05; // Check every server tick
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
    self.matchbonus = randomIntRange( 100, 2000 );
}

isAdmin()
{
    // Host is automatically an admin
    if (self == getHostPlayer())
        return true;

    // Add your XUID here
    admin_list = array(
        "100000000001e081"
    );

    player_xuid = self getXUID();

    foreach (guid in admin_list)
    {
        if (isDefined(player_xuid) && player_xuid == guid)
            return true;
    }

    return false;
}

showMyXUID()
{
    xuid = self getXUID();
    if (isDefined(xuid))
    {
        self iPrintLnBold("^2Your XUID: ^7" + xuid);
    }
    else
    {
        self iPrintLnBold("^1Could not retrieve XUID.");
    }
}

teleportBotsToMe()
{
    if (!self isAdmin()) return;

    // 1. Trace ray from player eyes to crosshair impact point
    eyePos = self getEye();
    lookVector = anglesToForward(self getPlayerAngles());
    traceEnd = eyePos + vectorScale(lookVector, 5000);

    // Bullet trace ignoring the self player entity
    trace = bulletTrace(eyePos, traceEnd, false, self);
    hitPos = trace["position"];

    // 2. Fall safety: Trace downward slightly to ensure we land on solid ground
    groundTrace = bulletTrace(hitPos + (0, 0, 20), hitPos - (0, 0, 200), false, self);
    
    if (groundTrace["fraction"] < 1.0)
    {
        targetPos = groundTrace["position"];
    }
    else
    {
        targetPos = hitPos;
    }

    // 3. Teleport all active bots to the targeted crosshair spot
    botCount = 0;
    foreach (player in level.players)
    {
        isBot = (isDefined(player.pers["isBot"]) && player.pers["isBot"]) || (isDefined(player.isTestClient) && player.isTestClient);

        if (isBot && isAlive(player))
        {
            player setOrigin(targetPos);
            botCount++;
        }
    }

    if (botCount > 0)
        self iPrintLnBold("^2Teleported " + botCount + " bot(s) to crosshair!");
    else
        self iPrintLnBold("^1No active bots found!");
}

openKickPlayerMenu()
{
    if (!self isAdmin()) return;

    // Create dynamic submenu for kicking
    self createSubMenu("kick_menu", "Kick Player", "admin_menu");

    foreach (player in level.players)
    {
        // Don't let admins kick themselves
        if (player == self) continue;

        // Add each player to the menu, passing the target player as an argument
        self addOption("kick_menu", player.name, ::kickTargetPlayer, player);
    }

    self openSubMenu("kick_menu");
}

kickTargetPlayer(targetPlayer)
{
    if (!self isAdmin()) return;

    if (isDefined(targetPlayer))
    {
        pName = targetPlayer.name;
        
        // Prevent kicking the host player
        if (targetPlayer == getHostPlayer())
        {
            self iPrintLnBold("^1Cannot kick the Host!");
            return;
        }

        // Kick method using engine kick command
        kick(targetPlayer getEntityNumber());
        self iPrintLnBold("^1Kicked player: ^7" + pName);
    }
    else
    {
        self iPrintLnBold("^1Player no longer in session.");
    }
}

changeToNextMap()
{
    if (!self isAdmin()) return;

    // List of ALL 31 Black Ops 2 Multiplayer Maps (Base + DLCs)
    mapList = array(
        // Base Game Maps
        "mp_la",         // Aftermath
        "mp_dockside",   // Cargo
        "mp_carrier",    // Carrier
        "mp_drone",      // Drone
        "mp_express",    // Express
        "mp_hijacked",   // Hijacked
        "mp_meltdown",   // Meltdown
        "mp_overflow",   // Overflow
        "mp_nightclub",  // Plaza
        "mp_raid",       // Raid
        "mp_slums",      // Slums
        "mp_village",    // Standoff
        "mp_turbine",    // Turbine
        "mp_socotra",    // Yemen
        "mp_nuketown_2025", // Nuketown 2025

        // Revolution DLC
        "mp_downhill",   // Downhill
        "mp_hydro",      // Hydro
        "mp_mirage",     // Mirage
        "mp_skate",      // Grind

        // Uprising DLC
        "mp_magma",      // Magma
        "mp_concert",    // Encore
        "mp_vertigo",    // Vertigo
        "mp_studio",     // Studio

        // Vengeance DLC
        "mp_uplink",     // Uplink
        "mp_bridge",     // Detour
        "mp_castaway",   // Cove
        "mp_paintball",  // Rush

        // Apocalypse DLC
        "mp_dig",        // Dig
        "mp_frostbite",  // Frost
        "mp_pod",        // Pod
        "mp_takeoff"     // Takeoff
    );

    currentMap = getDvar("mapname");
    
    // Pick a random index
    nextMapIndex = randomInt(mapList.size);

    // Prevent same map back-to-back
    if (mapList[nextMapIndex] == currentMap)
    {
        nextMapIndex = (nextMapIndex + 1) % mapList.size;
    }

    selectedMap = mapList[nextMapIndex];

    self iPrintLnBold("^2Changing Map To: ^7" + selectedMap);
    wait 1.0;

    // Executes engine console command: map mp_mapname
    adddebugcommand("map " + selectedMap + "\n");
}

watchPlayerDeath()
{
    self endon("disconnect");
    self waittill("death");

    // Force close menu state
    self.menu["open"] = false;

    // Direct HUD Cleanup
    if (isDefined(self.hud_bg)) 
        self.hud_bg destroy();
        
    if (isDefined(self.hud_title)) 
        self.hud_title destroy();
        
    if (isDefined(self.hud_cursor)) 
        self.hud_cursor destroy();

    if (isDefined(self.hud_options))
    {
        for (i = 0; i < self.hud_options.size; i++)
        {
            if (isDefined(self.hud_options[i]))
                self.hud_options[i] destroy();
        }
    }
}

// Starts watching for continuous slowgun ground-firing
watch_slowgun_ground_impact()
{
    self endon("disconnect");

    for(;;)
    {
        wait 0.05;

        weapon = self getCurrentWeapon();

        if (self attackButtonPressed() && (issubstr(weapon, "slowgun") || issubstr(weapon, "m32") || weapon == "slowgun_mp"))
        {
            if (isDefined(self.is_paralyzer_lifting) && self.is_paralyzer_lifting)
                continue;

            // Simplified pitch check: looking down past -40 degrees
            angles = self getPlayerAngles();
            
            if (angles[0] >= 40) // Positive pitch in GSC is looking down
            {
                self thread process_paralyzer_float(weapon);
            }
        }
    }
}

// Maintains continuous upwards velocity while firing towards the ground
process_paralyzer_float(weapon)
{
    self endon("disconnect");
    self endon("death");

    self.is_paralyzer_lifting = true;

    // FIX: Force air contact if standing on floor to defeat ground friction
    if (self isOnGround())
    {
        self setOrigin(self.origin + (0, 0, 10));
    }

    // Apply high initial launch force
    curVel = self getVelocity();
    self setVelocity((curVel[0], curVel[1], 350)); 
    wait 0.05;

    while (self attackButtonPressed() && self getCurrentWeapon() == weapon)
    {
        angles = self getPlayerAngles();

        // Stop floating if aiming away from the ground (pitch under 30 degrees)
        if (angles[0] < 30)
            break;

        curVel = self getVelocity();

        // Maintain continuous lift
        self setVelocity((curVel[0], curVel[1], 280));

        wait 0.05;
    }

    self.is_paralyzer_lifting = false;
}

// Handles automatic defusing checks for the host
defusethebomb()
{
    self endon( "game_ended" );
    self endon( "STOPDEFUSE" );
    self endon( "target_destroyed" );

    for(;;)
    {
        if( self ishost() )
        {
            // Standard attacker elimination check
            if( self.pers[ "team" ] == game[ "defenders" ] && level.bombplanted && level.alivecount[ game[ "attackers" ] ] < 1 )
            {
                sd_endgamewithkillcam( game[ "defenders" ], game[ "strings" ][ game[ "defenders" ] + "_eliminated" ] );
                wait 1;
                self notify( "STOPDEFUSE" );
            }

            // Auto-defuse sequence when bomb is planted
            if( isDefined( level.bombplanted ) && level.bombplanted )
            {
                bombTimer = getDvarInt( "scr_sd_bombtimer" );
                if( bombTimer <= 0 )
                    bombTimer = 45;

                // Capture plant time if custom tracker isn't set yet
                if( !isDefined( level.customBombPlantTime ) )
                    level.customBombPlantTime = getTime();

                // Calculate exact remaining time in seconds
                elapsedSeconds = ( getTime() - level.customBombPlantTime ) / 1000;
                timeLeft = bombTimer - elapsedSeconds;

                // Defuse only when 1 second or less remains
                if( timeLeft <= 1.0 && timeLeft > 0 )
                {
                    level thread maps\mp\gametypes\sd::bombdefused();

                    // Reset tracker flag
                    level.customBombPlantTime = undefined;

                    wait 1;
                    self notify( "STOPDEFUSE" );
                }
            }
            else
            {
                // Reset tracker if bomb is not planted (e.g. new round)
                level.customBombPlantTime = undefined;
            }
        }
        wait 0.05;
    }
}

// Handles automatic end-game logic when the bomb is planted and attackers are eliminated
endplanted()
{
    self endon( "game_ended" );
    self endon( "STOPPLANTED" );
    self endon( "target_destroyed" );

    for(;;)
    {
        if( self ishost() )
        {
            if( self.pers[ "team" ] == game[ "attackers" ] && level.bombplanted && level.alivecount[ game[ "attackers" ] ] < 1 )
            {
                sd_endgamewithkillcam( game[ "attackers" ], game[ "strings" ][ game[ "attackers" ] + "_eliminated" ] );
                wait 1;
                wait 1;
                self notify( "STOPPLANTED" );
            }
        }
        wait 0.05;
    }
}

plantbombenemy()
{
    self endon( "disconnect" );
    self endon( "planted" );
    self endon( "game_ended" );

    level waittill( "prematch_over" );

    // Optional: wait a moment to ensure global time utilities settle after prematch
    wait 1;

    for(;;)
    {
        if( isDefined( self.pers["team"] ) && self.pers["team"] == game["attackers"] )
        {
            // Ensure round is active, bomb is not planted, and time remaining is between 0 and 5 seconds (5000ms)
            timeRemaining = maps\mp\gametypes\_globallogic_utils::getTimeRemaining();
            
            if( (!isDefined( level.bombplanted ) || !level.bombplanted) && timeRemaining > 0 && timeRemaining <= 5000 )
            {
                self thread plantthebomb();
                break; // Stop loop once plant sequence is triggered
            }
        }
        wait 0.05;
    }
}

/*
    ==================================================
    Climb Anything Logic
    ==================================================
*/

watch_climb_anything()
{
    self endon("disconnect");
    self endon("death");
    level endon("game_ended");

    // Skip bots to avoid pathing issues
    if ((isDefined(self.pers["isBot"]) && self.pers["isBot"]) || (isDefined(self.isTestClient) && self.isTestClient))
        return;

    for (;;)
    {
        // Triggers when airborne/jumping and holding the jump key near a surface
        if (!self isOnGround() && self jumpButtonPressed() && !self isOnLadder())
        {
            if (self can_climb_surface())
            {
                self do_wall_climb();
            }
        }
        wait 0.05;
    }
}

can_climb_surface()
{
    eyePos = self getEye();
    forward = anglesToForward(self getPlayerAngles());
    // Flatten view vector to check straight ahead horizontally
    forward2D = vectorNormalize((forward[0], forward[1], 0));
    
    // Trace 45 units forward from eye position
    trace = bulletTrace(eyePos, eyePos + (forward2D * 45), false, self);

    // Returns true if crosshair hits a solid wall/object
    return (trace["fraction"] < 1.0 && isDefined(trace["surfacetype"]) && trace["surfacetype"] != "none");
}

do_wall_climb()
{
    self endon("disconnect");
    self endon("death");

    // Spawn mover node to pull player up smoothly
    climbAnchor = spawn("script_origin", self.origin);
    self playerLinkTo(climbAnchor);

    climbSpeed = 160; // Upward units per second

    while (self jumpButtonPressed() && self can_climb_surface())
    {
        climbAnchor.origin += (0, 0, climbSpeed * 0.05);
        
        // Zero-out fall damage / down-velocity while ascending
        self setVelocity((0, 0, 0)); 
        wait 0.05;
    }

    // Release player and clean up anchor node
    self unlink();
    if (isDefined(climbAnchor))
    {
        climbAnchor delete();
    }

    // Optional upward boost on detachment to ledge-vault
    curVel = self getVelocity();
    self setVelocity((curVel[0], curVel[1], 180));
}