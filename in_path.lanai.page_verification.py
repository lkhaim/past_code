# $Id: page_verification.py 16885 2014-03-27 19:00:33Z lkhaimovich $
#

import re, logging, string
from nbt.ui.sh.configure.optimization.in_path.malta.page_verification \
    import PageVerification as Base

KICKOFF_INDEX = 10
KICKOFF_TRUE = "Yes"
KICKOFF_FALSE = "No"
KICKOFF_NONE = "--"

def translate_VLAN(vlan=None):
    if vlan is None:
        vlan = 'All'
    else:
        vlan = string.capitalize(str(vlan))
    return vlan


class PageVerification(Base):
    """
    Defines in-path page level verifications for Lanai
    """
    def __init__(self, test, appliance,
                 widgets=None, page=None):
        """
        Constructor

        @param test: instance of the test
        @param appliance: instance of appliance UI
        @param widgets: Widget.py that is common to the appliance
        @param page: page under test
        """
        #   TODO: Check if this really is correct. If we are given a page,
        #   we are going to clobber it? Huh?
        if widgets is None:
            widgets = appliance.get_widgets("configure.optimization.in_path")
        self.widgets = widgets
        Base.__init__(self, test, appliance, widgets=widgets, page=page)
    
    def expected_rule(self, number_of_rules=None, **kwords):
        """
        Generate expected state of in-path rule
        @param type_of_rule: type of rule could be Auto discovery, Passthrough,
                       discard or deny
        @param **kwords: The data dictionary
        """
        #   We just pass through the whole data distionary and let each
        #   method handle them as they see fit
        if kwords['type_of_rule'] == "Auto Discover":
            expected_row = self.expected_auto_discover_rule(
                number_of_rules=number_of_rules, **kwords)

        elif kwords['type_of_rule'] == "Fixed-Target":
            expected_row = self.expected_fixed_target_rule(
                number_of_rules=number_of_rules, **kwords)

        elif kwords['type_of_rule'] == "Pass Through":
            expected_row = self.expected_pass_through_rule(
                number_of_rules=number_of_rules, **kwords)

        elif kwords['type_of_rule'] == "Discard":
            expected_row = self.expected_discard_rule(
                number_of_rules=number_of_rules, **kwords)

        elif kwords['type_of_rule'] == "Deny":
            expected_row = self.expected_deny_rule(
                number_of_rules=number_of_rules, **kwords)

        else:
            self.log.info("Not a valid type")

        expected_data = []
        expected_data.append(expected_row)
        if 'description' in kwords:
            description_row = []
            description_row.append('Description: ' + kwords['description'])
            expected_data.append([description_row])

        return expected_data
    
    def __expected_rule_prefix(self,
                               type_of_rule,
                               position,
                               source_subnet='all-IPv4',
                               source_port='*',
                               destination_subnet='all-IPv4',
                               destination_port='*'):
        # Generate common elements for all the rules
        # type_of_rule       - type of rule could be Auto discovery,Passthrough,
        #                      discard or deny
        # position           - position of the rule
        # source_subnet      - source subnet
        # destination_subnet - destination subnet
        # destination_port   - destination port
        
        # Substituting 'all' and 'All' port names with '*', to simulate
        # the formatting performed by WebUI.
        patc = re.compile(r'\Aall\Z', re.IGNORECASE)
        m_source = patc.match(source_port)
        m_destination = patc.match(destination_port)
        if m_source:
            source_port = '*'
        if m_destination:
            destination_port = '*'

        source = str(source_subnet) + ':' + str(source_port)
        destination = str(destination_subnet) + ':' + str(destination_port)
        
        return [[str(position)], [type_of_rule], [source], [destination]]

    def expected_auto_discover_rule(self,
                                    number_of_rules=None,
                                    position=None,
                                    source_subnet='all-IPv4',
                                    source_port='*',
                                    destination_subnet='all-IPv4',
                                    destination_port='*',
                                    vlan_id=None,
                                    preoptimization_policy='None',
                                    optimization_policy='Normal',
                                    latency_optimization_policy='Normal',
                                    protocol='--',
                                    auto_kickoff=None,
                                    status='Enabled',
				    cloud_acceleration="Auto",
                                    **kwords):
        """
        Generate expected auto discover rule.

        @param number_of_rules: Number of rules in the table
        @param position: position of the rule
        @param source_subnet: source subnet
        @param source_port: source port
        @param destination_subnet: destination subnet
        @param destination_port: destination port
        @param vlan_id: VLAN tag id
        @param preoptimization_policy: policy could be None, JInitiator,
                                 JInitiator+SSL, SSL
        @param optimization_policy: policy could be None, SDR-Only,
                                     Compression-Only, Normal,
        @param latency_optimization_policy: policy could be None, HTTP, Normal
        @param protocol: the protocol used
        @param auto_kickoff: if it will auto start
        @param status: Whether enabled or not
        @param cloud_acceleration: cloud acceleration select option
        """
        if position is None:
            position = number_of_rules

        expected_row = self.__expected_rule_prefix(
            'Auto Discover', position, source_subnet, source_port,
            destination_subnet, destination_port)
         
        if optimization_policy == "Compression-Only":
            optimization_policy = "Compr-Only"

        if (auto_kickoff is not None and auto_kickoff):
		kickoff = "Yes"
	else:
		kickoff = "No"
	expected_row.extend([[translate_VLAN(vlan=vlan_id)],
                             [protocol],
                             [preoptimization_policy],
                             [latency_optimization_policy],
                             [optimization_policy],
                             [cloud_acceleration],
			     [kickoff],
                             [status]])
                         
        return expected_row

    def expected_fixed_target_rule(self,
                                   number_of_rules=None,
                                   position=None,
                                   source_subnet='all-IPv4',
                                   source_port='*',
                                   destination_subnet='all-IPv4',
                                   destination_port='*',
                                   vlan_id=None,
                                   preoptimization_policy='None',
                                   optimization_policy='Normal',
                                   latency_optimization_policy='Normal',
                                   protocol='--',
                                   auto_kickoff=None,
                                   status='Enabled',
				   cloud_acceleration=None,
                                   **kwords):
        """
        Generate expected fixed target rule

        @param number_of_rules: Number of rules in the table
        @param position: position of the rule
        @param protocol: The protocol
        @param source_subnet: source subnet
        @param source_port: source port
        @param destination_subnet: destination subnet
        @param destination_port: destination port
        @param vlan_id: VLAN tag id
        @param preoptimization_policy: policy could be None, JInitiator,
                                 JInitiator+SSL, SSL
        @param optimization_policy: policy could be None, SDR-Only,
        Compression-Only, Normal,
        @param latency_optimization_policy: policy could be None, HTTP, Normal,
        @param description: rule description
        @param auto_kickoff: Will it kick off or not
        @param status: Current status
        """
        if position is None:
            position = number_of_rules

        expected_row = self.__expected_rule_prefix(
            'Fixed-Target', position, source_subnet, source_port,
            destination_subnet, destination_port)
         
        if optimization_policy == "Compression-Only":
            optimization_policy = "Compr-Only"
	if (auto_kickoff is not None and auto_kickoff):
                kickoff = "Yes"
        else:
                kickoff = "No"
	cloud_acceleration = "--"
        expected_row.extend([[translate_VLAN(vlan=vlan_id)],
                             [protocol],
                             [preoptimization_policy],
                             [latency_optimization_policy],
                             [optimization_policy],
                             [cloud_acceleration],
                             [kickoff],
                             [status]])
	
        return expected_row

    def expected_pass_through_rule(self,
                                   number_of_rules=None,
                                   position=None,
                                   source_subnet='all-IPv4',
                                   source_port='*',
                                   destination_subnet='all-IPv4',
                                   destination_port='*',
                                   vlan_id=None,
                                   protocol='TCP',
                                   status='Enabled',
				   cloud_acceleration="Auto",
                                   **kwords):
        """
        Generate expected pass through rule

        @param number_of_rules: Number of rules in the table
        @param position: position of the rule
        @param source_subnet: source subnet
        @param source_port: source port
        @param destination_subnet: destination subnet
        @param destination_port: destination port
        @param vlan_id: VLAN tag id
        @param protocol: The protocol
        @param status: Current status
        @param cloud_acceleration: Cloud acceleration select option
        """
        if position is None:
            position = number_of_rules

        expected_row = self.__expected_rule_prefix(
            'Pass Through', position, source_subnet, source_port,
            destination_subnet, destination_port)
         
        preoptimization_policy = "--"
        optimization_policy = "--"
        latency_optimization_policy = "--"

        kickoff = '--'
        expected_row.extend([[translate_VLAN(vlan=vlan_id)],
                             [protocol],
                             [preoptimization_policy],
                             [latency_optimization_policy],
                             [optimization_policy],
                             [cloud_acceleration],
                             [kickoff],
                             [status]])

	
        return expected_row

    def expected_discard_rule(self,
                              number_of_rules=None,
                              position=None,
                              source_subnet='all-IPv4',
                              source_port='*',
                              destination_subnet='all-IPv4',
                              destination_port='*',
                              vlan_id=None,
                              protocol='--',
                              status='Enabled',
			      cloud_acceleration = None,
                              **kwords):
        """
        Generate expected discard rule

        @param number_of_rules: Number of rules in the table
        @param position: position of the rule
        @param source_subnet: source subnet
        @param source_port: source port
        @param destination_subnet: destination subnet
        @param destination_port: destination port
        @param vlan_id: VLAN tag id
        @param protocol: The protocol
        @param status: Current status
        """
        if position is None:
            position = number_of_rules

        expected_row = self.__expected_rule_prefix(
            'Discard', position, source_subnet, source_port,
            destination_subnet, destination_port)
         
        preoptimization_policy = "--"
        optimization_policy = "--"
        latency_optimization_policy = "--"
        kickoff = '--'
	cloud_acceleration = "--"
        expected_row.extend([[translate_VLAN(vlan=vlan_id)],
                             [protocol],
                             [preoptimization_policy],
                             [latency_optimization_policy],
                             [optimization_policy],
                             [cloud_acceleration],
                             [kickoff],
                             [status]])
        return expected_row
     
    def expected_deny_rule(self, type_of_rule=None, position=None,
                           source_subnet='all-IPv4',
                           destination_subnet='all-IPv4',
                           destination_port='*', vlan_id=None,
                           number_of_rules=None, protocol='--',
                           status='Enabled', source_port='*',
			   cloud_acceleration=None,
                           **kwords):
        """
        Generate expected deny rule

        @param number_of_rules: Number of rules in the table
        @param position: position of the rule
        @param source_subnet: source subnet
        @param source_port: source port
        @param destination_subnet: destination subnet
        @param destination_port: destination port
        @param vlan_id: VLAN tag id
        @param protocol: The protocol
        @param status: Current status
        """

        if position is None:
            position = number_of_rules

        expected_row = self.__expected_rule_prefix(
            'Deny', position, source_subnet, source_port,
            destination_subnet, destination_port)
         
        preoptimization_policy = "--"
        optimization_policy = "--"
        latency_optimization_policy = "--"
        kickoff = '--'
        cloud_acceleration = "--"
	expected_row.extend([[translate_VLAN(vlan=vlan_id)],
                             [protocol],
                             [preoptimization_policy],
                             [latency_optimization_policy],
                             [optimization_policy],
                             [cloud_acceleration],
                             [kickoff],
                             [status]])

        return expected_row
