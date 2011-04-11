namespace eval ::xolrn {

ad_proc -public batch_import {comm_id package_id} {
	##
	## import all exercises from a LMS (community_id) into package
	##
	set community_obj [::tlf_global load_community $comm_id]
	set csp_root_id [$community_obj root_concept_id]
	::xolrn::importfolder $csp_root_id $package_id $comm_id
	
}

ad_proc -public importsubfolder {parent_folder package_id comm_id folder} {
##
##  recursive import of subfolders
##
set sub_folder [db_list_of_lists sub_folder {select c.lr_concept_id as folder_id, c.name as title, shortname
		FROM lr_concepts c 
		INNER JOIN lr_objects lro 
		ON c.lr_concept_id = lro.lr_object_id
		WHERE c.parent_id = :parent_folder
		ORDER BY tree_sortkey ASC;} ]
		
		foreach item $sub_folder {
			foreach {folder_id title shortname} $item {
			#process all children of parent_folder
			::xowiki::Package initialize -package_id $package_id
			set folder_obj  [string trimleft [$package_id resolve_page_name "exercise.form"] ::]
			set exercises_obj [string trimleft [$package_id resolve_page_name "exercises"] ::]
			::xowiki::FormPage create exercises -noinit \
			-set anon_instances f \
			-set form {} \
			-set text {} \
			-set package_id $package_id \
			-set name $shortname \
			-set page_template $folder_obj \
			-set title $title \
			-set publish_status ready \
			-set form_constraints _nls_language:omit \
			-set parent_id $folder
			set newfolder [exercises save_new]
			ns_log notice "imp: $folder - $title"
			ns_log notice "imp: $parent_folder - $folder_id"
		
		set itemlist [db_list_of_lists itemlist {SELECT lr_object_id from lr_concept__all_objects_developers_view lrc 
  		inner join dotlrn_communities_full dc on lrc.community_id = dc.community_id 
  		where restype = 'excs' 
  		and lrc.community_id = :comm_id 
  		and lr_concept_id = :folder_id;}]
		
		foreach lr_object_id $itemlist {
  			ds_comment "imp: trying to import $lr_object_id, passing $folder $package_id - returned $dev"
  			catch {::xolrn::importlr $lr_object_id $package_id $newfolder} dev
			}
		#import subfolders of curernt folder
		::xolrn::importsubfolder $folder_id $package_id $comm_id $newfolder
		}
		}
	}

ad_proc -public importfolder {fid package_id comm_id} {
##
## import root folder, call recursive import
##
db_0or1row root_folder {select c.lr_concept_id as folder_id, c.name as title, shortname
		FROM lr_concepts c 
		INNER JOIN lr_objects lro 
		ON c.lr_concept_id = lro.lr_object_id
		WHERE c.lr_concept_id = :fid
		ORDER BY tree_sortkey ASC;} 
		#this is the root folder
		#create folder
		::xowiki::Package initialize -package_id $package_id
		#create folder objects
		set folder_obj  [string trimleft [$package_id resolve_page_name "exercise.form"] ::]
		set exercises_obj [string trimleft [$package_id resolve_page_name "exercises"] ::]
			::xowiki::FormPage create exercises -noinit \
			-set anon_instances f \
			-set form {} \
			-set text {} \
			-set package_id $package_id \
			-set name $shortname \
			-set page_template $folder_obj \
			-set title $title \
			-set publish_status ready \
			-set form_constraints _nls_language:omit \
			-set parent_id $exercises_obj
			set folder [exercises save_new]
			ns_log notice "imp: $folder - $title"
		ns_log notice "imp: $fid - $folder_id"
		
		db_foreach item {SELECT lr_object_id from lr_concept__all_objects_developers_view lrc 
  		inner join dotlrn_communities_full dc on lrc.community_id = dc.community_id 
  		where restype = 'excs' 
  		and lrc.community_id = :comm_id 
  		and lr_concept_id = :folder_id;} {
  			catch {::xolrn::importlr $lr_object_id $package_id $folder} dev
  			ds_comment "imp: trying to import $lr_object_id, passing $folder $package_id - returned $dev"
  		}
			::xolrn::importsubfolder $folder_id $package_id $comm_id $folder
}

 ad_proc -public importlr {id package_id folder_id} {
 ##
 ## import a simple exercise (id) into folder of package
 ##
	set xml [db_string interaction_xml {select data from lr_exercisesi where item_id = :id;}]
	set root [dom parse $xml documentElement]
	#ds_comment "original exercise [$root asXML] "
	set ex_type multiplechoice
	catch {set ex_type [[$root selectNodes "/exercise/question_data/*"] nodeName]} err
	
	if {$ex_type eq "multiplechoice"} {
	#exercise text - angabe
	set exercise_text ""
	catch {set exercise_text [[$root selectNodes "/exercise/question_data/problem_text"] asXML]} err
	foreach probtext [$root selectNodes "/exercise/question_data/$ex_type/problem_text/*"] 	   {
		lappend exercise_text [$probtext asXML]
	}
	#ds_comment "text $exercise_text"
	set formcontent "form \{<form>
				<table class='mchoice'><tbody>
				<tr><td class='text' colspan='2'><div class='question_text'>$exercise_text</div></td></tr>
				"
	set feedback ""
        set feedbacknodes [$root selectNodes "/exercise/question_data/$ex_type/feedback/*"] 
	foreach node $feedbacknodes {
		lappend feedback [$node asXML]
	}
	#ds_comment "feedback $feedback"
	
        set test_item "
		test_item.minutes 0 
		test_item.grading exact
		test_item.adaptive yes
		test_item.penalty 0.3
		test_item.shuffle yes
		test_item.scoring default
		test_item.interaction \{ test_item.interaction.text \{ $exercise_text \} 
		"
	
	if {$feedback ne ""} {
	append test_item "
		test_item.feedback_correct \{$feedback\}
		"
	}
	
	#answers
	set i 1
	#set answers [$root selectNodes "/exercise/question_data/$ex_type/answer/answer_text/*"]
	set title [[$root selectNodes "/exercise/metadata/title"] text]
	set name [[$root selectNodes "/exercise"] getAttribute "shortname"]
	foreach answerNode [$root selectNodes "//answer"] {
		set ansroot [dom parse [$answerNode asXML]]
		set answer [[$ansroot selectNodes "/answer/answer_text"] text]
		set istrue [$answerNode getAttribute "value"] 
		switch $istrue {
			true {
				set istrue t
			}
			false {
				set istrue f
			}
		}
		
		#ds_comment $answer
		
	append formcontent "<tr><td class='selection'>
		<input type='checkbox' name='v-$i' value='v-$i'/></td>
		<td class='value'>$answer</td></tr>"
        
        append test_item "
		test_item.interaction.v-$i \{ 
			test_item.interaction.v-$i.text \{$answer\} 
			test_item.interaction.v-$i.correct $istrue 
			\} "
        incr i
	}
	append formcontent "</tbody></table></FORM> \} " 
        append formcontent "test_item \{$test_item\}"
        append formcontent "\} 
	question_type mc 
	feedback_level full
	auto_correct true 
	exercise_form mc
	nr_choices [expr {$i-1}]
	anon_instances true 
	form_constraints \{@categories:off 
		@cr_fields:hidden 
		_nls_language:omit 
		_page_order:hidden 
		_creator:hidden 
		_description:hidden 
		v-1:checkbox,answer=v-1 
		v-2:checkbox,answer= 
		v-3:checkbox,answer= 
		v-4:checkbox,answer= 
		v-5:checkbox,answer= 
	\}"
        #ds_comment $formcontent
        ::xowiki::Package initialize -package_id $package_id
	set page_template [string trimleft [$package_id resolve_page_name wf-form-edit] :]
	set parent_id [string trimleft [$package_id resolve_page_name exercises] :]
        set a [::xowiki::FormPage create newquestion \
		-noinit -package_id $package_id \
		-parent_id $folder_id \
		-name $name \
		-title $title \
		-publish_status ready \
		-page_template $page_template \
		-instance_attributes $formcontent \
		-state edited]
        newquestion save_new
        #return [$a serialize]	
	} else {
	ds_comment "$id was not imported: unsupported question type"
	}
}

#somewhat deprecated, since exporting from xml is less buggy and less complicated
    ad_proc -public importqti {id package_id} {
        lr_export_manager ::expo -id $id -infopath_p 0 -qti_p 0 -redirect_p 0
	::expo export 
        set root [[dom parse [[::expo]::export_objs::$id set whole_xml]] documentElement]
        #calling export acutually twice results in a xml beginning with <learning_resources>, which needs to be removed
        set object_node [$root firstChild]
        set qti_in_xml [dom createDocument learning_resources]
        
        if {[$object_node nodeName] == "exercise"} {
            if [$object_node hasAttributeNS "" xmlns] {
                    $object_node removeAttributeNS "" xmlns
            }
            [$qti_in_xml documentElement] appendChild $object_node
        }
    
        set fd [open [file join [acs_package_root_dir tlf-resource-integrator] www resources learn2qti.xsl]]
        set xsl [read $fd]
        close $fdpa
        set xsl_dom [dom parse $xsl]
        
         foreach answerNode [[$qti_in_xml documentElement] selectNodes -namespaces {html http://www.w3.org/1999/xhtml} "//answer|//html:answer|//answer_text|//html:answer_text|//dummy|//value"] {
                        #ns_log notice "mmo answerNode [$answerNode asXML]"
                        $answerNode setAttribute ident [$answerNode selectNodes "generate-id()"]
         }
    
        [$qti_in_xml documentElement] xslt $xsl_dom root
        ds_comment [$root asXML]
        set a [$root selectNodes "/questestinterop/assessment/section/item"]
        set title [$a getAttribute "title"]
        set name [$a getAttribute "ident"]
        set assignment [[$a selectNodes "/questestinterop/assessment/section/item/presentation/flow/material/mattext"] text]
        
        set answers [$a selectNodes "/questestinterop/assessment/section/item/presentation/flow/response_lid/render_choice/flow_label/response_label"]
        set conditions [$root selectNodes "/questestinterop/assessment/section/item/resprocessing/respcondition/conditionvar"]
        
        set formcontent "form \{<form>
				<table class='mchoice'><tbody>
				<tr><td class='text' colspan='2'><div class='question_text'>$title</div></td></tr>
				"
        
        set test_item "
		test_item.minutes 0 
		test_item.grading exact
		test_item.adaptive yes
		test_item.penalty 0.3
		test_item.shuffle yes
		test_item.scoring default
		test_item.interaction \{ test_item.interaction.text \{ $title \} 
		"
        
        set i 1
        foreach node $answers {
            set ident [$node getAttribute "ident"]
            if {[$root selectNodes "/questestinterop/assessment/section/item/resprocessing/respcondition/conditionvar\[varequal='$ident'\]"] eq ""} {
                set istrue f
            } else {
                set istrue t
            }
        
            set answer [[[$node childNode] childNode] text]
            append formcontent "<tr><td class='selection'>
			<input type='checkbox' name='v-$i' value='v-$i'/></td>
			<td class='value'>$answer</td></tr>"
        
            append test_item "
		test_item.interaction.v-$i \{ 
			test_item.interaction.v-$i.text \{$answer\} 
			test_item.interaction.v-$i.correct $istrue 
			\} "
        
            incr i
        }
        append formcontent "</tbody></table></FORM> \} " 
        append formcontent "test_item \{$test_item\}"
        append formcontent "\} 
	question_type mc 
	feedback_level full
	auto_correct true 
	exercise_form mc
	nr_choices [expr {$i-1}]
	anon_instances true 
	form_constraints \{@categories:off 
		@cr_fields:hidden 
		_nls_language:omit 
		_page_order:hidden 
		_creator:hidden 
		_description:hidden 
		v-1:checkbox,answer=v-1 
		v-2:checkbox,answer= 
		v-3:checkbox,answer= 
		v-4:checkbox,answer= 
		v-5:checkbox,answer= 
	\}"
        ::xowiki::Package initialize -package_id $package_id
	set page_template [string trimleft [$package_id resolve_page_name wf-form-edit] :]
	#set parent_id [string trimleft [$package_id resolve_page_name exercises] :]
        set a [::xowiki::FormPage create newquestion \
		-noinit -package_id $package_id \
		-parent_id $folder_id \
		-name $name \
		-title $title \
		-publish_status ready \
		-page_template $page_template \
		-instance_attributes $formcontent \
		-state edited]
        newquestion save_new
        return [$a serialize]
    }
}