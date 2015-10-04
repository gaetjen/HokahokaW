(* ::Package:: *)

(* Wolfram Language package *)

(* Wolfram Language package *)

BeginPackage["HokahokaW`Graphics`",{"HokahokaW`"}];


HHImageMean::usage="Gives the mean of a series of images. Image data must have the same dimensions and depths.";
HHImageCommon::usage="Gives the most common pixel cluster for each pixel in a series of images.  Image data must have the same dimensions and depths.";
HHImageDifference::usage="Filters an image list based on the common and threshold lists generated by HHImageCommon.";
Options[HHImageDifference]={Normalized->False};

HHImageSubtract::usage="Subtracts two images to give the difference.";


(* //ToDo2 create HHImageTestImage[] for help files*)


HHGraphicsColumn::usage="Stacks images vertically. In contrast to the standard GraphicsColumn, adjusts widths to be equal.";

Options[HHGraphicsColumn]= Options[Graphics];


Begin["`Private`"];


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


End[];

EndPackage[];
