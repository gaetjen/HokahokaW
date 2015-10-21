(* ::Package:: *)

(* Wolfram Language package *)

BeginPackage["HokahokaW`Graphics`",{"HokahokaW`"}];


(* ::Subsection:: *)
(*Package-specific Option Keys*)


(* ::Subsection:: *)
(*HHStackLists / HHListLinePlotStack*)


HHStackLists::usage="Augments a series of traces so that when plotted, they will be stacked vertically.";


HHBaselineCorrection::usage="Option for HHStackTraces and HHListLinePlotStack. Specify how to correct the baseline for \
individual traces. Specify a function: for example, Mean  (the default) will subtract individual trace means, First will \
subtract the first value. (#[[1]]*2)& will subtract twice the First value.";


HHStackIncrement::usage="Option for HHStackTraces and HHListLinePlotStack. \
By what interval to stack lists. Automatic gives x1.1 of the 95% Min-Max quantile (i.e. Quantile[ (# - Min[#])&[ Flatten[traces] ], 0.95]*1";


Options[HHStackLists] = {HHBaselineCorrection -> Mean, HHStackIncrement -> Automatic};


HHListLinePlotStack::usage=
"HHListLinePlotStack plots multiple traces together, stacked vertically.";


HHListLinePlotStack$UniqueOptions = {
	(*HHStackLists->Automatic,*) (*HHStackAxes->False,*)(* HHBaselineCorrection-> Mean*)
};
HHListLinePlotStack$OverrideOptions = { AspectRatio -> 1/2, PlotRange -> All };
 
Options[HHListLinePlotStack] =
HHJoinOptionLists[
	HHListLinePlotStack$UniqueOptions, 
	HHListLinePlotStack$OverrideOptions,
	Options[HHStackLists],
	Options[ListLinePlot]
];


(* ::Subsection:: *)
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


(* ::Subsection::Closed:: *)
(*HHImageMean/HHImageCommon/HHImageDifference*)


HHImageMean::usage="Gives the mean of a series of images. Image data must have the same dimensions and depths.";
HHImageCommon::usage="Gives the most common pixel cluster for each pixel in a series of images.  Image data must have the same dimensions and depths.";
HHImageDifference::usage="Filters an image list based on the common and threshold lists generated by HHImageCommon.";
Options[HHImageDifference]={Normalized->False};

HHImageSubtract::usage="Subtracts two images to give the difference.";


(* //ToDo2 create HHImageTestImage[] for help files??*)


(* ::Section:: *)
(*Private*)


Begin["`Private`"];


(* ::Subsection::Closed:: *)
(*HHStackLists / HHListLinePlotStack*)


HHStackLists[traces_ /; Depth[traces]==3, opts:OptionsPattern[]] :=
  Block[{tempTraces, temp, 
		opHHBaselineCorrection, baselineSubtractFactors, 
		opHHStackIncrement, stackAddFactors},
	
	tempTraces = traces;

	opHHBaselineCorrection = OptionValue[HHBaselineCorrection];

	baselineSubtractFactors = Switch[opHHBaselineCorrection,
		None, Table[0, {Length[traces]}],
		f_/;HHFunctionQ[f],    opHHBaselineCorrection/@traces, (*This covers specifications such as Mean and First or (#[[1]])& *)
		f_/;(Quiet[temp=f[#]&/@traces]; And@@(NumericQ /@ temp) ), 
								temp, (*This covers specifications such as Mean and First or (#[[1]])& *)
		_, Message[ HHStackLists::invalidOptionValue, "HHBaselineCorrection", ToString[opHHBaselineCorrection]]; 
								Table[0, {Length[traces]}]
	];
(*Print[baselineSubtractFactors];*)

	tempTraces = tempTraces - baselineSubtractFactors;
	
	opHHStackIncrement=OptionValue[HHStackIncrement];
	stackAddFactors = Switch[ opHHStackIncrement,
		Automatic,                Table[ Quantile[ (# - Min[#])&[ Flatten[traces] ], 0.95]*1.1, {Length[traces]}], (*- Subtract@@MinMax[ Flatten[traces] ]*)
		x_/;NumericQ[x],         Table[ opHHStackIncrement, {Length[traces]}],
		f_/;HHFunctionQ[f],      Table[ opHHStackIncrement[ Flatten[traces] ], {Length[traces]}], 
										(*This covers specifications such as Mean[#]& or (#[[1]])& *)
		f_/;(Quiet[temp=f[ Flatten[traces]]]; And@@(NumericQ /@ temp) ), 
								  temp, (*This covers specifications such as Mean and First *)
		_, Message[ HHStackLists::invalidOptionValue, "HHStackIncrement", ToString[opHHStackIncrement]]; Table[0, {Length[traces]}]
	];
(*Print[stackAddFactors];*)

	tempTraces = tempTraces + FoldList[Plus, 0, stackAddFactors[[ ;; -2]] ]; 
						(*last stack add factor is not used... nothing to stack on top*)

	tempTraces

   ];


HHStackLists[traces_ /; (Depth[traces]==4 && Union[(Dimensions /@ traces)[[All, 2]]]=={2}), opts:OptionsPattern[]] :=
  Block[{tempTimes, tempTraces},
	
	tempTimes = traces[[All, All, 1]];
	tempTraces = traces[[All, All, 2]];

	tempTraces =  HHStackLists[tempTraces, opts];

	Transpose /@ MapThread[{#1, #2}&, {tempTimes, tempTraces}]
   ];


HHStackLists[args___] := Message[HHStackLists::invalidArgs, {args}];


HHListLinePlotStack[
	traces_/;(Depth[traces]==3 || (Depth[traces]==4 && Union[(Dimensions /@ traces)[[All, 2]]]=={2})), 
	opts:OptionsPattern[]
]:=
Module[{tempData},
	
	tempData = HHStackLists[traces, Sequence@@FilterRules[{opts}, Options[HHStackLists]]];

	ListLinePlot[tempData,
		Sequence@@HHJoinOptionLists[ ListLinePlot, {opts}, HHListLinePlotStack$UniqueOptions ]
	]
];


HHListLinePlotStack[args___] := Message[HHListLinePlotStack::invalidArgs, {args}];


(* ::Subsection:: *)
(*HHListLinePlotMean*)


HHListLinePlotMean[traces_/;(Length[Dimensions[traces]]==2 && Length[Union[Length/@traces]]==1), opts:OptionsPattern[]]:=
Module[{temp,
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


(* ::Subsection::Closed:: *)
(*HHImageMean*)


HHImageMean[x:{__Image}]:= HHImageMean[ImageData /@ x];

HHImageMean[imageDataList_List/;Depth[imageDataList]==5]:=
Module[{},
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
Module[{tempSelf,tempProd, threshLower, threshUpper},
	tempSelf=MapThread[ Dot, {imageData,imageData},2];
	tempProd=MapThread[ Dot, {imageData+0.0001,templateData+0.0001},2];
	(*Map[ Clip[Norm[#],{1-threshold, 1+ threshold},{0, 0}]&, (imageData-templateData)(*tempSelf/tempProd*), {2}]*)
	threshLower=1-threshold;
	threshUpper=1+threshold;
	MapThread[ 
		Module[{temp},
			temp=#1-#2;
			If[threshLower \[LessEqual] temp &&  temp \[LessEqual] threshUpper, #3, {0.,0.,0.}]
		]&, 
		{tempSelf, tempProd, imageData}, {2}]
];*)


(* ::Subsection::Closed:: *)
(*HHImageDifference*)


HHImageDifference[imageData_List/;Depth[imageData]==4, templateData_List, threshold_]:= 
	MapThread[ 
		Module[{temp},
			temp=Norm[#1-#2];
			If[temp <= threshold, {0.,0.,0.}, #1]
		]&, 
		{imageData, templateData}, 2
	];


HHImageDifference[imageData_List/;Depth[imageData]==4, templateData_List, threshold_]:= 
	MapThread[ 
		Module[{temp},
			temp=Norm[Normalize[#1]-Normalize[#2]];
			If[temp <= threshold, {0.,0.,0.}, #1]
		]&, 
		{imageData, templateData}, 2
	];


HHImageDifferenceImpl[imageDataNorm_List, templateData_List, threshold_]:= 
	MapThread[ 
		Module[{temp},
			temp=Norm[#1-#2];
			If[temp <= threshold, {0.,0.,0.}, #1]
		]&, 
		{imageDataNorm, templateData}, 2
	];


(*HHImageDifference[x_Image, commonList_List, threshold_]:= HHImageDifference[{x}, commonList, threshold][[1]];

HHImageDifference[x:{__Image}, commonList_List, threshold_]:=
Module[{commonListDim, threshold2, filterImage},
	(*The following part is repeated with modifications*)
	commonListDim = Dimensions[commonList];
	threshold2 = threshold^2.;

(*	filterImageC= Compile[{{imageDataC, _Real, 3}},
		MapThread[ If[ Plus@@((#1 - #2)^2.) <= threshold2, {0.,0.,0.}, #1  ]&,
			{imageDataC, commonList}, 2    					
		],
		{{threshold2, _Real},{commonList, _Real, 3}}
	];*)
	filterImage[image_Image]:= Module[{imageData},
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
Module[{tempList, threshold2},
	threshold2 = threshold^2.;
	(*tempList=Transpose[{imageData, commonList},{3,1,2}];
	Map[   If[ Plus@@((#[[1]] - #[[2]])^2) <= threshold2,  {0,0,0}, #[[1]]  ]&,   tempList, {2} ]*)
	MapThread[ 
		If[ Plus@@((#1 - #2)^2.) <= threshold2, {0.,0.,0.}, #1  ]&,
		 {imageData, commonList}, 2]
];*)

(*HHImageDifference[x:{__Image}, commonList_List, threshold_]:=
Module[{tempImageData, tempImageDim, func, threshold2, euclideanDistance2Threshold},
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
Module[{tempImageData, tempImageDim},
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
Module[{tempList},
	tempList=Transpose[{imageData, commonList, thresholdList},{3,1,2}];
	Map[   If[ Plus@@((#[[1]] - #[[2]])^2) <= #[[3]],  {0,0,0}, #[[1]]  ]&,   tempList, {2} ]
];*)


HHImageDifference[args___]:=Message[HHImageDifference::invalidArgs, {args}];


HHImageDifference::dimensionsMustBeSame = "Input list of Image objects must all have the same dimensions and color depths!";
HHImageDifference::commonDimensionMustMatch = "Input common Lists must have same dimensions as Images";
HHImageDifference::thresholdDimensionMustMatch = "Input threshold List must have same dimensions as Images";


(* ::Subsection::Closed:: *)
(*HHImageCommon*)


HHImageCommon[x:{__Image}/;Length[x]>=4]:=
Module[{tempImageData},
	(*The following part is repeated with modifications*)
	tempImageData=ImageData /@ x;
	If[ Length[Union[  Dimensions/@tempImageData ]]!=1,
		Message[HHImageMean::dimensionsMustBeSame];,
		ParallelMap[medianQuietPixelsShortC, Transpose[tempImageData, {3, 1, 2, 4}], {2}]
		(*medianQuietPixelsWholeShortC[ tempImageData ]*)
	]
];
HHImageCommon::dimensionsMustBeSame = "Input list of Image objects must all have the same dimensions and color depths!";

HHImageCommon[args___]:=Message[HHImageCommon::invalidArgs, {args}];

(*medianQuietPixelsWholeShortC=
Compile[{{imageDataList, _Real, 4}},
	ParallelMap[medianQuietPixelsShortC, Transpose[imageDataList, {3, 1, 2, 4}], {2}],
	Parallelization\[Rule]True
];*)

(*medianQuietPixelsShort[pixels_List]:=
Module[{pixelMedian, pixelsDist2, pixelsOrdering, pixelsSortedThresholded(*, pixelCutoff*)},
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

medianQuietPixelsShortC=
Compile[{{pixelList, _Real, 2}},
	pixelMedian=Median /@ Transpose[pixelList];
	pixelsDist2=(Plus@@((#-pixelMedian)^2))& /@ pixelList;
	quartileEndIndex=Round[Length[pixelList]/4];
	pixelsOrdering = Ordering[pixelsDist2][[1 ;; quartileEndIndex]];
	Mean /@ Transpose[pixelList[[pixelsOrdering]]],
{{pixelMedian, _Real, 1},{pixelsDist2, _Real, 1},
{pixelsOrdering, _Integer, 1},{quartileEndIndex, _Integer}}
];

(*simpleDistance[a_,b_]:=Plus@@(Abs /@ (a-b));
simplePixelCluster[pixelList_List/;Length[pixelList]==1, absThreshold_]:= pixelList[[1]];
simplePixelCluster[pixelList_, absThreshold_]:=
	Module[{clusters,clusterCount,innerBreak,innerRet},
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


(* ::Section:: *)
(*Ending*)


End[];

EndPackage[];


(* ::Section::Closed:: *)
(*Bak*)


(*HHImageMeanSubtractedAdjusted[x:{__Image}]:=
Module[{tempImageData,tempMean},
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
