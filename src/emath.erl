-module(emath).
-include_lib("eunit/include/eunit.hrl").
-include_lib("deps/edat/src/edat.hrl").
-export([s/2, u/2, i/2]).
-author("ea1a87").

%% Неиспользуемые в настоящий момент функции
-compile([{nowarn_unused_function, [
	{module, 1},
	{square, 1},
	{root	 , 1}
]}]).

comp({Type, Val, Angle}) -> {Type, Val, -Angle}.

is_current({current, _, _}) -> true;
is_current(_)								-> false.

is_voltage({voltage, _, _}) -> true;
is_voltage(_)								-> false.

is_impedance({z, _, _}) -> true;
is_impedance(_)					-> false.

is_power({power, _, _}) -> true;
is_power(_) -> false.

%% @doc функция смены типа электрических величин. Поскольку в математических операциях типы не имеют смысла, необходимо их приводить к требуемому результату в конце вычислений.
-spec change_type(A, Type) -> {Type, number(), number()} when
	A :: complex_number(),
	Type :: atom().
change_type(A, Type) -> {_, A1, A2} = A, {Type, A1, A2}.

%% @doc Умножение двух комплексных чисел в показательной форме
-spec mulc(A, B) -> {ok, Value, Angle} when
	A :: complex_number(),
	B :: complex_number(),
	Value :: number(), % модуль комплексного числа
	Angle :: number(). % угол комплексного числа
mulc(A, B) ->
	{_	 , Ar	, JA	 } = A,
	{_   , Br	, JB   } = B,
	{ok	 , Ar*Br, JA+JB}.
mulc_test() ->
	?_assert(mulc({v, 1, 30}, {c, 3, -60}) =:= {ok, 3, -30}).

%% @doc получение модуля комплексного числа
-spec module(A) -> Module when
	A :: complex_number(),
	Module :: number().
module(A) ->
	{_, Val, Angle} = A,
	A = Val * math:cos(Angle),
	B = Val * math:sin(Angle),
	math:sqrt(A*A+B*B).

%% @doc возведение комплексного числа в квадрат
-spec square(A) -> B when
	A :: complex_number(),
	B :: complex_number().
square(A) -> mulc(A, A).

%% @doc Извлечение корня из комплексного числа
-spec root(A) -> B when
	A :: complex_number(),
	B :: complex_number().
root(A) ->
	{Type, _Value, Angle} = A,
	{Type, math:sqrt(module(A)), Angle/2}.


-spec divc(A, B) -> {ok, Value, Angle} when
	A :: complex_number(),
	B :: complex_number(),
	Value :: number(), % модуль комплексного числа
	Angle :: number(). % угол комплексного числа
%% @doc Деление двух компллексных чисел в показательной форме
divc(Ac, Bc) ->
	{_	 , Ar, JA} = Ac,
	{_	 , Br, JB} = Bc,
	{ok	 , Ar/Br, JA-JB}.

-spec s(ElectricValueA, ElectricValueB) -> power() when
	ElectricValueA :: complex_number(),
	ElectricValueB :: complex_number().
%% @doc Функция возвращающая полную можность исходя из заданных двух любых величин
s(A1, A2) ->
	A1c = is_current	(A1),
	A2c = is_current	(A2),
	A1v = is_voltage	(A1),
	A2v = is_voltage	(A2),
	A1z = is_impedance(A1),
	A2z = is_impedance(A2),
	if
		A1c and A2v ->
			I = comp(A1),	% Î
			U = A2,
			S = mulc(U, I),		% S=U*Î
			change_type(S, power);
		A1v and A2c ->
			I = comp(A2),	% Î
			U = A1,
			S = mulc(U, I),		% S=U*Î
			change_type(S, power);
		A1c and A2z ->
			I = comp(A1),			% Î
			U = mulc(A1, A2), % U=Z*I
			S = mulc(U, I),		% S=U*Î
			change_type(S, power);
		A1z and A2c ->
			I = comp(A2),			% Î
			U = mulc(A1, A2), % U=Z*I
			S = mulc(U, I),		% S=U*Î
			change_type(S, power);
		A1v and A2z ->
			U = A1,
			II= divc(A1,A2),	% I = U/Z
			I = comp(II),			% Î
			S = mulc(U, I),		% S=U*Î
			change_type(S, power);
		A2v and A1z ->
			U = A2,
			II= divc(A2,A1),	% I = U/Z
			I = comp(II),			% Î
			S = mulc(U, I),		% S=U*Î
			change_type(S, power);
		true				-> error(badarg)
end.
s_test_() ->
	I = {current, 1, 30},
	U = {voltage, 4, 10},
	Z = {z			, 2,-30},
	[
		?_assert(s(I, U) =:= {power	, 4		,-20}),
		?_assert(s(U, I) =:= {power	, 4		,-20}),
		?_assert(s(I, Z) =:= {power	, 2		,-30}), % U=Z*I=2<0, Î=1<-30, S=2<-30
		?_assert(s(Z, I) =:= {power	, 2		,-30}),
		?_assert(s(U, Z) =:= {power	, 8.0 ,-30}), % I=U/Z=2<40, Î=4<-40, S=8<-30
		?_assert(s(Z, U) =:= {power	, 8.0 ,-30})
].

%% @doc Функция возвращающая напряжение исходя из заданных двух любых величин
-spec u(ElectricValueA, ElectricValueB) -> voltage() when
	ElectricValueA :: complex_number(),
	ElectricValueB :: complex_number().
u(A1, A2) ->
	A1c = is_current	(A1),
	A2c = is_current	(A2),
	A1p = is_power		(A1),
	A2p = is_power		(A2),
	A1z = is_impedance(A1),
	A2z = is_impedance(A2),
	if
		A1c and A2p ->
			I = comp(A1),	% Î
			S = A2,
			U = divc(S, I),		% S=U*Î
			change_type(U, voltage);
		A1p and A2c ->
			I = comp(A2),	% Î
			S = A1,
			U = divc(S, I),		% S=U*Î
			change_type(U, voltage);
		A1c and A2z ->
			I = A1,
			Z = A2,
			U = mulc(Z, I),		% U=Z*I
			change_type(U, voltage);
		A1z and A2c ->
			I = A2,
			Z = A1,
			U = mulc(Z, I),		% U=Z*I
			change_type(U, voltage);
		(A1p and A2z) or (A1z and A2p) ->
			error(not_impemented);
		% TODO: di it later
		%%A1p and A2z ->
			%%S = A1,
			%%Z = A2,
			% S=U*Î, U = S / Î = S /(U/Z)^ = (S * Z^) / Û => U*Û = S*Z^ -> |U|^2 = S*Z^
			%%Zc= comp(Z),
			% |U|^2 = S*Z^ -> |U| = sqrt(a*a+b*b) -> (sqrt(a*a+b*b))^2 = S *Z^
			%
			% I = U/Z
		true				-> error(badarg)
end.
u_test_() ->
	I = {current, 1, 30},
	Z = {z			, 2,-30},
	S = {power	,	4,-60},
	[
		?_assert(u(I, S) =:= {voltage , 4.0,-30}), % Î=1<-30, U=S/Î=4<-30
		?_assert(u(S, I) =:= {voltage	, 4.0,-30}),
		?_assert(u(I, Z) =:= {voltage	, 2  ,  0}), % U=Z*I=2<0
		?_assert(u(Z, I) =:= {voltage	, 2  ,  0})
].

%% @doc Функция возвращающая ток исходя из заданных двух любых величин
-spec i(ElectricValueA, ElectricValueB) -> current() when
	ElectricValueA :: complex_number(),
	ElectricValueB :: complex_number().
i(A1, A2) ->
	A1p = is_power		(A1),
	A2p = is_power		(A2),
	A1v = is_voltage	(A1),
	A2v = is_voltage	(A2),
	A1z = is_impedance(A1),
	A2z = is_impedance(A2),
	if
		A1p and A2v ->
			S = A1,
			U = A2,
			I= comp(divc(S,U)),
			change_type(I, current);
		A1v and A2p ->
			S = A2,
			U = A1,
			I= comp(divc(S,U)),
			change_type(I, current);
		A1v and A2z ->
			U = A1,
			Z = A2,
			I = divc(U,Z),	% I = U/Z
			change_type(I, current);
		A2v and A1z ->
			U = A2,
			Z = A1,
			I = divc(U,Z),	% I = U/Z
			change_type(I, current);
		true				-> error(badarg)
end.
i_test_() ->
	U = {voltage, 4, 10},
	Z = {z			, 2,-30},
	S = {power	, 4,-60},
	[
		?_assert(i(S, U) =:= {current, 1.0, 70}), % Î=S/U=1<-70, I=1<70
		?_assert(i(U, S) =:= {current, 1.0, 70}),
		?_assert(i(U, Z) =:= {current, 2.0, 40}), % I=U/Z=2<40
		?_assert(i(Z, U) =:= {current, 2.0, 40})
].
