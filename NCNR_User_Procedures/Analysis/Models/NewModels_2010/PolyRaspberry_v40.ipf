#pragma rtGlobals=1		// Use modern global access method.


////////////////////////////////////////////////////
// Raspberry model
//
// Larson-Smith et al. Small angle scattering model for Pickering emulsions and raspberry particles.
//   Journal of colloid and interface science (2010) vol. 343 (1) pp. 36-41
//
////////////////////////////////////////////////////

// Raspberry particles with polydisperse large sphere
#include "Raspberry_v40"

Proc PlotPolyRaspberry(num,qmin,qmax)
	Variable num=500, qmin=1e-5, qmax=0.7
	Prompt num "Enter number of data points for model: "
	Prompt qmin "Enter minimum q-value (^-1) for model: " 
	Prompt qmax "Enter maximum q-value (^-1) for model: "
//
	Make/O/D/n=(num) xwave_PolyRaspberry, ywave_PolyRaspberry
	xwave_PolyRaspberry =  alog(log(qmin) + x*((log(qmax)-log(qmin))/num))
	Make/O/D coef_PolyRaspberry = {0.05,5000,0.1,-4e-7,0.005,100,0.4,3.5e-6,0,6.3e-6,0.0}			
	make/o/t parameters_PolyRaspberry =  {"vf Large","Radius Large (A)","pd Large Sphere","SLD Large sphere (A-2)","vf Small", "Radius Small (A)","surface coverage","SLD Small sphere (A-2)","delta","SLD solvent (A-2)","bkgd (cm-1)"}
	Edit parameters_PolyRaspberry, coef_PolyRaspberry
	
	Variable/G root:g_PolyRaspberry
	g_PolyRaspberry := PolyRaspberry(coef_PolyRaspberry, ywave_PolyRaspberry, xwave_PolyRaspberry)
	Display ywave_PolyRaspberry vs xwave_PolyRaspberry
	ModifyGraph marker=29, msize=2, mode=4
	ModifyGraph log=1,grid=1,mirror=2
	Label bottom "q (\\S-1\\M) "
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	AddModelToStrings("PolyRaspberry","coef_PolyRaspberry","parameters_PolyRaspberry","PolyRaspberry")
//
End


Proc PlotSmearedPolyRaspberry(str)								
	String str
	Prompt str,"Pick the data folder containing the resolution you want",popup,getAList(4)
	
	// if any of the resolution waves are missing => abort
	if(ResolutionWavesMissingDF(str))		//updated to NOT use global strings (in GaussUtils)
		Abort
	endif
	
	SetDataFolder $("root:"+str)
	
	// Setup parameter table for model function
	Make/O/D smear_coef_PolyRaspberry = {0.05,5000,0.1,-4e-7,0.005,100,0.4,3.5e-6,0,6.3e-6,0.0}
	make/o/t smear_parameters_PolyRaspberry = {"vf Large","Radius Large (A)","pd Large Sphere","SLD Large sphere (A-2)","vf Small", "Radius Small (A)","surface coverage","SLD Small sphere (A-2)","delta","SLD solvent (A-2)","bkgd (cm-1)"}
	Edit smear_parameters_PolyRaspberry,smear_coef_PolyRaspberry					//display parameters in a table
	
	// output smeared intensity wave, dimensions are identical to experimental QSIG values
	// make extra copy of experimental q-values for easy plotting
	Duplicate/O $(str+"_q") smeared_PolyRaspberry,smeared_qvals
	SetScale d,0,0,"1/cm",smeared_PolyRaspberry
					
	Variable/G gs_PolyRaspberry=0
	gs_PolyRaspberry := fSmearedPolyRaspberry(smear_coef_PolyRaspberry,smeared_PolyRaspberry,smeared_qvals)	//this wrapper fills the STRUCT
	
	Display smeared_PolyRaspberry vs smeared_qvals
	ModifyGraph log=1,marker=29,msize=2,mode=4
	Label bottom "q (\\S-1\\M)"
	Label left "I(q) (cm\\S-1\\M)"
	AutoPositionWindow/M=1/R=$(WinName(0,1)) $WinName(0,2)
	
	SetDataFolder root:
	AddModelToStrings("SmearedPolyRaspberry","smear_coef_PolyRaspberry","smear_parameters_PolyRaspberry","PolyRaspberry")
End


Function PolyRaspberry(cw,yw,xw) : FitFunc
	Wave cw,yw,xw
	
#if exists("PolyRaspberryX")
	yw = PolyRaspberryX(cw,xw)
#else
	yw = fPolyRaspberry(cw,xw)
#endif
	return(0)
End


Function fPolyRaspberry(w,x) : FitFunc
	Wave w
	Variable x
	

	//Set up variables
	// variables are:							
	//[0] volume fraction large spheres
	//[1] radius large sphere ()
	//[2] polydispersity large sphere
	//[3] sld large sphere (-2)
	//[4] volume fraction small spheres
	//[5] fraction of small spheres at surface
	//[6] radius small sphere (A)
	//[7] sld small sphere
	//[8] small sphere penetration (A) 
	//[9] sld solvent
	//[10] background (cm-1)
	
	Variable vfL,rL,pdL,sldL,vfS,rS,sldS,deltaS,delrhoL,delrhoS,bkg,sldSolv,qval,aSs,fSs	
	vfL = w[0]
	rL = w[1]
	pdL = w[2]
	sldL = w[3]
	vfS = w[4]
	rS = w[5]
	aSs = w[6]
	sldS = w[7]
	deltaS = w[8]
	sldSolv = w[9]
	bkg = w[10]
	
	delrhoL = abs(sldL - sldSolv)
	delrhoS = abs(sldS - sldSolv)	
	
	qval = x		//rename the input q-value, purely for readability
	
	Variable f2	
	Variable va,vb,ii,zi,nord,yy,summ
	String weightStr,zStr
	
	Variable Np,VL,VS
	
	Variable sig = pdL*rL		
	
	//select number of gauss points by setting nord=20 or76 points
//	nord = 20
	nord = 76
	
	weightStr = "gauss"+num2str(nord)+"wt"
	zStr = "gauss"+num2str(nord)+"z"
	
	if (WaveExists($weightStr) == 0) // wave reference is not valid, 
		Make/D/N=(nord) $weightStr,$zStr
		Wave gauWt = $weightStr
		Wave gauZ = $zStr		// wave references to pass
		if(nord==20)
			Make20GaussPoints(gauWt,gauZ)
		else
			Make76GaussPoints(gauWt,gauZ)
		endif	
	else
		if(exists(weightStr) > 1) 
			 Abort "wave name is already in use"		//executed only if name is in use elsewhere
		endif
		Wave gauWt = $weightStr
		Wave gauZ = $zStr		// create the wave references
	endif
	
	// end points of integration
	// limits are technically 0-inf, but wisely choose interesting region of q where R() is nonzero
	// +/- 3 sigq catches 99.73% of distrubution
	// change limits (and spacing of zi) at each evaluation based on R()
	//integration from va to vb
	va = -4*sig + rL
	if (va< 4*rS)
		va=4*rS		//to avoid numerical error when  va<0 (-ve q-value)
	endif
	vb = 4*sig +rL

	//VL = 4*pi/3*rL^3
	//VS = 4*pi/3*rS^3
	//Np = vfS*fSs*VL/vfL/VS

	
	Make/O/N=9 rasp_temp
	rasp_temp[0] = w[0]
	rasp_temp[1] = w[1]
	rasp_temp[2] = delrhoL
	rasp_temp[3] = w[4]
	rasp_temp[4] = w[5]
	rasp_temp[5] = w[6]
	rasp_temp[6] = delrhoS
	rasp_temp[7] = w[8]
	rasp_temp[8] = w[9]
	rasp_temp[9] = Np

	summ = 0.0		// initialize integral
	for(ii=0;ii<nord;ii+=1)
		// calculate Gauss points on integration interval (r-value for evaluation)
		zi = ( gauZ[ii]*(vb-va) + vb + va )/2.0
		rasp_temp[1] = zi	
		//calculate scattering
		yy = gauWt[ii] * RaspGauss_distr(sig,rL,zi) * fRaspberryKernel(rasp_temp,qval)
		summ += yy		//add to the running total of the quadrature	
	endfor
	
	summ = (vb-va)/2.0*summ
	
	//Use average volume of oil droplet, so fraction of particles should be correct...
	VL = (4*pi/3*rL^3) *(1+3*pdL^2)
	VS = 4*pi/3*rS^3
	
	//Using average volume of oil droplet, should get average Np...
	Np = aSs*4*(rS/(rL+deltaS))*VL/VS 
	//Np = aSs*4*((rL+deltaS)/rS)^2

	fSs = Np*vfL*VS/vfS/VL
	
	f2 = summ 
	f2 += vfS*(1-fSs)*delrhoS^2*VS*fRaspBes(qval,rS)*fRaspBes(qval,rS)
	
	f2 *= 1e8		// [=] 1/cm
	
	return (f2+bkg)	// Scale, then add in the background

End

Function RaspGauss_distr(sig,avg,pt)
	Variable sig,avg,pt
	
	Variable retval
	
	retval = (1/ ( sig*sqrt(2*Pi)) )*exp(-(avg-pt)^2/sig^2/2)
	return(retval)
End


///////////////////////////////////////////////////////////////
// smeared model calculation
//
// you don't need to do anything with this function, as long as
// your Raspberry works correctly, you get the resolution-smeared
// version for free.
//
// this is all there is to the smeared model calculation!
Function SmearedPolyRaspberry(s) : FitFunc
	Struct ResSmearAAOStruct &s

//	the name of your unsmeared model (AAO) is the first argument
	Smear_Model_20(PolyRaspberry,s.coefW,s.xW,s.yW,s.resW)

	return(0)
End

///////////////////////////////////////////////////////////////


// nothing to change here
//
//wrapper to calculate the smeared model as an AAO-Struct
// fills the struct and calls the ususal function with the STRUCT parameter
//
// used only for the dependency, not for fitting
//
Function fSmearedPolyRaspberry(coefW,yW,xW)
	Wave coefW,yW,xW
	
	String str = getWavesDataFolder(yW,0)
	String DF="root:"+str+":"
	
	WAVE resW = $(DF+str+"_res")
	
	STRUCT ResSmearAAOStruct fs
	WAVE fs.coefW = coefW	
	WAVE fs.yW = yW
	WAVE fs.xW = xW
	WAVE fs.resW = resW
	
	Variable err
	err = SmearedPolyRaspberry(fs)
	
	return (0)
End


// plots the Gauss distribution based on the coefficient values
// a static calculation, so re-run each time
//
Macro PlotRaspDistribution()

	variable pd,avg,zz,maxr,vf
	
	if(Exists("coef_pgs")!=1)
		abort "You need to plot the unsmeared model first to create the coefficient table"
	Endif
	pd=coef_PolyRaspberry[2]
	avg = coef_PolyRaspberry[1]
	vf = coef_PolyRaspberry[0]
	
	Variable vfL,rL,pdL,sldL,vfS,rS,sldS,deltaS,delrhoL,delrhoS,bkg,sldSolv,qval	,fSs	

	vfL = coef_PolyRaspberry[0]
	rL = coef_PolyRaspberry[1]
	pdL = coef_PolyRaspberry[2]
	sldL = coef_PolyRaspberry[3]
	vfS = coef_PolyRaspberry[4]
	rS = coef_PolyRaspberry[5]
	aSs = coef_PolyRaspberry[6]
	sldS = coef_PolyRaspberry[7]
	deltaS = coef_PolyRaspberry[8]
	sldSolv = coef_PolyRaspberry[9]
	bkg = coef_PolyRaspberry[10]
	
	Make/O/D/N=1000 Rasp_distribution,Rasp_Vf,Rasp_Np,Rasp_VL
	maxr =  avg*(1+10*pd)

	SetScale/I x, 0, maxr, Rasp_distribution
	Rasp_distribution = RaspGauss_distr(pd*avg,avg,x)
	Display Rasp_distribution
	
End