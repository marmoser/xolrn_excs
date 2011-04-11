::xo::db::require package xowiki
::xo::db::require package xowf

#definition of exercise items

namespace eval ::xowiki::formfield {
  ###########################################################
  #
  # ::xowiki::formfield::FormGeneratorField
  #
  ###########################################################

  Class FormGeneratorField -superclass CompoundField -parameter {
  }
  FormGeneratorField set abstract 1
  FormGeneratorField instproc pretty_value {v} {
    return [[my object] property form ""]
  }
  FormGeneratorField instproc render_input {} {
    ::xo::Page requireCSS /resources/xowf/myform.css
    next
  }

}

namespace eval ::xowiki::formfield {
	Class penalty -superclass text \
	-extend_slot validator penalty_validator 
	
	penalty instproc check=penalty_validator {value} {
    if {$value eq ""} {return 0}
	if {$value < 0.0 || $value > 1.0} {return 0}
	return 1
  }

}

namespace eval ::xowiki::formfield {

  ###########################################################
  #
  # ::xowiki::formfield::test_item
  #
  ###########################################################
  Class test_item -superclass FormGeneratorField -parameter {
    {question_type mc}
    {nr_choices 5}
    {feedback_level full}
  }
  
  #
  # provide a default setting for xinha javascript for test-items
  #
  test_item set xinha(javascript) [::xowiki::formfield::FormField fc_encode { 
    xinha_config.toolbar = [ 
                            ['popupeditor', 'bold','italic','createlink','insertimage','separator'], 
                            ['killword','removeformat','htmlmode'] 
                           ]; 
  }]

  test_item instproc feed_back_definition {auto_correct} {
    #
    # Return the definition of the feed_back widgets depending on the
    # value of auto_correct. If we can't determine automatically,
    # what's wrong, we can't provide different feedback for right or
    # wrong.
    #
    my instvar inplace feedback_level
    if {$feedback_level eq "none"} {
      return ""
    }

    set widget "richtext,editor=xinha,slim=true,inplace=$inplace,plugins=OacsFs,height=150px"
    if {$auto_correct} {
      return [subst {
        {feedback_correct   {$widget,label=#xolrn_excs.feedback_correct#}}
        {feedback_incorrect {$widget,label=#xolrn_excs.feedback_incorrect#}}
      }]
    }
    return [subst {
      {feedback {$widget,label=#xowf.feedback#}}
    }]
  }

  #
  # test_item is the wrapper for interaction to be used in
  # evaluations. Different wrapper can be defined in a similar way for
  # questionairs, which might need less input fields.
  #
  test_item instproc initialize {} {
  #don't query get_property on a Form
  if {[[my object] info class] eq "::xowiki::FormPage"} {
  my set nr_choices [[my object] get_property -name nr_choices]
    }
    if {[my set __state] ne "after_specs"} return
    my instvar inplace feedback_level
    set options ""
    #
    # Provide some settings for name short-cuts
    #
	set inplace true
	# The object might be a form, just use the property, if we are on
    # a FormPage.
    if {[[my object] istype ::xowiki::FormPage]} {
      set feedback_level_property [[my object] property feedback_level]
      if {$feedback_level_property ne ""} {
        set feedback_level $feedback_level_property
      }
    }
	
    switch -- [my question_type] {
      mc { # we should support as well: minChoices, maxChoices, shuffle
			set interaction_class mc_interaction
			set options nr_choices=[my nr_choices]
			
         }
      sc { # we should support as well: minChoices, maxChoices, shuffle
			set interaction_class mc_interaction
			set options nr_choices=[my nr_choices],multiple=false
         }
      ot { 
			set interaction_class text_interaction
			set options nr_choices=[my nr_choices]
		}
      matching { 
			set interaction_class matching_interaction 
			set options nr_questions=[my nr_choices],nr_answers=[my nr_choices]
	  }
	  gap_text {
			set interaction_class gap_text_interaction
		}
	  order { 
			set interaction_class order_interaction
			set options nr_answers=[my nr_choices]
			}
	  slider {
			set interaction_class slider_interaction
		}
      default {error "unknown question type: [my question_type]"}
    }
	
	#generate the components
	switch -- [my question_type] {
		ot {
			set auto_correct 0
			my create_components  [subst {
		  {interaction {$interaction_class,$options,feedback_level=$feedback_level,inplace=$inplace,form_item_wrapper_CSSclass=hidden-field-set}}
		  [my feed_back_definition $auto_correct]
		}]
		}
		default {
			set auto_correct [expr {[$interaction_class exists auto_correct] && [$interaction_class set auto_correct] == false ? 0 : 1}]
			my create_components  [subst {
		  {minutes numeric,size=2,label=#xowf.Minutes#,hidden}
		  {grading {select,options={exact exact} {partial partial},default=exact,label=#xowf.Grading-Schema#,hidden}}
		  {adaptive {select,options={yes yes} {no no},default=yes,label=#xolrn_excs.adaptive#}}
		  {penalty penalty,size=2,label=#xolrn_excs.penalty#,default=0.3}
		  {shuffle {select,options={yes yes} {no no},default=yes,label=#xolrn_excs.shuffle#}}
		  {scoring {select, options={{Simple score} {default}} {#xolrn_excs.wi_multiplechoice# wi_score_multiplechoice} {#xolrn_excs.wi_multiplechoice_mix# wi_score_multiplechoice_mix} {#xolrn_excs.score_fractionpoints# score_fractionpoints} {#xolrn_excs.score_fractionpoints_sub# score_fractionpoints_sub},default=default,label=#xolrn_excs.scoring#}}
		  {interaction {$interaction_class,$options,feedback_level=$feedback_level,inplace=$inplace,form_item_wrapper_CSSclass=hidden-field-set}}
		  [my feed_back_definition $auto_correct]
		}]
		}
	}
    my set __initialized 1
  }


}

namespace eval ::xowiki::formfield {
  ###########################################################
  #
  # ::xowiki::formfield::mc_interaction
  #
  ###########################################################

  Class mc_interaction -superclass FormGeneratorField -parameter {
    {feedback_level full}
    {inplace false}
    {shuffle true}
    {nr_choices 5}
    {multiple true}
  }

  mc_interaction instproc set_compound_value {value} {
    set r [next]
    if {![my multiple]} {
      # For single choice questions, we have a fake-field for denoting
      # the correct entry. We have to distribute this to the radio
      # element, which is rendered.
      set correct_field_name [my get_named_sub_component_value correct]
      if {$correct_field_name ne ""} {
        foreach c [my components] {
          if {[$c name] eq $correct_field_name} {
            ${c}::correct value $correct_field_name
          }
        }
      }
    }
    return $r
  }

  mc_interaction instproc initialize {} {
    if {[my set __state] ne "after_specs"} return
    test_item instvar {xinha(javascript) javascript}
    my instvar feedback_level inplace input_field_names
    #
    # build choices
    #
    set choice_definition "{mc_choice,feedback_level=$feedback_level,label=#xowf.alternative#,inplace=$inplace,multiple=[my multiple]}"
    set input_field_names [my generate_fieldnames [my nr_choices]]
    set choices ""
    if {![my multiple]} {
      append choices "{correct radio,omit}\n"
    }
    
    

    foreach n $input_field_names {append choices "{$n $choice_definition}\n"}
    
    #
    # create component structure
    #
    my create_components  [subst {
      {text  {richtext,required,editor=xinha,height=100px,label=#xowf.exercise-text#,plugins=OacsFs,javascript=$javascript,inplace=$inplace}}
      $choices
    }]
    my set __initialized 1
  }
  mc_interaction set auto_correct true
  mc_interaction instproc convert_to_internal {} {
    #
    # Build a from from the componets of the exercise on the fly.
    # Actually, this methods computes the properties "form" and
    # "form_constraints" based on the components of this form field.
    # 
    set formelems [my set input_field_names]
foreach f $formelems {append fe2 $f}
    
    set form "<form>\n<table class='mchoice' border='1'>\n<tbody>"
    set fc "@categories:off @cr_fields:hidden\n"
    set intro_text [my get_named_sub_component_value text]
    append form "<tr><td class='text' colspan='2'><div class='question_text'>$intro_text</div></td><td></td></tr>\n"

    #my msg " input_field_names=[my set input_field_names]"
   
    if {![my multiple]} {
      set correct_field_name [my get_named_sub_component_value correct]
    }
    
    foreach input_field_name $formelems {
      foreach f {text correct feedback_correct feedback_incorrect adaptive penalty shuffle scoring} {
        set value($f) [my get_named_sub_component_value $input_field_name $f]
      }
      # skip empty entries
      if {$value(text) eq ""} continue

      #
      # fill values into form
      #
      if {[my multiple]} {
        set correct $value(correct)
#my msg "$input_field_name correct: $correct"        
append form \
            "<tr><td class='selection'><input type='checkbox' name='$input_field_name' value='$input_field_name'/></td>\n" \
            "<td class='value'>$value(text)</td><td></td></tr>\n"
      } else {
        #my msg $correct_field_name,[my name],$input_field_name
        set correct [expr {"[my name].$input_field_name" eq $correct_field_name}]
#my msg "correct2 $correct"
        append form \
            "<tr><td class='selection'><input type='radio' name='radio' value='$input_field_name' /></td>\n" \
            "<td class='value'>$value(text)</td></tr>\n"
      }
      #my msg "[array get value] corr=$correct"

      #
      # build form constraints per input field
      #
	  
	#my msg "is this correct? $correct"
      set if_fc [list]
      if {$correct} {lappend if_fc "answer=$input_field_name"} else {lappend if_fc "answer="}
      if {$value(feedback_correct) ne ""} {
        lappend if_fc "feedback_answer_correct=[::xowiki::formfield::FormField fc_encode $value(feedback_correct)]"
      }
      if {$value(feedback_incorrect) ne ""} {
        lappend if_fc "feedback_answer_incorrect=[::xowiki::formfield:::FormField fc_encode $value(feedback_incorrect)]"
      }
	  #my msg "if_fc $if_fc"
      if {[llength $if_fc] > 0} {append fc [list $input_field_name:checkbox,[join $if_fc ,]]\n}
      #my msg "$input_field_name .correct = $value(correct)"
    }

    if {![my multiple]} {
      regexp {[.]([^.]+)$} $correct_field_name _ correct_field_value
      lappend fc "radio:text,answer=$correct_field_value"
    }
    append form "</tbody></table></FORM>\n"
    [my object] set_property -new 1 form $form
#my msg "form constraints $fc \n form $form" 
    [my object] set_property -new 1 form_constraints $fc
    set anon_instances true ;# TODO make me configurable
    [my object] set_property -new 1 anon_instances $anon_instances
    [my object] set_property -new 1 auto_correct [[self class] set auto_correct]
    [my object] set_property -new 1 has_solution true
    [my object] set publish_status ready
    if {[my multiple]} {
	[my object] set_property -new 1 question_type mc  
	} else {
	[my object] set_property -new 1 question_type sc
	}
    }

  ###########################################################
  #
  # ::xowiki::formfield::mc_choice
  #
  ###########################################################

  Class mc_choice -superclass FormGeneratorField -parameter {
    {feedback_level full}
    {inplace true}
    {multiple true}
  }

  mc_choice instproc initialize {} {
    if {[my set __state] ne "after_specs"} return

    if {1} {
      test_item instvar {xinha(javascript) javascript}
      set text_config [subst {editor=xinha,height=100px,label=Text,plugins=OacsFs,inplace=[my inplace],javascript=$javascript}]
    } else {
      set text_config [subst {editor=wym,height=100px,label=Text}]
    }
    if {[my feedback_level] eq "full"} {
      set feedback_fields {
	{feedback_correct {textarea,cols=60,label=#xowf.feedback_correct#}}
	{feedback_incorrect {textarea,cols=60,label=#xowf.feedback_incorrect#}}
      }
    } else {
      set feedback_fields ""
    }
    if {[my multiple]} {
      # We are in a multiple choice item; provide for editing a radio
      # group per alternative.
      my create_components [subst {
        {text  {richtext,$text_config}}
        {correct {boolean,horizontal=true,label=#xolrn_excs.correct#}}
        $feedback_fields
      }]
    } else {
      # We are in a single choice item; provide for editing a single
      # radio group spanning all entries.  Use as name for grouping
      # the form-field name minus the last segment.
      regsub -all {[.][^.]+$} [my name] "" groupname
      my create_components [subst {
        {text  {richtext,$text_config}}
        {correct {radio,label=#xolrn_excs.correct#,forced_name=$groupname.correct,options={"" [my name]}}}
        $feedback_fields
      }]
    }
    my set __initialized 1
  }
}

namespace eval ::xowiki::formfield {
  ###########################################################
  #
  # ::xowiki::formfield::matching_interaction
  #
  ###########################################################
	Class matching_interaction -superclass FormGeneratorField -parameter {
	{feedback_level none}
	{inplace true}
	{nr_questions 3}
	{nr_answers 3}
	}
	
	matching_interaction instproc initialize {} {
	    if {[my set __state] ne "after_specs"} return
	  	test_item instvar {xinha(javascript) javascript}
        set text_config [subst {editor=xinha,height=40px,label=Text,plugins=OacsFs,inplace=[my inplace],javascript=$javascript}]
        my instvar feedback_level inplace input_field_names
        set i 0
        set selectionhtml ""
        set fns [my generate_fieldnames [my nr_questions]]	
	set choices ""
	set answers ""
	foreach f $fns {
            append choices "{$f {textarea,label=Frage [incr i]}}\n"
            #append selection " {{Frage $i} {$f}}"
        }

        set i 0
        my set ans [my generate_fieldnames [my nr_answers]]
        foreach f [my set ans] {
            #append answers "{answer_[incr i] {textarea,label=Antwortoption $i}} {select_$i {select,options=$selection,label=Zugeordnete Frage} }\n"
            set selection ""
            incr i
            for {set j 1} {$j <= [my nr_questions]} {incr j} {
                append selection "{{Frage $j} {${i}_${j}}} "
            }
            append answers "{answer_$i {textarea,label=Antwortoption $i}} {checkbox_$i {checkbox,options=$selection,label=Zugeordnete Fragen}} \n"
        }
        #my msg " [subst {$choices $answers}]"
        set components [my create_components [subst {
            {text {richtext,$text_config,label=Text}} $choices $answers
        }]]
        my set __initialized 1
	}
	
	matching_interaction instproc convert_to_internal {} {
	    set anz_select_elements 0
	    set correct_list ""
        foreach f [my set components] {
            #my msg "formfields: [$f serialize]"
            if {[string match "*checkbox_*" [$f name]]} {
                append correct_list "[$f value] "
                #selections store which matches are correct
            }
            if {[string match "*answer_*" [$f name]]} {
                append selection "{[$f value] [$f value]}"
                append selectionhtml "<option>[$f value]</option>"
                lappend select_elements $f
                incr anz_select_elements
            }
            if {[string match "*v-*" [$f name]]} {
                lappend formelems $f
            }
        }
        #my msg "correct_list: $correct_list"
        set form "<form>\n <table class='matching' border='1'>\n<tbody>"
        set intro_text [my get_named_sub_component_value text]
        append form "<tr><td class='text' colspan='[expr {$anz_select_elements+1}]'><div class='question_text'>$intro_text</div></td><td></td></tr>\n"
        
        append form "<tr><td></td>"
        foreach s_ele $select_elements {
            append form "<td>[$s_ele value]</td>"
        }
        append form "</tr>"
        set fc "@categories:off @cr_fields:hidden\n"
        
        #set formelems [my set input_field_names]
        #iterate through the elements and create form elements
        set i 0
#        foreach input_field $formelems {
#            incr i
#            my msg "dealing with [$input_field name]"
#            append form "<tr><td class='value' name='[$input_field name]'>[$input_field value]</td>\n" \
#            "<td class='selection'><select name='v-$i'>$selectionhtml</select></td></tr>\n"
#            #append fc "{v-$i:select,options=$selection}\n"
#        }
        
        set i 1
        set k 1
        foreach input_field $formelems {
            append form "<tr><td class='value' name='[$input_field name]'>[$input_field value]</td>\n"
            set j 1
            set cmp_string "${i}_${j}"
            foreach s_ele $select_elements {
                append form "<td class='value'><input type='checkbox' name='v-$k' value='v-$k'></td>"
                set if_fc [list]
                if {[string match "*${j}_${i}*" $correct_list]} {
                    #my msg "found: ${j}_${i}"
                    lappend if_fc "answer=v-$k"
                    #if {$correct} {lappend if_fc "answer=$input_field_name"} else {lappend if_fc "answer="}
                    #if {[llength $if_fc] > 0} {append fc [list $input_field_name:checkbox,[join $if_fc ,]]\n}
                    #lappend fc [list "answer=v-$k"]
                } else {
                    lappend if_fc "answer="
                    #append fc [list "answer="]
                }
                append fc [list v-$k:checkbox,[join $if_fc ,]]\n
                incr j
                incr k                
            }
            incr i
            append form "</tr>"
        }

        #ds_comment "<xmp>$form</xmp>"
        append form "</tbody></table></FORM>\n"
        set anon_instances true
        [my object] set_property -new 1 form $form
        [my object] set_property -new 1 form_constraints $fc
        [my object] set_property -new 1 anon_instances $anon_instances
        [my object] set_property -new 1 auto_correct true
        [my object] set_property -new 1 has_solution true
        [my object] set_property -new 1 question_type matching
	[my object] set publish_status ready
    }
	
}

namespace eval ::xowiki::formfield {
  ###########################################################
  #
  # ::xowiki::formfield::slider_interaction
  #
  ###########################################################
  Class slider_interaction -superclass FormGeneratorField -parameter {
	{feedback_level none}
    {inplace true}
  }

  slider_interaction instproc initialize {} {
        if {[my set __state] ne "after_specs"} return

        test_item instvar {xinha(javascript) javascript}
        my instvar feedback_level inplace input_field_names

      my create_components  [subst {
      {text  {richtext,required,editor=xinha,height=150px,label=#xolrn_excs.exercise-text#,plugins=OacsFs,javascript=$javascript,inplace=$inplace}}
      {correctResponse {numeric,size=3,label=Richtig}}
      {correctTolerance {numeric,default=10,size=3,label=Fehlertoleranz}}
      {upperBound {numeric,default=100,size=3,label=Oberes Limit}}
      }]
      
    my set __initialized 1
  }
  
  slider_interaction instproc convert_to_internal {} {
    set form "<form>\n"
    set fc "@categories:off @cr_fields:hidden\n"
    set intro_text [my get_named_sub_component_value text]
    set correct [my get_named_sub_component_value correctResponse]
    set correctTolerance [my get_named_sub_component_value correctTolerance]
    set upperBound [my get_named_sub_component_value upperBound]
   # set lowerBound [my get_named_sub_component_value lowerBound]

    append form "<div class='question_text'>$intro_text</div>\n"
    append form "<input type='hidden' name='v-1' id='slider_value'>"
    append form "<div class='yui-skin-sam'>
			<ul class='horizontal-list plain'><li style='padding-right:195px;'>0</li>
			<li id='upperboundvalue'>$upperBound</li></ul>
			<div id='slider-bg' class='yui-h-slider' tabindex='-1' title='Slider'>
			<div id='slider-thumb' class='yui-slider-thumb'><img src='/resources/ajaxhelper/yui/slider/assets/thumb-n.gif'></div></div>
			<div style='margin-left:10px;width:200px;text-align:center' id='current_value'>0</div>
			</div>"
    
    set js "
    <style type='text/css'> #slider-bg \{ background:url(/resources/ajaxhelper/yui/slider/assets/bg-fader.gif) 5px 0 no-repeat; \} </style>
    <link rel='stylesheet' type='text/css' href='/resources/ajaxhelper/yui/slider/assets/slider-skin.css' />
    <script type='text/javascript' src='/resources/ajaxhelper/yui/slider/slider-min.js'></script>\n
    <script type='text/javascript' src='/resources/xolrn_excs/xoslider.js'></script>\n
    "

    append fc "v-1:text,answer=$correct;$correctTolerance\n"
    append form "$js\n</form>"
    append from "</form>\n"
    [my object] set_property -new 1 form $form
    [my object] set_property -new 1 form_constraints $fc
    set anon_instances true ;# TODO make me configurable
    [my object] set_property -new 1 anon_instances $anon_instances
    [my object] set_property -new 1 auto_correct true
    [my object] set_property -new 1 has_solution true
    [my object] set_property -new 1 question_type slider
    [my object] set publish_status ready
  }
}

namespace eval ::xowiki::formfield {
  ###########################################################
  #
  # ::xowiki::formfield::order_interaction
  #
  ###########################################################

  Class order_interaction -superclass FormGeneratorField -parameter {
	{feedback_level none}
	{multiple true}
	{inplace true}
	{nr_answers 3}
  }
	
    order_interaction instproc initialize {} {
	if {[my set __state] ne "after_specs"} return
	test_item instvar {xinha(javascript) javascript}
        set text_config [subst {editor=xinha,height=40px,label=Text,plugins=OacsFs,inplace=[my inplace],javascript=$javascript}]
        my instvar feedback_level inplace input_field_names
        set i 0
	if {[my nr_answers] eq ""} {my set nr_answers 3}
        my set ans [my generate_fieldnames [my nr_answers]]
        foreach f [my set ans] {
            append answers "{answer_[incr i] {textarea,label=Antwort $i}}\n"
        }
        #my msg " [subst {$choices $answers}]"
        set components [my create_components [subst {
            {text {richtext,$text_config,label=Text}} $answers
        }]]
        my set __initialized 1
	}
  
    order_interaction instproc convert_to_internal {} {

	    set anz_answer_elements 0
	    set answer_elements [list]
	    foreach f [my set components] {
            #my msg "formfields: [$f serialize]"
            if {[string match "*answer_*" [$f name]]} {
                lappend answer_elements $f
                incr anz_answer_elements
            }
            if {[string match "*v-*" [$f name]]} {
                lappend formelems $f
            }
        }
	
        set form "<form>\n"
        set intro_text [my get_named_sub_component_value text]
        append form "<br><table class='order'><tbody><tr><td class='text' colspan='2'><div class='question_text'>$intro_text</div></td></tr>\n"
        append form "</tbody></table>"
        append form "<div class='workarea'><ul id='ul_order_question' class='draglist'>"
        set fc "@categories:off @cr_fields:hidden \n"
        set djs ""
        set i 1
        foreach input_field $answer_elements {
            append form "<li class='list1' id='[$input_field name]' name='[$input_field name]' value='v-$i'>[$input_field value]</li>\n<input name='v$i' type='hidden' value='v-$i'>"
            append djs "new YAHOO.example.DDList(\"[$input_field name]\");\n"
            append fc "v$i:text,answer=v-$i \n"
            incr i
        }
        append form "</ul></div>"
	
	set js "
        <script src='/resources/ajaxhelper/yui/dragdrop/dragdrop-min.js' ></script>
        <script src='/resources/xolrn_excs/xolrn.js' type='text/javascript'></script>
       " 
	append js "<script type='text/javascript'>
                    ( function() {
                        var Dom = YAHOO.util.Dom;
                        var Event = YAHOO.util.Event;  
                        var DDM = YAHOO.util.DragDropMgr; 
                        
                        Event.onDOMReady(function() {
                                    new YAHOO.util.DDTarget(\"ul_order_question\");
                                    $djs
                                });
                    } ) ();\n
                </script>"
        append form "$js</form>\n"
        set anon_instances true
        [my object] set_property -new 1 form $form
        [my object] set_property -new 1 form_constraints $fc
        [my object] set_property -new 1 anon_instances $anon_instances
        [my object] set_property -new 1 auto_correct true
        [my object] set_property -new 1 has_solution true
        [my object] set_property -new 1 question_type order
	[my object] set publish_status ready
    }
}

namespace eval ::xowiki::formfield {
  ###########################################################
  #
  # ::xowiki::formfield::text_interaction
  #
  ###########################################################

  Class text_interaction -superclass FormGeneratorField -parameter {
    {feedback_level full}
    {inplace true}
    {nr_choices 3}
  }
  text_interaction set auto_correct false

  text_interaction instproc initialize {} {
    if {[my set __state] ne "after_specs"} return
    test_item instvar {xinha(javascript) javascript}
    my instvar feedback_level inplace input_field_names nr_choices
    #
    # create component structure
    #
    set samplesolutions ""
    for {set x 1} {$x<=$nr_choices} {incr x} {
    append samplesolutions [subst {
	{solution-$x {richtext,required,editor=xinha,height=150px,label=Lösung $x (CF),plugins=OacsFs,javascript=$javascript,inplace=$inplace}}
	{qvar-$x {text,default=0.5,size=3,label=Qualitätswert}}
    }]
    }
    
    my create_components  [subst {
      {text  {richtext,required,editor=xinha,height=150px,label=#xowf.exercise-text#,plugins=OacsFs,javascript=$javascript,inplace=$inplace}}
      {lines {numeric,default=10,size=3,label=#xowf.lines#}}
      {columns {numeric,default=60,size=3,label=#xowf.columns#}}
      $samplesolutions
    }]
    my set __initialized 1
  }

  text_interaction instproc convert_to_internal {} {
  my instvar nr_choices 
  set package_id [[my object] package_id]
    #create sample solutions
  set workflow_form_id [string trimleft [$package_id resolve_page_name wf-opentext-cf] :]
    for {set x 1} {$x<=$nr_choices} {incr x} {
	set answer [my get_named_sub_component_value solution-$x]
	set qvar [my get_named_sub_component_value qvar-$x]
	set existing_page [$package_id resolve_page_name [[my object] set name]___$x]
	if {$existing_page eq ""} {
	::xowiki::FormPage create solution -noinit \
		-set instance_attributes [subst {
		answer {$answer} qvar $qvar bvar $qvar init_done 1 p.form {[[my object] item_id]}
		}]	\
		-set text {} \
		-set state {closed} \
		-set page_template $workflow_form_id \
		-set package_id $package_id \
		-set name [[my object] set name]___$x \
		-set title {Opentext Exercise} \
		-set publish_status ready \
		-set parent_id [$package_id set folder_id]
	solution save_new
	} else {
		#update
		set s [$existing_page find_slot instance_attributes]
		$existing_page update_attribute_from_slot $s [subst {
			answer {$answer} qvar $qvar bvar $qvar p.form {[[my object] item_id]}
		}] 
	}
    }
    set form "<form>\n"
    set fc "@categories:off @cr_fields:hidden\n"
    set intro_text [my get_named_sub_component_value text]
    set lines      [my get_named_sub_component_value lines]
    set columns    [my get_named_sub_component_value columns]
    append form "<div class='question_text'>$intro_text</div>\n"
    #append form "<textarea name='answer' rows='$lines' cols='$columns'></textarea>\n" 
    append form "@answer@"
    append fc "answer:textarea,rows=$lines,cols=$columns,required=yes,label=,validator=safe_html"
    append form "</FORM>\n"
    [my object] set_property -new 1 form $form
    [my object] set_property -new 1 form_constraints $fc
    set anon_instances true ;# TODO make me configurable
    [my object] set_property -new 1 anon_instances $anon_instances
    [my object] set_property -new 1 auto_correct [[self class] set auto_correct]
    [my object] set_property -new 1 has_solution false
    [my object] set_property -new 1 question_type ot
    [my object] set publish_status ready
  }
}

namespace eval ::xowiki::formfield {

  ###########################################################
  #
  # ::xowiki::formfield::gap_text_interaction
  #
  ###########################################################

 Class gap_text_interaction -superclass FormGeneratorField -parameter {
    {feedback_level full}
    {inplace true}
  }

  gap_text_interaction instproc initialize {} {
  #todo: allow multiple correct entries (store as csv, split)
  my set auto_correct true
    if {[my set __state] ne "after_specs"} return
    test_item instvar {xinha(javascript) javascript}
    my instvar feedback_level inplace input_field_names
    #
    # create component structure
    #
    my create_components  [subst {
      {text  {richtext,required,editor=xinha,height=150px,label=#xowf.exercise-text#,plugins=OacsFs,javascript=$javascript,inplace=$inplace}}
	  {gaptext  {richtext,required,editor=xinha,height=150px,label=Lückentext,plugins=OacsFs,javascript=$javascript,inplace=$inplace}}
    }]
    my set __initialized 1
  }

  gap_text_interaction instproc convert_to_internal {} {
    set form "<form>\n"
    set fc "@categories:off @cr_fields:hidden\n"
    set intro_text [my get_named_sub_component_value text]
	set gap_text [my get_named_sub_component_value gaptext]
    append form "<div class='question_text'>$intro_text</div>\n"
	# process gaptext and create form element foreach gap
	set i 1
	set gaptexthtml "<p>"
	set fullgaptext "<p>"
	foreach section [split $gap_text #] {
	#my msg "section $section"
	#we have answer sections and normal text
	if {[string match "*-answer*" $section] } {
	set answer [lindex [split $section @] 1]
	    append fullgaptext $answer
		set answer [regsub -all " " $answer "%20"]	
		append gaptexthtml "<input type=text name=v${i}>"
		append fc v${i}:text,answer=$answer\n
		incr i
	} else {
	   append gaptexthtml $section
	   append fullgaptext $section
	}
	}		
	append gaptexthtml "</p>"
	append fullgaptext "</p>"
	
    #append form "<textarea name='answer' rows='$lines' cols='$columns'></textarea>\n" 
    #append fc "answer:textarea"
	append form $gaptexthtml
    append form "</FORM>\n"
    [my object] set_property -new 1 form $form
	[my object] set_property -new 1 fullgaptext $fullgaptext
    [my object] set_property -new 1 form_constraints $fc
	ns_log notice "fc $fc"
    set anon_instances true ;# TODO make me configurable
    [my object] set_property -new 1 anon_instances $anon_instances
   # [my object] set_property -new 1 auto_correct [[self class] set auto_correct]
    [my object] set_property -new 1 has_solution false
    [my object] set_property -new 1 question_type gt
    [my object] set publish_status ready
  }
  
}
