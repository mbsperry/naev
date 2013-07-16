--[[

   MISSION: Absent-minded Merchant
   DESCRIPTION: From the wiki mission ideas. A merchant with a slow ship suddenly realizes he can't make the delivery and implores the player (with a fast ship presumed) to do it for him. Since he has to look good with his employers he'll pay the player a bonus if he does it.

--]]

-- Localization, choosing a language if naev is translated for non-english-speaking locales.
lang = naev.lang()
if lang == "es" then
else -- Default to English

-- This section stores the strings (text) for the mission.

-- Bar information, describes how the person appears in the bar
   bar_desc = "A disheveled merchant Captain is glancing nervously around the room. You're not sure why, but for some reason you feel the need to talk to him."

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
   text[1] = [[Oh, man, I was glad to see you pull into dock. That looks like a pretty fast ship you have out there. Do you feel like making some easy money?"]] 

-- Other stages...
   title[2] = "Visibly relieved"
   text[2] = [["Listen, I'm in a tight spot. I've got 33 tons of food that needs to get to %s in 3 STP before it rots. I took off from %s a couple of STP ago thinking I had plent of time, but the old Llama isn't running as well as she used to. My boss will fire me if I miss another shipment. I'll pay you a hefty bonus if you can get this food there on time. My job is counting on it!"]]  

   title[3] = "Mission accomplished"
   text[3] = [[The dock crew makes quick work of offloading the slightly smelly food and packing it into refrigerated transports. Shortly after they finish, your comm lights up with Jerry's face. "Oh man, I can't tell you how much I owe you for this one. I just wired you a sweet bonus for making that run so fast. Thanks again!"]]

-- Comm chatter
   talk = {}
   talk[1] = ""

-- Other text for the mission
   msg_abortTitle = "" 
   msg_abort = [[]]

   not_enough_cargo_space = "You don't have enough space for this mission"
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
   target_world_sys = system.get("Gamma Polaris")
   target_world = planet.get("Polaris Prime")

   misn.setNPC( "A Merchant", "unique/jorek" )
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
      misn.markerAdd( target_world_sys, "high" ) --change as appropriate to point to a system object and marker style.

      tk.msg( title[2], string.format( text[2], target_world:name(), merch_origin:name()) )

      hook.land("land")
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
   misn.finish()
end
