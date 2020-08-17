(* Visual Configuration *)

(* Dark theme *) (*
Color = <|
	"Back"    -> "#181A1B", 
	"Font"    -> "#DDDDDD", 
	"Gray"    -> "#404548",
	"Purple"  -> "#43008A",
	"Blue"    -> "#0059A8",
	"Green"   -> "#589F17",
	"Yellow"  -> "#C19D09",
	"Orange"  -> "#B86000",
	"Red"     -> "#A81414",
	"Magenta" -> "#900769"
|> *)

(* Light theme, based on https://www.schemecolor.com/twisted-rainbow.php *)
Color = <|
	"Back"    -> "#FFFFFF",
	"Font"    -> "#000000",
	"Gray"    -> "#848484",
	"Purple"  -> "#5400AC",
	"Blue"    -> "#006FD3",
	"Green"   -> "#6EC81D",
	"Yellow"  -> "#FFE620",
	"Orange"  -> "#FF9420",
	"Red"     -> "#E73131",
	"Magenta" -> "#B40983"
|>
backgroundHex = Color["Back"]
Color = Map[RGBColor,Color]

fontStyle = {
	FontFamily -> "Ubuntu Mono",
	FontSize -> 16,
	FontColor -> Color["Font"]
}

Styled[s_String] := Style[s,Sequence@@fontStyle]

l = 3.00 (* horizontal lenght of the days *)
r = 0.20 (* rounding radius *)
d = 0.02 (* streching factor *)


(* Utility functions *)

WeekDay[s_String] := First@FirstPosition[{"Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"}, s]
WeekDay::usage = "Takes a weekday name string and returns its number. WeekDay[\"Monday\"] is 1."

DecimalHour[s_String] := #1 + #2/60 & @@ ToExpression@StringSplit[s, ":"]
DecimalHour::usage = "Takes a 24 clock hour hh:mm and returns its decimal form."

ProcessCSV[{day_,name_,start_,end_,color_,room_}] := <|
	"Day"     -> WeekDay[day],
	"Name"    -> name,
	"Start"   -> -DecimalHour[start], (*negative because schedules are read top to bottom *)
	"End"     -> -DecimalHour[end],
	"Color"   -> Color[color],
	"Tooltip" -> start<>"-"<>end<>"&#013;"<>room
|>
ProcessCSV::usage = "ProcessCSV[list] returns an Association with the information needed to make a schedule. 
Fields are strings Day, Name, Start, End, Color and Tooltip."

RectanglePosition[c_Association] := {
	{l(c["Day"]+d  ),c["Start"]}, (* xmin, ymin *)
	{l(c["Day"]+1-d),c["End"]  }  (* xmax, ymax *)
}

(* Main *)

path = $ScriptCommandLine[[2]]
rawData = Import[path][[2;;]]
cleanData = Map[ProcessCSV,rawData]

(* make rectangles *)
positions = RectanglePosition[#]& /@ cleanData
rectangles = Map[Apply[Rectangle],positions]
roundedRectangles = Replace[#, f_[a_,b_] :> f[a,b,RoundingRadius->r]]& /@ rectangles
tooltipRectangles = Apply[Tooltip[#1,#2]&] /@ Transpose[{roundedRectangles,cleanData[[All,"Tooltip"]]}]
colorRectangles = Riffle[cleanData[[All,"Color"]],tooltipRectangles]

(* make text *)
textPositions = Map[Mean,positions]
styledText = Styled /@ cleanData[[All,"Name"]]
text = Apply[Text] /@ Transpose[{styledText,textPositions}]

g = Graphics[
	colorRectangles~Join~text,
	Background->Color["Back"],
	ImageSize->700
]

fig = StringReplace[
	ExportString[g, "HTML", "FullDocument" -> False], {
		RegularExpression["(?<=src=)[\\s\\S]+(?= width)"] -> "\"schedule.svg\" ", 
 		"<p class=\"Output\">" -> "", 
		"</p>" -> ""
	}
]

doc = StringReplace[
"<!DOCTYPE html>
<html>
<head>
	<title>
		Schedule
	</title>
	<meta charset=\"utf-8\"/>
	<style>
		body {background-color: BGC;}
	</style>
</head>
<body>
	<center>
		fig
	</center>
</body>
</html>
",{"BGC"->backgroundHex,"fig"->fig}]

Quiet[CreateDirectory["results"]]
file = OpenWrite["./results/schedule.html"]
Export["./results/schedule.svg",g]
WriteString[file,doc]


