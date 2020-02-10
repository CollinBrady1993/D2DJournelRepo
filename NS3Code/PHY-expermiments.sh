#!/bin/bash

 #/* -*-  Mode: C++; c-file-style: "gnu"; indent-tabs-mode:nil; -*- */
 #
 # NIST-developed software is provided by NIST as a public
 # service. You may use, copy and distribute copies of the software in
 # any medium, provided that you keep intact this entire notice. You
 # may improve, modify and create derivative works of the software or
 # any portion of the software, and you may copy and distribute such
 # modifications or works. Modified works should carry a notice
 # stating that you changed the software and should note the date and
 # nature of any such change. Please explicitly acknowledge the
 # National Institute of Standards and Technology as the source of the
 # software.
 #
 # NIST-developed software is expressly provided "AS IS." NIST MAKES
 # NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
 # OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 # WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 # NON-INFRINGEMENT AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR
 # WARRANTS THAT THE OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED
 # OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT
 # WARRANT OR MAKE ANY REPRESENTATIONS REGARDING THE USE OF THE
 # SOFTWARE OR THE RESULTS THEREOF, INCLUDING BUT NOT LIMITED TO THE
 # CORRECTNESS, ACCURACY, RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
 #
 # You are solely responsible for determining the appropriateness of
 # using and distributing the software and you assume all risks
 # associated with its use, including but not limited to the risks and
 # costs of program errors, compliance with applicable laws, damage to
 # or loss of data, programs or equipment, and the unavailability or
 # interruption of operation. This software is not intended to be used
 # in any situation where a failure could cause risk of injury or
 # damage to property. The software developed by NIST employees is not
 # subject to copyright protection within the United States.

if [[ -z "${NS3_MODULE_PATH}" ]]; then
  echo "Waf shell not detected; run after './waf shell' command"
  exit
fi

export OVERWRITE
OVERWRITE=0
if [[ "$#" -gt 0 && $1 == "-f" ]];then
OVERWRITE=1
fi

export numCores=8 # Number of cores on your machine (to parallelize)

if [[ ! -d "scratch" ]];then
echo "ERROR: $0 must be copied to ns-3 directory!" 
exit
fi

export STARTRUN=1
export ENDRUN=10 #Number of runs 10
export tx=100
export minUE=10 #Number of UEs
export maxUE=100
export minNf=3
export maxNf=6
export minNt=4
export maxNt=8
export dVec=(5000) #max distance
export PtVec=(10) #dBm
export noiseFigureVec=(0) #noise figure, dBm
export fcVec=(23280) #center frequency, these values are specific, 23280(band 14) 22750(band 11) 18000(band 1)
export dataPoints=10000
export version="data-MAC-experiments" #Version for logging run output
export recovery=true #
export container="$version-discovery-scenarios"
mkdir -p $container

cd $container
for ((Nt=$minNt; Nt<=$maxNt; Nt++))
do
	for ((Nf=$minNf; Nf<=$maxNf; Nf++))
	do
		Nr=$(($Nf*$Nt))
		c1="Nr=$Nr,Nt=$Nt"
		mkdir -p $c1
		cd $c1
		
		minUE=$((Nr/4))
		maxUE=$((3*Nr))
		for ((UE=$minUE; UE<=$maxUE; UE++))
		do
			c2="UE$UE"
			mkdir -p $c2
		
		done
		cd ..
	done
done
cd ..



#export main_discovery_log_file="${container}/discovery-log.txt"
#echo "$version: $ENDRUN runs, $MAXSEEDS seeds - wns3-2017-discovery, $UE UEs in simulation, simTime=$stime, enableRecovery=$recovery" >> $main_discovery_log_file

./waf

profile=$(./waf --check-profile | tail -1 | cut -d ' ' -f 3)


function run-scenario () {
    run=${1}
    UE=${2}
    Nt=${3}
    Nf=${4}
    c1=${5}
    c2=${6}
    d=${7}
    Pt=${8}
    noiseFigure=${9}
    fc=${10}
    newdir="${container}/${c1}/${c2}/${version}-${UE}-${Nr}-${Nt}-${d}-${Pt}-${noiseFigure}-${fc}-${run}"
    if [[ -d $newdir && $OVERWRITE == "0" ]];then
        echo "$newdir exist! Use -f option to overwrite."
        return
    fi
    mkdir -p $newdir
    cd $newdir 
    OUTFILE="$log-${version}-${UE}-${Nr}-${Nt}-${d}-${Pt}-${noiseFigure}-${fc}-${run}.txt"
    #rm -f $OUTFILE
    echo "UEs in simluation = $UE" >> $OUTFILE
    #echo "Simulation time = $stime" >> $OUTFILE
    echo -e "-------------------------------\n" >> $OUTFILE
    if [[ $profile == "optimized" ]]; then
        ../../../../build/src/lte/examples/ns3-dev-wns3-2017-discovery-optimized --RngRun=$run --txProb=$tx --numUe=$UE --Nf=$Nf --Nt=$Nt --enableRecovery=$recovery --d=$d --Pt=$Pt --noiseFigure=$noiseFigure --fc=$fc >> $OUTFILE 2>&1
    elif [[ $profile == "debug" ]]; then
        ../../../../build/src/lte/examples/ns3-dev-wns3-2017-discovery-debug --RngRun=$run --txProb=$tx --numUe=$UE --Nf=$Nf --Nt=$Nt --enableRecovery=$recovery --d=$d --Pt=$Pt --noiseFigure=$noiseFigure --fc=$fc >> $OUTFILE 2>&1
    else
        echo "Profile: $profile not found"
        exit
    fi
    cd ../..
}

export -f run-scenario

export simcount=0
for d in ${dVec[@]};
do
	for Pt in ${PtVec[@]};
	do
		for noiseFigure in ${noiseFigureVec[@]};
		do
			for fc in ${fcVec[@]};
			do
				
				for ((Nt=$minNt; Nt<=$maxNt; Nt++))
				do
					for ((Nf=$minNf; Nf<=$maxNf; Nf++))
					do
						Nr=$(($Nf*$Nt))
						c1="Nr=$Nr,Nt=$Nt"
						minUE=$((Nr/4))
						maxUE=$((3*Nr))
						for ((UE=$minUE; UE<=$maxUE; UE ++))
						do	
							top=$(($dataPoints+$UE-1))
							bottom=$(($UE))
							ENDRUN=$(($top/$bottom))
							c2="UE$UE"
							
							
							for ((run=$STARTRUN; run<=$ENDRUN; run++))
							do
								echo "RUN: ${version}-${Nf}-${Nt}-${UE}-${d}-${Pt}-${noiseFigure}-${fc}-${run}"
								simcount=$((simcount + 1))
								run-scenario $run $UE $Nt $Nf $c1 $c2 $d $Pt $noiseFigure $fc &
								[[ $((simcount % numCores)) -eq 0 ]] && wait # parallelize up to numCores jobs
								
							done
						done
					done
				done
			done
		done
	done
done

wait
echo "all simulations complete"

