/* -*-  Mode: C++; c-file-style: "gnu"; indent-tabs-mode:nil; -*- */
/*
 * NIST-developed software is provided by NIST as a public
 * service. You may use, copy and distribute copies of the software in
 * any medium, provided that you keep intact this entire notice. You
 * may improve, modify and create derivative works of the software or
 * any portion of the software, and you may copy and distribute such
 * modifications or works. Modified works should carry a notice
 * stating that you changed the software and should note the date and
 * nature of any such change. Please explicitly acknowledge the
 * National Institute of Standards and Technology as the source of the
 * software.
 *
 * NIST-developed software is expressly provided "AS IS." NIST MAKES
 * NO WARRANTY OF ANY KIND, EXPRESS, IMPLIED, IN FACT OR ARISING BY
 * OPERATION OF LAW, INCLUDING, WITHOUT LIMITATION, THE IMPLIED
 * WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE,
 * NON-INFRINGEMENT AND DATA ACCURACY. NIST NEITHER REPRESENTS NOR
 * WARRANTS THAT THE OPERATION OF THE SOFTWARE WILL BE UNINTERRUPTED
 * OR ERROR-FREE, OR THAT ANY DEFECTS WILL BE CORRECTED. NIST DOES NOT
 * WARRANT OR MAKE ANY REPRESENTATIONS REGARDING THE USE OF THE
 * SOFTWARE OR THE RESULTS THEREOF, INCLUDING BUT NOT LIMITED TO THE
 * CORRECTNESS, ACCURACY, RELIABILITY, OR USEFULNESS OF THE SOFTWARE.
 *
 * You are solely responsible for determining the appropriateness of
 * using and distributing the software and you assume all risks
 * associated with its use, including but not limited to the risks and
 * costs of program errors, compliance with applicable laws, damage to
 * or loss of data, programs or equipment, and the unavailability or
 * interruption of operation. This software is not intended to be used
 * in any situation where a failure could cause risk of injury or
 * damage to property. The software developed by NIST employees is not
 * subject to copyright protection within the United States.
 */


#include "ns3/lte-module.h"
#include "ns3/core-module.h"
#include "ns3/network-module.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-module.h"
#include "ns3/applications-module.h"
#include "ns3/point-to-point-module.h"
#include "ns3/config-store.h"
#include <cfloat>
#include <sstream>
#include <unordered_map>
#include <unordered_set>

using namespace ns3;

NS_LOG_COMPONENT_DEFINE ("wns3-2017-discovery");

std::unordered_map<uint64_t, std::unordered_set<uint32_t> > monitorAppsPerImsi;
std::unordered_map<uint64_t, std::unordered_set<uint32_t> > discoveredAppsPerImsi;

void SlStartDiscovery (Ptr<LteHelper> helper, Ptr<NetDevice> ue, std::list<uint32_t> apps, bool rxtx)
{
  helper->StartDiscovery (ue, apps, rxtx);
}

void SlStopDiscovery (Ptr<LteHelper> helper, Ptr<NetDevice> ue, std::list<uint32_t> apps, bool rxtx)
{
  helper->StopDiscovery (ue, apps, rxtx);
}

void DiscoveryMonitoringTrace (Ptr<OutputStreamWrapper> stream, uint64_t imsi, uint16_t cellId, uint16_t rnti, uint32_t proSeAppCode)
{
  *stream->GetStream () << Simulator::Now ().GetSeconds () << "\t" << imsi << "\t" << cellId << "\t" << rnti << "\t" << proSeAppCode << std::endl;

  auto retMap = monitorAppsPerImsi.find (imsi);
  if (retMap == monitorAppsPerImsi.end ())
    {
      auto retDiscoverdMap = discoveredAppsPerImsi.find (imsi);
      NS_ABORT_MSG_IF (retDiscoverdMap == discoveredAppsPerImsi.end (), "Imsi "
                                       << imsi << " have no monitoring app installed");
    }
  else
    {
      auto retSet = retMap->second.find (proSeAppCode);
      if (retSet == retMap->second.end ())
        {
          auto retDiscoveredApp = discoveredAppsPerImsi [imsi].find (proSeAppCode);
          NS_ABORT_MSG_IF (retDiscoveredApp == discoveredAppsPerImsi [imsi].end (), "Imsi "
                                            << imsi << " is not monitoring ProSe APP code = " << proSeAppCode);
          NS_LOG_DEBUG ("Found APP " << proSeAppCode << " in already discovered map");
        }
      else
        {
          discoveredAppsPerImsi [imsi].insert (proSeAppCode);
          retMap->second.erase (retSet);
          NS_LOG_DEBUG ("At " << Simulator::Now ().GetSeconds () << " sec erased ProSe App code " << proSeAppCode);
        }

      if (retMap->second.size () == 0)
        {
          monitorAppsPerImsi.erase (imsi);
          NS_LOG_DEBUG ("At " << Simulator::Now ().GetSeconds () << " sec erased IMSI " << imsi);
        }

      if (monitorAppsPerImsi.size () == 0)
        {
          NS_LOG_DEBUG ("At " << Simulator::Now ().GetSeconds ()
                        << " sec all the UEs have discovered each other. Exiting simulation");
          Simulator::Stop ();
        }
    }
}

void DiscoveryAnnouncementPhyTrace (Ptr<OutputStreamWrapper> stream, std::string imsi, uint16_t cellId,
                                    uint16_t rnti, uint32_t proSeAppCode, int rb1, int rb2)
{
  *stream->GetStream () << Simulator::Now ().GetSeconds () << "\t" << imsi << "\t" << cellId
                        << "\t"  << rnti << "\t" << proSeAppCode << "\t" << rb1 << "\t" << rb2 << std::endl;
}

void DiscoveryAnnouncementMacTrace (Ptr<OutputStreamWrapper> stream, std::string imsi, uint16_t rnti, uint32_t proSeAppCode)
{
  *stream->GetStream () << Simulator::Now ().GetSeconds () << "\t" << imsi << "\t" << rnti << "\t" << proSeAppCode << std::endl;
}

void EndSimulation (double simTime)
{
  if (Simulator::Now ().GetSeconds () != simTime)
    {
      Simulator::Schedule (Seconds (simTime), &EndSimulation, simTime);
    }
  else
    {
      NS_LOG_DEBUG ("Maximum simulation time has elapsed. Calling Simulator::Stop () at " << simTime << " sec");
      Simulator::Stop ();
    }
}

int
main (int argc, char *argv[])
{
  // Initialize some values
  double simTime = 5;
  uint32_t nbUes = 2;
  uint16_t txProb = 100;
  double Nf = 1;
  double Nt = 300;
  bool useRecovery = false;
  bool  enableNsLogs = false; // If enabled will output NS LOGs
  double d = 1000; //distance between UE
  double Pt = -30.058669281218442; //dBM
  double noiseFigure = 0; //dB
  uint32_t fc = 23280; //this isnt exactly the center frequency, but rather a mapping

  // Command line arguments
  CommandLine cmd;
  cmd.AddValue ("simTime", "Simulation time", simTime);
  cmd.AddValue ("numUe", "Number of UEs", nbUes);
  cmd.AddValue ("Nf", "Number of frequency subcarriers", Nf);
  cmd.AddValue ("Nt", "Number of timeslots", Nt);
  cmd.AddValue ("txProb", "initial transmission probability", txProb);
  cmd.AddValue ("enableRecovery", "error model and HARQ for D2D Discovery", useRecovery);
  cmd.AddValue ("enableNsLogs", "Enable NS logs", enableNsLogs);
  cmd.AddValue ("d", "distance between the UE", d);
  cmd.AddValue ("Pt", "transmit power", Pt);
  cmd.AddValue ("noiseFigure", "noise figure", noiseFigure);
  cmd.AddValue ("fc", "center frequency", fc);

  cmd.Parse (argc, argv);

  if (enableNsLogs)
    {
      LogLevel logLevel = (LogLevel)(LOG_PREFIX_FUNC | LOG_PREFIX_TIME | LOG_PREFIX_NODE | LOG_LEVEL_ALL);
      LogComponentEnable ("wns3-2017-discovery", logLevel);
	  LogComponentEnable ("MultiModelSpectrumChannel", logLevel);
	  LogComponentEnable ("LteSlInterference", logLevel);
	  LogComponentEnable ("LteSlChunkProcessor", logLevel);
      LogComponentEnable ("LteSpectrumPhy", logLevel);
      LogComponentEnable ("LteUePhy", logLevel);
      LogComponentEnable ("LteUeRrc", logLevel);
      LogComponentEnable ("LteEnbPhy", logLevel);
      LogComponentEnable ("LteUeMac", logLevel);
      LogComponentEnable ("LteSlUeRrc", logLevel);
      LogComponentEnable ("LteSidelinkHelper", logLevel);
      LogComponentEnable ("LteHelper", logLevel);
    }
  
  
  // Set the UEs power in dBm
  Config::SetDefault ("ns3::LteUePhy::EnableUplinkPowerControl", BooleanValue (true)); //turn off power control
  Config::SetDefault ("ns3::LteUePhy::TxPower", DoubleValue(-1*Pt));
  Config::SetDefault ("ns3::LteUePhy::NoiseFigure",DoubleValue(noiseFigure));   //for SNR: /1000 // for SINR make it closed to negative infinity in dB scale.
  // Use error model and HARQ for D2D Discovery (recovery process)
  Config::SetDefault ("ns3::LteSpectrumPhy::SlDiscoveryErrorModelEnabled", BooleanValue (useRecovery));
  Config::SetDefault ("ns3::LteSpectrumPhy::DropRbOnCollisionEnabled", BooleanValue (true));

  ConfigStore inputConfig;
  inputConfig.ConfigureDefaults ();

  NS_LOG_INFO ("Creating helpers...");
  Ptr<LteHelper> lteHelper = CreateObject<LteHelper> ();
  Ptr<PointToPointEpcHelper>  epcHelper = CreateObject<PointToPointEpcHelper> ();
  lteHelper->SetEpcHelper (epcHelper);

  // Set pathloss model
  lteHelper->SetAttribute ("PathlossModel", StringValue ("ns3::FriisPropagationLossModel"));
  lteHelper->SetAttribute ("UseSidelink", BooleanValue (true));
  lteHelper->Initialize ();

  // Since we are not installing eNB, we need to set the frequency attribute of pathloss model here
  // Frequency for Public Safety use case (band 14 : 788 - 798 MHz for Uplink)
  double ulFreq = LteSpectrumValueHelper::GetCarrierFrequency (fc);
  NS_LOG_LOGIC ("UL freq: " << ulFreq);
  Ptr<Object> uplinkPathlossModel = lteHelper->GetUplinkPathlossModel ();
  Ptr<PropagationLossModel> lossModel = uplinkPathlossModel->GetObject<PropagationLossModel> ();
  NS_ABORT_MSG_IF (lossModel == NULL, "No PathLossModel");
  bool ulFreqOk = uplinkPathlossModel->SetAttributeFailSafe ("Frequency", DoubleValue (ulFreq));
  if (!ulFreqOk)
    {
      NS_LOG_WARN ("UL propagation model does not have a Frequency attribute");
    }

  NS_LOG_INFO ("Deploying UE's...");
  NodeContainer ues;
  ues.Create (nbUes);

  //Position of the nodes
  Ptr<ListPositionAllocator> positionAllocUe = CreateObject<ListPositionAllocator> ();

  for (uint32_t u = 0; u < ues.GetN (); ++u)
    {
      Ptr<UniformRandomVariable> rand = CreateObject<UniformRandomVariable> ();
      double x = rand->GetValue (-d,d);
      double y = rand->GetValue (-d,d);
      
      //if(u==0)
      //{
		//x=0;
		//y=0;  
      //}
      //else if(u==1)
      //{
		  //x=0;
		  //y=d/1000;
	  //}
	  //else
	  //{
		  //x=0;
		  //y=1000;
	  //}
      
      double z = 1.5;
      positionAllocUe->Add (Vector (x, y, z));
    }

  // Install mobility
  MobilityHelper mobilityUe;
  mobilityUe.SetMobilityModel ("ns3::ConstantPositionMobilityModel");
  mobilityUe.SetPositionAllocator (positionAllocUe);
  mobilityUe.Install (ues);

  NetDeviceContainer ueDevs = lteHelper->InstallUeDevice (ues);

  //Fix the random number stream
  uint16_t randomStream = 1;
  randomStream += lteHelper->AssignStreams (ueDevs, randomStream);

  AsciiTraceHelper asc;
  Ptr<OutputStreamWrapper> st = asc.CreateFileStream ("discovery_nodes.txt");
  *st->GetStream () << "id\tx\ty" << std::endl;

  for (uint32_t i = 0; i < ueDevs.GetN (); ++i)
    {
      Ptr<LteUeNetDevice> ueNetDevice = DynamicCast<LteUeNetDevice> (ueDevs.Get (i));
      uint64_t imsi = ueNetDevice->GetImsi ();
      Vector pos = ues.Get (i)->GetObject<MobilityModel> ()->GetPosition ();
      std::cout << "UE " << i << " id = " << ues.Get (i)->GetId () << " / imsi = " << imsi << " / position = [" << pos.x << "," << pos.y << "," << pos.z << "]" << std::endl;
      *st->GetStream () << imsi << "\t" << pos.x << "\t" << pos.y << std::endl;
    }

  NS_LOG_INFO ("Configuring discovery pool for the UEs...");
  Ptr<LteSlUeRrc> ueSidelinkConfiguration = CreateObject<LteSlUeRrc> ();
  ueSidelinkConfiguration->SetDiscEnabled (true);

  //todo: specify parameters before installing in UEs if needed
  LteRrcSap::SlPreconfiguration preconfiguration;

  preconfiguration.preconfigGeneral.carrierFreq = fc;
  preconfiguration.preconfigGeneral.slBandwidth = 50;
  preconfiguration.preconfigDisc.nbPools = 1;
  preconfiguration.preconfigDisc.pools[0].cpLen.cplen = LteRrcSap::SlCpLen::NORMAL;
  preconfiguration.preconfigDisc.pools[0].discPeriod.period = LteRrcSap::SlPeriodDisc::rf32;
  preconfiguration.preconfigDisc.pools[0].numRetx =0;
  preconfiguration.preconfigDisc.pools[0].numRepetition = 1;
  preconfiguration.preconfigDisc.pools[0].tfResourceConfig.prbNum = Nf;
  preconfiguration.preconfigDisc.pools[0].tfResourceConfig.prbStart = 10;
  
  if (Nf == 1){
	  preconfiguration.preconfigDisc.pools[0].tfResourceConfig.prbEnd = 11;
  } else {
	  preconfiguration.preconfigDisc.pools[0].tfResourceConfig.prbEnd = 10 + 2*Nf -1;
  }
  
  
  preconfiguration.preconfigDisc.pools[0].tfResourceConfig.offsetIndicator.offset = 0;
  
  std::string a="";
  for (int i = 0; i < Nt*(preconfiguration.preconfigDisc.pools[0].numRetx+1); i++)
  {
	  a.append("1");
  }
  preconfiguration.preconfigDisc.pools[0].tfResourceConfig.subframeBitmap.bitmap = std::bitset<400> (a);
  
  preconfiguration.preconfigDisc.pools[0].txParameters.txParametersGeneral.alpha = LteRrcSap::SlTxParameters::al09;
  preconfiguration.preconfigDisc.pools[0].txParameters.txParametersGeneral.p0 = -40;
  preconfiguration.preconfigDisc.pools[0].txParameters.txProbability = SidelinkDiscResourcePool::TxProbabilityFromInt (txProb);

  NS_LOG_INFO ("Install Sidelink discovery configuration in the UEs...");
  ueSidelinkConfiguration->SetSlPreconfiguration (preconfiguration);
  lteHelper->InstallSidelinkConfiguration (ueDevs, ueSidelinkConfiguration);

  NS_LOG_INFO ("Configuring discovery applications");
  std::map<Ptr<NetDevice>, std::list<uint32_t> > announceApps;
  std::map<Ptr<NetDevice>, std::list<uint32_t> > monitorApps;
  for (uint32_t i = 1; i <= nbUes; ++i)
    {
      announceApps[ueDevs.Get (i - 1)].push_back ((uint32_t)i);
      for (uint32_t j = 1; j <= nbUes; ++j)
        {
          if (i != j)
            {
              monitorApps[ueDevs.Get (i - 1)].push_back ((uint32_t)j);
              monitorAppsPerImsi[DynamicCast<LteUeNetDevice> (ueDevs.Get (i - 1))->GetImsi()].insert (j);
            }
        }
    }

  for (uint32_t i = 0; i < nbUes; ++i)
    {
      Simulator::Schedule (Seconds (2.0), &SlStartDiscovery, lteHelper, ueDevs.Get (i),announceApps.find (ueDevs.Get (i))->second, true); // true for announce
      Simulator::Schedule (Seconds (2.0), &SlStartDiscovery, lteHelper, ueDevs.Get (i), monitorApps.find (ueDevs.Get (i))->second, false); // false for monitor
    }

  ///*** End of application configuration ***///

  // Set Discovery Traces
  AsciiTraceHelper ascii;
  Ptr<OutputStreamWrapper> stream = ascii.CreateFileStream ("discovery-out-monitoring.tr");
  *stream->GetStream () << "Time\tIMSI\tCellId\tRNTI\tProSeAppCode" << std::endl;

  AsciiTraceHelper ascii1;
  Ptr<OutputStreamWrapper> stream1 = ascii1.CreateFileStream ( "discovery-out-announcement-phy.tr");
  *stream1->GetStream () << "Time\tIMSI\tCellId\tRNTI\tProSeAppCode\tRB1\tRB2" << std::endl;

  //AsciiTraceHelper ascii2;
  //Ptr<OutputStreamWrapper> stream2 = ascii1.CreateFileStream ( "discovery-out-announcement-mac.tr");
  //*stream2->GetStream () << "Time\tIMSI\tRNTI\tProSeAppCode" << std::endl;

  std::ostringstream oss;
  oss.str ("");
  for (uint32_t i = 0; i < ueDevs.GetN (); ++i)
    {
      Ptr<LteUeRrc> ueRrc = DynamicCast<LteUeRrc> ( ueDevs.Get (i)->GetObject<LteUeNetDevice> ()->GetRrc () );
      ueRrc->TraceConnectWithoutContext ("DiscoveryMonitoring", MakeBoundCallback (&DiscoveryMonitoringTrace, stream));
      oss << ueDevs.Get (i)->GetObject<LteUeNetDevice> ()->GetImsi ();
      Ptr<LteUePhy> uePhy = DynamicCast<LteUePhy> ( ueDevs.Get (i)->GetObject<LteUeNetDevice> ()->GetPhy () );
      uePhy->TraceConnect ("DiscoveryAnnouncement", oss.str (), MakeBoundCallback (&DiscoveryAnnouncementPhyTrace, stream1));
      //Ptr<LteUeMac> ueMac = DynamicCast<LteUeMac> ( ueDevs.Get (i)->GetObject<LteUeNetDevice> ()->GetMac () );
      //ueMac->TraceConnect ("DiscoveryAnnouncement", oss.str (), MakeBoundCallback (&DiscoveryAnnouncementMacTrace, stream2));
      oss.str ("");
    }
  NS_LOG_INFO ("Starting simulation...");

  //Schedule Simulator::Stop ()
  //EndSimulation (simTime);

  Simulator::Run ();
  Simulator::Destroy ();
  return 0;

}
