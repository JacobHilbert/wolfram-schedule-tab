(* Generalities *)
DayNumbers[s_String]  :=  ReplaceAll[Characters[s],Thread[Characters["LMIJV"]->Range[5]]]
HourValue[t_TimeObject]  :=  First[t].{1,1/60}
Hack[s_String, size_Integer, a___]  :=  Style[s,FontFamily->"Hack",size,a]

(* Import and process schedule data. All could be in one line, but no *)
data = Values /@ Normal[SemanticImport[schedule]];
data = MapThread[#1->Table[Session[i,#3,#4,#5],{i,DayNumbers[#2]}]&,Transpose[data]];
data = Merge[Flatten@*Join]@data;
data = ReplaceAll[Normal[data],Rule[k_,v_]:>{k,v}];
data = Transpose[Join[{Range[Length[data]]},Transpose@RandomSample[data]]];

(* graphics definitions *)
l = 2.50; (*horizontal lenght of the days*)
r = 0.20; (*rounding radius*)
d = 0.01; (*streching factor*)
colors = ColorData["BlueGreenYellow"] /@ Subdivide[Length[data]-1];
fontColors = ColorData["BlueGreenYellow"] /@ Mod[Subdivide[Length[data]-1]+0.5,1];

SessionGraphics[{index_, name_, session_Session}] := Block[{ycenter,yrange,day,start,end,place},
	{day,start,end,place} = List@@session;
	start = HourValue[start];end = HourValue[end];
	ycenter = -(start+end)/2;
	yrange = end-start;
	{
		colors[[index]],Rectangle[{l(day-0.5+d),-end},{l(day+0.5-d),-start},RoundingRadius->r],
		fontColors[[index]],Text[Hack[name,20,Bold],{day l,ycenter+yrange/6}],Text[Hack[place,10],{day l,ycenter-yrange/6}]
	}
]

LectureGraphics[{index_, name_, sessions_List}] := Table[SessionGraphics[{index,name,s}],{s,sessions}]

yticks = {-HourValue[#],DateString[#]}& /@ Flatten[data[[All,3]]][[All,2]];
xticks = {Range[5]l,{"Lunes","Martes","Miércoles","Jueves","Viernes"}}\[Transpose];

Graphics[
	LectureGraphics /@ data,
	ImageSize->1000,ImagePadding->50,
	Frame->True,FrameStyle->Black,FrameTicks->{xticks,yticks},FrameTicksStyle->Directive[Black,12,FontFamily->"Hack"],
	GridLines->{None,yticks[[All,1]]},GridLinesStyle->LightGray
]