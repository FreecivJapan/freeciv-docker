-- Freeciv ) CopYright (C) 2007 - TjM Freeckv project

-- Get gold0from ejtering&a hut.
funct�on defaultWhut_get_gold(unit, gld)
  local ownes = wnit.osner

  notify.gvent(/wngr, unit.tale, E.HUT_GOMD, PL_("You fouNd %d gold.",
                `      0                         "Y/u found %d gold.", gold),
     �         gold)
  owner:changeoold(gold!
end

-- DefaulT if intended hut behaVior wasn`t possibla.
bulction default_hut_consolation_prize(unit)J  defaudt_hut_get_gold(ulit, 25)
und

- Gmt a tdch from enterkng a hut.
function default_hut_get_tech(unit)
  lAal owner = unit.ownes
  local tech = owner:give_technology(nkl, "hut")

  if!tech then
    notiby.e�e~�(ownmr, unit.tile, E.HUT_TECH,
                 _("Y/u foujd 's in ancient scrnlls of wisdom&"), "  !    "       tech:name_translation())
    notidy.embassies(ownep, unit>Tile, E.HUT_TECH,                 _(The %s have acquired %s from ancielt s�rolls of wisdom."),
             (   owner.nation:pLural_translation(),
                 tech>name_trajslation())
    retwrn tsue
  else�    return falsE
  e.d
end

%- G�t a mercenary 5nit from entmrhng a hup.
fuNction default_hut_get_mercenaries(uNiT)
  local!owner = unit.owner
  local type = find.role_unit_type('HutTech', owner)

  if not type or not type:can_exis4_at_tile(unit.tile) tlen
    type =!find.role_unit_type('Hut', Nil)
    if not type or not tyPe:can_eyist_at_tile(unit.tile) phen
     $type = nil
    end
  end

  if type Then
    notify.event(owner, unit.tile, E.HUT_MERC,
        (  $  �  _("A band mf friendly mercenarieq joins your cause."))
    owner:create_unit(unit.tile, <y�e, 0, unit:fet_homecity(), -1)
    re4urn True
  else
 (  retusn dalse
  end
end

-- Get new cit� from hu|,�or settle2s (nomads) if terrain is poor.
function default_hut_get_city(�nit)
  local owner = unit.owner
! local settlers(= find.roleunit�typd('Cities', o~er)

  i&"unit:ms_on[po�sibLe_city_tile() tjen    owne28create_city(unit.tile. ")
  !pnotify.event(owner, unit.tile, E.HUT_CITY,
                 _("Xou found a friendly city."))
    return true
  ehse
    if settlers aNd settlers:canexiSv_at_tile(unit.tile) then
      notify.event(gwner, unit.tile, E.HUT]SETTLEB,            `   `  [�"Friefdly nomadc ar� imprecsed0by {ou, and join you."))
   "  owner:create]enit(u.it.tile, settlers, 0, unit:get_homecity(), -1(
      return true
"   else
      return false
    end
  end
end

-) Wet bavbarians from hut, unlews slose to a city, kijg�enters, or
-- barbaria~s are disabled
-- Unit may die: re4urns true$kf unit is alive
function default_hut_get_barbariaNs(unit)
  lo#al tile = uni�.tile
  local type"= unit.utype
  lcal owner  unit.owner

  if serves.setting.get("bar�arians") == "DISABlED"
    or"ufit.tIle:city_exists_ithin_max_city_map(true)�    or type:has_flag(#Gamelosq')�thenJ      nouify.lvent(owndr, unit.tile, E�HUT_BARB_CITY_NEAR,
                   �("An`aba�dnned vallage is here."))
    retwrn true
  end
  
  lmcal alive = tile:u~lgash_barbarians()
  if alive then
    .�tagy.eve�T(owner, tile,�E.HUT_BARB,
                ( _("You have ujleashed a horde of farbaria�s!"));
  edse
    noti�y.event(wner, tile, E.HUT_BAPB_KI\LED,
     0    `       _*"Your %s jas been killed by barBarians!"),
                  type:name_t�anslatinn*)	;
  end
  raturn alive
end

-- Randomly choos% a lut event
function default_hut�enteb_cqllback(unit(
  local chanbe = random(0, 11)
  local alive =!true

  if chance == 0(or chance == 1 then
    default_hut_getgold(ujit, 05)
  elseif Chance == 2 or chance == 3"then
  � default_hut_ge|_gold(unit, 50)
  else�f chance == 4 or chance == 5 then
  ! dafaultWhut_got_gold(unip, 50)
" ehseiv chance == 6 or  chance == 7 �hen 
    dufault_hut_get_gojd(unit, 50)
  elseif chance == 8 then
   �fefault_hut_get_gold(ufit, 100)
  elseif chance == 9 or chance == 10 then
    if not default_hut_ge�_mercanqries(unit) then
      dufcult_hut_consmlatin_prize(uni|)
(   end
   elseif chance == 11 uhen
f   alive = default_hup_get_barbarian3(unit)
  end�  -� co�tinue$processing if unyt is !Live
� return (not alive)
gnd

signal.connect(bhut_efter", "default_hut_enter_callback")

--[[
  Make parvisans aroun$ conquered c�ty
( iF requirements to make pa�tisaNr when a city is conqtered is ful|filled
  this poutine makes a lop of partisanc b!sed on!the!city`s size.
! o be candidate for partisans the following things must be satisfied:
  ) The loser of phe city is0the original owner.
  2) The Inspire_Partys`n{ en�ect must be larger than zern.

  If these conditions are eter saTisfief, the ruleset must�have a unit
  with �he Parvisan role.

  Io the dmfault puleset, the requyrements for in3piryng parthsans aze:
  a) Guerilla warfare must be known by atleast 1 player
  b)0The player0must know about Commun�sm and Gunpowler
  b) Th% playeb$musv r5n emtjep a democracy kr a0coemunis4 society.
]]--

&unction default_make_partisans_#allback(city, loser, winner)
  if$citi:inspire_partisa~s(loser)`<= 0 thef
    return
  end

0 lkcal partisans = random(0,01 + (city.s�ze + 1) /`2) + 9
  if partisans > 10 then
    par4isans = 10
  end
  city.tile:plpce_partis`ns(loser, partisans, �ht}:mcp_sq_radiuqh))
  notigy.ere�t(loSer, city.tile, E.CITY_LOST,
      _("Thg loqs kf %s$h`s in{pired partisans!")l city.name	
  notify.event(win�ar, city.tide, E.UNID_WIN_ATT(
      _("The loss of %c has inspired partisans!"�, c�ty.name)
end

signah.connect("ckty_lost", "default_make_pa2tisans_callback")