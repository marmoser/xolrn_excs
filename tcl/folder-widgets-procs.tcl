::xo::library doc {
 This provides two includelets for the xolrn project, based on the folder-procs of xowiki
}

#::xo::db::require package xowiki
#::xo::library require -package xowiki  xowiki-procs
::xo::library require -package xowiki includelet-procs


namespace eval ::xowiki::includelet {
  ###########################################################
  #
  # ::xowiki::includelet::xofolders
  #
  ###########################################################
  ::xowiki::IncludeletClass create xofolders \
      -superclass ::xowiki::Includelet \
      -cacheable false \
      -parameter {
        {__decoration plain}
        {parameter_declaration {
          {-show_full_tree true}
        }}
        {id "[xowiki::Includelet js_name [self]]"}
        {folder_form_name exercise.form}
	{assignment_form_name assignment.form}
	{root_form exercises}
      }

  xofolders instproc include_head_entries {} {
    ::xowiki::Tree include_head_entries -renderer yuitree -style folders
  }

  xofolders instproc render {} {
     my instvar show_full_tree
    my get_parameters
    set js "
      var [my js_name];
      YAHOO.util.Event.onDOMReady(function() {
         [my js_name] = new YAHOO.widget.TreeView('foldertree_[my id]'); 
         [my js_name].subscribe('clickEvent',function(oArgs) { 
            var m = /href=\"(\[^\"\]+)\"/.exec(oArgs.node.html);
            return false;
          });
         [my js_name].render();
      });
     "
    return [[my build_tree] render -style yuitree -js $js]
  }

xofolders instproc build_tree {} {
    #my get_parameters
    my instvar current_folder current_folder_id __including_page show_full_tree package_id assignment_form_name root_form
    set current_folder $__including_page
    set current_folder_id [$current_folder item_id]

    set folder_form [string trimleft [$package_id resolve_page_name [my folder_form_name]] ::]
    set assignment_form [string trimleft [$package_id resolve_page_name [my assignment_form_name]] ::]
    set root_folder_name "#xolrn_excs.exercises#"
    
    if {[$__including_page set page_template] eq $folder_form} {
    set useform [my folder_form_name]
    } elseif {[$__including_page set page_template] eq $assignment_form} {
    set root_form "assignments"
    set root_folder_name "#xolrn_excs.assignments#"
    set useform [my assignment_form_name]
    } else {
     #if we have a question opened that is called from an assignment, we use this property to determine to which assignment it belongs
     set a [$__including_page property a]
     if {$a ne ""} {
        set root_form "assignments"
	set root_folder_name "#xolrn_excs.assignments#"
	set useform [my assignment_form_name]
     } else {
	   set useform [my folder_form_name]
     }
    }
    
      set root_folder [$package_id  resolve_page_name $root_form]
      set root_folder_id [$root_folder set item_id]
      set root_folder_href [::$package_id pretty_link $root_form]

    set current_folder_id [$current_folder item_id]
    set is_current [expr {$current_folder_id eq [$root_folder item_id]}]
    set is_open [expr {$is_current || $show_full_tree}]
    
    my set folder_form_id [::xowiki::Weblog instantiate_forms \
                               -forms $useform \
                               -package_id $package_id]

    # TODO There is also a wrapping DIV that has the same id...
    set t [::xowiki::Tree new -id foldertree_[my id] ]
    set node [::xowiki::TreeNode new \
                -href $root_folder_href \
                -label $root_folder_name \
                -highlight $is_current \
                -object $root_folder \
                -expanded $is_open \
                -open_requests 1]
    $t add $node
    my build_sub_tree -node $node
    
    #always draw both types and their nodes
    if {[permission::permission_p -object_id $package_id -privilege "admin"] && $root_form eq "assignments"} {
	#draw exercises node
	set root_folder [$package_id  resolve_page_name "exercises"]
	set exnode [::xowiki::TreeNode new \
                -href [::$package_id pretty_link "exercises"] \
                -label #xolrn_excs.exercises# \
                -highlight $is_current \
                -object $root_folder \
                -expanded 0 \
                -open_requests 1]
    $t add $exnode
    
        my set folder_form_id [::xowiki::Weblog instantiate_forms \
                               -forms [my folder_form_name] \
                               -package_id $package_id]
    
    my build_sub_tree -node $exnode
    } elseif {[permission::permission_p -object_id $package_id -privilege "admin"] && $root_form eq "exercises"} {
    
	#draw exercises node
	set root_folder [$package_id  resolve_page_name "assignments"]
	set exnode [::xowiki::TreeNode new \
                -href [::$package_id pretty_link "assignments"] \
                -label #xolrn_excs.assignments# \
                -highlight $is_current \
                -object $root_folder \
                -expanded 0 \
                -open_requests 1]
    $t add $exnode
    
        my set folder_form_id [::xowiki::Weblog instantiate_forms \
                               -forms [my assignment_form_name] \
                               -package_id $package_id]
    
    my build_sub_tree -node $exnode
    
    }
    
    
    return $t
  }

 xofolders instproc build_sub_tree {
    {-node}
  } {
    my instvar current_folder_id package_id show_full_tree

    set current_object [$node object]
    set folder_pages [::xowiki::FormPage get_form_entries \
                          -parent_id [$current_object item_id] \
                          -base_item_ids [my set folder_form_id] -form_fields "" \
                          -publish_status ready -package_id $package_id]
    eval lappend folders [$folder_pages children]
    foreach c $folders {
      set is_current [expr {$current_folder_id eq [$c item_id]}]
      set is_open [expr {$is_current || $show_full_tree}]
      set label [$c title]
      set subnode [::xowiki::TreeNode new \
                       -href "[::$package_id pretty_link -parent_id [$c parent_id] [$c name]]" \
                       -label $label \
                       -object $c \
                       -highlight $is_current \
                       -expanded $is_open \
                       -open_requests 1]
      $node add $subnode
      my build_sub_tree -node $subnode
    }
  }
}

namespace eval ::xowiki::includelet {
  ###########################################################
  #
  # ::xowiki::includelet::child_resources_light
  #
  ###########################################################
  ::xowiki::IncludeletClass create child_resources_light \
      -superclass ::xowiki::Includelet \
      -parameter {
        {
          parameter_declaration {
            {-skin:optional "yui-skin-sam"}
            {-folder_id:optional false}
            {-show_types:optional "::xowiki::Page,::xowiki::File,::xowiki::FormPage"}
            {-regexp:optional}
            {-with_subtypes:optional false}
            {-with_children:optional false}
            {-orderby:optional "title,desc"}
            {-view_target:optional "inwindow"}
	    {-folder "exercise.form"}
	    {-assignment "assignment.form"}
          }
        }
      }
  
  child_resources_light instproc initialize {} {
    #init parameters here because get_parameters does not work on formfields
    #note that only skin is currently required
    my instvar skin folder assignment
    my get_parameters
  }
  
  child_resources_light instproc types_to_show {} {
    my get_parameters
    foreach type [split $show_types ,] {set ($type) 1}
    return [lsort [array names ""]]
  }

  child_resources_light instproc render {} {
    #my get_parameters	  
    my instvar __caller_parameters queryparm __decoration parameter_declaration  actual_query package_id skin folder assignment __including_page
    ::xo::Page requireCSS "/resources/xolrn_excs/xolrn.css"
    set folder_form [string trimleft [$package_id resolve_page_name folder.form] ::]  
    set pt [::xo::db::CrClass get_instance_from_db -item_id [$folder_form parent_id]]
    set amiadmin [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"] 
    set foldercontent [list]
    $package_id instvar package_key
    set page $__including_page
    set genericexamform [string trimleft [$package_id resolve_page_name genericexamform] ::]

    if {[$page istype ::xowiki::FormPage]} {
        #my msg "$page is FormPage"      
	set folder_form [::xowiki::Weblog instantiate_forms -forms $folder \
	-package_id $package_id]
        set assignment_form [::xowiki::Weblog instantiate_forms -forms $assignment \
	-package_id $package_id]
	set pt [$page set page_template]
	if {$pt eq $folder_form} {
	  set current_folder_id [string trimleft $page ::]
	} elseif {$pt eq $assignment_form} {
	   set current_folder_id [$page item_id]
	} else {
	 set a [$page property a]
	  if {$a ne ""} {
	  #if we are working on an assignment, we set it the current including_page
            set page [::xo::db::CrClass get_instance_from_db -item_id $a]
	  } else {
	  array set ipage_ia [$page set instance_attributes]
          set current_folder_id [string trimleft $ipage_ia(folder_id) ::]
	  array unset ipage_ia
     }
	}
    } else {
        # we assume it is the index page (from prototype page) of a folder (fallback)
        set current_folder [::xo::db::CrFolder get_instance_from_db -item_id [$page parent_id]]
	set current_folder_id [$current_folder item_id]
    }


    #add items to menubar
    set mb [info command ::__xowiki__MenuBar]
    if {$mb ne "" && [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"]} {
    #new exercise
    set editwf [$package_id pretty_link wf-form-edit]
    $mb clear_menu -menu New
    $mb clear_menu -menu Package

    $mb add_menu_item -name New.Exercise \
          -item [list text #xolrn_excs.exercise# url "$editwf?m=create-new&parent_id=[$page item_id]"]
	
     #new section
     set sectionlink [$package_id pretty_link section.form]?m=create-new&p.str_id=[$package_id set folder_id]&parent_id=[$page set item_id]&return_url=[::xo::cc url]
    $mb add_menu_item -name New.Section \
	-item [list text "#xolrn_excs.section#" url $sectionlink]
	
      #new assignment
      set assignment_root [$package_id resolve_page_name assignments]
     $mb add_menu -name Assignment
     if {$pt eq $assignment_form} {
     $mb add_menu_item -name Assignment.New \
	   -item [list text New url "[$package_id package_url]assignment.form?m=create-new&parent_id=[$page item_id]"]
	   } else {
     $mb add_menu_item -name Assignment.New \
	   -item [list text New url "[$package_id package_url]assignment.form?m=create-new&parent_id=[$assignment_root item_id]"]
	   }
     	
      $mb add_menu_item -name New.ExerciseFolder \
	   -item [list text "#xolrn_excs.folder#" url "[$package_id package_url]exercise.form?m=create-new&parent_id=[$page item_id]"]	
	  }

    set return_url [::xo::cc url] ;#"[$package_id package_url]edit-done"
    set category_url [export_vars -base [$package_id package_url] { {manage-categories 1} {object_id $package_id}}]

    # TODO: Rename YUI::Anchorfield to YUI::DataTable::Anchorfield
    if {$amiadmin} {
    set t [::YUI::DataTable new -skin $skin -volatile \
               -columns {
		::YUI::AnchorField edit -CSSclass edit-item-button -label "" 
		::YUI::AnchorField delete -CSSclass delete-item-button -label "" 
		::YUI::AnchorField title -label "#xolrn_excs.title#" -orderby title
		::YUI::AnchorField last_modified -label "#xolrn_excs.Last-Modified#" -orderby last_modified 
		::YUI::AnchorField tries -label "#xolrn_excs.tries#"
		::YUI::AnchorField score -label "#xolrn_excs.points#"
		::YUI::AnchorField user_tries -label "#xolrn_excs.totaltries#"
		::YUI::AnchorField result_cnt -label "#xolrn_excs.totalsubmitted#"
		::YUI::AnchorField unique_tries -label "#xolrn_excs.students#"
		::YUI::AnchorField avg_result -label "#xolrn_excs.avgpoints#"
		::YUI::AnchorField show_answers -label "#xolrn_excs.showanswers#"
               }]
	} else {
	  set t [::YUI::DataTable new -skin $skin -volatile \
	  -columns {
                 ::YUI::AnchorField title -label "#xolrn_excs.title#" -orderby title
                 ::YUI::AnchorField last_modified -label "#xolrn_excs.Last-Modified#" -orderby last_modified 
                 ::YUI::AnchorField tries -label "#xolrn_excs.tries#"
                 ::YUI::AnchorField score -label "#xolrn_excs.points#"
		 }]
	}

    set where_clause ""
    set view_id ""
    # TODO: why filter on title and name?
    if {[my exists regexp]} {set where_clause "(bt.title ~ '$regexp' OR ci.name ~ '$regexp' )"}

    #foreach object_type [my types_to_show] \{
    set object_type "::xowiki::FormPage"
    set attributes [list revision_id creation_user title parent_id \
                          "to_char(last_modified,'YYYY-MM-DD HH24:MI') as last_modified" ]
    if {$object_type eq "::xowiki::FormPage"} {
        lappend attributes page_template instance_attributes state
        set base_table [$object_type set table_name]i
    } else {
        set base_table cr_revisions
    }
    set ordervar ""
	set itemorder [ad_get_client_property module orderby]
	if {[lindex $itemorder 0] eq "title" } {
		set ordervar "$itemorder"
	} 
	if {$itemorder eq ""} {
	    #first call, no sorter defined
	    set ordervar "title asc"
    }
      
	#checks - is this user allowed to open this question?
	set time_from [$page get_property -name time_from -default ""]
	set time_to [$page get_property -name time_to -default ""]
	set requirement [$page get_property -name progress_constraint -default ""]
	set currenttime [clock seconds]
	
	set time_from_secs [clock scan $time_from]
	set time_to_secs [clock scan $time_to]
	
	if {![permission::permission_p -object_id $package_id -privilege "admin"]} {
	if {$time_from ne "" } {
		if {$currenttime <= $time_from_secs} {
		return "<div id='user-message'>Kein Zugriff! \n Dieses Item wird erst am $time_from freigeschaltet</div>"
		}
	}
	
	if {$time_to ne ""} {
		if {$currenttime >= $time_to_secs} {
			return "<div id='user-message'>Kein Zugriff! \n Dieses Item war nur bis $time_to freigeschaltet</div>"
		}
	}
	}
      
	 #check if user has fulfilled the requirements
	set requirement ""
	if {[$page istype ::xowiki::FormPage]} {
	set requirement [$page get_property -name progress_constraint -default ""] }
	set requirements_met 1
          if {$requirement ne  ""} {
		#does the user meet the requirements?
		set page [string trimleft [$package_id resolve_page_name /$requirement ] :]
		if {$page ne "" && [$page istype ::xowiki::FormPage]} {
			foreach question [$page get_property -name content] {
			#my msg $question
				regexp {.*/(.*)$} $question match shortname
				#my msg " ${shortname}___[::auth::get_user_id] -parent_id [$package_id folder_id]"
				set item [::xo::db::CrClass lookup -name ${shortname}___[::auth::get_user_id] -parent_id [$package_id folder_id]]
				if {$item != 0} {
					set instance [::xo::db::CrClass get_instance_from_db -item_id $item]
					if {[$instance set state] ne "closed"} {
						set requirements_met 0
						break
					}
				} elseif {$item eq 0} {
					set requirements_met 0
				}
			}
		}
	}
    if {[$page istype ::xowiki::FormPage]} {
    set assignment_marker ""
	if {$requirements_met} {
    set sql ""
    set type ""
	if {[$page get_property -name content -default ""] ne ""} {
		#assignments have a content attribute in the ia 
            set type [$page get_property -name typ] 
            #regsub -all " " [$page get_property -name content] ", " itemlist
            foreach i [$page get_property -name content] {
                #lappend itemlist [string trimleft [[$page package_id] resolve_page_name /$i ] :]
                lappend itemlist [string trimleft [::xo::db::CrClass get_instance_from_db -item_id $i ] :]
		#my msg "resolving $itemlist /$i"
            }
	    
            regsub -all " " $itemlist ", " itemlist
            switch -- $type {
              exam {
                      #my msg "we have an exam!"
		      set including_page_id [$page set item_id]
                      #resolve wf
                      set examwf [$package_id pretty_link wf-exam ]
                      #display generic exam page with statistics
                      #if {[::xo::cc query_parameter startexam 0]} {
                       # ad_set_client_property module ${including_page_id}_started 1
                       # ad_set_client_property module ${including_page_id}_starttime [exec date +%H-%M]
                        #ad_set_client_property module currentexam $including_page_id
                      #}
                      #exam done: display page with results
					  #                    -title.href  "$return_url?view=$including_page_id"
					  #&jumpto=$genericexamform
                      $t add \
                    -title "Übersichtsseite Musterklausur" \
		    -title.href  "$examwf?m=create-or-use&a=[$page item_id]"\
                    -last_modified "" \
                    -tries "" \
                    -score "" \
		    -user_tries "" \
                    -result_cnt "" \
                    -avg_result "" \
                    -unique_tries "" \
                    -show_answers "" \
					-edit ""
					$t set hide "tries score user_tries result_cnt avg_result unique_tries edit last_modified"
                }
            }
              set sql "SELECT bt.item_id,ci.name,ci.publish_status,bt.object_type,revision_id,creation_user,bt.title,parent_id,to_char(last_modified,'YYYY-MM-DD HH24:MI') as last_modified,page_template,instance_attributes,state FROM cr_items ci, xowiki_form_pagei bt WHERE ci.item_id = bt.item_id and coalesce(ci.live_revision,ci.latest_revision) = bt.revision_id and ci.item_id in ($itemlist) ORDER BY title asc"
        set assignment_marker &a=[$page item_id]
    } elseif {[$page istype ::xowiki::FormPage]} {
        set sql [$object_type instance_select_query \
                     -folder_id $current_folder_id \
                     -with_subtypes false \
                     -select_attributes $attributes \
                     -where_clause $where_clause \
					 -orderby $ordervar \
                     -base_table $base_table]
#ns_log notice "mmo!! sql $sql"					 
		  #::xowiki::FormPage instantiate_objects -sql $sql
    } 
		
    if {$sql ne ""} {
        set j 0
		lappend itemurllist $genericexamform ""
        db_foreach [my qn instance_select] $sql {
            set page_link2 [::$package_id pretty_link  -parent_id $parent_id $name ]
	    set page_link $item_id
	    #set name [::$package_id external_name -parent_id $parent_id $name]
            if {$name eq "index"} continue
            if {$object_type eq "::xowiki::FormPage"} {
                ::xo::db::CrClass get_instance_from_db -item_id $page_template 
                set type_label [$page_template name]	  
                if {[$page_template istype ::xowiki::FormPage]} {
                    set type_label [$page_template property icon_markup]
                    set object_type_richtext true
                } else {
                    set type_label "Folder [$page_template name]"
                    set object_type_richtext false
                }
            } else {
                set type_label [string map [list "::xowiki::" ""] $object_type]
                set object_type_richtext false
            }
            
            set titlelink [export_vars -base $page_link {template_file}]
            set editlink [export_vars -base $page_link {{m edit} return_url}]
            #set wf_simple_qti [ $package_id pretty_link wf-simple-qti]
            array set ia $instance_attributes
        
            #set folder [::xo::db::CrFolder get_instance_from_db -item_id [[$page package_id] folder_id]]
                
            if {[info exists ia(question_type)] } {
                switch -- $ia(question_type) {
                    ot {
                        #set wflow  [::xo::db::CrClass lookup -name wf-opentext-cf -parent_id [$folder set item_id]]
			#set wflowtype "opentext-cf"
			set wflowtype [$package_id pretty_link wf-opentext-cf]
                    }
                    default {
                        #set wflow [::xo::db::CrClass lookup -name wf-simple-qti -parent_id [$folder set item_id]] 
			set wflowtype [$package_id pretty_link wf-simple-qti]
                    }
                }
            } else {
                #assuming default (this is an old question)
                #set wflow [::xo::db::CrClass lookup -name wf-simple-qti -parent_id [$folder set item_id]] ;# wf-simple-qti
		set wflowtype [$package_id pretty_link wf-simple-qti]
            }
        
            lappend foldercontent $item_id
            #we have to read the performance of the user from the instances
            #can the parent_id be different from the workflow id?, anyway, let's use the str_id
            set tries ""
            set score ""
            set avg_result ""
            set result_cnt ""
            set user_tries ""
            set unique_tries ""
            set result_sum 0
			#instances are all in en
			regsub -all "de:" $name "en:" enname
            set id [::xo::db::CrClass lookup -name ${enname}___[::auth::get_user_id] -parent_id [$package_id folder_id]]
            if {$id ne 0} {
                set useritem [::xo::db::CrClass get_instance_from_db -item_id $id]
                array set ia [$useritem set instance_attributes]
                set score [expr {[info exists ia(score)] ? [format "%.2f" $ia(score)] :  ""}]
                set tries [expr {[info exists ia(attempts)] ? $ia(attempts) : ""}]
                #my msg "meine instance attribute: [array get ia]"
                set user_tries [expr {[info exists ia(global_nr_of_tries)] ? $ia(global_nr_of_tries) : ""}]
		array unset ia
            }

            ##summing up results from the page template
            #get the item from db 
            set page_template_id [::xo::db::CrClass lookup -name ${name} -parent_id $parent_id]
            #my msg "name: $name - parent_id: $parent_id - page_template_id: $page_template_id"
            if {$page_template_id ne 0} {
                set page_template_item [::xo::db::CrClass get_instance_from_db -item_id $page_template_id]
                array unset page_template_ia
                array set page_template_ia [$page_template_item set instance_attributes]
    
                set result_cnt 0
                set unique_tries 0
                set r_name_list [list]
                foreach {r_name result} [array get page_template_ia "result_*"] {
                    incr result_cnt
                    set result_sum [expr {$result_sum+$result}]
                    #remove the time of the name
                    regexp {(.*_.*)_} $r_name complete r_name
                    #my msg "r_name: $r_name"
                    if {[lsearch $r_name_list $r_name] eq -1} {
                        lappend r_name_list $r_name
                        incr unique_tries
                    }
                }
                if {$unique_tries eq 0} {set unique_tries "" }
                if {$result_cnt ne 0} {
                    set avg_result [format "%.2f" [expr {$result_sum/$result_cnt}]]
                } else {
                    set result_cnt ""
                }            
            }
            if {$state ne ""} {
	    set including_page_id [$page set item_id]
	     #my msg "is this started?[ad_get_client_property -default 0 module ${including_page_id}_started] $type"
                switch -- $type {
                      exam {
                          #show questions only after the exam has been started, use exam workflow
                          if {[$__including_page get_property -name started -default 0] || 
			  [$__including_page get_property -name completed -default 0]} {
                              $t add \
                                  -title $title \
                                  -title.href  "[::xo::cc url]?jumpto=$page_link"\
                                  -last_modified $last_modified \
                                  -tries $tries \
                                  -score $score \
                                  -user_tries $user_tries \
                                  -result_cnt $result_cnt \
                                  -unique_tries $unique_tries \
                                  -avg_result $avg_result \
                                  -show_answers "" \
				  -edit ""
                             #itemlist will be used in the workflow
			}
                             lappend itemurllist $page_link ""
                      }
                      default {
		      if {$amiadmin} {
                          $t add \
                            -title $title \
                            -title.href  "$wflowtype?m=create-or-use&p.form=$page_link$assignment_marker"\
                            -last_modified $last_modified \
                            -tries $tries \
                            -score $score \
                            -user_tries $user_tries \
                            -result_cnt $result_cnt \
                            -unique_tries $unique_tries \
                            -avg_result $avg_result \
                            -show_answers "Antworten" \
                            -show_answers.href "$page_link2?m=list_answers&page_size=1000" \
			    -edit "" \
			    -edit.href  "$page_link2?m=edit" \
			    -edit.title #xowiki.edit# \
			    -delete "" \
			    -delete.href "$page_link2?m=delete&return_url=[::xo::cc url]" \
			    -delete.title #xowiki.delete#
			} else {
			   $t add \
                            -title $title \
                            -title.href  "$wflowtype?m=create-or-use&p.form=$page_link$assignment_marker"\
                            -last_modified $last_modified \
                            -tries $tries \
                            -score $score 
			}
                      }
                }
            }
	    array unset ia
      } ;#end db_foreach
       
      #if {$type eq "exam"} {
          #if {[ad_get_client_property -default 0 module ${including_page_id}_started]} {
			#if {[ad_get_client_property -default 0 module ${including_page_id}_itemlist] eq 0} { 
              #my msg "child_res ${including_page_id}_itemlist $itemurllist"
              #ad_set_client_property module ${including_page_id}_itemlist $itemurllist
		#	  }
         # }
      #}
	}
    } else {;#end requirements_met
		return "<div id='user-message'>Kein Zugriff! \n Voraussetzung für diese Aufgabe ist [$page set title]</div>"
	  }
	  }
    #\} end types_to_show
   # foreach {att order} [split $itemorder ,] break
    #orderby is handled by the itemorder parameter
	#orderby is also faulty, sort titles in db query
	set precedence ""
	if {$itemorder ne ""} {
        if {[lindex $itemorder 0] ne "title"} {
            $t orderby -order [expr {[lindex $itemorder 1] eq "asc" ? "increasing" : "decreasing"}] [lindex $itemorder 0]
        }
	}
	
## 	if {[::xo::cc query_parameter next ""] eq 1} {
 # 		#search the next question and store it
 # 		set i 1
 # 		foreach line [$t children] {
 # 			ns_log notice "mmo [$line set title.href]"
 # 			if {[string match *[::xo::cc query_parameter p.form]* [$line set title.href] ]} {
 # 				set nextlink [lindex [$t children] $i]
 # 				ns_log notice "mmo we are redirecting to: [$nextlink set title.href]"
 # 				#ad_returnredirect [$nextlink set title.href]
 # 			}
 # 			incr i
 #         }
 # 	}
 ##
	
	foreach field [$t children] {
	    lappend precedence [$field set title.href]
	}
	#my msg "precedence $precedence"
	ad_set_client_property module precedence $precedence
	return [$t asHTML]
  }
}