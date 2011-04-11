ad_library {
    install routines for xolrn-excs
    
    @creation-date 2010-08-09
    @author Markus Moser
}

::xo::db::require package xowf
#::xo::db::require package xowiki
#::xo::db::require package xotcl-core

namespace eval ::xolrn_excs {
    ::xo::PackageMgr create ::xolrn_excs::Package \
        -package_key "xolrn_excs" -pretty_name "Lernfortschrittskontrolle neu" \
        -superclass ::xowf::Package -table_name "xolrn_excs"
	
		#user type checking
		ad_proc -private user_role {} {
		# check if user has admin privileges
		if { [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] } {
			return "admin"
		}
		# check if user has student privileges
		if { "student"==[dotlrn_community::get_user_role [dotlrn_community::get_community_id]] } {
			return "student"
		} else {
			return "member"
		}
	}

	ad_proc -public before-uninstall {} {
		xolrn_installer uninstall	
	}
	
	ad_proc -public after-install {} {
	ns_log notice "[xolrn_installer serialize]"
		xolrn_installer install
	}
	
	ad_proc -public mount_callback {
		-package_id:required
		-node_id:required
	} {
		xolrn_installer create_wf $package_id
		return 1
	}
	
	ad_proc -public create_wf {package_id} {
		xolrn_installer create_wf $package_id
	  }

}

Object xolrn_installer
xolrn_installer proc applet_key {} {
    return "xolrn_excs"
}

xolrn_installer proc my_package_key {} {
    return "xolrn_excs"
}

xolrn_installer ad_proc package_key {
} {
    What package do I deal with?
} {
    return "xolrn_excs"
}

xolrn_installer ad_proc node_name {
} {
    returns the node name
} {
    return "xolrn_excs"
}

xolrn_installer ad_proc pretty_name {
} {
    returns the pretty name
} {
    return "Lernfortschrittskontrolle neu"
}

xolrn_installer ad_proc add_applet {
} {
    One time init - must be repeatable!
 } {
  	ns_log notice "xolrn_excs:adding applet!"
  	if {![dotlrn::is_package_mounted -package_key [my package_key]]} {
  		set package_id [dotlrn::mount_package \
                              -url [my package_key] \
                              -package_key [my package_key] \
                              -pretty_name "Lernfortschrittskontrolle neu" \
                              -directory_p t \
                             ]
  		my create_wf $package_id
  		
          
  		dotlrn_applet::add_applet_to_dotlrn \
              -applet_key [my applet_key] \
              -package_key [my my_package_key]
  	}
}

xolrn_installer ad_proc remove_applet {
} {
    One time destroy. 
} {
    ad_return_complaint 1 "[my applet_key] remove_applet not implemented!"
}

xolrn_installer ad_proc add_applet_to_community {
    community_id
} {
    Add the xowiki applet to a specifc dotlrn community
} {
ns_log notice "xolrn:adding applet to community"
    # get the community portal id
    set portal_id [dotlrn_community::get_portal_id -community_id $community_id]
    
    # get applet id
    set applet_id [dotlrn_applet::get_applet_id_from_key -applet_key [my applet_key]]
    
    # create the package instance
    #set package_id [dotlrn::instantiate_and_mount -package_name [my pretty_name] $community_id [my package_key]]
    set package_id [dotlrn::instantiate_and_mount -mount_point [my node_name] $community_id [my package_key]]
    
	my create_wf $package_id
        #my add_portlet  $portal_id $package_id
	ns_log notice "mmo: adding applet to community pid $package_id"
	return $package_id
}


xolrn_installer ad_proc remove_applet_from_community {
    community_id
} {
    remove the applet from the community
} {
    # get package id
    set package_id [dotlrn_community::get_applet_package_id \
                        -community_id $community_id \
                        -applet_key [my applet_key]]
    # get portal id's
    set portal_id [dotlrn_community::get_portal_id -community_id $community_id]
    
    set applet_id [dotlrn_applet::get_applet_id_from_key -applet_key [my applet_key]]
    dotlrn::unmount_package -package_id $package_id
    #podcast_portlet::remove_self_from_page -portal_id $portal_id -package_id $package_id
    set url "[dotlrn_community::get_community_url $community_id][my node_name]/"
    # delete site node
    if { [site_node::exists_p -url $url] } {
        # get site node of mounted xowiki instance
        set node_id [site_node::get_node_id -url $url]
        # unmount package (deprecated, not necessary anymore)
	#site_node::unmount -node_id $node_id
        # delete site node
        site_node::delete -node_id $node_id
    }
}

xolrn_installer ad_proc add_user {
  user_id
} {
    one time user-specific init
} {
    # noop
}

xolrn_installer ad_proc remove_user {
    user_id
} {
} {
  ad_return_complaint 1 "[my applet_key] remove_user not implemented!"
}

xolrn_installer ad_proc add_user_to_community {
    community_id
    user_id
} {
    Add a user to a specifc dotlrn community
} {
    #nothing yet
}

xolrn_installer ad_proc remove_user_from_community {
    community_id
    user_id 
} {
    Remove a user from a community
} {
   #nothing yet
}

xolrn_installer ad_proc add_portlet {
    portal_id
    package_id
} {
    A helper proc to add the underlying portlet to the given portal. 
    
    @param portal_id
} {
   #nothing yet
}

xolrn_installer ad_proc remove_portlet {
    portal_id
    args
} {
    A helper proc to remove the underlying portlet from the given portal. 
    
    @param portal_id
    @param args A list of key-value pairs (possibly user_id, community_id, and more)
} { 
  #nothing yet
}

xolrn_installer ad_proc clone {
  old_community_id
  new_community_id
} {
  Clone this applet's content from the old community to the new one
} {
  #ns_log notice "Cloning: [my applet_key]"
  #set new_package_id [my add_applet_to_community $new_community_id]
  #set old_package_id [dotlrn_community::get_applet_package_id \
  #                        -community_id $old_community_id \
  #                        -applet_key [my applet_key] \
  #                   ]
  #db_exec_plsql clone_data {}
  #return $new_package_id
}

xolrn_installer ad_proc change_event_handler {
  community_id
  event
  old_value
  new_value
} { 
  listens for the following events: 
} { 
  #; nothing
}   

xolrn_installer proc install {} {
ns_log notice "xolrn:doing an install of xolrn_excs package"
   set name [my applet_key]
    db_transaction {
  
      # register the applet implementation
      ::xo::db::sql::acs_sc_impl new \
          -impl_contract_name "dotlrn_applet" -impl_name $name \
          -impl_pretty_name "" -impl_owner_name $name
  
      # add the operations
  
      foreach {operation call} {
        GetPrettyName 	        "xolrn_installer pretty_name"
        AddApplet                 "xolrn_installer add_applet"
        RemoveApplet              "xolrn_installer remove_applet"
        AddAppletToCommunity      "xolrn_installer add_applet_to_community"
        RemoveAppletFromCommunity "xolrn_installer remove_applet_from_community"
        AddUser                   "xolrn_installer add_user"
        RemoveUser                "xolrn_installer remove_user"
        AddUserToCommunity        "xolrn_installer add_user_to_community"
        RemoveUserFromCommunity   "xolrn_installer remove_user_from_community"
        AddPortlet                "xolrn_installer add_portlet"
        RemovePortlet             "xolrn_installer remove_portlet"
        Clone                     "xolrn_installer clone"
        ChangeEventHandler        "xolrn_installer change_event_handler"
      } {
        ::xo::db::sql::acs_sc_impl_alias new \
            -impl_contract_name "dotlrn_applet" -impl_name $name  \
            -impl_operation_name $operation -impl_alias $call \
            -impl_pl "TCL"
      }
  
      # Add the binding
      ::xo::db::sql::acs_sc_binding new \
          -contract_name "dotlrn_applet" -impl_name $name
  	
	my add_applet
  }
}

xolrn_installer proc uninstall {} {
  my log "--applet calling [self proc]"
  #
  # pretty similar "xowiki_portlet uninstall"
  #
  set name [my applet_key]

  db_transaction {
    # 
    # get the datasource
    #

    set ds_id [db_string dbqd..get_ds_id {
      select datasource_id from portal_datasources where name = :name
    } -default "0"]
    
    if {$ds_id == 0} {
      ns_log notice "No datasource id found for $name"
    } else {
      #
      # drop the datasource
      #
      ::xo::db::sql::portal_datasource delete -datasource_id $ds_id
    }
    #
    #  drop the operation
    #
    foreach operation {
      GetPrettyName
      AddApplet
      RemoveApplet
      AddAppletToCommunity
      RemoveAppletFromCommunity
      AddUser
      RemoveUser
      AddUserToCommunity
      RemoveUserFromCommunity
      AddPortlet
      RemovePortlet
      Clone
    } {
      ::xo::db::sql::acs_sc_impl_alias delete \
          -impl_contract_name "dotlrn_applet" -impl_name $name \
          -impl_operation_name $operation
    }
    #
    #  drop the binding
    #
    ::xo::db::sql::acs_sc_binding delete \
        -contract_name "dotlrn_applet" -impl_name $name

    #
    #  drop the implementation
    #
    ::xo::db::sql::acs_sc_impl delete \
        -impl_contract_name "dotlrn_applet" -impl_name $name 
  }
  my log "--applet end of [self proc]"
}

xolrn_installer ad_proc create_wf {package_id} {
	create all the necessary objects in a package
} {
	ns_log notice "xolrn: creating form objects"
	::xowf::Package initialize -package_id $package_id
	set folder_id [$package_id folder_id]
    
    	::xowiki::Form create workflow -noinit \
  		-set text {{<p> @workflow_definition@
              </p>
              <p>Form Constraints: @form_constraints@</p>} text/html} \
  		-set package_id $package_id \
  		-set name workflow \
  		-set title Workflow \
  		-set publish_status ready \
  		-set form_constraints {workflow_definition:workflow_definition
              form_constraints:form_constraints} \
  		-set parent_id $folder_id
		
  	set workflow_form_id [workflow save_new]
 
    #section form
    ::xowiki::Form create section.form -noinit \
	-set anon_instances f \
	-set form {} \
	-package_id $package_id \
	-set text {{{{set-parameter __no_footer 1}}
	@_name@
@_title@
@_creator@
@_text@
@exam@
} text/html} \
	-set name section.form \
	-set title "#xolrn_excs.section#" \
	-set publish_status ready \
	-set form_constraints {_text:label=#xolrn_excs.exercise-text#
_page_order:omit 
_name:required
_title:required
_description:omit 
_nls_language:omit
exam:resource_selector_ff,label=#xolrn_excs.assignment-selector#} \
	-set parent_id $folder_id

section.form save_new

#edit workflow
::xowiki::FormPage create wf-form-edit -noinit \
	-set instance_attributes {return_url {} form_constraints {@table:_name,_state,_creator,_last_modified
_title:label=#xolrn_excs.visiblename#
_name:label=#xolrn_excs.name#} workflow_definition {set debug 0

Action edit_start -next_state editing -label "Frage anlegen"

Action edit_done -next_state edited -label "Editieren abschließen" -proc activate {obj} {
#we are redirecting to the parent folder
set parent_folder [::xo::db::CrClass get_instance_from_db -item_id [$obj set parent_id]]
ad_returnredirect [[$obj set package_id] pretty_link -parent_id [$parent_folder set parent_id] [$parent_folder set name]]
}

Action save -label "Speichern"
Action change-type -next_state initial -label "Fragentyp ändern"

State parameter [list {view_method view} [list form [my property form]]]

State initial -view_method edit -form_loader edit_initialform -actions {edit_start}

State editing -view_method edit -actions {change-type save edit_done} -form_loader edit_testitemform -proc form args {
#my msg [my property exercise_form]
   return [my property exercise_form]
}
State edited -actions {change-type save} -form_loader edit_testitemform -proc form args {
   return [my property exercise_form]
}}} \
	-set text {} \
	-set package_id $package_id \
	-set page_template $workflow_form_id \
	-set name wf-form-edit \
	-set title {Edit Workflow for Exercises} \
	-set publish_status ready \
	-set parent_id $folder_id
	
wf-form-edit save_new

#opentext-cf wf
::xowiki::FormPage create wf-opentext-cf -noinit \
	-set instance_attributes {return_url {} form_constraints _title:label=\"Freitextaufgabe\" workflow_definition {set debug 0

Property rating -default f
Property fetched_item_ids -default 0
Property answerstorate -default 3

Action allocate -proc activate {obj} {
  # Called, when we try to create or use a workflow instance
  # via a workflow definition ($obj is a workflow definition)
  #regexp {.*/(.*)$} [$obj query_parameter p.form] match exercise
  set exercise [::xo::db::CrClass get_instance_from_db -item_id [$obj query_parameter p.form]]
  #my set_new_property name ${exercise}___[::xo::cc set untrusted_user_id]
  my set_new_property name [$exercise set name]___[::xo::cc set untrusted_user_id]
  my set_new_property title "Freitextaufgabe"
}

Action initialize -proc activate {obj} {
  set ctx [my info parent]
  set form_object [$ctx form_object $obj]
  if {[$form_object exists title]} {
    $obj title [$form_object title]
}
if {[$obj get_property -name init_done] ne 1} {
  set items [$obj get_answers]
  #rating wird nur erlaubt wenn es mehr als 3 abgegebene Antworten gibt
  set rating_required [expr {[llength [$items children]] >= 3}]
  $obj set_property -new 1 rating $rating_required
  [my info parent] set_property -new 1 bvar 0.5
 $obj set_property -new 1 init_done 1
}
}

Condition rating_needed -expr {[$obj get_property -name rating]}

Action submit -next_state {? rating_needed do_rating else closed} -proc activate {obj} {
  my set_property -new 1 creator_id [::xo::cc set user_id]
  my set_property -new 1 username [acs_user::get_element -element username]
  if {[my rating_needed]} {
    set items [[$obj get_answers] children]

   #shuffle list
    for {set i 1} {$i <[llength $items]} {incr i} {
      set j [expr {int(rand()*[llength $items])}]
      set tmp [lindex $items $i]
      lset items $i [lindex $items $j]
      lset items $j $tmp
    }

    set j 0
    foreach i $items {
      array set item_ia [$i instance_attributes]
      my set_property -new 1 rateitem[incr j] $item_ia(answer)
      lappend fetched_item_ids [$i item_id]
      lappend fetched_item_names [$i set name]
      array unset item_ia
      if {$j > 2} {break}
    }
    
    #ensure that at least one sample answer is fetched
    regexp {(.*___).*} [$obj set name] match shortitemname
    set sampleitempos [lsearch $fetched_item_names ${shortitemname}?]
    if {$sampleitempos == -1} {
      #we have no sample item, retrieve the first, if one exists
      foreach i $items {
        if {[string match ${shortitemname}? [$i set name]]} {
            $obj set_property -new 1 rateitem0 [$i item_id]
	   ns_log notice "xolrn_cf: old: $fetched_item_ids - replacing [lindex $fetched_item_ids 0] with [$i item_id]"
           set fetched_item_ids [lreplace $fetched_item_ids 0 0 [$i item_id]]
           break  
	}
     }
    }
    
    my set_property -new 1 your_answer [my property answer]
    my set_property -new 1 fetched_item_ids $fetched_item_ids
    util_user_message -html -message "<font color='red'>Please rate!</font>"
  } else {
    util_user_message -message "Thank you!"
  }
}

Action rate -next_state {closed} -proc activate {obj} {
  set item_ids [$obj get_property -name fetched_item_ids]
  foreach id $item_ids {
    catch {lappend items [::xo::db::CrClass get_instance_from_db -item_id $id]}
  }
  $obj calc_basevalues $items
  $obj set_property bvar [$obj get_property -name qvar]
  util_user_message -message "Thank you!"
}

State parameter [list {view_method edit} [list form [my property form]]]

State initial   -actions {submit} -form_loader wf_form

State do_rating     -actions {rate} -form_loader ot_ratingform

State closed    -view_method view_user_input_with_feedback -form_loader wf_form}} \
	-set text {} \
	-set page_template $workflow_form_id \
	-set package_id $package_id \
	-set name wf-opentext-cf \
	-set title {Opentext Exercise} \
	-set publish_status ready \
	-set parent_id $folder_id 
	
wf-opentext-cf save_new

#assignment form
::xowiki::Form create assignment.form -noinit \
	-set form {} \
	-set text {{{{set-parameter __no_footer 1}}
	<table>
<tbody>
<tr>
<td>@typ@</td>
</tr>
<tr>
<td>@time_from@</td>
<td>@time_to@</td>
</tr>
<tr>
<td>@progress_constraint@</td>
</tr>
<tr>
<td>@selector@</td>
<td>@content@</td>
</tr>
<tr>
<td><br></td>
</tr>
</tbody>
</table>
<div style="clear: right;" id="left">
<p>{{xofolders}}</p>
<p><br></p>
</div>
<div id="content">
<p>{{child_resources_light}}</p>
</div>
} text/html} \
	-set package_id $package_id \
	-set name assignment.form \
	-set title "#xolrn_excs.assignment#" \
	-set publish_status ready \
	-set form_constraints {{typ:select,options={#xolrn_excs.exercises# exercise},label=Typ,default=exercise,hide_value=1}
{availability:select,options={none none} {time_based time_based} {progress_based progress_based},label=Zugriffsbeschränkung,default=none,hide_value=1}
_page_order:hidden
_nls_language:omit
_creator:hidden
_description:hidden
_title:required,label=#xolrn_excs.visiblename#
_name:required,label=#xolrn_excs.name#
selector:assignment_selector_ff,label=#xolrn_excs.assignment-selector-select#
content:textarea,CSSclass=selection,hide_value=1,hidden
progress_constraint:requirement_selector,label=#xolrn_excs.requirement#,CSSclass=selectiondd,hide_value=1
"time_from:date,format=DD_MONTH_YYYY_HH24_MI,label=#xolrn_excs.available-from#,hide_value=1"
"time_to:date,format=DD_MONTH_YYYY_HH24_MI,label=#xolrn_excs.available-until#,hide_value=1"} \
	-set parent_id $folder_id

set assignment_form_id [assignment.form save_new]


::xowiki::FormPage create assignments -noinit \
	-set anon_instances f \
	-set form {} \
	-set text {} \
	-set package_id $package_id \
	-set name assignments \
	-set page_template $assignment_form_id \
	-set title {Assignments} \
	-set publish_status ready \
	-set form_constraints _nls_language:omit \
	-set parent_id $folder_id

assignments save_new


#exercise form
::xowiki::Form create exercise.form -noinit \
	-set anon_instances f \
	-set form {} \
	-set text {{{{set-parameter __no_footer 1}}<br><div id="left1">{{xofolders}}</div><div id="center1">{{child_resources_light}}</div><div id="view_wf"></div>} text/html} \
	-set package_id $package_id \
	-set name exercise.form \
	-set title "#xolrn_excs.folder#" \
	-set publish_status ready \
	-set form_constraints {
	_nls_language:omit
	_section:hidden
	_description:hidden
	_name:required,label=#xolrn_excs.name#
	_title:required,label=#xolrn_excs.visiblename#
	_creator:hidden
	_page_order:hidden
	} \
	-set parent_id $folder_id

set exercise_form_id [exercise.form save_new]

::xowiki::FormPage create exercises -noinit \
	-set anon_instances f \
	-set form {} \
	-set text {} \
	-set package_id $package_id \
	-set name exercises \
	-set page_template $exercise_form_id \
	-set title {Exercise Folder} \
	-set publish_status ready \
	-set form_constraints _nls_language:omit \
	-set parent_id $folder_id

exercises save_new
#simple qti wf

::xowiki::FormPage create wf-simple-qti -noinit \
	-set instance_attributes {return_url {} form_constraints {@table:_name,_state,_creator,_last_modified
_title:label=Beispiel} workflow_definition {set debug 0
Property isexercise -default 1

Action allocate -proc activate {obj} {
#  Called, when we try to create or use a workflow instance
  # via a workflow definition ($obj is a workflow definition)
  #
  #p.form is a parameter sent in the url
  set exercise [$obj query_parameter p.form]
  set shortname [$obj set title]
  set exercise [::xo::db::CrClass get_instance_from_db -item_id [$obj query_parameter p.form]]
  #regexp {.*/(.*)$} $exercise _ shortname
  #my set_new_property name ${shortname}___[::xo::cc set untrusted_user_id]
   my set_new_property name [$exercise set name]___[::xo::cc set untrusted_user_id]

}

Action initialize -proc activate {obj} {
  # called, after workflow instance was created
  set ctx [my info parent]
  set form_object [$ctx form_object $obj]
  if {[$form_object exists title]} {
    $obj title [$form_object title]
  }
}

#Property form -default qti-sample -allow_query_parameter true

Condition answer_ok   -expr {[$obj answer_is_correct] == 1}

Action submit -next_state {? answer_ok closed else submitted} -label Überprüfen -proc activate {obj} {
#my msg "~~correct?? [$obj answer_is_correct]~~"
  set attempts [$obj get_property -name attempts -default 0]

  $obj set_property -new 1 attempts [incr attempts]
  if {[my answer_ok]} {
    util_user_message -message "Correct!"
  } else {
    util_user_message -html -message "<font color='red'>Wrong! Try again.</font>"
  }
  set nroftries [$obj get_property -name nr_of_tries]
  set gltries [[my info parent] get_property -name global_nr_of_tries -default 1]
  [my info parent] set_property -new 1 global_nr_of_tries $gltries
  set act_score [$obj calculate_score]
  $obj set_property -new 1 score $act_score
  set result_name result_[auth::get_user_id]_[clock seconds]
  set template_obj [$obj get_property -name form_id]
  #util_user_message -message "obj template object: $template_obj - result_name: $result_name"
  $template_obj set_property -new 1 $result_name $act_score
  set s [$template_obj find_slot instance_attributes]
  $template_obj update_attribute_from_slot $s [$template_obj instance_attributes]
}


Action redo -next_state initial -proc activate {obj} {
  $obj set_property -new 1 attempts 0
  $obj set_property -new 1 score -1
  $obj set_property -new 1 adaptive_score -1
  $obj set_property -new 1 shuffled_order ""
  set nrtries [$obj get_property -name nr_of_tries -default 0]
  $obj set_property -new 1 nr_of_tries [incr nrtries]
  $obj clear_form_selections

set gltries [[my info parent] get_property -name global_nr_of_tries -default 1]
  [my info parent] set_property -new 1 global_nr_of_tries [incr gltries]
  if {$nrtries ne ""} {
    util_user_message -message "Sie haben diese Fragen schon $nrtries mal beantwortet"
    }
}

State parameter [list {view_method edit} [list form [my property form]]]

State initial   -actions {submit} -form_loader wf_form
State closed    -actions {redo} -view_method view_user_input_with_feedback -form_loader wf_form
State submitted -actions {submit} -view_method view_user_input_with_partial_feedback -form_loader wf_form

my proc check_answer {} {
  if {[$obj answer_checking_needed]} {
   return [$obj answer_is_correct]
  } else {
   #always right if no answer exists
   return 1
  }

}}} \
	-set text {} \
	-set page_template $workflow_form_id \
	-set package_id $package_id \
	-set name wf-simple-qti \
	-set title {Exercise Workflow} \
	-set publish_status ready \
	-set parent_id $folder_id

wf-simple-qti save_new

#exam wf

::xowiki::FormPage create wf-exam -noinit \
	-set instance_attributes {workflow_definition {set debug 0

#set view [ad_get_client_property module currentexam]
#Property itemlist -default [ad_get_client_property module ${view}_itemlist]
Property current_form -default ""
Property position -default 2
Property isexam -default 1
Property started -default 0
Property starttime -default ""

Action allocate -proc activate {obj} {
  my set_new_property name [$obj set name]___[xo::cc set untrusted_user_id]
}

Action initialize -proc activate {obj} {
my msg "itemlist! [$obj get_property -name itemlist]"
if {[$obj get_property -name itemlist] eq ""} {
 set assignment [::xo::db::CrClass get_instance_from_db -item_id [$obj get_property -name a]]
 foreach item [$assignment get_property -name content] {
 lappend itemlist $item ""
}
my msg $itemlist
$obj set_property -new 1 itemlist $itemlist
}
}

Condition more_questions -expr {[clock seconds] < [expr {[my property starttime]+3600}]}

Action start -next_state submitted -proc activate {obj} {
        #set view [ad_get_client_property module currentexam]
        #set itemlist [ad_get_client_property module ${view}_itemlist]
        set itemlist [$obj get_property -name itemlist]
        #my set_property itemlist $itemlist
        my set_property current_form [lindex $itemlist 2]
        my set_property started 1
        my set_property starttime [clock seconds]
        #ad_set_client_property module ${view}_started 1
}

Action calc_results -label "Abgeben" -next_state {corrected} -proc activate {obj} {
        my set_property started 0

        #calculate score, necessary if called from an item
        set itemscore [$obj calculate_score]
        $obj clear_form_selections

        set items [my property itemlist]
        foreach {form score} $items {
          if {[my property current_form] eq $form} {
         lappend newitemlist $form $itemscore
          } else {
         lappend newitemlist $form $score
         }
        }
        my set_property itemlist $newitemlist


        #calculate results
        set totalscore 0
        set elements 0
        foreach {item score} [my property itemlist] {
          if {[string match *genericexamform $item]} continue
          #unsubmitted questions have "" as score
          if {$score eq ""} {set score 0}
          set totalscore [expr {$totalscore+$score}]
          incr elements
        }
        set result [expr {$totalscore/$elements}]
        my set_new_property results_[clock seconds] $result
        #set view [ad_get_client_property module currentexam]
        my set_property -new 1 completed 1
        my set_property started 0 
        #ad_set_client_property module ${view}_completed 1
        #ad_set_client_property module ${view}_started 0
}


Action previous -next_state {submitted} -label vorige -proc activate {obj} {

        #calculate score
        set itemscore [$obj calculate_score]
        $obj clear_form_selections

        set items [my property itemlist]
        foreach {form score} $items {
          if {[my property current_form] eq $form} {
         lappend newitemlist $form $itemscore
          } else {
         lappend newitemlist $form $score
         }
        }
        my set_property itemlist $newitemlist

        if {[expr {[my property position]-2}] > 0} {
        my set_property current_form [lindex $items [expr {[my property position]-2}]]
        my set_property position [expr {[my property position]-2}]
        if {[my property current_form] eq ""} {
          my set_property current_form "genericexamform"
        }
        }
}

Action restart -next_state {initial} -label "erneut starten" -proc activate {obj} {
#remove old score
#delete formfield values and score from ia
        foreach {ia value} [$obj set instance_attributes] {
                if {[string match itemlist $ia]} {
                        #reiterate itemlist, remove score
                        foreach {item score} $value {
                        lappend newvalue "$item" ""
                        }
                        my set_property $ia $newvalue
                } elseif {![string match *___* $ia]} {
                        my set_property $ia $value
                } else {
                                my set_property $ia ""
                }
        }
        my set_property started 0
        my set_property position 2
        my set_property -new 1 completed 0
        #set view [ad_get_client_property module currentexam]
        #ad_set_client_property module ${view}_completed 0
}

Action submit -next_state {? more_questions submitted else done} -label nächste -proc activate {obj} {

        #calculate score
        set itemscore [$obj calculate_score]
        $obj clear_form_selections

        set items [my property itemlist]
        foreach {form score} $items {
          if {[my property current_form] eq $form} {
         lappend newitemlist $form $itemscore
          } else {
         lappend newitemlist $form $score
         }
        }
        my set_property itemlist $newitemlist
        if {[my property position] < [llength [my property itemlist]]} {
        my set_property current_form [lindex $items [expr {[my property position]+2}]]
        my set_property position [expr {[my property position]+2}]

        if {[my property current_form] eq ""} {
          my set_property current_form "genericexamform"
        }
        }

}

State parameter {{view_method view_exam_question}}

#allow jumps
if {[::xo::cc query_parameter jumpto] ne "" && [my property current_form] ne ""} {
if {[my property current_form] ne [::xo::cc query_parameter jumpto]} {
my set_new_property current_form [::xo::cc query_parameter jumpto]
set itemlist [my property itemlist]
set pos [lsearch $itemlist [my property current_form]]
my set_new_property position $pos
}
}

State corrected -actions {restart} -form [my property current_form] -view_method view_exam_question -form_loader renameff
State done -form [my property current_form] -view_method view_exam_question -actions {calc_results} -form_loader renameff
State initial   -actions {start} -form  genericexamform
State submitted -actions {previous submit calc_results} -view_method view_exam_question -form_loader renameff

set form [my property current_form]} form_constraints {@table:_name,_state,_creator,_last_modified
_title:hidden
_name:hidden
_page_order:hidden
_creator:hidden
_description:hidden
_nls_language:omit}} \
	-set text {} \
	-set page_template $workflow_form_id \
	-set package_id $package_id \
	-set name wf-exam \
	-set title {Exam Workflow} \
	-set publish_status ready \
	-set parent_id $folder_id 

wf-exam save_new

#exam overview page
::xowiki::Form create genericexampage -noinit \
	-set anon_instances f \
	-set form {} \
	-set text {{{set-parameter __no_footer 1}}@folderstruct@ @genericexamform@ text/html} \
	-set package_id $package_id \
	-set name genericexamform \
	-set title {Exercise Folder} \
	-set publish_status ready \
	-set form_constraints {genericexamform:genericexampage,label=
	folderstruct:folderstruct
	} \
	-set parent_id $folder_id

genericexampage save_new

	ns_log notice "xolrn_installer: all done"
}

::xowiki::FormPage instproc wpr_excs_xml_export {} {
    #test export proc for günter tiefenbacher for wpr
    
    array set excs_ia [my instance_attributes]
    dom parse "<learning_resources></learning_resources>" document
    $document documentElement root
    set exercise_node [$document createElement exercise]
    $exercise_node setAttribute area ""
    $exercise_node setAttribute restype excs
    $exercise_node setAttribute shortname [lindex [array get excs_ia shortname] 1]
    $root appendChild $exercise_node
    $exercise_node appendXML "<metadata><title>[[$document createTextNode [my title]] asXML]</title></metadata>"
    
    set question_node [$document createElement question_data]
    $exercise_node appendChild $question_node
    set multiplechoice_node [$document createElement multiplechoice]
    $question_node appendChild $multiplechoice_node
    set angabe [lindex [array get excs_ia angabe] 1]
    $multiplechoice_node appendXML "<problem_text>[[$document createTextNode $angabe] asXML]</problem_text>"
    for {set i 1} {$i <= 5} {incr i} {
        set text_value [lindex [array get excs_ia alt${i}] 1]
        if {[lindex [array get excs_ia chk${i}] 1]} {
            $multiplechoice_node appendXML "<answer value='true'><answer_text>[[$document createTextNode $text_value] asXML]</answer_text></answer>"
        } else {
            $multiplechoice_node appendXML "<answer value='false'><answer_text>[[$document createTextNode $text_value] asXML]</answer_text></answer>"
        }
    }
    ns_return 200 text/xml [$root asXML]
}
