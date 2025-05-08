#pragma rtFunctionErrors=1
#pragma TextEncoding="UTF-8"
#pragma rtGlobals=3 // Use modern global access method.

// This all appears to be superceded by other routines, but this is
// likely a double-check for the code flow. (2020)

// this is version 3.0? of the code for the DLL from K. Krycka
// 18 MAY 2011
//
// converted to Igor, SRK
//
//

// this is one monolithic program to gather the inputs and then do the corrections
//
// -- some changes here --
//
// (1) data here is assumed to be RAW data, not partially corrected ASCII
//
// look for HARD WIRED VALUES, and eventually get rid of these
//

Function PolCorr_main()

	variable Monitor_Normalization = 1.0e+08
	variable Max_Data_Multiplicity = 5
	variable Cells                 = 3
	variable Number_Cells          = Cells
	variable Orientation           = 4
	variable Q_PixelsX             = 128
	variable Q_PixelsY             = 128

	// 	Variable lenFile = 100
	// 	String File_PP1,File_PP2,File_PP3,File_PP4,File_PP5
	// 	String File_MP1,File_MP2,File_MP3,File_MP4,File_MP5
	// 	String File_MM1,File_MM2,File_MM3,File_MM4,File_MM5
	// 	String File_PM1,File_PM2,File_PM3,File_PM4,File_PM5
	// 	String File_PPout,File_MPout,File_MMout,File_PMout
	// these differed only in the capitialzation of out -> Out, which is not recognized in Igor
	// but were apparently never used
	//String File_PP_Out,File_MP_Out,File_MM_Out,File_PM_Out

	variable input
	string   holder
	variable counter, counter2
	variable start_day, start_month, start_year
	variable helium_day, helium_month, helium_year
	variable data_day, data_month, data_year
	Make/O/D/N=(Cells) He_Pol_Measure_Time, gamm, Te, onl, Initial_He_Pol
	Make/O/D/N=(Orientation) Number_Files //PP, MP, MM, PM
	Make/O/T/N=(Orientation, Max_Data_Multiplicity) Data_Files
	Make/O/T/N=(Orientation) Out_Files
	Make/O/D/N=(Orientation, Max_Data_Multiplicity) Helium_Cell
	variable Polarization_SuperMirror, P_M //polarization of supermirror
	variable Polarization_Flipper, P_F //polarization of flipper = 2*efficiency - 1

	variable YesNo
	string   ch
	Make/O/T/N=(4) sub_holder
	variable ori
	variable mult
	variable Row, Column
	string line1, line2, line3, line4, line5, line6, line7, line8, line9, line10
	string line11, line12, line13, line14, line15, line16, line17, line18, line19
	variable date_v, month, year, hour, minute, second
	variable time_v
	variable moncounts
	variable sum_of_counts
	variable Scaled_Counts
	//	char *JANUARY={"JAN"};char *FEBRUARY={"FEB"};char *MARCH={"MAR"};char *APRIL={"APR"}
	//	char *MAY={"MAY"};char *JUNE={"JUN"};char *JULY={"JUL"};char *AUGUST={"AUG"}
	//	char *SEPTEMBER={"SEP"};char *OCTOBER={"OCT"};char *NOVEMBER={"NOV"};char *DECEMBER={"DEC"}
	variable Multiplicity
	variable a, b
	variable X, Y

	Make/O/D/N=(Orientation, Max_Data_Multiplicity) Time_Data_Collected
	Make/O/D/N=(Orientation, Max_Data_Multiplicity) Monitor_Counts //[PP,MP,MM,PM][Data_Multiplicity]
	Make/O/D/N=(Orientation, Max_Data_Multiplicity) Total_Counts //[PP,MP,MM,PM][Data_Multiplicity]
	Make/O/D/N=(Orientation, Max_Data_Multiplicity, 2) He_Transmission //[PP,MP,MM,PM][Data_Multiplicity][majority, minority] in percent transmitted.
	Make/O/D/N=(Orientation, Q_PixelsX, Q_PixelsY) Scattering_Intensity //[PP,MP,MM,PM][Max_Data_Multiplicity][X][Y]
	Make/O/D/N=(Orientation, Orientation) Prefactors
	Make/O/D/N=(Orientation, Orientation) Inverted_Matrix
	Make/O/D/N=(Orientation) Norm_Data

	//***********************************************************************************************************
	//Read in Record.txt parameters
	//***********************************************************************************************************

	////// this looks like all of the necessary inputs to make it work
	//
	//    fscanf(user_input, "%f", &input); start_day = input; //printf("start day is %u\n", start_day)
	//    fscanf(user_input, "%f", &input); start_month = input; //printf("start month is %u\n", start_month)
	//    fscanf(user_input, "%f", &input); start_year = input; //printf("start year is %u\n", start_year)

	//// HARD WIRED VALUES
	start_day   = 26
	start_month = 4
	start_year  = 2010

	helium_day  = start_day
	helium_year = start_year - 2000
	if(start_month == 1)
		helium_month = 0
	endif
	if(start_month == 2)
		helium_month = 31
	endif
	if(start_month == 3)
		helium_month = 59
	endif
	if(start_month == 4)
		helium_month = 90
	endif
	if(start_month == 5)
		helium_month = 120
	endif
	if(start_month == 6)
		helium_month = 151
	endif
	if(start_month == 7)
		helium_month = 181
	endif
	if(start_month == 8)
		helium_month = 212
	endif
	if(start_month == 9)
		helium_month = 243
	endif
	if(start_month == 10)
		helium_month = 273
	endif
	if(start_month == 11)
		helium_month = 304
	endif
	if(start_month == 12)
		helium_month = 334
	endif

	//// HARD WIRED VALUES
	// right now, Cells = 1, only one cell in use
	//
	Cells = 1

	for(counter = 0; counter < Cells; counter += 1)
		He_Pol_Measure_Time[counter] = 14.5 //hours, HARD WIRED (from midnight of start day?)
	endfor

	for(counter = 0; counter < Cells; counter += 1)
		gamm[counter] = 298.5 //hours
	endfor

	for(counter = 0; counter < Cells; counter += 1)
		Te[counter] = 0.87
	endfor

	// onl == mu == opacity of the cell
	for(counter = 0; counter < Cells; counter += 1)
		onl[counter] = 3.108
	endfor

	for(counter = 0; counter < Cells; counter += 1)
		Initial_He_Pol[counter] = 0.641
	endfor

	// number of input files in each orientation
	Number_Files[0] = 1
	Number_Files[1] = 2
	Number_Files[2] = 1
	Number_Files[3] = 2

	// index to keep track of which cell was used --for which data set-- at which orientation
	Helium_Cell = 0
	// 	Helium_Cell[orientation][data set num] = cell number
	Helium_Cell[0][0] = 1
	Helium_Cell[1][0] = 1
	Helium_Cell[1][1] = 1
	Helium_Cell[2][0] = 1
	Helium_Cell[3][0] = 1
	Helium_Cell[3][1] = 1

	//     for(counter=0; counter<Orientation; counter++){
	//    	for(counter2=0; counter2<Max_Data_Multiplicity; counter2++){
	//    		fscanf(user_input, "%f", &input); Helium_Cell[counter][counter2] = input; //printf("  cell used %u %u is %f", counter, counter2, Helium_Cell[counter][counter2]);
	//    	}
	//    }

	//    fscanf(user_input, "%f", &input); Polarization_SuperMirror = input; P_M = input; //printf("polarization of super mirror is %f \n", Polarization_SuperMirror)
	//    fscanf(user_input, "%f", &input); Polarization_Flipper = 2.0*input -1.0; P_F = input;  //printf("polarization of flipper is %f \n", Polarization_Flipper)

	//// HARD WIRED VALUES
	P_M                      = 0.937
	Polarization_SuperMirror = P_M

	P_F                  = 0.98
	Polarization_Flipper = 2 * P_F - 1.0

	//***********************************************************************************************************
	//Read in data files, add scans, calculate He transmissions
	//***********************************************************************************************************

	//
	// -- use AddFilesInList() here to put the data in SAM,
	// then move each orienatation into the Scattering_Intensity[][][] matrix
	// and fill in the He cell timing information, based on the header information.
	//
	// unroll the ori loop, and do each separtely, for better control of which files to load
	// - presumably input from a panel somewhere as run nubmers.
	//
	//	samStr = ParseRunNumberList("1,2,3,")		//returns a string with the file names
	//  err = AddFilesInList(activeType,samStr)			// adds the files in samStr to the activeType folder
	//
	// String fname = FindFileFromRunNumber(num) // could also be used. this returns the full path:name
	//
	//
	// -- I'm still not exactly sure what the times really are and how they are calculated. write this up...
	//
	//
	//	PathInfo catPathName			//this is where the files are
	//	String pathStr=S_path

	Scattering_Intensity = 0 //end row and column initialization loops

	for(ori = 0; ori < 4; ori += 1) //[PP,MP,MM,PM]
		Multiplicity = Number_Files[ori] //[SS,ST,CS,CT][PP,MP,MM,PM]

		for(mult = 0; mult < Multiplicity; mult += 1) //Multiplicity = number of relevant files

			Monitor_Counts[ori][mult] = moncounts

			// for this time value, get the midpoint of the data set, that is start + 1/2 of the collection time
			Time_Data_Collected[ori][mult] = time_v

			variable He_cell = Helium_Cell[ori][mult]

			variable He_pol_time = Initial_He_Pol[He_cell] * exp(-(Time_Data_Collected[ori][mult] - He_Pol_Measure_Time[He_cell]) / gamm[He_cell])
			He_Transmission[ori][mult][0] = Te[He_cell] * exp(-(1 - He_pol_time) * onl[He_cell]) //He majority transmission
			He_Transmission[ori][mult][1] = Te[He_cell] * exp(-(1 + He_pol_time) * onl[He_cell]) //He minority transmission

			sum_of_counts = 0
			for(Row = 0; Row < 128; Row += 1)
				for(Column = 0; Column < 128; Column += 1)
					Scaled_Counts                          = input * Monitor_Normalization / Monitor_Counts[ori][mult] //[PP,MP,MM,PM][Data_Multiplicity][X][Y]
					Scattering_Intensity[ori][Column][Row] = Scattering_Intensity[ori][Column][Row] + Scaled_Counts
					sum_of_counts                          = sum_of_counts + Scaled_Counts
				endfor
			endfor
			Total_Counts[ori][mult] = sum_of_counts

		endfor //end Multiplicity loop
	endfor //end Orientation loop

	//***********************************************************************************************************
	//Fill in matrix prefactors prior to solving four simultaneous equations
	//***********************************************************************************************************

	//
	// should this be a time-of-collection weighted linear combination of the coefficients?
	// what if each data file that contributes to Iab(q) was not collected for the same length
	// of time?
	//
	//
	//
	//
	for(a = 0; a < 4; a += 1)
		for(b = 0; b < 4; b += 1)
			Prefactors[a][b] = 0.0
		endfor
	endfor

	Multiplicity = Number_Files[0] //[PP]
	for(mult = 0; mult < Multiplicity; mult += 1)
		Prefactors[0][0] = Prefactors[0][0] + (1 + P_M) * He_Transmission[0][mult][0]
		Prefactors[0][1] = Prefactors[0][1] + (1 - P_M) * He_Transmission[0][mult][0]
		Prefactors[0][2] = Prefactors[0][2] + (1 - P_M) * He_Transmission[0][mult][1]
		Prefactors[0][3] = Prefactors[0][3] + (1 + P_M) * He_Transmission[0][mult][1]
	endfor

	Multiplicity = Number_Files[1] //[MP]
	for(mult = 0; mult < Multiplicity; mult += 1)
		Prefactors[1][0] = Prefactors[1][0] + (1 - P_M * P_F) * He_Transmission[1][mult][0]
		Prefactors[1][1] = Prefactors[1][1] + (1 + P_M * P_F) * He_Transmission[1][mult][0]
		Prefactors[1][2] = Prefactors[1][2] + (1 + P_M * P_F) * He_Transmission[1][mult][1]
		Prefactors[1][3] = Prefactors[1][3] + (1 - P_M * P_F) * He_Transmission[1][mult][1]
	endfor

	Multiplicity = Number_Files[2] //[MM]
	for(mult = 0; mult < Multiplicity; mult += 1)
		Prefactors[2][0] = Prefactors[2][0] + (1 - P_M * P_F) * He_Transmission[2][mult][1]
		Prefactors[2][1] = Prefactors[2][1] + (1 + P_M * P_F) * He_Transmission[2][mult][1]
		Prefactors[2][2] = Prefactors[2][2] + (1 + P_M * P_F) * He_Transmission[2][mult][0]
		Prefactors[2][3] = Prefactors[2][3] + (1 - P_M * P_F) * He_Transmission[2][mult][0]
	endfor

	Multiplicity = Number_Files[3] //[PM]
	for(mult = 0; mult < Multiplicity; mult += 1)
		Prefactors[3][0] = Prefactors[3][0] + (1 + P_M) * He_Transmission[3][mult][1]
		Prefactors[3][1] = Prefactors[3][1] + (1 - P_M) * He_Transmission[3][mult][1]
		Prefactors[3][2] = Prefactors[3][2] + (1 - P_M) * He_Transmission[3][mult][0]
		Prefactors[3][3] = Prefactors[3][3] + (1 + P_M) * He_Transmission[3][mult][0]
	endfor

	//***********************************************************************************************************
	//Written by K. Krycka 2006, modified for SANS Nov. 2007.
	//This is an n-dimensional square matrix solver.
	//***********************************************************************************************************

	variable subtract
	variable col, inner, inner_col, inner_row

	variable dimension = 4
	Make/O/D/N=(4, 4) Identity
	Identity       = 0
	Identity[0][0] = 1
	Identity[1][1] = 1
	Identity[2][2] = 1
	Identity[3][3] = 1

	Make/O/D/N=(dimension, dimension) MatrixToInvert
	for(col = 0; col < dimension; col += 1)
		for(row = 0; row < dimension; row += 1)
			MatrixToInvert[row][col] = Prefactors[row][col]
			if(col == row)
				Inverted_Matrix[row][col] = 1.0
			else
				Inverted_Matrix[row][col] = 0.0
			endif
		endfor
	endfor

	subtract = 0
	if(MatrixToInvert[0][0] != 0)
		for(col = 0; col < (dimension - 1); col += 1)
			for(row = col + 1; row < dimension; row += 1)
				subtract = MatrixToInvert[row][col] / MatrixToInvert[col][col]
				if(MatrixToInvert[row][col] != 0)
					for(inner_col = 0; inner_col < dimension; inner_col += 1)
						Identity[row][inner_col]       = Identity[row][inner_col] - subtract * Identity[col][inner_col]
						MatrixToInvert[row][inner_col] = MatrixToInvert[row][inner_col] - subtract * MatrixToInvert[col][inner_col]
					endfor
				endif
			endfor
		endfor

		for(row = 0; row < (dimension - 1); row += 1)
			for(col = row + 1; col < dimension; col += 1)
				subtract = MatrixToInvert[row][col] / MatrixToInvert[col][col]
				if(MatrixToInvert[row][col] != 0)
					for(inner_row = 0; inner_row < dimension; inner_row += 1)
						Identity[row][inner_row]       = Identity[row][inner_row] - subtract * Identity[col][inner_row]
						MatrixToInvert[row][inner_row] = MatrixToInvert[row][inner_row] - subtract * MatrixToInvert[col][inner_row]
					endfor
				endif
			endfor
		endfor

	endif

	Make/O/D/N=(dimension) divide
	for(row = 0; row < dimension; row += 1)
		divide[row] = MatrixToInvert[row][row]
	endfor

	for(row = 0; row < dimension; row += 1)
		for(col = 0; col < dimension; col += 1)
			Identity[row][col]       = Identity[row][col] / divide[row]
			MatrixToInvert[row][col] = MatrixToInvert[row][col] / divide[row]
		endfor
	endfor

	for(a = 0; a < dimension; a += 1)
		for(b = 0; b < dimension; b += 1)
			Inverted_Matrix[a][b] = Identity[a][b]
		endfor
	endfor

	//***********************************************************************************************************
	//Solve for cross sections PP, MP, MM, and PM
	//***********************************************************************************************************
	//
	// it looks like the Scattering_Intensity matrix is overwritten in place
	//
	for(X = 0; X < Q_PixelsX; X += 1)
		for(Y = 0; Y < Q_PixelsY; Y += 1)

			for(a = 0; a < 4; a += 1)
				Norm_Data[a] = Scattering_Intensity[a][X][Y]
			endfor

			for(a = 0; a < 4; a += 1)
				Scattering_Intensity[a][X][Y] = 0
			endfor

			for(ori = 0; ori < Orientation; ori += 1)
				for(col = 0; col < 4; col += 1)

					Scattering_Intensity[ori][X][Y] = Scattering_Intensity[ori][X][Y] + Inverted_Matrix[ori][col] * Norm_Data[col]
					//Solved[ori][X][Y] = Solved[ori][X][Y] + Inverted_Matrix[ori][col]*Scattering_Intensity[col][X][Y]

				endfor //end col loop
			endfor //end ori loop

		endfor //end Y loop
	endfor //end X loop

	//***********************************************************************************************************
	//Write processed, output files
	//***********************************************************************************************************

	// CHANGE this step to write out the 4 cross sections from the Scattering_Intensity[][][] matrix, just to simple
	// arrays, to be carried through the reduction

	//
	Make/O/D/N=(Q_PixelsX, Q_PixelsY) linear_data_PP, linear_data_MP, linear_data_MM, linear_data_PM

	linear_data_PP = Scattering_Intensity[0][p][q]
	linear_data_MP = Scattering_Intensity[1][p][q]
	linear_data_MM = Scattering_Intensity[2][p][q]
	linear_data_PM = Scattering_Intensity[3][p][q]

	// 	for(ori=0; ori<Orientation; ori+=1)
	//
	// 		for(Row = 0; Row<Q_PixelsX; Row+=1)
	// 			for(Column = 0; Column<Q_PixelsY; Column+=1)
	// 				//fprintf(fp, "%f\n", Raw_Counts[ori][0][Row][Column])
	// 				//fprintf(fp, "%f\n", Scattering_Intensity[ori][Row][Column])
	// 				fprintf(fp, "%f\n", Scattering_Intensity[ori][Row][Column])
	// 			endfor
	// 		endfor
	//
	// 	endfor		//end ori loop
	//
	//
	//

	//***********************************************************************************************************
	//Write message to user of completion
	//***********************************************************************************************************

	print "start year", start_year
	print "Time of first data collection is ", Time_Data_Collected[0][0]
	print "Monitor counts are ", Monitor_Counts[0][0]
	print "Total counts are ", Total_Counts[0][0]

	Print "Your data has beed processed"

End // PolCorr_main
