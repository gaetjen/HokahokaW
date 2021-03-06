(* ::Package:: *)

(* Wolfram Language package *)


BeginPackage["HokahokaW`Notebook`",{"HokahokaW`"}];


HHNotebookCreate::usage="Alias for CreateNotebook[]. Takes options to apply \
to the created NotebookObject. Saves the created notebook in \
$HHCurrentNotebook to use in further writing functions";
Options[HHNotebookCreate]=Options[NotebookObject];


HHOptNotebook::usage = "";
HHOptCellType::usage = "";


HHNotebookWriteCell::usage="Use NotebookWrite to write a cell.";
Options[HHNotebookWriteCell]=Join[
	{HHOptNotebook :> $HHCurrentNotebook},
	Options[Cell]
];


HHNotebookSave::usage="Use NotebookSave to save a notebook or \
NotebookPrint to save a *.pdf of the notebook, depending upon the file extension.";
Options[HHNotebookSave]={HHOptNotebook :> $HHCurrentNotebook};


HHNotebookClose::usage="Alias for NotebookClose, applied to $HHCurrentNotebook";
Options[HHNotebookClose]={HHOptNotebook :> $HHCurrentNotebook};


(* ::Section:: *)
(*Private*)


Begin["`Private`"];


$HHCurrentNotebook = Null;


(* ::Subsection:: *)
(*HHNotebookCreate*)


HHNotebookCreate[opts:OptionsPattern[]]:=
Block[{},
	$HHCurrentNotebook = CreateNotebook[];
	If[Length[{opts}]>0, SetOptions[ $HHCurrentNotebook, opts]];
];


HHNotebookCreate[args___]:=Message[HHNotebookCreate::invalidArgs,{args}];


(* ::Subsection:: *)
(*HHNotebookWriteCell*)


HHNotebookWriteCell[contents_List, cellStyle___String, opts:OptionsPattern[]] := 
	HHNotebookWriteCell[#, cellStyle, opts]& /@ contents;


HHNotebookWriteCell[contents_String, cellStyle___String, opts:OptionsPattern[]] := 
NotebookWrite[ OptionValue[ HHOptNotebook ],
	Cell[ contents, cellStyle, opts ]
];


HHNotebookWriteCell[contents_, cellStyle___String, opts:OptionsPattern[]] := 
NotebookWrite[ OptionValue[ HHOptNotebook ],
	Cell[ BoxData[ToBoxes[ contents ]], 
			FilterRules[{opts}, Options[Cell]], cellStyle, opts 
	]
];


HHNotebookWriteCell[args___]:=Message[HHNotebookWriteCell::invalidArgs,{args}];


(* ::Subsection:: *)
(*HHNotebookSave*)


HHNotebookSave[fileName_String, opts:OptionsPattern[]]:=
If[ StringMatchQ[ fileName, __~~".nb" ],
	NotebookSave[ OptionValue[HHOptNotebook], fileName ],
	If[ StringMatchQ[ fileName, __~~".pdf" ],
		NotebookPrint[ OptionValue[HHOptNotebook], fileName ],
		NotebookSave[ OptionValue[HHOptNotebook], fileName<>".nb" ]
	]
];	


HHNotebookSave[args___]:=Message[HHNotebookSave::invalidArgs,{args}];


(* ::Subsection:: *)
(*HHNotebookClose*)


HHNotebookClose[opts:OptionsPattern[]]:= NotebookClose[ OptionValue[HHOptNotebook] ];


HHNotebookClose[args___]:=Message[HHNotebookClose::invalidArgs,{args}];


(* ::Section:: *)
(*Ending*)


End[];
EndPackage[];


(* ::Section:: *)
(*Bak*)
