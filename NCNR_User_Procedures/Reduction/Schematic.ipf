#pragma rtGlobals=1		// Use modern global access method.
#pragma version=5.0
#pragma IgorVersion=6.0

//***********************
// Vers. 1.2 092101
//
//procedures to display a schematic layout of the data reduction procedure
//that was used to reduce a given file. useful for diagnosing 
//data reduction problems
//
// - due to pixelation differences between Mac/Windows, there are 
// two different procedures, one for each platform.
//
//************************


//main entry procedure for drawing schematics of the data reduction
//process - switches on platform, since screen pixels are different
//on each, and no realiable platform independent method could 
//be found
//
Proc ShowSchematic()

	Dowindow/F Schematic_Layout
	if(V_flag==1)
		Abort "Please close the existing schematic before creating a new one. Print it out if you want to save it."
		//DoWindow/K Schematic_Layout
	endif
	
	Variable oldScaling=root:myGlobals:gLogScalingAsDefault

	Variable num=getNewScaling()
	if(num==-99)		//use cancel
		Abort
	else
		root:myGlobals:gLogScalingAsDefault=num
	endif
	
	if(cmpstr("Macintosh",IgorInfo(2)) == 0)
		DrawMacSchematic()
	else
		DrawWinSchematic()
	Endif
	//reset scaling back to old value
	root:myGlobals:gLogScalingAsDefault=oldScaling
End

//returns the new color mapping
//global is not changed by this function
//
// returns 0 for linear scaling, 1 for log scaling, -99 for user cancel
//
Function getNewScaling()

	String scaleStr="Log"
	Prompt scaleStr,"Select the color mapping for the 2D data",popup, "Log;Linear"
	doPrompt "Color Mapping",scaleStr
	
	if(V_flag==1)
		return(-99)
	else
		return(cmpstr(scaleStr,"Linear"))	
	endif
end

//inStr is a keyword=value string (semicolon delimited)
//outStr is "stacked" for nice printing, replacing the semicolons
//with returns
//
Function/S StackText(inStr)
	String inStr
	
	String item="",outStr=""
	Variable ii=0,num=0
	
	num = ItemsInList(inStr, ";")
	do
		item = StringFromList(ii, inStr, ";")
		outStr += item
		outStr += "\r"
		ii+=1
	while(ii<num)
	
	return outStr
End

//procedure to draw a schamatic layout on a Macintosh
//separate prcedure is used for Windows, due to screen pixel differences
//
//runs the data reduction on one file (so the files are fresh and correct)
//and draws the schematic based on what the selected protocol dictates
//	
Proc DrawMacSchematic()

	//run data reduction on one file, using a specified protocol
	ReduceAFile()
	DoWindow/K SANS_Data		//get the data window out of the way
	
	//parse protocol to set PICTs, text, and variables
	String protocolName = root:myGlobals:Protocols:gProtoStr
	String waveStr = "root:myGlobals:Protocols:"+protocolName	//full path to the protocol used
	
	
	//set all of the text strings (0-23) that may need to be changed
	String text2,text3,text5,text7,text22,text21,text11,text20,text23
	
	text2 = "Using Protocol: "+protocolName
	text3 = "Sample file: "+ root:SAM:fileList
	text5 = "T\\BSAM\\M = " + getTransStrFromReals("SAM")	//trans and thickness of the sample
	text5 += "   d\\BSAM\\M = " + getThickStrFromReals("SAM") + " cm"
	text7 = "T\\BEMP\\M = " + getTransStrFromReals("EMP")	//transmission of the empty cell
	//attenuators used in sample measurement

	text23 = "SAM Attenuator = "+GetAttenNumStrFromReals("SAM")
	
	text11 = "Final 1-D Dataset"
	text20 = $waveStr[5]
	//make KW-string easy to read
	text20 = StackText(text20)
	
	//calculate KAPPA for absolute scaling
	text21 = $waveStr[4]
	
	if(cmpstr(text21,"none")==0)
		//no absolute scaling
		text22= "KAPPA = none used"
	else
		//get the parameters, and calculate Kappa
		Variable c2=0,c3=0,c4=1,c5=0
		c2 = NumberByKey("TSTAND", text21, "=", ";")	//parse the list of values
		c3 = NumberByKey("DSTAND", text21, "=", ";")
		c4 = NumberByKey("IZERO", text21, "=", ";")
		c5 = NumberByKey("XSECT", text21, "=", ";")
		text22= ""
		sprintf text22,"KAPPA = %g",1/(c2*c3*c5/c4)
	Endif
	text21 = StackText(text21)
	 
	//draw the textboxes
	PauseUpdate; Silent 1		// building window...
	Layout/C=1/W=(5,42,500,600) as "Data Reduction Schematic"
	DoWindow/C Schematic_Layout
	Textbox/N=text0/F=0/A=LB/X=10.00/Y=94.49 "SAM"
	Textbox/N=text1/F=0/A=LB/X=25.27/Y=94.49 "EMP"
	Textbox/N=text2/F=0/A=LB/X=57.45/Y=93.66 text2
	Textbox/N=text3/F=0/A=LB/X=57.45/Y=91.18 text3
	Textbox/N=text4/F=0/A=LB/X=39.82/Y=94.49 "BGD"
	Textbox/N=text6/F=0/A=LB/X=50.55/Y=76.61 "COR = (SAM - BGD) - (T\\BSAM\\M/T\\BEMP\\M)*(EMP - BGD)"
	Textbox/N=text5/F=0/A=LB/X=62.00/Y=86.23 text5
	Textbox/N=text7/F=0/A=LB/X=62.00/Y=83.61 text7
	Textbox/N=text8/F=0/A=LB/X=47.45/Y=69.01 "CAL = COR / DIV"
	Textbox/N=text9/F=0/A=LB/X=44.73/Y=52.48 "ABS = [1/(KAPPA*T\\BSAM\\M*d\\BSAM\\M)]*CAL"
	Textbox/N=text10/F=0/A=LB/X=47.09/Y=37.88 "Masked pixels are excluded\rfrom final1-D file"
	Textbox/N=text11/F=0/A=LB/X=5.82/Y=9.37 text11
	Textbox/N=text12/F=0/A=LB/X=10.00/Y=77.41 "COR"
	Textbox/N=text13/F=0/A=LB/X=25.27/Y=77.41 "DIV"
	Textbox/N=text14/F=0/A=LB/X=10.00/Y=61.16 "CAL"
	Textbox/N=text15/F=0/A=LB/X=25.73/Y=61.16 "ABSOLUTE SCALE"
	Textbox/N=text16/F=0/A=LB/X=9.45/Y=44.49 "ABS"
	Textbox/N=text17/F=0/A=LB/X=25.82/Y=44.49 "MSK"
	//set at bottom of proc Textbox/N=text18/F=0/A=LB/X=10.18/Y=27.82 "END"
	Textbox/N=text19/F=0/A=LB/X=22.00/Y=21.35 "1-D AVERAGE"
	Textbox/N=text20/F=0/A=LT/X=44/Y=75 text20			//AVG note "LT" anchor
	Textbox/N=text21/F=0/A=LT/X=20.73/Y=42 text21				//ABS par
	Textbox/N=text22/F=0/A=LB/X=44.73/Y=55 text22		//KAPPA value
	TextBox/N=text23/F=0/A=LB/X=62.00/Y=80.61 text23
	//then draw the layout
	ModifyLayout mag=1, units=1
	SetDrawLayer UserFront
	//braces
	SetDrawEnv gstart
	DrawLine 50,141,50,162		
	DrawLine 306,141,306,162
	DrawLine 50,162,306,162
	SetDrawEnv arrow= 1
	DrawLine 153,162,135,180
	SetDrawEnv gstop
	SetDrawEnv gstart
	DrawLine 50,263,50,282
	DrawLine 224,263,224,282
	DrawLine 50,282,224,282
	SetDrawEnv arrow= 1
	DrawLine 153,282,135,302
	SetDrawEnv gstop
	SetDrawEnv gstart
	DrawLine 50,380,50,402
	DrawLine 224,380,224,402
	DrawLine 50,402,224,402
	SetDrawEnv arrow= 1
	DrawLine 153,402,135,419
	SetDrawEnv gstop
	SetDrawEnv gstart
	DrawLine 50,501,50,522
	DrawLine 224,501,224,522
	DrawLine 50,522,224,522
	SetDrawEnv arrow= 1
	DrawLine 153,522,135,540
	SetDrawEnv gstop
	SetDrawEnv gstart
	DrawLine 50,623,50,642
	DrawLine 224,623,224,642
	DrawLine 50,642,224,642
	SetDrawEnv arrow= 1
	DrawLine 153,642,135,662
	SetDrawEnv gstop
	//end of braces
	
	//0 = background
	//1= empty cell
	//2= div
	//3=msk
	//4=ABS
	//5=averaging
	String temp = ""
	Variable draw
	
	//place the sample file
	temp = "SAM exists"
	draw = SetGraphic("SAM",temp)
	PlaceGraphic("SAM",draw,60,80,132,152)
	
	temp = $waveStr[0]
	draw = SetGraphic("BGD",temp)
	PlaceGraphic("BGD",draw,224,80,296,152)
	
	temp = $waveStr[1]
	draw = SetGraphic("EMP",temp)
	PlaceGraphic("EMP",draw,142,80,214,152)
	
	temp = $waveStr[2]
	draw = SetGraphic("DIV",temp)
	PlaceGraphic("DIV",draw,142,200,214,272)
	
	temp = $waveStr[3]
	draw = SetGraphic("MSK",temp)
        Variable maskDraw = 0
        if (draw == 0) 
           maskDraw = 1
        endif
	PlaceGraphic("MSK",draw,142,440,214,512)
	
	//need to decide what to do with  COR, CAL, and END file
	//COR will not be created IFF BGD and EMP are "none"
	String temp1 = $waveStr[0]
	String temp2 = $waveStr[1]
	if( (cmpstr(temp1,"none")==0)  &&  (cmpstr(temp2,"none")==0)  )
		//both are none, COR was not created
		temp = "none"
	else
		//COR was created
		temp = "yes, COR exists"
	Endif
	draw = SetGraphic("COR",temp)
	PlaceGraphic("COR",draw,60,200,132,272)
	
	//keep track of the "latest" file reduction step"
	String lastStep = "SAM"
	if(draw==0)
		lastStep = "COR"
	Endif
	
	//CAL will not be created if DIV is "none"
	temp1 = $waveStr[2]
	if(cmpstr(temp1,"none")==0)
		//CAL not created
		temp = "none"
	else
		//CAL was created
		temp = "yes, CAL exists"
	Endif
	draw = SetGraphic("CAL",temp)
	PlaceGraphic("CAL",draw,60,320,132,392	)
	if(draw==0)
		lastStep = "CAL"
	Endif
	
	temp = $waveStr[4]
	draw = SetGraphic("ABS",temp)
	PlaceGraphic("ABS",draw,60,440,132,512)
	if(draw==0)
		lastStep = "ABS"
	Endif
	
	//put the appropriate graphic in the last step	
        if(maskDraw==1) 
	    temp = "MSK overlay"
            draw = SetGraphic(lastStep,temp)
            lastStep += "MSK"
        Endif
	PlaceGraphic(lastStep,0,60,560,132,632)
	Textbox/N=text18/F=0/A=LB/X=10.18/Y=27.82 lastStep
	
End


//input is "type" of data, and what the protocol actually did with
//data in the "type" folder (either didn't use it, tried but no data was
//there, or used the data that ws there
//set the PNG of what is there  (if used), or instruct other graphics to be drawn
//as placeholders
//
//returns 1)=NOT USED, 2)=no data, 0)= PNG graphic is available
//return value is used by PlaceGraphic() to decide what graphic
//is actually drawn
//
// 080802 - uses the default scaling of the data (log or lin) as the data scaling
// being sure to re-convert the folder to log scale if needed
//
Function SetGraphic(type,choice)
	String type,choice
	
	WAVE NIHColors = $"root:myGlobals:NIHColors"
	String nameStr = type + "_PNG"
	if(cmpstr(choice,"none")==0)
		//none used, protocol did not need data from this folder
		return (1)
	else
		NVAR doLogScaling = root:myGlobals:gLogScalingAsDefault
		
		wave data = $("root:"+type+":data")
		if(waveExists(data))
			PauseUpdate; Silent 1		// building window...
			Display /W=(40,40,196,196)
			//plot and name the picture, then kill it
			AppendImage data
//			DoUpdate
			DoWindow/C temp_png
   		 	//Make the mask look green
	       	if(cmpstr(type,"MSK")==0)
	       		//don't convert the scaling of the mask file
	 			ModifyImage data ctab= {0,1,BlueRedGreen,0}
	         	else
	         		//convert the data to log/lin as requested
	         		If(doLogScaling)
					ConvertFolderToLogScale(type)
				Else
					ConvertFolderToLinearScale(type)
				Endif
	         		WaveStats/Q data
	          		ScaleColorsToData(V_min, V_max, NIHColors)
				ModifyImage data cindex=NIHColors
	       	endif
	       	//If we are working on the last step and overlaying
	       	//a mask on it do this
	      		if(cmpstr(choice,"MSK overlay")==0)
	        		nameStr = type+"MSK_PNG"
	        		Duplicate/O root:MSK:data root:MSK:overlay
	         		Redimension/D root:MSK:overlay
	         		String tempStr = "root:MSK:overlay"
	    	       	ResetLoop(tempStr)
	       	   	AppendImage root:MSK:overlay
	         		ModifyImage overlay ctab={0,1,BlueRedGreen,0}
	       	endif
	     		//end of overlay
//	     		DoUpdate
			ModifyGraph margin(left)=14,margin(bottom)=14,margin(top)=14,margin(right)=14
		  	ModifyGraph nticks=4
			ModifyGraph minor=1
			ModifyGraph fSize=9
			ModifyGraph standoff=0
			ModifyGraph tkLblRot(left)=90
			ModifyGraph btLen=3
			ModifyGraph tlOffset=-2
			SVAR fileStr = $("root:"+type+":fileList")
			Textbox/N=text0/F=0/A=MT/X=0.00/Y=0.00/E fileStr
			
// comment out line below for DEMO_MODIFIED version
			SavePICT/Z/E=-5 as "Clipboard"		//saves as PNG format
			
		 	LoadPICT/O/Q "Clipboard",$nameStr
		 	DoWindow/K temp_png
		  	return(0)
		else
			//data not found, but protocol wanted to use it
	 		return(2)
		Endif
	Endif
End

//places appropriate graphic in the selected location in the layout
//"draw" specifies the type of graphic to be displayed
//"type" is the data (folder) type
//l.r.b.t are the pixel specifications for where (and how large)
//to draw the graphic
//
Proc PlaceGraphic(type,draw,left,top,right,bottom)
	String type
	Variable draw,left,top,right,bottom
	
	DoWindow/F Schematic_Layout
	if(draw==0)
		//graphic has been set, use the PNG of the proper "type"
		String name = ""
		sprintf name,"%s_PNG(%d,%d,%d,%d)/O=8",type,left,top,right,bottom
		AppendToLayout $name
	else
		if(draw == 1)
			//"not used" graphic
			SetDrawEnv gstart
			SetDrawEnv fillpat= 0
			DrawRect left,top,right,bottom
			DrawText (left+23),(top+31),"NOT"
			DrawText (left+20),(top+54),"USED"
			SetDrawEnv gstop
		else
			//"no data" graphic
			SetDrawEnv gstart
			SetDrawEnv fillpat= 0
			DrawRect left,top,right,bottom
			DrawText (left+27),(top+34),"NO"
			DrawText (left+18),(top+56),"DATA"
			SetDrawEnv gstop
		Endif
	Endif

End

//procedure to draw a schamatic layout on Windows
//separate prcedure is used for Macintosh, due to screen pixel differences
//
//runs the data reduction on one file (so the files are fresh and correct)
//and draws the schematic based on what the selected protocol dictates
//	
Proc DrawWinSchematic()

	//run data reduction on one file, using a specified protocol
	ReduceAFile()
	DoWindow/K SANS_Data
	
	//parse protocol to set PICTs, text, and variables
	String protocolName = root:myGlobals:Protocols:gProtoStr
	String waveStr = "root:myGlobals:Protocols:"+protocolName	//full path to the protocol used
	
	
	//set all of the text strings (0-23) that may need to be changed
	String text2,text3,text5,text7,text22,text21,text11,text20,text23
	
	text2 = "Using Protocol: "+protocolName
	text3 = "Sample file: "+ root:SAM:fileList
	text5 = "T\\BSAM\\M = " + getTransStrFromReals("SAM")	//trans and thickness of the sample
	text5 += "   d\\BSAM\\M = " + getThickStrFromReals("SAM") + " cm"
	text7 = "T\\BEMP\\M = " + getTransStrFromReals("EMP")	//transmission of the empty cell
	//attenuators used in sample measurement

	text23 = "SAM Attenuator = "+GetAttenNumStrFromReals("SAM")
	
	text11 = "Final 1-D Dataset"
	text20 = $waveStr[5]
	//make KW-string easy to read
	text20 = StackText(text20)
	
	//calculate KAPPA for absolute scaling
	text21 = $waveStr[4]
	
	if(cmpstr(text21,"none")==0)
		//no absolute scaling
		text22= "KAPPA = none used"
	else
		//get the parameters, and calculate Kappa
		Variable c2=0,c3=0,c4=1,c5=0
		c2 = NumberByKey("TSTAND", text21, "=", ";")	//parse the list of values
		c3 = NumberByKey("DSTAND", text21, "=", ";")
		c4 = NumberByKey("IZERO", text21, "=", ";")
		c5 = NumberByKey("XSECT", text21, "=", ";")
		text22= ""
		sprintf text22,"KAPPA = %g",1/(c2*c3*c5/c4)
	Endif
	text21 = StackText(text21)
	 
	//draw the textboxes
	PauseUpdate; Silent 1           // building window...
  	Layout/C=1/W=(5,42,360,460) as "Data Reduction Schematic"
  	DoWindow/C Schematic_Layout
  	Textbox/N=text0/F=0/A=LB/X=9.65/Y=98.03 "SAM"
  	Textbox/N=text1/F=0/A=LB/X=26.69/Y=98.03 "EMP"
 	Textbox/N=text2/F=0/A=LB/X=57.40/Y=93.62 text2
  	Textbox/N=text3/F=0/A=LB/X=57.40/Y=91.18 text3
  	Textbox/N=text4/F=0/A=LB/X=45.02/Y=98.03 "BGD"
  	Textbox/N=text6/F=0/A=LB/X=40.51/Y=79.58 "COR = (SAM - BGD) - (T\\BSAM\\M/T\\BEMP\\M)*(EMP - BGD)"
 	Textbox/N=text5/F=0/A=LB/X=62.06/Y=87.19 text5
  	Textbox/N=text7/F=0/A=LB/X=62.06/Y=84.64 text7
  	Textbox/N=text8/F=0/A=LB/X=47.43/Y=69.03 "CAL = COR / DIV"
  	Textbox/N=text9/F=0/A=LB/X=47.43/Y=52.44 "ABS = [1/(KAPPA*T\\BSAM\\M*d\\BSAM\\M)]*CAL"
 	Textbox/N=text10/F=0/A=LB/X=47.11/Y=37.94 "Masked pixels are excluded\rfrom final1-D file"
 	Textbox/N=text11/F=0/A=LB/X=12.06/Y=6.15 text11
  	Textbox/N=text12/F=0/A=LB/X=9.65/Y=80.63 "COR"
 	Textbox/N=text13/F=0/A=LB/X=27.01/Y=80.74 "DIV"
 	Textbox/N=text14/F=0/A=LB/X=9.65/Y=62.06 "CAL"
 	Textbox/N=text15/F=0/A=LB/X=22.03/Y=62.06 "ABSOLUTE SCALE"
 	Textbox/N=text16/F=0/A=LB/X=9.65/Y=44.55 "ABS"
 	Textbox/N=text17/F=0/A=LB/X=25.88/Y=44.55 "MSK"
  	Textbox/N=text19/F=0/A=LB/X=23.63/Y=21.35 "1-D AVERAGE"
 	Textbox/N=text20/F=0/X=47.75/Y=74.83 text20
  	Textbox/N=text21/F=0/X=22.03/Y=41.07 text21
  	Textbox/N=text22/F=0/A=LB/X=47.11/Y=59.98 text22
       TextBox/N=text23/F=0/A=LB/X=62.00/Y=82.61 text23
	//then draw the layout
	ModifyLayout mag=1, units=1
	//braces
	SetDrawLayer UserFront
 	SetDrawEnv gstart
 	DrawLine 84,146.25,84,167.25
  	DrawLine 339,146.25,339,167.25
  	DrawLine 84,167.25,339,167.25
	SetDrawEnv arrow= 1
	DrawLine 186,167.25,168,185.25
	SetDrawEnv gstop
	SetDrawEnv gstart
	DrawLine 84,261.875,84,280.875
	DrawLine 258.125,261.875,258.125,280.875
	DrawLine 84,280.875,258.125,280.875
	SetDrawEnv arrow= 1
	DrawLine 187.125,280.875,169.125,300.875
	SetDrawEnv gstop
	SetDrawEnv gstart
	DrawLine 84,380,84,402
	DrawLine 260.75,380,260.75,402
	DrawLine 84,402,260.75,402
	SetDrawEnv arrow= 1
	DrawLine 189.75,402,171.75,419
	SetDrawEnv gstop
	SetDrawEnv gstart
	DrawLine 84,501,84,522
	DrawLine 260.75,501,260.75,522
	DrawLine 84,522,260.75,522
	SetDrawEnv arrow= 1
  	DrawLine 189.75,522,171.75,540
 	SetDrawEnv gstop
  	SetDrawEnv gstart
  	DrawLine 84,623,84,642
  	DrawLine 260.75,623,260.75,642
  	DrawLine 84,642,260.75,642
  	SetDrawEnv arrow= 1
  	DrawLine 189.75,642,171.75,662
 	SetDrawEnv gstop
	//end of braces
	
	//0 = background
	//1= empty cell
	//2= div
	//3=msk
	//4=ABS
	//5=averaging
	String temp = ""
	Variable draw
	
	//place the sample file
	temp = "SAM exists"
	draw = SetGraphic("SAM",temp)
	PlaceGraphic("SAM",draw,91.5,88.5,163.5,160.5)
	
	temp = $waveStr[0]
	draw = SetGraphic("BGD",temp)
	PlaceGraphic("BGD",draw,255,87.75,327,159.75)
	
	temp = $waveStr[1]
	draw = SetGraphic("EMP",temp)
	PlaceGraphic("EMP",draw,173.25,88.5,245.25,160.5)
	
	temp = $waveStr[2]
	draw = SetGraphic("DIV",temp)
	PlaceGraphic("DIV",draw,173.25,200.25,245.25,272.25)
	
	temp = $waveStr[3]
	draw = SetGraphic("MSK",temp)
	Variable maskDraw = 0
	if (draw == 0) 
		maskDraw = 1
	endif
	PlaceGraphic("MSK",draw,177,440.25,249,512.25)
	
	//need to decide what to do with  COR, CAL, and END file
	//COR will not be created IFF BGD and EMP are "none"
	String temp1 = $waveStr[0]
	String temp2 = $waveStr[1]
	if( (cmpstr(temp1,"none")==0)  &&  (cmpstr(temp2,"none")==0)  )
		//both are none, COR was not created
		temp = "none"
	else
		//COR was created
		temp = "yes, COR exists"
	Endif
	draw = SetGraphic("COR",temp)
	PlaceGraphic("COR",draw,91.5,200.25,163.5,272.25)
	
	//keep track of the "latest" file reduction step"
	String lastStep = "SAM"
	if(draw==0)
		lastStep = "COR"
	Endif
	
	//CAL will not be created if DIV is "none"
	temp1 = $waveStr[2]
	if(cmpstr(temp1,"none")==0)
		//CAL not created
		temp = "none"
	else
		//CAL was created
		temp = "yes, CAL exists"
	Endif
	draw = SetGraphic("CAL",temp)
	PlaceGraphic("CAL",draw,92.25,320.25,164.25,392.25)
	if(draw==0)
		lastStep = "CAL"
	Endif
	
	temp = $waveStr[4]
	draw = SetGraphic("ABS",temp)
	PlaceGraphic("ABS",draw,93.75,440.25,165.75,512.25)
	if(draw==0)
		lastStep = "ABS"
	Endif
	
	//put the appropriate graphic in the last step	
	if(maskDraw==1) 
		temp = "MSK overlay"
		draw = SetGraphic(lastStep,temp)
		lastStep += "MSK"
	Endif

	PlaceGraphic(lastStep,0,94.5,560.25,166.5,632.25)
	Textbox/N=text18/F=0/A=LB/X=9.65/Y=25.52 lastStep

End


//returns a string containg the transmision stored in the file that is 
//currently in the "type" folder (not from the binary header)
//returns "none" if the value (in RealsRead) cannot be found
//
Function/S getTransStrFromReals(type)
	String type
	
	String name="root:"+type+":realsread"
	WAVE reals = $name
	if(waveExists(reals))
		return(num2str(reals[4]))
	else
		return("none")
	endif	
End

//returns a string containg the sample thickness stored in the file that is 
//currently in the "type" folder (not from the binary header)
//returns "none" if the value (in RealsRead) cannot be found
//
Function/S getThickStrFromReals(type)
	String type
	
	String name="root:"+type+":realsread"
	WAVE reals = $name
	if(waveExists(reals))
		return(num2str(reals[5]))
	else
		return("none")
	endif	
End

//returns a string containg the sample thickness stored in the file that is 
//currently in the "type" folder (not from the binary header)
//returns "none" if the value (in RealsRead) cannot be found
//
Function/S GetAttenNumStrFromReals(type)
	String type
	
	String name="root:"+type+":realsread"
	WAVE reals = $name
	if(waveExists(reals))
		return(num2str(reals[3]))
	else
		return("none")
	endif	
End