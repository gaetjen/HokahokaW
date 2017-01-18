(* ::Package:: *)

(* Wolfram Language package *)

BeginPackage["HokahokaW`Graphics`", {"HokahokaW`"}];


(* ::Section:: *)
(*Declarations*)


HHOptLabelStyleSpecifications::usage = "Option for HHLabelGraphics.";


(* ::Subsection::Closed:: *)
(*HHStackLists / HHListLineStackPlot (HHListLinePlotStack)*)


HHStackLists::usage = 
"HHStackLists takes lists and stacks the values (e.g. for stacked list plots with HHListLineStackPlot[])";

Options[HHStackLists] = {HHOptBaselineCorrection -> None(*, HHOptStack -> Automatic*)};


HHOptBaselineCorrection::usage =
"Option for HHStackTraces and HHListLinePlotStack. Specify how to correct the baseline for \
individual traces. Specify a function: for example, Mean  (the default) will subtract \
individual trace means, First will subtract the first value. \
(#[[1]]*2)& will subtract twice the First value.";


HHOptStack::usage="Option for HHStackTraces and HHListLinePlotStack. \
By what interval to stack lists. \n
Automatic: stack at x1.1 of the 95% Min-Max \
quantile (i.e. Quantile[ (# - Min[#])&[ Flatten[traces] ], 0.95]*1  \n \
None: no increment";


HHPlotRangeClipping::usage="";


HHListLineStackPlot::usage=
"HHListLineStaciPlot plots multiple traces together, stacked vertically.";

(*HHListLinePlotStack::usage=
"DEPRECATED HHListLinePlotStack plots multiple traces together, stacked vertically.";*)


HHListLineStackPlot$UniqueOptions = { };
HHListLineStackPlot$OverrideOptions = { PlotRange -> Automatic};
 
Options[HHListLineStackPlot] =
HHJoinOptionLists[
	HHListLineStackPlot$UniqueOptions, 
	HHListLineStackPlot$OverrideOptions,
	Options[HHStackLists],
	Options[ListLinePlot]
];


(*HHListLinePlotStack$UniqueOptions = {
	HHPlotRangeClipping -> Automatic
	(*HHStackLists->Automatic,*) (*HHStackAxes->False,*)(* HHOptBaselineCorrection-> Mean*)
};
HHListLinePlotStack$OverrideOptions = { AspectRatio -> 1/2, PlotRange -> All };
 
Options[HHListLinePlotStack] =
HHJoinOptionLists[
	HHListLinePlotStack$UniqueOptions, 
	HHListLinePlotStack$OverrideOptions,
	Options[HHStackLists],
	Options[ListLinePlot]
];*)


(* ::Subsection::Closed:: *)
(*HHListLinePlotMean*)


HHListLinePlotMean::usage= "HHListLinePlotMean plots multiple traces together, along with mean and standard error.";


HHMeanPlot::usage= "Option for HHListLinePlotMean. Whether to plot a mean trace in NNListLinePlotMean. True (plots mean) or False/None,  or \
functional specification such as Mean, Median, etc.";
HHMeanPlotStyle::usage= "PlotStyle for mean trace in NNListLinePlotMean.";

HHErrorPlot::usage= "Option for HHListLinePlotMean. Whether to plot error bound traces in NNListLinePlotMean.";
HHErrorPlotStyle::usage= "Option for HHListLinePlotMean. How to plot the upper and lower error bounds, also see HHErrorPlotFillingStyle.\
True, False/None, or \"StandardDeviation\", \"StandardError\", \"Quartiles\", \"MinMax\".";
HHErrorPlotFillingStyle::usage= "Option for HHListLinePlotMean. How to shade between the upper and lower error bounds, also see HHErrorPlotStyle.";


HHListLinePlotMean$UniqueOptions = 
	{
	HHMeanPlot -> True, HHMeanPlotStyle->Directive[Opacity[0.5]], 
	HHErrorPlot -> True,  HHErrorPlotStyle -> None, HHErrorPlotFillingStyle -> Automatic
	};
HHListLinePlotMean$OverrideOptions = { PlotStyle -> None };

Options[HHListLinePlotMean] =
HHJoinOptionLists[
	HHListLinePlotMean$UniqueOptions, 
	HHListLinePlotMean$OverrideOptions,
	Options[ListLinePlot]
];


(* ::Subsection:: *)
(*HHLabelGraphics*)


HHLabelGraphics::usage= "Labels a graphic with information on one of the corners.";
Options[HHLabelGraphics]={ HHOptLabelStyleSpecifications -> Tiny };


(* ::Subsection:: *)
(*HHExploreGraphicSlider*)


HHExploreGraphicSlider::usage= "Pass a Graphics object to explore it by dynamically changing the PlotRange with the help of Sliders.";


(* ::Subsection:: *)
(*HHExploreGraphicMouse*)


HHExploreGraphicMouse::usage= "Pass a Graphics object to explore it by zooming and panning with left and right mouse buttons respectively.";


(* ::Subsection::Closed:: *)
(*Image Related*)


HHImageMean::usage="Gives the mean of a series of images. Image data must have the same dimensions and depths.";
HHImageCommon::usage="Gives the most common pixel cluster for each pixel in a series of images.  Image data must have the same dimensions and depths.";
HHImageDifference::usage="Filters an image list based on the common and threshold lists generated by HHImageCommon.";
Options[HHImageDifference]={Normalized->False};

HHImageSubtract::usage="Subtracts two images to give the difference.";


HHImageThresholdNormalize::usage="Normalizes an image to uniform brightness after thresholding.";
HHImageThresholdLinearNormalize::usage="Normalizes an image to uniform summed vector length after thresholding.";


HHImageThreshold::usage="Thresholds an image by closeness to the given color.";
HHImageThresholdLinear::usage="Thresholds an image by linear closeness to the given color.";


(* //ToDo2 create HHImageTestImage[] for help files??*)


(* ::Section:: *)
(*Private*)


Begin["`Private`"];


(* ::Subsection::Closed:: *)
(*HHStackLists*)


HHStackLists[
	traces_ /; Length[Dimensions[traces]]==2, 
	increment_/;NumericQ[increment], 
	opts:OptionsPattern[]
] :=
Block[{tempTraces, temp, 
		opHHOptBaselineCorrection, baselineSubtractFactors, 
		opHHOptStack, stackAddFactors, stackFactorsCumulated},
	
	tempTraces = traces;

	opHHOptBaselineCorrection = OptionValue[HHOptBaselineCorrection];

	(*====================*)
	(* Baseline subtraction *)
	(*====================*)
	baselineSubtractFactors = Switch[opHHOptBaselineCorrection,
		None, None,
		(*This covers specifications such as (#[[1]])& *)
		f_/;HHFunctionQ[f],
		    opHHOptBaselineCorrection/@traces, 
		(*This covers specifications such as Mean and First, which are function names *)
		f_/;(Quiet[temp=f[#]&/@traces]; And@@(NumericQ /@ temp) ), 
			temp, 
		_, Message[ HHStackLists::invalidOptionValue, "HHOptBaselineCorrection", ToString[opHHOptBaselineCorrection]]; 
			None
	];
	If[ baselineSubtractFactors =!= None,
		tempTraces = tempTraces - baselineSubtractFactors
	];

	(*====================*)
	(* Stack incrementation *)
	(*====================*)
	stackFactorsCumulated = FoldList[Plus, 0, Table[ increment, {Length[traces]}] ];
	tempTraces + stackFactorsCumulated[[ ;; -2]]

  ];


(*Stack lists of {{t1, x1}, {t2, x2}, ...} pairs in the second dimension*)
HHStackLists[
	traces_ /; (Length[Dimensions[traces]] == 3 && Union[(Dimensions /@ traces)[[All, 2]]]=={2}), 
	increment_/;NumericQ[increment], 
	opts:OptionsPattern[]] :=
Block[{tempTimes, tempTraces},

	tempTimes = traces[[All, All, 1]];
	tempTraces = traces[[All, All, 2]];

	tempTraces =  HHStackLists[tempTraces, increment, opts];

	Transpose /@ MapThread[{#1, #2}&, {tempTimes, tempTraces}]
];


(* ::Subsubsection::Closed:: *)
(*Old Signatures*)


HHStackLists[traces_ /; Depth[traces]==3, opts:OptionsPattern[]] :=
Block[{tempTraces, temp, 
		opHHOptBaselineCorrection, baselineSubtractFactors, 
		opHHOptStack, stackAddFactors, stackFactorsCumulated},
	
	Message[ HHStackLists::deprecatedSignature ];

	tempTraces = traces;

	opHHOptBaselineCorrection = OptionValue[HHOptBaselineCorrection];

	(*====================*)
	(* Baseline subtraction *)
	(*====================*)
	baselineSubtractFactors = Switch[opHHOptBaselineCorrection,
		None, None,
		f_/;HHFunctionQ[f],    opHHOptBaselineCorrection/@traces, (*This covers specifications such as Mean and First or (#[[1]])& *)
		f_/;(Quiet[temp=f[#]&/@traces]; And@@(NumericQ /@ temp) ), 
					temp, (*This covers specifications such as Mean and First or (#[[1]])& *)
		_, Message[ HHStackLists::invalidOptionValue, "HHOptBaselineCorrection", ToString[opHHOptBaselineCorrection]]; 
		   None
	];
	If[ baselineSubtractFactors =!= None,
		tempTraces = tempTraces - baselineSubtractFactors
	];
	
	(*====================*)
	(* Stack incrementation *)
	(*====================*)
	opHHOptStack = OptionValue[HHOptStack];
	stackAddFactors = Switch[ opHHOptStack,
		None,                    None,
		Automatic,               Table[ Quantile[ (# - Min[#])&[ Flatten[traces] ], 0.95]*1.1, {Length[traces]}], (*- Subtract@@MinMax[ Flatten[traces] ]*)
		x_/;NumericQ[x],         Table[ opHHOptStack, {Length[traces]}],
		f_/;HHFunctionQ[f],      Table[ opHHOptStack[ Flatten[traces] ], {Length[traces]}], 
										(*This covers specifications such as Mean[#]& or (#[[1]])& *)
		f_/;(Quiet[temp=f[ Flatten[traces]]]; And@@(NumericQ /@ temp) ), 
								  temp, (*This covers specifications such as Mean and First *)
		_, Message[ HHStackLists::invalidOptionValue, "HHOptStack", ToString[opHHOptStack]]; Table[0, {Length[traces]}]
	];
	stackFactorsCumulated = FoldList[Plus, 0, stackAddFactors];
	$ActualStackRange = {- stackAddFactors[[1]], stackFactorsCumulated[[ -1 ]]};
	tempTraces + stackFactorsCumulated[[ ;; -2]](*FoldList[Plus, 0, stackAddFactors[[ ;; -2]] ]*)
						(*last stack add factor is not used here... nothing to stack on top*)

   ];


(*Stack lists of {{t1, x1}, {t2, x2}, ...} pairs in the second dimension*)
HHStackLists[
	traces_ /; (Depth[traces]==4 && Union[(Dimensions /@ traces)[[All, 2]]]=={2}), 
	opts:OptionsPattern[]] :=

Block[{tempTimes, tempTraces},

	Message[ HHStackLists::deprecatedSignature ];

	tempTimes = traces[[All, All, 1]];
	tempTraces = traces[[All, All, 2]];

	tempTraces =  HHStackLists[tempTraces, opts];

	Transpose /@ MapThread[{#1, #2}&, {tempTimes, tempTraces}]
];


(* ::Subsubsection:: *)
(*Fallthrough*)


HHStackLists[args___] := Message[HHStackLists::invalidArgs, {args}];


(* ::Subsection::Closed:: *)
(*HHListLineStackPlot*)


(*Used to pass variables to HHListLinePlotStack in an extra-functional manner*)
$ActualStackRange={0,0};


HHListLineStackPlot[
	traces_/;(Length[Dimensions[traces]] == 2 || 
		(Length[Dimensions[traces]] == 3 && Union[(Dimensions /@ traces)[[All, 2]]]=={2})), 
	increment_/;NumericQ[increment], 
	opts:OptionsPattern[]
]:=
Block[{tempData, tempPlotRangeOpts},
	
	tempData = HHStackLists[traces, increment, Sequence@@FilterRules[{opts}, Options[HHStackLists]]];
	tempPlotRangeOpts = 
		If[ OptionValue[PlotRange] === Automatic, 
			{PlotRange -> {All, {- increment/2, (Length[traces]-1/2)*increment}},
			AxesOrigin -> If[OptionValue[AxesOrigin] === Automatic, {Automatic, - increment/2}, OptionValue[AxesOrigin]]},
			{PlotRange -> OptionValue[PlotRange]}
		];

	ListLinePlot[tempData,
		Sequence@@HHJoinOptionLists[ ListLinePlot, tempPlotRangeOpts, {opts}, HHListLineStackPlot$UniqueOptions ]
	]
];


HHListLineStackPlot[args___] := Message[HHListLineStackPlot::invalidArgs, {args}];


(* ::Subsubsection:: *)
(*BAK: HHListLinePlotStack (Old Signature)*)


(*HHStackLists[traces_ /; Depth[traces]==3, opts:OptionsPattern[]] :=
Block[{tempTraces, temp, 
		opHHOptBaselineCorrection, baselineSubtractFactors, 
		opHHOptStack, stackAddFactors, stackFactorsCumulated},
	
	Message[ HHStackLists::deprecatedSignature ];

	tempTraces = traces;

	opHHOptBaselineCorrection = OptionValue[HHOptBaselineCorrection];

	(*====================*)
	(* Baseline subtraction *)
	(*====================*)
	baselineSubtractFactors = Switch[opHHOptBaselineCorrection,
		None, None,
		f_/;HHFunctionQ[f],    opHHOptBaselineCorrection/@traces, (*This covers specifications such as Mean and First or (#[[1]])& *)
		f_/;(Quiet[temp=f[#]&/@traces]; And@@(NumericQ /@ temp) ), 
					temp, (*This covers specifications such as Mean and First or (#[[1]])& *)
		_, Message[ HHStackLists::invalidOptionValue, "HHOptBaselineCorrection", ToString[opHHOptBaselineCorrection]]; 
		   None
	];
	If[ baselineSubtractFactors =!= None,
		tempTraces = tempTraces - baselineSubtractFactors
	];
	
	(*====================*)
	(* Stack incrementation *)
	(*====================*)
	opHHOptStack = OptionValue[HHOptStack];
	stackAddFactors = Switch[ opHHOptStack,
		None,                    None,
		Automatic,               Table[ Quantile[ (# - Min[#])&[ Flatten[traces] ], 0.95]*1.1, {Length[traces]}], (*- Subtract@@MinMax[ Flatten[traces] ]*)
		x_/;NumericQ[x],         Table[ opHHOptStack, {Length[traces]}],
		f_/;HHFunctionQ[f],      Table[ opHHOptStack[ Flatten[traces] ], {Length[traces]}], 
										(*This covers specifications such as Mean[#]& or (#[[1]])& *)
		f_/;(Quiet[temp=f[ Flatten[traces]]]; And@@(NumericQ /@ temp) ), 
								  temp, (*This covers specifications such as Mean and First *)
		_, Message[ HHStackLists::invalidOptionValue, "HHOptStack", ToString[opHHOptStack]]; Table[0, {Length[traces]}]
	];
	stackFactorsCumulated = FoldList[Plus, 0, stackAddFactors];
	$ActualStackRange = {- stackAddFactors[[1]], stackFactorsCumulated[[ -1 ]]};
	tempTraces + stackFactorsCumulated[[ ;; -2]](*FoldList[Plus, 0, stackAddFactors[[ ;; -2]] ]*)
						(*last stack add factor is not used here... nothing to stack on top*)

   ];*)


(*(*Stack lists of {{t1, x1}, {t2, x2}, ...} pairs in the second dimension*)
HHStackLists[
	traces_ /; (Depth[traces]==4 && Union[(Dimensions /@ traces)[[All, 2]]]=={2}), 
	opts:OptionsPattern[]] :=

Block[{tempTimes, tempTraces},

	Message[ HHStackLists::deprecatedSignature ];

	tempTimes = traces[[All, All, 1]];
	tempTraces = traces[[All, All, 2]];

	tempTraces =  HHStackLists[tempTraces, opts];

	Transpose /@ MapThread[{#1, #2}&, {tempTimes, tempTraces}]
];*)


(*HHListLinePlotStack[
	traces_/;(Depth[traces]==3 || (Depth[traces]==4 && Union[(Dimensions /@ traces)[[All, 2]]]=={2})), 
	opts:OptionsPattern[]
]:=
Block[{tempData,tempPlotRange},

	Message[ HHStackLists::deprecatedSignature ];

	
	tempData = HHStackLists[traces, Sequence@@FilterRules[{opts}, Options[HHStackLists]]];
	tempPlotRange = If[ OptionValue[HHPlotRangeClipping] === Automatic, {PlotRange->{All, $ActualStackRange}},{}];
		

	ListLinePlot[tempData,
		Sequence@@HHJoinOptionLists[ ListLinePlot, {tempPlotRange}, {opts}, HHListLinePlotStack$UniqueOptions ]
	]
];*)


(*HHListLinePlotStack[args___] := Message[HHListLinePlotStack::invalidArgs, {args}];*)


(* ::Subsection::Closed:: *)
(*HHListLinePlotMean*)


HHListLinePlotMean[traces_/;(Length[Dimensions[traces]]==2 && Length[Union[Length/@traces]]==1), opts:OptionsPattern[]]:=
Block[{temp,
		tempMeanData = {}, 
		tempErrorMeanData = {}, tempErrorData1 = {}, tempErrorData2 = {},
		opPlotStyle,
		opMeanPlot, opMeanPlotStyle,
		opErrorPlot, opErrorPlotStyle, opErrorPlotFillingStyle, 
		grMean, grError, grErrorFilling, grMain},

	opPlotStyle=OptionValue[PlotStyle];
	opMeanPlot=OptionValue[HHMeanPlot];	opMeanPlotStyle=OptionValue[HHMeanPlotStyle];
	
	opErrorPlot=OptionValue[HHErrorPlot]; opErrorPlotStyle=OptionValue[HHErrorPlotStyle]; 
	opErrorPlotFillingStyle=OptionValue[HHErrorPlotFillingStyle];
	If[ MemberQ[{False, None, Null}, opErrorPlotStyle] ==  None && MemberQ[{False, None, Null}, opErrorPlotFillingStyle], opErrorPlot = False];
	
	(*==========Process data==========*)
	tempMeanData = Switch[ opMeanPlot,
		x_/;MemberQ[{False, None, Null}, x],    {},
		True,                                    Mean[traces],
		f_/;HHFunctionQ[f],                     opMeanPlot/@Transpose[traces],
		f_/;(Quiet[temp=f[#]&/@Transpose[traces]]; And@@(NumericQ /@ temp) ), 
												temp,
		_, Message[ HHListLinePlotMean::invalidOptionValue, "HHMeanPlot", ToString[opMeanPlot]]; 
												{}(*Table[0, {Length[traces[[1]]]}]*)
	];
	
	Switch[ opErrorPlot ,
		x_/;MemberQ[{False, None, Null}, x], Null,
		x_/;MemberQ[{True, "StandardError"}, x], (
			tempErrorMeanData = Mean[traces];
			tempErrorData1 = StandardDeviation[traces]/Sqrt[Length[traces]];
		),
		x_/;MemberQ[{"StandardDeviation", StandardDeviation}, x], (
			tempErrorMeanData = Mean[traces];
			tempErrorData1 = StandardDeviation[traces];
		),
		x_/;MemberQ[{MedianDeviation, "MedianDeviation"}, x], (
			tempErrorMeanData = Median[traces];
			tempErrorData1 = MedianDeviation[traces];
		),
		x_/;MemberQ[{Quartiles, "Quartiles"}, x], (
			tempErrorData1 = Quartiles[traces];
			tempErrorData2 = tempErrorData1[[All, 1]];
			tempErrorData1 = tempErrorData1[[All, 3]];
		),
		x_/;MemberQ[{MinMax, "MinMax"}, x], (
			tempErrorData1 = MinMax /@ Transpose[traces];
			tempErrorData2 = tempErrorData1[[All, 1]];
			tempErrorData1 = tempErrorData1[[All, 2]];
		),
		_, Message[ HHListLinePlotMean::invalidOptionValue, "HHErrorPlot", ToString[opErrorPlot]]
	];

	If[ opErrorPlot =!= False && tempErrorData2 === {},
		tempErrorData2 = tempErrorMeanData - tempErrorData1;
		tempErrorData1 = tempErrorMeanData + tempErrorData1;
	];


	(*==========Create graphics==========*)
	
		(*==========Mean trace plot==========*)
		grMean=If[ tempMeanData == {}, 
			{},
			ListLinePlot[tempMeanData, 
				Sequence@@HHJoinOptionLists[ListLinePlot, 
				{PlotStyle -> opMeanPlotStyle}, {opts}, Options[HHListLinePlotMean]]
			]
		];

		(*==========Error filling plot==========*)
		grErrorFilling = If[ tempErrorData1 == {} || MemberQ[{False, Null, None, {}, ""}, opErrorPlotFillingStyle], 
			{},
			ListLinePlot[{tempErrorData1, tempErrorData2}, 
				Sequence@@HHJoinOptionLists[ListLinePlot,
					{PlotStyle -> None, Filling->{1 -> {2}}, FillingStyle -> opErrorPlotFillingStyle},
					{opts}, Options[HHListLinePlotMean]
					]
			]
		];

		(*==========Error trace plots==========*)
		grError=If[ tempErrorData1 == {} || MemberQ[{False, Null, None, {}, ""}, opErrorPlotStyle], 
			{},
			ListLinePlot[{tempErrorData1, tempErrorData2}, 
				Sequence@@HHJoinOptionLists[ListLinePlot,
					{PlotStyle -> opErrorPlotStyle},
					{opts}
				]
			]
		];

		(*==========Traces plot==========*)
		grMain = If[ MemberQ[{False, Null, None, {}, ""}, opPlotStyle],
			{},
			ListLinePlot[traces, 
				Sequence@@HHJoinOptionLists[ListLinePlot, {PlotStyle -> opPlotStyle}, {opts}, Options[HHListLinePlotMean]]
			]
		];

	(*==========Combine plots==========*)
	Show@@Flatten[{grErrorFilling, grError, grMean, grMain}]
];


HHListLinePlotMean[args___] := Message[HHListLinePlotMean::invalidArgs, {args}];


(* ::Subsection:: *)
(*HHLabelGraphics*)


HHLabelGraphics[ graphics_Graphics, text_String, opts:OptionsPattern[] ]:=
	HHLabelGraphics[ graphics, text, {Right, Bottom}, opts];


HHLabelGraphics[
	graphics_Graphics, text_String, {alignmentX_:Right, alignmentY_:Bottom}, 
	opts:OptionsPattern[] ]:=
Block[{optLabelStyleSpecifications, tempAbsPlotRange,
		tempX, tempY},
		
	optLabelStyleSpecifications = OptionValue[ HHOptLabelStyleSpecifications ];
	tempAbsPlotRange = AbsoluteOptions[graphics, PlotRange][[1, 2]];
	
	tempX = Switch[ alignmentX, 
		Left, tempAbsPlotRange[[1, 1]],
		Right, tempAbsPlotRange[[1, 2]],
		_,  Message[HHLabelGraphics::invalidAlignmentX, alignmentX];
			tempAbsPlotRange[[1, 2]]
	];
	tempY = Switch[ alignmentY, 
		Top, tempAbsPlotRange[[2, 2]],
		Bottom, tempAbsPlotRange[[2, 1]],
		_,  Message[HHLabelGraphics::invalidAlignmentY, alignmentY];
			tempAbsPlotRange[[2, 1]]
	];
	
	Show[
		graphics,
		Graphics[Text[ Style[ text, Sequence@@optLabelStyleSpecifications ],
			{tempX, tempY}, {alignmentX, alignmentY}
		]]
	]
];
HHLabelGraphics::invalidAlignmentX = "X alignment must be Left or Right, not `1`";
HHLabelGraphics::invalidAlignmentY = "Y alignment must be Top or Bottom, not `1`";

HHLabelGraphics[args___]:=Message[HHLabelGraphics::invalidArgs, {args}];


(* ::Subsection:: *)
(*HHExploreGraphicSlider*)


HHExploreGraphicSlider[gr_Graphics] :=
  Module[ {tempRange, opt, ar},
    tempRange = PlotRange /. AbsoluteOptions[gr, PlotRange]; (*seems like an idiomatic way to get Option values*)
    opt = DeleteCases[Options[graph], PlotRange -> _ | AspectRatio -> _];
    ar = AspectRatio /. AbsoluteOptions[gr, AspectRatio];
    Manipulate[
      Show[gr, 
        PlotRange -> {{pos[[1]] - xrange/2, pos[[1]] + xrange / 2}, {pos[[2]] - yrange / 2, pos[[2]] + yrange / 2}},
        AspectRatio -> ar,
        Sequence @@ opt],
      {{xrange, First[Differences[tempRange[[1]]]], "x range"}, 0, First[Differences[tempRange[[1]]]]},
     {{yrange, First[Differences[tempRange[[2]]]], "y range"}, 0, First[Differences[tempRange[[2]]]]},
     {{pos, {Mean[tempRange[[1]]],  Mean[tempRange[[2]]]}, "Position"}, {tempRange[[1, 1]], tempRange[[2, 1]]}, {tempRange[[1, 2]], tempRange[[2, 2]]}}
    ]
  ];


(* ::Subsection:: *)
(*HHExploreGraphicMouse*)


(* adapted from http://forums.wolfram.com/mathgroup/archive/2008/Jan/msg00009.html *)
HHExploreGraphicMouse[graph_Graphics] :=
  With[ {gr = First[graph],
    opt = DeleteCases[Options[graph], PlotRange -> _ | AspectRatio -> _],
    plr = PlotRange /. AbsoluteOptions[graph, PlotRange],
    ar = AspectRatio /. AbsoluteOptions[graph, AspectRatio], 
    rectangle = {Dashing[Small],Line[{#1, {First[#2], Last[#1]}, #2, {First[#1], Last[#2]}, #1}]} &},
    DynamicModule[ {dragging = False, first, second, rx1, rx2, ry1, ry2, range = {{rx1, rx2}, {ry1, ry2}} = plr}, (*range isn't used, but it doesn't work without*)
      Panel@EventHandler[Dynamic@
        Graphics[If[ dragging,
                   {gr, rectangle[first, second]},
                   gr
                 ], PlotRange -> {{rx1, rx2}, {ry1, ry2}}, AspectRatio -> ar, Sequence @@ opt],
         {{"MouseDown", 1} :> (first = MousePosition["Graphics"]),
        {"MouseDragged", 1} :> (dragging = True;
                                second = MousePosition["Graphics"]),
        {"MouseUp", 1} :> If[ dragging,
                            dragging = False;
                            {{rx1, rx2}, {ry1, ry2}} = Transpose@{first, second},
                            {{rx1, rx2}, {ry1, ry2}} = plr
                          ],
       {"MouseDown", 2} :> (first = {sx1, sy1} = MousePosition["Graphics"]),
         {"MouseDragged", 2} :> (second = {sx2, sy2} = MousePosition["Graphics"];
                                 rx1 = rx1 - (sx2 - sx1);
                                 rx2 = rx2 - (sx2 - sx1);
                                 ry1 = ry1 - (sy2 - sy1);
                                 ry2 =  ry2 - (sy2 - sy1))
       }]]
  ];


(* ::Subsection:: *)
(*Image Related*)


(* ::Subsubsection:: *)
(*HHImageMean*)


HHImageMean[x:{__Image}]:= HHImageMean[ImageData /@ x];

HHImageMean[imageDataList_List/;Depth[imageDataList]==5]:=
Block[{},
	(*The following part is repeated with modifications*)
	If[ Length[Union[  Dimensions/@imageDataList ]]!=1,
		Message[HHImageMean::dimensionsMustBeSame];,
		Image[ Mean[imageDataList] ]
	]
];

HHImageMean::dimensionsMustBeSame = "Input list of Image objects must all have the same dimensions and color depths!";

HHImageMean[args___]:=Message[HHImageMean::invalidArgs, {args}];


HHImageSubtract[a_Image, b_Image]:=Image[ ImageData[a] -ImageData[b]];

HHImageSubtract[args___]:=Message[HHImageSubtract::invalidArgs, {args}];


(*HHImageDifference[imageData_List, templateData_List, threshold_]:= 
Block[{tempSelf,tempProd, threshLower, threshUpper},
	tempSelf=MapThread[ Dot, {imageData,imageData},2];
	tempProd=MapThread[ Dot, {imageData+0.0001,templateData+0.0001},2];
	(*Map[ Clip[Norm[#],{1-threshold, 1+ threshold},{0, 0}]&, (imageData-templateData)(*tempSelf/tempProd*), {2}]*)
	threshLower=1-threshold;
	threshUpper=1+threshold;
	MapThread[ 
		Block[{temp},
			temp=#1-#2;
			If[threshLower \[LessEqual] temp &&  temp \[LessEqual] threshUpper, #3, {0.,0.,0.}]
		]&, 
		{tempSelf, tempProd, imageData}, {2}]
];*)


(* ::Subsubsection::Closed:: *)
(*HHImageDifference*)


HHImageDifference[imageData_List/;Depth[imageData]==4, templateData_List, threshold_]:= 
	MapThread[ 
		Block[{temp},
			temp=Norm[#1-#2];
			If[temp <= threshold, {0.,0.,0.}, #1]
		]&, 
		{imageData, templateData}, 2
	];


HHImageDifference[imageData_List/;Depth[imageData]==4, templateData_List, threshold_]:= 
	MapThread[ 
		Block[{temp},
			temp=Norm[Normalize[#1]-Normalize[#2]];
			If[temp <= threshold, {0.,0.,0.}, #1]
		]&, 
		{imageData, templateData}, 2
	];


HHImageDifferenceImpl[imageDataNorm_List, templateData_List, threshold_]:= 
	MapThread[ 
		Block[{temp},
			temp=Norm[#1-#2];
			If[temp <= threshold, {0.,0.,0.}, #1]
		]&, 
		{imageDataNorm, templateData}, 2
	];


(*HHImageDifference[x_Image, commonList_List, threshold_]:= HHImageDifference[{x}, commonList, threshold][[1]];

HHImageDifference[x:{__Image}, commonList_List, threshold_]:=
Block[{commonListDim, threshold2, filterImage},
	(*The following part is repeated with modifications*)
	commonListDim = Dimensions[commonList];
	threshold2 = threshold^2.;

(*	filterImageC= Compile[{{imageDataC, _Real, 3}},
		MapThread[ If[ Plus@@((#1 - #2)^2.) <= threshold2, {0.,0.,0.}, #1  ]&,
			{imageDataC, commonList}, 2    					
		],
		{{threshold2, _Real},{commonList, _Real, 3}}
	];*)
	filterImage[image_Image]:= Block[{imageData},
		imageData=ImageData[image];
		If[ commonListDim != Dimensions[imageData],
			Message[HHImageDifference::commonDimensionMustMatch];,
			(*filterImageC[imageData]*)
			MapThread[ If[ Plus@@((#1 - #2)^2.) <= threshold2, {0.,0.,0.}, #1  ]&,
			{imageData, commonList}, 2    					
			]
		]
	];

	ParallelMap[ filterImage, x ]
];*)

(*filterImage[imageData_List, commonList_List, threshold_]:=
Block[{tempList, threshold2},
	threshold2 = threshold^2.;
	(*tempList=Transpose[{imageData, commonList},{3,1,2}];
	Map[   If[ Plus@@((#[[1]] - #[[2]])^2) <= threshold2,  {0,0,0}, #[[1]]  ]&,   tempList, {2} ]*)
	MapThread[ 
		If[ Plus@@((#1 - #2)^2.) <= threshold2, {0.,0.,0.}, #1  ]&,
		 {imageData, commonList}, 2]
];*)

(*HHImageDifference[x:{__Image}, commonList_List, threshold_]:=
Block[{tempImageData, tempImageDim, func, threshold2, euclideanDistance2Threshold},
	(*The following part is repeated with modifications*)
	tempImageData=ImageData /@ x;
	If[ Length[Union[  Dimensions/@tempImageData ]]!=1,
		Message[HHImageMean::dimensionsMustBeSame];,
			tempImageDim=Dimensions[ImageData[x[[1]]]];
			If[ tempImageDim \[NotEqual] Dimensions[commonList],
				Message[HHImageDifference::commonDimensionMustMatch];,
				threshold2=threshold^2.;
				euclideanDistance2Threshold=Compile[{{xx, _Real, 1}, {yy, _Real, 1}},
					If[ Plus@@((xx - yy)^2.) <= threshold2, {0.,0.,0.}, xx  ]
				];
				func=Compile[{{oneImage, _Real, 3}},
					MapThread[ euclideanDistance2Threshold, {oneImage, commonList}, 2],
					{{commonList, _Real, 3}}
				];
				ParallelMap[ func, tempImageData ]
			]
	]
];*)


(*HHImageDifference[x:{__Image}, {commonList_List, thresholdList_List}]:=
Block[{tempImageData, tempImageDim},
	(*The following part is repeated with modifications*)
	tempImageData=ImageData /@ x;
	If[ Length[Union[  Dimensions/@tempImageData ]]!=1,
		Message[HHImageMean::dimensionsMustBeSame];,
			tempImageDim=Dimensions[ImageData[x[[1]]]];
			If[ tempImageDim \[NotEqual] Dimensions[commonList],
				Message[HHImageDifference::commonDimensionMustMatch];,
				If[ tempImageDim[[1;;2]] \[NotEqual] Dimensions[thresholdList],
					Message[HHImageDifference::thresholdDimensionMustMatch];,
					ParallelMap[ filterImage[#, {commonList, thresholdList}]&, tempImageData ]
				]
			]
	]
];

filterImage[imageData_List, {commonList_, thresholdList_}]:=
Block[{tempList},
	tempList=Transpose[{imageData, commonList, thresholdList},{3,1,2}];
	Map[   If[ Plus@@((#[[1]] - #[[2]])^2) <= #[[3]],  {0,0,0}, #[[1]]  ]&,   tempList, {2} ]
];*)


HHImageDifference[args___]:=Message[HHImageDifference::invalidArgs, {args}];


HHImageDifference::dimensionsMustBeSame = "Input list of Image objects must all have the same dimensions and color depths!";
HHImageDifference::commonDimensionMustMatch = "Input common Lists must have same dimensions as Images";
HHImageDifference::thresholdDimensionMustMatch = "Input threshold List must have same dimensions as Images";


(* ::Subsubsection::Closed:: *)
(*HHImageCommon*)


HHImageCommon[x:{__Image}/;Length[x]>=4]:=
Block[{tempImageData},
	(*The following part is repeated with modifications*)
	tempImageData=ImageData /@ x;
	If[ Length[Union[  Dimensions/@tempImageData ]]!=1,
		Message[HHImageCommon::dimensionsMustBeSame];,
		
		(*DistributeDefinitions["HokahokaW`Graphics`"];
		DistributeDefinitions["HokahokaW`Graphics`Private`"];*)
		ParallelMap[HHImageCommonImpl, Transpose[tempImageData, {3, 1, 2, 4}], {2}]
		(*ParallelMap[medianQuietPixelsShortC, Transpose[tempImageData, {3, 1, 2, 4}], {2}]*)
		(*medianQuietPixelsWholeShortC[ tempImageData ]*)
	]
];
HHImageCommon::dimensionsMustBeSame = "Input list of Image objects must all have the same dimensions and color depths!";

HHImageCommon[args___]:=Message[HHImageCommon::invalidArgs, {args}];


HHImageCommonImpl[{data__List}, sqEucThreshold_]:=
Block[{dataBuildup, temp, tempNewElementList},
	If[ Length[{data}] > 5,
		dataBuildup = {{{data}[[1]] , {{data}[[1]]}}};

		Do[
			(*sort by SquaredEuclideanDistance*)
			temp={SquaredEuclideanDistance[elementC, #[[1]]], #}&/@dataBuildup;
			temp= SortBy[ temp, First]; 
			(* temp = {  { sed1, {mean1, {{x,y,z}, {x,y,z}, ...}}}, { sed2, {mean2, {{x,y,z}, {x,y,z}, ...}}}, ... } *)

			dataBuildup=If[ temp[[1,1]]<= sqEucThreshold,
			tempNewElementList= Append[(temp[[1,2,2]]), elementC];
			ReplacePart[temp[[All, 2]], 1 -> {Mean[tempNewElementList], tempNewElementList}],
			Join[temp[[All , 2]], {{elementC, {elementC}}}]
		],
		{elementC, {data}[[2;;]]}
	];

	temp= SortBy[dataBuildup, Length[#[[2]]]&][[-1]];
	If[ Length[temp[[2]]] <3,{},temp[[1]]],

	Message[ HHImageCommon::notEnoughItems, Length[{data}]]
	]
];



HHImageCommon::notEnoughItems="Not enough items in list (`1`)!";


(*HHImageCommonImpl[{}, {remainingElements__List}, sqEucThreshold_]:=
	If[ Length[{remainingElements}] > 5,
		HHImageCommonImpl[
		{{{remainingElements}[[1]] , {{remainingElements}[[1]]}}},  {remainingElements}[[2 ;;]],
			 sqEucThreshold
	],
	Message[ HHImageCommon::notEnoughItems, Length[{remainingElements}]]
];*)


(*HHImageCommonImpl[{dataElements__List}, {}, sqEucThreshold_]:=
Block[{temp},
	temp= SortBy[{dataElements}, Length[#[[2]]]&][[-1]];
	If[ Length[temp[[2]]] <3,{},temp[[1]]]
];*)


(*HHImageCommonImpl[{dataElements__List}, {remainingElements__List}, sqEucThreshold_]:=
(* {dataElements} = {  {mean1, {{x,y,z}, {x,y,z}, ...}}, {mean2, {{x,y,z}, {x,y,z}, ...}}, ... } *)
(* {remainingElements} = { {x,y,z}, {x,y,z}, ... } *)

With[{elementC = First[{remainingElements}]},
Block[{temp, tempNewElementList},

	(*elementC = First[{remainingElements}];*)

	(*sort by SquaredEuclideanDistance*)
	temp = ( ({SquaredEuclideanDistance[ elementC,  #[[1]]], #}&) /@ {dataElements} );
	temp = SortBy[ temp, First];
	(* temp = {  { sed1, {mean1, {{x,y,z}, {x,y,z}, ...}}}, { sed2, {mean2, {{x,y,z}, {x,y,z}, ...}}}, ... } *)

	HHImageCommonImpl[
		If[ temp[[1,1]]<= sqEucThreshold,
		tempNewElementList= Append[(temp[[1,2,2]]),elementC];
		ReplacePart[temp[[All, 2]], 1 -> {Mean[tempNewElementList], tempNewElementList}],
		Join[temp[[All , 2]], {{elementC, {elementC}}}]
		],
		Rest[{remainingElements}], 
		sqEucThreshold
	]
]];*)


HHImageCommonImpl[list_List]:=
Block[{temp},
	temp = HHImageCommonImpl[list, 0.00025];
	If[temp==={}, temp = HHImageCommonImpl[list, 0.001]];
	If[temp==={}, temp = HHImageCommonImpl[list, 0.004]];
	If[temp==={}, temp = HHImageCommonImpl[list, 0.016]];
	If[temp==={}, temp = HHImageCommonImpl[list, 0.064]];
	If[temp==={}, list[[1]]*0., temp ]
];


(*medianQuietPixelsShortC=
Compile[{{pixelList, _Real, 2}},
	pixelMedian=Median /@ Transpose[pixelList];
	pixelsDist2=(Plus@@((#-pixelMedian)^2))& /@ pixelList;
	quartileEndIndex=Round[Length[pixelList]/4];
	pixelsOrdering = Ordering[pixelsDist2][[1 ;; quartileEndIndex]];
	Mean /@ Transpose[pixelList[[pixelsOrdering]]],
{{pixelMedian, _Real, 1},{pixelsDist2, _Real, 1},
{pixelsOrdering, _Integer, 1},{quartileEndIndex, _Integer}}
];*)


(* ::Subsubsection::Closed:: *)
(*HHImageThresholdNormalize/HHImageThresholdLinearNormalize*)


HHImageThresholdNormalize[imageData_List/;Depth[imageData]==4, threshold_:0.2]:= 
Map[(tempHHITNNorm = Norm[#]; If[ tempHHITNNorm < threshold, {0,0,0}, #/tempHHITNNorm])&, 
	imageData, 
	{2}
];


HHImageThresholdNormalize[imageData_List/;Depth[imageData]==3, threshold_:0.2]:= 
Map[(tempHHITNNorm = Norm[#]; If[ tempHHITNNorm < threshold, {0,0,0}, #/tempHHITNNorm])&, 
	imageData
];


HHImageThresholdNormalize[imageData_List/;Depth[imageData]==2, threshold_:0.2]:= 
(tempHHITNNorm = Norm[imageData]; If[ tempHHITNNorm < threshold, {0,0,0}, imageData/tempHHITNNorm]);


HHImageThresholdNormalize[image_Image, threshold_:0.2]:= 
Image[ HHImageThresholdNormalize[ ImageData[image], threshold ] ];


HHImageThresholdNormalize[args___]:=Message[HHImageThresholdNormalize::invalidArgs, {args}];


HHImageThresholdLinearNormalize[imageData_List/;Depth[imageData]==4, threshold_:0.5]:= 
Block[{sum},
	Map[(sum = Plus @@ #;
		If[ sum < threshold, {0,0,0}, # / sum * 3])&, 
		imageData, 
		{2}]
];


HHImageThresholdLinearNormalize[image_Image, threshold_:0.2]:= 
	Image[ HHImageThresholdLinearNormalize[ ImageData[image], threshold ] ];


HHImageThresholdLinearNormalize[args___]:=Message[HHImageThresholdLinearNormalize::invalidArgs, {args}];


(* ::Subsubsection::Closed:: *)
(*HHImageThreshold/HHImageThresholdLinear*)


HHImageThreshold[imageData_List/;Depth[imageData]==4, color_List/;Length[color]==3, threshold_:0.2]:= 
	Map[If[Norm[# - color] < threshold, {1,1,1}, {0,0,0}]&, 
		imageData, 
		{2}];


HHImageThreshold[image_Image, color_List/;Length[color]==3, threshold_:0.2]:= 
	Image[ HHImageThreshold[ ImageData[image], color, threshold ] ];


HHImageThreshold[args___]:=Message[HHImageThreshold::invalidArgs, {args}];


HHImageThresholdLinear[imageData_List/;Depth[imageData]==4, color_List/;Length[color]==3, threshold_:0.2]:= 
	Map[If[Sum @@ Abs[# - color] < threshold, {1,1,1}, {0,0,0}]&, 
		imageData, 
		{2}];


HHImageThresholdLinear[image_Image, color_List/;Length[color]==3, threshold_:0.2]:= 
	Image[ HHImageThresholdLinear[ ImageData[image], color, threshold ] ];


HHImageThresholdLinear[args___]:=Message[HHImageThresholdLinear::invalidArgs, {args}];


(* ::Section:: *)
(*Ending*)


End[];

EndPackage[];


(* ::Section:: *)
(*Backup*)


(*HHImageMeanSubtractedAdjusted[x:{__Image}]:=
Block[{tempImageData,tempMean},
	tempImageData=ImageData /@ x;
	If[ Length[Union[  Dimensions/@tempImageData ]]!=1,
		Message[HHImageMeanSubtractedAdjusted::dimensionsMustBeSame];,
		tempMean=Mean[tempImageData];
		ImageAdjust/@(Image/@((#-tempMean)& /@ tempImageData))
	]
];
HHImageMeanSubtractedAdjusted::dimensionsMustBeSame = "Input list of Image objects must all have the same dimensions and color depths!";

HHImageMeanSubtractedAdjusted[args___]:=Message[HHImageMean::invalidArgs, {args}];*)


(*HHGraphicsColumn[list:{__}, opts:OptionsPattern[]]:= 

See tests in /HokahokaW/Tests/Graphics for more information.
Until further improvements in graphics syntax, the best way is to use
Column[  Show[gr1, ImageSize\[Rule] y*72], Show[gr2, ImageSize\[Rule] y*72] ]
*)


(*medianQuietPixelsShort[pixels_List]:=
Block[{pixelMedian, pixelsDist2, pixelsOrdering, pixelsSortedThresholded(*, pixelCutoff*)},
	pixelMedian=Median /@ Transpose[pixels];
	(*pixelsDist=EuclideanDistance[#, pixelMedian]& /@ pixels;*)
	pixelsDist2=(Plus@@((#-pixelMedian)^2.))& /@ pixels;
	pixelsOrdering = Ordering[pixelsDist2][[1 ;; Round[Length[pixels]/4]]];
	Mean /@ Transpose[pixels[[pixelsOrdering]]]

(*	pixelMedian=Mean[pixelsSortedThresholded];
	pixelsDist2=(Plus@@((#-pixelMedian)^2))& /@ pixels;
	pixelsSortedThresholded=SortBy[Transpose[{pixelsDist2, pixels}], First];*)
(*	{Mean[pixelsSortedThresholded[[All, 2]]], pixelsSortedThresholded[[-1, 1]]}*)
];*)
(*simpleDistance[a_,b_]:=Plus@@(Abs /@ (a-b));
simplePixelCluster[pixelList_List/;Length[pixelList]==1, absThreshold_]:= pixelList[[1]];
simplePixelCluster[pixelList_, absThreshold_]:=
	Block[{clusters,clusterCount,innerBreak,innerRet},
		clusters={pixelList[[1]]}; clusterCount={1};
		
	(*For each pixel in the list past index 2*)
	Do[
		innerBreak=False;innerRet=0;

		(*For each cluster index*)
		Do[
			If[ simpleDistance[clusters[[n]],pixel]<=absThreshold,
					clusters=ReplacePart[clusters, n->  Mean[{clusters[[n]],pixel}]];
					clusterCount=ReplacePart[clusterCount,n->  (clusterCount[[n]]+1)];
					Break[],
				AppendTo[clusters,pixel]; AppendTo[clusterCount,1]
			],
		{n,Length[clusters]}
		],

	{pixel,pixelList[[2 ;; ]]}
	];

	SortBy[Transpose[{clusterCount,clusters}], First][[-1,2]]

];*)
