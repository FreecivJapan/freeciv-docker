-- Freeciv - Copyright (C) 2007 - The Freeciv Project
--   This program is free software; you can redistribute it and/or modify
--   it under the terms of the GNU General Public License as published by
--   the Free Software Foundation; either version 2, or (at your option)
--   any later version.
--
--   This program is distributed in the hope that it will be useful,
--   but WITHOUT ANY WARRANTY; without even the implied warranty of
--   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--   GNU General Public License for more details.

-- Place Ruins at the location of the destroyed city.
function city_destroyed_callback(city, loser, destroyer)
  city.tile:create_base("Ruins", NIL)
  -- continue processing
  return false
end

signal.connect("city_destroyed", "city_destroyed_callback")




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





-- return true
-- if player is nation_string and player has wonder:building_string

function nation_has_wonder(player, nation_string, building_string)

  local Nation_Type = find.nation_type(nation_string)
  if player.nation ~= Nation_Type then
    return false
  end

  local Building_Type = find.building_type(building_string)
  if not player:has_wonder(Building_Type) then
    return false
  end

  return true
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
------------------------------------------------  ruleset event function
------------------------------------------------




--- gets unit_cost gold when you are killed your units

function get_gold_when_killed_callback(unit, loser, reason)

  if not nation_has_wonder(loser, "Aztec", "Sacrificial Altar") then
    return false
  end

  if reason == "killed" or reason == "nuke" then
    local gold = 2 * math.floor( unit.utype:build_shield_cost() )
    edit.change_gold(loser, gold)
    notify.event(unit.owner, unit.tile, E.HUT_GOLD,
                 _("Sacrificial Altar: ") ..
                 _("You get %d gold."), gold)
  end
end

signal.connect("unit_lost", "get_gold_when_killed_callback")





-- you get a river under each cities

function get_river_undre_city_callback(building_type, city)

  if building_type:rule_name() == "Olympia"
     and city.owner.nation:rule_name() == "Greek" then

    local road_name ="River"
    for target_city in city.owner:cities_iterate() do
      if not target_city.tile:has_road (road_name) then
        edit.create_road (target_city.tile, road_name)
      end
    end

    notify.event(city.owner, city.tile, E.WONDER_BUILD,
                 _("Olympia") .. ": " ..
                 _("Added a river under each your cities."))
  end
end

signal.connect("building_built", "get_river_undre_city_callback")





-- you get gold from other nation

LoN_turn   = -1
donate_turn = 3

function get_gold_from_other_nation_callback(building_type, city)

  if not (building_type:rule_name() == "League of Nations"
          and city.owner.nation:rule_name() == "American") then
    return false
  end

  if LoN_turn == -1 then
    LoN_turn = game.turn()
    return true
  else
    return false
  end
end

signal.connect("building_built", "get_gold_from_other_nation_callback")



function get_gold_from_other_nation_callback_body(turn, year)

  if LoN_turn == -1 then
    return false
  end

  local current_turn = game.turn()
  if LoN_turn < (current_turn - donate_turn) then
    return false
  end

  local wonder_owner = search_wonder_owner(find.building_type("League of Nations"))
  if wonder_owner == nil
     or wonder_owner.nation:rule_name() ~= "American" then
    return false
  end

  local total_gold    = 0
  local donate_factor = 0.8

  for player in players_iterate() do
    if player.is_alive
       and player.nation:rule_name() ~= "American"
       and player.nation:rule_name() ~= "Barbarian"
       and player.nation:rule_name() ~= "Pirate" then

      local change_gold = math.floor(donate_factor * player:gold())
      if 1 <= change_gold then
        edit.change_gold (player, -1 * change_gold)
        total_gold = total_gold + change_gold

        notify.event(player, nil, E.WONDER_BUILD,
                 _("You donated %d gold to the League of Nations. (%d/%d)"),
                     change_gold,
                     current_turn - LoN_turn, donate_turn)
      end
    end
  end

  edit.change_gold (wonder_owner, total_gold)
  notify.event(wonder_owner, nil, E.WONDER_BUILD,
                _("The League of Nations had collected donations. (%d/%d) ")
                .. _("You get %d gold."),
                current_turn - LoN_turn, donate_turn,
                total_gold)

end

signal.connect("turn_started", "get_gold_from_other_nation_callback_body")





-- Inca gets Heaven's Blessing when they build the wonder

function inca_get_special_unit_callback(building_type, city)

  if not ((building_type:rule_name() == "Machu Picchu"
           or building_type:rule_name() == "Nazca Lines")
          and city.owner.nation:rule_name() == "Inca") then
    return false
  end

  local units_name ="Heaven's Blessing"

  edit.create_unit(city.owner, city.tile,
                   find.unit_type(units_name), 0, nil, -1)

    notify.event(city.owner, city.tile, E.WONDER_BUILD,
                 _("%d: ") ..
                 _("You get %d."),
                 building_type:rule_name(), units_name)
end

signal.connect("building_built", "inca_get_special_unit_callback")








-- Publish the capital positoin and number of units in each countries

function publish_capital_and_units_callback(building_type, city)

  if not (building_type:rule_name() == "The Kremlin"
          and city.owner.nation:rule_name() == "Russian") then
    return false
  end

local tech_list = {
"Advanced Flight", "Alphabet", "Amphibious Warfare", "Astronomy",
"Atomic Theory", "Automobile", "Banking", "Bridge Building", "Bronze Working",
"Ceremonial Burial", "Chemistry", "Chivalry", "Code of Laws", "Combined Arms",
"Combustion", "Communism", "Computers", "Conscription", "Construction",
"Currency", "Democracy", "Economics", "Electricity", "Electronics",
"Engineering", "Environmentalism", "Espionage", "Explosives", "Feudalism",
"Flight", "Fusion Power", "Genetic Engineering", "Guerilla Warfare",
"Gunpowder", "Horseback Riding", "Industrialization", "Invention",
"Iron Working", "Labor Union", "Laser", "Leadership", "Literacy",
"Machine Tools", "Magnetism", "Map Making", "Masonry", "Mass Production",
"Mathematics", "Medicine", "Metallurgy", "Miniaturization", "Mobile Warfare",
"Monarchy", "Monotheism", "Mysticism", "Navigation", "Nuclear Fission",
"Nuclear Power", "Philosophy", "Physics", "Plastics", "Polytheism",
"Pottery", "Radio", "Railroad", "Railroad", "Refining", "Refrigeration",
"Robotics", "Rocketry", "Sanitation", "Seafaring", "Space Flight", "Stealth",
"Steam Engine", "Steel", "Superconductors", "Tactics", "The Corporation",
"The Republic", "The Wheel", "Theology", "Theory of Gravity", "Trade",
"University", "Warrior Code", "Writing"
}

  notify.event(nil, nil, E.CHAT_MSG,
               "[b]The Kremlin has finished their investigation"
               .. " of other countries.[/b]"
               .. " (" .. _("Turn: %d") .. ")", game.turn())

  local player       = nil
  for player in players_iterate() do

    local capital_name  = _("Unknown")
    local capital_type  = find.building_type("Palace")
    local city_size     = 0
    local mil_units_num = 0
    local leader_mess   = ""
    local tech_num      = 0

    if player:has_wonder(capital_type) then
      for city in player:cities_iterate() do
        if city:has_building(capital_type) then
         capital_name = get_linked_text_string("city", city)
        end
      end
    end

    for city in player:cities_iterate() do
      city_size = city_size + city.size
    end

    for index = 1, #tech_list do
      if player:knows_tech(find.tech_type(tech_list[index])) then
        tech_num = tech_num + 1
      end
    end

    for units in player:units_iterate() do
      if units:exists() then
        if not units.utype:has_flag("NonMil") then
          mil_units_num = mil_units_num + 1
        end
        if units.utype:rule_name() == "Leader" then
          leader_mess = "  || " .. _("?unit:Leader") .. ": " ..
                        get_linked_text_string("tile", units.tile)
        end
      end
    end

    if player.nation:rule_name() == "Russian" then
      notify.event(player, nil, E.CHAT_MSG,
             "%2d %14s :  %s",
             player.id, player.name, player.nation:name_translation())
      notify.event(player, nil, E.CHAT_MSG,
             "%4d %s %6d %s %4d %s (%d% s) %5d %s (%d %s) %4d %s     || %s %s %s",
             player:civilization_score(), _("Score"),
             player:gold(), _("Gold"),
             player:num_cities(), _("Cities"),
             city_size, _("Population"),
             player:num_units(), _("Units"),
             mil_units_num, _("Militaly Units"),
             tech_num, _("Advances"),
             _("Capital:"), capital_name,
             leader_mess)
    else
      notify.event(nil, nil, E.CHAT_MSG,
             "%2d %14s :  %s",
             player.id, player.name, player.nation:name_translation())
      notify.event(nil, nil, E.CHAT_MSG,
             "%4d %s %6d %s %4d %s (%d% s) %5d %s (%d %s) %4d %s     || %s %s %s",
             player:civilization_score(), _("Score"),
             player:gold(), _("Gold"),
             player:num_cities(), _("Cities"),
             city_size, _("Population"),
             player:num_units(), _("Units"),
             mil_units_num, _("Militaly Units"),
             tech_num, _("Advances"),
             _("Capital:"), capital_name,
             leader_mess)
    end
  end
end

signal.connect("building_built", "publish_capital_and_units_callback")






-- Announce the number of terrain tiles

function announce_number_of_terrain_tiles_callback(building_type, city)

  if not (building_type:rule_name() == "Ajanta Caves"
          and city.owner.nation:rule_name() == "Indian") then
    return false
  end

  notify.event(nil, nil, E.CHAT_MSG,
               "Ajanta Caves: " ..
               "Indian has completed a survey of" ..
               " the number of terrain tiles." ..
               " (" .. _("Turn: %d") .. ")", game.turn())

  local count = 0
  local blank, inacce, water1, water2, water3 = 0, 0, 0, 0, 0
  local land1, land2, land3, land4, land5 = 0, 0, 0, 0, 0
  local land6, land7, land8, land9, land0 = 0, 0, 0, 0, 0
  local tile_x, tile_y = 0, 0

  for tile in whole_map_iterate() do

    if tile_x < tile.nat_x then tile_x = tile.nat_x end
    if tile_y < tile.nat_y then tile_y = tile.nat_y end

    count = count + 1
    if tile.terrain == nil then
      blank = blank + 1
    else
      local terrain_name = tile.terrain:rule_name()
      if terrain_name == "Inaccessible"   then inacce = inacce + 1
      elseif terrain_name == "Lake"       then water1 = water1 + 1
      elseif terrain_name == "Ocean"      then water2 = water2 + 1
      elseif terrain_name == "Deep Ocean" then water3 = water3 + 1
      elseif terrain_name == "Glacier"    then land1 = land1 + 1
      elseif terrain_name == "Desert"     then land2 = land2 + 1
      elseif terrain_name == "Forest"     then land3 = land3 + 1
      elseif terrain_name == "Grassland"  then land4 = land4 + 1
      elseif terrain_name == "Hills"      then land5 = land5 + 1
      elseif terrain_name == "Jungle"     then land6 = land6 + 1
      elseif terrain_name == "Mountains"  then land7 = land7 + 1
      elseif terrain_name == "Plains"     then land8 = land8 + 1
      elseif terrain_name == "Swamp"      then land9 = land9 + 1
      elseif terrain_name == "Tundra"     then land0 = land0 + 1
      else log.error("terrain_name matching error!")
      end
    end
  end

  notify.event(nil, nil, E.CHAT_MSG,
    "%s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d %s%d",
    find.terrain("Inaccessible"):name_translation(), inacce,
    find.terrain("Lake"):name_translation(), water1,
    find.terrain("Ocean"):name_translation(), water2,
    find.terrain("Deep Ocean"):name_translation(), water3,
    find.terrain("Glacier"):name_translation(), land1,
    find.terrain("Desert"):name_translation(), land2,
    find.terrain("Forest"):name_translation(), land3,
    find.terrain("Grassland"):name_translation(), land4,
    find.terrain("Hills"):name_translation(), land5,
    find.terrain("Jungle"):name_translation(), land6,
    find.terrain("Mountains"):name_translation(), land7,
    find.terrain("Plains"):name_translation(), land8,
    find.terrain("Swamp"):name_translation(), land9,
    find.terrain("Tundra"):name_translation(), land0,
    _("Unknown"), blank)

  local land_num = land1 + land2 + land3 + land4 + land5 + land6 + land7 + land8 + land9 + land0
  local water_num = water1 + water2 + water3
  local land_rate = 100 * land_num / (land_num + water_num)

  notify.event(nil, nil, E.CHAT_MSG,
    "Land tiles : %d   Ocean tiles : %d   Land ratio : %2.2f%%    Total tiles : %d (%d x %d)",
    land_num, water_num, land_rate, count, tile_x+1, tile_y+1)
end

signal.connect("building_built", "announce_number_of_terrain_tiles_callback")






-- store starting position in each nations

coordinate_list = {}

function store_start_position_callback(turn, year)

  if game.turn() ~= 0 then
    return false
  end

  local index = 0
  for player in players_iterate() do
    for units in player:units_iterate() do
      if units:exists() then
        index = index + 1
        coordinate_list[index] = units.tile.x
        index = index + 1
        coordinate_list[index] = units.tile.y
        break
      end
    end
  end
end

signal.connect("turn_started", "store_start_position_callback")


-- restore starting position and announce it

function announce_start_position_callback(building_type, city)

  if not (building_type:rule_name() == "Ajanta Caves"
          and city.owner.nation:rule_name() == "Indian") then
    return false
  end

  local message = ""
  for index = 1, #coordinate_list, 2 do
    message = message .. " " ..
             "[l tgt=\"tile\" x=" .. coordinate_list[index] ..
                            " y=" .. coordinate_list[index+1] .. "\" /]"
  end
  notify.event(nil, nil, E.CHAT_MSG,
              "A list of starting positions: %s", message)
end

signal.connect("building_built", "announce_start_position_callback")






-- Spanish victory challenge

challenge_flag = false
challenge_turn = 0
challenge_num  = 5

function victory_challenge_start_callback(building_type, city)

  if not (building_type:rule_name() == "Sagrada Familia"
          and city.owner.nation:rule_name() == "Spanish") then
    return false
  end

  notify.event(nil, city.tile, E.CHAT_MSG,
               "[b]Spanish has finished to build the Sagrada Familia,"
               .. " and they will win the game![/b]")

  challenge_flag = true
  challenge_turn = game.turn()
end

signal.connect("building_built", "victory_challenge_start_callback")



function victory_challenge_lost_city_callback(city, loser, winner)

  if not challenge_flag then
    return false
  end

  if loser.nation:rule_name() == "Spanish" then
    challenge_flag = false
    notify.event(nil, city.tile, E.CHAT_MSG,
                 "[b]Spanish lost their city,"
                 .. " failed to Victory Challenge![/b]")
  end
end

signal.connect("city_lost", "victory_challenge_lost_city_callback")



function victory_challenge_destroy_city_callback(city, loser, destroyer)

  if not challenge_flag then
    return false
  end

  if loser.nation:rule_name() == "Spanish" then
    challenge_flag = false
    notify.event(nil, city.tile, E.CHAT_MSG,
                 "[b]Spanish were destroyed their city,"
                 .. " failed to Victory Challenge![/b]")
  end
end

signal.connect("city_destroyed", "victory_challenge_destroy_city_callback")



function victory_challenge_turn_start_callback(turn, year)

  if not challenge_flag then
    return false
  end

  local current_turn = game.turn()
  local wonder_owner = search_wonder_owner(find.building_type("Sagrada Familia"))

  if not nation_has_wonder(wonder_owner, "Spanish", "Sagrada Familia") then
    notify.event(nil, nil, E.CHAT_MSG,
                 "[b]Spanish failed to Victory Challenge"
                 .. " because they doesn't have Sagrada Familia.[/b]")
    challenge_flag = false
    return false
  end

  if challenge_turn >= current_turn - challenge_num then
    notify.event(nil, nil, E.CHAT_MSG,
                 "[b]Spanish will win the game.[/b] (%d/%d)",
                 current_turn - challenge_turn , challenge_num)
  else
    notify.event(nil, nil, E.CHAT_MSG,
                 "[b]Now, spanish has won the game![/b]")
    edit.player_victory(wonder_owner)
    challenge_flag = false
  end

end

signal.connect("turn_started", "victory_challenge_turn_start_callback")






-- player gets some gold if he is conquested by enemy cities
-- eprecated in 2.6. Use city_transferred instead. 

function get_gold_if_lost_city_callback(city, loser, winner)

  if winner.nation:rule_name() == "Barbarian"
     or winner.nation:rule_name() == "Pirate" then
    return false
  end

  local factor = 0.5
  local gold = math.floor(factor * winner:gold())

  if nation_has_wonder(loser, "Mayan", "Chichien Itza") then
    edit.change_gold(winner, -1 * gold)
    edit.change_gold(loser, gold)
    notify.event(winner, city.tile, E.WONDER_BUILD,
                 _("Chichien Itza: ") ..
                 _("You lost %d gold."), gold)
    notify.event(loser, city.tile, E.WONDER_BUILD,
                 _("Chichien Itza: ") ..
                 _("You get %d gold."), gold)
  end
end

signal.connect("city_lost", "get_gold_if_lost_city_callback")




-- Civilwar will occurs in 5% of probability if not Mayan occupy the city

function civiliwar_via_curse_callback(city, loser, winner)

  if winner.nation:rule_name() == "Barbarian"
     or winner.nation:rule_name() == "Pirate" then
    return false
  end

  if not nation_has_wonder(loser, "Mayan", "Long Count Calendar") then
    return false
  end

  local probability = 5

  if (edit.civil_war(winner, probability) ~= nil) then
    notify.event(nil, city.tile, E.CIVIL_WAR,
                 _("Long Count Calendar: ") ..
                 _("Civilwar was happened!"))
  end
end

signal.connect("city_lost", "civiliwar_via_curse_callback")







-- player gets 25 Mangudai units

function get_mongol_mangudai_callback(building_type, city)

  if building_type ~= find.building_type("Statue of Khan") then
    return false
  end

  local unit_type = find.unit_type("Mongol Mangudai")
  local max_num = 25

  for i=1, max_num, 1 do
    edit.create_unit(city.owner, city.tile, unit_type, 0, nil, -1)
  end

  local leader_unit_type = find.unit_type("Great Mongol Khan")
  edit.create_unit(city.owner, city.tile, leader_unit_type, 0, nil, -1)

  notify.event(city.owner, city.tile, E.WONDER_BUILD,
               _("Statue of Khan: ") ..
               _("Come sir, let's start the world conquest!"))
end

signal.connect("building_built", "get_mongol_mangudai_callback")





-- player gets some gold if he conquest enemy cities
-- eprecated in 2.6. Use city_transferred instead. 

function get_gold_if_conquest_city_callback(city, loser, winner)

  if nation_has_wonder(winner, "Spanish", "Conquistador") then
    local gold = 100 * city.size
    edit.change_gold(winner, gold)
    notify.event(winner, city.tile, E.WONDER_BUILD,
                 _("Conquistador: ") ..
                 _("You get %d gold."), gold)
  end
end

signal.connect("city_lost", "get_gold_if_conquest_city_callback")






-- unleash defender (30%) if French is occupied the city

function unleash_defender_callback(city, loser, winner)

  if not nation_has_wonder(loser, "French", "Arc de Triomphe") then
    return false
  end

  local units_name = ""
  if loser:knows_tech(find.tech_type("Labor Union")) then
    units_name = "Mech. Inf."
  elseif loser:knows_tech(find.tech_type("Tactics")) then
    units_name = "Alpine Troops"
  elseif loser:knows_tech(find.tech_type("Conscription")) then
    units_name = "Riflemen"
  elseif loser:knows_tech(find.tech_type("Gunpowder")) then
    units_name = "Musketeers"
  elseif loser:knows_tech(find.tech_type("Bronze Working")) then
    units_name = "Phalanx"
  else
    units_name = "Warriors"
  end

  local probability = 30
  local event_flag = false
  local event_units = find.unit_type(units_name)

  for event_tile in city.tile:circle_iterate(city:map_sq_radius()) do
    if random(1, 100) <= probability                   -- probability
       and event_units:can_exist_at_tile(event_tile)   -- can exist?
       and event_tile:num_units() == 0               -- no units on same tile
       and event_tile:city() == nil then             -- not city tile
      event_flag = edit.create_unit(loser, event_tile,
                                      event_units, 1, nil, -1)
    end
  end

  if event_flag then
    notify.event(winner, city.tile, E.CITY_LOST,
                 _("Volunteers reblogged uprising at %s !"),
                 get_linked_text_string("city", city))
    notify.event(loser, city.tile, E.CITY_LOST,
                 _("Volunteers reblogged uprising at %s !"),
                 get_linked_text_string("city", city))
  end
end

signal.connect("city_lost", "unleash_defender_callback")





-- player gets gold  (total city size)

function get_gold_that_equal_to_city_size_callback(building_type, city)

  if building_type ~= find.building_type("The Forbidden Palace") then
    return false
  end

  local total_gold = 0
  local total_city_size = 0

  for target_city in city.owner:cities_iterate() do
    total_city_size = total_city_size + target_city.size
  end

  total_gold = total_city_size * 50

  edit.change_gold(city.owner, total_gold)
  notify.event(city.owner, city.tile, E.WONDER_BUILD,
               _("The Forbidden Palace: ") ..
               _("Total city size is %d. ") ..
               _("You get %d gold."),
               total_city_size, total_gold)
end

signal.connect("building_built", "get_gold_that_equal_to_city_size_callback")






-- get gold if player has finished a tech researching

function get_gold_when_finish_research_callback(tech_type, player, source)

  if not (source == "researched") then
    return false
  end

  if not nation_has_wonder(player, "Persian", "Great Mosque of Samarra") then
    return false
  end

  local gold = player:civilization_score()
  edit.change_gold(player, gold)
  notify.event(player, nil, E.TECH_GAIN,
               _("Great Mosque of Samarra: ") ..
               _("You've finished the research. ") ..
               _("You get %d gold."), gold)
end

signal.connect("tech_researched", "get_gold_when_finish_research_callback")








