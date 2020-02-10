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
export minUE=2 #Number of UEs
export maxUE=2
export minNf=1
export maxNf=1
export minNt=300
export maxNt=300
export dVec=(1000) # 50837 49680 48549 47444 46364 45309 44278 43270 42285 41322 40382 39462 38564 37686 36828 35990 35171 34370 33588 32823 32076 31346 30633 29935 29254 28588 27937 27301 26680 26073 25479 24899 24332 23778 23237 22708 22191 21686 21193 20710 20239 19778 19328 18888 18458 18038 17627 17226 16834 16451) #distance between UE, these values are rounded
export PtVec=(10) #transmit power, in dBm
export noiseFigureVec=(0) #noise figure, dBm
export fcVec=(23280) #center frequency, in MHz, these values are specific, 23280(band 14) 22750(band 11) 18000(band 1)
export dataPoints=10000
export version="data-SINR-experiments" #Version for logging run output
export recovery=true

export container="$version-discovery-scenarios"
mkdir -p $container

cd $container
for ((UE=$minUE; UE<=$maxUE; UE+=1))
do
	c1="UE$UE"
	mkdir -p $c1
	cd $c1
	c2="theta$tx"
	mkdir -p $c2
	cd $c2
	
	#minNt=$(($UE/4))
	#maxNt=$((4*$UE))
	
	for ((Nt=$minNt; Nt<=$maxNt; Nt++))
	do
		for ((Nf=$minNf; Nf<=$maxNf; Nf++))
		do
			Nr=$(($Nf*$Nt))
			c3="Nr=$Nr,Nt=$Nt"
			mkdir -p $c3
		done
	done
	cd ../..
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
    c3=${7}
    d=${8}
    Pt=${9}
    noiseFigure=${10}
    fc=${11}
    newdir="${container}/${c1}/${c3}/${c2}/${version}-${UE}-${Nr}-${Nt}-${d}-${Pt}-${noiseFigure}-${fc}-${run}"
    if [[ -d $newdir && $OVERWRITE == "0" ]];then
        echo "$newdir exist! Use -f option to overwrite."
        return
    fi
    mkdir -p $newdir
    cd $newdir #{newdir}/
    OUTFILE="$log-${version}-${UE}-${Nr}-${Nt}-${d}-${Pt}-${noiseFigure}-${fc}-${run}.txt"
    #rm -f $OUTFILE
    echo "UEs in simluation = $UE" >> $OUTFILE
    #echo "Simulation time = $stime" >> $OUTFILE
    echo -e "-------------------------------\n" >> $OUTFILE
    if [[ $profile == "optimized" ]]; then
        ../../../../../build/src/lte/examples/ns3-dev-wns3-2017-discovery-optimized --RngRun=$run --txProb=$tx --numUe=$UE --Nf=$Nf --Nt=$Nt --enableRecovery=$recovery --d=$d --Pt=$Pt --noiseFigure=$noiseFigure --fc=$fc >> $OUTFILE 2>&1
    elif [[ $profile == "debug" ]]; then
        ../../../../../build/src/lte/examples/ns3-dev-wns3-2017-discovery-debug --RngRun=$run --txProb=$tx --numUe=$UE --Nf=$Nf --Nt=$Nt --enableRecovery=$recovery --d=$d --Pt=$Pt --noiseFigure=$noiseFigure --fc=$fc >> $OUTFILE 2>&1
    else
        echo "Profile: $profile not found"
        exit
    fi
    cd ../..
}

export -f run-scenario

export simcount=0
for ((UE=$minUE; UE<=$maxUE; UE +=1))
do
	c1="UE$UE"
	
	#determine how many runs we need
	#top=$(($dataPoints+$UE-1))
	#bottom=$(($UE))
	#ENDRUN=$(($top/$bottom))
	
	#determine the range of the pool size
	#minNt=100 #$(($UE/4))
	#maxNt=$((4*$UE))
	
	for ((Nt=$minNt; Nt<=$maxNt; Nt++))
	do
		for ((Nf=$minNf; Nf<=$maxNf; Nf++))
		do
			Nr=$(($Nf*$Nt))
			c2="Nr=$Nr,Nt=$Nt"
			c3="theta$tx"
			
			for d in ${dVec[@]};
			do
				for Pt in ${PtVec[@]};
				do
					for noiseFigure in ${noiseFigureVec[@]};
					do
						for fc in ${fcVec[@]};
						do
							
							
							for ((run=$STARTRUN; run<=$dataPoints; run++))
							do
								
								echo "RUN: ${version}-${Nf}-${Nt}-${UE}-${d}-${Pt}-${noiseFigure}-${fc}-${run}"
								simcount=$((simcount + 1))
								run-scenario $run $UE $Nt $Nf $c1 $c2 $c3 $d $Pt $noiseFigure $fc &
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

