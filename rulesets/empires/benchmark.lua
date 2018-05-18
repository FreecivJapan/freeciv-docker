
iterate_num = 50

function create_units_and_move(player, units, next_tile)
  local count = 0
  for i=1, iterate_num, 1 do
    local next_units = nil
    next_units = edit.create_unit(player, units.tile, units.utype, 0,
                                  units:get_homecity(), -1)
    if next_units then
      edit.unit_move(next_units, next_tile, 3)
      count = count + 1
    end
  end
  return count
end

function benchmark_callback(turn, year)

  if turn == 0 then
    for player in players_iterate() do

      notify.event(player, nil, E.CHAT_MSG, _("Start"))

      if player:is_human() then
        local count = 0
        local tile_sq_radius = 2
        for units in player:units_iterate() do
          for next_tile in (units.tile):circle_iterate(tile_sq_radius) do
            if (units.utype):can_exist_at_tile(next_tile)
               and units.tile ~= next_tile then
              count = count + create_units_and_move(player, units, next_tile)
              break
            end
          end

          if count == 0 then
            notify.event(player, next_tile, E.CHAT_MSG,
                         "[b]The server failed to create any units"
                         .. "to neighboring tile.[/b]")
            return false
          end
        end

        notify.event(player, nil, E.CHAT_MSG, _("Done") .. " (" ..
                     PL_("%d unit", "%d units", count) .. ")", count)
        return true
      end
    end
  end
end

signal.connect("turn_started", "benchmark_callback")



