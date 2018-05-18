

------------------------------------------------
--TEST_MODE = "yes"
TEST_MODE = "no"
------------------------------------------------


function check_script_debug_mode_callback(turn, year)
  if turn == 0 then

if TEST_MODE == "no" then return end  ---------------------------------------

    notify.event(nil, nil, E.CHAT_MSG, "[b]*** Script debugging mode ***[/b]")
  end
end
signal.connect("turn_started", "check_script_debug_mode_callback")


------------------------------------------------
------------------------------------------------   helper function
------------------------------------------------


-- Require : (String type_name,   ... "city" or "unit" or "tile"
--            object)             ... City or Unit_Type or Tile
-- Return  : String               ... linked text string

function get_linked_text_string(type_name, object)
  local result_string = ""
  if type_name == "city" then
    result_string = "[l tgt=\"city\" id=" .. object.id ..
                    " name=\"" .. object.name .. "\" /]"
    return result_string
  elseif type_name == "unit" then
    result_string = "[l tgt=\"unit\" id=" .. object.id ..
                    " name=\"" .. object:name_translation() .. "\" /]"
    return result_string
  elseif type_name == "tile" then
    result_string = "[l tgt=\"tile\" x=" .. object.x ..
                    " y=" .. object.y .. "\" /]"
    return result_string
  else
    log.error("incorrect type_name in get_linked_text_string()")
    return result_string
  end
end





-- require: Building_type wonder
-- return: Player wonder_owner
-- return nil if nobody has the wonder
function search_wonder_owner(wonder)
  local wonder_owner = nil
  for player in players_iterate() do
    if player:has_wonder(wonder) then
      wonder_owner = player
    end
  end
  return wonder_owner
end





-- does player have the wonder?  and does player equal to nation_string?

function nation_has_wonder(player, nation_string, building_string)

  local Building_Type = find.building_type(building_string)
  if not player:has_wonder(Building_Type) then
    return false
  end

  local Nation_Type = find.nation_type(nation_string)
  if not player.nation == Nation_Type then
    return false
  else
    return true
  end
end





function tile_is_adjacent_to_water(tile)
  local temp_tile = nil
  local adjacent_sq = 1
  for temp_tile in tile:square_iterate(adjacent_sq) do
    if temp_tile.terrain:rule_name() == "Lake"
       or temp_tile.terrain:rule_name() == "Ocean"
       or temp_tile.terrain:rule_name() == "Deep Ocean" then
      return true
    end
  end
  return false
end

--[[
function TEST_tile_is_adjacent_to_water(city)
  local result = tile_is_adjacent_to_water(city.tile)
  if result == false then
    notify.event(city.owner, city.tile, E.CITY_BUILD,
                   _("There is no water in the vicinity of " .. city.name .. "."))
  else
    notify.event(city.owner, city.tile, E.CITY_BUILD,
                   _("Water exists in the vicinity of " .. city.name .. "."))
  end
end
signal.connect("city_built", "TEST_tile_is_adjacent_to_water")
]]--








------------------------------------------------
------------------------------------------------   experimental function
------------------------------------------------




-- get new units when you are killed your units

function get_units_when_killed_callback(unit, loser, reason)

if TEST_MODE == "no" then return end  ---------------------------------------

 -- if not nation_has_wonder(loser, "Mayan", "Long Count Calendar") then
 --   return
 -- end

  local chance = 0
  local units_name = (unit.utype):rule_name()
  if units_name == "Catapult" or units_name == "Cannon" or
     units_name == "Artillery" or units_name == "Howitzer" then
    chance = 10
  elseif units_name == "Fighter" or units_name == "Bomber" or
         units_name == "Helicopter" or units_name == "Stealth Fighter" or
         units_name == "Stealth Bomber" then
    chance = 10
  elseif units_name == "Cruise Missile" or units_name == "Nuclear" then
    chance = 10
  elseif units_name == "Frigate" or units_name == "Ironclad" or
         units_name == "Destroyer" or units_name == "Cruiser" or
         units_name == "AEGIS Cruiser" or units_name == "Battleship" or
         units_name == "Submarine" or units_name == "Carrier" then
    chance = 10
  else
    chance = 25
  end

if TEST_MODE == "no" then chance = 100 end  ---------------------------------

  if reason == "killed" and random(1, 100) <= chance then
    local new_unit_type = find.unit_type(units_name)
    local new_unit_homecity = unit:get_homecity()
    local new_unit_owner = unit.owner
    edit.create_unit_full(new_unit_owner, new_unit_homecity.tile, new_unit_type,
                          0, new_unit_homecity, 0, 1, nil)
  end
end

signal.connect("unit_lost", "get_units_when_killed_callback")








-- you get a Nuclear weapons if you finished to build specified building

function get_nuclear_weapon_callback(building_type, city)

if TEST_MODE == "no" then return end  ---------------------------------------

  if building_type:rule_name() == "Maya Pyramids" then
    edit.create_unit(city.owner, city.tile,
                     find.unit_type("Nuclear"), 0, nil, -1) 
  end
end

signal.connect("building_built", "get_nuclear_weapon_callback")








function get_phalanx_series_callback(tech_type, player, source)

if TEST_MODE == "no" then return end  ---------------------------------------

  if not (source == "researched" or source == "traded"
          or source == "stolen") then
    return false
  end

--  if (not (player:has_wonder(find.building_type("Long Count Calendar"))))
--      or player.nation:rule_name() ~= "Mayan" then
--    return false
--  end

  local units_name = nil
  if tech_type:rule_name() == "Bronze Working" then
    units_name = "Phalanx"
  elseif tech_type:rule_name() == "Gunpowder" then
    units_name = "Musketeers"
  elseif tech_type:rule_name() == "Conscription" then
    units_name = "Riflemen"
  elseif tech_type:rule_name() == "Tactics" then
    units_name = "Alpine Troops"
  elseif tech_type:rule_name() == "Labor Union" then
    units_name = "Mech. Inf."
  else
    return false
  end

  for city in player:cities_iterate() do
    edit.create_unit(city.owner, city.tile,
                     find.unit_type(units_name), 1, nil, -1)
  end
end

signal.connect("tech_researched", "get_phalanx_series_callback")




function get_catapult_series_callback(tech_type, player, source)

if TEST_MODE == "no" then return end  ---------------------------------------

  if not (source == "researched" or source == "traded"
          or source == "stolen") then
    return false
  end

--  if (not (player:has_wonder(find.building_type("Long Count Calendar"))))
--      or player.nation:rule_name() ~= "Mayan" then
--    return false
--  end

  local units_name = nil
  if tech_type:rule_name() == "Mathematics" then
    units_name = "Catapult"
  elseif tech_type:rule_name() == "Metallurgy" then
    units_name = "Cannon"
  elseif tech_type:rule_name() == "Machine Tools" then
    units_name = "Artillery"
  elseif tech_type:rule_name() == "Robotics" then
    units_name = "Howitzer"
  else
    return false
  end

  for city in player:cities_iterate() do
    edit.create_unit(city.owner, city.tile,
                     find.unit_type(units_name), 1, nil, -1)
  end
end

signal.connect("tech_researched", "get_catapult_series_callback")




function get_horsemen_series_callback(tech_type, player, source)

if TEST_MODE == "no" then return end  ---------------------------------------

  if not (source == "researched" or source == "traded"
          or source == "stolen") then
    return false
  end

--  if (not (player:has_wonder(find.building_type("Long Count Calendar"))))
--      or player.nation:rule_name() ~= "Mayan" then
--    return false
--  end

  local units_name = nil
  if tech_type:rule_name() == "Horseback Riding" then
    units_name = "Horsemen"
  elseif tech_type:rule_name() == "The Wheel" then
    units_name = "Chariot"
  elseif tech_type:rule_name() == "Chivalry" then
    units_name = "Knights"
  elseif tech_type:rule_name() == "Leadership" then
    units_name = "Dragoons"
  elseif tech_type:rule_name() == "Tactics" then
    units_name = "Cavalry"
  elseif tech_type:rule_name() == "Mobile Warfare" then
    units_name = "Armor"
  else
    return false
  end

  for city in player:cities_iterate() do
    edit.create_unit(city.owner, city.tile,
                     find.unit_type(units_name), 1, nil, -1)
  end
end

signal.connect("tech_researched", "get_horsemen_series_callback")





function get_caravel_series_callback(tech_type, player, source)

if TEST_MODE == "no" then return end  ---------------------------------------

  if not (source == "researched" or source == "traded"
          or source == "stolen") then
    return false
  end

--  if (not (player:has_wonder(find.building_type("Long Count Calendar"))))
--      or player.nation:rule_name() ~= "Mayan" then
--    return false
--  end

  local units_name = nil
  if tech_type:rule_name() == "Navigation" then
    units_name = "Caravel"
  elseif tech_type:rule_name() == "Magnetism" then
    units_name = "Frigate"
  elseif tech_type:rule_name() == "Steam Engine" then
    units_name = "Ironclad"
  elseif tech_type:rule_name() == "Electricity" then
    units_name = "Destroyer"
  elseif tech_type:rule_name() == "Steel" then
    units_name = "Cruiser"
  elseif tech_type:rule_name() == "Automobile" then
    units_name = "Battleship"
  else
    return false
  end

  for city in player:cities_iterate() do
    if tile_is_adjacent_to_water(city.tile) then
      edit.create_unit(city.owner, city.tile,
                       find.unit_type(units_name), 1, nil, -1)
    end
  end
end

signal.connect("tech_researched", "get_caravel_series_callback")




function get_fighter_series_callback(tech_type, player, source)

if TEST_MODE == "no" then return end  ---------------------------------------

  if not (source == "researched" or source == "traded"
          or source == "stolen") then
    return false
  end

--  if (not (player:has_wonder(find.building_type("Long Count Calendar"))))
--      or player.nation:rule_name() ~= "Mayan" then
--    return false
--  end

  local units_name = nil
  if tech_type:rule_name() == "Flighter" then
    units_name = "Fighter"
  elseif tech_type:rule_name() == "Rocketry" then
    units_name = "Cruise Missile"
  elseif tech_type:rule_name() == "Stealth" then
    units_name = "Stealth Fighter"
  else
    return false
  end

  for city in player:cities_iterate() do
    edit.create_unit(city.owner, city.tile,
                     find.unit_type(units_name), 1, nil, -1)
  end
end

signal.connect("tech_researched", "get_fighter_series_callback")




function get_free_technology_callback(turn, year)

if TEST_MODE == "no" then return end  ---------------------------------------

  if turn % 50 ~= 0 then
    return false
  end

  local wonder_owner = search_wonder_owner(find.building_type("Palace"))
-- there are no wonder in the world
  if wonder_owner == nil then
    return false
  end
--  if wonder_owner.nation:rule_name() == "Mayan" then
    edit.give_technology(wonder_owner, nil, hut)
--  end
end

signal.connect("turn_started", "get_free_technology_callback")






-- units will be killed in 10% of probability
-- if Mayan is occupied the city where there is a Maya Pyramids

-- edit.unit_kill() is used in 2.6

function units_killed_via_curse_callback(city, loser, winner)

if TEST_MODE == "no" then return end  ---------------------------------------

  if winner.nation:rule_name() == "Barbarian"
     or winner.nation:rule_name() == "Pirate" then
    return false
  end

  if loser.nation:rule_name() == "Mayan"
       and city:has_building(find.building_type("Maya Pyramids")) then
    local units_sum = 0
    local probability = 10
    for target_units in winner:units_iterate() do
       if (not target_units.utype:has_flag("GameLoss"))     -- exclude Leader
          and random(1, 100) <= probability then       -- probability
        edit.unit_kill(target_units, "killed", loser)     -- for 2.6
        units_sum = units_sum + 1
      end
    end

    if units_sum ~= 0 then
      notify.event(city.owner, city.tile, E.UNIT_LOST_MISC,
                   _(winner.nation:name_translation() .. " lost "
                     .. units_sum .. " units because Maya Pyramids curse!"))
    end
  end
end

signal.connect("city_lost", "units_killed_via_curse_callback")






-- player gets some gold when city growth

function get_gold_when_city_growth_callback(city, size)

if TEST_MODE == "no" then return end  ---------------------------------------

  local gold = 5 * size
  if nation_has_wonder(city.owner, "Mayan", "Long Count Calendar") then
    edit.change_gold(city.owner, gold)
    notify.event(city.owner, city.tile, E.HUT_GOLD,
                 _("You get %d gold."), gold)
  end
end

signal.connect("city_growth", "get_gold_when_city_growth_callback")




-- player get gold  (equal in all units cost)

function get_gold_that_equal_to_all_units_cost_callback(building_type, city)

if TEST_MODE == "no" then return end  ---------------------------------------

  if not nation_has_wonder(city.owner, "Chinese", "The Forbidden Palace") then
    return false
  end

  local cost = 0
  local gold = 0

  for unit in city_owner:units_iterate() do
    cost = cost + unit.utype:build_shield_cost()
  end

  gold = math.floor(cost * 0.25)
  edit.change_gold(city.owner, gold)
  notify.event(city.owner, city.tile, E.HUT_GOLD,
               _("You get %d gold."), gold)
end

signal.connect("building_built", "get_gold_that_equal_to_all_units_cost_callback")




-- freeze units

function freeze_units_callback(building_type, city)

-- if TEST_MODE == "no" then return end  ---------------------------------------

  if building_type ~= find.building_type("Chichien Itza") then
    return false
  end

  local tile_sq_radius = 2

  for player in players_iterate() do
    if player.is_alive
       and player.nation:rule_name() ~= "Mayan"
       and player.nation:rule_name() ~= "Barbarian"
       and player.nation:rule_name() ~= "Pirate" then

      for unit in player:units_iterate() do
        for next_tile in unit.tile:circle_iterate(tile_sq_radius) do
          if unit.utype:can_exist_at_tile(next_tile)    -- can exist?
             and unit.tile ~= next_tile                 -- not same tile?
             and next_tile:num_units() == 0             -- no unit?
             and next_tile:city() == nil then           -- not city tile
            local original_tile = unit.tile
            edit.unit_move (unit, next_tile, 4)
            edit.unit_move (unit, original_tile, 4)
            edit.unit_move (unit, next_tile, 4)

  notify.event(nil, nil, E.CHAT_MSG,
               "Move unit %s - from %s to %s",
  get_linked_text_string("unit", unit.utype),
  get_linked_text_string("tile", original_tile),
  get_linked_text_string("tile", next_tile))

            break
          end
        end

      end
    end
  end

  notify.event(nil, nil, E.CHAT_MSG,
               "[b]All units has been frozen by Mayan.[/b]")
end

signal.connect("building_built", "freeze_units_callback")






-- if there are Soviet, show witty messages

function wise_saying_callback()

if TEST_MODE == "no" then return end  ---------------------------------------

  local wit_table = {
"'If the opposition disarms, well and good. If it refuses to disarm, we shall disarm it ourselves.' - Joseph Stalin",
"'Death solves all problems - no man, no problem.' - Joseph Stalin",
"'In the Soviet army it takes more courage to retreat than advance.' - Joseph Stalin"
                    }
  local number = random(1, #wit_table)

  for player in players_iterate() do
    if player.nation:rule_name() == "Soviet" then
      notify.event(nil, nil, E.CHAT_MSG,
                  "Today's wit (No. %d)\n %s", number, wit_table[number])
    end
  end
end

signal.connect("map_generated", "wise_saying_callback")



