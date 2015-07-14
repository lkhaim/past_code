# $Id$
#

package NBT::GRiTS::SRDF::SrdfSmoke;

use strict;
use warnings;

use NBT::GRiTS::SRDF;
use NBT::Math;
use NBT::Trace qw(:trace);
use NBT::Traffic;

our @ISA = qw(NBT::GRiTS::SRDF);

=head1 NAME

NBT::GRiTS::SRDF::SrdfSmoke

=head1 DESCRIPTION

This is a smoke test for SRDF functionality that is pretty much following
"A common case of SRDF traffic" test case in Icebox:
https://icebox/testcase/edit/9993/.

Differently from the Icebox version, each of the Symmetrix storage arrays
has 5 RDF groups each and is opening 5 connections. Also tput and reduction
are checked only after 5min of running traffic.

Using parameters in the YAML file (no_config, no_store_clean, no_cleanup,
and no_config_swap) one can skip configuration, restart sport without cleaning
the data store, skip cleanup altogether so that configuration can be reused,
or just skip rewriting working configuration at the end of the test case
with the one that was on Steelheads at the beginning of the test.

Validation is performed by, first, comparing general optimized tput with
the same measurements performed by SRDF blade. Second, by comparing
data reduction for each symmid and each RDF group with the benchmarks provided
via YAML file, which is described in more details in the L<"SYNOPSIS"> section.
And third, if parse_logs==1, by checking that no records at "warning" and
higher were printed to the syslog while optimized traffic was running.

=head1 REQUIREMENTS

There have to be 2 Steelheads and 2 client/server pairs in the allocation
used for running the test:

   client1-cfe---tdnb---sfe-server1
   client2/                \server2

STT has to be installed on both client/server pairs. Both client/server pairs
can be on the same interface or on separate ones. The dummynet is optional but
warnings will be logged if there is none.

=head1 MANDATORY RESOURCE ROLES AND OTHER REQUIREMENTS

Resources must have the following roles in VLAB in order for this test to run:

=over 2

=item I<sfe>

Steelhead closest to the simulated Symmetrix arrays, which are sending data;

=item I<cfe>

Steelhead closest to the simulated Symmetrix arrays, which are receiving data;

=item I<client1> and I<client2>

Two clients using STT to simulate data-receiving Symmetrix arrays;

=item I<server1> and I<server2>

B<Note:> Two servers using STT to simulate data-sending Symmetrix arrays;

=back

The interfaces used on the servers have to be called "test."

=head1 SYNOPSIS

The test can be started with a standard command line:

 grits.pl --vlab=VLAB365 --allocation=trans test_SrdfSmoke.yml

Parameters for the test are submitted via a YAML file like the one below.
They are described in the L<"PARAMETERS"> section.

 - module: NBT::GRiTS::SRDF::SrdfSmoke
   params:
     no_config: 1
     no_store_clean: 0
     no_cleanup: 1
     no_config_swap: 1
     DummyNetBandwidth: 62200
     DummyNetDelay: 20
     DummyNetPacketLossRate: 0
     bdp_value: 3110000
     lan_size: 1000000
     link_rate: 100000000
     logging:
       parse_logs: 1
       local_log_level: notice
     pair_2_delay: 30
     run_time: 330
     interval: 5min
     traffic_options:
       pair_1:
         binary_client: /u/qa/tools/stt-bin/stt-client-v3.0.0
         binary_server: /u/qa/tools/stt-bin/stt-server-v3.0.0
         checksum_option: -L
         connection: 5
         data_length: 500
         data_type: 8
         idle_time: -1
         independent_dataset: 1
         no_con_check: 1
         port_num: 1749
         proto: stt
         bandwidth: 1024000
         report_interval: 60
         retry: 2
         retry_wait: 5
         srdf_stt: 32:5:512
         wait_for_conn: 10
       pair_2:
         binary_client: /u/qa/tools/stt-bin/stt-client-v3.0.0
         binary_server: /u/qa/tools/stt-bin/stt-server-v3.0.0
         checksum_option: -L
         connection: 5
         data_length: 500
         data_pos: 1000000000000000
         data_type: 8
         idle_time: -1
         independent_dataset: 1
         no_con_check: 1
         port_num: 1749
         proto: stt
         bandwidth: 1024000
         report_interval: 60
         retry: 2
         retry_wait: 5
         srdf_stt: 32:5:512
         wait_for_conn: 10
     srdf_set:
       sfe:
         ports:
           - 1748
           - 1749
         rules:
           - dif: enable
             src-ip: 0.0.0.0
             dif-blocksize: 512
             dst-ip: 0.0.0.0
       cfe:
         ports:
           - 1748
           - 1749
         rules:
           - dif: enable
             src-ip: 0.0.0.0
             dif-blocksize: 512
             dst-ip: 0.0.0.0
     validation:
       tput_dif_lwr_lmt: 0.9
       tput_dif_upr_lmt: 1.0
       rdxn_total_lwr_lmt: 75.1
       rdxn_total_upr_lmt: 75.3
       rdxn_none_lwr_lmt: -1.7
       rdxn_none_upr_lmt: -1.6
       rdxn_lz-only_lwr_lmt: 80.1
       rdxn_lz-only_upr_lmt: 80.3
       rdxn_sdr-default_lwr_lmt: 99.1
       rdxn_sdr-default_upr_lmt: 99.3

=head1 PARAMETERS

L<"SYNOPSIS"> section contains an example of the correctly indented YAML file
with the parameters. Their meaning and range of values is described below.

=over 2

=item no_config

Can be "0" to configure Steelheads and dummynet, or "1" to skip configuring
them.

=item no_store_clean

Can be "0" to clean the segstore both in configure() and
clean_up() methods, or "1" to skip doing that.

=item no_cleanup

Can be "0" to run cleanup() method, or "1" to skip it.

=item no_config_swap

Can be "0" to rewrite working configuration at the end of the test case with
the one that was on Steelheads at the beginning of the test, or "1" to skip it.

=item DummyNetBandwidth

A value in kbps used for configuring dummynets with the bandwidth limit.

=item DummyNetDelay

A value in milliseconds for configuring dummynets with the delay.

=item DummyNetPacketLossRate

A value in percents for configuring dummynets with the packet loss rate.

=item bdp_value

Bandwidth-Delay Product value in bytes selected for testing.
See "Choosing the Steelhead Appliance WAN Buffer Settings" section
in Riverbed Deployment Guide and online help for
"Configure › Optimization › Transport Settings" page in a Steelhead's WebUI
for more detail.

=item lan_size

A value in bytes for configuring LAN send and receive buffer size. See online
help for "Configure › Optimization › Transport Settings" page
in a Steelhead's WebUI for more detail.

=item link_rate

A value in kbps for configuring QoS on each WAN interface with the smaller of
it and BW limit for this model. See online help for
"Configure › Networking › Outbound QoS (Advanced)" page in a Steelhead's WebUI
for more detail.

=item logging

A section determening what is written to the syslog and how it is used
by the test. It contains 2 keys: parse_logs and local_log_level,
described below.

=back

=over 4

=item parse_logs

Can be "1" to search syslog written during the test case duration for records
at "warning" and higher, or "0" to do no parsing. If "1" is selected,
the offending records will be written into the test log and
the test will be failed.

=item local_log_level

Determines the minimum severity of records written to syslog.
See online help for "Configure › System Settings › Logging" page
in a Steelhead's WebUI for more detail.

=back

=over 2

=item pair_2_delay

Time delay in seconds between the onset of traffic in the first and second
client/server pair.

=item run_time

Duration in seconds of traffic flow on both client/server pairs.

=item interval

Time interval for measuring average throughput and data reduction.
See online help for "Reports › Optimization › SRDF" page in a Steelhead's WebUI
for more detail. All legitimate values of time intervals can be found
by running "show stats protocol srdf interval ?"

=item traffic_options

A section with two hashes--pair_1 and pair_2--for configuring STT traffic
on the two client/server pairs.

=back

=over 4

=item pair_1 ( and pair_2)

Parameters for configuring traffic objects instantiated via L<NBT::Traffic> and
L<NBT::Traffic::STT> classes on the two client/server pairs. For more detail
refer to the POD of those classes (http://pod/qalib/NBT/Traffic.html).

=back

=over 2

=item srdf_set

A section with two hashes for configuring SRDF optimization on CFE and SFE.
It contains 2 keys: cfe and sfe, described below.

=back

=over 4

=item sfe (and cfe)

A hash of two arrays--ports and rules--for configuring SRDF ports and rules.

=back

=over 6

=item ports

A list of ports for configuring SRDF optimization. See online help for
"Configure › Optimization › SRDF" page in a Steelhead's WebUI for more detail.

=item rules

List of hashes with parameters of the rules for configuring SRDF optimization.
See online help for "Configure › Optimization › SRDF" page in a Steelhead's
WebUI for more detail. 

=back

=over 2

=item validation

A section with benchmark values used for validating the test case.
The values have to be matching the test setup (environment, Steelhead settings,
and traffic).

=back

=over 4

=item tput_dif_lwr_lmt

The test is failed if the measured SRDF throughput is below this fraction of
all optimized throughput.

=item tput_dif_upr_lmt

The test is failed if the measured SRDF throughput is above this fraction of
all optimized throughput.

=item rdxn_total_lwr_lmt

The test is failed if the measured total data reduction for any Symmetrix array
is below this percentage value.

=item rdxn_total_upr_lmt

The test is failed if the measured total data reduction for any Symmetrix array
is above this percentage value.

=item rdxn_none_lwr_lmt

The test is failed if the measured data reduction for any RDF group configured
with "none" optimization policy is below this percentage value.

=item rdxn_none_upr_lmt

The test is failed if the measured data reduction for any RDF group configured
with "none" optimization policy is above this percentage value.

=item rdxn_lz-only_lwr_lmt

The test is failed if the measured data reduction for any RDF group configured
with "lz-only" optimization policy is below this percentage value.

=item rdxn_lz-only_upr_lmt

The test is failed if the measured data reduction for any RDF group configured
with "lz-only" optimization policy is above this percentage value.

=item rdxn_sdr-default_lwr_lmt

The test is failed if the measured data reduction for any RDF group configured
with "sdr-default" optimization policy is below this percentage value.

=item rdxn_sdr-default_upr_lmt

The test is failed if the measured data reduction for any RDF group configured
with "sdr-default" optimization policy is above this percentage value.

=back

=head1 INSTANCE VARIABLES

=over 2

=item {rdfgr_per_symmid}

This is {$symmid => $rdf_gr_count} hash capturing how many rdf groups there are
per symmid.

=item {syslog_problems}

Returned by NBT::Appliance::parse_log() at the time traffic is stopped.
$self->{syslog_problems}->{trap_errors} contains a list of "warning" and higher
records in the syslog.

=item {tput}

A nested hash returned by NBT::SH::Feature::SRDF::Malta::show_stats_tput() and
containing SRDF throughput and reduction stats for each Symmetrix array.

=item {optimized_lan_tput}

Average LAN throughput returned by
NBT::SH::Model::Stats::Tuvalu::show_stats_throughput().

=item {optimized_wan_tput}

Average WAN throughput returned by
NBT::SH::Model::Stats::Tuvalu::show_stats_throughput().

=back

=head1 METHODS

=over 2

=item configure()

Saves the current working configuration if it will be restored during cleanup
(see L<no_config_swap> parameter). Cleans the segstore unless parameter
L<no_store_clean> is set to "1". Configures Symmetrix arrays for selective
optimization. Calculates params to be sent to SUPER::configure and calls it.
Configures the dummynets.
On both SFE and CFE adds ports, rules, and enables SRDF blade.

The whole method can be skipped (saving the current config and cleaning the
segstore still will be done if requested) by setting parameter L<no_config>
to "1".

=cut

sub configure {
    my $self = shift;
    my $params = $self->{params};

    # Save initial configuration if it will be restored during cleanup
    unless ( $params->{no_config_swap} ) {
        for my $role (qw(cfe sfe)) {
            my $modelobj = $self->{$role}->get_model();
            my $save_initial_config =
                $modelobj->config_write_to( name => 'initial_config' );
            my $config_switch = $modelobj->config_switch( name => 'working' );
            # Restarting is needed here only if it's not done
            # later during configuration or store cleaning
            if ($params->{no_config} == 1 && $params->{no_store_clean} == 1) {
                my $restart = $self->{$role}->write_and_restart();
            }
        }
    }

    # Skip configuring Steelheads and dummynet if that was requested via YAML
    if ( $params->{no_config} ) {
        trace_warn( "Configuration purposefully skipped." );
        # Skip data store cleaning if that was requested via YAML
        if ( $params->{no_store_clean} ) {
            trace_warn( "Store cleaning purposefully skipped." );
            return 1;
        }
        for my $role (qw(cfe sfe)) {
            $self->{$role}->write_and_restart ( clean => 1 )
        }
        
        return 1;
    }
    
    # Get 2 servers and 2 clients
    # Presence of CFE and SFE is checked in NBT::GRiTS::SRDF::new()
    for my $role (qw(client1 client2 server1 server2)) {
        $self->{$role} = $self->{resources}->{$role}->[0]
            or throw ("%s not found.", $role);
    }

    # Configure symmids and selective optimization policies
    my $symmids_opols = $self->_config_symmids_opols();

    # Calculate a total stt connection number on all client/server pairs
    my $total_conn_count =
        $params->{traffic_options}->{pair_1}->{connection} +
        $params->{traffic_options}->{pair_2}->{connection};

    # Sets WAN buffer size to 2 times BDP value
    # (see "Choosing the Steelhead Appliance WAN Buffer Settings" section in
    # Riverbed Deployment Guide).
    my $wan_size = 2 * $params->{bdp_value};

    $self->SUPER::configure( wan_size => $wan_size,
                             lan_size => $params->{lan_size},
                             link_rate => $params->{link_rate},
                             total_conn_count => $total_conn_count,
                             symmids => $symmids_opols->{symmids},
                             optim_policies => $symmids_opols->{opols},
                             local_log_level =>
                                $params->{logging}->{local_log_level} );

    # Non-default parameters for the dummynet setup should be in the YAML file
    $self->SUPER::dummynet_setup();

    # On both SFE and CFE add ports, rules, and enable SRDF blade
    # ( $self->{sfe} and $self->{cfe} are created in the SUPER::configure() )
    for my $role (qw(cfe sfe)) {
        my $srdf = $self->{$role}->get_feature(name=>"SRDF")
            or trace_warn( "Could not get SRDF feature on $role" );
        if ( $params->{srdf_set}->{$role}->{ports} ) {
            $srdf->add_ports( restart => 0,
                              ports => $params->{srdf_set}->{$role}->{ports} );
        } else {
            trace_warn( "No ports to add on %s", $self->{$role}->{name} );
        }
        if ( $params->{srdf_set}->{$role}->{rules} ) {
            $srdf->add_rules( restart => 0,
                              rules => $params->{srdf_set}->{$role}->{rules} );
        } else {
            trace_warn( "No rules to add on %s", $self->{$role}->{name} );
        }
        my $srdf_enabled = $srdf->enable( restart => 0 );
        if ($srdf_enabled) {
            trace_info ( "SRDF optimization is enabled on %s",
                         $self->{$role}->{name} );
        }

        $self->{$role}->
            write_and_restart( clean => ($params->{no_store_clean} ? 0 : 1) );
    }
    return 1;
}

=item start()

Sets the starting point for parsing syslogs on both Steelheads.
Starts STT traffic on both client/server pairs.
Sleeps to allow enough time for traffic to stabilize and for collecting stats.
Measures throughput and data reduction values and saves them.
Stops STT traffic.
Parses the syslog and saves the results.

=cut

sub start {
    my $self = shift;
    my $params = $self->{params};
    
    my (@stt_traffic);

    # Get 2 servers, 2 clients, SFE, and CFE
    # Presence of CFE and SFE is checked in NBT::GRiTS::SRDF::new()
    for my $role (qw(client1 client2 server1 server2 sfe cfe)) {
        $self->{$role} = $self->{resources}->{$role}->[0]
            or throw ("%s not found.", $role);
    }

    # Get SRDF feature on SFE so we can collect stats 
    my $sfe_srdf = $self->{sfe}->get_feature(name => "SRDF") or
        trap("Could not get SRDF feature on SFE!");

    # Create STT traffic objects for both c/s pairs
    for ( my $i = 1; $i <= 2; $i++) {
        $stt_traffic[$i] = NBT::Traffic->new(
                            client => $self->{"client".$i},
                            server => $self->{"server".$i},
                            %{$params->{traffic_options}->{"pair_".$i}}
                            );
    }

    # Set a place in syslog determening from where parse_log() will be applied
    $self->{sfe}->watch_log();

    # Start STT traffic on both c/s pairs
    for ( my $i = 1; $i <= 2; $i++) {
        $stt_traffic[$i]->start();
        if ( $i < 2 ) {
            sleep($params->{pair_2_delay});
        }
    }

    # Sleep to allow enough time for traffic to stabilize and to collect stats
    sleep( $params->{run_time} );

    # Measure general optimized throughput to be used for validation
    my $modelobj = $self->{sfe}->get_model();

    $self->{optimized_lan_tput} =
        $modelobj->show_stats_throughput( type     => 'lan-to-wan',
                                          duration => $params->{interval} )
                 ->{parsed_output}->{lan}->{average_throughput};
    
    $self->{optimized_wan_tput} =
        $modelobj->show_stats_throughput( type     => 'lan-to-wan',
                                          duration => $params->{interval} )
                 ->{parsed_output}->{wan}->{average_throughput};

    # Measure SRDF throughput and reduction stats to be used for validation
    my $symmids = $sfe_srdf->show_symmids();

    foreach my $symmid ( values(%{$symmids}) ) {
        $self->{tput}->{$symmid} =
            $sfe_srdf->show_stats_tput( symmid => $symmid,
                                        interval => $params->{interval} );
    }

    # Stop STT traffic on both c/s pairs
    for ( my $i = 1; $i <= 2; $i++ ) {
        $stt_traffic[$i]->stop();
    }

    # Save results of checking syslog for "warning" and higher
    # as an instance variable to use for validation
    $self->{syslog_problems} =
        $self->{sfe}->parse_log( trap_errors => ['\.WARN',
                                                 '\.ERR',
                                                 '\.CRIT']
                               );
    return 1;
}

=item validate()

Using log_metric() logs the measured throughput and data reduction values into
the Icebox DB.
Compares values of general and srdf throughput.
Compares data reduction obtained in this test with benchmark numbers.
Fails the test by incrementing $self->{issues} if syslog on any Steelhead
contains records at "warning" and higher.

=cut

sub validate {
    my $self   = shift;
    my $params = $self->{params};
    my $v_params = $self->{params}->{validation};
    my %p = @_;

    my ( $s_name, $symmid, $m_name, $metric,
         $element, $m_dscrptn, $mu, $side );
    
    # Log LAN/WAN throughput and data reduction reported by SRDF blade
    # into Icebox DB for all Symmetrix arrays
    # The follwing abbreviations were used for variable names:
    #    s_name = Symmetrix name;
    #    m_name = metric's name;
    #    mu = measurement unit;

    foreach $s_name ( keys(%{$self->{tput}}) ) {
        $symmid = $self->{tput}->{$s_name};
        foreach $m_name ( keys(%{$symmid}) ) {
            if ( $m_name =~ /^mu_/ ) {
                next;
            }
            $metric = $self->{tput}->{$s_name}->{$m_name};
            my $i = 0;
            foreach $element ( @{$metric} ) {
                $m_dscrptn = '';
                if ($i == 0 ) {
                    $m_dscrptn = "$s_name" . "_$m_name" . "_total";
                } elsif ( $i >= 1 ) {
                    $m_dscrptn = "$s_name" . "_$m_name" . "_rdf-gr_$i";
                }
                $mu = $self->{tput}->{$s_name}->{"mu_${m_name}"};
                if (  defined $m_dscrptn  && 
                      defined $mu  &&
                      defined $element ) {
                    $self->log_metric(
                        metric_description => $m_dscrptn,
                        metric_type => "result",
                        metric_unit => $mu,
                        value => $element,
                    );
                }else{
                    trace_warn( "log_metric() params are not defined " .
                                "for %s(%s) on %s",
                                ${m_name}, $i, $s_name );
                }
            $i++;
            }
        }
    }

    # Log LAN/WAN optimized throughput reported by
    # "show stats throughput all lan-to-wan <interval>" command
    # into Icebox DB
    for $side (qw(lan wan)) {
        $self->log_metric(
            metric_description => "optimized_${side}_tput",
            metric_type => "result",
            metric_unit => $self->{"optimized_${side}_tput"}->{units},
            value => $self->{"optimized_${side}_tput"}->{value},
        );
    }

    # Calculate the total (a sum over all Symmetrix arrays)
    # of LAN/WAN optimized throughput reported by SRDF blade
    # and log it into Icebox DB
    my %srdf_tput;
    
    for $side (qw(lan wan)) {
        $srdf_tput{"${side}_sum"} = 0;
        $srdf_tput{"mu_tput_${side}"} = '';
        my $i = 0;

        foreach my $symmid ( keys( %{$self->{tput}} ) ) {
            if ( ( $self->{tput}->{$symmid}->{"mu_tput_${side}"} eq
                   $srdf_tput{"mu_tput_${side}"} ) || ( $i == 0 ) ) {
                $srdf_tput{"${side}_sum"} +=
                    $self->{tput}->{$symmid}->{"tput_${side}"}->[0];
                $srdf_tput{"mu_tput_${side}"} =
                    $self->{tput}->{$symmid}->{"mu_tput_${side}"};
            } else {
                trace_warn ( "${side} tput units differ among symmids!" );
            }
        }

        $self->log_metric(
            metric_description => "total_srdf_${side}_tput",
            metric_type => "result",
            metric_unit => $srdf_tput{"mu_tput_${side}"},
            value => $srdf_tput{"${side}_sum"},
        );
    }

    # Compare LAN/WAN throughput reported by SRDF blade and
    # by "show stats throughput all lan-to-wan <interval>" command
    my ( $gen_val, $gen_unit, $srdf_val, $srdf_unit, $gen_val_cnvrtd );

    for $side (qw(lan wan)) {
        # Assign variables to save typing
        $gen_val = $self->{"optimized_${side}_tput"}->{value};
        $gen_unit = $self->{"optimized_${side}_tput"}->{units};
        $srdf_val = $srdf_tput{"${side}_sum"};
        $srdf_unit = $srdf_tput{"mu_tput_${side}"};

        # Convert general optimized tput value to the units used by srdf one,
        # if they were not measured in the same units
        if ( $gen_unit ne $srdf_unit ) {
            $gen_val_cnvrtd = NBT::Math::convert_units_tput(
                                                    in_value => $gen_val,
                                                    in_unit => $gen_unit,
                                                    out_unit => $srdf_unit );
        } else {
            $gen_val_cnvrtd = $gen_val;
        }
        
        # Compare values of general and srdf throughput
        if ( $v_params->{tput_dif_lwr_lmt} * $gen_val_cnvrtd < $srdf_val &&
             $srdf_val < $v_params->{tput_dif_upr_lmt} * $gen_val_cnvrtd ) {
            trace_info( "General and SRDF tput on %s are as close as expected",
                        $side );
        } else {
            $self->{issues}++;
            trace_error ( "The difference between general and " .
                          "srdf tput readings on %s is too big:\n" .
                          "SRDF tput: %s(%s)\nGeneral tput: %s(%s)",
                          $side, $srdf_val, $srdf_unit, $gen_val, $gen_unit );
        }
    }

    # Compare data reduction obtained in this test with benchmark numbers
    # !!! In YAML file benchmark numbers should match the test setup !!!
    # Default case:
    # "stt-server 1749 -d 8 -R 60 -L -Z 32:5:512 -i -s 500"
    # "stt-client <server_ip> 1749 -c 5 -R 60 -Z -I -1"
    # on both Symmetrix simulating servers
    # and measurements taken at interval equal to 5min
    
    my ( $rdxn_kind, $rdxn, $lwr_lmt, $upr_lmt );
    
    # Check that $self->{rdfgr_per_symmid} is defined, because
    # it won't when configure() is skipped by setting
    # $params->{no_config} = 1
    unless ( defined $self->{rdfgr_per_symmid} ) {
        if ( $params->{no_config} == 1 ) {
            $self->_config_symmids_opols();
        } elsif ( $params->{no_config} == 0 ) {
            trap( "$self->{rdfgr_per_symmid} has to be defined, " .
                  "if params->{no_config} == 0. " );
        } else {
            trace_warn( "params->{no_config} = %s, rather than 0 or 1, " .
                        "still re-running _config_symmids_opols().",
                        $params->{no_config} );
            $self->_config_symmids_opols();
        }
    }

    # For each rdf group within each Symmetrix array
    # check that data reduction values are within the required boundaries
    foreach $s_name ( keys(%{$self->{tput}}) ) {
        for ( my $i = 0; $i <= $self->{rdfgr_per_symmid}->{$s_name}; $i++) {

            # Create short descriptors for using in the logs and hash keys
            # Optimization policies are assigned to rdf groups
            # in _config_symmids_opols()
            if ( $i == 0 ) {
                $rdxn_kind = 'total';
            } elsif ( $i == 1 ) {
                $rdxn_kind = 'none';
            } elsif ( $i == 2 ) {
                $rdxn_kind = 'lz-only';
            } else {
                $rdxn_kind = 'sdr-default';
            }

            $lwr_lmt = $v_params->{"rdxn_${rdxn_kind}_lwr_lmt"};
            $upr_lmt = $v_params->{"rdxn_${rdxn_kind}_upr_lmt"};
            
            if ( defined $self->{tput}->{$s_name}->{rdxn}->[$i] ) {
                 
                $rdxn = $self->{tput}->{$s_name}->{rdxn}->[$i];

                unless ( $lwr_lmt < $rdxn && $rdxn < $upr_lmt ) {
                    $self->{issues}++;
                    trace_error( "%s data rdxn in rdf group #%s " .
                                 " of %s Symmetrix array " .
                                 "is outside the required boundaries:\n" .
                                 "Rdxn: %s\nLower limit: %s\nUpper limit: %s",
                                 $rdxn_kind, $i, $s_name, $rdxn,
                                 $lwr_lmt, $upr_lmt );
                }

            } else {
                trace_warn( "Data rdxn was not compared with a benchmark " .
                               "on %s Symmetrix array for rdf group %s.",
                               $s_name, $i );
            }
        }
    }

    # Fail the test by incrementing $self->{issues}
    # if syslog contains records at "warning" and higher.
    if ($params->{logging}->{parse_logs}) {
        unless ( $self->{syslog_problems}->{trap_errors} eq '' ) {
            $self->{issues}++;
            trace_error ( "Here is the list of syslog problems:\n%s",
                         $self->{syslog_problems}->{trap_errors} );
        }
    } else {
        trace_warn( "Syslog is not checked for \"warning\" and higher." );
    }

    $self->SUPER::validate();

    return 1;

}

=item clean_up()

Restores both Steelheads to the state they were in before the beginning
of the test.
Resets dummynets back to the VLAB defaults.

The whole method can be skipped by setting parameter L<no_cleanup> to "1".

=cut

sub clean_up {
    my $self = shift;
    my $params = $self->{params};

    # Return from the method if no cleanup is requested
    if ( $params->{no_cleanup} ) {
        trace_warn( "Clean-up purposefully skipped." );
        return 1;
    }

    # For both SFE and CFE switch to Basic QoS, disable multi-core setup,
    # disable srdf blade, and restart sport with optional segstore cleaning.
    for my $role (qw(sfe cfe)) {
        # Switching MX-TCP to basic QoS
        my $adv_qos_feature = $self->{$role}->get_feature(
            name => 'QoSDPI::QoSAdvConfig::QoSAdvHierarchicalConfig'
        );

        unless ( $adv_qos_feature ) {
            trace_warn( "Couldn't get QoSAdvHierarchicalConfig feature on %s" .
                        " Skipping cleanup.",
                        $self->{$role}->{name} );
            next;
        }

        $adv_qos_feature->purge_adv_qos(restart => 0) or
          trace_warn("could not purge adv QoS on %s",
                     $self->{$role}->{name});

        # Switching to basic QoS has to be confirmed
        $adv_qos_feature->switch_to_basic_qos(confirm => 0) or
          trace_warn("Couldn't initiate " .
                     "switch to basic qos on %s",
                     $self->{$role}->{name});

        $adv_qos_feature->switch_to_basic_qos(confirm => 1) or
          trace_warn("Couldn't confirm " .
                     "switch to basic qos on %s",
                     $self->{$role}->{name});

        # Disable multi-core setup
        my $sdr = $self->{$role}->get_feature(name => 'SDR')
            or trap( "Couldn't get SDR feature on %s!",
                     $self->{$role}->{name} );
        $sdr->set_sdr_settings( multi_core_balance => 0 )
            or trace_warn( "Couldn't disable multi-core on %s!",
                           $self->{$role}->{name} );

        # Disable srdf blade
        my $srdf = $self->{$role}->get_feature(name => "SRDF") or
            trap( "Could not get SRDF feature on %s!",
                  $self->{$role}->{name} );
        if ( $srdf->disable( restart => 0 ) ) {
            trace_info ( "SRDF optimization is disabled on %s",
                         $self->{$role}->{name} );
        } else {
            trace_warn( "Couldn't disable SRDF optimization on %s!",
                        $self->{$role}->{name} );
        }

        # Restart sport and optionally clean the segstore
        $self->{$role}->
            write_and_restart( clean => ($params->{no_store_clean} ? 0 : 1) );
    }

    # Restore dummynet(s) to defaults
    if (@{$self->{dummynets}} != 0) {
        foreach my $dummynet (@{$self->{dummynets}}) {
            my $result = $dummynet->configure(
                        bandwidth => NBT::GRiTS::SRDF::DEFAULT_BANDWIDTH,
                        delay     => NBT::GRiTS::SRDF::DEFAULT_DELAY,
                        plr       => NBT::GRiTS::SRDF::DEFAULT_PLR,
                        queue     => NBT::GRiTS::SRDF::DEFAULT_QUEUE );
            unless ($result) {
                trace_warn("Unable to cleanup DummyNet(s).");
            }
        }
    } else {
        trace_warn("No DummyNets found in the allocation for cleanup.");
    }

    # Make sure we call our SUPER clean_up,
    # so it knows that we have cleaned up after ourselves.
    $self->SUPER::clean_up(@_);

    # Return from the clean_up() if no configfile restoration was requested
    if ( $params->{no_config_swap} ) {
        trace_warn( "Dirty config is purposefully left on Steelheads." );
        return 1;
    }

    # On both CFE and SFE restore the configuration to one saved in configure()
    # in order to reset TCP socket buffer sizes back to default.
    # Config swap consists of 4 steps and sport restart.
    for my $role (qw(cfe sfe)) {
        my $modelobj = $self->{$role}->get_model();

        # Step 1: Switch configuration to the one saved during configure()
        my $switch_init = $modelobj->config_switch( name => 'initial_config' );
        if ( $switch_init->{error} ) {
            trace_warn( "Couldn't switch to initial_config on %s.",
                        $self->{$role}->{name} );
        }

        # Step 2: Delete dirty 'working' configuration
        my $delete_working = $modelobj->config_delete( name => 'working' );
        if ( $delete_working->{error} ) {
            trace_warn( "Couldn't delete used working configuration on %s.",
                        $self->{$role}->{name} );
        }

        # Step 3: Copy current configuration to 'working'
        my $copy_init_config = $modelobj->config_write_to( name => 'working' );
        if ( $copy_init_config->{error} ) {
            trace_warn( "Couldn't copy initial_config to working on %s.",
                        $self->{$role}->{name} );
        }

        # Step 4: Delete the configuration saved during configure()
        my $del_init_config =
            $modelobj->config_delete( name => 'initial_config' );
        if ( $del_init_config->{error} ) {
            trace_warn( "Couldn't delete initial_config on %s.",
                        $self->{$role}->{name} );
        } else {
            trace_info( "Used working replaced with initial_config on %s.",
                        $self->{$role}->{name} );
        }

        $self->{$role}->restart();
    }

    return 1;
}

## Helper method preparing symmids from the existing servers' IP addresses
## and then using those symmids for adding up to 3 optimization policies
## to every Symmetrix array.
## Returns a reference to the hash of array references.
sub _config_symmids_opols {
    my $self = shift;

    my $if_name = 'test';
    my $filler = '000000'; # 6-digit string to bring $symmid to 10 digits,
                           # which is standard for Symmetrix array IDs

    my ( $srv_ip, $symmid, @symmids, @optim_policies, $last2, $pair,
        $srdfstt, $rdf_gr_count, $j );

    for my $role (qw(server1 server2)) {
        # Prepare a key for retrieving "pair_x" parameter from the YAML.
        $pair = "pair_" . substr( $role, -1  );
        
        # Obtain rdf group count for the c/s pair.
        $srdfstt = $self->{params}->{traffic_options}->{$pair}->{srdf_stt};
        if ( $srdfstt =~ /^\d{1,3}:(\d{1,3})/ ) {
            $rdf_gr_count = $1;
        } else {
            trace_warn( "Couldn't obtain rdf group count for %s in YAML",
                  $pair );
        }
        
        # Create a 10-digit symmid with first and last two digits
        # taken from the corresponding Symmetrix array's IP address.
        $srv_ip = $self->{$role}->interface(name => $if_name)->addr();
        $last2 = substr( $srv_ip, -2  );
        $symmid = $last2 . $filler . $last2;

        # Create an array of hashes for sending to add_symmids() method
        push ( @symmids,
               { id => $symmid,
               address => $srv_ip } );

        # Create an array of hashes for sending to add_optim_policies() method
        $j = 0;
        for my $opol (qw(none lz-only sdr-default)) {
            $j++;

            # Add three optimization policies if there are enough rdf groups
            if ( $rdf_gr_count >= $j ) {
                push ( @optim_policies,
                       { id => $symmid,
                       rdf_group => $j,
                       optimization => $opol } );
            } else {
                trace_warn ( "Tried to assign 3 optimization policies ".
                             " to %s rdf groups in %s ",
                             $rdf_gr_count, $pair );
                last;
            }
        }

        # rdfgr_per_symmid hash saved in $self object
        # for capturing how many rdf groups there are per symmid
        $self->{rdfgr_per_symmid}->{$symmid} = $rdf_gr_count;
    }

    return { symmids => \@symmids, opols => \@optim_policies };
}

=back

=cut

1;
