//Please use from 01 March 2017; updated by JB. Diamond mountant.
//Written by Dominic Waithe for Veronica Buckle and Jill Brown.
//Make sure you update the chromatic correction settings for your samples!!

getVoxelSize(Vox_w, Vox_h, Vox_d, unit);
//green channel displacment in um.


//Correction for the chromatic shift in green channel relative to red.
gCHx =0.021;
gCHy =0.042;	
gCHz =0.148;

//Parameters for 3d patch size.
zBuff = 3; //(zBuff*2)+1 = number of zslice
regWidth = 20; //width of area.
regHeight = 20; //width of box


//Enhance paramter should be kept at 0.35
enhance = 0.35;




getDimensions(w, h, channels, s, f);
s = selectionType();
dir = getDirectory("image"); 
title = getTitle;
//um per pixel



if( s == -1 ) {
    exit("There was no selection.");
    
} else if( s != 10 ) {
    exit("The selection wasn't a point selection.");
} 
getSelectionCoordinates(xPoints,yPoints);
getCursorLoc(x,y,z,flags);
    x = floor(xPoints[0]);
    y = floor(yPoints[0]);
setBatchMode(true);   

Stack.getPosition(channel, slice, frame);
//currentSlice =  getSliceNumber(); 
print("At coordinates (Vox_w: "+Vox_w+", Vox_h: "+Vox_h+", Vox_d: "+Vox_d+")");

c = nSlices/channels;
//Calculates number of zslices. There probably is a diret method.
c = nSlices/channels;


//Makes sure our area of study is legal in Z.
b=slice;
if((b-zBuff) < 0 ){
bottom = 1;
top = ((b-zBuff)*-1)+b+zBuff;
}else if(b+zBuff > c){
top = c;
bottom = (b-zBuff)-(b+zBuff-c);}
else{
bottom = b-zBuff;
top = b+zBuff;}
top = top;
bottom = bottom;

//Duplicates a copy of the image.
run("Select None");
run("Duplicate...", "title=image duplicate channels=1-3 slices=1-"+c+"");
wid = getWidth();
hei = getHeight();

//Crop regions of image.
roimar = 50;

xcrop0 = x - roimar;
xcrop1 = x + roimar;
ycrop0 = y - roimar;
ycrop1 = y + roimar;



//Makes sure the crop boundaries are legal.
if (xcrop1 > wid)
	xcrop1 = wid;
if (ycrop1 > hei)
	ycrop1 = hei;
	
if (xcrop0 < 0)
	xcrop0 = 0;
if (ycrop0 < 0)
	ycrop0 = 0;

rwid = xcrop1 - xcrop0; 
rhei = ycrop1 - ycrop0;

roimarw = round(rwid/2);
roimarh = round(rhei/2);

//This speeds up the remaining code. Crop coarsely around region in x and  y.
run("Specify...", "width="+rwid+" height="+rhei+" x="+x+" y="+y+" slice="+slice+" centered");
run("Crop");	
run("Select None");


//Split component channels.
run("Split Channels");

//Creates translated version of original to account for chromatic drift.
selectWindow("C2-image");
run("TransformJ Translate", "x-translation="+(gCHx/Vox_w)+" y-translation="+(gCHy/Vox_h)+" z-translation="+(gCHz/Vox_d)+" voxel interpolation=linear background=0.0");
selectWindow("C2-image");
close();
selectWindow("C2-image translated");

//Find substack of the green.
rename("C2-image");
run("Specify...", "width="+regWidth+" height="+regHeight+" x="+roimarw+" y="+roimarh+" slice="+slice+" centered");
run("Make Substack...", "channels=1-3  slices="+bottom+"-"+top+"");
rename("greenCH");

//Find substack of the red.
selectWindow("C3-image");
run("Specify...", "width="+regWidth+" height="+regHeight+" x="+roimarw+" y="+roimarh+" slice="+b+" centered");
run("Make Substack...", "channels=1-3  slices="+bottom+"-"+top+"");
rename("redCH");

//Close unwanted windows.
selectWindow("C3-image");
close();
selectWindow("C2-image");
close();
selectWindow("C1-image");
close();

selectWindow("greenCH");
run("Make Montage...","columns=7 rows=1 scale=1 first=1 last 7 increment=1 border=0 font=12");
//run("Window/Level...");
run("Enhance Contrast","saturated="+enhance);
//run("Close");
rename("greenCHMontage");
selectWindow("redCH");
run("Make Montage...","columns=7 rows=1 scale=1 first=1 last 7 increment=1 border=0 font=12");
//run("Window/Level...");
run("Enhance Contrast","saturated="+enhance);
//run("Close");
rename("redCHMontage");
selectWindow("greenCHMontage");
run("Duplicate...", "title=greenCHMontage2");
run("RGB Color");
selectWindow("redCHMontage");
run("Duplicate...", "title=redCHMontage2");
run("RGB Color");
imageCalculator("Add create", "greenCHMontage2","redCHMontage2");
selectWindow("greenCHMontage2");
close();
selectWindow("redCHMontage2");
close();
selectWindow("greenCH");
close();
selectWindow("redCH");
close();



selectWindow("greenCHMontage");
run("Duplicate...", "title=greenCHMontageTHR");
run("Clear Results");
getMinAndMax(min, max); 
//showMessage("max Intensity: "+max+"");
threshold = max*0.90 ;
thresholdMax = 65535;
setThreshold(threshold,thresholdMax);
run("Convert to Mask");
run("Montage to Stack...", "images_per_row=7 images_per_column=1 border=0");
rename("greenCHStack");
setVoxelSize(Vox_w, Vox_h, Vox_d, unit);
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 show_numbers white_numbers redirect_to=none");
run("3D Objects Counter", "threshold=128 slice=3 min.=5 max.=22743  statistics summary");
grnVolume = getResult('Volume (microns^3)', nResults-1);
xG = newArray(nResults);
yG = newArray(nResults);
zG = newArray(nResults);
lenG = nResults;
for (row=0; row<nResults; row++) {
xG[row] = getResult("X", row); 
yG[row] = getResult("Y", row);
zG[row] = getResult("Z", row);

//print(xG[row]);
//print(yG[row]);
//print(zG[row]);
}

selectWindow("redCHMontage");

run("Duplicate...", "title=redCHMontageTHR");
run("Clear Results");
getMinAndMax(min, max); 
//showMessage("max Intensity: "+max+"");
threshold = max*0.90 ;
thresholdMax = 65535;
setThreshold(threshold,thresholdMax);
run("Convert to Mask");
run("Montage to Stack...", "images_per_row=7 images_per_column=1 border=0");
rename("redCHStack");
setVoxelSize(Vox_w, Vox_h, Vox_d, unit);
run("3D OC Options", "volume surface nb_of_obj._voxels nb_of_surf._voxels integrated_density mean_gray_value std_dev_gray_value median_gray_value minimum_gray_value maximum_gray_value centroid mean_distance_to_surface std_dev_distance_to_surface median_distance_to_surface centre_of_mass bounding_box dots_size=5 font_size=10 show_numbers white_numbers redirect_to=none");
run("3D Objects Counter", "threshold=128 slice=3 min.=5 max.=22743  statistics summary");
redVolume = getResult('Volume (microns^3)', nResults-1);
selectWindow("redCHMontageTHR");
run("8-bit");
run("Red");
run("RGB Color");
selectWindow("greenCHMontageTHR");
run("8-bit");
run("Green");
run("RGB Color");
imageCalculator("Add create", "greenCHMontageTHR","redCHMontageTHR");

selectWindow("greenCHStack");
close();
selectWindow("redCHStack");
close();


run("Images to Stack", "name=Stack title=Montage");
run("Make Montage...", "columns=1 rows=6 scale=1 first=1 last=6 increment=1 border=2 font=12");

saveAs("PNG", dir+"/out_"+title+"_"+x+"_"+y+"_"+b+".png");
rename("out");
selectWindow("Stack");
close();
selectWindow("out");
setBatchMode(false);
xR = newArray(nResults);
yR = newArray(nResults);
zR = newArray(nResults);
lenR = nResults;
for (row=0; row<nResults; row++) {
xR[row] = getResult("X", row); 
yR[row] = getResult("Y", row);
zR[row] = getResult("Z", row);
//print(xR[row]);
//print(yR[row]);
//print(zR[row]);
}
//Calculate the distances.
string1 = "In image:"+title+":At coordinates (slice:"+slice+":, x:"+x+":, y:"+y+":)";
print (string1);
for (idG=0;idG<lenG; idG++){
for (idR=0;idR<lenR; idR++){


	
a1 = (xR[idR]-xG[idG])*Vox_w;
b1 = (yR[idR]-yG[idG])*Vox_h;
c1 = (zR[idR]-zG[idG])*Vox_d;

d = sqrt((a1*a1) + (b1*b1) +(c1*c1));
print("distance (microns) between green cluster "+(idG+1)+ " and red cluster "+(idR+1)+": ");
print("\t "+d);
print("volume of green cluster (microns^3):");
print("\t \t"+grnVolume);
print("volume of red cluster (microns^3):");
print("\t \t \t"+redVolume);
}
}
path = dir+"/coord.txt";
if (File.exists(path) == 1){
	str = File.openAsString(path);
	lines=split(str,"\n");
	exists = false;
	for (i=0;i<lines.length;i++){
		//print (lines[i]);
		if(lines[i] == string1)
		{exists = true;}
		}
		if(exists == false){File.append(string1,path);}
	
	
	
	
	
	}else{
	
	
	File.open(path);
	File.append(string1,path);
	
	}



