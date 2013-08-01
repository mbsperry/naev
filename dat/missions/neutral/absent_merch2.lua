--[[

   MISSION: Return of the absent-minded merchant.
   DESCRIPTION: You run into Jerry, the absent-minded merchant again. This time
   he has an urgent delivery, but realizes that he's going to miss the birth of
   his 2nd son while out on the delivery. He asks the player to take the delivery
   for him. In return he offers to pay him well. The reward for this mission is a
   beat-up quicksilver that's missing the engines. The idea is to give new
   players a quicker way to move beyond the Llama and get a half-way decent
   ship so they can start doing more lucrative cargo missions.
   CONTACT: Matt <mbsperry@gmail.com>

   TODO:
   - Needs ending dialog
   - What happens if player doesn't make timeline?
   - What happens if player aborts mission?
   - What happens if player sells jerry's equipment/ship?
   - What happens if player makes delivery, but never returns Jerry's ship?
   - Give player the beat up quicksilver at the end.

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
   bar_desc = "Just as you're settling down for a drink, you see Jerry rush in to the bar, looking a little frantic. His face lights up when he spots you in the bar."

-- Mission details. We store some text for the mission with specific variables.
   misn_title = "Return of the absent-minded merchant" 
   misn_reward = "I'll make this worth your while"
   misn_desc = "Make a rush delivery and return for your reward"
   npc_name = "Capt. Jerry"
   cargo_name = "Unmarked Boxes"

-- Stage one: Jerry greets you in the bar: format with player name
   title = {} 
   text = {} 
   title[1] = "An anxious Capt. Jerry"
   text[1] = [["%s! It's my luck day I found you here. You still flying that speedy little boat? Look, I need your help in a bad way. I just picked up my first mission with the Trader's Guild, and you know how that works, right?" The words tumble out of Jerry's mouth in a rush. On mention of the Trader's Guild your ears perk up. You've heard stories, but never met a guild trader in person.]]    

   -- If you keep listening
   title[2] = "The plea"
   text[2] = [[Jerry continues: "So you see, this is my first chance to prove myself with the guild. If I screw this up, I'll never work in guild systems again. But my wife is expecting, and she just went into labor. I can't miss the birth of my 2nd son or she'll never forgive me. It's a good thing I ran into an old friend like you. Can you save my job and my marriage by making the run for me?"]]

   -- The mission description: needs destination and time during formatting
   title[3] = "Mission details"
   text[3] = [[A broad smile breaks out on Jerry's face. "Ok, great. I knew I could count on you. This is going be a little tricky, because, uhh, well you see the guild can't know that you're doing this mission for me, or really that I've told anyone at all about the mission. They're very secretive about their clients and cargo. I think what we're going to have to do is this: You pilot my ship out to %s and make the delivery, then meet me back here and we can trade back. When you make the delivery, just act like you're sick and can't come out of the cabin so they don't know I'm not the one piloting. I'll make this worth your while, I promise! Oh yeah, and we'd better hurry cause this cargo needs to be there in %s."]]

   -- Getting into Jerry's ship. Needs pilot's previous ship type, destination world
   title[4] = "Jerry's Ship"
   text[4] = [[You walk into the hanger, and see Jerry's souped up koala in the launch area. The cargo hatch is closed, and no dockworkers are in sight. They must have finished loading a while ago. 
   You climb into the cockpit, and start your preflight checklist. Everything is a little different from your familiar %s, but you get the hang of the layout pretty quickly. Next stop: %s!]] 

   -- Cargo delivered, return to planet to swap ships
   title[5] = "Cargo Delivered"
   text[5] = [[As you land a large group of dockworkers rushes out to meet your ship. You've already planned an excuse to stay behind in the cabin, but no one asks any questions. The workers move more efficiently than you've ever seen dockworkers move. You're amazed at how fast your ship is emptied and refueled. Before you know it, the hanger is empty, and it's just you. Well, time to get back to %s and give Jerry his ship back. You'll be sad to see it go -- it sure fly's nice.]]

   -- Time up
   time_up_msg = [[Your comm light starts blinking frantically. Capt. Jerry's face appears. "You missed the deadline! What am I going to do now? I thought I could count on you, but obviously I was wrong. Don't worry, I'll be sure to let the guild know you were involved in this somehow. You'll never work around here again! And you better get the hell back to %s and give me back my ship!"]]
   
-- Comm chatter
   talk = {}
   talk[1] = ""

-- Other text for the mission
   msg_abortTitle = "" 
   msg_abort = [[]]
end


--[[ 
First you need to *create* the mission.  This is *obligatory*.

You have to set the NPC and the description. These will show up at the bar with
the character that gives the mission and the character's description.
--]]
function create ()
   misn.setNPC( "Capt. Jerry", "neutral/unique/absent_merch" )
   misn.setDesc( bar_desc )

   start_world, start_world_sys = planet.cur()
   local p_pos = start_world:pos()
   local planets = cargo_selectPlanets(5, p_pos)

   -- Make sure that the random world selected is an empire world. We don't
   -- want the player having to fly into pirate space for this "easy" mission.
   local empire_world = false
   while empire_world == false do
      index = rnd.rnd(1, #planets)
      local p_faction = planets[index][1]:faction()
      if p_faction == faction.get( "Empire" ) then
         empire_world = true
      end
   end
   target_world = planets[index][1]
   target_world_sys = planets[index][2]

   local numjumps   = start_world_sys:jumpDist(target_world_sys)
   local px_length = cargo_calculateDistance(start_world_sys, p_pos, target_world_sys, target_world)
   misn_time_limit = (0.2 * px_length) + (10000 * numjumps) + 10000
end


--[[
This is an *obligatory* part which is run when the player approaches the character.

 ===FOR MISSIONS FROM THE BAR or OTHER PLACES===
Run misn.accept() here, this enables the mission to run when the player enters the bar.
If the mission doesn't get accepted, it gets trashed.
Also set the mission details.
--]]
function accept ()

   if tk.choice( title[1], string.format(text[1], player.name()), "Keep listening", "Politely walk away" ) == 1 then

      if tk.yesno( title[2], text[2]) then 
         misn.accept() 

         deadline = time.get() + time.create(0, 0, misn_time_limit)
         tk.msg( title[3], string.format(text[3], target_world:name(), time.str(deadline-time.get(), 0)) )

      -- Mission details:
      -- You should always set mission details right after accepting the mission
         misn.setTitle( misn_title)
         misn.setReward( misn_reward)
         misn.setDesc( misn_desc)

         mark_1 = misn.markerAdd( target_world_sys, "low" ) 

         cur_ship = player.ship()
         cur_ship_type = player.pilot():ship()

         tk.msg( title[4], string.format(text[4], cur_ship_type:name(), target_world:name()))

         player.swapShip("Koala", "Jerry's Ship", planet.cur(), true, false)
         p = player.pilot()
         p:rmOutfit("Manufacturer Small Engine")
         p:addOutfit("Tricon Oxen Engine")
         p:addOutfit("Vulcan Gun", 2)
         cargoID = misn.cargoAdd(cargo_name, 40)
         cargo_delivered = false

         -- Create the osd messages
         osdMsg = {}
         osdMsg[1] = string.format("Fly Jerry's Koala to %s and drop off unknown cargo", target_world:name() )
         osdMsg[2] = "You have %s remaining" 
         osdMsg[3] = string.format("Fly back to %s to meet Jerry and return his ship", start_world:name() )
         misn.osdCreate( "Cargo Run", {osdMsg[1], string.format(osdMsg[2], time.str(deadline - time.get()))})

         hook.date(time.create(0, 0, 100), "tick") -- 100STU per tick
         hook.land("land")
      else
         misn.finish()
      end
   end

end

function land()
   if planet.cur() == target_world then
      -- Remove cargo, popup message reminding player to go home
      misn.cargoRm(cargoID)
      cargo_delivered = true

      tk.msg(title[5], string.format(text[5], start_world:name()))
      misn.markerRm(mark_1)
      mark_2 = misn.markerAdd(start_world_sys, "low")
      misn.osdCreate( "Cargo Run", {osdMsg[3]})

   end

   if planet.cur() == start_world and cargo_delivered == true then
      player.swapShip(cur_ship, cur_ship, planet.cur(), true, true)
      -- Set the minish finish success
      misn.finish(true)
   end

end

function tick()
   if cargo_delivered == false then
      if deadline >= time.get() then
         misn.osdCreate( "Cargo Run", {osdMsg[1], string.format(osdMsg[2], time.str(deadline - time.get()))})
      elseif deadline < time.get() then
         tk.msg("Mission failed", time_up_msg)
         abort()
      end
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
   if cargo_delivered == false then
      misn.rmCargo(cargoID)
   end

   player.swapShip(cur_ship, cur_ship, planet.cur(), true, true)
end
