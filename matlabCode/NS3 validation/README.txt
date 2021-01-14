This folder contains data required to validate the data obtained from NS-3 
against the theoretical results.

The following scripts/functions reference the specific filepaths that the 
NS-3 data may be saved at, please replace these filepaths with wherever you 
choose to save this data from your NS-3 simulation runs:
1) dataReadScript.m;

Although including all data I have collected would be imposible for size 
reasons, I have included a zip which contains some sample NS-3 data so you 
can try these functions without running the NS-3 code yourself. These files 
are located in the zip file called sampleNS3Data.zip

The following functions/scrifpts require a folder "AData to be within this 
folder. I have include a zip of that AData here for you, please unzip it 
and place it in ~\matlabCode\NS3 validation(MACvsPHY)\

This folder include much of the same code which can be found in 
~\matlabCode\Probability Calculation\. It is used here to compare to the 
simulation results and for simplicity(no need to add anything to matlab search paths)
