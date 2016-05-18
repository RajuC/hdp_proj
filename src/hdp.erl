-module(hdp).
-export([login/1,signup/1,user/1,get_user_vals_4_py/1,prediction/1,delete/1,write_user_his_file/1]).
-define(SIGNUP_BUC,<<"signup_cache">>).
-define(USER_BUC,<<"user_cache">>).
-define(USER_HIS_BUC,<<"user_his_cache">>).
-define(PRED_BUC,<<"pred_cache">>).
-define(PRED_HIS_BUC,<<"pred_his_cache">>).
-define(COUNT_BUC,<<"count_his_cache">>).
-define(_BUC,<<"rec_cache">>).
-define(SPA_PATH,"/home/raju/Documents/hdp_proj").
-define(SPARK_CMD,"/home/raju/spark-1.6.0/bin/spark-submit").



%%==================================================================================	


login(Details) ->
	Email = proplists:get_value(<<"email">>,Details),
	SignUpDetails = rs:get(?SIGNUP_BUC,Email),
	LoginPwd = proplists:get_value(<<"pwd">>,Details),
	SignUpPwd = proplists:get_value(<<"pwd">>,SignUpDetails),
	if SignUpPwd =:= LoginPwd ->
			UserId = proplists:get_value(<<"user_id">>,SignUpDetails),
		<<"success","-",UserId/binary>>;
		true ->
			<<"incorrect_password">>
	end.


signup(Details) ->
	UserId = get_user_id(),
	Email = proplists:get_value(<<"email">>,Details),
	ok = rs:put(?SIGNUP_BUC,Email,[{<<"user_id">>,UserId}|Details]),
	<<"success">>.
	

user(InDetails) ->
	UserId = proplists:get_value(<<"user_id">>,InDetails),
	AgeSexDetails = getuser_age_sex(UserId),
    Details = AgeSexDetails++InDetails,
	UserInputStr = get_vals_as_str(Details,""),
	TimeStamp = ts_format(erlang:localtime()),
	ok = rs:put(?USER_BUC,UserId,[{<<"user_string">>,UserInputStr}|Details]++[{<<"timestamp">>,TimeStamp}]),	
	io:format("hiiii i am here before SPARK script~n~n"),
%%	PrivDir = code:priv_dir(hdp_proj),
%%	Cmd =  ?SPARK_CMD++" "++PrivDir++"/spark/sparkpred.py "++binary_to_list(UserId),
	Cmd =  ?SPARK_CMD++" "++?SPA_PATH++"/sparkpred.py "++binary_to_list(UserId),
	io:format("Cmd:: ~p~n",[Cmd]),
	Reply = os:cmd(Cmd),
%%	Reply = os:cmd("pyspark sparkpred.py 1462L306353S708848"),
	io:format("Pyhon Replyyy ~p~n",[Reply]),	
	UserPredDetls = rs:get(?PRED_BUC,UserId),
	Pred = proplists:get_value(<<"pred_per">>,UserPredDetls),
	ok = rs:put(?USER_HIS_BUC,TimeStamp,Details++[{<<"user_string">>,UserInputStr},{<<"prediction">>,Pred}]),
	ok = write_pred_to_file(Pred),
	ok = write_pred_to_his_file(UserId),
	ok = write_user_his_file(UserId),
	check_all_atrributes(Pred,Details),
	Pred.

prediction(Details) ->
	UserId = proplists:get_value(<<"user_id">>,Details),
	Ts = erlang:localtime(),
	ok = rs:put(?PRED_BUC,UserId,[{<<"timestamp">>,Ts}|Details]),
	Id = 
		case rs:get(?COUNT_BUC,<<"count">>) of
			{error_not_found} ->
				rs:put(?COUNT_BUC,<<"count">>,1),
				1;
			Count ->
				rs:put(?COUNT_BUC,<<"count">>,Count+1),
				Count+1
		end,
	TimeStamp = 	ts_format(Ts),
	ok = rs:put(?PRED_HIS_BUC,integer_to_binary(Id),[{<<"time">>,TimeStamp}|Details]),	
	<<"posted the predition data">>.


get_user_vals_4_py(UserId) ->
	UserInputDetls = rs:get(?USER_BUC,UserId),	
	io:format("UserInputDetls:::: ~p~n",[UserInputDetls]),
	proplists:get_value(<<"user_string">>,UserInputDetls).
	

check_all_atrributes(Pred,Details) ->
	Age = proplists:get_value(<<"age">>,Details),
	Cp = proplists:get_value(<<"cp">>,Details),
	TrestBps = proplists:get_value(<<"trestbps">>,Details),
	Chol = proplists:get_value(<<"chol">>,Details),
	Slope = proplists:get_value(<<"slope">>,Details),
	Thal = proplists:get_value(<<"thal">>,Details),
	Thalach = proplists:get_value(<<"thalach">>,Details),
	CpData = check_cp(Cp),
	SlopeData=check_slope(Slope),
	ThalData = check_thal(Thal),
	TrestBpsData = check_trestbps(binary_to_integer(TrestBps)),
	CholData = check_chol(binary_to_integer(Chol)),
	ThalachData= check_thalach(binary_to_integer(Thalach),binary_to_integer(Age) div 10 ),
	PredData = [{<<"code">>,<<"prediction">>}]++check_pred(binary_to_float(Pred)),
	FinalData = jsx:encode([PredData,CpData,SlopeData,ThalData,TrestBpsData,CholData,ThalachData]),
	Path = code:priv_dir(hdp_proj) ++ "/js/table_rec.json",
	file:write_file(Path, FinalData).


%%======================================================================================

getuser_age_sex(UserId) ->
	{ok,Keys} = rs:list_keys(?SIGNUP_BUC),
	SignUpDetails = get_details(UserId,Keys),
	Age = proplists:get_value(<<"age">>,SignUpDetails),
	Sex = proplists:get_value(<<"sex">>,SignUpDetails),
	[{<<"age">>,Age},{<<"sex">>,Sex}].


get_details(_,[]) ->
	[];
get_details(UserId,[Key|Tail]) ->
	SignUpDetails = rs:get(?SIGNUP_BUC,Key),
	UserIdL = proplists:get_value(<<"user_id">>,SignUpDetails),
	case UserIdL =:= UserId of
		true ->
			SignUpDetails;
		false ->
			get_details(UserId,Tail)
	end.



check_thalach(Thalach,Age) ->
	PrefThalach = 
	case Age of
		2 -> 200;
		3 -> 190;
		4 -> 180;
		5 -> 170;
		6 -> 160;
		7 -> 170
	end,
	if Thalach >= PrefThalach ->
		[{<<"code">>, <<"thalach">>},
		{<<"value">>, Thalach},
		{<<"description">>,<<"You heart rate is higher than Max Heart rate for your age">>},
					{<<"link">>,<<"http://www.heart.org/HEARTORG/HealthyLiving/PhysicalActivity/FitnessBasics/Target-Heart-Rates_UCM_434341_Article.jsp">>}];
	true ->
		[{<<"code">>, <<"thalach">>},
		{<<"value">>, Thalach},
		{<<"description">>,<<"You heart rate is Normal for your age">>},
					{<<"link">>,<<"http://www.heart.org/HEARTORG/HealthyLiving/PhysicalActivity/FitnessBasics/Target-Heart-Rates_UCM_434341_Article.jsp">>}]
	end.	

			
b2i(A) ->
	binary_to_integer(A).

check_cp(Cp) ->
	CpRes =
	case Cp of
		<<"1">> -> 
			[{<<"value">>, b2i(Cp)},
				{<<"description">>,<<"You have Typical Angina">>},
				{<<"link">>,<<"http://www.webmd.com/pain-management/guide/whats-causing-my-chest-pain?page=4">>}];
		<<"2">> ->
			[{<<"value">>, b2i(Cp)},
				{<<"description">>,<<"You have Atypical Angina">>},
				{<<"link">>,<<"http://www.webmd.com/pain-management/guide/whats-causing-my-chest-pain?page=4">>}];
		<<"3">> ->
			[{<<"value">>, b2i(Cp)},
				{<<"description">>,<<"You have Non-anginal pain">>},
				{<<"link">>,<<"http://www.webmd.com/pain-management/guide/whats-causing-my-chest-pain?page=4">>}];
		<<"4">> ->
			[{<<"value">>, b2i(Cp)},
				{<<"description">>,<<"You dont have any Chest pain">>},
				{<<"link">>,<<"http://www.webmd.com/pain-management/guide/whats-causing-my-chest-pain?page=4">>}]
	end,
	Data = jsx:encode([[{<<"code">>, <<"cp">>}]++CpRes]),
	Path = code:priv_dir(hdp_proj) ++ "/js/cp_rec.json",
	file:write_file(Path, Data),
	[{<<"code">>, <<"cp">>}]++CpRes.
%%=====================================================================================		
check_slope(Slope) ->
	SlopeRes=
	case Slope of
		<<"1">> -> 
			[{<<"value">>, b2i(Slope)},
				{<<"description">>,<<"Upsloping">>},
				{<<"link">>,<<"http://www.ncbi.nlm.nih.gov/pubmed/2480239">>}];
		<<"2">> ->
			[{<<"value">>, b2i(Slope)},
				{<<"description">>,<<"Flat Slope">>},
				{<<"link">>,<<"http://www.ncbi.nlm.nih.gov/pubmed/2480239">>}];
		<<"3">> ->
			[{<<"value">>, b2i(Slope)},
				{<<"description">>,<<"Downsloping">>},
				{<<"link">>,<<"http://www.ncbi.nlm.nih.gov/pubmed/2480239">>}]
	end,
	Data=jsx:encode([[{<<"code">>, <<"slope">>}]++SlopeRes]),
	Path = code:priv_dir(hdp_proj) ++ "/js/slope_rec.json",
	file:write_file(Path, Data),
	[{<<"code">>, <<"slope">>}]++SlopeRes.


%%=====================================================================================		
check_thal(Thal) ->
	Thalres=
	case Thal of
		<<"3">> -> 
			[{<<"value">>, b2i(Thal)},
				{<<"description">>,<<"You dont have Thalassemia">>},
				{<<"link">>,<<"http://www.healthline.com/health/thalassemia#Outlook6">>}];
		<<"6">> ->
			[{<<"value">>, b2i(Thal)},
				{<<"description">>,<<"You have Fixed defect of Thalassemia">>},
				{<<"link">>,<<"http://www.healthline.com/health/thalassemia#Outlook6">>}];
		<<"7">> ->
			[{<<"value">>, b2i(Thal)},
				{<<"description">>,<<"You have Reversable defect of Thalassemia">>},
				{<<"link">>,<<"http://www.healthline.com/health/thalassemia#Outlook6">>}]
	end,
	Data = jsx:encode([[{<<"code">>, <<"thal">>}]++Thalres]),
	Path = code:priv_dir(hdp_proj) ++ "/js/thal_rec.json",
	file:write_file(Path, Data),
	[{<<"code">>, <<"thal">>}]++Thalres.

%%=====================================================================================		
check_trestbps(TrestBps) ->
	TrestBpsRes=
	case TrestBps >= 140 of
		true ->
			[{<<"value">>, TrestBps},
				{<<"description">>,<<"You Have High Blood Pressure">>},
				{<<"link">>,<<"http://www.heart.org/HEARTORG/Conditions/HighBloodPressure/AboutHighBloodPressure/Understanding-Blood-Pressure-Readings_UCM_301764_Article.jsp">>}];
		false ->
			case TrestBps =< 120 of
				true ->
					[{<<"value">>, TrestBps},
						{<<"description">>,<<"Your Blood Pressure type is Pre Hyper Tension">>},
						{<<"link">>,<<"http://www.heart.org/HEARTORG/Conditions/HighBloodPressure/AboutHighBloodPressure/Understanding-Blood-Pressure-Readings_UCM_301764_Article.jsp">>}];
				false ->
					case TrestBps > 90 of
						true ->
							[{<<"value">>, TrestBps},
								{<<"description">>,<<"Normal Blood Pressure">>},
								{<<"link">>,<<"http://www.heart.org/HEARTORG/Conditions/HighBloodPressure/AboutHighBloodPressure/Understanding-Blood-Pressure-Readings_UCM_301764_Article.jsp">>}];
						false ->
							[{<<"value">>, TrestBps},
								{<<"description">>,<<"Low Blood Pressure">>},
								{<<"link">>,<<"http://www.heart.org/HEARTORG/Conditions/HighBloodPressure/AboutHighBloodPressure/Understanding-Blood-Pressure-Readings_UCM_301764_Article.jsp">>}]
					end
			end
	end,
	Data = jsx:encode([[{<<"code">>, <<"trestbps">>}]++TrestBpsRes]),
	Path = code:priv_dir(hdp_proj) ++ "/js/trestbps_rec.json",
	file:write_file(Path, Data),
	[{<<"code">>, <<"trestbps">>}]++TrestBpsRes.

%%=====================================================================================		

check_chol(Chol) ->
	CholRes= 
	case Chol > 240 of
		true  ->
			[{<<"value">>, Chol},
				{<<"description">>,<<"You have High cholestoral">>},
				{<<"link">>,<<"http://www.webmd.com/cholesterol-management/tc/high-cholesterol-exams-and-tests">>}];
		false ->
			case Chol > 200 of 
				true ->
					[{<<"value">>, Chol},
					{<<"description">>,<<"You have Border cholestoral">>},
						{<<"link">>,<<"http://www.webmd.com/cholesterol-management/tc/high-cholesterol-exams-and-tests">>}];	
				false ->
					[{<<"value">>, Chol},
						{<<"description">>,<<"You have Normal cholestoral">>},
						{<<"link">>,<<"http://www.webmd.com/cholesterol-management/tc/high-cholesterol-exams-and-tests">>}]
			end
	end,
	Data = jsx:encode([[{<<"code">>, <<"chol">>}]++CholRes]),
	Path = code:priv_dir(hdp_proj) ++ "/js/chol_rec.json",
	file:write_file(Path, Data),
	[{<<"code">>, <<"chol">>}]++CholRes.	




check_pred(Pred)  ->
	if Pred >= 0.5 ->
		[{<<"value">>, Pred},
			{<<"description">>,<<"Your prediction is near to heart attack Please consult doctor">>},
			{<<"link">>,<<"http://articles.mercola.com/sites/articles/archive/2015/03/12/6-factors-predicting-heart-attack-risk.aspx">>}];
	true ->
		[{<<"value">>, Pred},
			{<<"description">>,<<"You prediction for heart attack is Normal">>},
			{<<"link">>,<<"http://articles.mercola.com/sites/articles/archive/2015/03/12/6-factors-predicting-heart-attack-risk.aspx">>}]
	end.


%%==================================Extra functions========================================


write_user_his_file(UserId) ->
	{ok,Keys}=rs:list_keys(<<"user_his_cache">>),
	Data = jsx:encode(get_user_his(UserId,Keys,[])),
	Path = code:priv_dir(hdp_proj) ++ "/js/userHistory.json",
	file:write_file(Path, Data).

get_user_his(_UserId,[],Res) ->
	Res;

get_user_his(UserId,[Key|Tail],Res) ->
	UsrDetails = rs:get(<<"user_his_cache">>,Key),
	UsrId = proplists:get_value(<<"user_id">>,UsrDetails),
	case UserId =:= UsrId of
		true ->
			L = proplists:delete(<<"action">>,UsrDetails),
			L1 = proplists:delete(<<"age">>,L),
			L2 = proplists:delete(<<"sex">>,L1),
			L3 = proplists:delete(<<"user_id">>,L2),
			L4 = proplists:delete(<<"user_string">>,L3),
			get_user_his(UserId,Tail,Res++[[{<<"timestamp">>,Key}]++L4]);
		false ->
			get_user_his(UserId,Tail,Res)
	end.


write_pred_to_file(Pred) ->
	io:format("PRedddddddd:;:::~p~n",[Pred]),
	PredData = check_pred(binary_to_float(Pred)),
	Data =jsx:encode([[{<<"code">>,<<"prediction">>}]++PredData]),
	io:format("Data::~p~n",[Data]),
	Path = code:priv_dir(hdp_proj) ++ "/js/HDPrediction.json",
	file:write_file(Path, Data).	


write_pred_to_his_file(UserId) ->
	{ok,Keys} = rs:list_keys(?PRED_HIS_BUC),
	PredKeyVal = get_pred_k_v(UserId,sort_keys(Keys),[]),
%%	io:format("PredKeyVal::~p~n",[PredKeyVal]),
	Data = jsx:encode(PredKeyVal),
	Path = code:priv_dir(hdp_proj) ++ "/js/predictionHistory.json",
	file:write_file(Path, Data).

get_pred_k_v(_UserId,[],Res) ->
%%	io:format("PredHis::~p~n",[Res]),
	Res;
%%	lists:ukeysort(1,Res);

get_pred_k_v(UserId,[H|T],Res) ->
	PredDetails = rs:get(?PRED_HIS_BUC,H),
	case proplists:get_value(<<"user_id">>,PredDetails) =:= UserId of
		true ->
			Pred = proplists:get_value(<<"pred_per">>,PredDetails),
			TimeStamp = proplists:get_value(<<"time">>,PredDetails),
			get_pred_k_v(UserId,T,Res++[[{<<"ID">>,H},{<<"prediction">>,binary_to_float(Pred)},{<<"time">>,TimeStamp}]]);
		false ->
			get_pred_k_v(UserId,T,Res)
	end.


i2l(A) ->
	integer_to_list(A).

ts_format(Ts) ->
	{{Y,M,D},{H,Min,S}} = Ts,
	list_to_binary(i2l(Y)++"-"++i2l(M)++"-"++i2l(D)++"T"++i2l(H)++":"++i2l(Min)++":"++i2l(S)).


sort_keys(Keys) ->
	Sorted = lists:sort([binary_to_integer(X)||X<-Keys]),
	[integer_to_binary(X)||X<-Sorted].


get_user_id() ->
	{L,M,N} = os:timestamp(),
	Id = string:join([integer_to_list(L),ran_alpha(),integer_to_list(M),ran_alpha(),integer_to_list(N)],""),
	list_to_binary(Id).

ran_alpha() ->
	List ="ABCDEFGHIJKLMNOPQRSTUVWXYZ",
	Index = random:uniform(length(List)),
	[lists:nth(Index,List)].



get_vals_as_str([],Res) ->
	list_to_binary(string:substr(Res,1,length(Res)-1));
get_vals_as_str([{Key,_Val}|Rest],Res) when (Key =:= <<"user_id">>) ->
	get_vals_as_str(Rest,Res);
get_vals_as_str([{Key,_Val}|Rest],Res) when (Key =:= <<"action">>) ->
	get_vals_as_str(Rest,Res);	
get_vals_as_str([{Key,_Val}|Rest],Res) when (Key =:= <<"user_timestamp">>) ->
	get_vals_as_str(Rest,Res);	
get_vals_as_str([{_,Val}|Rest],Res) ->
	get_vals_as_str(Rest,Res++req_format(Val)++"-").



req_format(Val) ->
	float_to_list(float(binary_to_integer(Val)),[{decimals,1},compact]).




delete(Buc) ->
	{ok,Keys} = rs:list_keys(Buc),
	delete(Buc,Keys).


delete(_Buc,[]) ->
	ok;
delete(Buc,[H|T]) ->
	rs:delete(Buc,H),
	delete(Buc,T).		






