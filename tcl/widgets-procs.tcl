::xo::library doc {
  Part of XoLrn Project

  @author Markus Moser, Thomas Renner
  @creation-date 2010
}

 ::xo::library require -package xowiki xowiki-procs

namespace eval ::xowiki::formfield {
###
###generates a page that displays information about the currently active exam and the users' previous scores

	Class genericexampage -superclass FormField -parameter {
	{inplace true}
	}
	genericexampage instproc initialize {} {
		#nada
	}
		
	genericexampage instproc render_input {} {
		set exampagehtml "<table id='genericpage' border='1'><tr><td><h3>Musterklausur</h3></td><td>Frage</td><td>Abgegeben</td><td>Punkte</td></tr>"
		set j 0
		#my msg "[[my object] get_property -name itemlist]"
		foreach {item score} [[my object] get_property -name itemlist] {
			if {[string match *genericexamform $item]} {continue}
			#set currentitem [[[my object] set package_id] resolve_page_name /$item]
			set currentitem [::xo::db::CrClass get_instance_from_db -item_id $item]
			my msg "currentitem $currentitem $item"
			if {[[my object] get_property -name started]} {
			if {$score eq ""} {set submitted "nein"} else {set submitted "ja"}
			append exampagehtml "<tr id='[$currentitem set item_id]'><td>Frage [incr j]</td><td>[$currentitem set title]</td><td id='submitted'>$submitted</td><td id='score'></td></tr>"
			} else {
			append exampagehtml "<tr id='[$currentitem set item_id]'><td>Frage [incr j]</td><td>[$currentitem set title]</td><td id='submitted'></td><td id='score'>$score</td></tr>"
			}
			}
			
		set abgabentable	"<table><tr><td>Abgabe am</td><td>erreichte Prozent</td></tr>"
		set resultsexist 0
		foreach {ia value} [[my object] set instance_attributes] {
			if {[string match results_* $ia]} {
			   regexp {.*_(.*)$} $ia match clockvalue
				set resultsexist 1
				append abgabentable "<tr><td>[clock format $clockvalue -format {%d.%m.%Y %R}]</td><td>[string range [expr {$value*100}] 0 3]</td></tr>"
			}
		}
		append exampagehtml "</table>"
			::html::t -disableOutputEscaping "$exampagehtml"
		if {$resultsexist} {
			append abgabentable "</table>"
			::html::t -disableOutputEscaping "$abgabentable"
		}
	}
}

#view_resources is deprecated and has been replaces by form fields (see workflow-procs)
## namespace eval ::xowiki::includelet {
 #    
 #     ::xowiki::IncludeletClass create view_resources \
 #         -superclass ::xowiki::Includelet 
 #      #deprecated! current version is using formfields
 #     view_resources instproc render {} {
 #         my instvar __including_page actual_query __caller_parameters parameter_declaration querypar
 # 		#note: to prevent ugly form resolution issues, the wf-form is now submitted as item_id
 #     	        if {[::xo::cc query_parameter wf ""] ne ""} {
 #                 my msg "query_parameter: [::xo::cc query_parameter wf]"
 #                 set workflowitem [::xo::db::CrClass get_instance_from_db -item_id [::xo::cc query_parameter wf]]
 #                 set method [::xo::cc query_parameter method]
 #                 set package_id [$__including_page package_id]
 # 
 # 				#checks - is this user allowed to open this question?
 # 				set time_from [$__including_page get_property -name time_from -default ""]
 # 				set time_to [$__including_page get_property -name time_to -default ""]
 # 				set requirement [$__including_page get_property -name progress_constraint -default ""]
 # 				set currenttime [clock seconds]
 # 				
 # 				set time_from_secs [clock scan $time_from]
 # 				set time_to_secs [clock scan $time_to]
 # 				
 # 				if {$time_from ne ""} {
 # 					if {$currenttime <= $time_from_secs} {
 # 					return "<div id='user-message'>Kein Zugriff! \n Dieses Item wird erst am $time_from freigeschaltet</div>"
 # 					}
 # 				}
 # 				
 # 				if {$time_to ne ""} {
 # 					if {$currenttime >= $time_to_secs} {
 # 						return "<div id='user-message'>Kein Zugriff! \n Dieses Item war nur bis $time_to freigeschaltet</div>"
 # 					}
 # 				}
 # 				
 #                 switch -- $method {
 #                         create-or-use-resource {
 #                                 #use the current url as return_url until another item is selected by the user
 #                                 ad_set_client_property module return_url [ad_return_url]
 #                                 set item [$workflowitem create-or-use-resource [$workflowitem set name] [::xo::cc query_parameter p.form]]
 #                         }
 #                         create-new {
 # 				ad_set_client_property module return_url [ad_return_url]
 #                                 set item [$workflowitem create-new ]
 #                         }
 #                         default {
 #                         my msg "~~~~~unknown method~~~"
 #                         }
 #                 }
 #                 #for some reason a single line after item view breaks everything
 # 		#$item set_property -new 1 template [::xo::cc query_parameter template]
 # 		ns_log notice "xxx [$item serialize]"
 # 		$item set_property -new 1 template2 "view-inwindow"
 # 		$item view
 # 		
 #         } elseif {[$__including_page istype ::xowiki::FormPage]} {
 # 				if {[$__including_page get_property -name typ] eq "exam"} {
 #                my msg "we have parameter view! - view a Page"
 #                #display special pages for some assignment types if the user has clicked them
 #                switch -- [$__including_page get_property -name typ] {
 #                exam {
 # 			   my msg "[ad_get_client_property -default 0 module [$__including_page set item_id]_itemlist]"
 # 				set wf [::xo::db::CrClass lookup -name wf-exam -parent_id [[::xo::cc package_id] set folder_id]]
 # 				ad_returnredirect  [::xo::cc url]?wf=$wf&template2=view-inwindow&method=create-or-use-resource&title=[$__including_page set title]
 # 			   }
 # 			   exam_old {
 # 				set genericpageid [::xo::db::CrClass lookup -name [$__including_page set name]_exampage_[::xo::cc set user_id] -parent_id [[$__including_page set package_id] folder_id]]
 # 				
 # 				if {$genericpageid == 0} {
 # 					  set buildexampage 1
 # 					#let's create a new one
 #                       set exampagehtml "<table id='genericpage'><tr><td><h3>Musterklausur</h3></td><td>Frage</td><td>Abgegeben</td><td>Punkte</td></tr>"
 # 					  set j 0
 # 					  foreach {item parent} [$__including_page get_property -name content] {
 # 						set currentitem [::xo::db::CrClass get_instance_from_db -item_id $item]
 # 						append exampagehtml "<tr id='[$currentitem set item_id]'><td>Frage [incr j]</td><td>[$currentitem set title]</td><td id='submitted'></td><td id='score'></td></tr>"
 # 						}
 # 					append exampagehtml "</table>"
 #           #build the thing 
 # 				set genericpage [::xowiki::Page create genericexampage -noinit \
 # 					-set text "\{$exampagehtml\} text/html"\
 # 					-set package_id [$__including_page package_id] \
 # 					-set name [$__including_page set name]_exampage_[::xo::cc set user_id] \
 # 					-set title Musterklausur \
 # 					-set publish_status ready \
 # 					-set parent_id [[$__including_page package_id] folder_id]]
 # 					genericexampage save_new
 # 				} else {
 # 					set genericpage [::xo::db::CrClass get_instance_from_db -item_id $genericpageid]
 # 					#let's check if the user has submitted the questions and add it via dom
 # 					    dom parse -simple -html [lindex [$genericpage set text] 0] doc
 # 						$doc documentElement root
 # 						foreach n [$root selectNodes "//table\[@id='genericpage'\]/tr/td\[@id='submitted'\]"] {
 # 								#if {[::xo::db::CrClass lookup -name exam_${viewid}_${formname}___[::xo::cc set user_id] -parent_id  [[::xo::cc package_id] set folder_id]] } {
 # 									#$n appendChild [$doc createTextNode "blabla"]
 # 								#	}
 # 					
 # 					$genericpage set text "{[$root asXML]} text/html"
 # 							
 # 				}
 # 				}
 # 				set viewid [$__including_page set item_id]
 # 				set items [ad_get_client_property module ${viewid}_itemlist]
 # 				my msg "items $items"
 # 			if {[::xo::cc query_parameter submitexam 0]} {
 # 				 #we have the score for each item in the itemurllist array -> calculate overall score and display a pretty page
 # 				 #set session vars
 # 				 #special view method after submit 
 # 				 ad_set_client_property module ${viewid}_started 0
 # 				 ad_set_client_property module ${viewid}_completed 1
 # 				 set k 0
 # 				 set score_sum 0
 # 				 foreach {form str_id score} $items {
 # 					my msg "score:  $score"
 # 					if {$score eq ""} {
 # 						set score 0
 # 						my msg "question $form has not been submitted"
 # 						}
 # 					set score_sum [expr {$score_sum + $score}]
 # 					incr k
 # 				 }
 # 				 set percentage [expr {$score_sum / $k}]
 # 				 my msg "sie haben $percentage % erreicht"
 # 				 
 # 				 #use dom to write the results to genericpage
 # 				  
 # 				  }
 # 				  
 # 			if {[::xo::cc query_parameter startexam 0]} {
 # 			  my msg "startexam"
 # 			  
 # 			  #if the user takes an exam again, we delete the old answers
 # ## 			  foreach {url score} $items {
 # 				regexp {.*p.form=(.*)&p.str} $url match formname
 # 				set existingitem [::xo::db::CrClass lookup -name exam_${viewid}_${formname}___[::xo::cc set user_id] -parent_id  [[::xo::cc package_id] set folder_id]]
 # 				if {$existingitem != 0} {
 # 					#set instantiateditem [::xo::db::CrClass get_instance_from_db -item_id $existingitem]
 # 				#my msg "[$instantiateditem serialize]"
 # 				#$instantiateditem clear_form_selections
 # 				#problem: this is somehow slow, so let's avoid deleting
 # 			    [::xo::cc package_id] delete -name exam_${viewid}_${formname}___[::xo::cc set user_id] -item_id $existingitem
 # 				}
 # 			}
 # 			ad_returnredirect [lindex $items 0]
 #  ##	
 # 
 # 			}
 # 
 # 				set is_started [ad_get_client_property -default 0 module ${viewid}_started]
 # 				set context_package_id [::xo::cc package_id]
 # 				set title [$genericpage title]
 # 
 # 				foreach {html mime} [$genericpage set text] break
 # 				if {$is_started} {
 # 					append html "<a class='button' href='[::xo::cc url]?submitexam=1'>Klausur abgeben</a>"
 # 		       } else {
 # 					append html "<a class='button' href='[::xo::cc url]?startexam=1'>Starten</a>"
 # 		       }
 #                 set html [$genericpage adp_subst $html]
 # 				set content  [$genericpage substitute_markup $html]
 # 				set template_file "/packages/xowiki/www/view-inwindow"
 # 				$context_package_id return_page -adp $template_file -variables {
 # 				name title item_id context 
 # 				content {package_id $context_package_id} page_package_id page_context
 # 				}
 # 				# $genericpage view
 # 			}
 #        } ;#end switch
 # 	   }
 #        } ;#end view
 # 
 #         
 # 	}		
 # }
 ##

namespace eval ::xowiki::formfield {
###
### Which requirements must be fulfilled for starting an exercise?

	Class requirement_selector -superclass enumeration -parameter {
	{inplace true}
	{assignment_form assignment.form}
}

	requirement_selector instproc initialize {} {
	    my set widget_type text(select)
		next
		if {![my exists options]} {my options [list]}
	}
	
	requirement_selector instproc render_input {} {
	    set atts [my get_attributes id name disabled {CSSclass class}]
		set pid [[my object] set package_id]

		set folder_pages [::xowiki::FormPage get_form_entries -base_item_ids [string trimleft [$pid resolve_page_name [my assignment_form]] :] \
		-form_fields [list] \
		-package_id $pid \
		-orderby title]
		
		::html::select $atts {
				::html::option "" {::html::t ""}
				::html::t \n
			foreach item [$folder_pages children] {
			set atts [my get_attributes disabled]
			set name [$pid pretty_link  -parent_id [$item set parent_id] [$item set name]]
			lappend atts value $name
			if {[my value] eq $name } {
				lappend atts selected on
			}
				::html::option $atts {::html::t [$item set title]}
				::html::t \n
			}}
	}
}

namespace eval ::xowiki::formfield {
    Class assignment_selector_ff -superclass FormField -parameter {
    {feedback_level full}
    {inplace true}
   {folder_form_name exercise.form}
  }
  
  assignment_selector_ff instproc initialize {} {
	#nada
  }
  
  assignment_selector_ff instproc render_input {} {
	my instvar __including_page actual_query __caller_parameters parameter_declaration queryparm js
	my instvar package_id folder_id root_folder root_folder_href root_folder_name usednd
	my mixin ::xowiki::includelet::resource_selector
	set usednd 0
	::xo::Page requireJS "/resources/xolrn_excs/xolrn.js"
		
	set package_id [[my object] set package_id]
        set folder_id [$package_id set folder_id]
        set root_folder [::xo::db::CrClass get_instance_from_db -item_id $folder_id]
        set root_folder_href [$package_id set package_url]
        set root_folder_name [$package_id set instance_name]
		
	set js "
	var tree = '';
	var selectiontree = '';
	var nodemapper = {};
	var nodemapperbyname = {};
	var nodemapperbyid = {};
	var nodemapperbylabel = {};
	var ajaxloader = new YAHOO.util.YUILoader({
	require: \['treeview'\], // what components?
	base: \"/resources/ajaxhelper/yui/\",        
	loadOptional: true,
	onSuccess: function() {
		tree = new YAHOO.widget.TreeView(\"treeDiv1\");
		var rootNode = tree.getRoot();

		selectiontree = new YAHOO.widget.TreeView(\"treeDiv2\");
		var selroot = selectiontree.getRoot();
		var newvalue = '[[my object] property content]';
		var items = newvalue.split(' ');
		for (var j = 0; j < items.length; j++) \{
		  var o = items\[j\];
		  if (o == \"\") continue;
		    new YAHOO.widget.TextNode(\{label: nodemapperidtolabel\[o\]\}, selroot, true);
		  \}
		selectiontree.subscribe('clickEvent', selectiontree.onEventToggleHighlight);
		selectiontree.render();
		
		"
		
	my rendermain
	
	append js "},
	onFailure: function(o) {
		  alert('error: ' + YAHOO.lang.dump(o)); 
	}});
	
	ajaxloader.insert();
        "
		
		#generate textarea
		::html::t -disableOutputEscaping "<table><tr><td>
		<div id=\"treeDiv1\" class=\"ygtv-checkbox\"></div>
		<a class='button' id=\"add_to_assignment\">Auswahl hinzufügen></button>
		</td><td>
		<div id=\"treeDiv2\" class=\"ygtv-checkbox\"></div>
		<a class='button' id=\"remove_from_assignment\">Auswahl entfernen></button>"
		
		#append js "YAHOO.util.Event.onDOMReady(DDApp_assignment.init, DDApp_assignment, true);\n"
		#<a class='button' href='[$package_id pretty_link [[[my object] set page_template] set name] ]?m=create-new&parent_id=[[my object] item_id]' target='_new'>Neues Subfolder anlegen></button>
		::html::t -disableOutputEscaping "</td></tr></table><script>$js</script>"
}
}
 
 namespace eval ::xowiki::formfield {
 #same as resource_selector, but designed as formfield
 Class resource_selector_ff -superclass FormField -parameter {
    {feedback_level full}
    {inplace true}
	{folder_form_name exercise.form}
  }

  resource_selector_ff instproc initialize {} {
	#nada
	}

  resource_selector_ff instproc render_input {} {
		my instvar __including_page actual_query __caller_parameters parameter_declaration queryparm js
		my instvar package_id folder_id root_folder root_folder_href root_folder_name usednd
		my mixin ::xowiki::includelet::resource_selector
		set usednd 1
		::xo::Page requireJS "/resources/xolrn_excs/xolrn.js"
		
	set package_id [::xo::cc set package_id]
        set folder_id [$package_id set folder_id]
        set root_folder [::xo::db::CrClass get_instance_from_db -item_id $folder_id]
        set root_folder_href [$package_id set package_url]
        set root_folder_name [$package_id set instance_name]
	
	set js "
	var tree = '';
	var rootNode = '';
	var nodemapperbyid = {};
	var nodemapper = {};
	var nodemapperbyname = {};
	var nodemapperbylabel = {};

	var ajaxloader = new YAHOO.util.YUILoader({
	require: \['treeview'\], // what components?
	base: \"/resources/ajaxhelper/yui/\",        
	loadOptional: true,
	onSuccess: function() {
	tree = new YAHOO.widget.TreeView(\"treeDiv1\");
	rootNode = tree.getRoot();
	"
	
	my rendermain
	
	append js "
	},
	onFailure: function(o) {
		  alert('error: ' + YAHOO.lang.dump(o)); 
	}});
	
	ajaxloader.insert();
        "

	::html::t -disableOutputEscaping "<table><tr><td><div id=\"treeDiv1\"></div></td><td>"
	::html::div -class workarea {
		set values ""
		foreach v [my value] {
		  append values $v \n
		  set __values($v) 1
		}
		my CSSclass selection
		my set cols 30
		set atts [my get_attributes id name disabled {CSSclass class}]
		::html::textarea [my get_attributes id name cols rows style {CSSclass class} disabled] {
		  ::html::t $values
		}
	}
	#initialize javascript
	append js "YAHOO.util.Event.onDOMReady(DDApp.init, DDApp, true);\n"
	 ::html::t -disableOutputEscaping "</td></tr></table><script>$js</script>"
  }
  
    resource_selector_ff instproc convert_to_internal {} {
    #adopted from test_section
	#iterate through the forms of the selected items and concatenate them
    set form "<form>\n"
    set fc "@categories:off @cr_fields:hidden\n"
    set intro_text [[my object] property _text]
    append form "$intro_text\n<ol>\n"
	#my msg "i have [my value]"
    foreach v [my value] {
		set page ""
		#values should be the item_ids of the questions, that saves us resolution troubles
        catch {set page [::xo::db::CrClass get_instance_from_db -item_id $v]} err
        #my msg "test_section: we have item_id - name $v pid [[my object] parent_id]"
		if {$page ne ""} {
        append form "<li id=\"[$page get_property -name question_type]\" class=\"[$page set item_id]\"><h2>[$page set title]</h2>\n"
        set prefix c[$page set item_id]
        array set __ia [$page set instance_attributes]
        #my msg "voodoo some ia [$page set instance_attributes]"      
        # If for some reason, we have not form entry, we ignore it.
        # TODO: We should deal here with computed forms and with true
        # ::xowiki::forms as well...
        #
        if {![info exists __ia(form)]} {
          my msg "$v has no form included"
          continue
        }
        #
        # Replace the form-field names in the form
        #
        dom parse -simple -html $__ia(form) doc
        $doc documentElement root
        set alt_inputs [list]
        set alt_values [list]
        foreach html_type {input textarea} {
  	foreach n [$root selectNodes "//$html_type\[@name != ''\]"] {
  	  set alt_input [$n getAttribute name]
  	  $n setAttribute name ${prefix}_$alt_input
        #my msg "[$n asXML]"
  	  if {$html_type eq "input"} {
          if {[$n hasAttribute value]} {
            set alt_value [$n getAttribute value]
          }
  	  } else {
  	    set alt_value ""
  	  }
  	  lappend alt_inputs $alt_input
  	  lappend alt_values $alt_value
  	}
        }
        # We have to drop the toplevel <FORM> of the included form
        foreach n [$root childNodes] {append form [$n asHTML]}
        append form "</li>\n"
        #
        # Replace the formfield names in the form constraints
        #
        foreach f $__ia(form_constraints) {
          if {[regexp {^([^:]+):(.*)$} $f _ field_name definition]} {
  	  if {[string match @* $field_name]} continue
            # keep all form-constraints for which we have altered the name
  	  #my msg "old fc=$f, [list lsearch $alt_inputs $field_name] => [lsearch $alt_inputs $field_name] $alt_values"
  	  set ff [[my object] create_raw_form_field -name $field_name -spec $definition]
  	  #my msg "ff answer => '[$ff answer]'"
            if {[lsearch $alt_inputs $field_name] > -1} {
  	    lappend fc ${prefix}_$f
 	  } elseif {[$ff exists answer] && $field_name eq [$ff answer]} {
  	    # this rules is for single choice
  	    lappend fc ${prefix}_$f
  	  }
         }
        }
		}
      }
 
    append form "</ol></form>\n"
	[my object] set state edited ;#this was not created via the workflow
    [my object] set_property -new 1 form $form
    [my object] set_property -new 1 form_constraints $fc
    set anon_instances true ;# TODO make me configurable
    [my object] set_property -new 1 anon_instances $anon_instances
    # for mixed test sections (e.g. text interaction and mc), we have
    # to combine the values of the items
    [my object] set_property -new 1 auto_correct true ;# should be computed
    [my object] set_property -new 1 has_solution true ;# should be computed
	[my object] set_property -new 1 question_type section  
    #my msg "fc=$fc"
  }
  
 }
 
 namespace eval ::xowiki::includelet {
 #a selector using YUI TreeView to display all items in a strcutured way
    ::xowiki::IncludeletClass create resource_selector \
    -superclass ::xowiki::Includelet \
    -cacheable false \
    -parameter {
        {folder_form_name exercise.form}
      }
    
    resource_selector instproc render {} {
        my instvar __including_page actual_query __caller_parameters parameter_declaration queryparm js
		my instvar package_id folder_id root_folder root_folder_href root_folder_name usednd
		set usednd 0
		
        set package_id [$__including_page set package_id]
        set folder_id [$package_id set folder_id]
        set root_folder [::xo::db::CrClass get_instance_from_db -item_id $folder_id]
        set root_folder_href [$package_id set package_url]
        set root_folder_name [$package_id set instance_name]
		my rendermain
	}
		
	resource_selector instproc rendermain {} {
        my instvar package_id folder_id root_folder root_folder_href root_folder_name js usednd
        
        my set folder_form_id [::xowiki::Weblog instantiate_forms \
                           -forms [my folder_form_name] \
                           -package_id $package_id]
        #create root node
        append js "
	var n_$folder_id = new YAHOO.widget.TextNode(\{label: \"$root_folder_name\", href: \"$root_folder_href \"\}, rootNode, true); \n n_$folder_id.id = '$folder_id' \n
		nodemapper\[n_$folder_id.labelElId\] = n_$folder_id;\n
		nodemapperbyname\[n_$folder_id.name\] = n_$folder_id;\n
		var name_mapping = new Object();\n"

        my build_sub_tree -node $root_folder

        append js "tree.setNodesProperty('propagateHighlightUp',true);
        tree.setNodesProperty('propagateHighlightDown',true);
        tree.subscribe('clickEvent', tree.onEventToggleHighlight);
        tree.render();
        "
        
        return "<div id=\"treeDiv1\" class=\"ygtv-checkbox\"></div>
        <button id=\"add_selected\">Auswahl hinzufügen></button>
        <script>$js</script>"
    }
  
   resource_selector instproc build_sub_tree { 
    {-node}
  } {
        #my get_parameters
        my instvar current_folder_id js package_id usednd
    
        set folder_pages [::xowiki::FormPage get_form_entries \
                              -parent_id [$node item_id] \
                              -base_item_ids [my set folder_form_id] -form_fields "" \
                              -publish_status ready -package_id $package_id]

        eval lappend folders [$folder_pages children]
 
     foreach folder $folders {
        set label [$folder name]
		set folder_id [$folder item_id]
        append js "var n_$folder_id = new YAHOO.widget.TextNode(\{label: \"$label\"\}, n_[$folder parent_id], true); \n"
        #n_$folder_id.id = '$folder_id'; \n
		#nodemapper\[n_$folder_id.labelElId\] = n_$folder_id;\n
		#nodemapperbyname\[n_$folder_id.name\] = n_$folder_id;\n
		#name_mapping\[$folder_id\] = '[$package_id pretty_link -parent_id [$folder parent_id] $label]';\n"
		
        set sql [::xowiki::FormPage instance_select_query \
        -folder_id [$folder item_id] \
        -with_subtypes false \
        -with_children false \
        -select_attributes [list revision_id creation_user name title parent_id page_template] \
        -where_clause "state != ''" \
        -base_table [::xowiki::FormPage set table_name]i
        ]
        
        db_foreach [my qn instance_select] $sql {
            append js "var n_$item_id = new YAHOO.widget.TextNode(\{label: \"$title\"\}, n_[$folder item_id], false); \n n_$item_id.id = $item_id; \n n_$item_id.name = '$name';  \n
            nodemapper\[n_$item_id.labelElId\] = n_$item_id;\n
            nodemapperbyname\[n_$item_id.name\] = n_$item_id;\n
            nodemapperbyid\[$item_id\] = n_$item_id; \n
	    nodemapperbylabel\[n_$item_id.label\] = $item_id;\n"
            #useless mappers
	    #nodemapperurlfromname\['$title'\] =  '[$package_id pretty_link -parent_id $parent_id  $name]';\n
	    #  nodemapperidtolabel\[$item_id\] = n_$item_id.label ;\n
	    #nodemapperbyurl\['[$package_id pretty_link -parent_id $parent_id  $name]'\] = n_$item_id;\n
	    # name_mapping\[$item_id\] = '[$package_id pretty_link -parent_id $parent_id  $name]';\n
	    
	    
            if {$usednd} {append js "new DDList(\"ygtv\" + n_$item_id.index);\n"}
        }
        my build_sub_tree -node $folder
     }
 
 }
 }

namespace eval ::xowiki {
  Page ad_instproc rename_formfields {} {
  rename the form field and form constraints in workflow that process multiple forms
  } {
  #set prefix [string trimleft [my get_template_object] :]
  if {[my istype ::xowiki::FormPage]} {
  set prefix [my item_id]
  array set __ia [my set instance_attributes]
    if {![info exists __ia(form)]} {
        my msg "we have no form included"
        continue
      }
      #
      # Replace the form-field names in the form
      #
      dom parse -simple -html $__ia(form) doc
      $doc documentElement root
      set alt_inputs [list]
      set alt_values [list]
      foreach html_type {input textarea} {
	foreach n [$root selectNodes "//$html_type\[@name != ''\]"] {
	  set alt_input [$n getAttribute name]
	  $n setAttribute name ${prefix}___$alt_input
	  $n setAttribute value ${prefix}___$alt_input
      #my msg "[$n asXML]"
	  if {$html_type eq "input"} {
        if {[$n hasAttribute value]} {
          set alt_value [$n getAttribute value]
        }
	  } else {
	    set alt_value ""
	  }
	  lappend alt_inputs $alt_input
	  lappend alt_values $alt_value
	}
      }
      # We have to drop the toplevel <FORM> of the included form
      #foreach n [$root childNodes] {append form [$n asHTML]}
      #append form "</li>\n"
      set form [$root asXML]
	#
      # Replace the formfield names in the form constraints
      #
      foreach f $__ia(form_constraints) {
	if {[regexp {^([^:]+):(.*)$} $f _ field_name definition]} {
	  if {![string match @* $field_name]} {
	  my msg "old fc=$f, [list lsearch $alt_inputs $field_name] => [lsearch $alt_inputs $field_name] $alt_values"
	  set ff [my create_raw_form_field -name $field_name -spec $definition]
          if {[lsearch $alt_inputs $field_name] > -1} {
	    lappend fc ${prefix}___$f
	  } elseif {[$ff exists answer] && $field_name eq [$ff answer]} {
	    # this rules is for single choice
	    lappend fc ${prefix}___$f
	  }
	  } else {
	  #my msg "no match $f should be cr"
	  lappend fc $f
	  }
        }
      }
	  my msg "new fc $fc form $"
    return [list $fc $form] 
  }
  }
}

	#folders
	#########################
	#########################
	#displays folders
	#########################
	#########################
namespace eval ::xowiki::formfield {
	Class folderstruct -superclass FormField -parameter {
	{inplace true}
	}
	folderstruct instproc initialize {} {
	my instvar show_full_tree id folder_form_name assignment_form_name __including_page package_id root_form
	set show_full_tree 1
	set folder_form_name exercise.form
	set assignment_form_name assignment.form
	set __including_page [my object]
	set package_id [[my object] set package_id]
	set root_form exercises
	}


	folderstruct instproc render_item {} {
		my mixin ::xowiki::includelet::xofolders
		my instvar package_id folder_form_name assignment_form_name __including_page root_form
	       ::xo::Page requireJS "/resources/ajaxhelper/yui/yahoo-dom-event/yahoo-dom-event.js"
               ::xo::Page requireJS "/resources/ajaxhelper/yui/treeview/treeview-min.js"
               ::xo::Page requireCSS "/resources/ajaxhelper/yui/treeview/assets/folders/tree.css"

		set js "
			var [xowiki::Includelet js_name [self]];
			YAHOO.util.Event.onDOMReady(function() {
			[xowiki::Includelet js_name [self]] = new YAHOO.widget.TreeView('foldertree_[my id]'); 
			[xowiki::Includelet js_name [self]].subscribe('clickEvent',function(oArgs) { 
			var m = /href=\"(\[^\"\]+)\"/.exec(oArgs.node.html);
			return false;
			  });
			[xowiki::Includelet js_name [self]].render();
		      });
		     "
		::html::t -disableOutputEscaping [[my build_tree] render -style yuitree -js $js]
	}
	
	#child_resources_light
	#########################
	#########################
	#displays exercise_folder content
	#########################
	#########################
	Class child_resources_light -superclass FormField -parameter {
	{inplace true}
	}
	child_resources_light instproc initialize {} {
	my instvar package_id __including_page skin folder assignment
	set package_id [[my object] set package_id]
	set __including_page [my object]
	set folder exercise.form
	set assignment assignment.form
	set skin yui-skin-sam
	}
	child_resources_light instproc render_item {} {
	my mixin ::xowiki::includelet::child_resources_light
	::html::t -disableOutputEscaping [my render]
	}
	
	textarea instproc check=safe_html {value} {
	set msg [ad_html_security_check $value]
		if {$msg ne ""} {
			my uplevel [list set errorMsg $msg]
			return 0
		}
	return 1
  }
	
}