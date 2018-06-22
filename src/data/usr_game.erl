%%%--------------------------------------------------------
%%% @Module: usr_game
%%% @Description: 自动生成
%%%--------------------------------------------------------
-module(usr_game).
-export([get_one/1, get_game_gids_by_game_type_and_open_status/1, set_one/1, set_field/3, del_one/1, syncdb/1, clean_all_cache/0, cache_key/1]).
-include("common.hrl").
-include("record_usr_game.hrl").

get_one(Game_id = Id) ->
	case run_data:in_trans() of
		true ->
			case run_data:trans_get(usr_game, Id) of
				[] ->
					get_one_(Id);
				trans_deleted -> [];
				R -> R
			end;
		false ->
			get_one_(Id)
	end.

get_one_(Game_id = Id) ->
	case cache:get(cache_key(Id)) of
		{true, _Cas, Val} ->
			Val;
		_ ->
			case db_esql:get_row(?DB_USR, <<"select game_id,game_hashid,game_name,open_status,game_key,balance_lua_f,hard_coef,mining_rule,trusteeship_exuserid,cp_name,cp_exuserid,ip_list,token_symbol_list,game_type from game where game_id=?">>, [Game_id]) of
				[] -> [];
				Row ->
					R = build_record_from_row(Row),
					cache:set(cache_key(R#usr_game.key_id), R),
					R
			end
	end.

get_game_gids_by_game_type_and_open_status({Game_type, Open_status} = Id) ->
	case db_esql:get_all(?DB_USR, <<"select game_id from game where game_type=? and open_status=?">>, [Game_type, Open_status]) of
		[] -> [];
		Rows ->
			[Game_id_ || [Game_id_ | _] <- Rows]
	end.

set_field(Game_id = Id, Field, Val) ->
	Fields = record_info(fields, usr_game),
	L = lists:zip(Fields, lists:seq(1, length(Fields))),
	{_, N} = lists:keyfind(Field, 1, L),
	R0 = get_one(Id),
	R = setelement(N+1, R0, Val),
	set_one(R),
	R.

set_one(R0) when is_record(R0, usr_game) ->
	case R0#usr_game.key_id =:= undefined of
		false ->
			case run_data:in_trans() of
				true ->
					run_data:trans_set(usr_game, R0#usr_game.key_id, R0,
						void,
						void);
				false ->
					syncdb(R0),
					cache:set(cache_key(R0#usr_game.key_id), R0)
			end,
			R0#usr_game.key_id;
		true ->
			#usr_game{
				game_id = Game_id,
				game_hashid = Game_hashid,
				game_name = Game_name,
				open_status = Open_status,
				game_key = Game_key,
				balance_lua_f = Balance_lua_f,
				hard_coef = Hard_coef,
				mining_rule = Mining_rule,
				trusteeship_exuserid = Trusteeship_exuserid,
				cp_name = Cp_name,
				cp_exuserid = Cp_exuserid,
				ip_list = Ip_list,
				token_symbol_list = Token_symbol_list,
				game_type = Game_type
			} = R0,
			{ok, [[Insert_id|_]]} = db_esql:multi_execute(?DB_USR, io_lib:format(<<"insert into game(game_id,game_hashid,game_name,open_status,game_key,balance_lua_f,hard_coef,mining_rule,trusteeship_exuserid,cp_name,cp_exuserid,ip_list,token_symbol_list,game_type) values(~p,'~s','~s',~p,'~s','~s',~p,'~s',~p,'~s',~p,'~s','~s',~p); select last_insert_id()">>,
				[Game_id, Game_hashid, util:esc(Game_name), Open_status, Game_key, Balance_lua_f, Hard_coef, ?T2B(Mining_rule), Trusteeship_exuserid, util:esc(Cp_name), Cp_exuserid, Ip_list, Token_symbol_list, Game_type])),
			R = R0#usr_game{key_id = Insert_id, game_id = Insert_id},
			F = fun() ->
					cache:set(cache_key(R#usr_game.key_id), R)
				end,
			case run_data:in_trans() of
				true ->
					run_data:trans_set(usr_game, R#usr_game.key_id, {trans_inserted, R}, F, fun() -> usr_game:del_one(R) end);
				false ->
					F()
			end,
			R#usr_game.key_id
	end.

del_one(R) when is_record(R, usr_game) ->
	case run_data:in_trans() of
		true ->
			run_data:trans_del(usr_game, R#usr_game.key_id,
				fun() -> usr_game:del_one(R) end,
				void);
		false ->
			Game_id = R#usr_game.key_id,
			run_data:db_write(del, R, fun() -> db_esql:execute(?DB_USR, <<"delete from game where game_id=?">>, [Game_id]) end),
			cache:del(cache_key(R#usr_game.key_id))
	end,
	ok.

clean_all_cache() ->
	clean_all_cache(0),
	ok.

clean_all_cache(N) ->
	case db_esql:get_all(?DB_USR, <<"select game_id from game limit ?, 1000">>, [N * 1000]) of
		[] -> ok;
		Rows ->
			F = fun(Id) -> cache:del(cache_key(Id)) end,
			[F(Id) || [Id | _] <- Rows],
			clean_all_cache(N + 1)
	end.

syncdb(R) when is_record(R, usr_game) ->
	#usr_game{
		game_id = Game_id,
		game_hashid = Game_hashid,
		game_name = Game_name,
		open_status = Open_status,
		game_key = Game_key,
		balance_lua_f = Balance_lua_f,
		hard_coef = Hard_coef,
		mining_rule = Mining_rule,
		trusteeship_exuserid = Trusteeship_exuserid,
		cp_name = Cp_name,
		cp_exuserid = Cp_exuserid,
		ip_list = Ip_list,
		token_symbol_list = Token_symbol_list,
		game_type = Game_type
	} = R,
	run_data:db_write(upd, R, fun() -> db_esql:execute(?DB_USR, io_lib:format(<<"insert into game(game_id,game_hashid,game_name,open_status,game_key,balance_lua_f,hard_coef,mining_rule,trusteeship_exuserid,cp_name,cp_exuserid,ip_list,token_symbol_list,game_type) values(?,?,?,?,?,?,?,?,?,?,?,?,?,?) on duplicate key update "
		"game_hashid = ?, game_name = ?, open_status = ?, game_key = ?, balance_lua_f = ?, hard_coef = ?, mining_rule = ?, trusteeship_exuserid = ?, cp_name = ?, cp_exuserid = ?, ip_list = ?, token_symbol_list = ?, game_type = ?">>, []),
		[Game_id, Game_hashid, util:esc(Game_name), Open_status, Game_key, Balance_lua_f, Hard_coef, ?T2B(Mining_rule), Trusteeship_exuserid, util:esc(Cp_name), Cp_exuserid, Ip_list, Token_symbol_list, Game_type, Game_hashid, util:esc(Game_name), Open_status, Game_key, Balance_lua_f, Hard_coef, ?T2B(Mining_rule), Trusteeship_exuserid, util:esc(Cp_name), Cp_exuserid, Ip_list, Token_symbol_list, Game_type]) end).

build_record_from_row([Game_id, Game_hashid, Game_name, Open_status, Game_key, Balance_lua_f, Hard_coef, Mining_rule, Trusteeship_exuserid, Cp_name, Cp_exuserid, Ip_list, Token_symbol_list, Game_type]) ->
	#usr_game{
		key_id = Game_id,
		game_id = Game_id,
		game_hashid = Game_hashid,
		game_name = Game_name,
		open_status = Open_status,
		game_key = Game_key,
		balance_lua_f = Balance_lua_f,
		hard_coef = Hard_coef,
		mining_rule = ?B2T(Mining_rule),
		trusteeship_exuserid = Trusteeship_exuserid,
		cp_name = Cp_name,
		cp_exuserid = Cp_exuserid,
		ip_list = Ip_list,
		token_symbol_list = Token_symbol_list,
		game_type = Game_type
	}.

cache_key(Game_id = Id) ->
	list_to_binary(io_lib:format(<<"usr_game_~p">>, [Game_id])).

