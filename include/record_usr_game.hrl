%%%--------------------------------------------------------
%%% @Module: usr_game
%%% @Description: 自动生成
%%%--------------------------------------------------------

-record(usr_game, {
		key_id,
		game_id = 0, % 游戏id
		game_name = <<"">>, % 游戏名
		open_status = 0, % 游戏状态，0-close, 1-open
		game_key = <<"">>, % 游戏固定key，用于登录校验
		balance_lua_f = <<"">>, % 结算lua脚本函数代码
		hard_coef = 1, % 难度系数，难度高给分紧的：> 1，难度低给分松的：< 1，其余：= 1
		reclaimed_gold = 0 % 游戏回收的总金币数
}).
