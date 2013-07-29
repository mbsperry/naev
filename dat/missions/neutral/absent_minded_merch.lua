--[[

   MISSION: Absent-minded Merchant
   DESCRIPTION: From the wiki mission ideas. A merchant with a slow ship suddenly realizes he can't make the delivery and implores the player (with a fast ship presumed) to do it for him. Since he has to look good with his employers he'll pay the player a bonus if he does it.
   CONTACT: matt <mbsperry@gmail.com>

--]]

include "jumpdist.lua"
include "cargo_common.lua"
include "numstring.lua"

-- Localization, choosing a language if naev is translated for non-english-speaking locales.
lang = naev.lang()
if lang == "es" then
else -- Default to English

-- This section stores the strings (text) for the mission.

-- Bar information, describes how the person appears in the bar
   bar_desc = "A disheveled merchant Captain is pacing the bar, looking at his watch, and muttering to himself. You feel sorry for the worried Captain, and wonder if you could help in some way."

-- Mission details. We store some text for the mission with specific variables.
   misn_title = "The Absent-minded Merchant" 
   misn_reward = 50000
   misn_desc = "Help a fellow merchant make a rush delivery"
   npc_name = "Capt. Jerry"
   cargo_name = "Food"

-- Stage one
   title = {}    --Each dialog box has a title.
   text = {}      --We store mission text in tables.  As we need them, we create them.
   title[1] = "Hello"    --Each chunk of text is stored by index in the table.
   text[1] = [["Oh, man, I was glad to see you pull into dock. That looks like a pretty fast ship you have out there. Would you be willing to help a fellow captain out?"]] 

-- Other stages...
   title[2] = "Visibly relieved"
   text[2] = [["Thank the stars! You see, I've got myself in a tight spot. I've got 10 tons of food that needs to get to %s in %s before it rots. I took off from %s a couple of STP ago thinking I had plenty of time, but the old Llama isn't running as well as she used to. My boss will fire me if I miss another shipment. I can't afford to lose this job -- I've got a wife and kids to feed! If you can make the run and drop the food on time, I'll throw in a small bonus on top of the delivery fee! My job is counting on it!"]]  

   title[3] = "Mission accomplished"
   text[3] = [[The dock crew makes quick work of offloading the slightly smelly food and packing it into refrigerated transports. Shortly after they finish, your comm lights up with Jerry's face. "Oh man, I can't tell you how much I owe you for this one. I just wired you a sweet bonus for making that run so fast. Thanks again!"]]

-- Comm chatter
   talk = {}
   talk[1] = ""

-- Other text for the mission
   msg_abortTitle = "" 
   msg_abort = [[]]

   not_enough_cargo_space = "You don't have enough space for this mission"
   time_up_msg = [[Your comm light starts blinking frantically. Capt. Jerry's face appears. "You missed the deadline! What am I going to do now? Thanks for nothing, jerk!."]]
end


--[[ 
First you need to *create* the mission.  This is *obligatory*.

You have to set the NPC and the description. These will show up at the bar with
the character that gives the mission and the character's description.
--]]
function create ()
--[[ Does not claim any systems --]]

   merch_origin = planet.get("Praxis")
   start_world, start_world_sys = planet.cur()
   p_pos = start_world:pos()
   planets = cargo_selectPlanets(3, p_pos)

   -- Make sure that the random world selected is an empire world. We don't want the player having to fly into pirate space for this "easy" mission.
   empire_world = false
   while empire_world == false do
      index = rnd.rnd(1, #planets)
      p_faction = planets[index][1]:faction()
      if p_faction == faction.get( "Empire" ) then
         empire_world = true
      end
   end
   target_world = planets[index][1]
   target_world_sys = planets[index][2]

   numjumps   = start_world_sys:jumpDist(target_world_sys)
   px_length = cargo_calculateDistance(start_world_sys, p_pos, target_world_sys, target_world)
   misn_time_limit = (0.2 * px_length) + (10000 * numjumps) + 10000


--[[
   merch_origin = planet.get("Praxis")
   start_world, start_world_sys = planet.cur()
   target_world_sys = system.get("Gamma Polaris")
   target_world = planet.get("Polaris Prime")
--]]

   misn.setNPC( "A Merchant", "neutral/unique/absent_merch" )
   misn.setDesc( bar_desc )

end


--[[
This is an *obligatory* part which is run when the player approaches the character.

 ===FOR MISSIONS FROM THE BAR or OTHER PLACES===
Run misn.accept() here, this enables the mission to run when the player enters the bar.
If the mission doesn't get accepted, it gets trashed.
Also set the mission details.
--]]
function accept ()
   -- Most missions will need the following to avoid crashing Naev

   -- This will create the typical "Yesn/No" dialogue when mission is created
   -- at bar.  It returns true if yes was selected.
   if tk.yesno( title[1], text[1] ) then

      if player.pilot():cargoFree() < 10 then
         tk.msg( "Abort", not_enough_cargo_space )
         misn.finish()
      end

      misn.accept()  -- For missions from the Bar only.

      -- Mission details:
      -- You should always set mission details right after accepting the mission
      misn.setTitle( misn_title)
      misn.setReward( "A healthy bonus")
      misn.setDesc( misn_desc)

      cargoID = misn.cargoAdd(cargo_name, 10)
      -- Markers indicate a target system on the map, it may not be needed
      -- depending on the type of mission you're writing.
      misn.markerAdd( target_world_sys, "low" ) --change as appropriate to point to a system object and marker style.

      -- Calculates the deadline as a time
      deadline = time.get() + time.create(0, 0, misn_time_limit)

      -- This is the text which appears after the player accepts. 
      tk.msg( title[2], string.format( text[2], target_world:name(), time.str(deadline-time.get(), 0), merch_origin:name()) )

      -- Create the osd messages
      osdMsg = {}
      osdMsg[1] = string.format("Urgent delivery of food to %s", target_world:name() )
      osdMsg[2] = "You have %s remaining" 
      misn.osdCreate( "Cargo Run", {osdMsg[1], string.format(osdMsg[2], time.str(deadline - time.get()))})

      hook.land("land")
      hook.date(time.create(0, 0, 100), "tick") -- 100STU per tick
    else
      misn.finish()
   end

end

function land()
   -- Right planet?
   if planet.cur() == target_world then
      -- Remove the cargo, send Jerry's response, pay the player
      misn.cargoRm(cargoID)
      tk.msg(title[3], text[3])
      player.pay(misn_reward)

      -- Set the minish finish success
      misn.finish(true)
   end

end

function tick()
   if deadline >= time.get() then
      misn.osdCreate( "Cargo Run", {osdMsg[1], string.format(osdMsg[2], time.str(deadline - time.get()))})
   elseif deadline < time.get() then
      tk.msg("Mission failed", time_up_msg)
      abort()
   end
end


--[[
Use other functions to define other actions.
Connect them to game actions through hooks.
For example you can put hooks in the body of the main create() and accept() functions.
When the mission ends, use misn.finish( [true or false] ).
The misn.finish() function clears the mission from memory and determines if it will appear again.
--]]


--[[
OPTIONAL function that will be run if player aborts the mission.
Nothing happens if it isn't found and the mission fails.
--]]
function abort ()
   misn.cargoRm(cargoID)
   misn.finish(false)
end
