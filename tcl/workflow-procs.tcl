::xo::library doc {
  XoWiki Workflow - main library classes and objects

  @author Gustaf Neumann
  @creation-date 2008-03-05
  @cvs-id $Id $
}

# Todo:
# - after import, references are not updated 
#   (same for plain references); after_import methods?
#
# - Roles
# - assignment
# - workflow-assingnment includelet (over multiple workflows and 
#   package instances)

#::xo::db::require package xowiki
#::xo::db::require package xowf
#::xo::library require -package xowiki xowiki-procs
#::xo::library require -package xowf xowf-procs

namespace eval ::xowf {

#	static form_loader used in the workflows are defined here
	Context instproc edit_initialform {name} {
		 set f [::xowiki::Form new -childof [self] -name form-select-form -title "Neue Aufgabe erstellen" \
		 -text {{<p>@exercise_form@ @nr_choices@<br />@feedback_level@ <br /></p>} text/html} \
		 -anon_instances t \
		 -form_constraints {{exercise_form:select,label=#xolrn_excs.questiontype#,options={{Multiple choice} {mc}} {{Single choice} {sc}} {{#xolrn_excs.opentext#} {ot}} {{#xolrn_excs.gaptext#} {gt}} {{#xolrn_excs.matching#} {matching}} {{#xolrn_excs.order#} {order}} {{#xolrn_excs.slider#} {slider}},required} {feedback_level:radio,label=#xolrn_excs.feedbacklevel#,horizontal=true,options={"#xolrn_excs.fullfeedback#" full} {"#xolrn_excs.somefeedback#" some} {"#xolrn_excs.nofeedback#" none},default=none} {nr_choices:text,label=#xolrn_excs.nrofchoices#,size=2,value=3} {folderstruct:folderstruct} @cr_fields:hidden _nls_language:omit}]
	}
	
	Context instproc edit_testitemform {name} {
	array set ia [[my object] instance_attributes]
		switch -- $ia(exercise_form) {
			mc {
				set fc "test_item:test_item,question_type=mc,nr_choices=[[my object] get_property -name nr_choices -default 3],label=#xowf.exercise_mc# 
						form:form form_constraints:hidden
						anon_instances:hidden _nls_language:hidden
						@categories:off _page_order:hidden
						_description:hidden
						test_item.question.alt-1:label=XXX"
			}
			ot {
				set fc "test_item:test_item,question_type=ot,label=Open Text Exercise 
							form:form form_constraints:hidden 
							_description:hidden
							anon_instances:hidden _nls_language:hidden 
							@categories:off _page_order:hidden _title:label=Kurzüberschrift 
							test_item.question.alt-1:label=XXX"
			}
			sc {
				set fc "test_item:test_item,question_type=sc,nr_choices=[[my object] get_property -name nr_choices -default 3],label=#xowf.exercise_sc# 
					form:form form_constraints:hidden
					_description:hidden
					anon_instances:hidden _nls_language:omit
					@categories:off _page_order:hidden
					@_title:label=Kurzüberschrift
					test_item.question.alt-1:label=XXX"
			}
			matching {
				set fc "test_item:test_item,question_type=matching,nr_choices=[[my object] get_property -name nr_choices -default 3],label=Matching
					form:form form_constraints:hidden
					_description:hidden
					anon_instances:hidden _nls_language:omit
					@categories:off _page_order:hidden
					@_title:label=Kurzüberschrift
					test_item.question.alt-1:label=XXX"
			}
			gt {
				set fc "test_item:test_item,question_type=gap_text,label=Matching
					form:form form_constraints:hidden
					_description:hidden
					anon_instances:hidden _nls_language:omit
					@categories:off _page_order:hidden
					@_title:label=Kurzüberschrift
					test_item.question.alt-1:label=XXX"
			}
			slider {
				set fc "test_item:test_item,question_type=slider,label=Order
					form:form form_constraints:hidden
					_description:hidden
					anon_instances:hidden _nls_language:omit
					@categories:off _page_order:hidden
					@_title:label=Kurzüberschrift
					test_item.question.alt-1:label=XXX"
			}
			order {
				set fc "test_item:test_item,question_type=order,label=Order
					form:form form_constraints:hidden
					_description:hidden
					anon_instances:hidden _nls_language:omit
					@categories:off _page_order:hidden
					@_title:label=Kurzüberschrift
					test_item.question.alt-1:label=XXX"
			}
			default {
			my msg "this question type is not implemented!! $ia(exercise_form)"
			}		 
		}
		lappend fc "folderstruct:folderstruct"
		array unset ia
		set f [::xowiki::Form new -childof [self] -name test-item-form -title "Neue Aufgabe erstellen" \
		 -form {{<form>@_name@ @_title@ @_creator@ <br> @test_item@ @_description@ @form_constraints@ @_nls_language@ @anon_instances@ </form>} text/html} \
		 -anon_instances t \
		 -form_constraints $fc]
	}

	Context instproc ot_ratingform {name} {
	        set template [my get_property -name form_id]
		::xo::db::CrClass get_instance_from_db -item_id [string trimleft $template :]
	        set orig_question [$template get_property -name test_item]
		set question [lindex [lindex $orig_question 1] 1]
		set f [::xowiki::Form new -childof [self] -name ot-rate -title "Please rate the answers below" \
		-text {} \
		-form [subst {{<form> <table> <colgroup> <col width="120" /> <col width="80" /> </colgroup> 
			<tbody><tr><td><strong>Frage: </strong>$question</td></tr><tr></tr>
			<tr> <td style="width: 100%;">@rateitem1@ @rateitem1_scale@</td></tr> 
			<tr> <td>@rateitem2@ @rateitem2_scale@</td></tr> 
			<tr> <td>@rateitem3@ @rateitem3_scale@</td></tr> 
			</tbody> </table> </form>} text/html} ]\
		-anon_instances t \
		-form_constraints {{rateitem1:richtext, cols=60, rows=10, label=Andere abgegebene Lösung,disabled=true} 
		{rateitem1_scale:scale,n=10,label=Ihre Bewertung,horizontal=true,required=yes} 
		{rateitem2:richtext, cols=60, rows=10, label=Andere abgegebene Lösung,disabled=true} 
		{rateitem2_scale:scale,n=10,label=Ihre Bewertung,horizontal=true,required=yes} 
		{rateitem3:richtext, cols=60, rows=10, label=Andere abgegebene Lösung,disabled=true} 
		{rateitem3_scale:scale,n=10,label=Ihre Bewertung,horizontal=true,required=yes} @cr_fields:hidden}]
	}
	
	Context instproc wf_form {name} {
		#uses a form_loader to add form fields for rendering folderstructure
		#set form_id [[[my object] package_id] resolve_page_name /[my property p.form]]
		set form_id [::xo::db::CrClass get_instance_from_db -item_id [my property p.form]]
		set assignment [[my object] property a]
		array set ia [$form_id instance_attributes]
		my set_property -new 1 folder_id [$form_id set parent_id]
		my set_property -new 1 form_id $form_id
		my set_property -new 1 exercise_type $ia(question_type)
		my set_property -new 1 question_type instance
		set formelement [string trimleft $ia(form) "<form>"]
		
		set f [::xowiki::Form new -childof [self] -title "[$form_id title]" \
		-text {} \
		-form "<form>@child_resources@ <br> $formelement text/html" \
		-anon_instances t \
		-form_constraints "$ia(form_constraints) folderstruct:folderstruct child_resources:child_resources_light"]
	}
	
	Context instproc genericexamform {name} {
		my set_property -new 1 a [my set view]
		#my msg [my set view]

		 set f [::xowiki::Form new -childof [self] -name genericexamform -title "Übersichtsseite" \
		 -text {{<p>@folderstruct@ @child_resources@ <br />@genericexampage@</p>} text/html} \
		 -anon_instances t \
		 -form_constraints { {child_resources:child_resources_light} {genericexampage:genericexampage} {folderstruct:folderstruct} @cr_fields:hidden}]
	}
	Context instproc renameff {name} {
		#set formobj [[[my object] package_id] resolve_page_name /[my property current_form]]
		set formobj [::xo::db::CrClass get_instance_from_db -item_id [my property current_form]]
		foreach {fc form} [$formobj rename_formfields] {
			$formobj set_property form_constraints $fc
			$formobj set_property form $form
		}
		my set_property -new 1 folder_id [$formobj set parent_id]
		my set_property -new 1 form_id $formobj
		my set_property -new 1 question_type instance
		array set ia [$formobj instance_attributes]
		set formelement [string trimleft $ia(form) "<form>"]
		set f [::xowiki::Form new -childof [self] -title "[$formobj title]" \
		-text {} \
		-form "<form> @folderstruct@ @child_resources@ <br> $formelement text/html" \
		-anon_instances t \
		-form_constraints "$ia(form_constraints) folderstruct:folderstruct child_resources:child_resources_light"]
	}

  #some more customizations for xowf's view method
    WorkflowPage ad_instproc view {{content ""}} {
    Provide additional view modes:
       - edit: instead of viewing a page, it is opened in edit mode
       - view_user_input: show user the provided input
       - view_user_input_with_feedback: show user the provided input with feedback
  } {
    # The edit method calls view with an HTML content as argument.
    # To avoid a loop, when "view" is redirected to "edit",
    # we make sure that we only check the redirect on views
    # without content.
    ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
    
    if {[my is_wf_instance] && $content eq ""} {
      set ctx [::xowf::Context require [self]]
      set method [$ctx get_view_method]

      if {$method ne "" && $method ne "view"} {
        my instvar package_id
        #my msg "view redirects to $method in state [$ctx get_current_state]"
        switch -- $method {
          view_user_input {
            #my msg "calling edit with disable_input_fields=1"
            return [my edit -disable_input_fields 1]
            #return [$package_id call [self] edit [list -disable_input_fields 1]]
          }
          view_user_input_with_feedback {
            my set __feedback_mode 1
            #my msg "calling edit with disable_input_fields=1 user_input_with_fb"
            return [my edit -disable_input_fields 1]
            #return [$package_id call [self] edit [list -disable_input_fields 1]]
          }
	  view_user_input_with_partial_feedback {
	  #my msg "calling edit with fb mode partial"
            my set __feedback_mode_partial 1
            #my msg "calling edit with disable_input_fields=1"
            return [my edit]
            #return [$package_id call [self] edit [list -disable_input_fields 1]]
          }
	  view_exam_question {
	  if {![my get_property -name started]} {
		#display feedback only after exam has been submitted 
		#my set __feedback_mode 1
		return [my edit -disable_input_fields 1 ]
	  } else {
		return [my edit]
	  }
	  }
          default {
            #my msg "calling $method"
            return [$package_id invoke -method $method]
          }
        }
      } 
    }
    next
  }
  
    WorkflowPage instproc create-or-use args {
    #my msg "instance = [my is_wf_instance], wf=[my is_wf]"
    ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
    if {[my is_wf]} {
      my instvar package_id
      #
      # In a first step, we call "allocate". Allocate is an Action
      # defined in a workflow, which is called *before* the workflow
      # instance is created. Via allocate, it is e.g. possible to
      # provide a computed name for the workflow instance from within
      # the workflow definition.
      #
      set ctx [::xowf::Context require [self]]
      my activate $ctx allocate
      
      # Check, if allocate has provided a name:
      set name [my property name ""]
      if {$name ne ""} {
	# Ok, a name was provided. Check if an instance with this name
	# exists in the current folder.
	set default_lang [my lang]
	set isxolrn [expr {[[my package_id] package_key] eq "xolrn_excs"}]
        set parent_id [my query_parameter "parent_id" [$package_id folder_id]]
	$package_id get_lang_and_name -default_lang $default_lang -name $name lang stripped_name
	#ignore language prefixes for xolrn
	if {$isxolrn} {
		set id [::xo::db::CrClass lookup -name $stripped_name -parent_id $parent_id]
		if {$id != 0} {
		  # The instance exists already
		  return [$package_id returnredirect \
			      [export_vars -base [$package_id pretty_link -parent_id $parent_id $stripped_name] \
				   [list return_url template_file]]]
		} 
		  return [next -name $stripped_name]
		} else {
		set id [::xo::db::CrClass lookup -name $lang:$stripped_name -parent_id $parent_id]
		#my msg "lookup of $lang:$stripped_name returned $id, default-lang([my name])=$default_lang [my nls_language]"
		if {$id != 0} {
		  # The instance exists already
		  return [$package_id returnredirect \
			      [export_vars -base [$package_id pretty_link -parent_id $parent_id $lang:$stripped_name] \
				   [list return_url template_file]]]
		} else {
		  if {$lang ne $default_lang} {
		    set nls_language [my get_nls_language_from_lang $lang]
		  } else {
		    set nls_language [my nls_language]
		  }
		  #my msg "We want to create $lang:$stripped_name"
		  return [next -name $lang:$stripped_name -nls_language $nls_language]
		}
	}
      }
    }
    next
  }
  
	#we don't really want to waste performance on initalizing exercises, check
    WorkflowPage instproc initialize_loaded_object {} {
      next
      ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
      #mmo: safety checks (I leave them here for now since there have been problems with initializing lecturecast objects)
      if {[my is_wf_instance] && [my exists package_id]} {
          my instvar package_id
          if {![my isobject $package_id]} {
              # ::xo::Package initialize -package_id [my package_id]
              if {[ns_conn isconnected]} {
                  ::xowiki::Package initialize -package_id $package_id
              } else {
                  ::xowiki::Package initialize -package_id $package_id -init_url false -url [site_node::get_url_from_object_id -object_id $package_id] -user_id [acs_magic_object "sys_account"] -actual_query ""
              }
          }
	  #do not initialize instances of xolrn-questions
	  array set ia [my instance_attributes]
	  if {![info exists ia(question_type)] && ![info exists ia(isexercise)]} {
          #my msg "xowf: doing init for [my set name]"
	  my initialize
	  }
	  array unset ia
      }
  }
  
#xolrn core methods providing feedback, score calculation, exercise correction etc

  WorkflowPage ad_instproc post_process_form_fields {form_fields} {
  } {
    ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
      if {[my exists __feedback_mode] || [my exists __feedback_mode_partial]} {
      #
      # Provide feedback for every alternative
      #
      foreach f $form_fields {

	#if {[$f name] eq "folderstruct" || [$f name] eq "child_resources" || ![string match _* [$f name]]} continue
	if {![string match v-* [$f name]]} continue
		set is_correct [$f answer_is_correct]
		set ex_type [my get_property -name exercise_type]
	if {$ex_type eq "slider" || $ex_type eq "qt" || $ex_type eq "order"} {
		set is_correct [my answer_is_correct]
	}
	#my msg "[$f name]: correct? [$f answer_is_correct]"
        switch -- $is_correct {
           0 { continue }
          -1 { set result "incorrect"}
           1 { set result "correct"  }
        }
	#my msg "[$f set value] - [$f set answer] - $result"
        $f form_widget_CSSclass $result
        $f set evaluated_answer_result $result
      #my msg "processing [$f name] $result"
        set feedback ""
        if {[$f exists feedback_answer_$result]} {
          set feedback [$f feedback_answer_$result]
        } else {
          set feedback [_ xowf.answer_$result]
}
        $f help_text $feedback
      }
    }
  }

  WorkflowPage ad_instproc post_process_dom_tree {dom_doc dom_root form_fields} {
    post-process form in edit mode to provide feedback in feedback mode
  } {
      ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
    #my msg "post_process_dom_tree: [my serialize]"
    if {[my exists __feedback_mode_partial]} {
        my unset __feedback_mode_partial
        ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css 
        set form [lindex [$dom_root selectNodes "//form"] 0]
        $form setAttribute class "[$form getAttribute class] feedback"
        set i 1
        foreach f $form_fields {
            #my msg "formfieldname: [$f name]"
            if {[$f exists __rendered]} continue
            if {[$f exists evaluated_answer_result]} {
                #compound exercises have a prefix
		if {[my get_template_parameter question_type] eq "sc"} {
                        set ffname [$f value]
                    } else {
		        set ffname [$f name]
		    }
               
                set cleanvalue ""
                regexp {.*_(.*)} $ffname match cleanvalue
                if {$cleanvalue ne ""} {set ffname $cleanvalue}
                #if the answer was checked and is false and we are in adaptive mode, write partial feedback
                #my msg "name: $ffname eq value: [$f value]"
		set qt [my get_template_parameter question_type]
                if {$ffname eq [$f value] } {
                    if {$qt eq "order"} {
                        set search_string "//form//ul\[@id='ul_order_question'\]/li\[@value='v-$i'\]"
                        incr i
                    } elseif {$qt eq "sc"} {
                        set search_string "//form//*\[@value='[$f value]'\]"
                    } elseif {$qt eq "mc"} {
		         set search_string "//form//*\[@name='[$f name]'\]"
		    } else {
			set search_string "//form//*\[@name='[$f name]'\]"
		    }
                    foreach n [$dom_root selectNodes $search_string] {
                        set oldCSSClass [expr {[$n hasAttribute class] ? [$n getAttribute class] : ""}]
                        #my msg "$oldCSSClass oldCSSClass"
                        $n setAttribute class [string trim "$oldCSSClass [$f form_widget_CSSclass]"]
                        $f form_widget_CSSclass [$f set evaluated_answer_result]
                        set helpText [$f help_text]
                        #my msg "n_as_xml: [$n asXML]"
                        #my msg "helpText: $helpText"
                        if {$helpText ne ""} {
                            set divNode [$dom_doc createElement div]
                            $divNode setAttribute class [$f form_widget_CSSclass]
                            $divNode appendChild [$dom_doc createTextNode $helpText]
                            #my msg "divnode $divNode"
                            set fb ""
                            if {[my get_template_parameter exercise_type] eq "matching" || [my get_template_parameter exercise_type] eq "order"} {
                                #for matching it's necessary to put the feedback under the checkbox
                                set fb $n
                            } else {
			        set fb_parent [[$n parentNode] nextSibling]
                                if {$fb_parent eq ""} {
				  set fb $n
				} else {
				  set fb [$fb_parent nextSibling]
                                #fallback if something goes wrong
                                }
				if {$fb eq ""} {set fb $n}
                            }
                            #my msg "punkt: [$fb asXML]"
                            #[$n parentNode] insertBefore $divNode [$n nextSibling]
                            $fb appendChild $divNode
                        }
                    }
                }
            }
        }
	}
	
	# In feedback mode, we set the CSS class to correct or incorrect
    if {[my exists __feedback_mode]} {
        my unset __feedback_mode
        ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css 
        set form [lindex [$dom_root selectNodes "//form"] 0]
        $form setAttribute class "[$form getAttribute class] feedback"

        #
        # In cases, where the HTML exercise was given, we process the HTML
        # to flag the result. 
        #
        # TODO: what should we do with the feedback. util-user-message not optimal...
        #
        set i 1
        foreach f $form_fields {
	    if {[$f name] eq "folderstruct" || [$f name] eq "child_resources"} continue
            if {[$f exists __rendered]} continue
            if {[$f exists evaluated_answer_result]} {
                set result [$f set evaluated_answer_result]
                #my msg "f name [$f name]"
		set qt [my get_property -name exercise_type]
                if {$qt eq "order"} {
                    set search_string "//form//ul\[@id='ul_order_question'\]/li\[@value='v-$i'\]"
                    incr i
		} elseif {$qt eq "sc"} {
                        set search_string "//form//*\[@value='[$f value]'\]"
                    } elseif {$qt eq "mc"} {
		         set search_string "//form//*\[@name='[$f name]'\]"
		    } else {
			set search_string "//form//*\[@name='[$f name]'\]"
		    }
                if {$qt ne "gt"} {
		#gaptext questions are excluded for now
                foreach n [$dom_root selectNodes $search_string] {
                    #my msg "feedback: [$n asXML]"
                    set oldCSSClass [expr {[$n hasAttribute class] ? [$n getAttribute class] : ""}]
                    $n setAttribute class [string trim "$oldCSSClass [$f form_widget_CSSclass]"]
                    $f form_widget_CSSclass $result
            
                    set helpText [$f help_text]
                    if {$helpText ne ""} {
                        set divNode [$dom_doc createElement div]
                        $divNode setAttribute class [$f form_widget_CSSclass]
                        $divNode appendChild [$dom_doc createTextNode $helpText]
                        #my msg "n [$n asXML]"
                        set fb ""
                        if {[my get_template_parameter exercise_type] eq "matching" || [my get_template_parameter exercise_type] eq "order"} {
                            #for matching it's necessary to put the feedback under the checkbox
                            set fb $n
                        } else {
			        set fb_parent [[$n parentNode] nextSibling]
                                if {$fb_parent eq ""} {
				  set fb $n
				} else {
				  set fb [$fb_parent nextSibling]
                                #fallback if something goes wrong
                                }
				if {$fb eq ""} {set fb $n}
                        }
                        #set fb [[[$n parentNode] nextSibling] nextSibling]
                        [$n parentNode] insertBefore $divNode [$n nextSibling]
                        #util_user_message -message "field [$f name], value [$f value]: $helpText (post_process_dom_tree)"
                        $fb appendChild $divNode
                    }
                }
		}
            }
        }
        #
        # Provide feedback for the whole exercise
        #
        if {[my answer_is_correct]} {
            set feedback [my get_testitem_parameter feedback_correct]
        } else {
            set feedback [my get_testitem_parameter feedback_incorrect]
        }
	  
	    if {[my get_template_parameter exercise_type] eq "gt"} {
            #display feedback
            set feedback [my get_testitem_parameter fullgaptext]
        }
        if {[my get_property -name exercise_type -default ""] eq "ot"} {
            if {[my get_property -name qvar -default ""] ne ""} {
                set feedback "Diese Antwort hat eine Bewertung von [format %.2f [expr {[my get_property -name qvar]*10.0}]] von 10."
            } else {
                set feedback ""
            }
        }
        if {$feedback ne ""} {
            $dom_root appendFromScript {
		html::br
                html::div -class feedback {
                    html::t -disableOutputEscaping "<br><p>Feedback: <br>$feedback</p>"
                }
            }
        }
    }
    
    #add score to the form
    if {[my get_property -name isexam -default 0] ne 0 || [my get_template_parameter question_type] ne "exam"} {
        set divNode [$dom_doc createElement div]
        if {[my get_property -name adaptive_score -default ""] ne "" && [my get_property -name score -default ""] ne "" && [my get_property -name adaptive_score -default ""] ne -1 && [my get_property -name score -default ""] ne -1} { 
            $divNode appendChild [$dom_doc createTextNode "Punkte: adaptive_score: [my get_property -name adaptive_score -default ""] simple_score: [my get_property -name score -default ""]"]
        } elseif {[my get_property -name score -default ""] ne "" && [my get_property -name score -default ""] ne -1} {
            $divNode appendChild [$dom_doc createTextNode "Punkte: simple_score: [my get_property -name score -default ""]"]
        }
        set form_node [$dom_root selectNodes "//form"]
        set button_node [$form_node lastChild]
        $dom_root insertBefore $divNode $button_node
        #my msg "ich bin hier: [$dom_doc asXML]"
    }
    
    #problem: the order of the shuffled questions needs to be stored
    #-> we shuffle once, store the order in the page and retrieve it every time the page is opened again
    if {[my get_testitem_parameter shuffle] eq "yes" && ![my get_property -name isexam -default 0]} {
        #my msg "param: shuffled yes"
	#match mc and sc exercises
        if {[string match ?c [my get_property -name exercise_type -default ""]]} {
            if {[my get_property -name shuffled_order -default ""] eq ""} {
                        set form [lindex [$dom_root selectNodes "//form//*\[@class='mchoice'\]/tbody"] 0]
                        #$form setAttribute class "[$form getAttribute class] feedback"
                        set trs [$form selectNodes "//tr\[position()>1\]"]
                    
                        for {set i 1} {$i <[llength $trs]} {incr i} {
                            set j [expr {int(rand()*[llength $trs])}]
                            set tmp [lindex $trs $i]
                            lset trs $i [lindex $trs $j]
                            lset trs $j $tmp	    
                        }
                        #since domNodes are only references to html elements, we need to clone them 
                        foreach tr $trs {
                            set newtrs [$tr cloneNode -deep]
                            $tr delete 
                            $form appendChild $newtrs
                        }
                        #store the precendence order
                        set order [list]
                        set tds [$form selectNodes "//form//*\[@class='mchoice'\]/tbody/tr/td/input"]
                        foreach td $tds {
                            lappend order [$td getAttribute value]
                        }
                        my set_property -new 1 shuffled_order $order
			#__wfi will cause a mess if we don't clear them first
			my array unset __wfi
                        set s [my find_slot instance_attributes]
                        my update_attribute_from_slot $s [my instance_attributes] 
			
            } else {
                #precedence of shuffled items has been stored, use these to build the answers in the correct order
                set order [my get_property -name shuffled_order]
                set form [lindex [$dom_root selectNodes "//form//*\[@class='mchoice'\]/tbody"] 0]
                
                set ordered_trs [list]
                foreach o $order {
                    set node [$form selectNodes "//form//*\[@class='mchoice'\]/tbody/tr/td/input\[@value='$o'\]"]
                    lappend ordered_trs [[[$node parentNode] parentNode] cloneNode -deep]
                    [[$node parentNode] parentNode]  delete
                }
            
                foreach otr $ordered_trs {
                    $form appendChild $otr
                }
            }
        } elseif {[my get_property -name exercise_type] eq "order"} {
            set form [lindex [$dom_root selectNodes "//form//*\[@class='order'\]"] 0]
            if {[my get_property -name shuffled_order -default ""] eq ""} {
                set ul [$form selectNodes "//ul\[@id='ul_order_question'\]"]
                set orig_list [list]
		#delete old nodes
                foreach node [$ul selectNodes "//input"] {
                    set source_string [$node asXML]
                    if {[regexp "input name=\"v.*\".*value=\"(.*)\"" $source_string all_selected pos_of_li_element _]} {
                        lappend orig_list [$node asXML]
                        $node delete
                    }
                }
                
                #my msg "orig_list before shuffling: $orig_list"
                #shuffling                
                 for {set i 1} {$i < [llength $orig_list]} {incr i} {
                      set j [expr {int(rand()*[llength $orig_list])}]
                      set tmp [lindex $orig_list $i]
                      lset orig_list $i [lindex $orig_list $j]
                     lset orig_list $j $tmp	    
                 }
	
                #my msg "orig_list after shuffling: $orig_list"
                
                for {set i 0} {$i < [llength $orig_list]} {incr i} {
                    if {[regexp "input name=\"v.*\".*value=\"(.*)\"" [lindex $orig_list $i] all_selected pos_of_li_element _]} {
                        #my msg "pos found: $pos_of_li_element"
                        regsub $pos_of_li_element [lindex $orig_list $i] "v-[expr {$i+1}]" tmp
                        set search_string "v-$pos_of_li_element ---- $tmp"
                        lset orig_list $i $tmp
                    }
                }
                #my msg "orig_list after setting: $orig_list"
                
                set xml ""
                foreach o $orig_list {
                    $ul appendXML $o
                }
                
                my set_property -new 1 shuffled_order $orig_list
		my array unset __wfi
                set s [my find_slot instance_attributes]
                my update_attribute_from_slot $s [my instance_attributes]
            }
            
            #get the order out of the hidden fields
            set order_string [list]
            foreach input_element [$form selectNodes "//input"] {
                set source_string [$input_element asXML]
                if {[regexp "input name=\"v(.*)\" type=\"hidden\".*value=\"(.*)\"" $source_string all_selected name_of_li_element pos_of_li_element _]} {
                    #my msg "name_of_li_element: $name_of_li_element - position found: $pos_of_li_element"
                    set index [expr {$name_of_li_element-1}]
                    set order_string [linsert $order_string $index $pos_of_li_element]
                }
                
            }
            #my msg "order_string: $order_string"
            
            #get the li elements out of the form and delete them
            set ordered_li [list]
            set ul [$form selectNodes "//ul\[@id='ul_order_question'\]"]
            #my msg "ul: [$ul asXML]"
            foreach o $order_string {
                #my msg "o: $o"
                set node [$ul selectNodes "//li\[@value='$o'\]"]
                #my msg "node found: [$node asXML]"
                lappend ordered_li [$node cloneNode -deep]
                $node delete
                
            }
            #append the li elements in the correct order to the form
            foreach o $ordered_li {
                $ul appendChild $o
            }
        }
    }
		
    #display link to next question, insert it next to submit buttons
    set buttondiv [$dom_root selectNodes "//form/div\[@class='form-button'\]"]
    set i 1
    foreach question [ad_get_client_property module precedence] {
        regexp {...(.*)____*} [my name] match prettyname
        if {[info exists prettyname]} {
        #my msg "$prettyname prettyname - $question question"
        if {[string match *$prettyname* [lindex $question 0]]} {
            #build link to next question
            set nextlink [lindex [ad_get_client_property module precedence] $i]
            dom parse -html "<p align='right'><a href='$nextlink'>Nächste Frage</a></p>" nextlink_clean
            set nextlink_root [$nextlink_clean documentElement]
            $buttondiv appendChild $nextlink_root
            break
            }
        }
        incr i
    }

    #my msg "[$a asXML] waa"
    #regsub -all {&} $nextlink %26 nextlink_clean
    #$buttondiv appendXML "<p align='right'><a href='$nextlink_clean'>nächste Frage</a></p>"
    #my msg "[$buttondiv asXML]"
    
    #unset ad_redirect variable
    #ad_set_client_property module return_url ""
}

  WorkflowPage ad_instproc calculate_score {} {
  determines the score for this item
  } {
        ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
        set adaptive [expr {[my get_testitem_parameter adaptive] eq yes}]
        
        if {$adaptive} {
        #get old score
        #several cases here: primitive scoring, adaptive mode, test sequence mode
            set attempts [my get_property -name attempts -default 0]
            set penalty [my get_testitem_parameter penalty]
            if {$penalty eq ""} {set penalty 0}
            set score [my calc_primitive_score]
            #my msg "adaptive mode attempts $score $attempts $penalty"
            set adaptive_score [expr {$score - ($attempts -1) * $penalty} ]
            my set score $score
            my set adaptive_score $adaptive_score
            #my msg "mein adaptive: $adaptive_score"
            #todo: enable custom max score
            if {$adaptive_score < 0} {set adaptive_score 0}
            #my msg "adaptive score $adaptive_score bei $attempts versuchen"
            #attempts are incremented in the wf!
            #my set_property -new 1 attempts [incr attempts]
            
        } else {
            set score [my calc_primitive_score]
            my set score $score
            #my msg "primitive scoring: result: $score"
        }
        
        #add score entry in the form for summing up
        
        return $score
  }
  
  WorkflowPage ad_instproc calc_primitive_score {} {
  } {
      ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
	  #primitive scoring
	  set score 0.0
	  set fields [my instantiated_form_fields]
	  set answer_count 0
	  set correct_counter 0
	  set answer_correct 0
	  set correct_marked 0
	  set wrong_marked 0
	  foreach f $fields {
	  if {[string match *v-* [$f name]]} {
	      incr answer_count
	      #my msg "scoring formfield serialized: [$f serialize]; (f value): [$f set value]; (f answer): [$f set answer];"
	      if {[$f answer_is_correct] == 1} {
	          incr correct_counter
	          #set score [expr {$score + 1.0/[llength $fields]} ]
	          #my msg "primitive: [$f name] is correct - score: $score"
	      }
	      #for mc_scoring methods we need special values
	      set x [my get_property -name form_id]
	      if {[my get_from_template exercise_type] eq "mc"} {
              if {[$f set answer] ne ""} {
                  incr answer_correct
                  if {[$f set answer] eq [$f set value]} {
                      incr correct_marked
                  }
              }
              if {[$f set answer] eq "" && [$f set value] ne ""} {
                  incr wrong_marked
              }
          }
	  }
	  }
 
	  if {[my get_template_parameter exercise_type] eq "order"} {
	      #divide by 2 because we have hidden fields, which will be set by the javascript code
	      set answer_count [expr {$answer_count/2}]
	  }
	  
	  #set wrong_marked [expr {$answer_count - $correct_counter}]
	  set scoring_method [my get_testitem_parameter scoring]
	  #my msg "trenner: answer_count: $answer_count; answer_correct: $answer_correct; correct_counter: $correct_counter; correct_marked: $correct_marked; wrong_marked: $wrong_marked; scoring_method: $scoring_method;"
	  
	  #wi_score_multiplechoice and wi_score_multiplechoice_mix are only for mc questions
	  switch $scoring_method {
	      wi_score_multiplechoice {
	            #Hansen Schema mit Sonderregel 1-Falsches
	          	set wrong [expr {$answer_count-$answer_correct}]
	          	set bonus [expr {$answer_correct ? 1.0/$answer_correct : 0.0}]
                if { $wrong == 1 } {
                    set malus 0.5
                } elseif { $wrong == 0 } {
                    set malus 0
                } else {
                    set malus [expr {1.0/$wrong}]
                }                
                set score [expr {$correct_marked*$bonus - $wrong_marked*$malus}]
	      }
	      wi_score_multiplechoice_mix {
	            #Hansen Schema mit Sonderregeln 1-Falsches + 1-Richtiges
                set wrong [expr {$answer_count-$answer_correct}]
                set bonus [expr {$answer_correct ? 1.0/$answer_correct : 0.0}]
                if { $answer_correct == 1 } {
                    set malus 1
                } else {
                    if { $wrong == 1 } {
                        set malus 0.5
                    } elseif { $wrong == 0 } {
                        set malus 0
                    } else {
                        set malus [expr {1.0/$wrong}]
                    }
                }
                set score [expr {$correct_marked*$bonus - $wrong_marked*$malus}]
          }
	      score_fractionpoints {
	            #Teilpunkte errechnen sich aus (Anzahl der richtig markierten) * ( % für eine Alternative )
	          	set score [expr (1.0/$answer_count) * $correct_counter]
	      }
	      score_fractionpoints_sub {
                #Teilpunkte wie bei score_fractionpoints nur mit Abzügen für falsch markierte Alternativen
                set fraction [expr {1.0/$answer_count}]
                set wrong_counter [expr $answer_count - $correct_counter]
                set score [expr (($fraction * $correct_counter) - ($fraction * $wrong_counter))]
	      }
	      default {
	          if {$answer_count eq $correct_counter} {
	              set score 1
	          }
	      }
	  }
	  if { $score < 0 } { 
	      set score 0 
      }
	  #my msg "SCORING: scoring_method: [my get_testitem_parameter scoring]; score: $score;"	  
	  return $score
  }
  
  WorkflowPage ad_instproc get_testitem_parameter {param} {
   retrieves a parameter from a test_item
  } {
        ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
        set i 0
	foreach f [my get_template_parameter test_item] {
		set out ""
		regexp {\.(.*)} $f match out
		if {$out eq $param} {
			return [lindex [my get_template_parameter test_item] [incr i]]
		}
		incr i
	}
  }

  WorkflowPage ad_instproc has_solution {} {
  Do we need answer checking, or are we working on a question without solution
  } {
      ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
  set template_obj [my get_template_object]
  return [$template_obj get_property -name has_solution]
  }

  WorkflowPage ad_instproc get_template_parameter {param} {
  Get a parameter from the template xowiki::FormPage
  } {
        set form_id [my get_property -name form_id -default 0]
	if {$form_id == 0} {return 0} else { ::xo::db::CrClass get_instance_from_db -item_id [string trimleft $form_id :] } 
	if {[$form_id istype ::xowiki::FormPage]} {
	return [$form_id get_property -name $param]
	else {
	return 0
	}
  }
}

  WorkflowPage ad_instproc clear_form_selections {} {
 } {
     ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
	foreach f [my instantiated_form_fields] {
	if {[string match v-* [$f name] ]} {
	  #my msg "[$f name] - [$f value]"
		$f set value ""
		my set_property [$f name] ""
	} elseif {[string match *___v-* [$f name]]} {
		$f set value ""
		my set_property [$f name] ""
	}
	}
}
  WorkflowPage ad_instproc correct_checkbox_exercise {ff} {
checks correctness of exercises using checkboxes (mc, sc, 
} {
    ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
	set correct 0
    if {[my get_from_template auto_correct] != false} {
        foreach f $ff {
	if {[$f name] eq "folderstruct" || [$f name] eq "child_resources"} {continue}
            #my msg "ffie [$f serialize]"
            #my msg "checking correctness [$f name] [$f info class] answer?[$f exists answer] -- [my get_from_template auto_correct]"
            #my msg "formfield: [$f serialize]"
            if {[$f exists answer]} {
                #my msg "answer: [$f set answer] - answer_correct: [$f answer_is_correct]"
                if {[$f answer_is_correct] != 1} {
                    #my msg "checking correctness [$f name] failed ([$f answer_is_correct])"
                    set correct -1
                    break
                }
                set correct 1
            }
        }
    }
    return $correct
}

  WorkflowPage ad_instproc correct_gaptext_exercise {ff} {
} {
    ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
    foreach f $ff {
	if {[$f name] eq "folderstruct" || [$f name] eq "child_resources"} {continue}
	set useranswer [$f value]
        if {[$f exists answer]} {
            set answer [regsub -all "%20" [$f set answer] " "]
            set answerchoices [split $answer \;]
            #multiple answers can be specified with an ;
            foreach ans $answerchoices {
		set iscorrect -1
                #ns_log notice "answer #$ans# useranswer #$useranswer#"
                if {![string compare $ans $useranswer]} {
                       set iscorrect 1
		       break
                }
            }
        }
    }
        return $iscorrect
}

  WorkflowPage ad_instproc correct_slider_exercise {ff} {
} {
    ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
      foreach f $ff {
      if {[$f name] eq "folderstruct" || [$f name] eq "child_resources"} {continue}
      #my msg "answer [$f set answer] = [$f value]"
      set useranswer [$f value]
      if {[$f exists answer]} {
        set ans [split [$f set answer] \;]
        set answer [lindex $ans 0]
        set tolerance [lindex $ans 1]
        if {$answer == $useranswer} {
        return 1
        } elseif {$useranswer < $answer} {
          if {$useranswer > [expr {$answer - $tolerance}]} {
            return 1
            }
          } elseif {$useranswer > $answer} {
          if {$useranswer < [expr {$answer + $tolerance}]} {
            return 1
          }
        }}
      }
      return 0
}

  WorkflowPage ad_instproc correct_order_exercise {ff} {
    checks correctness of order exercises
} {
    ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
    set correct 0
    set correct_count 0
    set wrong_count 0
    set cnt 0
    foreach f $ff {
    if {![string match v-* [$f value]]} {continue}
        incr cnt
        if {[$f answer_is_correct] eq 0} {
            incr wrong_count
        }
        if {[$f answer_is_correct] eq 1} {
            incr correct_count
        }
    }
    
    #my msg "wrong_count: $wrong_count - correct_count: $correct_count - CORRECT: $correct"
	
    if {$correct_count == $cnt} {
    return 1
    } else {
    return -1
    }
}

  WorkflowPage ad_instproc answer_is_correct {} {
    Check, if answer is correct based on "answer" attribute of form fields
    and provided user input.
  } {
      ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
    set form_id [string trimleft [my get_property -name form_id] ::]
    set template [::xo::db::CrClass get_instance_from_db -item_id $form_id]
    switch -- [$template get_property -name question_type] {
    mc {
		my correct_checkbox_exercise [my instantiated_form_fields]
	}
	sc {
		my correct_checkbox_exercise [my instantiated_form_fields]
	}
    matching {
        my correct_checkbox_exercise [my instantiated_form_fields]
    }
	gt {
	    my correct_gaptext_exercise [my instantiated_form_fields]
	}
    slider {
        my correct_slider_exercise [my instantiated_form_fields]
    }
    order {
        my correct_order_exercise [my instantiated_form_fields]
    }
    section {
        dom parse -simple -html [my get_template_parameter form] doc
        $doc documentElement root
        set nodes [$root selectNodes "//form/ol/li"]
        foreach n $nodes {
          #get all formfields belonging to a specific question
          set ff [my instantiated_section_ff [$n getAttribute class]]
          switch -- [$n getAttribute id] {
            mc {
              if {[my correct_checkbox_exercise $ff] == -1} {
              return -1
              }
            }
            sc {
              if {[my correct_checkbox_exercise $ff] == -1} {
              return -1
              }
            }
            matching {
              if {[my correct_checkbox_exercise $ff] == 0} {
              return 0
              }
            }
            gt {
              if {[my correct_gaptext_exercise $ff] == 0} {
              return 0
              }
            }
            slider {
            if {[my correct_slider_exercise $ff] == 0} {
              return 0
            }
            }
          }
        }
        #everything is fine, returning 1
        return 1
    }
    ot {
	#no autocorrect for opentext
	return 1
    }
    default {
    my msg "unknown question type, not implemented yet [$template get_property -name question_type]"
    return 0
    }
    }
  }
  
  WorkflowPage instproc instantiated_section_ff {id} {
  #get all formfields for a question (useful in a compound exercise with multiple questions)
  ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
  foreach ff [lindex [my field_names_from_form] 1] {
      if {[string match *$id* $ff]} {
        lappend field_names $ff
      }
    }
    set form_fields [my create_form_fields $field_names]
    my load_values_into_form_fields $form_fields
    return $form_fields
  }
  
  WorkflowPage instproc get_list_parameter {param l} {
	set i 0
	foreach item $l {
		incr i
		if {[string match *$param $item]} {
			return [lindex $l $i]
		}
	}
  }

  
# procs for collaborative filtering

  WorkflowPage ad_instproc get_answers {} {
  } {
      ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
  set form [my page_template]
  set shortname [my name]
  regexp {(.*)___(.*)$} [my name] match shortname
  set form_fields [::xowiki::FormPage get_table_form_fields \
    -base_item $form \
    -field_names answer,qvar,evar,bvar,revision_id,ratings \
    -form_constraints " "]
  array set wc {tcl true h "" vars "" sql ""}
  set items [::xowiki::FormPage get_form_entries -base_item_ids $form \
    -package_id [my package_id] \
    -form_fields $form_fields \
    -publish_status "all" \
    -always_queried_attributes {_revision_id _item_id _page_id _object_id _creator} \
    -h_where [array get wc] \
    -initialize false \
    -extra_where_clause " and bt.state = 'closed' and name like '%${shortname}\\\\_\\\\_\\\\_%' "]
	#ignorieren aller items im initial status verhindert das eigene item zurückzubekommen
	#shortname stellt sicher dass nur Antworten zu dieser Frage zurückgegeben werden
	#items ist ein "ordered composite"
	ns_log notice "xolrn_cf: got [llength [$items children]]"
	#foreach item [$items children] {
	#	ns_log notice "xolrn_cf: one item [$item set item_id]"
	#}
	return $items
	}
  
  WorkflowPage ad_instproc get_answers_for_template {} {
  } { 
#todo: implement subcases for other workflow types
  set form [string trimleft [[my package_id] resolve_page_name "wf-opentext-cf"] :]
  set shortname [my name]
  regexp {(.*)___(.*)$} [my name] match shortname
  set form_fields [::xowiki::FormPage get_table_form_fields \
    -base_item $form \
    -field_names answer,qvar,evar,bvar,revision_id,ratings \
    -form_constraints " "]
  array set wc {tcl true h "" vars "" sql ""}
  #my msg $shortname
  set items [::xowiki::FormPage get_form_entries -base_item_ids $form \
    -package_id [my package_id] \
    -form_fields $form_fields \
    -publish_status "all" \
    -always_queried_attributes {_revision_id _item_id _page_id _object_id _creator} \
    -h_where [array get wc] \
    -initialize false \
    -extra_where_clause " and bt.state != 'initial' and name like '%${shortname}\\\\_\\\\_\\\\_%' "]
	#ns_log notice "xolrn_cf: got [llength [$items children]]"
	return $items
	}
  
  WorkflowPage ad_instproc recalc_bvar {} {
  } {
    #recalc the bvar in a recalculation iteration of a changed qvar
    set sum 0.0
    set answerstorate 3.0
    set fetched_items [my get_property -name fetched_item_ids]
    if {$fetched_items ne 0} {
	foreach item $fetched_items {
	if {![catch {::xo::db::CrClass get_instance_from_db -item_id $item} dev]} {
			continue
		}
		set wform [my get_property -name rateitem[incr k]_scale]
		set qitem [$item get_property -name qvar]
		set w [expr {$wform / 10.0}]
		if {[expr {1.0-$qitem }] > $qitem } {
			set maxdivq [expr {1.0-$qitem}]
		} else {
			set maxdivq $qitem
		}
		#vorzeichen aendern wenn negativ
		set dev [expr {$w-$qitem }]
		if {$dev < 0} {
	ssh		set dev [expr -$dev]
		}
			set sum [expr {$sum + 0.0 + ($dev) / ($maxdivq)}]
	}
	set bvar  [expr {1.0- (1.0 / $answerstorate) * $sum}]
	return $bvar
	} else {return [my get_property -name bvar]}
	}
  
  WorkflowPage ad_instproc recalc_basevalues {items exclude level} {
    } {
    ns_log notice "recursion level is $level for $exclude"
	if {$level > 2} {return 0}
	incr level
	lappend exclude [cache get excludeitems]
        #recalc the qvar in a recalculation iteration of a changed qvar
	#do not recalculate the item whose qvar we just changed ($exclude)
	set sum 0.0
	set answerstorate 3.0
	# calculate basiswert for own answer
	set user_id ""
       #do not recalculate qvar for sample answers
       #my msg "doing recalc for $items"
       regexp {.*___(.*)} [my set name] match userid
       set user_exists [db_string bla "select username from users where user_id = :userid;" -default 0]
	if {$user_exists eq 0} {
		ns_log notice "[my set name] will not be recalculated!"
	} else {

  foreach item $items {
    set wform [my get_property -name rateitem[incr k]_scale]
    if {$wform ne ""} {
    set qitem [$item get_property -name qvar]
    set w [expr {$wform / 10.0}]
    if {[expr {1.0-$qitem }] > $qitem } {
        set maxdivq [expr {1.0-$qitem}]
    } else {
	set maxdivq $qitem
    }

    #vorzeichen aendern wenn negativ
    set dev [expr {$w-$qitem }]
    if {$dev < 0} {
      set dev [expr -$dev]
    }

    ns_log notice "xolrn_cf: doing calc_basevalues for [$item set item_id] - [$item set name] - dev=$dev, qitem=$qitem, w=$w, maxdivq=$maxdivq"
    #calculate sum
    set sum [expr {$sum + 0.0 + ($dev) / ($maxdivq)}]
  }
  }

  set bvar  [expr {1.0- (1.0 / $answerstorate) * $sum}]
  ns_log notice "xolrn_cf: sum=$sum, bvar=$bvar item=[my item_id]"
   #do NOT change the evar here!
   my set_property -new 1 qvar $bvar
   set s [my find_slot instance_attributes]
   my update_attribute_from_slot $s [$item instance_attributes]
   my save
  }
  #update evaluation values of rated answers
  foreach item $items {
	set qwsum 0.0
	set qsum 0.0
       #get current ratings of the item
       #calculate qwsum
       set user_id ""
       #do not recalculate qvar for sample answers
       regexp {.*___(.*)} [$item set name] match userid
       set user_exists [db_string bla "select username from users where user_id = :userid;" -default 0]
	if {$user_exists eq 0} {
		ns_log notice "[$item set name] will not be recalculated!"
	} else {
    set ratings [$item get_property -name ratings]
    ns_log notice "xolrn_cf: ### recalc evar for [$item set item_id] number of ratings= [llength ratings]"
    set ratings_valid ""
	  
    foreach rating $ratings {
      set solution_id ""
      ns_log notice "xolrn_cf: current rating=$rating "
      set w [lindex $rating 0]
      set solution_id [lindex $rating 1]
      ns_log notice "xolrn_cf: rating=$w,solution_id=$solution_id"
      set solution_item ""
      catch {set solution_item [::xo::db::CrClass get_instance_from_db -item_id $solution_id]}
      if {$solution_item ne ""} {
        lappend ratings_valid $rating
        set qvar [$solution_item get_property -name qvar]
        ns_log notice "xorln_cf: solution item found qvar=$qvar, w=$w"
        set qwsum [expr {0.0 + $qwsum + $w * $qvar}]
        set qsum [expr {0.0 + $qsum + $qvar}]
      }
    }

    set ratings $ratings_valid
    if {$qsum <= 0} {
      set qsum 0.001
      ns_log notice "####serious bug? xolrn_cf: important: qsum was 0!"
    }
    
    set evar [expr {(1.0 / $qsum) * $qwsum}]
    ns_log notice "xolrn_cf: qwsum fuer $item= $qwsum, qsum=$qsum, evar=$evar"
    
    $item set_property -new 1 evar $evar
    set bvar_old [$item get_property -name bvar]
    set bvar [$item recalc_bvar]
    ns_log notice "i am [$item item_id] - bvar = $bvar old= $bvar_old"
    set nratings [llength $ratings]
    set qvar [expr {($answerstorate/($answerstorate+$nratings))*$bvar+(($nratings)/($nratings+$answerstorate)*$evar)}]
    ns_log notice "xolrn_cf: debug: bvar=$bvar evar=$evar nratings=$nratings answerstorate=$answerstorate - qvar=$qvar iam=[$item item_id]"
    #$item set_property -new 1 ratings $ratings
    if {[lsearch $exclude [$item item_id]] eq -1} {
	$item set_property -new 1 qvar $qvar
	$item set_property -new 1 bvar $bvar
	}
    set s [$item find_slot instance_attributes]
    $item update_attribute_from_slot -revision_id "[$item revision_id]" $s [$item instance_attributes]
    $item save
}
  }
		foreach item $items {
		ns_log notice "recalc final loop: dealing with $item"
		  regexp {.*___(.*)} [$item set name] match userid
			set user_exists [db_string bla "select username from users where user_id = :userid;" -default 0]
			if {$user_exists eq 0} {
				ns_log notice "[$item set name] will not be recalculated!"
				continue
				}
		
			array set ia [$item set instance_attributes]
			set ratings [expr {[info exists ia(ratings)] ? $ia(ratings) : ""}]
			ns_log notice "$item has been rated by $ratings"
			array unset ia	
			foreach rating $ratings {
				foreach {wform ratingitem} $rating {
						set cached_data [cache get recalcitems]
						ns_log notice "cache is king $cached_data"
						ns_log notice "ratingitem: $ratingitem"
					if {[lsearch $cached_data *$ratingitem] ne -1} {
						ns_log notice "found $ratingitem"
					} else {
					ns_log notice "not found in cache $ratingitem starting recursion"
					lappend cached_data $ratingitem
					cache set recalcitems $cached_data
					if {![catch {set rateitem [::xo::db::CrClass get_instance_from_db -item_id $ratingitem]} dev]} {
						set fetched_items [$rateitem get_property -name fetched_item_ids]
							if {$fetched_items ne 0} {
							foreach fetched_item $fetched_items {
							if {![catch {set fetched_item [::xo::db::CrClass get_instance_from_db -item_id $fetched_item]} dev]} {
								lappend itemlist $fetched_item
							}
							ns_log notice "recursion fetched items $itemlist for $rateitem"
							$rateitem recalc_basevalues $itemlist [$item set item_id] $level
							}
						}
					}	
				}
			}
		}
  }
  }
  
  WorkflowPage ad_instproc calc_basevalues {items} {
    } {
	set sum 0.0
	set answerstorate 3.0
	# calculate basiswert for own answer

  foreach item $items {
    set wform [my get_property -name rateitem[incr k]_scale]
    set qitem [$item get_property -name qvar]
    set w [expr {$wform / 10.0}]
    if {[expr {1.0-$qitem }] > $qitem } {
        set maxdivq [expr {1.0-$qitem}]
    } else {
	set maxdivq $qitem
    }

    #vorzeichen aendern wenn negativ
    set dev [expr {$w-$qitem }]
    if {$dev < 0} {
      set dev [expr -$dev]
    }

    ns_log notice "xolrn_cf: doing calc_basevacalc_basevalues for [$item set item_id] - [$item set name] - dev=$dev, qitem=$qitem, w=$w, maxdivq=$maxdivq"
    #calculate sum
    set sum [expr {$sum + 0.0 + ($dev) / ($maxdivq)}]

    # append rating and link to solution
    set ratings [$item get_property -name ratings]
    ns_log notice "xolrn_cf: my object id is: [my object_id] - my ratings are $ratings - i am [$item set item_id]"
    lappend ratings "$w [my item_id]"
    $item set_property -new 1 ratings $ratings
    set s [$item find_slot instance_attributes]
    $item update_attribute_from_slot -revision_id "[$item revision_id]" $s [$item instance_attributes]
    $item save
  }

  set bvar  [expr {1.0- (1.0 / $answerstorate) * $sum}]
  ns_log notice "xolrn_cf: sum=$sum, bvar=$bvar"

  #zu diesem zeitpunkt kann das item noch keine bewertungen haben, daher evar 0.0
  my set_property -new 1 evar 0.0
  my set_property -new 1 qvar $bvar
  #update evaluation values of rated answers
  foreach item $items {
	set qwsum 0.0
	set qsum 0.0
       #get current ratings of the item
       #calculate qwsum
       set user_id ""
       #do not recalculate qvar for sample answers
       regexp {.*___(.*)} [$item set name] match userid
       set user_exists [db_string bla "select username from users where user_id = :userid;" -default 0]
	if {$user_exists eq 0} {
		ns_log notice "[$item set name] will not be recalculated!"
	} else {
    set ratings [$item get_property -name ratings]
    ns_log notice "xolrn_cf: ### recalc evar for [$item set item_id] number of ratings= [llength ratings]"
    set ratings_valid ""
	  
    foreach rating $ratings {
      set solution_id ""
      ns_log notice "xolrn_cf: current rating=$rating "
      set w [lindex $rating 0]
      set solution_id [lindex $rating 1]
      ns_log notice "xolrn_cf: rating=$w,solution_id=$solution_id"
      set solution_item ""
      catch {set solution_item [::xo::db::CrClass get_instance_from_db -item_id $solution_id]}
      if {$solution_item ne ""} {
        lappend ratings_valid $rating
        set qvar [$solution_item get_property -name qvar]
        ns_log notice "xorln_cf: solution item found qvar=$qvar, w=$w"
        set qwsum [expr {0.0 + $qwsum + $w * $qvar}]
        set qsum [expr {0.0 + $qsum + $qvar}]
      }
    }

    set ratings $ratings_valid
    if {$qsum <= 0} {
      set qsum 0.001
      ns_log notice "####serious bug? xolrn_cf: important: qsum was 0!"
    }
    
    set evar [expr {(1.0 / $qsum) * $qwsum}]
    ns_log notice "xolrn_cf: qwsum fuer $item= $qwsum, qsum=$qsum, evar=$evar"
    
     $item set_property -new 1 evar $evar
      set bvar [$item get_property -name bvar]
      set nratings [llength $ratings]
      set qvar [expr {($answerstorate/($answerstorate+$nratings))*$bvar+(($nratings)/($nratings+$answerstorate)*$evar)}]
      ns_log notice "xolrn_cf: debug: bvar=$bvar evar=$evar nratings=$nratings answerstorate=$answerstorate - qvar=$qvar"
      $item set_property -new 1 ratings $ratings
      $item set_property -new 1 qvar $qvar
      set s [$item find_slot instance_attributes]
      $item update_attribute_from_slot -revision_id "[$item revision_id]" $s [$item instance_attributes]
  	$item save
 
}
  }
  }
  
    WorkflowPage instproc list_answers {} {
        ::xo::Page requireCSS /resources/xolrn_excs/xolrn.css
	
	#opentext
	if {[my get_property -name exercise_form] eq "ot" || [my get_property -name exercise_type] eq "ot"} {
	    set html "<div id='list-markup'><table id='list-content' >"
	    
	    set t [::YUI::DataTable new -skin yui-skin-sam -volatile \
               -columns {
		::YUI::AnchorField creator -label "Creator" 
		::YUI::AnchorField username -label "Username" 
		::YUI::AnchorField last_modified -label "Last-Modified" 
		::YUI::AnchorField qvar  -label "Qualitaetswert" 
		::YUI::AnchorField rerate  -label "Qualitaetswert neu bewerten"
		::YUI::AnchorField bvar  -label "Basiswert" 
		::YUI::AnchorField evar  -label "Evaluierungswert" 
		::YUI::AnchorField answer -label "Antwort" 
		::YUI::AnchorField ratings -label "ratings" 
		::YUI::AnchorField rateitem1 -label "rateitem1" 
		::YUI::AnchorField rateitem1_scale -label "rateitem1_scale" 
		::YUI::AnchorField rateitem2 -label "rateitem2" 
		::YUI::AnchorField rateitem2_scale -label "rateitem2_scale" 
		::YUI::AnchorField rateitem3 -label "rateitem3" 
		::YUI::AnchorField rateitem3_scale -label "rateitem3_scale" 
		::YUI::AnchorField item_id -label "item_id" 
		::YUI::AnchorField fetched_item_ids -label "fetched_item_ids" 
		}]
	      
	    foreach item  [[my get_answers_for_template] children] {
		array set ia [$item set instance_attributes]
		
		 if {![info exists ia(creator_id)]} {set ia(creator_id) "" }
		 if {![info exists ia(username)]} {set ia(username) unknown }
		 if {![info exists ia(qvar)]} {set ia(qvar) 0 }
		 if {![info exists ia(evar)]} {set ia(evar) 0 }
		 if {![info exists ia(bvar)]} {set ia(bvar) 0 }
		 if {![info exists ia(answer)]} {set ia(answer) empty }
		 if {![info exists ia(ratings)]} {set ia(ratings) none }
		 if {![info exists ia(rateitem1)]} {set ia(rateitem1)  ""}
		 if {![info exists ia(rateitem1_scale)]} {set ia(rateitem1_scale)  ""}
		 if {![info exists ia(rateitem2)]} {set ia(rateitem2)  ""}
		 if {![info exists ia(rateitem2_scale)]} {set ia(rateitem2_scale)  ""}
		 if {![info exists ia(rateitem3)]} {set ia(rateitem3)  ""}
		 if {![info exists ia(rateitem3_scale)]} {set ia(rateitem3_scale)  ""}
		 if {![info exists ia(fetched_item_ids)]} {set ia(fetched_item_ids)  ""}
		 set studentnr 0
		 #set reratelink "<input type='text' id='rerate'>"
		 regexp {.*___(.*)} [$item set name] match studentnr
		 set return_url "return_url=[::xo::cc set url]%3Fm%3dlist_answers%26page_size%3d1000"
		 append html "<tr>
		 <td>[::xo::get_user_name $studentnr]</td>
		 <td>$ia(username)</td>
		 <td>[$item last_modified]</td>
		 <td>
			$ia(qvar)<br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.1&return_url=[::xo::cc set url]'>setzen auf 0.1</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.2&$return_url'>setzen auf 0.2</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.3&$return_url'>setzen auf 0.3</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.4&$return_url'>setzen auf 0.4</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.5&$return_url'>setzen auf 0.5</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.6&$return_url'>setzen auf 0.6</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.7&$return_url'>setzen auf 0.7</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.8&$return_url'>setzen auf 0.8</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=0.9&$return_url'>setzen auf 0.9</a><br>
			<a href='[$item pretty_link]?m=change_qvar&newqvar=1.0&$return_url'>setzen auf 1.0</a><br>
			</td>
		 <td>$ia(bvar)<br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.1&$return_url'>setzen auf 0.1</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.2&$return_url'>setzen auf 0.2</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.3&$return_url'>setzen auf 0.3</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.4&$return_url'>setzen auf 0.4</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.5&$return_url'>setzen auf 0.5</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.6&$return_url'>setzen auf 0.6</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.7&$return_url'>setzen auf 0.7</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.8&$return_url'>setzen auf 0.8</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=0.9&$return_url'>setzen auf 0.9</a><br>
			<a href='[$item pretty_link]?m=change_bvar&newbvar=1.0&$return_url'>setzen auf 1.0</a><br>
			</td>
		 <td>$ia(evar)</td>
		 <td>$ia(answer)</td>
		 <td>$ia(ratings)</td>
		 <td>$ia(rateitem1_scale)<br>
		 $ia(rateitem1)</td>
		 <td>$ia(rateitem2_scale)<br>
		 $ia(rateitem2)</td>
		 <td>$ia(rateitem3_scale)<br>
		 $ia(rateitem3)</td>
		 <td>[$item set item_id]</td>
		 <td>$ia(fetched_item_ids)</td>
		 </tr>
		 "
## 		 $t add -creator [::xo::get_user_name $studentnr] \
 # 			-username $ia(username) \
 # 			-last_modified [$item last_modified] \
 # 			-qvar $ia(qvar) \
 # 			-rerate "setzen auf 0.5" \
 # 			-rerate.href "[$item pretty_link]?m=change_qvar&newqvar=0.5" \
 # 			-bvar $ia(bvar) \
 # 			-evar $ia(evar) \
 # 			-answer $ia(answer) \
 # 			-ratings $ia(ratings) \
 # 			-rateitem1 $ia(rateitem1) \
 # 			-rateitem1_scale $ia(rateitem1_scale) \
 # 			-rateitem2 $ia(rateitem2) \
 # 			-rateitem2_scale $ia(rateitem2_scale) \
 # 			-rateitem3 $ia(rateitem3) \
 # 			-rateitem3_scale $ia(rateitem3_scale) \
 # 			-item_id [$item set item_id] \
 # 			-fetched_item_ids $ia(fetched_item_ids)
 ##
		 array unset ia
	    }
		 append html "</table></div>"
		 append html {
		 <script>
		 
		 var sortDates = function(a, b, desc) {
			if(!YAHOO.lang.isValue(a)) {
			  return (!YAHOO.lang.isValue(b)) ? 0 : 1;
			}
			else if(!YAHOO.lang.isValue(b)) {
			  return -1;
			}
		
		var date_a = a.getData("last_modified");
		var day_a = date_a.substr(0,2);
		var month_a = date_a.substr(3,2);
		var year_a = date_a.substr(6,4);
		var time_a = date_a.substr(10);
		var newdate_a = year_a + '' +month_a +'' +day_a +'' +time_a;
		
		var date_b = b.getData("last_modified");
		var day_b = date_b.substr(0,2);
		var month_b = date_b.substr(3,2);
		var year_b = date_b.substr(6,4);
		var time_b = date_b.substr(10);
		var newdate_b = year_b + '' +month_b +'' +day_b +'' +time_b;

		var comp = YAHOO.util.Sort.compare;
		return comp(newdate_a, newdate_b, desc);

		}
		
	var datatableloader = new YAHOO.util.YUILoader({
	require: ['datatable'], // what components?
	base: "/resources/ajaxhelper/yui/",        
	loadOptional: false,
	onSuccess: function() {
		YAHOO.example.EnhanceFromMarkup = new function() {
	        var myColumnDefs = [ 
	            {key:"creator",label:"Creator",sortable:true}, 
	            {key:"username",label:"Username",sortable:true}, 
	            {key:"last_modified",label:"Änderungsdatum",formatter:YAHOO.widget.DataTable.formatDate,sortable:true,sortOptions:{sortFunction:sortDates}}, 
		     {key:"qvar",label:"Qualitaetswert",sortable:true}, 
	            {key:"bvar",label:"Basiswert",sortable:true}, 
	            {key:"evar",label:"Evaluierungswert",sortable:true}, 
	            {key:"answer",label:"Antwort",sortable:true},
	            {key:"ratings",label:"ratings",sortable:true},
	            {key:"rateitem1",label:"rateitem1",sortable:true},
	            {key:"rateitem2",label:"rateitem2",sortable:true},
	            {key:"rateitem3",label:"rateitem3",sortable:true},
	            {key:"item_id",label:"item_id",sortable:true},
	            {key:"fetched_item_ids",label:"fetched_item_ids",sortable:true}
	        ]; 
	        this.myDataSource = new YAHOO.util.DataSource(YAHOO.util.Dom.get("list-content")); 
	        this.myDataSource.responseType = YAHOO.util.DataSource.TYPE_HTMLTABLE; 
	        this.myDataSource.responseSchema = { 
	            fields: [{key:"creator"}, 
	                    {key:"username"}, 
	                    {key:"last_modified"}, 
	                    {key:"qvar"},
	                    {key:"bvar"},
	                    {key:"evar"},
	                    {key:"answer"},
	                    {key:"ratings"},
	                    {key:"rateitem1"},
	                    {key:"rateitem2"},
	                    {key:"rateitem3"},
	                    {key:"item_id"},
	                    {key:"fetched_item_ids"}
	            ] 
	        }; 
	        this.myDataTable = new YAHOO.widget.DataTable("list-markup", myColumnDefs, this.myDataSource); 
	    }; 
	},
	onFailure: function(o) {
		  alert('error: ' + YAHOO.lang.dump(o)); 
	}});
	datatableloader.insert();
	</script>
		 }
	    if { [[::xo::cc package_id] query_parameter "csv" 0] eq 1} {
		$t write_csv
	    } else {
	    #my view "[$t asHTML] \n
	    my view "$html \n
		<a href='[::xo::cc url]?[::xo::cc actual_query]&csv'>csv</a>"
	    }
	}
  }
  
  WorkflowPage instproc folder_export {} {
	#first thing to export is the current item
	set items([my item_id]) 1 
	
	#then export the folder's contents
        set attributes [list revision_id creation_user title parent_id \
                          "to_char(last_modified,'YYYY-MM-DD HH24:MI') as last_modified" ]
        set base_table [::xowiki::FormPage set table_name]i
	set sql [::xowiki::FormPage instance_select_query \
                     -folder_id [my item_id] \
                     -with_subtypes false \
                     -select_attributes $attributes \
                     -base_table $base_table]
	
	db_foreach [my qn instance_select] $sql {
		set items($item_id) 1
	}
	
	#then the wf instances
	foreach item [[my get_answers_for_template] children] {
		set items([$item item_id]) 1
	}
	
	#write everything to stdout
	foreach item_id [array names items] {
		::xo::db::CrClass get_instance_from_db -item_id $item_id
		ns_log notice "--exporting $item_id [$item_id name]"
		if {[catch {set obj [$item_id marshall]} errorMsg]} {
			ns_log error "Error while exporting $item_id [$item_id name]\n$errorMsg"
		} else {
			ns_write "$obj\n" 
		}
	}
  }
  
    WorkflowPage instproc change_bvar {} {
	set newbvar [::xo::cc query_parameter newbvar 0.5]
	#get the current variables
	array set ia [my instance_attributes]
	set bvar [expr {[info exists ia(bvar)] ? $ia(bvar) : ""}]	
	set evar [expr {[info exists ia(evar)] ? $ia(evar) : "0.0"}]	
	set ratings [expr {[info exists ia(ratings)] ? $ia(ratings) : ""}]	
	my array unset __wfi
	my set_property -new 1 bvar $newbvar	
	set answerstorate 3.0
	if {$ratings eq ""} {
		set nratings 0.0
	} else {
		set nratings [llength $ratings]
	}
	#mein bvar wird geändert: mein qvar ändert sich + qvar derer die mich bewertet haben
	set qvar [expr {($answerstorate/($answerstorate+$nratings))*$bvar+(($nratings)/($nratings+$answerstorate)*$evar)}]
	my set_property -new 1 qvar $qvar	
	set s [my find_slot instance_attributes]
	my update_attribute_from_slot -revision_id "[my revision_id]" $s [my instance_attributes]
	my save
	array unset ia	
	cache flush recalcitems
	cache flush excludeitems
	foreach rating $ratings {
		foreach {wform ratingitem} $rating {
			if {![catch {set item [::xo::db::CrClass get_instance_from_db -item_id $ratingitem]} dev]} {
			set fetched_items [$item get_property -name fetched_item_ids]
			if {$fetched_items ne 0} {
				foreach fetched_item $fetched_items {
				if {![catch {set fetched_item [::xo::db::CrClass get_instance_from_db -item_id $fetched_item]} dev]} {
					lappend itemlist $fetched_item
				}
				}
				cache set excludeitems [my item_id]
				if {[info exists itemlist]} {
					ns_log notice "change_bvar: will recalc for $item with $itemlist"
					$item recalc_basevalues $itemlist [my item_id] 1
				}
			}
			}
		}
	}
  ad_returnredirect [::xo::cc query_parameter return_url]
  }
  
  WorkflowPage instproc change_qvar {} {
	set newqvar [::xo::cc query_parameter newqvar 0.5]
	#get the current variables
	array set ia [my instance_attributes]
	ns_log notice [my instance_attributes]
	set qvar [expr {[info exists ia(qvar)] ? $ia(qvar) : ""}]	
	my array unset __wfi
	my set_property -new 1 qvar $newqvar	
	set s [my find_slot instance_attributes]
	my update_attribute_from_slot -revision_id "[my revision_id]" $s [my instance_attributes]
	my save
	set ratings [expr {[info exists ia(ratings)] ? $ia(ratings) : ""}]
	array unset ia	
	cache flush recalcitems
	cache flush excludeitems
	foreach rating $ratings {
		foreach {wform ratingitem} $rating {
			if {![catch {set item [::xo::db::CrClass get_instance_from_db -item_id $ratingitem]} dev]} {
			set fetched_items [$item get_property -name fetched_item_ids]
			if {$fetched_items ne 0} {
				foreach fetched_item $fetched_items {
				if {![catch {set fetched_item [::xo::db::CrClass get_instance_from_db -item_id $fetched_item]} dev]} {
					lappend itemlist $fetched_item
				}
				}
				cache set excludeitems [my item_id]
				if {[info exists itemlist]} {
					$item recalc_basevalues $itemlist [my item_id] 1
				}
			}
			}
		}
	}
    ad_returnredirect [::xo::cc query_parameter return_url]
  }
}
namespace eval ::xowiki {
#www interface hooks
Page instproc list_answers {} {
	next
}

Page instproc folder_export {} {
	next
}

Page instproc change_qvar {} {
	next
}

Page instproc change_bvar {} {
	next
}

###
##ensure that language prefixes are removed from items residing in XoLrn instances 
###
   Page instproc build_name {{-nls_language ""}} {
    #eliminate lng prefixes for workflowpages
     set isxolrn [expr {[[my package_id] package_key] eq "xolrn_excs"}]
     #no language prefix for items in XoLrn instances
      set name [my name]
      set stripped_name $name
      regexp {^..:(.*)$} $name _ stripped_name
      #my msg "$name / '$stripped_name'"
      # prepend the language prefix only, if the entry is not empty
      if {$stripped_name ne ""} {
        if {[my is_folder_page] || [my is_link_page] || $isxolrn} {
          # 
          # Do not add a language prefix to folder pages or xolrn items
          #
          set name $stripped_name
        } else {
          if {$nls_language ne ""} {my nls_language $nls_language}
         set name [my lang]:$stripped_name
        }
      }
    
    return $name
  }
  
}