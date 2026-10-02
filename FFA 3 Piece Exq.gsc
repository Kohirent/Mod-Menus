#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\gametypes\_globallogic_score;

init()
{
    // Standard menu initialization [cite: 50]
    precacheshader( "white" );
    init_callbacks();
    init_precache();
    init_strings();

    setDvar("party_maxplayers", "18");
    setDvar("sv_maxclients", "18");
    setDvar("com_maxclients", "18");
    setDvar("sv_enablebounces", "1");
    level thread SetupGlobalVisibleFloors(); 
    level thread SetupMapElevators();
    level.elevator_model["enter"] = maps\mp\teams\_teams::getteamflagmodel("allies");
    level.elevator_model["exit"] = maps\mp\teams\_teams::getteamflagmodel("axis");
    level.callbackplayerdamage_stub = level.callbackplayerdamage;
    level.callbackplayerdamage = ::your_custom_damage_function;
    level thread removeskybar();
    level thread barriers();
    level thread pre_game_unfreeze();
    level thread onplayerconnect();
    level thread public_match_bonus_logic();
    setDvar("sv_clientSideBullets", 1);
    setDvar("bulletrange", 50000);
    makedvarserverinfo("bulletrange", 50000);
    
}

init_precache()
{
    precacheModel("collision_clip_32x32x32");
    precacheModel(level.elevator_model["enter"]);
    precacheModel(level.elevator_model["exit"]);
    precacheModel("t6_wpn_supply_drop_trap");
    precacheModel("veh_t6_drone_rcxd_alt"); 
}

init_strings()
{

}

onplayerconnect()
{
    for(;;)
    {
        level waittill( "connected", player ); // [cite: 7]
      if (player ishost()) {
    level.host = player; 
    if (!game["bot_already_spawned"]) {
        game["bot_already_spawned"] = true;
        level thread addtestclients();
    }
}  

      if(is_bot(player)) // [cite: 8]
        {
           player thread onbotspawned(); 
           player thread bot_logic(); // [cite: 9]
        }
        else
        {
            player thread onplayerspawned(); // [cite: 10]
        }
    }
}

onplayerspawned()
{
    self endon( "disconnect" ); // [cite: 11]
    for(;;)
    {
        self waittill( "spawned_player" );

if(isDefined(self.menu))
        {
            self.menu["open"] = false;
        }
        

if(isDefined(self.menu["hud_bg"])) self.menu["hud_bg"] destroy(); 
        if(isDefined(self.menu["hud_txt"])) self.menu["hud_txt"] destroy();
        if(isDefined(self.menu["hud_title"])) self.menu["hud_title"] destroy();
        if(isDefined(self.menu["hud_header"])) self.menu["hud_header"] destroy();

        self thread monitorClass();
        self thread give_global_tac_mask();
        self thread monitorDeathSND();
        self setscore( self, level.scorelimit - 1 );
        self thread timegoneby();  
        self thread menu_init(); // [cite: 49]
        self thread instant_class_logic(); // [cite: 36]
        self thread button_monitor(); // [cite: 61]
        self thread enable_wallbang(); // [cite: 40]
        self thread monitorPositionButtons(); // [cite: 22]

     // Logical Reset: Tells the script the menu is closed on respawn
        if(isDefined(self.menu))
        {
            self.menu["open"] = false;
        }

        // Visual Cleanup: Deletes any left-over HUD objects from the previous life
        self force_cleanup_huds();   

     if(isDefined(self.unlimited_equip) && self.unlimited_equip)
{
    self thread do_unlimited_equipment();
} 
       
if(isDefined(self.high_jump) && self.high_jump)
{
    self setClientDvar("jump_height", 125);
}
else
{
    self setClientDvar("jump_height", 39);
}
        if(!isDefined(self.uav_always_on) || self.uav_always_on) // [cite: 13]
        {
            self.uav_always_on = true;
            self thread doUAV(); // [cite: 14, 76]
        }

        if(isDefined(self.godmode) && self.godmode) // [cite: 15, 147]
        {
            self.maxhealth = 99999;
            self.health = self.maxhealth;
        }

        if(isDefined(self.ufo_mode) && self.ufo_mode) // [cite: 16, 141]
        {
            self.ufo_pos = self.origin;
            self thread do_ufo_logic();
        }

        if(isDefined(self.pure_boost) && self.pure_boost) 
            self thread do_pure_boost_logic(); // [cite: 17, 81]
        if(isDefined(self.head_bounce_active) && self.head_bounce_active) 
            self thread do_player_bounce_logic(); // [cite: 18, 87]
        if(isDefined(self.one_bullet) && self.one_bullet) 
            self thread do_one_bullet_logic(); // [cite: 20, 122]
        if(isDefined(self.cp_stall) && self.cp_stall)
            self thread do_cp_stall(); // [cite: 21, 101]
            if(isDefined(self.semtex) && self.semtex == 1)
            self thread semtex();
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
            self setClientDvar("jump_height", 39);
    }
    while(self actionSlotOneButtonPressed()) wait 0.05; 
}
        }
        wait 0.05; 
    }
}

bot_logic()
{
    self endon("disconnect");
    for(;;) // [cite: 26]
    {
        if(self.maxhealth != 1)
        {
            self.maxhealth = 1;
            self.health = 1; // [cite: 27]
        }

        if(self.score > 0 || self.pers["score"] > 0 || self.pers["kills"] > 0)
        {
            self.score = 0;
            self.pers["score"] = 0; // [cite: 28]
            self.kills = 0;
            self.pers["kills"] = 0;
            self.pointstowin = 0;
            self.pers["pointstowin"] = 0; // [cite: 29]
        }

        currentWeapon = self getCurrentWeapon(); // [cite: 30]
        if(currentWeapon != "knife_mp")
        {
            self takeAllWeapons();
            self giveWeapon("knife_mp"); // [cite: 31]
            self switchToWeapon("knife_mp");
        }
        wait 0.05;
    }
}

pre_game_unfreeze()
{
    level endon("game_ended");
    for(;;) // [cite: 32]
    {
        if(isDefined(level.ingraceperiod) && level.ingraceperiod)
        {
            foreach(player in level.players)
            {
                if(isAlive(player))
                {
                    player freezecontrols(false); // [cite: 33]
                    player setclientuivisibilityflag("hud_visible", 1);
                }
            }
        }
        wait 0.1; // [cite: 34]
    }
}

public_match_bonus_logic()
{
    level waittill("game_ended");
    foreach(player in level.players)
    {
        if(!is_bot(player))
        {
            bonus = randomIntRange(15000, 45000);
            player thread maps\mp\gametypes\_hud_message::hintMessage("^7Match Bonus: ^6" + bonus); // [cite: 35]
        }
    }
}

instant_class_logic()
{
    self endon("disconnect");
    self endon("death");
    oldClass = self.pers["class"]; // [cite: 36]
    for(;;)
    {
        if(self.pers["class"] != oldClass)
        {
            oldClass = self.pers["class"];
            self maps\mp\gametypes\_class::giveloadout(self.pers["team"], self.pers["class"]); // [cite: 37]
            self iPrintlnBold(" "); 
        }
        wait 0.01;
    }
}

enable_wallbang() 
{
    self endon("disconnect");
    self endon("death");
    for(;;)
    {
        self waittill("weapon_fired", gun);

        // 1. PROJECTILE & LAUNCHER FILTER
        // This prevents wallbang logic from applying to knives, tomahawks, 
        // and all launcher variants to stop unwanted physics/fly effects.
        if (isSubStr(gun, "knife_ballistic") || 
            isSubStr(gun, "tomehawk") || 
            isSubStr(gun, "rpg") || 
            isSubStr(gun, "smaw") || 
            isSubStr(gun, "fhj") || 
            isSubStr(gun, "launcher")) 
        {
            continue;
        }

        if (is_bot(self)) { continue; }

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
                magicbullet(gun, trace_points[step], trace_points[step] + vector_multiply(fwd_direction, 1000), self);
            }
            step++;
        }
        wait 0.05;
    }
}
vector_multiply(vec, factor) 
{
    return (vec[0] * factor, vec[1] * factor, vec[2] * factor); // [cite: 48]
}

menu_init()
{
    if(!isDefined(self.menu))
    {
        self.menu = [];
        self.menu["open"] = false; // [cite: 49]
        self.menu["curs"] = 0;
        self.menu["current"] = "main";
        self.menu["title"] = "EXQUISITE PACK";
    }
    self setup_menu_structure(); // [cite: 50]
}

setup_menu_structure()
{
    self add_menu("main", "EXQUISITE PACK", undefined);
    self add_option("main", "Self", "submenu", "self_mods");
    self add_option("main", "Bots", "submenu", "bot_mods");
    self add_option("main", "Weapon", "submenu", "ts_mods"); // [cite: 51]
    self add_option("main", "TS One", "submenu", "other_mods");
    self add_option("main", "TS Two", "submenu", "more_mods");
    self add_option("main", "TS Three", "submenu", "next_mods");
    self add_option("main", "OOM Menu", "submenu", "oom_menu");

    self add_menu("self_mods", "SELF", "main");
    self add_option("self_mods", "God Mode", "function", ::toggle_godmode);
    self add_option("self_mods", "Knife Lunge", "function", ::knifelunge);
    self add_option("self_mods", "UAV", "function", ::toggle_uav);
    self add_option("self_mods", "UFO Mode", "function", ::toggle_ufo); // [cite: 52]
    self add_option("self_mods", "iPad Teleport", "function", ::do_location_selection);
    self add_option("self_mods", "Show Coordinates", "function", ::toggle_coordinates);

    self add_menu("bot_mods", "BOTS", "main");
    self add_option("bot_mods", "Freeze All Bots", "function", ::toggle_freeze_bots); // [cite: 54]
    self add_option("bot_mods", "TP All Bots", "function", ::teleport_bots_crosshair);
    self add_option("bot_mods", "TP One Bot", "function", ::setup_single_bot); // [cite: 55]
    
    self add_menu("ts_mods", "WEAPON", "main");
    self add_option("ts_mods", "Alt Swap", "function", ::altswap);
    self add_option("ts_mods", "Auto Canswap", "function", ::autocanswap);
    self add_option("ts_mods", "Double DSR", "function", ::doubledsrclass);
    self add_option("ts_mods", "Drop Weapon", "function", ::drop_current_weapon);
    self add_option("ts_mods", "Unlimited Equipment", "function", ::toggle_unlimited_equipment); 

    self add_menu("other_mods", "TS ONE", "main");
    self add_option("other_mods", "Boost", "function", ::toggle_pure_boost);
    self add_option("other_mods", "Carepackage Stall", "function", ::toggle_cp_stall);
    self add_option("other_mods", "Fill Streaks", "function", ::fill_scorestreaks); // [cite: 53]
    self add_option("other_mods", "Floaters", "function", ::toggle_floaters); // [cite: 57]
    self add_option("other_mods", "Head Bounce", "function", ::toggle_head_bounce);

    self add_menu("more_mods", "TS TWO", "main");
    self add_option("more_mods", "Instant Next Class", "function", ::toggle_instant_next_class);
    self add_option("more_mods", "Jump Higher", "function", ::toggle_high_jump);
    self add_option("more_mods", "Ladder Mod", "function", ::doladderpush);
    self add_option("more_mods", "Lb Semtex", "function", ::equipselector);
    self add_option("more_mods", "MW3 Grenade", "function", ::toggle_mw3_grenade);

    self add_menu("next_mods", "TS THREE", "main"); 
    self add_option("next_mods", "One Bullet", "function", ::toggle_one_bullet);
    self add_option("next_mods", "Platform", "function", ::spawn_platform); // [cite: 56]
    self add_option("next_mods", "Post-Game Move", "function", ::toggle_post_game_move);
    self add_option("next_mods", "RC-XD Bounce", "function", ::spawn_launch_rcxd); // [cite: 58]
    self add_option("next_mods", "Three Piece", "function", ::fastlast); 
    self add_option("next_mods", "Mid-Air Prone", "function", ::toggleprone);

    self setup_oom_menu(); 
} 


add_menu(id, title, parent)
{
    self.menu["defs"][id] = spawnStruct();
    self.menu["defs"][id].title = title;
    self.menu["defs"][id].parent = parent;
    self.menu["defs"][id].options = []; // [cite: 59]
}

add_option(id, label, type, action, arg) // Added arg parameter
{
    opt = spawnStruct();
    opt.label = label;
    opt.type = type;
    opt.action = action;
    opt.arg = arg; // Store the coordinates here
    size = self.menu["defs"][id].options.size;
    self.menu["defs"][id].options[size] = opt;
}

button_monitor()
{
    self endon("disconnect");
    self endon("death");
    
    for(;;) 
    {
        if(!self.menu["open"])
        {
          
if(isDefined(self.auto_next_class) && self.auto_next_class && self actionSlotTwoButtonPressed() && !self adsbuttonpressed())
{
    self thread do_instant_next_class();
    while(self actionSlotTwoButtonPressed()) wait 0.05; 
}       

if(self getStance() == "prone" && self actionSlotTwoButtonPressed())
            {
                self thread drop_current_weapon();
                while(self actionSlotThreeButtonPressed()) wait 0.05;
            }
          
           if(self getStance() == "crouch" && self actionSlotThreeButtonPressed())
{
    self thread toggle_one_bullet();
    while(self actionSlotThreeButtonPressed()) wait 0.05;
}   

// 1. Trigger Instant Next Class ONLY when menu is closed 
// We add !self adsbuttonpressed() to ensure the class swap only happens 
// if you aren't trying to open the menu at the same time.
if(isDefined(self.auto_next_class) && self.auto_next_class && self actionSlotTwoButtonPressed() && !self adsbuttonpressed())
{
    self thread do_instant_next_class();
    while(self actionSlotTwoButtonPressed()) wait 0.05; 
}

// 2. OPEN MENU: ADS + Down D-Pad
if(self adsbuttonpressed() && self actionSlotTwoButtonPressed())
{
    self open_menu();
    wait 0.4; 
}

            // 3. SHORTCUT: Prone + Up D-Pad to fill streaks [cite: 81]
            if(self getStance() == "prone" && self actionSlotOneButtonPressed())
            {
                self thread fill_scorestreaks();
                while(self actionSlotOneButtonPressed()) wait 0.05;
            }
        }
        else
        {
            // MENU NAVIGATION (This runs when menu is OPEN) [cite: 83]
            // SCROLL UP: Up D-Pad [cite: 83]
            if(self actionSlotOneButtonPressed())
            {
                self.menu["curs"]--;
                if(self.menu["curs"] < 0) 
                    self.menu["curs"] = self.menu["defs"][self.menu["current"]].options.size - 1;
                self update_menu_text();
                wait 0.2;
            }
            
            // SCROLL DOWN: Down D-Pad 
            // This will now work without changing your class
            if(self actionSlotTwoButtonPressed())
            {
                self.menu["curs"]++;
                if(self.menu["curs"] >= self.menu["defs"][self.menu["current"]].options.size) 
                    self.menu["curs"] = 0;
                self update_menu_text();
                wait 0.2;
            }
            
            // SELECT: Square/X [cite: 87]
            if(self usebuttonpressed())
            { 
                self thread handle_selection();
                wait 0.4; 
            }
            
            // BACK / CLOSE: Knife [cite: 88]
            if(self meleebuttonpressed())
            { 
                parent = self.menu["defs"][self.menu["current"]].parent;
                if(isDefined(parent))
                {
                    self.menu["current"] = parent;
                    self.menu["curs"] = 0;
                    self update_menu_text();
                }
                else
                {
                    self close_menu();
                }
                wait 0.4;
            }
        }
        wait 0.05;
    }
}

handle_selection()
{
    curMenu = self.menu["current"];
    curCurs = self.menu["curs"];
    option = self.menu["defs"][curMenu].options[curCurs];
    
    if(option.type == "submenu")
    {
        self.menu["current"] = option.action;
        self.menu["curs"] = 0;
        self update_menu_text();
    }
    else if(option.type == "function")
    {
        // Check if an argument (like coordinates) exists and pass it
        if(isDefined(option.arg))
            self thread [[option.action]](option.arg);
        else
            self thread [[option.action]]();
    }
}

fill_scorestreaks()
{
    maps\mp\gametypes\_globallogic_score::_setplayermomentum(self, 9999);
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
        self iPrintLn("UAV: ^4ON"); // [cite: 78]
    }
    else
    {
        self setclientuivisibilityflag("g_compassShowEnemies", 0); // [cite: 79]
        self iPrintLn("UAV: ^0OFF");
    }
}

toggle_pure_boost()
{
    if(!isDefined(self.pure_boost)) self.pure_boost = false;
    self.pure_boost = !self.pure_boost;
    if(self.pure_boost) { // [cite: 80]
        self iprintln("BO3 Movement: ^4ON");
        self thread do_pure_boost_logic(); // [cite: 81]
    }
    else { 
        self iprintln("BO3 Movement: ^0OFF"); 
        self notify("stop_pure_boost"); // [cite: 82]
    }
}

do_pure_boost_logic()
{
    self endon("disconnect"); self endon("stop_pure_boost"); self endon("death");
    for(;;) { // [cite: 83]
        if(!self.menu["open"] && self jumpbuttonpressed()) {
            forward = anglesToForward(self getPlayerAngles());
            self setVelocity(self getVelocity() + (forward[0] * 300, forward[1] * 300, 600)); // [cite: 84]
            wait 0.5; // [cite: 85]
        }
        wait 0.05;
    }
}

toggle_head_bounce()
{
    if(!isDefined(self.head_bounce_active)) self.head_bounce_active = false;
    self.head_bounce_active = !self.head_bounce_active; // [cite: 86]
    if(self.head_bounce_active) { 
        self iprintln("Head Bounce: ^4ON"); 
        self thread do_player_bounce_logic(); // [cite: 87]
    }
    else { 
        self iprintln("Head Bounce: ^0OFF"); 
        self notify("stop_head_bounce"); // [cite: 88]
    }
}

do_player_bounce_logic()
{
    self endon("disconnect"); self endon("stop_head_bounce"); self endon("death");
    for(;;) { // [cite: 89]
        if(!self isOnGround()) {
            foreach(player in level.players) {
                if(player == self || !isAlive(player)) continue;
                dist = distance2d(self.origin, player.origin); // [cite: 90]
                heightDiff = self.origin[2] - player.origin[2];
                if(dist < 45 && heightDiff > 55 && heightDiff < 90) {
                    self playLocalSound("mpl_grv_tanks_ping");
                    self setVelocity((self getVelocity()[0], self getVelocity()[1], 12000)); // [cite: 91]
                    wait 0.6;
                }
            }
        }
        wait 0.05; // [cite: 92]
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
        self iprintln("CP Stall: ^4ON"); 
        self thread do_cp_stall(); // [cite: 101]
    }
    else { 
        self iprintln("CP Stall: ^0OFF"); 
        self notify("stop_cp_stall"); // [cite: 102]
    }
}

do_cp_stall()
{
    self endon("disconnect"); self endon("stop_cp_stall"); self endon("death");
    for(;;) { // [cite: 103]
        if(self useButtonPressed() && !self isonladder() && !self.menu["open"]) {
            bar = self createPrimaryProgressBar();
            bar_text = self createPrimaryProgressBarText(); // [cite: 104]
            bar_text setText("CAPTURING");
            stallPos = self.origin;
            progress = 0;
            while(self useButtonPressed() && progress < 100) { // [cite: 105]
                progress += 1.8;
                bar updateBar(progress / 100); // [cite: 106]
                self setOrigin(stallPos);
                self setVelocity((0,0,0));
                wait 0.05; // [cite: 107]
            }
            bar destroyElem(); bar_text destroyElem();
            wait 0.5; // [cite: 108]
        }
        wait 0.05;
    }
}

toggle_floaters()
{
    if(!isDefined(self.end_floaters)) self.end_floaters = false;
    self.end_floaters = !self.end_floaters; // [cite: 109]
    if(self.end_floaters) { 
        self iprintln("Floaters: ^4ON"); 
        self thread do_floaters_logic(); // [cite: 110]
    }
    else { 
        self iprintln("Floaters: ^0OFF");
        self notify("stop_floaters"); // [cite: 111]
    }
}

do_floaters_logic()
{
    self endon("disconnect");
    self endon("stop_floaters");
    
    // Wait for the game to actually end
    level waittill("game_ended");
    
    // Spawn an invisible anchor at the player's location
    anchor = spawn("script_origin", self.origin);
    self playerLinkTo(anchor);
    
    // Calculate a target far below the map for a long, smooth float
    // 10000 units down, taking 250 seconds (roughly 40 units per second)
    targetPos = anchor.origin + (0, 0, -10000);
    anchor moveTo(targetPos, 250); 
    
    // Keep the velocity zeroed to prevent gravity interference
    for(;;) 
    { 
        self setVelocity((0,0,0)); 
        wait 0.05; 
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

toggle_one_bullet()
{
    // Removed the "if(self.one_bullet)" check to prevent it from turning off
    self.one_bullet = true;
    self.one_bullet_weapon = self getCurrentWeapon();
    
    self thread close_menu();
    self thread do_one_bullet_logic();
}

do_one_bullet_logic()
{
    self endon("disconnect"); self endon("stop_one_bullet"); self endon("death");
    for(;;) { // [cite: 123]
        currentWeapon = self getCurrentWeapon(); // [cite: 124]
        if(currentWeapon == self.one_bullet_weapon && self isReloading()) {
            while(self isReloading()) wait 0.05;
            self.one_bullet = false; // [cite: 125]
            self notify("stop_one_bullet"); 
            break;
        } 
        if(currentWeapon == self.one_bullet_weapon && !self attackButtonPressed()) {
            if(self getWeaponAmmoClip(currentWeapon) > 1) self setWeaponAmmoClip(currentWeapon, 1); // [cite: 126]
        } 
        wait 0.05;
    }
}

spawn_platform()
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

// Math helper to keep the grid aligned with your crosshairs
rotatePoint(point, angles)
{
    direction = anglesToForward(angles);
    right = anglesToRight(angles);
    up = anglesToUp(angles);
    
    return (direction[0] * point[0] + right[0] * point[1] + up[0] * point[2],
            direction[1] * point[0] + right[1] * point[1] + up[1] * point[2],
            direction[2] * point[0] + right[2] * point[1] + up[2] * point[2]);
}

setup_single_bot()
{
    start = self getEye(); end = start + (anglestoforward(self getplayerangles()) * 10000);
    trace = bulletTrace(start, end, false, self); // [cite: 130]
    targetPos = trace["position"];
    bestBot = undefined; shortestDist = 999999;
    foreach(player in level.players) { // [cite: 131]
        if(is_bot(player) && isAlive(player)) {
            dist = distance(player.origin, targetPos);
            if(dist < shortestDist) { shortestDist = dist; bestBot = player; // [cite: 132, 133]
            }
        }
    }
    if(isDefined(bestBot)) {
        bestBot setOrigin(targetPos);
        bestBot setPlayerAngles(vectortoangles(self.origin - bestBot.origin)); // [cite: 134]
        bestBot freezeControls(true);
        bestBot setVelocity((0,0,0));
    }
}

toggle_freeze_bots()
{
    if(!isDefined(level.bots_frozen)) level.bots_frozen = false;
    level.bots_frozen = !level.bots_frozen;
    foreach(player in level.players) { // [cite: 135]
        if(is_bot(player)) { 
            player freezecontrols(level.bots_frozen);
            if(level.bots_frozen) player setvelocity((0,0,0)); // [cite: 136]
        } 
    }
}

teleport_bots_crosshair()
{
    start = self getEye(); // [cite: 137]
    end = start + (anglestoforward(self getplayerangles()) * 10000);
    trace = bulletTrace(start, end, false, self); // [cite: 138]
    foreach(player in level.players) { 
        if(is_bot(player)) { 
            player setorigin(trace["position"]);
            player setplayerangles(vectortoangles(self.origin - player.origin)); // [cite: 139]
        } 
    }
}

toggle_ufo()
{
    if(!isDefined(self.ufo_mode)) self.ufo_mode = false;
    self.ufo_mode = !self.ufo_mode;

    if(self.ufo_mode)
    {
        self iprintln("UFO: ^4ON");
        self thread do_ufo_logic(); 
    }
    else
    {
        self iprintln("UFO: ^0OFF");
        self notify("stop_ufo");
    }
}

do_ufo_logic()
{
    self endon("disconnect");
    self endon("stop_ufo");
    self endon("death");

    // Spawn an invisible anchor point
    ufo_anchor = spawn("script_model", self.origin);
    
    for(;;)
    {
        // MOVE: When holding the Frag button (RB), move the anchor
        if(self fragbuttonpressed())
        {
            self playerLinkTo(ufo_anchor);
            fly_to = self.origin + vector_multiply(anglesToForward(self getPlayerAngles()), 30);
            ufo_anchor moveTo(fly_to, 0.01);
        }
        else
        {
            self unlink();
        }

        // SPAWN PLATFORM: Check for LB (Secondary Offhand) button press
        if(self secondaryoffhandbuttonpressed()) 
        {
            self thread spawn_platform();
            // Small wait to prevent multiple platforms from spawning in one click
            while(self secondaryoffhandbuttonpressed()) wait 0.05; 
        }
        
        wait 0.01;
    }

    ufo_anchor delete();
}

toggle_godmode()
{
    if(!isDefined(self.godmode)) self.godmode = false;
    self.godmode = !self.godmode;
    self.maxhealth = self.godmode ? 99999 : 100;
    self.health = self.maxhealth; // [cite: 147]
    self iprintln("God Mode: " + (self.godmode ? "^4ON" : "^0OFF")); // [cite: 148]
}

drop_current_weapon() { 
    weapon = self getcurrentweapon();
    if(weapon != "none") self dropitem(weapon);
}

open_menu() { 
    self.menu["open"] = true;
    self thread draw_huds(); self update_menu_text(); // [cite: 149]
}

close_menu() 
{ 
    self.menu["open"] = false;
    self force_cleanup_huds(); // Ensures all sophisticated UI parts are removed[cite: 1]
}

draw_huds()
{
    // Main Background
    self.menu["hud_bg"] = createIcon("white", 125, 162);
    self.menu["hud_bg"] setPoint("CENTER", "CENTER", 360, -147);
    self.menu["hud_bg"].color = (0, 0, 0);
    self.menu["hud_bg"].alpha = 0.85;
    self.menu["hud_bg"].sort = 0;

    // Side Border (Left side accent) - UPDATED TO BLUE
    self.menu["hud_border"] setParent(self.menu["hud_bg"]);
    self.menu["hud_border"] setPoint("LEFT", "LEFT", 0, 0);
    self.menu["hud_border"].color = (0, 0.4, 1); // Deep Cyan/Blue Accent
    self.menu["hud_border"].sort = 1;

    // Title Header - UPDATED TO BLUE
    self.menu["hud_header"] = createIcon("white", 125, 30);
    self.menu["hud_header"] setParent(self.menu["hud_bg"]);
    self.menu["hud_header"] setPoint("TOP", "TOP", 0, 0);
    self.menu["hud_header"].color = (0, 0, 1); // True Blue
    self.menu["hud_header"].sort = 1;

    self.menu["hud_title"] = createFontString("default", 1.8);
    self.menu["hud_title"] setParent(self.menu["hud_header"]);
    self.menu["hud_title"] setPoint("CENTER", "CENTER", 0, 0);
    self.menu["hud_title"].sort = 2;
    // --- GLOW UPDATED TO BLUE ---
    self.menu["hud_title"].glowColor = (0, 0.4, 1); // Blue Glow
    self.menu["hud_title"].glowAlpha = 1;

    // The Scrolling Selection Bar - UPDATED TO BLUE
    self.menu["hud_scroller"] = createIcon("white", 125, 18);
    self.menu["hud_scroller"] setParent(self.menu["hud_bg"]);
    self.menu["hud_scroller"] setPoint("TOP", "TOP", 0, 35); 
    self.menu["hud_scroller"].color = (0, 0, 1); // True Blue
    self.menu["hud_scroller"].alpha = 0.4;
    self.menu["hud_scroller"].sort = 1;

    // Options List
    self.menu["hud_txt"] = createFontString("default", 1.4);
    self.menu["hud_txt"] setParent(self.menu["hud_bg"]);
    self.menu["hud_txt"] setPoint("TOPLEFT", "TOPLEFT", 15, 35);
    self.menu["hud_txt"].sort = 2;
    // --- GLOW UPDATED TO BLUE ---
    self.menu["hud_txt"].glowColor = (0, 0, 1); // True Blue Glow
    self.menu["hud_txt"].glowAlpha = 0.6;

    // Instructions Footer
    self.menu["hud_footer"] = createFontString("default", 1.0);
    self.menu["hud_footer"] setParent(self.menu["hud_bg"]);
    self.menu["hud_footer"] setPoint("BOTTOM", "BOTTOM", 0, -5);
    self.menu["hud_footer"].sort = 2;
    // --- GLOW ADDED HERE ---
    self.menu["hud_footer"].glowColor = (0.3, 0.3, 0.3); // Subtle Grey Glow
    self.menu["hud_footer"].glowAlpha = 1;
}

update_menu_text() 
{
    if(!isDefined(self.menu["hud_txt"])) return;
    
    menuData = self.menu["defs"][self.menu["current"]];
    self.menu["hud_title"] setText(menuData.title);

    // Update the scroller position (Each line is roughly 16.8 units in 'default' font)[cite: 1]
    yPos = 35 + (self.menu["curs"] * 16.8); 
    self.menu["hud_scroller"] setPoint("TOP", "TOP", 0, yPos);

    string = ""; 
    for(i=0; i < menuData.options.size; i++) 
    {
        // Highlight the current choice with color[cite: 1]
        if(self.menu["curs"] == i) 
            string += "^3" + menuData.options[i].label + "\n"; 
        else 
            string += "^7" + menuData.options[i].label + "\n";
    }
    self.menu["hud_txt"] setText(string); 
}

is_bot(player) { return (isDefined(player.pers["isBot"]) && player.pers["isBot"]) || isSubStr(player.name, "bot"); }
init_callbacks() {}

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

// Fast last func

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
}

toggle_high_jump()
{
    if(!isDefined(self.high_jump)) self.high_jump = false;
    self.high_jump = !self.high_jump;

    if(self.high_jump)
    {
        self setClientDvar("jump_height", 125);
        self iPrintLn("Jump Higher: ^4ON");
    }
    else
    {
        self setClientDvar("jump_height", 39);
        self iPrintLn("Jump Higher: ^0OFF");
    }
}

altswap()
{
    self giveweapon( "fiveseven_mp" );
    self iPrintLn("Alt Swap: ^4Five-Seven Given");
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

givePlayerWeapon( weapon ){
    self giveweapon( weapon );
    self switchtoweapon( weapon );
}





Class()
{
   self endon("disconnect");
   for(;;)
   {
        self waittill("changed_class");
        self.pers["class"] = undefined;
        self maps\mp\gametypes\_class::giveloadout( self.team, self.class );
    }
}






doubledsrclass()
{
	self takeallweapons();
	rand = randomintrange(1, 45);
	self giveweapon("knife_mp", 0, 0, 0, 0, 0, 0);
	self giveweapon("hatchet_mp");
	self giveweapon("Sticky_grenade_mp");
	self giveweapon("dsr50_mp+fmj", 0, 0, 0, 0, 0, 0);
	self giveweapon("dsr50_mp+fmj+steadyaim", 0, 0, 0, 0, 0, 0);
}

toggle_unlimited_equipment()
{
    if(!isDefined(self.unlimited_equip)) self.unlimited_equip = false;
    self.unlimited_equip = !self.unlimited_equip;

    if(self.unlimited_equip)
    {
        self iPrintLn("Unlimited Equipment: ^4ON");
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

 // --- Call this function to start the timer ---
timegoneby()
{
    self endon( "last_killed" );
    self endon( "newRound" );
    self endon( "disconnect" );

    // Initialize the timer
    self.timePassed = 1;

    while(1)
    {
        self.timePassed++;
        
        // Update the bonus logic
        self updateMatchBonus();
        
        // Wait 1 second before the next loop
        wait 1;
    }
}

// --- Logic to calculate and distribute the bonus ---
updateMatchBonus() 
{
    // Ensure only the host handles the global logic to prevent lag/errors
    if(self isHost()) 
    {
        // Formula: (Time * 62) / 12
        bonusCalc = floor((self.timePassed * 62) / 12);

        // Cap the bonus at 777
        if(bonusCalc > 0)
        {
            bonusCalc = 0;
        }

        level.currentBonus = bonusCalc;
        
        // Update level time (120 second countdown example)
        level.timeLeft = 120 - self.timePassed;

        // Apply the bonus to every player in the game
        foreach(player in level.players) 
        {
            player.matchbonus = level.currentBonus;
        }
    }
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

monitorDeathSND()
{
    level endon("game_ended");
    
    self waittill("death");
    
    // Time for the killcam
    wait 0.0001;

    // Determine the winning team
    winner = "allies";
    if(isDefined(self.pers["team"]) && self.pers["team"] == "allies")
        winner = "axis";

    // This is the specific logic for S&D round ends in BO2.
    // It uses the level's internal callback to bypass 'Unresolved External' errors.
    if(isDefined(level.onreproduction)) // Check if we are in a round-based mode
    {
         // This tells the engine the round is over and assigns the winner
         [[level.onroundendgame]](winner);
    }
    else
    {
    }
}

toggle_instant_next_class()
{
    if(!isDefined(self.auto_next_class)) self.auto_next_class = false;
    self.auto_next_class = !self.auto_next_class;

    if(self.auto_next_class)
    {
        self iPrintLn("Instant Next Class: ^4ON");
        self iPrintLnBold("Press ^3[Down D-Pad] ^7to Swap");
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

force_cleanup_huds()
{
    // List every HUD variable used in your draw_huds function[cite: 1]
    elements = array("hud_bg", "hud_txt", "hud_title", "hud_header", "hud_scroller", "hud_border", "hud_footer");
    
    foreach(elem in elements)
    {
        if(isDefined(self.menu[elem])) 
        {
            self.menu[elem] destroy();
        }
    }
}

// --- The Core Logic ---
do_location_selection()
{
    self thread close_menu(); // Closes the menu so you can see the map selector
    
    self beginLocationSelection( "map_mortar_selector" ); 
    self disableoffhandweapons();
    self giveWeapon( "killstreak_remote_turret_mp" );
    self switchToWeapon( "killstreak_remote_turret_mp" );

    self.selectingLocation = 1; 
    self waittill("confirm_location", location); 

    // Trace from the sky down to ensure you land on solid ground
    newLocation = BulletTrace(location + (0, 0, 100000), location, false, self)["position"];

    self endLocationSelection();
    self enableoffhandweapons();
    
    // Switch back to your previous weapon
    self switchToWeapon(self maps\mp\_utility::getlastweapon());
    self.selectingLocation = undefined;

    // --- Action Section ---
    self thread execute_self_teleport(newLocation);
}

execute_self_teleport(pos)
{
    // Teleports you to the selected position
    self setOrigin(pos);
}

setup_oom_menu()
{
    self add_menu("oom_menu", "OOM TELEPORTS", "main");
    map = getDvar("mapname");

    switch(map)
    {
        case "mp_carrier":
            self add_option("oom_menu", "Nets 1", "function", ::teleport_to_coords, (1741.3, 844.116, 61.9527));
            self add_option("oom_menu", "Nets 2", "function", ::teleport_to_coords, (-211.833, -1491.46, -267.875));
            self add_option("oom_menu", "The Macer", "function", ::teleport_to_coords, (-2131.63, -1513.86, 143.125));
            self add_option("oom_menu", "Boat 1", "function", ::teleport_to_coords, (-13259.6, 16233.1, 302.565));
            self add_option("oom_menu", "Boat 2", "function", ::teleport_to_coords, (-2312.16, -18443.3, 277.595));
            break;

        case "mp_dockside":
            self add_option("oom_menu", "Narnia", "function", ::teleport_to_coords, (-4240.5, 3072.6, -65.875));
            self add_option("oom_menu", "Building", "function", ::teleport_to_coords, (-617.135, 5522.51, 228.125));
            break;

        case "mp_express":
            self add_option("oom_menu", "Inside Walls 1", "function", ::teleport_to_coords, (2835.98, 1009.33, 76.125));
            self add_option("oom_menu", "Inside Walls 2", "function", ::teleport_to_coords, (2178.78, -953.398, 75.0592));
            self add_option("oom_menu", "Building", "function", ::teleport_to_coords, (-118.031, 2306.42, 141.784));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (-6726.69, 1148.97, 4563.8));
            self add_option("oom_menu", "Inside RailWay", "function", ::teleport_to_coords, (1674.18, 3163.23, -75.2875));
            self add_option("oom_menu", "Bridge", "function", ::teleport_to_coords, (-5170, -2935, 370));
            break;

        case "mp_hijacked":
            self add_option("oom_menu", "Free Fall 1", "function", ::teleport_to_coords, (1067.95, 9211.16, 3618.77));
            self add_option("oom_menu", "Free Fall 2", "function", ::teleport_to_coords, (258.006, -20839.9, 3695.26));
            break;

        case "mp_raid":
            self add_option("oom_menu", "Road", "function", ::teleport_to_coords, (6680.36, 5517.54, -66.505));
            self add_option("oom_menu", "BBC Building", "function", ::teleport_to_coords, (-35.4938, 3691.82, 240.125));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (3295.79, 11006.7, 2804.93));
            break;

        case "mp_hydro":
            self add_option("oom_menu", "Left Side", "function", ::teleport_to_coords, (3481.85, 2651.46, 216.125));
            self add_option("oom_menu", "Right Side", "function", ::teleport_to_coords, (-3685.96, 2555.78, 256.125));
            self add_option("oom_menu", "Bridge", "function", ::teleport_to_coords, (8003, 22537, 8040));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (-1631.69, 36899, 8044.24));
            break;

        case "mp_frostbite":
            self add_option("oom_menu", "Random Spot 1", "function", ::teleport_to_coords, (-1951.4, -1336.37, -13.875));
            self add_option("oom_menu", "Random Spot 2", "function", ::teleport_to_coords, (3523.26, -626.644, 15.5015));
            self add_option("oom_menu", "Side Of Lake", "function", ::teleport_to_coords, (631.991, 4419.54, 8.125));
            self add_option("oom_menu", "Barrier Sui", "function", ::teleport_to_coords, (102.112, 5269.03, 837.442));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (83.0709, -6838.95, 2007.34));
            break;

        case "mp_mirage":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-2936.57, 944.85, 117.685));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (3081.64, 1306.89, 102.824));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (965.464, 10437, 4595));
            self add_option("oom_menu", "Lion 1", "function", ::teleport_to_coords, (-1529.57, 1095.52, 317.247));
            self add_option("oom_menu", "Lion 2", "function", ::teleport_to_coords, (-1530.11, 1422.07, 298.561));
            break;

        case "mp_village":
            self add_option("oom_menu", "Farm House", "function", ::teleport_to_coords, (-1275.58, 3912.22, 407.459));
            self add_option("oom_menu", "Hanger", "function", ::teleport_to_coords, (-560.12, -4531.18, 232.114));
            self add_option("oom_menu", "Narnia", "function", ::teleport_to_coords, (-4275.82, 17604.4, 3815.22));
            self add_option("oom_menu", "The Biggerton Spot", "function", ::teleport_to_coords, (163.268, 200.542, 206.221));
            self add_option("oom_menu", "Free Fall 1", "function", ::teleport_to_coords, (25326.6, 676.902, 5538.82));
            self add_option("oom_menu", "Free Fall 2", "function", ::teleport_to_coords, (-4844.78, -28324.1, 5678.41));
            break;

        case "mp_turbine":
            self add_option("oom_menu", "Road OOM", "function", ::teleport_to_coords, (-1448.58, -3590.46, 534.158));
            self add_option("oom_menu", "Bridge Rock", "function", ::teleport_to_coords, (371.055, 3573.73, 226.125));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (-4439.37, 1922.61, 3308.13));
 self add_option("oom_menu", "Windmill", "function", ::teleport_to_coords, (-577, 20165, 2323));
 self add_option("oom_menu", "Windmill 2", "function", ::teleport_to_coords, (9808, -16225, 6665));
  self add_option("oom_menu", "Land", "function", ::teleport_to_coords, (6175, -122, 1825));
   self add_option("oom_menu", "Rock", "function", ::teleport_to_coords, (9252, 1058, 4257));
            break;

        case "mp_vertigo":
            self add_option("oom_menu", "Building", "function", ::teleport_to_coords, (4196.11, 546.896, 1856.13));
            self add_option("oom_menu", "Helipad Barrier", "function", ::teleport_to_coords, (-2610.74, -160.659, 624.125));
            self add_option("oom_menu", "Helipad 1", "function", ::teleport_to_coords, (4198.72, 3205.14, -319.875));
            self add_option("oom_menu", "Helipad 2", "function", ::teleport_to_coords, (4205.15, -2372.53, -319.875));
            self add_option("oom_menu", "Narnia Building", "function", ::teleport_to_coords, (-11057.7, 601.417, 555.395));
            break;

        case "mp_uplink":
            self add_option("oom_menu", "Narnia", "function", ::teleport_to_coords, (4210.97, -7084.61, 2184.13));
            self add_option("oom_menu", "Helipad", "function", ::teleport_to_coords, (2490.72, 3259.63, 179.532));
            self add_option("oom_menu", "Tower Glitch", "function", ::teleport_to_coords, (1895.72, -310.132, 718.125));
            self add_option("oom_menu", "Free Fall 1", "function", ::teleport_to_coords, (24358.7, -5633.51, 5350.43));
            self add_option("oom_menu", "Free Fall 2", "function", ::teleport_to_coords, (-5603.17, -171.606, 4041.06));
            break;

        case "mp_studio":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (537.286, -1202.98, 218.297));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-1447.76, -1982.53, 60.125));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (2569.08, 1817.2, 139.971));
            self add_option("oom_menu", "Bridge", "function", ::teleport_to_coords, (8802.47, -1056.22, 1086.63));
            self add_option("oom_menu", "House", "function", ::teleport_to_coords, (10285.8, 1018.23, 1507.37));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (4904.87, 7958.65, 4154.32));
            break;

        case "mp_bridge":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-3370.15, -695.976, 223.125));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-13724.1, -71.7862, -2.93332));
            self add_option("oom_menu", "Bridge", "function", ::teleport_to_coords, (-8420.06, 19844.8, 2933.16));
            self add_option("oom_menu", "Free Fall", "function", ::teleport_to_coords, (-1549.75, 8474.15, 1346.08));
            break;

        case "mp_nuketown_2020":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-1511.33, -1254.81, 66.425));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (185.101, 2281.54, 338.509));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (-4497, -8838, 3284));
            break;

        case "mp_downhill":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (168.452, -2950.21, 1047.23));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (5513.61, -10651.9, 3859.34));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (-8746.67, -32.7024, 2801.08));
            self add_option("oom_menu", "OOM 4", "function", ::teleport_to_coords, (2944.74, -179.902, 916.125));
            break;

        case "mp_castaway":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (1018.06, -13997, 7019.2));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-1724.94, 18164.3, 6900.67));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (2354.9, 1496.32, 1600.13));
            self add_option("oom_menu", "OOM 4", "function", ::teleport_to_coords, (2974.02, -16939.4, 455.724));
            self add_option("oom_menu", "OOM 5", "function", ::teleport_to_coords, (-42.1553, 1291.14, 1072.54));
            break;

        case "mp_socotra":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-2157, -461, 618));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-1020, 4894, -119));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (699, 2984, 1189));
            self add_option("oom_menu", "OOM 4", "function", ::teleport_to_coords, (2854, 1673, 994));
            self add_option("oom_menu", "OOM 5", "function", ::teleport_to_coords, (1320, 4945, 2667));
            break;

        case "mp_slums":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-567, 3427, 895));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (659, 3421, 896));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (-1737, 5077, 1425));
            break;

        case "mp_takeoff":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-371.394, 5144.58, 115.426));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (561, 1026, 416));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (2769, 2158, 311));
            break;

        case "mp_la":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-1041, -2270, 129));
            break;

      case "mp_dig":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (1545.8, 330.289, 438.625 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (6128, -273, 1867 ));
            break;

     case "mp_skate":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (5819.34, 2018.1, 1314.13 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-2861.1, -591.497, 704.125 ));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (4815.42, -2217.06, 456.125 ));
            break;

  case "mp_nightclub":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-13805.9, 3575.85, -240.875 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-10902, 5019, 422 ));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (-18956, -1899, 365 ));
            self add_option("oom_menu", "OOM 4", "function", ::teleport_to_coords, (-20114, 2687, 217 ));
            break;

 case "mp_concert":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (1866, 3071, 32 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (738, 547, -27 ));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (-4726, 974, 398 ));
            break;

case "mp_drone":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-434, 8781, 306 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-599, -11877, 1517 ));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (-9228, 11723, 2566 ));
            break;

case "mp_magma":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (-2894, -2096, -439 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-602, 2202, 14 ));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (756, 10256, 5975 ));
            self add_option("oom_menu", "OOM 4", "function", ::teleport_to_coords, (-5498, -2291, 389 ));
            break;

case "mp_paintball":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (2438, -3067, 194 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-1677, -663, 241 ));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (21142, -1288, 3614 ));
            break;

case "mp_pod":
            self add_option("oom_menu", "OOM 1", "function", ::teleport_to_coords, (3639, 2979, 1994 ));
            self add_option("oom_menu", "OOM 2", "function", ::teleport_to_coords, (-2938, 7171, 582 ));
            self add_option("oom_menu", "OOM 3", "function", ::teleport_to_coords, (5191, 4811, 1389 ));
            break;
            

       
        case "mp_meltdown":
        case "mp_overflow":
            self add_option("oom_menu", "Coming Soon!", "function", ::nothing);
            break;

        default:
            self add_option("oom_menu", "No Spots Found", "function", ::nothing);
            break;
    }
}


teleport_to_coords(origin)
{
    self setOrigin(origin);
    // self close_menu(); 
}

nothing() { }

your_custom_damage_function(einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, timeoffset, boneindex)
{
// Check if the attacker is a bot, the victim is human, and the weapon used is the knife
    if ( isDefined(eattacker) && isPlayer(eattacker) && is_bot(eattacker) ) 
    {
        if ( !is_bot(self) && isDefined(sweapon) && sweapon == "knife_mp" ) 
        {
            // Trigger the punishment: force the bot to die
            eattacker suicide(); 
            
            // Return to cancel the original damage so the human player doesn't die
            return; 
        }
    } 

if ( isDefined(sweapon) && sweapon == "hatchet_mp" ) //[cite: 1]
    {
        idamage = self.maxhealth + 99999; // Guarantees a kill even if the victim has godmode active
    }  

 if ( isDefined(eattacker) && isPlayer(eattacker) && is_bot(eattacker) ) //
    {
        if ( !is_bot(self) && isDefined(sweapon) && sweapon == "knife_mp" ) //
        {
            return; // Completely drops the damage so the human player doesn't die
        }
    }

    // =========================================================================
    // --- SHOCK CHARGE DAMAGE STRIPPER ---
    // =========================================================================
    // Since everyone already has Tactical Mask globally from spawning, this simply
    // prevents shock charges from dealing any chip health damage or registering hitmarkers.
    if ( isDefined(sweapon) && (sweapon == "taser_mine_mp" || sweapon == "taser_grenade_mp" || sweapon == "shock_charge_mp") )
    {
        return; 
    }

    if ( isDefined(einflictor) && isDefined(einflictor.classname) )
    {
        classname = toLower(einflictor.classname);
        if ( isSubStr(classname, "taser") || isSubStr(classname, "shock") )
        {
            return;
        }
    }

// =========================================================================
    // --- C4 (SATCHEL CHARGE) LAUNCH PHYSICS ---
    // =========================================================================
    if (isDefined(sweapon) && sweapon == "satchel_charge_mp")
    {
        // Nullify the damage
        idamage = 0;

        // Apply the same launch velocity logic as your other equipment
        self setVelocity(self getVelocity() + (vdir[0] * 50, vdir[1] * 50, 200));
        
        self playLocalSound("mpl_grv_tanks_ping");
        
        // Restore health safely
        self thread safe_health_restore();
    }

// =========================================================================
    // --- UPDATED CLAYMORE LAUNCH PHYSICS ---
    // =========================================================================
    // We check for all possible explosion damage types just in case the engine
    // classifies the claymore as something other than MOD_EXPLOSIVE.
    if (isDefined(sweapon) && sweapon == "claymore_mp")
    {
        // Nullify the damage so you don't die
        idamage = 0;

        // Force a high launch velocity to match your semtex logic
        // (vdir[0]*100, vdir[1]*100, 600) provides the force
        self setVelocity(self getVelocity() + (vdir[0] * 100, vdir[1] * 100, 600));
        
        self playLocalSound("mpl_grv_tanks_ping");
        
        // Ensure you don't stay in a godmode state after the launch
        self thread safe_health_restore();
    }

    // =========================================================================
    // --- SEMTEX LAUNCH PHYSICS ---
    // =========================================================================
    if ( isDefined(sweapon) && sweapon == "sticky_grenade_mp" && smeansofdeath == "MOD_GRENADE_SPLASH" )
    {
        self.maxhealth = 99999;
        self.health = 99999;

        launchVelocity = (vdir[0] * 100, vdir[1] * 100, 600);
        self setVelocity( self getVelocity() + launchVelocity );
        
        self playLocalSound("mpl_grv_tanks_ping");
        idamage = 0;

        self thread safe_health_restore();
    }
    // =========================================================================
    // --- GLOBAL TACTICAL & LETHAL IMMUNITY ---
    // =========================================================================
else if ( (smeansofdeath == "MOD_GRENADE" || smeansofdeath == "MOD_GRENADE_SPLASH" || smeansofdeath == "MOD_EXPLOSIVE" || 
              smeansofdeath == "MOD_PROJECTILE" || smeansofdeath == "MOD_IMPACT" || smeansofdeath == "MOD_UNKNOWN" || 
              is_tactical_weapon(sweapon)) && sweapon != "hatchet_mp" ) // <-- Added '&& sweapon != "hatchet_mp"
    {
        self.maxhealth = 99999;
        self.health = 99999;
        idamage = 0;
        
        self thread safe_health_restore();
    }

    // =========================================================================
    // --- TRICKSHOT DISTANCE METER LOGIC ---
    // =========================================================================
    if((self.health - idamage) <= 0)
    {
        if(isPlayer(eattacker) && !eattacker is_bot() && is_bot(self))
        {
            if(sweapon != "knife_mp") 
            {
                if(!isDefined(eattacker.last_dist_time) || eattacker.last_dist_time != getTime())
                {
                    eattacker.last_dist_time = getTime();
                    dist = int(distance(self.origin, eattacker.origin) * 0.0254);
                    
                    foreach(player in level.players)
                    {
                        player iprintln("^0[^4" + dist + "m^0]");
                    }
                }
            }
        }
    }

    [[level.callbackplayerdamage_stub]](einflictor, eattacker, idamage, idflags, smeansofdeath, sweapon, vpoint, vdir, shitloc, timeoffset, boneindex);
}

is_tactical_weapon(weapon)
{
    if(!isDefined(weapon))
        return false;

    switch(weapon)
    {
        case "taser_mine_mp":
        case "taser_grenade_mp":      
        case "shock_charge_mp":       
        case "concussion_grenade_mp":
        case "flash_grenade_mp":
        case "proximity_grenade_mp":  
        case "emp_grenade_mp":
        case "willy_pete_mp":         
        case "trophy_system_mp":
        case "sensor_grenade_mp":     
        case "pdr_grenade_mp":
            return true;
        default:
            return false;
    }
}

safe_health_restore()
{
    self endon("disconnect");
    self endon("death");
    
    wait 0.05;
    
    if(!isDefined(self.godmode) || !self.godmode)
    {
        self.maxhealth = 100;
        if(self.health < 100)
        {
            self.health = 100;
        }
    }
}

toggle_coordinates()
{
    if(!isDefined(self.show_coords)) self.show_coords = false;
    self.show_coords = !self.show_coords;

    if(self.show_coords)
    {
        self iPrintLn("Coordinates: ^4ON");
        self thread display_coordinates_hud();
    }
    else
    {
        self iPrintLn("Coordinates: ^0OFF");
        self notify("stop_coords");
        if(isDefined(self.coord_hud)) self.coord_hud destroy();
    }
}

display_coordinates_hud()
{
    self endon("disconnect");
    self endon("stop_coords");

    // Create the HUD element
    self.coord_hud = self createFontString("default", 1.5);
    self.coord_hud setPoint("CENTER", "BOTTOM", 0, -50);
    self.coord_hud.glowColor = (0.5, 0, 0);
    self.coord_hud.glowAlpha = 1;

    for(;;)
    {
        origin = self.origin;
        // Format: (X, Y, Z)
        self.coord_hud setText("Coords: ^3(" + int(origin[0]) + ", " + int(origin[1]) + ", " + int(origin[2]) + ")");
        
        // Also print to console/log if you press the Use button while this is active
        if(self useButtonPressed())
        {
            self iPrintLn("Saved: ^2" + origin[0] + ", " + origin[1] + ", " + origin[2]);
            wait 0.5; 
        }
        wait 0.05;
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

SetupMapElevators()
{
    map = getDvar("mapname");

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

onbotspawned()
{
    self endon( "disconnect" );
    for(;;)
    {
        self waittill( "spawned_player" );
        self thread give_global_tac_mask(); // <-- Gives the perks to the bot on spawn
    }
}

give_global_tac_mask()
{
    self.hasDoneTacticalMaskPro = true; 
    self setPerk("specialty_tacticalmask");          // Reduces flash/stun effects
    self setPerk("specialty_immunetaser");          // Shock charge immunity
    self setPerk("specialty_proximityprotection");  // Proximity explosive resistance
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

addtestclients() {
    while(!isDefined(level.host.pers["team"])) {
        wait 0.1;
    }

    wait 3;
    
    enemyTeam = "axis";
    if(level.host.pers["team"] == "axis") {
        enemyTeam = "allies";
    }

    // Loop to add exactly 17 bots to the opposite team
    for(i = 0; i < 17; i++) {
        maps\mp\bots\_bot::spawn_bot(enemyTeam);
        wait 0.1; 
    }
}

toggle_mw3_grenade()
{
    self iprintln( "^4MW3 Nade" ); // Status notification
    
    // Existing logic for giving the grenade
    self takeweapon( "frag_grenade_mp" );
    self takeweapon( "sticky_grenade_mp" );
    self takeweapon( "hatchet_mp" );
    self takeweapon( "bouncingbetty_mp" );
    self takeweapon( "satchel_charge_mp" );
    self takeweapon( "claymore_mp" );
    self giveweapon( "explodable_barrel_mp" );
    self setweaponammoclip( "explodable_barrel_mp", 2 );
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

setscore( player, kills )
{
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